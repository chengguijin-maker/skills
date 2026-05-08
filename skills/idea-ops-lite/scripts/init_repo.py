#!/usr/bin/env python3
"""初始化单文件优先的轻量仓库骨架。"""

from __future__ import annotations

import argparse
from dataclasses import dataclass
from datetime import date
from pathlib import Path


@dataclass(frozen=True)
class InitConfig:
    root: Path
    title: str
    owner: str


def load_template(path: Path) -> str:
    return path.read_text(encoding="utf-8")


def render(template: str, mapping: dict[str, str]) -> str:
    result = template
    for key, value in mapping.items():
        result = result.replace(f"{{{{{key}}}}}", value)
    return result


def ensure_dir(path: Path) -> None:
    path.mkdir(parents=True, exist_ok=True)


def write_if_missing(path: Path, content: str) -> bool:
    if path.exists():
        return False
    path.write_text(content, encoding="utf-8")
    return True


def next_project_uid(root: Path, today: date) -> str:
    prefix = f"PRJ-{today.strftime('%Y%m%d')}-"
    candidates = [root / "WORK.md", root / "archive"]
    max_seq = 0

    for candidate in candidates:
        if candidate.is_file():
            text = candidate.read_text(encoding="utf-8", errors="ignore")
            for line in text.splitlines():
                if prefix in line:
                    tail = line.split(prefix, 1)[1][:3]
                    if tail.isdigit():
                        max_seq = max(max_seq, int(tail))
        elif candidate.is_dir():
            for file_path in candidate.rglob("*.md"):
                name = file_path.stem
                if name.startswith(prefix):
                    tail = name[len(prefix):len(prefix) + 3]
                    if tail.isdigit():
                        max_seq = max(max_seq, int(tail))

    return f"{prefix}{max_seq + 1:03d}"


def build_readme(title: str) -> str:
    return (
        f"# {title}\n\n"
        "当前主控文件：`WORK.md`\n\n"
        "Agent 约束入口：`AGENTS.md`\n"
    )


def init_repo(config: InitConfig) -> dict[str, Path]:
    today = date.today()
    root = config.root.resolve()

    ensure_dir(root)
    ensure_dir(root / "archive")
    ensure_dir(root / "scratch")
    ensure_dir(root / "src")
    ensure_dir(root / "tests")

    script_dir = Path(__file__).resolve().parent
    ref_dir = script_dir.parent / "references"

    work_template = load_template(ref_dir / "work-template.md")
    agents_template = load_template(ref_dir / "agents-template.md")

    project_uid = next_project_uid(root, today)
    replacements = {
        "PROJECT_TITLE": config.title,
        "PROJECT_UID": project_uid,
        "OWNER": config.owner or "",
        "REPO_PATH": root.as_posix(),
        "BRANCH": "",
        "WORKTREE_PATH": "",
        "TODAY": today.isoformat(),
    }

    created = {
        "readme": root / "README.md",
        "agents": root / "AGENTS.md",
        "work": root / "WORK.md",
    }

    write_if_missing(created["readme"], build_readme(config.title))
    write_if_missing(created["agents"], agents_template)
    write_if_missing(created["work"], render(work_template, replacements))

    write_if_missing(root / "archive" / ".gitkeep", "")
    write_if_missing(root / "scratch" / ".gitkeep", "")

    return created


def parse_args() -> InitConfig:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", required=True, help="目标仓库路径")
    parser.add_argument("--title", required=True, help="项目标题")
    parser.add_argument("--owner", default="", help="负责人")
    args = parser.parse_args()

    return InitConfig(
        root=Path(args.root),
        title=args.title.strip(),
        owner=args.owner.strip(),
    )


def main() -> None:
    config = parse_args()
    created = init_repo(config)
    print("已初始化轻量仓库骨架：")
    for name, path in created.items():
        print(f"- {name}: {path}")


if __name__ == "__main__":
    main()
