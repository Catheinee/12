# Tongpin Campus iOS GitHub 项目调研

调研日期：2026-08-28

## 结论

没有找到一个同时满足“SwiftUI、持续维护、课表 + 校历 + 任务 + 本地提醒、可直接作为完整基础”的成熟仓库。因此本项目采用组合式学习：以课表布局项目为视觉参考，以状态管理项目为架构参考，以学生规划项目为功能清单参考，核心数据继续由本地 `UserDefaults` 管理，不引入登录、Firebase 或外部云同步。

## 候选项目

| 项目 | 可借鉴内容 | 可见维护信号 | 许可证/风险 | 结论 |
| --- | --- | --- | --- | --- |
| [blabla-yy/SwiftUITimeTable](https://github.com/blabla-yy/SwiftUITimeTable) | SwiftUI 的周网格、按时间计算课程高度和垂直偏移、横竖布局预览 | 17 stars、1 fork、11 commits、1 tag；搜索页显示 2024-08-15 更新 | 仓库有 LICENSE，但正式集成前仍需在 Xcode 项目中保留版权声明并核对许可证文本 | 采用“时间轴/网格”的布局思想，不直接复制源码 |
| [Cookiezby/iOSDC2022-SwiftUI-TCA](https://github.com/Cookiezby/iOSDC2022-SwiftUI-TCA) | SwiftUI + TCA 的状态组织、时间表与自定义日程、详情页 | 22 stars、3 forks、69 commits；README 标注 Xcode 14、iOS 16 | README 标注 MIT；项目主题是会议日程，不能直接充当校园数据模型 | 参考状态拆分和页面流转，当前实现保持轻量本地 Store |
| [saiankit/TimeMan](https://github.com/saiankit/TimeMan) | 课表的 Scroll View / Grid View 双视图、添加到 Apple Calendar、本地通知、首页显示下一节课 | 18 stars、3 forks；README 要求 macOS 10.15.7、Xcode 12，搜索页显示 2022-04-09 更新 | 老项目，API 和工程结构偏旧；许可证需单独核对 | 采用双视图、日历导出和通知的产品思路，不直接搬运旧工程 |
| [negarprh/UniTrack](https://github.com/negarprh/UniTrack) | 课程、周课表、作业/考试、学习记录、提醒、进度面板的功能组合 | 0 stars、2 forks、33 commits；仓库包含 Xcode 项目 | README 使用 MIT badge，但仓库页未见独立 LICENSE；依赖 Firebase Auth/Firestore，会引入登录和云端状态 | 参考功能范围；本项目明确不引入其登录与 Firebase |
| [arua-pimenta/Planner](https://github.com/arua-pimenta/Planner) | SwiftUI + SwiftData、学期追踪、成绩、出勤、考试节点、版本记录 | README 标注 v1.3.7、最新发布版本，并支持持续发布 | 面向 macOS 14 的医学学生规划器；0 stars、0 forks；不能直接当 iOS 基础 | 参考学业节点和版本化数据的产品方向，不直接集成 |

## 本项目的落地取舍

1. 课表支持本周/前后周切换，提供“时间轴”和“周网格”两种视觉视图。
2. 课程导入优先支持粘贴 JSON 或 CSV 文本，避免依赖外部登录和服务端。
3. 校历和课程放在同一套日期导航里，学业节点在课表下方和“学业”模块双向可见。
4. 任务、提醒、学业节点和校园信息都使用统一的本地 Store 与设计令牌。
5. 外部项目只作为学习参考；如果未来正式复制任何代码，必须先逐项核对 LICENSE、保留版权声明并做独立代码审查。

## 来源与限制

上述星标、fork、commit、更新时间和 README 功能描述来自 GitHub 仓库页/搜索页在调研日期的可见内容。GitHub 在连续搜索后触发过 secondary rate limit，因此没有把无法再次打开的搜索结果当作额外证据。星标不代表代码质量；本次选择优先考虑数据模型、视图形态、工程可迁移性和许可证清晰度。
