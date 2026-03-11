#!/usr/bin/env python3
"""Install, inspect, and sync skills from the private repository."""

from __future__ import annotations

import argparse
import hashlib
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
from datetime import datetime, timezone
from urllib.parse import urlsplit, urlunsplit


DEFAULT_REPO_URL = "https://github.com/chengguijin-maker/skills.git"
DEFAULT_REF = "main"
MANAGER_DIRNAME = ".skills-manager"
MANIFEST_FILENAME = "installed.json"
CATALOG_RELATIVE_PATH = Path("catalog") / "skills.json"

AGENT_ROOTS = {
    "codex": Path.home() / ".codex" / "skills",
    "claude": Path.home() / ".claude" / "skills",
}


class ManagerError(RuntimeError):
    pass


def utc_now() -> str:
    return datetime.now(timezone.utc).isoformat().replace("+00:00", "Z")


def authenticated_repo_url(repo_url: str) -> str:
    token = os.environ.get("GITHUB_TOKEN") or os.environ.get("GH_TOKEN")
    if not token or not repo_url.startswith("https://"):
        return repo_url
    parts = urlsplit(repo_url)
    if "@" in parts.netloc:
        return repo_url
    netloc = f"x-access-token:{token}@{parts.netloc}"
    return urlunsplit((parts.scheme, netloc, parts.path, parts.query, parts.fragment))


def run_git(args: list[str], cwd: Path | None = None) -> str:
    result = subprocess.run(
        ["git", *args],
        cwd=str(cwd) if cwd else None,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True,
    )
    if result.returncode != 0:
        raise ManagerError(result.stderr.strip() or "git command failed")
    return result.stdout.strip()


def prepare_repo(repo_url: str, ref: str) -> tuple[Path, Path | None]:
    local_path = Path(repo_url).expanduser()
    if local_path.exists():
        return local_path.resolve(), None

    tmp_root = Path(tempfile.mkdtemp(prefix="skills-manager-"))
    repo_dir = tmp_root / "repo"
    run_git(["clone", "--depth", "1", "--branch", ref, authenticated_repo_url(repo_url), str(repo_dir)])
    return repo_dir, tmp_root


def load_catalog(repo_dir: Path) -> dict:
    catalog_path = repo_dir / CATALOG_RELATIVE_PATH
    if not catalog_path.exists():
        raise ManagerError(f"catalog file not found: {catalog_path}")
    return json.loads(catalog_path.read_text(encoding="utf-8-sig"))


def hash_directory(root: Path) -> str:
    if not root.exists():
        raise ManagerError(f"directory not found: {root}")
    digest = hashlib.sha256()
    for path in sorted(p for p in root.rglob("*") if p.is_file()):
        rel = path.relative_to(root).as_posix().encode("utf-8")
        digest.update(rel)
        digest.update(b"\0")
        digest.update(path.read_bytes())
        digest.update(b"\0")
    return digest.hexdigest()


def agent_roots(agent: str) -> dict[str, Path]:
    if agent == "both":
        return dict(AGENT_ROOTS)
    if agent not in AGENT_ROOTS:
        raise ManagerError(f"unsupported agent: {agent}")
    return {agent: AGENT_ROOTS[agent]}


def manifest_path(root: Path) -> Path:
    return root / MANAGER_DIRNAME / MANIFEST_FILENAME


def load_manifest(root: Path) -> dict:
    path = manifest_path(root)
    if not path.exists():
        return {"version": 1, "skills": {}}
    return json.loads(path.read_text(encoding="utf-8-sig"))


def save_manifest(root: Path, data: dict) -> None:
    path = manifest_path(root)
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(data, indent=2) + "\n", encoding="utf-8")


def backup_existing(target: Path, root: Path) -> None:
    if not target.exists():
        return
    backup_root = root / MANAGER_DIRNAME / "backups" / utc_now().replace(":", "-")
    backup_root.mkdir(parents=True, exist_ok=True)
    shutil.move(str(target), str(backup_root / target.name))


def copy_skill(repo_dir: Path, entry: dict, root: Path) -> None:
    source = repo_dir / entry["repo_path"]
    target = root / entry["name"]
    if not source.exists():
        raise ManagerError(f"skill path not found in repository: {source}")
    root.mkdir(parents=True, exist_ok=True)
    backup_existing(target, root)
    if target.exists():
        shutil.rmtree(target)
    shutil.copytree(source, target)


def update_manifest(root: Path, entry: dict, repo_url: str, ref: str) -> None:
    target = root / entry["name"]
    installed_hash = hash_directory(target)
    data = load_manifest(root)
    data["skills"][entry["name"]] = {
        "name": entry["name"],
        "repo_url": repo_url,
        "ref": ref,
        "repo_path": entry["repo_path"],
        "category": entry.get("category"),
        "tags": entry.get("tags", []),
        "source_type": entry.get("source_type"),
        "content_hash": entry["content_hash"],
        "catalog_hash": entry["content_hash"],
        "installed_hash": installed_hash,
        "installed_at": utc_now(),
    }
    save_manifest(root, data)


def find_entry(catalog: dict, skill_name: str) -> dict:
    for entry in catalog.get("skills", []):
        if entry["name"] == skill_name:
            return entry
    raise ManagerError(f"skill not found in catalog: {skill_name}")


def installed_skill_path(root: Path, skill_name: str) -> Path:
    return root / skill_name


def actual_installed_hash(root: Path, skill_name: str) -> str | None:
    target = installed_skill_path(root, skill_name)
    if not target.exists():
        return None
    return hash_directory(target)


def manifest_hash(installed: dict) -> str | None:
    return installed.get("installed_hash") or installed.get("catalog_hash") or installed.get("content_hash")


def skill_status(installed: dict, remote_entry: dict, root: Path) -> str:
    actual_hash = actual_installed_hash(root, installed["name"])
    if actual_hash is None:
        return "missing-install"

    remote_hash = remote_entry["content_hash"]
    expected_hash = manifest_hash(installed)

    if actual_hash == remote_hash:
        return "up-to-date"
    if expected_hash and actual_hash != expected_hash:
        if remote_hash != expected_hash:
            return "local-drift-and-update-available"
        return "local-drift"
    return "update-available"


def cmd_list(args: argparse.Namespace) -> int:
    repo_dir, cleanup_dir = prepare_repo(args.repo_url, args.ref)
    try:
        catalog = load_catalog(repo_dir)
        for entry in catalog.get("skills", []):
            category = entry.get("category", "uncategorized")
            print(f"{entry['name']} [{category}]")
            print(f"  {entry['description']}")
        return 0
    finally:
        if cleanup_dir:
            shutil.rmtree(cleanup_dir, ignore_errors=True)


def cmd_install(args: argparse.Namespace) -> int:
    repo_dir, cleanup_dir = prepare_repo(args.repo_url, args.ref)
    try:
        catalog = load_catalog(repo_dir)
        names = [entry["name"] for entry in catalog.get("skills", [])] if args.skill == ["*"] else args.skill
        for name in names:
            entry = find_entry(catalog, name)
            for _, root in agent_roots(args.agent).items():
                copy_skill(repo_dir, entry, root)
                update_manifest(root, entry, args.repo_url, args.ref)
                print(f"Installed {name} to {root}")
        return 0
    finally:
        if cleanup_dir:
            shutil.rmtree(cleanup_dir, ignore_errors=True)


def cmd_status(args: argparse.Namespace) -> int:
    repo_dir, cleanup_dir = prepare_repo(args.repo_url, args.ref)
    try:
        catalog = load_catalog(repo_dir)
        remote = {entry["name"]: entry for entry in catalog.get("skills", [])}
        for agent_name, root in agent_roots(args.agent).items():
            manifest = load_manifest(root)
            print(f"[{agent_name}] {root}")
            if not manifest["skills"]:
                print("  No managed skills")
                continue
            for name, installed in sorted(manifest["skills"].items()):
                remote_entry = remote.get(name)
                if not remote_entry:
                    print(f"  {name}: missing from catalog")
                    continue
                status = skill_status(installed, remote_entry, root)
                print(f"  {name}: {status}")
        return 0
    finally:
        if cleanup_dir:
            shutil.rmtree(cleanup_dir, ignore_errors=True)


def cmd_sync(args: argparse.Namespace) -> int:
    repo_dir, cleanup_dir = prepare_repo(args.repo_url, args.ref)
    try:
        catalog = load_catalog(repo_dir)
        remote = {entry["name"]: entry for entry in catalog.get("skills", [])}
        for _, root in agent_roots(args.agent).items():
            manifest = load_manifest(root)
            selected = manifest["skills"].keys() if args.skill == ["*"] else args.skill
            for name in selected:
                installed = manifest["skills"].get(name)
                if not installed:
                    continue
                remote_entry = remote.get(name)
                if not remote_entry:
                    print(f"Skipped {name}: no longer present in catalog")
                    continue
                status = skill_status(installed, remote_entry, root)
                if status == "up-to-date":
                    if manifest_hash(installed) != remote_entry["content_hash"]:
                        update_manifest(root, remote_entry, args.repo_url, args.ref)
                        print(f"Reconciled manifest for {name} in {root}")
                        continue
                    print(f"Up-to-date: {name}")
                    continue
                copy_skill(repo_dir, remote_entry, root)
                update_manifest(root, remote_entry, args.repo_url, args.ref)
                print(f"Synced {name} in {root}")
        return 0
    finally:
        if cleanup_dir:
            shutil.rmtree(cleanup_dir, ignore_errors=True)


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="Manage private skills repository installs")
    parser.add_argument("--repo-url", default=os.environ.get("SKILLS_MANAGER_REPO_URL", DEFAULT_REPO_URL))
    parser.add_argument("--ref", default=os.environ.get("SKILLS_MANAGER_REF", DEFAULT_REF))

    subparsers = parser.add_subparsers(dest="command", required=True)

    list_parser = subparsers.add_parser("list", help="List skills from the repository catalog")
    list_parser.set_defaults(func=cmd_list)

    install_parser = subparsers.add_parser("install", help="Install one or more skills")
    install_parser.add_argument("--skill", nargs="+", required=True, help="Skill names or * for all")
    install_parser.add_argument("--agent", choices=["codex", "claude", "both"], default="codex")
    install_parser.set_defaults(func=cmd_install)

    status_parser = subparsers.add_parser("status", help="Show managed skill status")
    status_parser.add_argument("--agent", choices=["codex", "claude", "both"], default="codex")
    status_parser.set_defaults(func=cmd_status)

    sync_parser = subparsers.add_parser("sync", help="Sync managed skills from repository catalog")
    sync_parser.add_argument("--skill", nargs="+", default=["*"], help="Skill names or * for all managed skills")
    sync_parser.add_argument("--agent", choices=["codex", "claude", "both"], default="codex")
    sync_parser.set_defaults(func=cmd_sync)

    return parser


def main() -> int:
    parser = build_parser()
    args = parser.parse_args()
    try:
        return args.func(args)
    except ManagerError as exc:
        print(f"Error: {exc}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
