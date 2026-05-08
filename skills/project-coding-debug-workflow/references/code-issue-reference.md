# 代码问题参考

## 1. 使用边界

代码问题线用于编译链接失败、undefined symbol、dlopen failed、soname、NEEDED 依赖、so 替换、GDB、coredump、native 内存泄漏、Java 进程加载 lib 泄漏和目标文件分析。

先判断问题发生阶段：

1. 编译期。
2. 加载期。
3. 运行期。
4. 内存期。

## 2. 编译链接问题

优先检查：

1. 源文件是否参与编译。
2. 头文件声明是否有对应实现。
3. 函数签名、命名空间、const、重载是否一致。
4. vtable 报错时检查虚函数和析构函数。
5. 构建文件是否漏配源文件或依赖库。

常用只读分析：

```text
objdump -tT test.so | grep <symbol>
objdump -x test.so | grep NEED
nm libtest2.so | grep <symbol>
addr2line -f -e libtest2.so <address>
c++filt <mangled_name>
```

## 3. dlopen 和动态库问题

重点检查：

1. 报错实际找的是哪个库。
2. 文件名、soname、NEEDED 是否一致。
3. 依赖库是否成组缺失。
4. 目标库是否被打包到 apk 或系统路径。
5. 架构、权限、运行路径是否匹配。

常用只读分析：

```text
readelf -d libxxx.so
objdump -p app_or_so
objdump -x app_or_so | grep -is "needed"
```

## 4. so 临时替换

临时替换适合定位和验证，不等于正式修复。

替换前确认：

1. 包名、进程、安装路径。
2. 系统预置还是 data 安装。
3. so 架构和版本是否匹配。
4. 是否需要成组替换多个 so。
5. 权限、SELinux、回滚和 MD5 校验。

## 5. GDB 和 coredump

核心检查：

1. core、bin、so、symbols、源码版本必须匹配。
2. `bt` 只有地址或 `??` 时，先查库路径和符号，不急着分析源码。
3. 当前目录中的错误库可能导致 GDB 误加载。

常见命令：

```text
gdb <appName> <coreDump>
info sharedlibrary
set solib-search-path <LIB_PATH>
bt
info threads
thread <id>
```

## 6. native 内存泄漏

关键原则：

1. 使用 malloc_debug 或 heap dump 前确认 root、进程重启和 symbols。
2. 单次 dump 不能证明泄漏。
3. 必须做复现前后同场景对比。
4. symbols 目录结构要和设备实际路径一致。

## 7. 不要误用

1. 不要把 undefined symbol 直接归因于链接器。
2. 不要只替换一个 so 就认为依赖完整。
3. 不要在符号版本不一致时解释 GDB 堆栈。
4. 不要把临时替换写成正式入版。
5. 不要把一次内存快照写成泄漏根因。
