# 性能定位参考

## 1. 使用边界

性能定位线用于 CPU 高、内存异常、I/O 慢、UI 卡顿、帧冻结、播放 underflow、开机慢、网页渲染慢、弱网、simpleperf、perfetto、atrace、ftrace 和基准测试。

先分类，再选工具。不要一开始就上重采样工具。

## 2. 分层方法

1. 系统层：CPU、内存、I/O、调度、网络、显示是否异常。
2. 进程层：哪个进程消耗资源或被阻塞。
3. 线程层：进程内部哪个线程异常。
4. 调用栈层：simpleperf、perfetto、atrace、ftrace、strace。
5. 源码和配置层：热点、路径或瓶颈被证据指向后再改代码。

## 3. 工具选择

| 问题 | 优先工具 |
| --- | --- |
| 进程 CPU 高 | `top`、`top -o %CPU` |
| 线程 CPU 高 | `top -H -p <pid>`、`ps -T -p <pid>` |
| native 或 Java 热点 | simpleperf |
| UI 卡顿和系统时间线 | perfetto、atrace、`dumpsys gfxinfo` |
| 内核函数和调度路径 | ftrace |
| 系统调用 | strace |
| 基准和压力 | perf bench、fio、stress-ng |
| 开机性能 | 固定起止点，多次取平均，保留视频 |
| 网页渲染 | Chrome Inspect Performance 和 Network |

## 4. 关键判断

1. FPS 高低不能直接判断卡顿，要看慢帧、冻结帧和帧耗时分布。
2. 一次 top 峰值不能直接写成根因。
3. 火焰图展示采样占比，不直接等同根因。
4. ftrace 和 atrace 会带来额外开销，必须限定范围和时间。
5. 压力测试和基准测试不能替代真实业务场景复现。
6. 性能优化必须有优化前后同场景对比。

## 5. 性能交接字段

| 字段 | 要求 |
| --- | --- |
| 问题类型 | CPU、内存、I/O、UI、播放、开机、网页、弱网 |
| 场景 | 输入源、片源、页面、网络、后台状态、动作 |
| 版本 | 样机、软件版本、分支、user 或 userdebug |
| 基础数据 | CPU、内存、I/O、进程、线程、时间点 |
| 深采证据 | simpleperf、perfetto、atrace、ftrace、gfxinfo |
| 对比 | 优化前后、不同版本、不同配置或不同机型 |
| 结论边界 | 事实、推断、待确认 |
