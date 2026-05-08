# Error Signatures

## `ls: cannot access .../bin/chrome-devtools-mcp`

含义：

- 配置把 `command` 写死到了某个不存在的 Node 全局 bin 路径。

处理：

- 优先改成 `command = "npx"`。
- 再把包版本固定在 `args` 中，例如 `chrome-devtools-mcp@0.20.0`。

## `Could not find Google Chrome executable for channel 'stable'`

含义：

- MCP 已经启动，但在真正拉起浏览器时找不到系统 Chrome。

处理：

- 优先通过 `apt` 安装 `google-chrome-stable`。
- 不要默认用软链接或下载用户态 Chrome 作为长期方案。
- 只有在必须临时绕过系统环境时，才短期使用 `--executablePath`。

## `Transport closed`

含义：

- MCP 子进程过早退出，通常不是“配置读不到”，而是运行时启动失败。

优先排查：

1. `npx` 是否可用：`command -v npx`
2. 系统 Chrome 是否可用：`/usr/bin/google-chrome-stable --version`
3. 根分区或 `/tmp` 是否写满：`df -h / /tmp /home`
4. 是否把日志或 profile 写到了没空间的位置

## `Error when opening/writing to log file: ENOSPC`

含义：

- 日志文件或 Chrome 运行时目录所在分区没有空间。

处理：

- 去掉临时 `--logFile`，或者把日志路径改到 `/home/.../.cache/...`。
- 给 MCP 设置 `TMPDIR=/home/<user>/.cache/chrome-devtools-mcp/tmp`。
- 清理旧日志、smoke profile 和中间文件后再重试。

## `Could not find DevToolsActivePort`

含义：

- 通常是 `--autoConnect` 链路有问题，不是标准“让 MCP 自己拉起浏览器”的问题。

处理：

- 默认不要用 `--autoConnect`。
- 如果用户明确要复用本地 Chrome，再检查 Chrome 144+、`chrome://inspect/#remote-debugging` 和远程调试开关。

## `curl 127.0.0.1:9222 refused`

含义：

- 只说明“远程调试端口浏览器”没有监听，不等于标准 `chrome-devtools-mcp` 配置一定坏了。

处理：

- 先分清楚当前方案是：
  - 让 MCP 自己拉起浏览器
  - 连接现有 `--browserUrl`
- 如果当前是标准 `npx ... --headless` 方案，可以不依赖 9222 端口。

## `codex mcp get chrome-devtools` 看起来正常，但工具调用还是失败

含义：

- 只能说明配置被 Codex 读到了，不能说明浏览器链路真的可用。

处理：

- 必须再跑真实 smoke test。
- 推荐直接用 `codex exec` 调用 MCP 打开网页并读取标题。

## 何时清理中间产物

在以下情况完成后，应清理排查阶段残留：

- 已经切回标准 `npx` 方案
- 已经安装系统 Chrome
- 已经通过真实 smoke test

优先清理：

- 全局 npm 安装的 `chrome-devtools-mcp`
- `/tmp/chrome-devtools-mcp*`
- smoke profile
- 用户态下载的 Chrome 缓存
- 为救火建立的软链接
