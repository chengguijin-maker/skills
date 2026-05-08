# Windows Terminal 卡顿排查

## 快速判断

1. 检查是否有长时间运行的 PowerShell、Python、node、rg、git、测试进程。
2. 检查是否有命令正在输出大量文本。
3. 检查是否有网络探测或外部请求在等待系统超时。
4. 检查是否有无界循环或后台任务没有清理。

## 安全列进程

```powershell
Get-Process |
  Where-Object { $_.ProcessName -match 'powershell|pwsh|python|node|rg|git' } |
  Select-Object Id,ProcessName,CPU,StartTime,Path
```

如果需要命令行，只输出截断摘要。

## 清理原则

- 不要直接杀所有 PowerShell。
- 先确认 PID、父进程、启动时间和命令摘要。
- 如果是用户交互终端，先询问。
- 如果是自己启动的后台任务，先正常停止，再强制清理。

## 常见高风险命令

- `Test-NetConnection ... -InformationLevel Detailed`
- `Get-ChildItem C:\Users\jinchenggui -Recurse`
- `rg ... C:\Users\jinchenggui`
- 无界 `while ($true)`
- 大文件 `Get-Content` 不加 `-Tail` 或不输出到文件
- 完整输出 `Win32_Process.CommandLine`
