# 工作流

## 云内到云外传输文件夹

在云内运行：

```bash
python3 scripts/cloud_channel.py doctor
mkdir -p transfer-root
printf "构建通过\n" > transfer-root/result.txt
python3 scripts/cloud_channel.py pack --file transfer-root
```

默认会自动推断方向、身份、传输方式、输出目录和载荷策略。传输文件夹会先用 zip 最高压缩级别压缩。压缩后的单条 JSON 放得下时，只生成一个 `inline-archive` 文件；放不下时，自动生成多个 `inline-archive-chunk` 文件。使用 `gerrit-notify` 按文件名顺序发送生成的 JSON 文件。

云外提取 JSON 文件后运行：

```powershell
python .\scripts\cloud_channel.py unpack --input-dir .\inbox --out-dir .\received
```

需要回应时直接创建回复消息：

```powershell
python .\scripts\cloud_channel.py pack --reply-to <message_id> --text "已收到，开始处理"
```

## 云内到云外已有压缩包

在云内运行：

```bash
python3 scripts/cloud_channel.py doctor
mkdir -p transfer-root
cp result.zip transfer-root/
python3 scripts/cloud_channel.py pack --file transfer-root
```

不要为压缩包单独设计发送方式，仍然把它放进 `transfer-root`。脚本会先尝试生成单条 `inline-archive`，单条放不下时再分片。接收方必须收到全部分片后才能还原。走 Gerrit 评论邮件时，默认会把每条 JSON 控制在 3,000,000 字节以内，并把同一批传输控制在 8,000,000 字节以内；只有云内确认 Gerrit 配置变化后，才显式设置 `--max-message-bytes`、`--max-transfer-bytes` 和 `--chunk-chars`。

## 云外到云内

在云外运行：

```powershell
python .\scripts\cloud_channel.py doctor
python .\scripts\cloud_channel.py pack --file .\transfer-root
```

推荐先整理 `transfer-root` 文件夹，再发送该文件夹。默认输出到 `D:\cloudshare\cloud-channel\outbox`。大包会生成一个 JSON 清单和一个旁路 zip 文件。在跳板机上，把映射出来的发件目录文件复制到云内 Linux。然后运行：

```bash
python3 scripts/cloud_channel.py unpack --input-dir ./inbox --out-dir ./received
```

需要回应时直接创建回复消息：

```bash
python3 scripts/cloud_channel.py pack --reply-to <message_id> --text "已收到，开始处理"
```

## 自动失败时的最小补充参数

优先修复环境探测。只有人工确认当前机器确实处在正确位置时，才补充参数：

```bash
python3 scripts/cloud_channel.py pack --file transfer-root --direction cloud-inner-to-cloud-outer --skip-environment-guard
```

如果只是不想使用默认输出目录，只补 `--out-dir`：

```powershell
python .\scripts\cloud_channel.py pack --file .\transfer-root --out-dir .\outbox
```
