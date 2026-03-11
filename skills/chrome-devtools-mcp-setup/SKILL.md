---
name: chrome-devtools-mcp-setup
description: 在 Codex CLI 或本地 Codex 环境中安装、配置、修复 Chrome DevTools MCP。用于 Linux/Ubuntu 上首次安装 `chrome-devtools`、把配置收敛为标准 `npx` 方案、通过 `apt` 安装系统 `google-chrome-stable`、处理 `Could not find Google Chrome executable`、`Transport closed`、`ENOSPC`、`Could not find DevToolsActivePort` 等启动错误，或需要用真实 `codex exec` smoke test 验证浏览器 MCP 可用性的场景。
---

# Chrome DevTools MCP Setup

## Overview

将 Chrome DevTools MCP 的安装与修复收敛到一条标准路径：优先使用 `npx` 启动 MCP，优先使用 `apt` 安装系统 Chrome，优先用真实浏览器操作做 smoke test，而不是只看配置是否“像对的”。

## 默认策略

- 优先读取 `~/.codex/config.toml`，不要先猜问题。
- 优先使用 `command = "npx"`，不要把 `chrome-devtools-mcp` 绑死到某个 Node 安装路径。
- 优先固定包版本，例如 `chrome-devtools-mcp@0.20.0`，不要默认 `@latest`。
- 优先使用 `apt` 安装的 `google-chrome-stable`，不要默认用软链接、Puppeteer 下载浏览器或手工 `--executablePath`。
- 只有在用户明确要连接现有浏览器实例时才考虑 `--browserUrl` 或 `--autoConnect`。默认让 MCP 自己拉起浏览器。
- 如果根分区或 `/tmp` 空间不足，优先把 `TMPDIR` 放到 `/home/.../.cache/...`，不要继续把 profile、socket、日志写到已满的 `/tmp`。
- 最终一定要跑真实 smoke test，例如让 `chrome-devtools` 打开 `https://example.com` 并读取标题。

## 工作流

### 1. 读取现状

- 先检查 `~/.codex/config.toml` 中是否已经存在 `[mcp_servers.chrome-devtools]`。
- 再确认 `npx` 是否在当前环境可用：`command -v npx`。
- 再确认系统 Chrome 是否存在：`/usr/bin/google-chrome-stable --version` 或 `/opt/google/chrome/chrome --version`。
- 只有在需要更详细配置或错误对照时，再读取：
  - `references/codex-ubuntu.md`
  - `references/error-signatures.md`

### 2. 安装标准依赖

- 如果系统没有 Chrome，优先按 `references/codex-ubuntu.md` 中的 Google 官方 apt 源方式安装 `google-chrome-stable`。
- 如果此前为了救火装过全局 `chrome-devtools-mcp`、用户态浏览器、软链接或临时 profile，在切回标准 `npx` 方案后清理这些临时产物。
- 不要默认保留非标准软链接。

### 3. 写入最小配置

- 优先写最小可维护配置，不要先堆 `logFile`、`userDataDir`、`--executablePath`。
- 默认配置形态见 `references/codex-ubuntu.md`。
- 只有出现空间、权限、现有浏览器复用等具体问题时，才添加额外参数。

### 4. 处理常见异常

- 遇到 `Could not find Google Chrome executable`，先修系统 Chrome，再考虑 `--executablePath`。
- 遇到 `Transport closed`，先检查日志、根分区、`TMPDIR` 和 Chrome 可执行文件。
- 遇到 `ENOSPC`，先把临时目录挪到 `/home`，再重试。
- 遇到 `Could not find DevToolsActivePort`，确认是否误用了 `--autoConnect`；默认不要走这条链路。
- 具体错误对照见 `references/error-signatures.md`。

### 5. 做真实验证

- 先运行 `codex mcp get chrome-devtools`，确认 Codex 读到了预期配置。
- 再运行一条真实 smoke test，让新会话实际调用 MCP 打开网页并读取标题。
- 如果 `codex exec` 能成功打开 `https://example.com` 并返回 `Example Domain`，再认为配置完成。

## 清理原则

- 完成修复后，清理排查阶段的全局 npm 安装、临时日志、smoke profile 和用户态浏览器缓存。
- 保留当前运行真正需要的缓存目录即可，不要把临时排查产物长期留在系统里。

## 参考资料

- 需要标准 Ubuntu/Codex 安装步骤、配置片段、验证命令时，读取 `references/codex-ubuntu.md`。
- 需要按报错字符串定位问题时，读取 `references/error-signatures.md`。
