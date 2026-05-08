# PowerShell 安全命令模式

## 网络探测

优先短超时 TCP 探测，不默认使用详细网络诊断。

```powershell
$client = [Net.Sockets.TcpClient]::new()
$task = $client.ConnectAsync("host", 80)
if (-not $task.Wait(1500)) { "timeout" } else { "connected" }
$client.Dispose()
```

只有需要诊断路由、DNS 或接口时，才使用 `Test-NetConnection`。

## 递归搜索

优先白名单路径：

```powershell
rg -n "pattern" .\src .\tests -m 100
```

避免：

```powershell
rg -n "pattern" C:\Users\jinchenggui
```

## 进程检查

输出摘要，不直接输出完整命令行：

```powershell
Get-CimInstance Win32_Process -Filter "name='powershell.exe'" |
  Select-Object ProcessId,ParentProcessId,CreationDate,@{n='Command';e={
    if ($_.CommandLine) { $_.CommandLine.Substring(0,[Math]::Min(160,$_.CommandLine.Length)) } else { "" }
  }}
```

## 循环

循环必须有边界：

```powershell
$deadline = (Get-Date).AddSeconds(30)
while ((Get-Date) -lt $deadline) {
  # work
  Start-Sleep -Milliseconds 200
}
```

## 输出控制

大输出写文件：

```powershell
some-command *> .\logs\command-output.txt
Get-Content .\logs\command-output.txt -Tail 80
```
