#!/usr/bin/env python3
"""云内外通道消息辅助工具。"""

from __future__ import annotations

import argparse
import base64
import hashlib
import io
import json
import os
import platform
import shutil
import socket
import sys
import uuid
import zipfile
from datetime import datetime, timedelta, timezone
from pathlib import Path
from typing import Any


MESSAGE_TYPE = "cloud_channel_message"
VERSION = "1.0"
DEFAULT_CHUNK_CHARS = 2800000
DEFAULT_GERRIT_MESSAGE_BYTES = 3000000
DEFAULT_GERRIT_TRANSFER_BYTES = 8000000
DEFAULT_TEXT_ENTRY_NAME = "payload.txt"
DEFAULT_ZIP_COMPRESSION_LEVEL = 9
DEFAULT_CITRIX_COMPRESSION_LEVEL = 3
SIDECAR_THRESHOLD_BYTES = 1000000
COMPRESSED_FILE_EXTENSIONS = {
    ".7z",
    ".docx",
    ".gz",
    ".jpeg",
    ".jpg",
    ".mov",
    ".mp4",
    ".pdf",
    ".png",
    ".rar",
    ".webp",
    ".xlsx",
    ".zip",
}
KNOWN_CLOUD_OUTER_PATH = Path("D:/cloudshare")
DEFAULT_CLOUD_OUTER_OUTBOX = Path("D:/cloudshare/cloud-channel/outbox")
DEFAULT_LOCAL_OUTBOX = Path("./outbox")
KNOWN_GERRIT_HOST = "192.168.101.231"
KNOWN_GERRIT_PORT = 29418


def utc_now() -> str:
    return datetime.now(timezone.utc).replace(microsecond=0).isoformat()


def parse_iso_datetime(value: str) -> datetime | None:
    if not value:
        return None
    try:
        return datetime.fromisoformat(value.replace("Z", "+00:00"))
    except ValueError:
        return None


def new_message_id() -> str:
    stamp = datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%SZ")
    return f"{stamp}-{uuid.uuid4().hex[:8]}"


def sha256_hex(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def read_text(path: Path) -> str:
    return path.read_text(encoding="utf-8")


def read_bytes_exact(size: int) -> bytes:
    if size < 0:
        raise SystemExit("大小不能为负数")
    pattern = hashlib.sha256(b"cloud-channel-probe").digest()
    repeats, remainder = divmod(size, len(pattern))
    return pattern * repeats + pattern[:remainder]


def write_json(path: Path, data: dict[str, Any]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(data, ensure_ascii=False, separators=(",", ":")), encoding="utf-8")


def json_bytes(data: dict[str, Any]) -> bytes:
    return json.dumps(data, ensure_ascii=False, separators=(",", ":")).encode("utf-8")


def max_message_bytes(args: argparse.Namespace) -> int:
    if args.max_message_bytes is not None:
        return int(args.max_message_bytes)
    if args.transport_hint == "gerrit-mail":
        return DEFAULT_GERRIT_MESSAGE_BYTES
    return 0


def max_transfer_bytes(args: argparse.Namespace) -> int:
    if args.max_transfer_bytes is not None:
        return int(args.max_transfer_bytes)
    if args.transport_hint == "gerrit-mail":
        return DEFAULT_GERRIT_TRANSFER_BYTES
    return 0


def compression_level(args: argparse.Namespace) -> int:
    configured = getattr(args, "compression_level", None)
    if configured is None:
        if getattr(args, "transport_hint", "") == "citrix-drive":
            level = DEFAULT_CITRIX_COMPRESSION_LEVEL
        else:
            level = DEFAULT_ZIP_COMPRESSION_LEVEL
    else:
        level = int(configured)
    if level < 0 or level > 9:
        raise SystemExit("--compression-level 必须在 0 到 9 之间，9 为最高 zip 压缩级别")
    return level


def should_use_sidecar(args: argparse.Namespace, payload_size: int) -> bool:
    return (
        getattr(args, "transport_hint", "") == "citrix-drive"
        and getattr(args, "sidecar", True)
        and payload_size >= SIDECAR_THRESHOLD_BYTES
    )


def should_use_sidecar_folder(args: argparse.Namespace) -> bool:
    return (
        getattr(args, "transport_hint", "") == "citrix-drive"
        and getattr(args, "sidecar", True)
        and getattr(args, "payload_type", "auto") == "auto"
    )


def enforce_message_size(args: argparse.Namespace, message: dict[str, Any]) -> None:
    limit = max_message_bytes(args)
    if limit <= 0:
        return
    size = len(json_bytes(message))
    if size > limit:
        raise SystemExit(
            f"通道消息超过当前传输大小上限：{size} 字节 > {limit} 字节。"
            "如果走 Gerrit 评论邮件，请减小正文、改用 inline-archive 分片，"
            "或降低 --chunk-chars。确认服务器真实限制后，可用 --max-message-bytes 调整。"
        )


def enforce_transfer_size(args: argparse.Namespace, messages: list[dict[str, Any]]) -> None:
    limit = max_transfer_bytes(args)
    if limit <= 0:
        return
    size = sum(len(json_bytes(message)) for message in messages)
    if size > limit:
        raise SystemExit(
            f"本批通道消息超过当前传输累计软上限：{size} 字节 > {limit} 字节。"
            "Gerrit 对同一个 change 有累计评论大小限制。请缩小载荷、减少分片，"
            "换新的承载 change，或只发送清单和文件位置。"
        )


def load_json(path: Path) -> dict[str, Any]:
    return json.loads(path.read_text(encoding="utf-8"))


def candidate_received_roots(args: argparse.Namespace) -> list[Path]:
    roots = [Path("received")]
    out_dir = getattr(args, "out_dir", None)
    if out_dir:
        roots.append(Path(out_dir).parent / "received")
    unique_roots: list[Path] = []
    seen: set[str] = set()
    for root in roots:
        key = str(root.resolve()) if root.exists() else str(root.absolute())
        if key not in seen:
            unique_roots.append(root)
            seen.add(key)
    return unique_roots


def find_conversation_id_for_reply(args: argparse.Namespace, reply_to: str) -> str:
    reply_path = Path(reply_to)
    if reply_path.exists() and reply_path.is_file():
        message = load_json(reply_path)
        return message.get("conversation_id") or message.get("message_id") or reply_to

    for root in candidate_received_roots(args):
        index_path = root / "index.jsonl"
        if index_path.exists():
            lines = index_path.read_text(encoding="utf-8").splitlines()
            for line in reversed(lines):
                if not line.strip():
                    continue
                try:
                    record = json.loads(line)
                except json.JSONDecodeError:
                    continue
                if record.get("message_id") == reply_to:
                    return record.get("conversation_id") or reply_to

        message_path = root / reply_to / "message.json"
        if message_path.exists():
            message = load_json(message_path)
            return message.get("conversation_id") or message.get("message_id") or reply_to

    return reply_to


def resolve_conversation_id(args: argparse.Namespace, message_id: str) -> str:
    configured = getattr(args, "conversation_id", None)
    if configured:
        return configured
    reply_to = getattr(args, "reply_to", None)
    if reply_to:
        return find_conversation_id_for_reply(args, reply_to)
    return message_id


def resolve_expect_reply_before(args: argparse.Namespace) -> str:
    timeout_minutes = getattr(args, "timeout_minutes", None)
    if timeout_minutes is None:
        return ""
    if timeout_minutes <= 0:
        raise SystemExit("--timeout-minutes 必须大于 0")
    return (datetime.now(timezone.utc) + timedelta(minutes=timeout_minutes)).replace(microsecond=0).isoformat()


def base_envelope(args: argparse.Namespace, message_id: str) -> dict[str, Any]:
    return {
        "channel_message_type": MESSAGE_TYPE,
        "version": VERSION,
        "message_id": message_id,
        "transfer_id": getattr(args, "transfer_id", None) or message_id,
        "conversation_id": resolve_conversation_id(args, message_id),
        "reply_to": getattr(args, "reply_to", None) or "",
        "expect_reply_before": resolve_expect_reply_before(args),
        "direction": args.direction,
        "created_at": utc_now(),
        "sender": args.sender,
        "receiver": args.receiver,
        "subject": args.subject,
        "body": args.body or "",
        "payload_type": "auto" if args.payload_type == "auto" else args.payload_type,
        "delivery": {
            "state": "created",
            "transport_hint": args.transport_hint,
        },
    }


def can_connect(host: str, port: int, timeout_seconds: float = 1.5) -> bool:
    try:
        with socket.create_connection((host, port), timeout=timeout_seconds):
            return True
    except OSError:
        return False


def detect_environment() -> dict[str, Any]:
    system_name = platform.system().lower()
    is_windows = system_name == "windows"
    is_linux = system_name == "linux"
    cloudshare_exists = KNOWN_CLOUD_OUTER_PATH.exists() if is_windows else False
    gerrit_ssh_reachable = can_connect(KNOWN_GERRIT_HOST, KNOWN_GERRIT_PORT)

    environment = "unknown"
    confidence = "low"
    reasons: list[str] = []

    if is_linux and gerrit_ssh_reachable:
        environment = "cloud-inner-linux"
        confidence = "high"
        reasons.append("Linux 主机可以访问开发内网 Gerrit SSH")
    elif is_windows and gerrit_ssh_reachable and not cloudshare_exists:
        environment = "cloud-inner-jump-windows"
        confidence = "medium"
        reasons.append("Windows 主机可以访问 Gerrit SSH，且没有发现 D:/cloudshare")
    elif is_windows and cloudshare_exists and not gerrit_ssh_reachable:
        environment = "cloud-outer-windows"
        confidence = "medium"
        reasons.append("Windows 主机存在 D:/cloudshare，且不能直接访问 Gerrit SSH")
    elif is_windows and cloudshare_exists and gerrit_ssh_reachable:
        environment = "ambiguous-windows"
        confidence = "low"
        reasons.append("Windows 主机同时存在 D:/cloudshare 且可以访问 Gerrit SSH")
    else:
        reasons.append("已知通道探测条件没有匹配到受支持环境")

    return {
        "environment": environment,
        "confidence": confidence,
        "system": platform.system(),
        "hostname": platform.node(),
        "probes": {
            "cloudshare_exists": cloudshare_exists,
            "gerrit_ssh_reachable": gerrit_ssh_reachable,
            "gerrit_host": KNOWN_GERRIT_HOST,
            "gerrit_port": KNOWN_GERRIT_PORT,
        },
        "reasons": reasons,
    }


def expected_direction_for_environment(environment: str) -> str | None:
    if environment in {"cloud-inner-linux", "cloud-inner-jump-windows"}:
        return "cloud-inner-to-cloud-outer"
    if environment == "cloud-outer-windows":
        return "cloud-outer-to-cloud-inner"
    return None


def default_sender_for_direction(direction: str) -> str:
    return "cloud-inner" if direction == "cloud-inner-to-cloud-outer" else "cloud-outer"


def default_receiver_for_direction(direction: str) -> str:
    return "cloud-outer" if direction == "cloud-inner-to-cloud-outer" else "cloud-inner"


def default_transport_for_direction(direction: str) -> str:
    return "gerrit-mail" if direction == "cloud-inner-to-cloud-outer" else "citrix-drive"


def default_out_dir_for_transport(transport_hint: str) -> str:
    return str(DEFAULT_CLOUD_OUTER_OUTBOX if transport_hint == "citrix-drive" else DEFAULT_LOCAL_OUTBOX)


def apply_pack_defaults(args: argparse.Namespace) -> None:
    detected = None
    direction = args.direction
    if direction is None:
        detected = detect_environment()
        args._detected_environment = detected
        environment = detected["environment"]
        direction = expected_direction_for_environment(environment)
    else:
        environment = ""
    if direction is None:
        raise SystemExit(
            "无法自动推断发送方向。请先运行 detect 或显式传入 --direction。"
            f"检测到环境 {environment}，可信度 {detected['confidence']}。"
        )
    args.direction = direction

    if not args.sender:
        args.sender = default_sender_for_direction(direction)
    if not args.receiver:
        args.receiver = default_receiver_for_direction(direction)
    if not args.transport_hint:
        args.transport_hint = default_transport_for_direction(direction)
    if not args.out_dir:
        args.out_dir = default_out_dir_for_transport(args.transport_hint)
    if not args.subject:
        args.subject = "云内外通道消息"

    if not args.file and Path("transfer-root").exists():
        args.file = "transfer-root"
    if not args.file and Path("payload").exists():
        args.file = "payload"


def guard_pack_direction(args: argparse.Namespace) -> None:
    if args.skip_environment_guard:
        return
    detected = getattr(args, "_detected_environment", None) or detect_environment()
    environment = detected["environment"]
    expected = expected_direction_for_environment(environment)
    if expected is None:
        raise SystemExit(
            "当前环境不适合直接发送通道消息。"
            f"检测到环境 {environment}，可信度 {detected['confidence']}。"
            "请先运行 detect 或 doctor。只有人工确认后，才可使用 --skip-environment-guard。"
        )
    if args.direction != expected:
        raise SystemExit(
            "拒绝创建方向与当前环境不匹配的消息。"
            f"检测到环境 {environment}，期望方向 {expected}，实际方向 {args.direction}。"
            "只有人工确认后，才可使用 --skip-environment-guard。"
        )


def output_name(message_id: str, suffix: str) -> str:
    safe_suffix = suffix.replace("/", "_").replace("\\", "_")
    return f"{message_id}_{safe_suffix}.json"


def command_pack(args: argparse.Namespace) -> int:
    apply_pack_defaults(args)
    guard_pack_direction(args)
    out_dir = Path(args.out_dir)
    message_id = args.message_id or new_message_id()
    envelope = base_envelope(args, message_id)

    if args.payload_type == "auto":
        if args.file:
            file_path = Path(args.file)
            if should_use_sidecar_folder(args):
                return write_sidecar_folder(args, envelope, file_path)
            if file_path.is_dir():
                archive_bytes = build_zip_from_folder(file_path, compression_level(args))
                archive_name = f"{file_path.name}.zip"
            elif file_path.is_file():
                file_bytes = file_path.read_bytes()
                archive_bytes = build_zip_bytes(file_path.name, file_bytes, compression_level(args))
                archive_name = f"{file_path.name}.zip"
            else:
                raise SystemExit(f"路径不存在：{file_path}")
        else:
            payload_bytes = (args.text if args.text is not None else args.body or "").encode("utf-8")
            if getattr(args, "transport_hint", "") == "citrix-drive":
                return write_text_message(args, envelope, payload_bytes)
            archive_bytes = build_zip_bytes(DEFAULT_TEXT_ENTRY_NAME, payload_bytes, compression_level(args))
            archive_name = "payload.zip"
        if should_use_sidecar(args, len(archive_bytes)):
            return write_sidecar_archive(args, envelope, archive_name, archive_bytes)
        return write_archive_messages(args, envelope, archive_name, archive_bytes)

    if args.payload_type == "text":
        payload_bytes = (args.text if args.text is not None else args.body or "").encode("utf-8")
        if args.compress:
            archive_bytes = build_zip_bytes(DEFAULT_TEXT_ENTRY_NAME, payload_bytes, compression_level(args))
            if should_use_sidecar(args, len(archive_bytes)):
                return write_sidecar_archive(args, envelope, "payload.zip", archive_bytes)
            return write_archive_messages(args, envelope, "payload.zip", archive_bytes)
        return write_text_message(args, envelope, payload_bytes)

    if args.payload_type == "inline-file":
        if not args.file:
            raise SystemExit("使用 inline-file 时必须提供 --file")
        file_path = Path(args.file)
        file_bytes = file_path.read_bytes()
        try:
            content = file_bytes.decode("utf-8")
        except UnicodeDecodeError as exc:
            raise SystemExit("inline-file 只接受 UTF-8 文本文件。二进制数据请使用 inline-archive。") from exc
        if args.compress:
            archive_bytes = build_zip_bytes(file_path.name, file_bytes, compression_level(args))
            archive_name = f"{file_path.name}.zip"
            if file_path.suffix.lower() in COMPRESSED_FILE_EXTENSIONS:
                archive_bytes = file_bytes
                archive_name = file_path.name
            if should_use_sidecar(args, len(archive_bytes)):
                return write_sidecar_archive(args, envelope, archive_name, archive_bytes)
            return write_archive_messages(args, envelope, archive_name, archive_bytes)
        envelope["payload"] = {
            "file_name": file_path.name,
            "encoding": "utf-8",
            "content": content,
        }
        envelope["integrity"] = {
            "payload_sha256": sha256_hex(file_bytes),
            "payload_size": len(file_bytes),
        }
        enforce_message_size(args, envelope)
        enforce_transfer_size(args, [envelope])
        write_json(out_dir / output_name(message_id, "file"), envelope)
        print(str(out_dir / output_name(message_id, "file")))
        return 0

    if args.payload_type == "inline-archive":
        if not args.file:
            raise SystemExit("使用 inline-archive 时必须提供 --file")
        file_path = Path(args.file)
        if file_path.is_dir():
            archive_bytes = build_zip_from_folder(file_path, compression_level(args))
            archive_name = f"{file_path.name}.zip"
        else:
            archive_bytes = file_path.read_bytes()
            archive_name = file_path.name
        if should_use_sidecar(args, len(archive_bytes)):
            return write_sidecar_archive(args, envelope, archive_name, archive_bytes)
        return write_archive_messages(args, envelope, archive_name, archive_bytes)

    raise SystemExit(f"不支持的载荷类型: {args.payload_type}")


def find_message_files(input_dir: Path, message_id: str | None) -> list[Path]:
    files = sorted(input_dir.glob("*.json"))
    found: list[Path] = []
    for path in files:
        try:
            data = load_json(path)
        except Exception:
            continue
        if data.get("channel_message_type") != MESSAGE_TYPE:
            continue
        if message_id and data.get("message_id") != message_id:
            continue
        found.append(path)
    return found


def append_message_index(root_dir: Path, message: dict[str, Any], message_dir: Path) -> None:
    index_path = root_dir / "index.jsonl"
    record = {
        "message_id": message.get("message_id", ""),
        "conversation_id": message.get("conversation_id", message.get("message_id", "")),
        "reply_to": message.get("reply_to", ""),
        "direction": message.get("direction", ""),
        "sender": message.get("sender", ""),
        "receiver": message.get("receiver", ""),
        "subject": message.get("subject", ""),
        "body": message.get("body", ""),
        "payload_type": message.get("payload_type", ""),
        "created_at": message.get("created_at", ""),
        "expect_reply_before": message.get("expect_reply_before", ""),
        "message_dir": str(message_dir),
    }
    index_path.parent.mkdir(parents=True, exist_ok=True)
    existing_ids: set[str] = set()
    if index_path.exists():
        for line in index_path.read_text(encoding="utf-8").splitlines():
            if not line.strip():
                continue
            try:
                existing_ids.add(json.loads(line).get("message_id", ""))
            except json.JSONDecodeError:
                continue
    if record["message_id"] in existing_ids:
        return
    with index_path.open("a", encoding="utf-8") as handle:
        handle.write(json.dumps(record, ensure_ascii=False, separators=(",", ":")) + "\n")


def write_received_message(root_dir: Path, message_dir: Path, message: dict[str, Any]) -> None:
    write_json(message_dir / "message.json", message)
    append_message_index(root_dir, message, message_dir)


def command_unpack(args: argparse.Namespace) -> int:
    input_dir = Path(args.input_dir)
    root_out_dir = Path(args.out_dir)
    files = find_message_files(input_dir, args.message_id)
    if not files:
        raise SystemExit("没有找到通道消息文件")

    messages = [load_json(path) for path in files]
    message_ids = sorted({item["message_id"] for item in messages})
    if len(message_ids) != 1:
        raise SystemExit("发现多个消息编号。请传入 --message-id。")
    message_id = message_ids[0]
    out_dir = root_out_dir / message_id
    out_dir.mkdir(parents=True, exist_ok=True)

    first = messages[0]
    payload_type = first.get("payload_type")

    if payload_type == "text":
        text = first.get("payload", {}).get("text", "")
        data = text.encode("utf-8")
        verify_sha(first, data)
        (out_dir / "payload.txt").write_bytes(data)
        write_received_message(root_out_dir, out_dir, first)
        print(str(out_dir))
        return 0

    if payload_type == "inline-file":
        payload = first.get("payload", {})
        content = payload.get("content", "")
        data = content.encode("utf-8")
        verify_sha(first, data)
        file_name = sanitize_file_name(payload.get("file_name") or "payload.txt")
        (out_dir / file_name).write_bytes(data)
        write_received_message(root_out_dir, out_dir, first)
        print(str(out_dir))
        return 0

    if payload_type in {"inline-archive", "inline-archive-chunk"}:
        if payload_type == "inline-archive":
            encoded = first.get("payload", {}).get("content", "")
            archive_bytes = base64.b64decode(encoded.encode("ascii"))
            verify_sha(first, archive_bytes)
            archive_name = sanitize_file_name(first.get("payload", {}).get("archive_name") or "payload.zip")
            (out_dir / archive_name).write_bytes(archive_bytes)
            extract_archive_bytes(archive_bytes, out_dir)
            write_received_message(root_out_dir, out_dir, first)
            print(str(out_dir))
            return 0

        chunks = sorted(messages, key=lambda item: int(item.get("payload", {}).get("chunk_index", 0)))
        expected = int(chunks[0].get("payload", {}).get("chunk_count", 0))
        if expected != len(chunks):
            raise SystemExit(f"压缩包分片缺失：期望 {expected} 个，实际 {len(chunks)} 个")
        for expected_index, item in enumerate(chunks, start=1):
            actual_index = int(item.get("payload", {}).get("chunk_index", 0))
            if actual_index != expected_index:
                raise SystemExit("压缩包分片序号不连续")
        encoded = "".join(item.get("payload", {}).get("content", "") for item in chunks)
        archive_bytes = base64.b64decode(encoded.encode("ascii"))
        verify_sha(chunks[0], archive_bytes)
        archive_name = sanitize_file_name(chunks[0].get("payload", {}).get("archive_name") or "payload.zip")
        (out_dir / archive_name).write_bytes(archive_bytes)
        extract_archive_bytes(archive_bytes, out_dir)
        write_received_message(root_out_dir, out_dir, chunks[0])
        print(str(out_dir))
        return 0

    if payload_type == "sidecar-archive":
        payload = first.get("payload", {})
        sidecar_file = sanitize_file_name(payload.get("sidecar_file") or "")
        if not sidecar_file:
            raise SystemExit("sidecar-archive 缺少 sidecar_file")
        sidecar_path = input_dir / sidecar_file
        if not sidecar_path.exists():
            raise SystemExit(f"没有找到旁路压缩包：{sidecar_path}")
        archive_bytes = sidecar_path.read_bytes()
        verify_sha(first, archive_bytes)
        archive_name = sanitize_file_name(payload.get("archive_name") or sidecar_file)
        (out_dir / archive_name).write_bytes(archive_bytes)
        try:
            extract_archive_bytes(archive_bytes, out_dir)
        except zipfile.BadZipFile:
            payload_dir = out_dir / "payload"
            payload_dir.mkdir(parents=True, exist_ok=True)
            (payload_dir / archive_name).write_bytes(archive_bytes)
        write_received_message(root_out_dir, out_dir, first)
        print(str(out_dir))
        return 0

    if payload_type == "sidecar-folder":
        payload = first.get("payload", {})
        folder_name = sanitize_file_name(payload.get("folder_name") or "")
        if not folder_name:
            raise SystemExit("sidecar-folder 缺少 folder_name")
        sidecar_folder = input_dir / folder_name
        if not sidecar_folder.exists() or not sidecar_folder.is_dir():
            raise SystemExit(f"没有找到旁路 payload 文件夹：{sidecar_folder}")
        verify_payload_folder(first, sidecar_folder)
        payload_dir = out_dir / "payload"
        if payload_dir.exists():
            raise SystemExit(f"payload 目录已存在：{payload_dir}")
        shutil.copytree(sidecar_folder, payload_dir, copy_function=shutil.copy2)
        write_received_message(root_out_dir, out_dir, first)
        print(str(out_dir))
        return 0

    raise SystemExit(f"不支持的载荷类型: {payload_type}")


def verify_sha(message: dict[str, Any], data: bytes) -> None:
    expected = message.get("integrity", {}).get("payload_sha256")
    actual = sha256_hex(data)
    if expected and expected != actual:
        raise SystemExit(f"SHA256 不匹配：期望 {expected}，实际 {actual}")


def sanitize_file_name(name: str) -> str:
    return os.path.basename(name).replace("/", "_").replace("\\", "_")


def build_zip_bytes(entry_name: str, content: bytes, compression_level: int = DEFAULT_ZIP_COMPRESSION_LEVEL) -> bytes:
    buffer = io.BytesIO()
    safe_entry_name = sanitize_file_name(entry_name) or DEFAULT_TEXT_ENTRY_NAME
    with zipfile.ZipFile(buffer, "w", compression=zipfile.ZIP_DEFLATED, compresslevel=compression_level) as zip_file:
        zip_file.writestr(safe_entry_name, content)
    return buffer.getvalue()


def build_zip_from_folder(folder_path: Path, compression_level: int = DEFAULT_ZIP_COMPRESSION_LEVEL) -> bytes:
    buffer = io.BytesIO()
    with zipfile.ZipFile(buffer, "w", compression=zipfile.ZIP_DEFLATED, compresslevel=compression_level) as zip_file:
        for path in sorted(folder_path.rglob("*")):
            if path.is_file():
                zip_file.write(path, arcname=path.relative_to(folder_path).as_posix())
    return buffer.getvalue()


def payload_folder_integrity(folder_path: Path) -> dict[str, Any]:
    file_count = 0
    directory_count = 0
    total_size = 0
    digest = hashlib.sha256()
    entries: list[Path] = []
    for path in folder_path.rglob("*"):
        entries.append(path)
    for path in sorted(entries, key=lambda item: item.relative_to(folder_path).as_posix()):
        relative_path = path.relative_to(folder_path).as_posix()
        stat = path.stat()
        mtime_seconds = int(stat.st_mtime)
        if path.is_dir():
            directory_count += 1
            line = f"D\t{relative_path}\t{mtime_seconds}\n"
        elif path.is_file():
            file_count += 1
            total_size += stat.st_size
            line = f"F\t{relative_path}\t{stat.st_size}\t{mtime_seconds}\n"
        else:
            continue
        digest.update(line.encode("utf-8"))
    return {
        "payload_kind": "folder",
        "file_count": file_count,
        "directory_count": directory_count,
        "total_size": total_size,
        "tree_fingerprint": f"sha256:{digest.hexdigest()}",
    }


def copy_source_to_payload_folder(source_path: Path, payload_folder: Path) -> None:
    if payload_folder.exists():
        raise SystemExit(f"payload 目录已存在：{payload_folder}")
    payload_folder.mkdir(parents=True)
    if source_path.is_file():
        shutil.copy2(source_path, payload_folder / source_path.name)
        return
    if source_path.is_dir():
        for child in source_path.iterdir():
            target = payload_folder / child.name
            if child.is_dir():
                shutil.copytree(child, target, copy_function=shutil.copy2)
            elif child.is_file():
                shutil.copy2(child, target)
        return
    raise SystemExit(f"路径不存在：{source_path}")


def verify_payload_folder(message: dict[str, Any], folder_path: Path) -> None:
    expected = message.get("integrity", {})
    actual = payload_folder_integrity(folder_path)
    for key in ["file_count", "directory_count", "total_size", "tree_fingerprint"]:
        if expected.get(key) != actual.get(key):
            raise SystemExit(
                f"payload 文件夹校验失败：{key} 期望 {expected.get(key)}，实际 {actual.get(key)}。"
                "请确认复制时保留目录结构和修改时间。"
            )


def extract_archive_bytes(archive_bytes: bytes, out_dir: Path) -> None:
    extract_dir = out_dir / "payload"
    extract_dir.mkdir(parents=True, exist_ok=True)
    with zipfile.ZipFile(io.BytesIO(archive_bytes), "r") as zip_file:
        for member in zip_file.infolist():
            member_path = Path(member.filename)
            if member_path.is_absolute() or ".." in member_path.parts:
                raise SystemExit(f"压缩包包含不安全路径：{member.filename}")
            zip_file.extract(member, extract_dir)


def write_archive_messages(args: argparse.Namespace, envelope: dict[str, Any], archive_name: str, archive_bytes: bytes) -> int:
    out_dir = Path(args.out_dir)
    message_id = envelope["message_id"]
    encoded = base64.b64encode(archive_bytes).decode("ascii")
    archive_sha256 = sha256_hex(archive_bytes)
    single_message = dict(envelope)
    single_message["payload_type"] = "inline-archive"
    single_message["payload"] = {
        "archive_name": archive_name,
        "encoding": "base64",
        "content": encoded,
    }
    single_message["integrity"] = {
        "payload_sha256": archive_sha256,
        "payload_size": len(archive_bytes),
    }
    limit = max_message_bytes(args)
    if limit <= 0 or len(json_bytes(single_message)) <= limit:
        enforce_message_size(args, single_message)
        enforce_transfer_size(args, [single_message])
        out_path = out_dir / output_name(message_id, "archive")
        write_json(out_path, single_message)
        print(str(out_path))
        return 0

    chunk_chars = int(args.chunk_chars or DEFAULT_CHUNK_CHARS)
    if chunk_chars < 1000:
        raise SystemExit("--chunk-chars 必须大于或等于 1000")
    if chunk_chars % 4 != 0:
        raise SystemExit("--chunk-chars 必须能被 4 整除，确保每个 Base64 分片可独立解码")
    chunks = [encoded[index : index + chunk_chars] for index in range(0, len(encoded), chunk_chars)] or [""]
    total = len(chunks)
    messages: list[dict[str, Any]] = []
    for index, chunk in enumerate(chunks, start=1):
        part = dict(envelope)
        part["payload_type"] = "inline-archive-chunk"
        part["payload"] = {
            "archive_name": archive_name,
            "encoding": "base64",
            "chunk_index": index,
            "chunk_count": total,
            "content": chunk,
        }
        part["integrity"] = {
            "payload_sha256": archive_sha256,
            "payload_size": len(archive_bytes),
            "chunk_sha256": sha256_hex(base64.b64decode(chunk.encode("ascii"))),
        }
        enforce_message_size(args, part)
        messages.append(part)
    enforce_transfer_size(args, messages)
    for index, part in enumerate(messages, start=1):
        name = output_name(message_id, f"part{index:03d}of{total:03d}")
        write_json(out_dir / name, part)
        print(str(out_dir / name))
    return 0


def write_text_message(args: argparse.Namespace, envelope: dict[str, Any], payload_bytes: bytes) -> int:
    out_dir = Path(args.out_dir)
    message_id = envelope["message_id"]
    message = dict(envelope)
    message["payload_type"] = "text"
    message["payload"] = {
        "encoding": "utf-8",
        "text": payload_bytes.decode("utf-8"),
    }
    message["integrity"] = {
        "payload_sha256": sha256_hex(payload_bytes),
        "payload_size": len(payload_bytes),
    }
    enforce_message_size(args, message)
    enforce_transfer_size(args, [message])
    out_path = out_dir / output_name(message_id, "text")
    write_json(out_path, message)
    print(str(out_path))
    return 0


def write_sidecar_folder(args: argparse.Namespace, envelope: dict[str, Any], source_path: Path) -> int:
    out_dir = Path(args.out_dir)
    message_id = envelope["message_id"]
    payload_folder_name = f"{message_id}_payload"
    payload_folder = out_dir / payload_folder_name
    copy_source_to_payload_folder(source_path, payload_folder)

    message = dict(envelope)
    message["payload_type"] = "sidecar-folder"
    message["payload"] = {
        "folder_name": payload_folder_name,
        "encoding": "folder",
    }
    message["integrity"] = payload_folder_integrity(payload_folder)
    out_path = out_dir / output_name(message_id, "folder")
    write_json(out_path, message)
    print(str(out_path))
    print(str(payload_folder))
    return 0


def write_sidecar_archive(args: argparse.Namespace, envelope: dict[str, Any], archive_name: str, archive_bytes: bytes) -> int:
    out_dir = Path(args.out_dir)
    message_id = envelope["message_id"]
    safe_archive_name = sanitize_file_name(archive_name) or "payload.zip"
    sidecar_name = f"{message_id}_{safe_archive_name}"
    sidecar_path = out_dir / sidecar_name
    sidecar_path.parent.mkdir(parents=True, exist_ok=True)
    sidecar_path.write_bytes(archive_bytes)

    message = dict(envelope)
    message["payload_type"] = "sidecar-archive"
    message["payload"] = {
        "archive_name": safe_archive_name,
        "sidecar_file": sidecar_name,
        "encoding": "file",
    }
    message["integrity"] = {
        "payload_sha256": sha256_hex(archive_bytes),
        "payload_size": len(archive_bytes),
    }
    out_path = out_dir / output_name(message_id, "sidecar")
    write_json(out_path, message)
    print(str(out_path))
    print(str(sidecar_path))
    return 0


def command_list(args: argparse.Namespace) -> int:
    files = find_message_files(Path(args.input_dir), args.message_id)
    now = datetime.now(timezone.utc)
    for path in files:
        data = load_json(path)
        expect_reply_before = data.get("expect_reply_before", "")
        timeout_state = ""
        deadline = parse_iso_datetime(expect_reply_before)
        if deadline and deadline.astimezone(timezone.utc) < now:
            timeout_state = "timeout"
        print(
            "\t".join(
                [
                    data.get("message_id", ""),
                    data.get("conversation_id", data.get("message_id", "")),
                    data.get("reply_to", ""),
                    data.get("direction", ""),
                    data.get("payload_type", ""),
                    timeout_state,
                    data.get("subject", ""),
                    str(path),
                ]
            )
        )
    return 0


def command_detect(args: argparse.Namespace) -> int:
    detected = detect_environment()
    if args.raw_json:
        print(json.dumps(detected, ensure_ascii=False, indent=2))
        return 0
    print(f"环境: {detected['environment']}")
    print(f"可信度: {detected['confidence']}")
    print(f"系统: {detected['system']}")
    print(f"主机名: {detected['hostname']}")
    for key, value in detected["probes"].items():
        print(f"{key}: {value}")
    for reason in detected["reasons"]:
        print(f"原因: {reason}")
    return 0


def command_doctor(args: argparse.Namespace) -> int:
    detected = detect_environment()
    problems: list[str] = []
    environment = detected["environment"]
    expected_direction = expected_direction_for_environment(environment)

    if expected_direction is None:
        problems.append("环境未知或存在歧义；除非使用保护覆盖，否则发送命令会失败")
    if environment == "cloud-outer-windows" and not detected["probes"]["cloudshare_exists"]:
        problems.append("没有找到 D:/cloudshare")
    if environment in {"cloud-inner-linux", "cloud-inner-jump-windows"} and not detected["probes"]["gerrit_ssh_reachable"]:
        problems.append("无法访问 Gerrit SSH")

    report = {
        "detected": detected,
        "expected_send_direction": expected_direction,
        "status": "ok" if not problems else "failed",
        "problems": problems,
    }
    if args.raw_json:
        print(json.dumps(report, ensure_ascii=False, indent=2))
    else:
        print(f"状态: {report['status']}")
        print(f"环境: {environment}")
        print(f"期望发送方向: {expected_direction or ''}")
        for problem in problems:
            print(f"问题: {problem}")
    return 0 if not problems else 2


def command_probe_plan(args: argparse.Namespace) -> int:
    out_dir = Path(args.out_dir)
    out_dir.mkdir(parents=True, exist_ok=True)
    sizes = parse_size_list(args.sizes)
    plan = {
        "probe_type": "gerrit_capacity_plan",
        "created_at": utc_now(),
        "direction": "cloud-inner-to-cloud-outer",
        "change_ids": args.change_ids,
        "patch_sets": args.patch_sets,
        "sizes": sizes,
        "repeat_count": args.repeat_count,
        "max_message_bytes": args.max_message_bytes,
        "max_transfer_bytes": args.max_transfer_bytes,
        "tests": [
            "单条评论边界：逐个发送不同大小的受控消息，记录第一个失败点。",
            "同一 change 累计边界：在同一 change 和同一 patch set 连续发送，记录累计失败点。",
            "换 patch set 验证：在同一 change 的不同 patch set 继续发送，确认累计是否仍然继承。",
            "换 change 验证：在另一个承载 change 发送同等大小消息，确认累计是否重新开始。",
        ],
        "safety": [
            "只在专用承载 change 上执行，不要使用真实业务评审。",
            "每次发送间隔建议不少于 2 秒，避免邮件风暴。",
            "遇到累计超限后，不要继续向同一个 change 重试。",
            "探测内容只包含随机样式字节和通道元数据，不包含敏感信息。",
        ],
    }
    write_json(out_dir / "gerrit_capacity_probe_plan.json", plan)

    for size in sizes:
        payload = read_bytes_exact(size)
        sample_args = argparse.Namespace(
            direction="cloud-inner-to-cloud-outer",
            sender="cloud-inner-probe",
            receiver="cloud-outer-probe",
            subject=f"gerrit capacity probe {size}",
            body=f"probe payload bytes {size}",
            payload_type="text",
            transport_hint="gerrit-mail",
            transfer_id=f"probe-{size}",
            conversation_id=f"probe-{size}",
            reply_to="",
            timeout_minutes=None,
        )
        envelope = base_envelope(sample_args, f"probe-{size}")
        archive_bytes = build_zip_bytes(DEFAULT_TEXT_ENTRY_NAME, payload)
        encoded = base64.b64encode(archive_bytes).decode("ascii")
        message = dict(envelope)
        message["payload_type"] = "inline-archive"
        message["payload"] = {
            "archive_name": "payload.zip",
            "encoding": "base64",
            "content": encoded,
        }
        message["integrity"] = {
            "payload_sha256": sha256_hex(archive_bytes),
            "payload_size": len(archive_bytes),
        }
        sample_report = {
            "input_size": size,
            "compressed_zip_size": len(archive_bytes),
            "single_json_size": len(json_bytes(message)),
            "default_message_limit": DEFAULT_GERRIT_MESSAGE_BYTES,
            "needs_chunk": len(json_bytes(message)) > DEFAULT_GERRIT_MESSAGE_BYTES,
        }
        write_json(out_dir / f"sample_{size}.json", sample_report)

    command_path = out_dir / "run_on_cloud_inner.md"
    command_path.write_text(build_probe_commands(args, sizes), encoding="utf-8")
    print(str(out_dir))
    return 0


def parse_size_list(value: str) -> list[int]:
    sizes: list[int] = []
    for item in value.split(","):
        item = item.strip()
        if not item:
            continue
        sizes.append(int(item))
    if not sizes:
        raise SystemExit("至少需要一个探测大小")
    return sizes


def build_probe_commands(args: argparse.Namespace, sizes: list[int]) -> str:
    change = args.change_ids[0] if args.change_ids else "<change-id>"
    patch_set = args.patch_sets[0] if args.patch_sets else "<patch-set>"
    lines = [
        "# Gerrit 容量探测云内执行清单",
        "",
        "前提：只在专用承载 change 上执行，确认 reviewer 已添加，发送间隔不少于 2 秒。",
        "",
        "## 单条和分片生成",
        "",
    ]
    for size in sizes:
        lines.extend(
            [
                f"### 载荷 {size} 字节",
                "",
                "```bash",
                "mkdir -p ./cloud-channel-probe-payload ./cloud-channel-probe-outbox",
                f"python3 - <<'PY'",
                "import hashlib",
                f"size = {size}",
                "pattern = hashlib.sha256(b'cloud-channel-probe').digest()",
                "repeats, remainder = divmod(size, len(pattern))",
                "data = pattern * repeats + pattern[:remainder]",
                f"open('./cloud-channel-probe-payload/payload-{size}.bin', 'wb').write(data)",
                "PY",
                f"python3 scripts/cloud_channel.py pack \\",
                "  --direction cloud-inner-to-cloud-outer \\",
                "  --sender cloud-inner-probe \\",
                "  --receiver cloud-outer-probe \\",
                f"  --subject \"gerrit capacity probe {size}\" \\",
                f"  --body \"change {change} patchset {patch_set} payload {size}\" \\",
                "  --payload-type inline-archive \\",
                f"  --file ./cloud-channel-probe-payload/payload-{size}.bin \\",
                "  --out-dir ./cloud-channel-probe-outbox \\",
                "  --transport-hint gerrit-mail",
                "```",
                "",
                "把生成的 JSON 按文件名顺序通过 gerrit-notify 发送，并记录成功或失败响应。",
                "",
            ]
        )
    lines.extend(
        [
            "## 必测结论",
            "",
            "- 同一 change 同一 patch set 连续发送到失败，记录累计成功字节数。",
            "- 同一 change 换 patch set 后继续发送，记录是否仍然累计。",
            "- 换新 change 后发送同等消息，记录是否恢复成功。",
            "- 每次失败保留 Gerrit REST 响应原文。",
            "",
        ]
    )
    return "\n".join(lines)


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="创建、查看和还原云内外通道消息。")
    sub = parser.add_subparsers(dest="command", required=True)

    pack = sub.add_parser("pack", help="创建通道消息 JSON 文件。")
    pack.add_argument("--direction", choices=["cloud-inner-to-cloud-outer", "cloud-outer-to-cloud-inner"])
    pack.add_argument("--sender")
    pack.add_argument("--receiver")
    pack.add_argument("--subject")
    pack.add_argument("--body", default="")
    pack.add_argument("--payload-type", default="auto", choices=["auto", "text", "inline-file", "inline-archive"])
    pack.add_argument("--text")
    pack.add_argument("--file")
    pack.add_argument("--out-dir")
    pack.add_argument("--message-id")
    pack.add_argument("--transfer-id")
    pack.add_argument("--conversation-id")
    pack.add_argument("--reply-to")
    pack.add_argument("--timeout-minutes", type=int)
    pack.add_argument("--chunk-chars", type=int, default=DEFAULT_CHUNK_CHARS)
    pack.add_argument("--max-message-bytes", type=int)
    pack.add_argument("--max-transfer-bytes", type=int)
    pack.add_argument("--transport-hint", default="")
    pack.add_argument("--compress", action=argparse.BooleanOptionalAction, default=True)
    pack.add_argument("--compression-level", type=int)
    pack.add_argument("--sidecar", action=argparse.BooleanOptionalAction, default=True)
    pack.add_argument("--skip-environment-guard", action="store_true")
    pack.set_defaults(func=command_pack)

    unpack = sub.add_parser("unpack", help="从通道消息 JSON 文件还原载荷。")
    unpack.add_argument("--input-dir", required=True)
    unpack.add_argument("--out-dir", required=True)
    unpack.add_argument("--message-id")
    unpack.set_defaults(func=command_unpack)

    list_cmd = sub.add_parser("list", help="列出目录中的通道消息。")
    list_cmd.add_argument("--input-dir", required=True)
    list_cmd.add_argument("--message-id")
    list_cmd.set_defaults(func=command_list)

    detect = sub.add_parser("detect", help="检测当前云内外通道环境。")
    detect.add_argument("--raw-json", action="store_true")
    detect.set_defaults(func=command_detect)

    doctor = sub.add_parser("doctor", help="检查当前环境是否适合执行通道操作。")
    doctor.add_argument("--raw-json", action="store_true")
    doctor.set_defaults(func=command_doctor)

    probe_plan = sub.add_parser("probe-plan", help="生成 Gerrit 容量边界探测计划。")
    probe_plan.add_argument("--out-dir", required=True)
    probe_plan.add_argument("--sizes", default="4096,8192,12288,14336,16384,24576,32768")
    probe_plan.add_argument("--change-ids", nargs="*", default=[])
    probe_plan.add_argument("--patch-sets", nargs="*", default=[])
    probe_plan.add_argument("--repeat-count", type=int, default=1)
    probe_plan.add_argument("--max-message-bytes", type=int, default=DEFAULT_GERRIT_MESSAGE_BYTES)
    probe_plan.add_argument("--max-transfer-bytes", type=int, default=DEFAULT_GERRIT_TRANSFER_BYTES)
    probe_plan.set_defaults(func=command_probe_plan)

    return parser


def main() -> int:
    parser = build_parser()
    args = parser.parse_args()
    return int(args.func(args))


if __name__ == "__main__":
    sys.exit(main())
