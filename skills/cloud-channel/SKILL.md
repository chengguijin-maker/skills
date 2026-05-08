---
name: cloud-channel
description: 建立和使用云内与云外之间的基础通信通道。适用于通过云内到云外的 Gerrit 邮件路径，或云外到云内的 Citrix 映射路径，以默认自动参数交换文本或传输文件夹，并用 reply_to 与 conversation_id 做异步消息配对。本技能只负责通道层和消息配对，不负责飞书、JIRA、Confluence 等上层业务集成。
---

# 云内外通道

## 范围

使用本技能创建、查看、还原和确认云内与云外之间的通道消息。

不要用本技能实现上层业务集成。飞书、JIRA、Confluence、Coremail 分拣和报告生成都是通道消费者，不属于本通道。

## 通道模型

云内到云外：

1. 云内把要传的内容放进 `transfer-root`。
2. 云内使用 `scripts/cloud_channel.py pack --file transfer-root` 创建通道 JSON 文件。
3. 云内通过 Gerrit 评论发送 JSON 文件内容，优先使用现有 `gerrit-notify` 技能。
4. Gerrit 发送邮件通知。
5. 云外读取 Coremail 并提取通道 JSON。
6. 云外还原 JSON 载荷，并按需用 `--reply-to` 创建后续消息。

云外到云内：

1. 云外把要传的内容放进 `transfer-root`。
2. 云外使用 `scripts/cloud_channel.py pack --file transfer-root` 创建通道 JSON 文件。
3. 云外默认把文件写入 `D:\cloudshare\cloud-channel\outbox`。
4. Citrix 驱动器映射把文件暴露到跳板机。
5. 跳板机使用 SCP 把文件复制到云内 Linux 收件目录。
6. 云内还原 JSON 载荷，并按需通过 Gerrit 邮件回复。

## 载荷模型

通道统一按“一个传输文件夹”处理。无论是文本、单文件、多文件还是多文件夹，发送前都先放进 `transfer-root`，然后把这个文件夹压成一个 zip。通道只负责传这个 zip 和对应 JSON 清单。

默认自动项：

- 方向：按当前环境推断，云内默认为 `cloud-inner-to-cloud-outer`，云外默认为 `cloud-outer-to-cloud-inner`。
- 身份：按方向推断 `sender` 和 `receiver`。
- 传输方式：云内到云外默认 `gerrit-mail`，云外到云内默认 `citrix-drive`。
- 输出目录：`gerrit-mail` 默认 `./outbox`，`citrix-drive` 默认 `D:\cloudshare\cloud-channel\outbox`。
- 载荷类型：默认 `auto`，云内到云外压缩后走 JSON，云外到云内文本走 JSON、文件走旁路 payload 文件夹。
- 压缩级别：Gerrit 方向默认 `9`，Citrix/SCP 方向默认 `3`。
- 标题：未提供时默认 `云内外通道消息`。
- 异步配对：新消息自动创建 `conversation_id`，回复消息用 `--reply-to` 关联上一条消息。
- 超时提醒：`--timeout-minutes` 只写入期望回复时间，用于 `list` 提示，不自动失败。

日常使用只需要准备 `transfer-root`，再运行 `pack --file transfer-root`。如果当前目录已经有 `transfer-root`，也可以只运行 `pack`。只有自动环境识别失败、默认输出目录不符合当前机器、或需要探测 Gerrit 边界时，才显式配置参数。

保留的载荷类型：

- `auto`：默认入口。用户只提供 `--file transfer-root`，脚本自动选择后续载荷。
- `inline-archive`：默认载荷。传输文件夹压成 zip 后，Base64 放入 JSON。
- `inline-archive-chunk`：zip 放不进单条 JSON 时生成的分片消息。
- `sidecar-folder`：云外到云内的默认文件载荷。JSON 只放清单，文件原样放在同目录旁路 payload 文件夹。
- `sidecar-archive`：兼容旧的大包载荷。JSON 只放清单，zip 作为同目录旁路文件传递。

`text` 和 `inline-file` 只作为兼容入口，内部也会被整理成 zip，不作为推荐用法。新流程不要单独设计文本、单文件或多文件夹参数，统一先放进 `transfer-root`。

## 异步沟通

通道不等待某个问题处理完成。任何一方都可以继续发送新消息或回复旧消息，靠消息字段配对：

- `message_id`：当前消息编号。
- `conversation_id`：同一组沟通的会话编号。新消息默认等于自己的 `message_id`。
- `reply_to`：当前消息回复哪一条消息。
- `expect_reply_before`：希望对方回应的时间，只做提醒。

发起消息：

```bash
python3 scripts/cloud_channel.py pack --text "请检查构建失败" --timeout-minutes 30
```

回复消息：

```bash
python3 scripts/cloud_channel.py pack --reply-to <message_id> --text "已收到，开始处理"
```

带文件回复：

```bash
python3 scripts/cloud_channel.py pack --reply-to <message_id> --file transfer-root
```

使用 `--reply-to` 时，脚本会优先从 `received/index.jsonl` 或 `received/<message_id>/message.json` 自动继承原会话。找不到原消息时，才把 `conversation_id` 设为这个 `reply_to`。日常不要手写 `--conversation-id`。

谨慎使用内联载荷：

- 默认 `auto` 行为保持简单：Gerrit 方向把 zip 内联进 JSON；Citrix/SCP 方向带文件时走旁路 payload 文件夹。
- Gerrit 方向默认压缩级别为 `9`。
- Citrix/SCP 方向默认不压缩文件和文件夹，生成 `message.json + <message_id>_payload/`。
- `sidecar-folder` 不记录完整文件清单，不读文件内容，只记录 `file_count`、`directory_count`、`total_size` 和基于相对路径、大小、秒级修改时间的 `tree_fingerprint`。
- 复制 `sidecar-folder` 时必须保留文件修改时间，否则接收端校验会失败。
- 压缩后单条 JSON 不超过当前传输上限时，发送一条 `inline-archive`。
- 压缩后单条 JSON 超过当前传输上限时，自动拆成多个 `inline-archive-chunk`。
- 走 Gerrit 评论邮件时，单条通道 JSON 默认按 3,000,000 字节以内控制。
- 走 Gerrit 评论邮件时，同一批传输默认按 8,000,000 字节以内控制。
- 超过单批上限时不要内联，只发送清单或文件位置。

Gerrit 官方默认单条人工评论限制是 `change.commentSizeLimit = 16 KiB`，源码默认值是 `16 << 10`。官方默认累计限制是 `change.cumulativeCommentSizeLimit = 3 MiB`，源码默认值是 `3 << 20`。但当前环境在 2026-05-07 已实测单条 Gerrit comment 正文 `3,145,741` 字节成功，同一 change 会话内累计也已超过 6 MB。实际策略以本环境实测值为准，官方默认值只作为外部环境迁移时的保守参考。本地 `gerrit-notify` 文档中的 50 KB 是封装层旧策略，不是实际链路上限。

如果需要确认真实边界，读取 `references/gerrit-capacity-probe.md`，先用 `probe-plan` 生成探测计划，再在云内专用承载 change 上执行。必须覆盖单条限制、同一 change 累计限制、换 patch set、换 change 四类用例。

## 命令

Windows 和 Linux 都直接使用同一个 Python 脚本：

```bash
python3 scripts/cloud_channel.py detect
python3 scripts/cloud_channel.py doctor
python3 scripts/cloud_channel.py pack --help
python3 scripts/cloud_channel.py unpack --help
python3 scripts/cloud_channel.py list --help
python3 scripts/cloud_channel.py probe-plan --help
```

修改脚本后，或把技能复制到云内前，运行技能自带回归测试：

```bash
python3 tests/test_cloud_channel.py
```

测试中包含一套云外模拟云内的完整闭环：云内到云外，云外用 `reply_to` 回复，再回到云内。测试用本地目录模拟 Gerrit 邮件提取和 Citrix 驱动器映射，因此不需要真实访问云内网络，也能验证通道协议。

Windows 也可以使用 PowerShell 包装脚本：

```powershell
.\scripts\cloud_channel.ps1 pack --help
```

Linux 也可以使用 shell 包装脚本：

```bash
./scripts/cloud_channel.sh pack --help
```

## 云内到云外示例

发送前先运行：

```bash
python3 scripts/cloud_channel.py detect
python3 scripts/cloud_channel.py doctor
```

`pack` 命令会检查检测到的环境是否与请求方向匹配。如果不匹配，会拒绝创建消息。只有在人工确认当前主机和传输路径正确后，才能使用 `--skip-environment-guard`。

在云内创建消息：

```bash
python3 scripts/cloud_channel.py pack --file transfer-root
```

如果当前目录已经有 `transfer-root`，可以更短：

```bash
python3 scripts/cloud_channel.py pack
```

默认会自动推断方向、身份、传输方式、输出目录和压缩策略。若压缩后的 JSON 超过单条限制，脚本会输出多个分片 JSON。通过 Gerrit 通知按文件名顺序逐条发送生成的 JSON。云外提取全部 JSON 后运行：

```powershell
python .\scripts\cloud_channel.py unpack --input-dir .\inbox --out-dir .\received
```

## 云外到云内示例

发送前先运行：

```powershell
python .\scripts\cloud_channel.py detect
python .\scripts\cloud_channel.py doctor
```

在云外创建传输文件夹消息。先把要传的内容放进一个目录，再发送这个目录：

```powershell
python .\scripts\cloud_channel.py pack --file .\transfer-root
```

如果当前目录已经有 `transfer-root`，可以更短：

```powershell
python .\scripts\cloud_channel.py pack
```

默认会写入 `D:\cloudshare\cloud-channel\outbox`。Citrix 映射和 SCP 把 JSON 文件移动到云内 Linux 后，在云内还原：

```bash
python3 scripts/cloud_channel.py unpack --input-dir ./inbox --out-dir ./received
```

## 需要显式配置的情况

日常不要显式配置方向、身份、传输方式、载荷类型、压缩级别和分片大小。只在下面情况加参数：

- 当前环境识别为 `unknown` 或 `ambiguous-windows`：先运行 `detect` 和 `doctor`，人工确认后再加 `--direction` 和 `--skip-environment-guard`。
- 不使用默认发件目录：加 `--out-dir`。
- 需要更清晰的人类摘要：加 `--subject` 或 `--body`。
- 回复已有消息：加 `--reply-to <message_id>`。
- 需要提示对方回应时限：加 `--timeout-minutes <分钟>`。
- 只有本地索引缺失且必须挂到指定旧会话时，才手写 `--conversation-id`。
- Gerrit 容量边界已经重新实测：才调整 `--max-message-bytes`、`--max-transfer-bytes` 或 `--chunk-chars`。

## 参考资料

只在需要时读取：

- `references/message-format.md`：标准 JSON 结构和大小策略。
- `references/channel-boundary.md`：允许使用的传输边界。
- `references/workflows.md`：端到端命令示例。
- `references/gerrit-capacity-probe.md`：Gerrit 容量边界探测用例和判定规则。
