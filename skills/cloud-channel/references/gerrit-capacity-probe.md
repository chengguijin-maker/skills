# Gerrit 容量边界探测

## 目标

用专用承载 change 测出当前 Gerrit、`gerrit-notify`、邮件链路组合下的真实能力。

必须验证四件事：

- 单条评论最大可用大小。
- 同一 change 同一 patch set 的累计可用大小。
- 同一 change 换 patch set 后，累计是否仍然继承。
- 换新 change 后，累计是否重新开始。

## 探测原则

- 只在专用承载 change 上执行，不要使用真实业务评审。
- 探测内容只使用脚本生成的固定字节，不包含敏感信息。
- 每次发送间隔不少于 2 秒，避免邮件风暴。
- 一旦 Gerrit 返回累计超限，不要继续向同一个 change 重试。
- 每次失败必须记录 Gerrit REST 响应原文。

## 生成探测计划

在云外或云内都可以先生成无副作用计划：

```bash
python3 scripts/cloud_channel.py probe-plan \
  --out-dir ./cloud-channel-probe \
  --sizes 524288,1048576,2097152,3145728,4194304 \
  --change-ids 523679 523680 \
  --patch-sets 1 2
```

输出内容：

- `gerrit_capacity_probe_plan.json`：结构化测试计划。
- `sample_<size>.json`：每个输入大小对应的压缩后大小、单条 JSON 大小、是否需要分片。
- `run_on_cloud_inner.md`：云内执行清单。

## 判定规则

- 如果单条发送失败，且错误类似 comment size exceeds limit，说明触发单条限制。
- 如果小分片连续发送到后期失败，且错误类似 cumulative size，说明触发同一 change 累计限制。
- 如果换 patch set 后仍然失败，说明累计按 change 继承，patch set 不能清空容量。
- 如果换新 change 后恢复成功，说明新 change 可以作为新的承载通道。

## 输出结论

探测完成后，把结果写成以下字段：

```json
{
  "max_single_comment_bytes": 0,
  "max_batch_bytes_same_change": 0,
  "patchset_resets_cumulative_limit": false,
  "new_change_resets_cumulative_limit": true,
  "recommended_max_message_bytes": 3000000,
  "recommended_max_transfer_bytes": 8000000
}
```

当前环境在 2026-05-07 已实测单条 Gerrit comment 正文 `3,145,741` 字节成功，同一 change 会话内累计超过 6 MB。继续探测时优先验证 `4 MiB` 和更高边界。
