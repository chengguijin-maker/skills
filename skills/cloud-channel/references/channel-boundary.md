# 通道边界

本技能只定义通道层。

云内到云外：

1. 在云内创建一个或多个通道 JSON 文件。
2. 通过 Gerrit 评论或现有 `gerrit-notify` 技能发送。
3. Gerrit 发送邮件通知。
4. 云外通过 Coremail 读取邮件。
5. 提取通道 JSON，并还原或回执。

云外到云内：

1. 在云外创建一个或多个通道 JSON 文件。
2. 放入约定的 `D:\cloudshare` 发件目录。
3. 通过 Citrix 驱动器映射暴露给跳板机。
4. 复制到云内 Linux 收件目录。
5. 在云内还原或回执。

本技能不创建新的网络隧道，只使用现有允许路径：

- 云内到云外使用 Gerrit 评论加邮件通知。
- 云外到云内使用 Citrix 驱动器映射加 SCP。

不要在通道消息中放入密码、Cookie、私钥或长期有效令牌。

## 环境保护

发送前运行 `detect`。工具会把当前主机分类为：

- `cloud-outer-windows`：存在 `D:\cloudshare`，且不能直接访问 Gerrit SSH 的 Windows 主机。
- `cloud-inner-jump-windows`：可以访问 Gerrit SSH，且没有暴露 `D:\cloudshare` 的 Windows 主机。
- `cloud-inner-linux`：可以访问 Gerrit SSH 的 Linux 主机。
- `ambiguous-windows`：同时匹配云外和云内探测条件的 Windows 主机。
- `unknown`：没有匹配到受支持环境。

默认情况下，`pack` 会拒绝不安全方向：

- `cloud-inner-linux` 和 `cloud-inner-jump-windows` 只能发送 `cloud-inner-to-cloud-outer`。
- `cloud-outer-windows` 只能发送 `cloud-outer-to-cloud-inner`。
- `ambiguous-windows` 和 `unknown` 不能发送，除非使用 `--skip-environment-guard`。

只有在人工确认当前环境后，才能使用 `--skip-environment-guard`。优先修复环境探测或切换到正确主机运行。
