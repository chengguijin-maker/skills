# Codex Ubuntu Setup

## 标准安装路径

### 1. 安装系统 Chrome

优先使用 Google 官方 apt 源安装 `google-chrome-stable`，不要默认走软链接或用户态浏览器。

```bash
sudo install -d -m 0755 /usr/share/keyrings
curl -fsSL https://dl.google.com/linux/linux_signing_key.pub | gpg --dearmor | sudo tee /usr/share/keyrings/google-chrome.gpg >/dev/null
printf 'deb [arch=amd64 signed-by=/usr/share/keyrings/google-chrome.gpg] https://dl.google.com/linux/chrome/deb/ stable main\n' | sudo tee /etc/apt/sources.list.d/google-chrome.list >/dev/null
sudo apt-get update
sudo apt-get install -y google-chrome-stable
```

安装后验证：

```bash
/usr/bin/google-chrome-stable --version
```

### 2. 写入最小 Codex 配置

优先使用 `npx`，不要把 `chrome-devtools-mcp` 绑死到具体 Node 安装路径。

```toml
[mcp_servers.chrome-devtools]
command = "npx"
args = [
  "-y",
  "chrome-devtools-mcp@0.20.0",
  "--headless",
  "--no-usage-statistics",
]
startup_timeout_ms = 20_000
```

### 3. 根分区或 `/tmp` 空间不足时的处理

如果 `/` 或 `/tmp` 已满，不要再把 Chrome 临时目录写到 `/tmp`。改用 `/home` 下的缓存目录：

```bash
mkdir -p ~/.cache/chrome-devtools-mcp/tmp
```

```toml
[mcp_servers.chrome-devtools.env]
TMPDIR = "/home/<user>/.cache/chrome-devtools-mcp/tmp"
```

默认只在出现 `ENOSPC`、`Transport closed`、临时目录写失败时才加这一段。

### 4. 真实验证命令

先检查配置是否被 Codex 读到：

```bash
codex mcp get chrome-devtools
```

再做真实浏览器 smoke test：

```bash
codex exec --skip-git-repo-check -C <workdir> --color never \
  "Use the chrome-devtools MCP server to open https://example.com and report the page title. If the MCP server is unavailable or fails to start, say that explicitly and include the exact error."
```

期望结果：

- MCP 启动状态为 `ready`
- 能成功打开 `https://example.com`
- 能读到标题 `Example Domain`

### 5. 何时不要使用这些参数

- 不要默认加 `--browserUrl`，除非用户明确要求连接已有 Chrome。
- 不要默认加 `--autoConnect`，除非用户明确需要复用正在运行的本地 Chrome 144+。
- 不要默认加 `--executablePath`，除非系统 Chrome 路径异常且用户接受临时绕路。
- 不要默认保留 `--logFile`；只有在需要抓日志定位问题时再加。

### 6. 收尾清理

如果之前为了救火做过非标准处理，恢复到标准配置后可以清理：

```bash
npm uninstall -g chrome-devtools-mcp || true
find /tmp -maxdepth 1 \( -name 'chrome-devtools-mcp*' -o -name 'google-chrome-mcp-smoke.log' \) -delete
```

如果仓库里为了测试额外拉起过远程调试浏览器，还要清理对应的临时 profile 和日志目录。
