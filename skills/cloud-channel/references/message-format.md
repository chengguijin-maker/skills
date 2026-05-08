# 消息格式

通道消息统一使用 JSON。所有文件保持 UTF-8 编码。

必需字段：

```json
{
  "channel_message_type": "cloud_channel_message",
  "version": "1.0",
  "message_id": "20260507T094000Z-a1b2c3d4",
  "transfer_id": "20260507T094000Z-a1b2c3d4",
  "direction": "cloud-inner-to-cloud-outer",
  "created_at": "2026-05-07T09:40:00+00:00",
  "sender": "cloud-inner",
  "receiver": "cloud-outer",
  "subject": "短标题",
  "body": "给人阅读的摘要",
  "ack_required": true,
  "payload_type": "text",
  "payload": {},
  "delivery": {
    "state": "created",
    "transport_hint": "gerrit-mail"
  }
}
```

载荷模型：

- 所有业务内容先整理成一个传输文件夹。
- 通道把这个文件夹压成一个 zip。
- 后续只传 zip 和 JSON 清单，不单独设计文本、单文件、多文件夹协议。
- 日常命令只需要 `pack --file transfer-root`。如果当前目录已经存在 `transfer-root`，可以省略 `--file`。
- 方向、身份、传输方式、输出目录、标题、载荷类型、压缩级别和分片策略都默认自动推断。
- 回执只需要 `ack --message ./inbox/message.json`，脚本按原消息自动反推回执方向和通道。

载荷类型：

- `auto`：默认入口。使用方只传 `--file transfer-root`，脚本自动选择实际载荷。
- `inline-archive`：默认载荷。传输文件夹压成 zip 后，把完整 zip 用 Base64 存放在 `payload.content`。
- `inline-archive-chunk`：Base64 压缩包分片，存放在 `payload.content`。
- `sidecar-archive`：JSON 存放旁路文件名和校验信息，压缩包作为同目录文件传递。主要用于 `citrix-drive`。
- `text` 和 `inline-file`：兼容入口，推荐新流程不要使用。
- `ack`：另一条消息的回执。

大小策略：

- 默认 auto 行为保持简单：`gerrit-mail` 把 zip 内联进 JSON，`citrix-drive` 的大 zip 走旁路文件。
- `gerrit-mail` 默认 zip 使用 `ZIP_DEFLATED` 且默认 `--compression-level 9`。
- `citrix-drive` 默认压缩级别为 `3`，超过 1 MB 的压缩包自动生成 `sidecar-archive`。
- 压缩级别可在 `0` 到 `9` 之间调整；`9` 压缩率最高，`0` 基本不压缩，只保留 zip 封装。
- 已经是压缩包或其他难压缩二进制时，也先放进 `transfer-root`，不要让使用方切换载荷类型。
- 压缩后单条 JSON 不超过当前传输上限时，发送一条 `inline-archive`。
- 压缩后单条 JSON 超过当前传输上限时，自动拆成多个 `inline-archive-chunk`。
- 走 Gerrit 评论邮件时，单条 JSON 默认按 3,000,000 字节以内控制。
- 走 Gerrit 评论邮件时，同一批传输默认按 8,000,000 字节以内控制。
- 超过单批上限时不要内联，只通过通道发送清单或文件位置。
- `inline-archive` 默认 `--chunk-chars 2800000`，每个分片都是一条独立 JSON 消息。
- `--chunk-chars` 必须能被 4 整除，因为 Base64 分片需要独立解码。
- `--transport-hint gerrit-mail` 默认启用 `--max-message-bytes 3000000` 的单条消息大小保护。确认真实 Gerrit 配置后可以显式调整。
- `--transport-hint gerrit-mail` 默认启用 `--max-transfer-bytes 8000000` 的单批累计软上限。接近该上限时应换新的 Gerrit 承载 change，或只发送清单和文件位置。

显式参数原则：

- 不要把 `direction`、`sender`、`receiver`、`transport_hint`、`payload_type` 当成日常配置。
- 环境自动识别失败时，先运行 `detect` 和 `doctor`；人工确认后才显式设置 `--direction` 和 `--skip-environment-guard`。
- 默认发件目录不合适时，只补 `--out-dir`。
- 重新探测过 Gerrit 容量后，才调整大小和分片参数。

分片发送和还原：

- 发送方运行 `pack` 后，按文件名顺序发送输出的 JSON 文件。
- 同一批分片共用 `message_id` 和 `transfer_id`。
- 每个分片有 `payload.chunk_index` 和 `payload.chunk_count`。
- 接收方必须收齐全部分片，再运行 `unpack`。
- `unpack` 会校验分片连续性、还原 Base64、校验压缩包 SHA256，并把 zip 解压到 `payload` 目录。
- `sidecar-archive` 还原时要求旁路文件和 JSON 在同一个 `input-dir`，校验 SHA256 后再解压。
- 如果缺少分片，接收方只回执缺失分片号，不要要求发送方重发整批，除非分片大量缺失。
- 真实 Gerrit 边界需要用 `probe-plan` 生成探测计划后在云内专用承载 change 上测试。测试说明见 `references/gerrit-capacity-probe.md`。

Gerrit 限制依据：

- Gerrit 官方配置项 `change.commentSizeLimit` 的默认值是 `16 KiB`，表示单条人工评论大小限制。
- Gerrit 源码 `CommentSizeValidator` 使用 `serverConfig.getInt("change", "commentSizeLimit", 16 << 10)`，确认默认值为 16384 字节。
- Gerrit 官方还有 `change.cumulativeCommentSizeLimit`，源码默认 `3 << 20`，限制同一个变更下人工评论和变更消息的累计大小。
- 当前环境在 2026-05-07 已实测单条 Gerrit comment 正文 `3,145,741` 字节成功，同一 change 会话内累计也已超过 6 MB。官方默认值只作为外部环境迁移时的保守参考。
- 本地 `gerrit-notify` 文档里的 50 KB 是本地封装旧策略，不是当前实际链路上限。实际发送时取服务器配置、封装层限制、邮件链路可承载大小三者中的最小值。

完整性校验：

- 每条载荷消息都包含 `integrity.payload_sha256`。
- 同一个压缩包的所有分片共用同一个 `payload_sha256`。
- 接收方必须校验哈希后再使用还原文件。
