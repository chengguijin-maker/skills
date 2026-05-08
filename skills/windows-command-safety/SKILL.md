---
name: windows-command-safety
description: 在 Windows Terminal、PowerShell、cmd 或 Windows 开发环境中执行命令时，控制超时、输出量、递归范围、网络探测、循环和后台进程，避免终端卡死、长时间无响应或海量输出刷屏。用于运行测试、搜索文件、探测网络、查看进程、压缩文件、循环轮询、后台任务和任何可能阻塞 Windows 终端的命令。
---

# Windows 命令安全

## 核心原则

在 Windows Terminal 或 PowerShell 中执行命令时，默认使用有边界、可中断、输出受控的写法。

必须避免：

- 无超时网络探测。
- 无边界循环。
- 对整个用户目录做递归搜索。
- 输出完整超长进程命令行。
- 海量 JSON、CSV、日志直接刷屏。
- 长任务在前台无状态运行。

## 默认规则

- 网络探测不要默认使用 `Test-NetConnection -InformationLevel Detailed`，尤其是访问云内地址时；优先使用短超时 `.NET TcpClient`。
- 不递归扫描整个 `C:\Users\jinchenggui`，除非用户明确要求；优先限定到具体项目、技能目录或文档目录。
- `rg`、`Get-ChildItem -Recurse`、`Select-String` 必须限制路径、结果数量或输出到文件。
- 查看进程时不要直接输出完整 `CommandLine`，要截断或只输出摘要。
- 循环必须有明确次数、退出条件、短 sleep 和总体超时。
- 长任务使用后台作业或独立进程时，必须配套 `Wait-Job -Timeout`、状态检查和清理方式。
- 压缩、大文件处理、网络请求和测试命令都要设置合理超时；只有确认超时过短导致失败时再提高。
- 发现疑似残留进程时，先列 PID、启动时间、父进程和截断命令行，不要直接杀进程，除非用户明确同意。

## 推荐模板

短超时 TCP 探测：

```powershell
$client = [Net.Sockets.TcpClient]::new()
$task = $client.ConnectAsync("192.168.101.231", 29418)
if (-not $task.Wait(1500)) { "timeout" } else { "connected" }
$client.Dispose()
```

安全查看 PowerShell 进程：

```powershell
Get-CimInstance Win32_Process -Filter "name='powershell.exe'" |
  Select-Object ProcessId,CreationDate,@{n='Command';e={$_.CommandLine.Substring(0,[Math]::Min(160,$_.CommandLine.Length))}}
```

限制搜索范围和结果数量：

```powershell
rg -n "关键词" C:\Users\jinchenggui\.codex\skills C:\Users\jinchenggui\.qoder\skills -m 50
```

有边界循环：

```powershell
for ($i = 0; $i -lt 20; $i++) {
  # work
  Start-Sleep -Milliseconds 200
}
```

后台任务带超时：

```powershell
$job = Start-Job -ScriptBlock { pytest tests }
if (Wait-Job $job -Timeout 60) {
  Receive-Job $job
} else {
  Stop-Job $job
  "timeout"
}
Remove-Job $job -Force
```

## 何时读取参考

- 需要写复杂 PowerShell、循环、后台任务、网络探测或进程清理时，读取 `references/powershell-patterns.md`。
- 需要排查 Windows Terminal 卡死或残留进程时，读取 `references/troubleshooting.md`。
