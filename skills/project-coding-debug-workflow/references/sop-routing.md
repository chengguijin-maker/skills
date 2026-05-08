# SOP 路由参考

## 1. 设备调试线

使用场景：adb、remount、串口、升级、替换文件、开关日志、bugreport、pstore。

需要展开时读取 `device-debug-reference.md`。

先问：

1. 样机和版本是什么。
2. 是否允许设备写入。
3. 是否需要回滚方式。
4. 调试动作是临时验证还是正式修复的一部分。

## 2. 日志体系线

使用场景：logcat、kernel、DTV、Audio、HDMI、DP、Dolby、HUI、错误日志分析、日志上报。

需要展开时读取 `logging-reference.md`。

先问：

1. 问题模块和复现场景。
2. 采集窗口是复现前、复现中还是复现后。
3. 日志输出路径和空间是否足够。
4. 是否需要同步截图、视频或 trace。

## 3. 性能定位线

使用场景：CPU 高、内存异常、I/O 慢、UI 卡顿、帧冻结、播放 underflow、开机慢、网页渲染慢、弱网。

需要展开时读取 `performance-reference.md`。

先做分层：

1. 系统资源。
2. 进程。
3. 线程。
4. 调用栈。
5. 源码和配置。

常见工具：`top`、`dumpsys meminfo`、`dumpsys gfxinfo`、`simpleperf`、`perfetto`、`atrace`、`ftrace`、`perf bench`、`fio`。

## 4. 代码问题线

使用场景：编译链接失败、undefined symbol、dlopen failed、soname、NEEDED 依赖、so 替换、GDB、coredump、native 泄漏。

需要展开时读取 `code-issue-reference.md`。

先判断问题阶段：

1. 编译期：查构建文件、源文件是否参与编译、函数是否定义、vtable。
2. 加载期：查文件名、soname、NEEDED、运行路径、成组依赖。
3. 运行期：查 core、tombstone、GDB、symbols、库路径。
4. 内存期：做复现前后 heap 对比。

## 5. 构建分支线

使用场景：目标分支确认、IR、OTA、version.txt、MTK tag、构建参数、构建产物、Jenkins 只读确认、回灌。

需要展开时读取 `branch-build-reference.md`。

先确认：

1. 目标分支是 master、IR、OTA 还是新品鉴定。
2. 是否需要 RD、PL、主设计、hisense 窗口、科室负责人邮件确认。
3. `vendor/mediatek/tv/build/version/version.txt` 是否同步。
4. 构建产物和测试交接是否可追溯。

## 6. 正式手册线

使用场景：整理项目流程、阶段划分、SOP、检查表、技能化沉淀。

输出优先级：

1. 阶段定位和完整链路。
2. 输入、输出、角色、系统、证据。
3. 专项 SOP。
4. 证据矩阵 CSV。
5. 风险和待补证据。
