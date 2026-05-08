# Jira 和 Confluence 系统内容图谱第三版

生成时间: 2026-05-07 19:16:42
证据目录: C:\Users\jinchenggui\temp\2026-05-07T19-05-36-jira-confluence-system-map

## 纠偏说明
- 本图谱优先回答 Jira 和 Confluence 本身能提供什么, 有哪些内容域, 后续如何使用。
- 本地资料只作为查询种子, 不作为最终知识来源。
- Confluence 空间精确页面总数未在本轮完成统计, 因分页遍历成本较高, 本版使用空间清单和近期内容样本描述内容分布。

## 一、Jira 全局图谱
- 可见项目: 1126。
- 字段: 518, 其中大多数为自定义字段, 能支持机型, 验证人, 问题分类, 问题来源, 适用机芯, 评审任务ID, CI选择等细粒度检索。
- 问题类型: 73。常见类型包括 SW Bug, Sub Task, Requirement, TE Bug, Third-Part Bug, Review, Change 等。
- 状态: 50。近期样本中同时存在中文状态和英文状态, 例如 打开, Open, Closed, Resolved, Inprogress, 新需求, 审批中。
- 核心可探索对象: project, issue, field, issue type, status, priority, resolution, component, version, comment, attachment, remote link, transition。

### Jira 项目分类
- 其他: 564 个项目。样例: CLASS3D:3D眼镜项目(利尔达) | K120HZ:8K@120Hz输出显示的软件架构预研 | ACASM:A-CAS Module | ARM3:AR-M3分体眼镜 | ARTMODECBB:ArtMode_CBB | ATSC32024:ATSC3.0 2024新需求新特性开发 | ATSC3JH:ATSC3.0交互应用预研 | B2BRJLC:B2B软件量产后问题管理 | BL704L10Q2IR:BL704L-10-Q2IR | BUGREPORTSERVICE:BugreportService | CBBRECENT:Cbb_Recent | CH32V203:CH32V203
- MTK平台其他: 187 个项目。样例: MT9612STABILITY:9612项目性能稳定性研究 | ANDROIDDMTBFCSTJ:Android多媒体播放器测试套件 | LMTKMULSCR:linux MTK平台多屏互动服务整合内部项目 | MT5327K370HK:MT5327-K370HK | MT5327LASERTV:MT5327-LaserTV | MT53297900A:MT5329-7900A | XT910:MT5329-XT910 | MT5505K370:MT5505-K370 | MT5505L288:MT5505-L288 | MT5507:MT5507 | MT5507HOTEL:MT5507酒店机 | K690U:MT5508-K690U
- 系统和OS平台: 154 个项目。样例: OSANDROID4KNOW:4KNow应用Google+Play上线运营项目研究 | ANDROIDAVGCBB:Alexa语音控制_CBB | ANDROIDTVATSC3:Android ATSC 3.0预研 | ANDROIDTVDZSMSKZH:Android TV电子说明书客制化需求研究 | ANDROIDTVDZSMS:Android TV电子说明书软件和编辑平台研究 | ANDROIDIPV6:ANDROID-IPv6适配预研 | ANDROIDOTA:Android_OTA | ANDROIDQKSSP:AndroidQ快速适配预研 | ANDROIDEUDTVLOGO:AndroidTV EU DTV logo认证关键技术研究 | ANDROIDTVGINGAD:AndroidTV Ginga-D关键技术研究 | ANDROIDMIRACASTDLTP:AndroidTV Miracast多路投屏技术研究  | ANDROIDMUTI:Android多场景性能优化
- 产品项目: 64 个项目。样例: TVS2K2023:2023 TVS 2K平台先行开发 | DBJPZNTV:Driver Based日本智能电视预研项目 | HBBTVTA:HbbTV TA新特性开发预研 | HBBTV204:HbbTV2.0.4新规范预研 | HISIV811SJTV:HISI-V811社交电视 | HISIV620TVOS2:HISIV620_TVOS2.0 | JULYTV:July_TV | LIVETVCBB:LiveTV_CBB | MARPROJECT:MARS_Project | MARSU10:MARS_Project_U10 | TVMW:Middleware_TVMW_CBB | MSD3553ODM:MSD3553-ODM
- 测试质量和自动化: 29 个项目。样例: AUTOTESTPROJ:AutoTest系统整合项目 | DTVFITESTAUTO:DTV功能集成测试自动化预研项目 | DTVTEST2:DTV自动化测试工具二期 | HAYSYNCTEST:HAY_SYNCTEST | LANGOTEST:langoTest | LITAUTOTEST:LIT集成测试项目 | ODINUNITTEST:OdinUnitTest | PLTESTINGTOOL:PLTestingTool | PVRHUITESTCASE:PVR_HUI_TestCase | SITAUTOTEST:SIT自动化问题库 | TESTFRAMEWORK:Test Framework | TESTTE:Test TE Bug
- Amlogic和Android平台: 28 个项目。样例: A311D2DPYX:A311D2-带屏音响 | A311D2CKXZZHP:A311D2-触控旋转智慧屏 | AML950D5EUAUCOAMU9:AML950D5_EUAUCOAM_U9 | AMLT950XROKU:AML_T950X_ROKU | AMLT962XXTV:AML_T962X_XTV | AMLTR955ROKU:AML_TR955_ROKU | AMLTR964K8E:AML_TR964-K8E_ROKU | AMLTR985ROKU4K:AML_TR985_ROKU4K | AMLOGIC:AMLOGIC | AT950S:Amlogic-T950S | AMLOGICT962X2:Amlogic-T962X2 | AMLOGICT962X3ZJ0E:Amlogic-T962X3Z-J0E
- 应用和多媒体: 26 个项目。样例: DTVATSC30:ATSC3.0 二期技术预研 | DTVMETADATA:DTV-MetaData快速搜索研究 | DTVMARKET:DTV市场问题跟踪 | MEDIACENTERCBB:MediaCenter_CBB | MEDFW2:MediaFramework 2.0  | MIRACASTCBB:Miracast_CBB | MIRACASTKEEPONWIF:Miracast不断网投屏 | ODINOPAPP:Odin_OpApp | REMOTEAPP:Remote app | HIPLAYER:下一代媒体播放器HiPlayer | PANORAMAPLAYER:全景播放器CBB | DTVUNITY:全球化DTV协议栈融合预研
- AI和画质算法: 25 个项目。样例: AIVOICE731: 语音助手自升级项目 | AIEAGLE:AI Eagle项目 | AIMACEY:AI Macey | AIMACEYTEST:AI Macey_Test | AIAQ:AIAQ | AIMACEYMNG:AIMacey主干管理项目 | AIOD:AIOD | AIOT:AIOT | AIPQ2CBB:AIPQ2.0_CBB | AIPQ6886U4EU:AIPQ软件项目_6886U4 EU | AIPQ9602U5EU:AIPQ软件项目_9602EU | AIHYJY:AI会议纪要
- MT9603平台: 17 个项目。样例: MT9603:MT9603 | MT9603AMU7:MT9603_AM_U7 | MT9603AMU8:MT9603_AM_U8 | MZDTVTYXYZ:MT9603_AM_U8_AddDVB | MT9603AMU9:MT9603_AM_U9 | MT9603EUAUCOU7:MT9603_EUAUCO_U7 | MT9603EUAUCOU8:MT9603_EUAUCO_U8 | MT9603EUAUCOU9:MT9603_EUAUCO_U9 | MT9603GLOBU9P:MT9603_Global_U9Projector | MT9603GTV:MT9603_GTV | MT9603JPU7:MT9603_JP_U7 | MT9603JPU85:MT9603_JP_U85
- MT9618平台: 15 个项目。样例: MT9618EUAUCOU7:MT9618_EUAUCO_U7 | MT9618EUAUCOU8:MT9618_EUAUCO_U8 | MT9618EUAUCOU9:MT9618_EUAUCO_U9 | MT9618JPBD:MT9618_JP_BD | MT9618JPU7:MT9618_JP_U7 | MT9618JPU75:MT9618_JP_U75 | MT9618JPU8:MT9618_JP_U8 | MT9618JPU85HJ26:MT9618_JP_U85HJ26 | MT9618LOEWE:MT9618_Loewe | MT9618USGTV:MT9618_US_GTV | MT9618USGTVU:MT9618_US_GTVU | MT9618VIDAALASER:MT9618_VIDAA_LASER
- MT9655平台: 10 个项目。样例: MT9655:MT9655 | MT9655FTV:MT9655-FTV-HAYWARD | MT9655LASER:MT9655-LASER | MT9655MICROLED:MT9655-MicroLED | MT9655SX:MT9655-商显 | MT9655AMGTV:MT9655_AM_GTV | MT9655AMU9:MT9655_AM_U9 | MT9655EUAUCOU9:MT9655_EUAUCO_U9 | MT9655JPU9:MT9655_JP_U9 | MT9655MONITOR:MT9655_MONITOR
- 工具流程管理: 7 个项目。样例: ATSC3TOOLS:ATSC 3.0码流分析和编辑工具预研 | OCMM:ODIN CORE MEMORY MANAGEMENT | WEBDIALCONFMNG:Web应用开发平台建设-DIAL可配置化管理 | SWCLMNG:事务处理管理项目 | STREVIEW:测试一所评审专用 | SWMNG:软件重点管理项目 | CMOREVIEW:配置管理评审任务管理

### Jira 近期活跃内容域
- MT9655平台: 近期样本 225 条, 涉及 8 个项目, 样例项目: MT9655,MT9655LASER,MT9655JPU9,MT9655AMGTV,MT9655MONITOR,MT9655EUAUCOU9,MT9655SX,MT9655FTV
- 测试质量和自动化: 近期样本 127 条, 涉及 4 个项目, 样例项目: WSPECTEST,APPPSCI,LANGOTEST,NSPECTEST
- MTK平台其他: 近期样本 127 条, 涉及 8 个项目, 样例项目: MT9653,MT9653LASER,MT9602EUAUNASACOU9,MT8195CKXZZHPWX,MT9616AOSP,MT9679,MT8195CKXZZHP,MT9216GTVR50
- 产品项目: 近期样本 125 条, 涉及 7 个项目, 样例项目: MARPROJECT,TVNXREVIEW,OSTVQM,SOUNBARTVS,OSTVREVIEW,TVSPRE27,TVSKS
- Amlogic和Android平台: 近期样本 116 条, 涉及 9 个项目, 样例项目: AMLOGICA311D2,AT966D5,AT963D4,AML950D5EUAUCOAMU9,AMLOGICT963SX,ANS16AMLA311D2,A311D2CKXZZHP,AT950S,AMLOGICT963
- 应用和多媒体: 近期样本 70 条, 涉及 3 个项目, 样例项目: NXAPPUP,TVAPPS,HIPLAYER
- 系统和OS平台: 近期样本 67 条, 涉及 8 个项目, 样例项目: VIDAADEV,VIDAAPROJECT,VIDAACHAPP,SSXSHC,VIDAAWEBAPP,VIDAASYGS,VIDAAIPKUPDATE,VIDAATEST
- 其他: 近期样本 42 条, 涉及 12 个项目, 样例项目: SXYFW,NT72690AMU9,XYFENDA,YYZGGL,NT72690EUAUCOU9,SXXFJKXT,WYXMGL,MONITORA,K1,XRVS3Q01,YYGS,USNPS
- MT9618平台: 近期样本 42 条, 涉及 5 个项目, 样例项目: MT9618VIDAALASERU9,MT9618EUAUCOU9,MT9618USGTVU,MT9618USGTV,MT9618LOEWE
- MT9603平台: 近期样本 42 条, 涉及 6 个项目, 样例项目: MT9603GLOBU9P,MT9603JPU95,MT9603EUAUCOU9,MT9603FTV,MT9603,MT9603AMU9
- AI和画质算法: 近期样本 17 条, 涉及 1 个项目, 样例项目: AIVOICE731

### Jira 近期活跃项目 Top 30
- LANGOTEST: langoTest, 分类=测试质量和自动化, 近期样本=104
- MARPROJECT: MARS_Project, 分类=产品项目, 近期样本=85
- TVAPPS: 智能电视独立应用, 分类=应用和多媒体, 近期样本=65
- MT9655: MT9655, 分类=MT9655平台, 近期样本=60
- VIDAADEV: VIDAADEV, 分类=系统和OS平台, 近期样本=54
- MT9655LASER: MT9655-LASER, 分类=MT9655平台, 近期样本=52
- AT966D5: AmlogicT966D5_AOSP, 分类=Amlogic和Android平台, 近期样本=47
- MT9653: MT9653, 分类=MTK平台其他, 近期样本=45
- MT9655AMGTV: MT9655_AM_GTV, 分类=MT9655平台, 近期样本=43
- MT9653LASER: MT9653-LASER, 分类=MTK平台其他, 近期样本=36
- MT9655MONITOR: MT9655_MONITOR, 分类=MT9655平台, 近期样本=27
- OSTVREVIEW: 电视外销评审, 分类=产品项目, 近期样本=22
- MT9603EUAUCOU9: MT9603_EUAUCO_U9, 分类=MT9603平台, 近期样本=20
- MT9618VIDAALASERU9: MT9618_VIDAA_LASERU9, 分类=MT9618平台, 近期样本=20
- MT9655JPU9: MT9655_JP_U9, 分类=MT9655平台, 近期样本=19
- MT8195CKXZZHPWX: MT8195-触控旋转智慧屏-外销, 分类=MTK平台其他, 近期样本=18
- APPPSCI: 应用个人CI问题管理, 分类=测试质量和自动化, 近期样本=17
- AIVOICE731:  语音助手自升级项目, 分类=AI和画质算法, 近期样本=17
- AMLOGICA311D2: AMLOGICA311D2, 分类=Amlogic和Android平台, 近期样本=16
- MT9603JPU95: MT9603_JP_U95, 分类=MT9603平台, 近期样本=14
- MT9616AOSP: MT9616-AOSP, 分类=MTK平台其他, 近期样本=14
- NT72690EUAUCOU9: NT72690_EUAUCO_U9, 分类=其他, 近期样本=13
- AT963D4: Amlogic-T963D4, 分类=Amlogic和Android平台, 近期样本=11
- ANS16AMLA311D2: ANS16AMLA311D2, 分类=Amlogic和Android平台, 近期样本=11
- MT9655SX: MT9655-商显, 分类=MT9655平台, 近期样本=11
- AML950D5EUAUCOAMU9: AML950D5_EUAUCOAM_U9, 分类=Amlogic和Android平台, 近期样本=11
- MT9618USGTV: MT9618_US_GTV, 分类=MT9618平台, 近期样本=10
- YYZGGL: 应用所主干管理项目, 分类=其他, 近期样本=10
- TVNXREVIEW: 电视内销评审, 分类=产品项目, 近期样本=9
- MT9655EUAUCOU9: MT9655_EUAUCO_U9, 分类=MT9655平台, 近期样本=9

### Jira 近期状态分布
- 打开: 269
- Open: 231
- Closed: 173
- Resolved: 77
- Inprogress: 60
- 新需求: 51
- 审批中: 47
- 同意: 37
- 进行中: 15
- 拒绝: 10
- 审核中: 8
- Pending: 7
- 通过: 6
- 开发中: 3
- Reopened: 2
- 待基线: 1
- 存在问题: 1
- 待验证: 1
- 变更中: 1

### Jira 近期问题类型分布
- SW Bug: 293
- Sub Task: 247
- SCC Bug: 82
- Requirement: 75
- Pending/Defer subtask: 68
- TE Bug: 50
- Third-Part Bug: 30
- SE Bug: 28
- UE Bug: 26
- HW Bug: 22
- Task: 14
- SWD Bug: 13
- Requirement_Subtask: 9
- SI SubTask: 8
- Review Subtask: 7
- RD Bug: 6
- Change: 4
- Bug: 3
- Review: 3
- SI Task: 3
- Approval SubTask: 2
- DA BUG: 2
- Third-Part Task: 2
- Review-Bug: 1
- TTF Bug: 1
- HWD Bug: 1

## 二、Confluence 全局图谱
- 可见空间: 34。
- 近期内容样本: 100 条。
- 核心可探索对象: space, page, blogpost, attachment, comment, label, ancestor, child page, version, restriction。
- 核心能力: CQL 搜索, 页面正文读取, 空间列表读取, 页面层级读取, 附件列表读取, 版本信息读取, 标签读取。

### Confluence 空间分类
- 电视研发和项目信息: 11 个空间。样例: YYZX:产品线运营中心学习资料共享 | DZKJDSHWKF:产品线运营中心深圳研发部 | RBRJJSS:日本产品软件所 | DZKJSZDSPT:海外数字电视与浏览器开发所 | dshwrj:海外软件开发所 | DZKJZLCS:深研质量改善小组 | DSODMCPKFZL:电视ODM产品开发资料 | RUANJIANYANFA:电视产品软件所 | dsxmxx:电视产品项目信息 | DSWXXM:电视外销项目空间 | JQ:电视应用软件所
- 平台和系统软件: 7 个空间。样例: HWDBYYS:VIDAA系统研发部 | PTRJKFS:平台软件开发所 | JUOS:海信JuOS操作系统知识库 | XTXNSY:系统性能优化团队（深研） | NXPTRJ:系统软件开发所 | QDPTJSS:系统软件开发所666 | RJYFBGG:软件研发部公共空间
- 其他: 7 个空间。样例: test1:test1 | RZZGXM:员工管理 | SYSHARE:深研公共分享 | ZJJSWYH:电子信息集团研发中心专业技术委员会 | DMTYFCXLT:电子信息集团研发中心创新论坛 | YFZXJSSL:视像科技研发中心技术沙龙 | TYXX:通用信息
- 培训知识库: 5 个空间。样例: ZYJCKC:专业基础课程 | ZYTSKC:专业提升课程 | PXZL:培训资料 | ALK:案例库 | SYKS:深研知识分享体系
- 工具和平台: 1 个空间。样例: TOOLS:工具池
- 个人空间: 1 个空间。样例: ~fengmeimei:冯美美
- 海外和VIDAA: 1 个空间。样例: VIDAA:VIDAA
- 测试认证质量: 1 个空间。样例: CELAB:Certification Lab

### Confluence 空间清单
- [测试认证质量] CELAB: Certification Lab, 主页=Certification Lab 主页
- [电视研发和项目信息] dshwrj: 海外软件开发所, 主页=海外软件开发所 Home
- [电视研发和项目信息] DSODMCPKFZL: 电视ODM产品开发资料, 主页=电视ODM产品开发资料 主页
- [电视研发和项目信息] DSWXXM: 电视外销项目空间, 主页=电视外销项目空间 主页
- [电视研发和项目信息] dsxmxx: 电视产品项目信息, 主页=内销电视产品项目信息
- [电视研发和项目信息] DZKJDSHWKF: 产品线运营中心深圳研发部, 主页=产品线深圳研发中心电视开发所 主页
- [电视研发和项目信息] DZKJSZDSPT: 海外数字电视与浏览器开发所, 主页=海外数字电视与浏览器开发所 主页
- [电视研发和项目信息] DZKJZLCS: 深研质量改善小组, 主页=深研质量改善小组 主页
- [电视研发和项目信息] JQ: 电视应用软件所, 主页=电视应用软件所 Home
- [电视研发和项目信息] RBRJJSS: 日本产品软件所, 主页=日本产品软件所 主页
- [电视研发和项目信息] RUANJIANYANFA: 电视产品软件所, 主页=电视产品软件所 Home
- [电视研发和项目信息] YYZX: 产品线运营中心学习资料共享, 主页=电视产品线运营中心学习共享
- [个人空间] ~fengmeimei: 冯美美, 主页=冯美美的主页
- [工具和平台] TOOLS: 工具池, 主页=工具池
- [海外和VIDAA] VIDAA: VIDAA, 主页=VIDAA Main page
- [培训知识库] ALK: 案例库, 主页=案例库
- [培训知识库] PXZL: 培训资料, 主页=培训资料
- [培训知识库] SYKS: 深研知识分享体系, 主页=深研知识分享体系 主页
- [培训知识库] ZYJCKC: 专业基础课程, 主页=专业基础课程
- [培训知识库] ZYTSKC: 专业提升课程, 主页=专业提升课程
- [平台和系统软件] HWDBYYS: VIDAA系统研发部, 主页=VIDAA系统研发部 Home
- [平台和系统软件] JUOS: 海信JuOS操作系统知识库, 主页=海信JuOS操作系统知识库
- [平台和系统软件] NXPTRJ: 系统软件开发所, 主页=系统软件开发所 主页
- [平台和系统软件] PTRJKFS: 平台软件开发所, 主页=平台软件开发所 主页
- [平台和系统软件] QDPTJSS: 系统软件开发所666, 主页=系统软件开发所666 Home
- [平台和系统软件] RJYFBGG: 软件研发部公共空间, 主页=软件研发部公共空间 主页
- [平台和系统软件] XTXNSY: 系统性能优化团队（深研）, 主页=系统性能优化团队（深研） 主页
- [其他] DMTYFCXLT: 电子信息集团研发中心创新论坛, 主页=视像科技研发中心创新论坛 主页
- [其他] RZZGXM: 员工管理, 主页=员工管理
- [其他] SYSHARE: 深研公共分享, 主页=深圳研发中心服务平台
- [其他] test1: test1, 主页=test1 Home
- [其他] TYXX: 通用信息, 主页=通用信息 主页
- [其他] YFZXJSSL: 视像科技研发中心技术沙龙, 主页=视像科技研发中心技术沙龙 主页
- [其他] ZJJSWYH: 电子信息集团研发中心专业技术委员会, 主页=电子信息集团研发中心专业技术委员会

### Confluence 近期活跃空间
- DSWXXM: 电视外销项目空间, 近期样本=60, 样例: 0.3 MT9616项目计划和进度 | 主板及样机资源 | 9618D 订单互审备份--26年新品AP | AQ Proposals | 2027 REGZA SRS - Request#150: 音量調整UI改善 | PQ Proposals | SW開発定例（2026.05.13 ※※4.29, 5.6はGW期間中のためSkip※※） | SW開発定例（2026.04.22）
- DZKJSZDSPT: 海外数字电视与浏览器开发所, 近期样本=5, 样例: 项目管理 各技术评审点项目成员活动及目标 | 项目 Debug 提效 | AI 提效 | CAM卡外借登记 & USBCAM现存资产 | CAM卡和码流统计
- HWDBYYS: VIDAA系统研发部, 近期样本=5, 样例: aios | vendor module | biz component 功能梳理 | 72690-Flash_env（env_list.xml）融合排查 | ota_module -oem code
- JUOS: 海信JuOS操作系统知识库, 近期样本=4, 样例: 4.4 项目干系人 | 9616 & T966D5 | 3.4 项目干系人 | 2026年组件复用统计
- DZKJDSHWKF: 产品线运营中心深圳研发部, 近期样本=4, 样例: 软件烧写： | U9.6 | 8. 订单特殊主板料号 | AML950
- PTRJKFS: 平台软件开发所, 近期样本=3, 样例: 2026年任务书填报模板与自评要求 | Video业务总结 | 26年第二季度发票收集
- RBRJJSS: 日本产品软件所, 近期样本=3, 样例: 点检任务 | 4.3.2 图像模块配置及点检 | 01 Daily used note
- RUANJIANYANFA: 电视产品软件所, 近期样本=3, 样例: 26年5月7号无软件预警 | 2026年5月项目输入 | 2026/5/7 无软件日报反馈
- dsxmxx: 电视产品项目信息, 近期样本=3, 样例: 01  详细机型列表信息 | 开发调测&参考资料 | MT9653机型信息
- QDPTJSS: 系统软件开发所666, 近期样本=2, 样例: 编译服务器编译数据对比 | 2026 S104负载监控
- SYSHARE: 深研公共分享, 近期样本=2, 样例: 1.JHD425J1U51-T0L4_模组项目技术评审会议资料-鉴定评审_结构部分 | 4.模组鉴定评审阶段_JHD425J1U51-T0L4
- RJYFBGG: 软件研发部公共空间, 近期样本=2, 样例: 6 XTS典型问题 | 4 XTS测试流程
- NXPTRJ: 系统软件开发所, 近期样本=2, 样例: 外销离散遥控器 --- （lxh） | SRS 软件需求规格设计-OSD 悬浮图层分离显示功能
- dshwrj: 海外软件开发所, 近期样本=1, 样例: Android多语言适配规则及翻译工具分享
- YFZXJSSL: 视像科技研发中心技术沙龙, 近期样本=1, 样例: 第30期 奇点智能技术大会-智能体技术发展现状分享

## 三、Jira 和 Confluence 可以提供的探索价值
- Jira 更适合回答: 有哪些需求, 缺陷, 风险, 负责人, 状态, 评论讨论, 附件证据, 关闭原因, 修复版本, 关联问题。
- Confluence 更适合回答: 有哪些设计文档, 开发指南, 测试总结, 会议纪要, 周报, SOP, 页面层级, 附件资料。
- 两者组合后可以建立: 需求到设计, 缺陷到修复, 测试到结论, 项目到知识库的双向追踪。

## 四、后续使用策略
1. 先定位领域: Jira 项目族和 Confluence 空间族。
2. 再做宽查询: JQL 查 issue, CQL 查页面。
3. 再做结构化抓取: Jira 抓 fields, comments, attachments, remote links; Confluence 抓 body, attachments, children, ancestors, labels, version。
4. 最后生成证据索引: 每条结论都回链到 issue key 或 page id。

## 五、后续补强项
- 对重点 Jira 项目做 issue 总量和近 30 天活跃量统计。
- 对重点 Confluence 空间做页面树和附件树抓取。
- 建立 Jira issue key 到 Confluence page id 的自动抽取索引。
- 在这个系统图谱基础上再进入 2D转3D主题探索。
