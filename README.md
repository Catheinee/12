# 同频校园 iOS

当前版本只保留七个模块：今日、计划、课表、提醒、学业、任务、校园。

## 已完成

- 本地优先的数据存储，使用 `UserDefaults` 保存课程、任务、提醒、学业节点和校园信息。
- 课表支持本周/上一周/下一周切换。
- 课表支持时间轴与周网格两种视图。
- 支持粘贴 JSON/CSV，或从文件选择器导入课程。
- 任务和提醒支持在应用内新增，并可直接完成/取消完成。
- 所有页面使用统一的同频校园颜色、间距、圆角和触控尺寸。

## 打开方式

在 macOS 上用 Xcode 打开 `TongpinCampusIOS.xcodeproj`，选择 iOS Simulator 或真机后运行。工程最低部署版本为 iOS 16，Bundle Identifier 为 `com.tongpin.campus.ios`。

没有 Mac 时，可将本目录上传到 GitHub，运行 `.github/workflows/ios-build.yml` 做云端 Simulator 编译。真实 iPhone 安装需要 Apple Developer 签名，完整流程见 [无Mac安装说明.md](无Mac安装说明.md)。

## 导入格式

CSV 首行为可选表头，字段顺序如下：

`name,teacher,room,weekday,startHour,startMinute,durationMinutes,colorHex`

也支持 JSON 数组，字段名与 CSV 表头一致。`weekday` 为 1-7，分别代表周一到周日；颜色使用六位十六进制值，不带 `#`。

## 开源参考

课表的时间轴/网格交互参考 [blabla-yy/SwiftUITimeTable](https://github.com/blabla-yy/SwiftUITimeTable)，状态组织和学生功能范围参考 [Cookiezby/iOSDC2022-SwiftUI-TCA](https://github.com/Cookiezby/iOSDC2022-SwiftUI-TCA) 与 [negarprh/UniTrack](https://github.com/negarprh/UniTrack)。当前代码保留了本项目的数据模型和视觉令牌，没有引入这些仓库的登录、云同步或外部服务依赖。正式发布前请按 [GitHub项目调研.md](GitHub项目调研.md) 逐项核对第三方许可证与署名要求。
