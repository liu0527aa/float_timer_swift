# FloatTimer

> 一个基于 iOS「画中画（Picture in Picture）」的悬浮毫秒时钟。即使 App 退到后台、或在其它应用（如刷视频）时，也能持续悬浮显示一个高精度的 6 位毫秒级时间戳。

## 简介

FloatTimer 利用 iOS 的**视频通话画中画（VideoCall PiP）**能力，把一个自绘的时钟视图以悬浮小窗的形式常驻在屏幕上。它主要解决两个工程问题：

1. **后台悬浮显示** —— 借助画中画能力，让时钟脱离 App 主界面独立悬浮，切到其它应用也不消失。
2. **高精度、防挂起的走时** —— 通过 NTP 网络时间校准 + 静音音频保活 + `CADisplayLink` 逐帧刷新，保证时间准确且后台不被系统挂起。

时钟显示的是 **Unix 毫秒时间戳的后 6 位**（`当前毫秒数 % 1000000`，前补零），常用于对时、演示、直播卡点等需要精确到毫秒的场景。

## 功能特性

- 🕐 **6 位毫秒时钟**：等宽字体逐帧刷新，数字不抖动。
- 📌 **画中画悬浮**：采用 `AVPictureInPictureVideoCallViewController`，不依赖视频播放，不黑屏。
- 🌐 **NTP 高精度校时**：使用 [Kronos](https://github.com/MobileNativeFoundation/Kronos) 从 NTP 服务器同步时间，失败时自动降级为系统时间。
- 🔋 **后台保活**：进入后台时循环播放一段静音音频（`mixWithOthers`），对抗系统挂起，且不打断用户正在听的音乐/视频。

## 运行环境

| 项目 | 要求 |
|------|------|
| Xcode | 16.0+ |
| iOS 部署目标 | 16.0+（画中画视频通话 API 需要 iOS 15+） |
| Swift | 5.0 |
| 依赖管理 | CocoaPods 1.12+ |
| 测试设备 | **真机**（模拟器对画中画/音频后台支持不完整，建议真机运行） |

## 快速开始

```bash
# 1. 克隆仓库
git clone https://github.com/<your-name>/FloatTimer.git
cd FloatTimer

# 2. 安装依赖（本仓库未提交 Pods/ 目录）
pod install

# 3. 打开 workspace（注意：不是 .xcodeproj）
open timer_swift.xcworkspace
```

在 Xcode 中：

1. 打开 `timer_swift.xcworkspace` 后，按下方 [配置签名（首次运行必做）](#配置签名首次运行必做) 完成一次性的本地签名设置。
2. 连接真机并运行。
3. 点击「启动 6 位毫秒时钟」按钮开启画中画，即可看到悬浮时钟。

## 配置签名（首次运行必做）

> ⚠️ **这是每位使用者在自己电脑上的一次性本地配置，与本仓库的代码无关。**
> 本仓库刻意**没有绑定任何开发者账号**（`DEVELOPMENT_TEAM` 为空，Bundle ID 为占位符 `com.yourname.floattimer`），
> 这样任何人 clone 下来都不会因为签名冲突而无法编译。你只需在本地把它改成你自己的即可。

### 操作步骤

1. 用 Xcode 打开 `timer_swift.xcworkspace`。
2. 左侧选中项目 → TARGETS 里选中 **`timer_swift`** → 打开顶部的 **Signing & Capabilities** 标签页。
3. 勾选 **Automatically manage signing**（自动管理签名，默认已勾选）。
4. 在 **Team** 下拉框中，选择你自己的 Apple 开发者账号（个人免费账号即可，无需付费账号）。
   - 如果下拉框是空的，点击 **Add an Account...** 用你的 Apple ID 登录即可。
5. 把 **Bundle Identifier** 从 `com.yourname.floattimer` 改成一个**全球唯一**的值，
   推荐格式为反向域名 + 项目名，例如 `com.zhangsan.floattimer`。
   （Xcode 要求 Bundle ID 全局唯一，占位符原样保留会导致签名失败。）
6. 连接 iPhone 真机，在 Xcode 顶部选择该设备，点击运行 ▶️。
7. 首次在真机运行时，iPhone 上会提示"不受信任的开发者"，
   前往 **设置 → 通用 → VPN与设备管理 → 开发者App**，信任你自己的证书即可。

### ⚠️ 请勿把本地签名改动提交回仓库

`DEVELOPMENT_TEAM` 和 `PRODUCT_BUNDLE_IDENTIFIER` 属于**你个人的本地配置**，
不应被提交并推送到公共仓库（否则会污染仓库、给下一个使用者造成签名冲突）。

如果你只是想跑通项目、并不打算贡献代码，可以让 Git 忽略对工程文件中这两项的改动：

```bash
# 让 Git 不再跟踪 project.pbxproj 的本地改动（仅影响你本地）
git update-index --skip-worktree timer_swift.xcodeproj/project.pbxproj

# 如需恢复跟踪：
# git update-index --no-skip-worktree timer_swift.xcodeproj/project.pbxproj
```

## 依赖说明

通过 CocoaPods 管理，见 [`podfile`](podfile)：

| 依赖 | 用途 |
|------|------|
| [SnapKit](https://github.com/SnapKit/SnapKit) | 声明式 Auto Layout 布局 |
| [Kronos](https://github.com/MobileNativeFoundation/Kronos) | NTP 网络时间同步，保证走时精度 |

## 项目结构

```
float_timer_swift/
├── podfile / Podfile.lock          # CocoaPods 依赖声明与锁定
├── timer_swift.xcworkspace         # 打开此文件进行开发
├── timer_swift.xcodeproj
└── timer_swift/
    ├── AppDelegate.swift           # App 生命周期入口
    ├── SceneDelegate.swift         # 前后台切换，触发保活音频
    ├── ViewController.swift        # 主控制器：PiP 配置、NTP 同步、时钟刷新逻辑
    ├── MCGCDTimer.swift            # GCD 定时器工具类
    ├── UIColor+Extension.swift     # 十六进制颜色扩展
    ├── BackgroundTaskManager/      # 静音音频后台保活
    │   ├── BackgroundTaskManager.swift
    │   └── slience.mp3
    ├── Assets.xcassets
    ├── Base.lproj/                 # Main / LaunchScreen storyboard
    └── Info.plist
```

## 核心实现原理

### 1. 画中画（VideoCall 模式）

苹果认可的画中画有两种：**视频播放** 与 **视频通话**。在 iOS 18 / Xcode 16 下，视频播放型画中画在启用相机后会被自动禁用，而视频通话型画中画则始终可用。因此本项目使用 `AVPictureInPictureController.ContentSource(activeVideoCallSourceView:contentViewController:)` 构建 PiP，把自绘时钟作为画中画内容，不依赖任何视频文件。

### 2. 高精度走时

- 使用 `Clock.now`（Kronos，NTP 校准后的时间）替代 `Date()`，消除设备本地时钟误差。
- 用 `CADisplayLink` 而非 `Timer` 逐帧刷新，并加入 `.common` RunLoop 模式，避免滚动等场景下停摆。

### 3. 后台保活

进入后台时（`SceneDelegate.sceneDidEnterBackground`）循环播放音量为 0 的静音音频，`AVAudioSession` 使用 `.playback + .mixWithOthers`，既能防止 App 被系统挂起，又不会打断用户正在播放的其它音频。

## 关于 App Store 审核

苹果可能会因为 App 使用了后台模式（`UIBackgroundModes: audio`）而要求说明用途。常见做法是在 App 内提供一个合理的音视频播放场景（例如内置教程视频播放器），使后台音频权限的使用具备正当理由。请根据你的实际上架需求评估合规性。

## License

本项目基于 [MIT License](LICENSE) 开源。

## 致谢

画中画视频通话相关实现参考了苹果官方文档 [Adopting Picture in Picture for video calls](https://developer.apple.com/documentation/avkit/adopting-picture-in-picture-for-video-calls)。
