#!/usr/bin/env python3
import argparse
from pathlib import Path

PROBLEM_FRAME = """# 问题卡：{title}

## 1. 问题是什么

## 2. 谁在什么场景下遇到

## 3. 现在怎么凑合做

## 4. 真正需要解决的需求

## 5. 已知约束

## 6. 当前假设

## 7. 关键决策点（难以后改的）

## 8. V1 包含 / 不包含
- In:
- Out:

## 9. 成功标准
"""

SPEC_AND_TASKS = """# 规格与任务：{title}

## 1. 一句话范围

## 2. 主要用户流

## 3. 关键组件与边界（<=9）

## 4. 选定方案

## 5. 风险与依赖

## 6. 验证策略

## 7. Sprint 切片

## 8. 任务清单
| ID | 标题 | Depends On | Spec Ref | 描述 | Validation | Done Signal |
| --- | --- | --- | --- | --- | --- | --- |
"""

EXECUTION_PLAN = """# 执行编排：{title}

## 1. 执行摘要

## 2. 任务 DAG

## 3. 并行波次
- Wave 1:
- Wave 2:
- Wave 3:

## 4. 写入边界

## 5. Checkpoints
| Checkpoint | 完成输出 | 验证结果 | 当前阻塞 | 下一步 |
| --- | --- | --- | --- | --- |

## 6. 快测方案

## 7. 停止 / 缩 scope 条件
"""

CRITICAL_DECISIONS = """# 关键决策：{title}

## 1. 决策主题

## 2. 备选方案
- A:
- B:
- C:

## 3. 取舍

## 4. 最终决定

## 5. 为什么现在必须定

## 6. 哪些可以以后再定
"""


def write_if_missing(path: Path, content: str) -> None:
    if path.exists():
        return
    path.write_text(content, encoding="utf-8")


def main() -> int:
    parser = argparse.ArgumentParser(description="初始化轻量 idea->spec->execution 目录与模板文件")
    parser.add_argument("--topic", required=True, help="主题目录名，例如 user-login-improvement")
    parser.add_argument("--title", help="文档显示标题，默认与 topic 相同")
    parser.add_argument("--base-dir", default="docs/light-specs", help="输出根目录，默认 docs/light-specs")
    parser.add_argument("--include-optional", action="store_true", help="同时创建 execution-plan.md 和 critical-decisions.md")
    args = parser.parse_args()

    title = args.title or args.topic
    topic_dir = Path(args.base_dir) / args.topic
    topic_dir.mkdir(parents=True, exist_ok=True)

    write_if_missing(topic_dir / "problem-frame.md", PROBLEM_FRAME.format(title=title))
    write_if_missing(topic_dir / "spec-and-tasks.md", SPEC_AND_TASKS.format(title=title))

    if args.include_optional:
        write_if_missing(topic_dir / "execution-plan.md", EXECUTION_PLAN.format(title=title))
        write_if_missing(topic_dir / "critical-decisions.md", CRITICAL_DECISIONS.format(title=title))

    print(f"initialized: {topic_dir}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
