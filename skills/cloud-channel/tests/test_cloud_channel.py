#!/usr/bin/env python3
"""云内外通道技能回归测试。"""

from __future__ import annotations

import hashlib
import json
import os
import subprocess
import sys
import tempfile
import unittest
import zipfile
from pathlib import Path


SKILL_ROOT = Path(__file__).resolve().parents[1]
SCRIPT = SKILL_ROOT / "scripts" / "cloud_channel.py"
DEFAULT_GERRIT_MESSAGE_BYTES = 3000000
TEST_COMMAND_TIMEOUT_SECONDS = 20


def run_command(*args: str, expect_success: bool = True) -> subprocess.CompletedProcess[str]:
    result = subprocess.run(
        [sys.executable, str(SCRIPT), *args],
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        check=False,
        timeout=TEST_COMMAND_TIMEOUT_SECONDS,
    )
    if expect_success and result.returncode != 0:
        raise AssertionError(f"command failed: {result.args}\nstdout={result.stdout}\nstderr={result.stderr}")
    if not expect_success and result.returncode == 0:
        raise AssertionError(f"command unexpectedly succeeded: {result.args}\nstdout={result.stdout}")
    return result


def run_command_in(
    work_dir: Path,
    *args: str,
    expect_success: bool = True,
) -> subprocess.CompletedProcess[str]:
    result = subprocess.run(
        [sys.executable, str(SCRIPT), *args],
        cwd=work_dir,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        check=False,
        timeout=TEST_COMMAND_TIMEOUT_SECONDS,
    )
    if expect_success and result.returncode != 0:
        raise AssertionError(f"command failed: {result.args}\nstdout={result.stdout}\nstderr={result.stderr}")
    if not expect_success and result.returncode == 0:
        raise AssertionError(f"command unexpectedly succeeded: {result.args}\nstdout={result.stdout}")
    return result


def sha256_file(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


class CloudChannelTests(unittest.TestCase):
    def test_detect_outputs_environment_report(self) -> None:
        result = run_command("detect", "--raw-json")
        report = json.loads(result.stdout)
        self.assertIn("environment", report)
        self.assertIn("confidence", report)
        self.assertIn("probes", report)

    def test_text_payload_round_trip(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            outbox = root / "outbox"
            inbox = root / "inbox"
            received = root / "received"
            outbox.mkdir()
            inbox.mkdir()

            run_command(
                "pack",
                "--direction",
                "cloud-inner-to-cloud-outer",
                "--sender",
                "cloud-inner",
                "--receiver",
                "cloud-outer",
                "--subject",
                "text test",
                "--body",
                "body",
                "--payload-type",
                "text",
                "--text",
                "hello cloud outer",
                "--out-dir",
                str(outbox),
                "--transport-hint",
                "gerrit-mail",
                "--skip-environment-guard",
            )
            for message_file in outbox.glob("*.json"):
                (inbox / message_file.name).write_bytes(message_file.read_bytes())

            run_command("unpack", "--input-dir", str(inbox), "--out-dir", str(received))
            payload_file = next(received.glob("*/payload/payload.txt"))
            self.assertEqual(payload_file.read_text(encoding="utf-8"), "hello cloud outer")
            index_records = [
                json.loads(line)
                for line in (received / "index.jsonl").read_text(encoding="utf-8").splitlines()
                if line.strip()
            ]
            self.assertEqual(index_records[0]["conversation_id"], index_records[0]["message_id"])
            self.assertEqual(index_records[0]["reply_to"], "")

    def test_inline_file_round_trip_preserves_hash(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            source = root / "task.md"
            source.write_bytes("cloud channel task\nline two".encode("utf-8"))
            outbox = root / "outbox"
            inbox = root / "inbox"
            received = root / "received"
            outbox.mkdir()
            inbox.mkdir()

            run_command(
                "pack",
                "--direction",
                "cloud-outer-to-cloud-inner",
                "--sender",
                "cloud-outer",
                "--receiver",
                "cloud-inner",
                "--subject",
                "file test",
                "--body",
                "body",
                "--payload-type",
                "inline-file",
                "--file",
                str(source),
                "--out-dir",
                str(outbox),
                "--transport-hint",
                "citrix-drive",
                "--skip-environment-guard",
            )
            for message_file in outbox.glob("*.json"):
                (inbox / message_file.name).write_bytes(message_file.read_bytes())

            run_command("unpack", "--input-dir", str(inbox), "--out-dir", str(received))
            restored = next(received.glob("*/payload/task.md"))
            self.assertEqual(sha256_file(source), sha256_file(restored))

    def test_inline_archive_chunk_round_trip_preserves_hash(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            random_file = root / "random.bin"
            random_file.write_bytes(os.urandom(20000))
            archive = root / "result.zip"
            with zipfile.ZipFile(archive, "w", compression=zipfile.ZIP_STORED) as zip_file:
                zip_file.write(random_file, arcname="random.bin")

            outbox = root / "outbox"
            inbox = root / "inbox"
            received = root / "received"
            outbox.mkdir()
            inbox.mkdir()

            run_command(
                "pack",
                "--direction",
                "cloud-inner-to-cloud-outer",
                "--sender",
                "cloud-inner",
                "--receiver",
                "cloud-outer",
                "--subject",
                "archive test",
                "--body",
                "body",
                "--payload-type",
                "inline-archive",
                "--file",
                str(archive),
                "--out-dir",
                str(outbox),
                "--chunk-chars",
                "1000",
                "--max-message-bytes",
                "2000",
                "--transport-hint",
                "gerrit-mail",
                "--skip-environment-guard",
            )
            chunk_files = list(outbox.glob("*.json"))
            self.assertGreaterEqual(len(chunk_files), 2)
            for message_file in chunk_files:
                (inbox / message_file.name).write_bytes(message_file.read_bytes())

            run_command("unpack", "--input-dir", str(inbox), "--out-dir", str(received))
            restored = next(received.glob("*/result.zip"))
            self.assertEqual(sha256_file(archive), sha256_file(restored))
            restored_payload = next(received.glob("*/payload/random.bin"))
            self.assertEqual(sha256_file(random_file), sha256_file(restored_payload))

    def test_default_compression_uses_single_archive_when_it_fits(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            outbox = root / "outbox"
            inbox = root / "inbox"
            received = root / "received"
            outbox.mkdir()
            inbox.mkdir()

            run_command(
                "pack",
                "--direction",
                "cloud-inner-to-cloud-outer",
                "--sender",
                "cloud-inner",
                "--receiver",
                "cloud-outer",
                "--subject",
                "compressed text",
                "--body",
                "body",
                "--payload-type",
                "text",
                "--text",
                "short text",
                "--out-dir",
                str(outbox),
                "--transport-hint",
                "gerrit-mail",
                "--skip-environment-guard",
            )
            message_file = next(outbox.glob("*.json"))
            message = json.loads(message_file.read_text(encoding="utf-8"))
            self.assertEqual(message["payload_type"], "inline-archive")
            self.assertLessEqual(len(message_file.read_bytes()), DEFAULT_GERRIT_MESSAGE_BYTES)
            (inbox / message_file.name).write_bytes(message_file.read_bytes())
            run_command("unpack", "--input-dir", str(inbox), "--out-dir", str(received))
            restored = next(received.glob("*/payload/payload.txt"))
            self.assertEqual(restored.read_text(encoding="utf-8"), "short text")

    def test_custom_gerrit_mail_chunk_messages_stay_under_size_limit(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            source = root / "payload.bin"
            source.write_bytes(os.urandom(20000))
            archive = root / "payload.zip"
            with zipfile.ZipFile(archive, "w", compression=zipfile.ZIP_STORED) as zip_file:
                zip_file.write(source, arcname="payload.bin")

            outbox = root / "outbox"
            outbox.mkdir()

            run_command(
                "pack",
                "--direction",
                "cloud-inner-to-cloud-outer",
                "--sender",
                "cloud-inner",
                "--receiver",
                "cloud-outer",
                "--subject",
                "size guard",
                "--body",
                "body",
                "--payload-type",
                "inline-archive",
                "--file",
                str(archive),
                "--out-dir",
                str(outbox),
                "--transport-hint",
                "gerrit-mail",
                "--max-message-bytes",
                "14336",
                "--chunk-chars",
                "8000",
                "--skip-environment-guard",
            )

            chunk_files = list(outbox.glob("*.json"))
            self.assertGreaterEqual(len(chunk_files), 2)
            for message_file in chunk_files:
                self.assertLessEqual(len(message_file.read_bytes()), 14336)

    def test_gerrit_mail_rejects_oversized_uncompressed_inline_text(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            result = run_command(
                "pack",
                "--direction",
                "cloud-inner-to-cloud-outer",
                "--sender",
                "cloud-inner",
                "--receiver",
                "cloud-outer",
                "--subject",
                "oversized text",
                "--body",
                "body",
                "--payload-type",
                "text",
                "--text",
                "x" * 15000,
                "--out-dir",
                temp_dir,
                "--transport-hint",
                "gerrit-mail",
                "--max-message-bytes",
                "1000",
                "--no-compress",
                "--skip-environment-guard",
                expect_success=False,
            )
            self.assertIn("超过当前传输大小上限", result.stderr)

    def test_default_high_compression_level_can_be_lowered(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            high_outbox = root / "high"
            low_outbox = root / "low"
            high_outbox.mkdir()
            low_outbox.mkdir()
            repeated_text = "X" * 20000

            common_args = [
                "pack",
                "--direction",
                "cloud-inner-to-cloud-outer",
                "--sender",
                "cloud-inner",
                "--receiver",
                "cloud-outer",
                "--subject",
                "compression level",
                "--body",
                "body",
                "--payload-type",
                "text",
                "--text",
                repeated_text,
                "--transport-hint",
                "gerrit-mail",
                "--skip-environment-guard",
            ]
            run_command(*common_args, "--out-dir", str(high_outbox))
            run_command(*common_args, "--out-dir", str(low_outbox), "--compression-level", "0")

            high_message = json.loads(next(high_outbox.glob("*.json")).read_text(encoding="utf-8"))
            low_message = json.loads(next(low_outbox.glob("*.json")).read_text(encoding="utf-8"))
            self.assertLess(high_message["integrity"]["payload_size"], low_message["integrity"]["payload_size"])

    def test_citrix_large_archive_uses_sidecar_and_round_trips(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            source = root / "large.bin"
            source.write_bytes(os.urandom(1200000))
            archive = root / "large.zip"
            with zipfile.ZipFile(archive, "w", compression=zipfile.ZIP_STORED) as zip_file:
                zip_file.write(source, arcname="large.bin")

            outbox = root / "outbox"
            inbox = root / "inbox"
            received = root / "received"
            outbox.mkdir()
            inbox.mkdir()

            run_command(
                "pack",
                "--direction",
                "cloud-outer-to-cloud-inner",
                "--sender",
                "cloud-outer",
                "--receiver",
                "cloud-inner",
                "--subject",
                "sidecar",
                "--body",
                "body",
                "--payload-type",
                "inline-archive",
                "--file",
                str(archive),
                "--out-dir",
                str(outbox),
                "--transport-hint",
                "citrix-drive",
                "--skip-environment-guard",
            )

            files = list(outbox.iterdir())
            json_files = [path for path in files if path.suffix == ".json"]
            sidecar_files = [path for path in files if path.suffix == ".zip"]
            self.assertEqual(len(json_files), 1)
            self.assertEqual(len(sidecar_files), 1)
            message = json.loads(json_files[0].read_text(encoding="utf-8"))
            self.assertEqual(message["payload_type"], "sidecar-archive")
            for path in files:
                (inbox / path.name).write_bytes(path.read_bytes())

            run_command("unpack", "--input-dir", str(inbox), "--out-dir", str(received))
            restored = next(received.glob("*/payload/large.bin"))
            self.assertEqual(sha256_file(source), sha256_file(restored))

    def test_folder_payload_round_trip_preserves_nested_files(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            transfer_root = root / "transfer-root"
            (transfer_root / "logs").mkdir(parents=True)
            (transfer_root / "reports").mkdir(parents=True)
            (transfer_root / "logs" / "build.log").write_text("build ok", encoding="utf-8")
            (transfer_root / "reports" / "summary.json").write_text('{"ok":true}', encoding="utf-8")
            outbox = root / "outbox"
            inbox = root / "inbox"
            received = root / "received"
            outbox.mkdir()
            inbox.mkdir()

            run_command(
                "pack",
                "--direction",
                "cloud-inner-to-cloud-outer",
                "--sender",
                "cloud-inner",
                "--receiver",
                "cloud-outer",
                "--subject",
                "folder",
                "--body",
                "body",
                "--file",
                str(transfer_root),
                "--out-dir",
                str(outbox),
                "--transport-hint",
                "gerrit-mail",
                "--skip-environment-guard",
            )
            for message_file in outbox.glob("*.json"):
                (inbox / message_file.name).write_bytes(message_file.read_bytes())

            run_command("unpack", "--input-dir", str(inbox), "--out-dir", str(received))
            self.assertEqual(next(received.glob("*/payload/logs/build.log")).read_text(encoding="utf-8"), "build ok")
            self.assertEqual(next(received.glob("*/payload/reports/summary.json")).read_text(encoding="utf-8"), '{"ok":true}')

    def test_auto_payload_type_uses_text_when_no_file_is_given(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            outbox = root / "outbox"
            inbox = root / "inbox"
            received = root / "received"
            outbox.mkdir()
            inbox.mkdir()

            run_command(
                "pack",
                "--direction",
                "cloud-inner-to-cloud-outer",
                "--sender",
                "cloud-inner",
                "--receiver",
                "cloud-outer",
                "--subject",
                "auto text",
                "--body",
                "auto body",
                "--text",
                "hello auto",
                "--out-dir",
                str(outbox),
                "--transport-hint",
                "gerrit-mail",
                "--skip-environment-guard",
            )
            for message_file in outbox.glob("*.json"):
                (inbox / message_file.name).write_bytes(message_file.read_bytes())

            run_command("unpack", "--input-dir", str(inbox), "--out-dir", str(received))
            self.assertEqual(next(received.glob("*/payload/payload.txt")).read_text(encoding="utf-8"), "hello auto")

    def test_pack_can_infer_most_fields_when_guard_is_skipped(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            transfer_root = root / "transfer-root"
            transfer_root.mkdir()
            (transfer_root / "note.txt").write_text("minimal", encoding="utf-8")
            outbox = root / "outbox"

            run_command(
                "pack",
                "--direction",
                "cloud-inner-to-cloud-outer",
                "--file",
                str(transfer_root),
                "--out-dir",
                str(outbox),
                "--skip-environment-guard",
            )

            message = json.loads(next(outbox.glob("*.json")).read_text(encoding="utf-8"))
            self.assertEqual(message["sender"], "cloud-inner")
            self.assertEqual(message["receiver"], "cloud-outer")
            self.assertEqual(message["delivery"]["transport_hint"], "gerrit-mail")
            self.assertEqual(message["subject"], "云内外通道消息")

    def test_pack_can_use_default_transfer_root_and_outbox(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            transfer_root = root / "transfer-root"
            transfer_root.mkdir()
            (transfer_root / "note.txt").write_text("default folder", encoding="utf-8")

            run_command_in(
                root,
                "pack",
                "--direction",
                "cloud-inner-to-cloud-outer",
                "--skip-environment-guard",
            )

            outbox = root / "outbox"
            message = json.loads(next(outbox.glob("*.json")).read_text(encoding="utf-8"))
            self.assertEqual(message["sender"], "cloud-inner")
            self.assertEqual(message["receiver"], "cloud-outer")
            self.assertEqual(message["delivery"]["transport_hint"], "gerrit-mail")
            self.assertEqual(message["payload"]["archive_name"], "transfer-root.zip")

    def test_async_reply_pairing_timeout_and_list_output(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            outbox = root / "outbox"
            received = root / "received"
            outbox.mkdir()

            run_command(
                "pack",
                "--direction",
                "cloud-inner-to-cloud-outer",
                "--sender",
                "cloud-inner",
                "--receiver",
                "cloud-outer",
                "--subject",
                "async request",
                "--body",
                "body",
                "--text",
                "please inspect",
                "--out-dir",
                str(outbox),
                "--transport-hint",
                "gerrit-mail",
                "--timeout-minutes",
                "1",
                "--skip-environment-guard",
            )
            request = json.loads(next(outbox.glob("*.json")).read_text(encoding="utf-8"))
            self.assertEqual(request["conversation_id"], request["message_id"])
            self.assertEqual(request["reply_to"], "")
            self.assertTrue(request["expect_reply_before"])

            reply_outbox = root / "reply-outbox"
            reply_outbox.mkdir()
            run_command(
                "pack",
                "--direction",
                "cloud-outer-to-cloud-inner",
                "--sender",
                "cloud-outer",
                "--receiver",
                "cloud-inner",
                "--subject",
                "async reply",
                "--body",
                "body",
                "--text",
                "started",
                "--reply-to",
                request["message_id"],
                "--out-dir",
                str(reply_outbox),
                "--transport-hint",
                "citrix-drive",
                "--skip-environment-guard",
            )
            reply = json.loads(next(reply_outbox.glob("*.json")).read_text(encoding="utf-8"))
            self.assertEqual(reply["reply_to"], request["message_id"])
            self.assertEqual(reply["conversation_id"], request["message_id"])

            run_command("unpack", "--input-dir", str(reply_outbox), "--out-dir", str(received))
            index_records = [
                json.loads(line)
                for line in (received / "index.jsonl").read_text(encoding="utf-8").splitlines()
                if line.strip()
            ]
            self.assertEqual(index_records[0]["reply_to"], request["message_id"])
            self.assertEqual(index_records[0]["conversation_id"], request["message_id"])

            expired_outbox = root / "expired-outbox"
            expired_outbox.mkdir()
            run_command(
                "pack",
                "--direction",
                "cloud-inner-to-cloud-outer",
                "--sender",
                "cloud-inner",
                "--receiver",
                "cloud-outer",
                "--subject",
                "expired",
                "--text",
                "timeout probe",
                "--message-id",
                "expired-message",
                "--conversation-id",
                "expired-conversation",
                "--timeout-minutes",
                "1",
                "--out-dir",
                str(expired_outbox),
                "--transport-hint",
                "gerrit-mail",
                "--skip-environment-guard",
            )
            expired_file = next(expired_outbox.glob("*.json"))
            expired_message = json.loads(expired_file.read_text(encoding="utf-8"))
            expired_message["expect_reply_before"] = "2000-01-01T00:00:00+00:00"
            expired_file.write_text(json.dumps(expired_message, ensure_ascii=False), encoding="utf-8")

            list_result = run_command("list", "--input-dir", str(expired_outbox))
            self.assertIn("expired-conversation", list_result.stdout)
            self.assertIn("timeout", list_result.stdout)

    def test_gerrit_mail_rejects_transfer_over_soft_limit(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            source = root / "payload.bin"
            source.write_bytes(os.urandom(20000))
            archive = root / "payload.zip"
            with zipfile.ZipFile(archive, "w", compression=zipfile.ZIP_STORED) as zip_file:
                zip_file.write(source, arcname="payload.bin")

            result = run_command(
                "pack",
                "--direction",
                "cloud-inner-to-cloud-outer",
                "--sender",
                "cloud-inner",
                "--receiver",
                "cloud-outer",
                "--subject",
                "transfer limit",
                "--body",
                "body",
                "--payload-type",
                "inline-archive",
                "--file",
                str(archive),
                "--out-dir",
                str(root / "outbox"),
                "--transport-hint",
                "gerrit-mail",
                "--max-transfer-bytes",
                "10000",
                "--skip-environment-guard",
                expect_success=False,
            )
            self.assertIn("超过当前传输累计软上限", result.stderr)

    def test_probe_plan_generates_capacity_test_artifacts(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            out_dir = root / "probe"
            run_command(
                "probe-plan",
                "--out-dir",
                str(out_dir),
                "--sizes",
                "1024,4096",
                "--change-ids",
                "523679",
                "--patch-sets",
                "1",
            )
            plan = json.loads((out_dir / "gerrit_capacity_probe_plan.json").read_text(encoding="utf-8"))
            self.assertEqual(plan["probe_type"], "gerrit_capacity_plan")
            self.assertEqual(plan["sizes"], [1024, 4096])
            self.assertTrue((out_dir / "sample_1024.json").exists())
            commands = (out_dir / "run_on_cloud_inner.md").read_text(encoding="utf-8")
            self.assertIn("换 patch set", commands)
            self.assertIn("换新 change", commands)

    def test_environment_guard_blocks_known_wrong_direction(self) -> None:
        detect_result = run_command("detect", "--raw-json")
        environment = json.loads(detect_result.stdout)["environment"]
        wrong_direction = None
        if environment == "cloud-outer-windows":
            wrong_direction = "cloud-inner-to-cloud-outer"
        elif environment in {"cloud-inner-linux", "cloud-inner-jump-windows"}:
            wrong_direction = "cloud-outer-to-cloud-inner"

        if wrong_direction is None:
            self.skipTest(f"environment guard has no deterministic wrong direction for {environment}")

        with tempfile.TemporaryDirectory() as temp_dir:
            result = run_command(
                "pack",
                "--direction",
                wrong_direction,
                "--sender",
                "wrong-side",
                "--receiver",
                "other-side",
                "--subject",
                "guard test",
                "--body",
                "body",
                "--payload-type",
                "text",
                "--text",
                "blocked",
                "--out-dir",
                temp_dir,
                "--transport-hint",
                "guard",
                expect_success=False,
            )
            self.assertIn("拒绝", result.stderr)

    def test_cloud_outer_simulates_cloud_inner_closed_loop(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            inner_outbox = root / "inner" / "outbox"
            inner_inbox = root / "inner" / "inbox"
            inner_received = root / "inner" / "received"
            simulated_gerrit_mail = root / "transport" / "gerrit-mail"
            outer_inbox = root / "outer" / "inbox"
            outer_received = root / "outer" / "received"
            outer_outbox = root / "outer" / "outbox"
            simulated_citrix_drive = root / "transport" / "citrix-drive"
            for folder in [
                inner_outbox,
                inner_inbox,
                inner_received,
                simulated_gerrit_mail,
                outer_inbox,
                outer_received,
                outer_outbox,
                simulated_citrix_drive,
            ]:
                folder.mkdir(parents=True)

            run_command(
                "pack",
                "--direction",
                "cloud-inner-to-cloud-outer",
                "--sender",
                "cloud-inner",
                "--receiver",
                "cloud-outer",
                "--subject",
                "closed loop request",
                "--body",
                "simulated cloud-inner message",
                "--payload-type",
                "text",
                "--text",
                "inner says hello",
                "--out-dir",
                str(inner_outbox),
                "--transport-hint",
                "gerrit-mail",
                "--skip-environment-guard",
            )

            for message_file in inner_outbox.glob("*.json"):
                (simulated_gerrit_mail / message_file.name).write_bytes(message_file.read_bytes())
            for message_file in simulated_gerrit_mail.glob("*.json"):
                (outer_inbox / message_file.name).write_bytes(message_file.read_bytes())

            run_command("unpack", "--input-dir", str(outer_inbox), "--out-dir", str(outer_received))
            outer_payload = next(outer_received.glob("*/payload/payload.txt"))
            self.assertEqual(outer_payload.read_text(encoding="utf-8"), "inner says hello")

            original_message = next(outer_inbox.glob("*.json"))
            original = json.loads(original_message.read_text(encoding="utf-8"))
            run_command(
                "pack",
                "--direction",
                "cloud-outer-to-cloud-inner",
                "--sender",
                "cloud-outer",
                "--receiver",
                "cloud-inner",
                "--subject",
                "closed loop response",
                "--body",
                "reply message",
                "--payload-type",
                "text",
                "--text",
                "outer received the request",
                "--reply-to",
                original["message_id"],
                "--conversation-id",
                original["conversation_id"],
                "--out-dir",
                str(outer_outbox),
                "--transport-hint",
                "citrix-drive",
                "--skip-environment-guard",
            )

            for message_file in outer_outbox.glob("*.json"):
                (simulated_citrix_drive / message_file.name).write_bytes(message_file.read_bytes())
            for message_file in simulated_citrix_drive.glob("*.json"):
                (inner_inbox / message_file.name).write_bytes(message_file.read_bytes())

            run_command("unpack", "--input-dir", str(inner_inbox), "--out-dir", str(inner_received))
            reply_file = next(inner_received.glob("*/message.json"))
            reply_message = json.loads(reply_file.read_text(encoding="utf-8"))
            self.assertEqual(reply_message["reply_to"], original["message_id"])
            self.assertEqual(reply_message["conversation_id"], original["conversation_id"])
            self.assertEqual(reply_message["direction"], "cloud-outer-to-cloud-inner")
            self.assertEqual(next(inner_received.glob("*/payload/payload.txt")).read_text(encoding="utf-8"), "outer received the request")


if __name__ == "__main__":
    unittest.main()
