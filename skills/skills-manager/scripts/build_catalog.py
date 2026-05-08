#!/usr/bin/env python3
"""Build catalog/skills.json from catalog/sources.lock.json and skill contents."""

from __future__ import annotations

import argparse
import hashlib
import json
from datetime import datetime, timezone
from pathlib import Path
import re
import subprocess
import sys


FRONTMATTER_RE = re.compile(r"^---\n(.*?)\n---", re.DOTALL)
NAME_RE = re.compile(r"^name:\s*(.+)$", re.MULTILINE)
DESCRIPTION_RE = re.compile(r"^description:\s*(.+)$", re.MULTILINE)
IGNORED_PATH_PARTS = {"__pycache__"}
IGNORED_FILENAMES = {".DS_Store", "Thumbs.db"}
IGNORED_SUFFIXES = {".pyc", ".pyo"}
TEXT_SUFFIXES = {
    ".json",
    ".md",
    ".ps1",
    ".py",
    ".sh",
    ".toml",
    ".txt",
    ".yaml",
    ".yml",
}


def parse_frontmatter(skill_md: Path) -> tuple[str, str]:
    content = skill_md.read_text(encoding="utf-8")
    match = FRONTMATTER_RE.match(content)
    if not match:
        raise ValueError(f"No frontmatter found in {skill_md}")
    frontmatter = match.group(1)
    name_match = NAME_RE.search(frontmatter)
    desc_match = DESCRIPTION_RE.search(frontmatter)
    if not name_match or not desc_match:
        raise ValueError(f"Missing name/description in {skill_md}")
    name = name_match.group(1).strip().strip("'\"")
    description = desc_match.group(1).strip().strip("'\"")
    return name, description


def should_ignore_path(path: Path, root: Path) -> bool:
    rel = path.relative_to(root)
    if any(part in IGNORED_PATH_PARTS for part in rel.parts):
        return True
    if path.name in IGNORED_FILENAMES:
        return True
    if path.suffix in IGNORED_SUFFIXES:
        return True
    return False


def normalized_file_bytes(path: Path) -> bytes:
    data = path.read_bytes()
    if path.suffix in TEXT_SUFFIXES:
        return data.replace(b"\r\n", b"\n").replace(b"\r", b"\n")
    return data


def run_git(repo_root: Path, args: list[str]) -> bytes:
    result = subprocess.run(
        ["git", *args],
        cwd=str(repo_root),
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
    )
    if result.returncode != 0:
        raise ValueError(result.stderr.decode("utf-8", errors="replace").strip() or "git command failed")
    return result.stdout


def is_git_repo(repo_root: Path) -> bool:
    result = subprocess.run(
        ["git", "rev-parse", "--git-dir"],
        cwd=str(repo_root),
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
    )
    return result.returncode == 0


def hash_git_directory(repo_root: Path, repo_path: str) -> str:
    digest = hashlib.sha256()
    repo_path_prefix = repo_path.rstrip("/") + "/"
    output = run_git(repo_root, ["ls-files", "-z", "--", repo_path])
    files = [item for item in output.decode("utf-8").split("\0") if item]
    for rel_path in sorted(files):
        rel_posix = rel_path[len(repo_path_prefix) :] if rel_path.startswith(repo_path_prefix) else Path(rel_path).name
        suffix = Path(rel_path).suffix
        blob = run_git(repo_root, ["show", f"HEAD:{rel_path}"])
        if suffix in TEXT_SUFFIXES:
            blob = blob.replace(b"\r\n", b"\n").replace(b"\r", b"\n")
        digest.update(rel_posix.encode("utf-8"))
        digest.update(b"\0")
        digest.update(blob)
        digest.update(b"\0")
    return digest.hexdigest()


def hash_directory(root: Path) -> str:
    digest = hashlib.sha256()
    for path in sorted(p for p in root.rglob("*") if p.is_file() and not should_ignore_path(p, root)):
        rel = path.relative_to(root).as_posix().encode("utf-8")
        digest.update(rel)
        digest.update(b"\0")
        digest.update(normalized_file_bytes(path))
        digest.update(b"\0")
    return digest.hexdigest()


def build_catalog(repo_root: Path) -> dict:
    lock_path = repo_root / "catalog" / "sources.lock.json"
    lock_data = json.loads(lock_path.read_text(encoding="utf-8"))
    use_git_hash = is_git_repo(repo_root)
    skills = []
    for item in lock_data.get("skills", []):
        skill_dir = repo_root / item["repo_path"]
        skill_md = skill_dir / "SKILL.md"
        name, description = parse_frontmatter(skill_md)
        install_url = (
            f"https://github.com/chengguijin-maker/skills/tree/"
            f"{lock_data['repository']['default_ref']}/{item['repo_path']}"
        )
        entry = {
            "name": name,
            "description": description,
            "repo_path": item["repo_path"],
            "category": item["category"],
            "tags": item.get("tags", []),
            "source_type": item["source"]["type"],
            "install_url": install_url,
            "content_hash": hash_git_directory(repo_root, item["repo_path"]) if use_git_hash else hash_directory(skill_dir),
        }
        if item["source"]["type"] == "mirrored":
            entry["upstream"] = {
                "repo": item["source"]["upstream_repo"],
                "path": item["source"]["upstream_path"],
                "ref": item["source"].get("ref", "main"),
            }
        skills.append(entry)

    return {
        "version": lock_data.get("version", 1),
        "generated_at": datetime.now(timezone.utc).isoformat().replace("+00:00", "Z"),
        "repository": lock_data["repository"],
        "skills": sorted(skills, key=lambda value: value["name"]),
    }


def main() -> int:
    parser = argparse.ArgumentParser(description="Build catalog/skills.json")
    parser.add_argument("--repo-root", default=".", help="Repository root path")
    args = parser.parse_args()

    repo_root = Path(args.repo_root).resolve()
    catalog = build_catalog(repo_root)
    output_path = repo_root / "catalog" / "skills.json"
    output_path.write_text(json.dumps(catalog, indent=2) + "\n", encoding="utf-8")
    print(f"Wrote {output_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
