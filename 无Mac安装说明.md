# 没有 Mac 时安装到 iPhone

当前工程是 SwiftUI 原生 iOS 工程。Windows 不能本地运行 Xcode，但可以使用 GitHub Actions 的 macOS 云端运行器完成编译检查。这个流程生成的是 Simulator 包，不能直接安装到真实 iPhone；真实设备还必须经过 Apple 签名。

## 推荐路径：云端构建 + TestFlight

1. 在 GitHub 新建一个仓库，把本目录中的全部文件上传到仓库根目录。不要上传 Apple ID、证书、`.p12` 或私钥文件。
2. 打开仓库的 `Actions`，运行 `Tongpin Campus iOS Build`。先确认 Simulator 构建通过。
3. 准备 Apple Developer 账号，并在 App Store Connect 创建应用，Bundle ID 使用 `com.tongpin.campus.ios`。
4. 使用 Codemagic、Bitrise、MacinCloud 或 GitHub Actions 的 macOS 环境完成签名归档。签名所需的证书、Provisioning Profile 和 App Store Connect API Key 只放在云服务的加密 Secrets 中。
5. 生成 IPA 后提交 TestFlight，在 iPhone 的 TestFlight 中安装。

## 临时个人安装

也可以把已经签名的 IPA 交给 AltStore 或 SideStore 安装。免费 Apple ID 签名通常有效期较短，需要定期重新签名；这条路径仍然需要先在云端完成 IPA 编译和签名。

## 本工程已准备好的部分

- `TongpinCampusIOS.xcodeproj` 已设置 iOS 16、Bundle ID 和 iPhone/iPad 设备族。
- `.github/workflows/ios-build.yml` 会在 macOS runner 上做无签名编译，结果作为 Actions artifact 保存。
- 代码没有登录、Firebase、云同步或外部服务密钥。

## 目前无法在本机完成的部分

当前 Windows 环境没有 `swift`、`xcodebuild` 和 Xcode，因此无法在这里验证 Xcode 编译、Apple 签名和真实 iPhone 安装。云端构建时如果出现 Swift 编译错误，应以 Actions 日志为准，再回到源码修复。
