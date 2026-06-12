# 云台走地机 - iOS (Flutter)

> **全程 Windows 开发，零 Mac 编译 iOS IPA**

## 快速开始

### 第一步：上传代码到 GitHub

```bash
cd e:\dji-ios
git init
git add .
git commit -m "Initial: Flutter iOS project"
git remote add origin https://github.com/YOUR_USERNAME/gimbal-ctrl.git
git push -u origin main
```

### 第二步：Codemagic 免费编译（500分钟/月）

1. 打开 https://codemagic.io/register 注册账号（用 GitHub 登录）
2. 点击 **"Add app"** → 选择 `gimbal-ctrl` 仓库 → 点击 **Start your first build**
3. 选择 **iOS** → Build type: ** Simulator** → 点击 **Start new build**
4. 等待编译（约 10-15 分钟）

### 第三步：下载并签名 IPA

1. 构建完成后，点击 **Artifacts** 标签
2. 下载 `Runner.app`
3. 用 [爱打包](https://www.aipad.top) 或 [AltStore](https://altstore.io) 将 `.app` 转为 `.ipa`
4. 用**轻松签**（在 iPad 上）安装 `.ipa`

---

## iOS App 信息

| 配置项 | 值 |
|--------|-----|
| **App Name** | 云台走地机 |
| **Bundle ID** | com.dji.gimbalctrl |
| **App Key** | be9d6aefbe48fbd8d9c55e0d |
| **Category** | Film shooting |
| **SDK** | DJI Mobile SDK V4 (4.16.1) |
| **最低版本** | iOS 14.0 |
| **支持设备** | iPhone, iPad |

---

## 功能清单

- 全屏图传 + DJI Fly 风格 HUD
- 云台 Pitch/Yaw 独立控制（角度 + 速度模式）
- 遥控器摇杆实时映射到云台
- 虚拟遥感触控板
- 拍照 / 录像
- 相机曝光 / ISO / 白平衡设置
- 实时遥测（电量 / GPS / 高度 / 速度）
- 姿态指示器
- **iPad 横竖屏自适应布局**

---

## 技术架构

```
Flutter (Dart) ← 你在 Windows 上编辑这里
    ↓ Platform Channel (Method/Event Channel)
iOS Native (Swift)
    ↓ DJI Mobile SDK V4 (4.16.1)
    ↓ USB
DJI RC-N1 遥控器 → DJI Air 2
```

---

## 目录结构

```
dji-ios/
├── lib/
│   ├── main.dart                        # App 入口 + Provider 状态管理
│   ├── managers/
│   │   ├── sdk_manager.dart             # SDK 注册 + 产品连接
│   │   ├── gimbal_controller.dart       # 云台 Pitch/Yaw 控制
│   │   ├── rc_input_manager.dart        # 遥控器摇杆输入
│   │   ├── camera_controller.dart       # 拍照/录像/曝光设置
│   │   ├── telemetry_manager.dart       # 遥测数据（电量/GPS/高度）
│   │   └── video_manager.dart           # 视频流管理
│   ├── view_controllers/
│   │   └── main_screen.dart             # 主界面（LayoutBuilder 响应式）
│   └── widgets/
│       ├── status_bar.dart              # 顶部状态栏
│       ├── bottom_toolbar.dart          # 底部工具栏（拍照/录像/缩放）
│       ├── gimbal_control_panel.dart    # 云台控制滑出面板
│       ├── camera_settings_panel.dart   # 相机设置滑出面板
│       ├── attitude_indicator.dart       # 姿态球指示器
│       └── video_overlay.dart           # 十字线叠加层
├── ios/
│   ├── Runner/
│   │   ├── AppDelegate.swift            # DJI SDK 注册 + 方法通道处理
│   │   ├── RCEventStreamHandler.swift   # 遥控器 → Flutter EventChannel
│   │   ├── CameraEventStreamHandler.swift
│   │   ├── VideoEventStreamHandler.swift
│   │   ├── TelemetryEventStreamHandler.swift
│   │   ├── Info.plist                  # App Key + 权限 + USB配件协议
│   │   └── Runner.entitlements
│   └── Podfile                          # DJI-SDK-iOS ~> 4.16.1
├── codemagic.yaml                       # Codemagic CI 配置
├── pubspec.yaml                         # Flutter 依赖
└── README.md
```

---

## Codemagic 详细配置

### 注册 & 连接 GitHub

1. 访问 https://codemagic.io/register
2. 选择 **Sign up with GitHub**
3. 授权访问你的仓库（选 `gimbal-ctrl`）
4. 点击 **Add application**

### 创建应用

1. **Select repository**: `YOUR_USERNAME/gimbal-ctrl`
2. **Configure application**:
   - Branch: `main`
   - Project type: `Flutter`
3. **Build for**: `iOS`
4. **Build mode**: `debug` 或 `release`
5. 点击 **Finish** → 自动开始构建

### 下载构建产物

构建完成后：
1. 点击构建记录 → **Artifacts** 标签
2. 下载 `Runner.app`（或 `Runner.app.dSYM`）
3. 用爱打包/AltStore 打包成 `.ipa`
4. 轻松签安装到 iPad

### 手动触发构建

- 代码 push 后自动触发
- 或在 Codemagic 页面点击 **Start new build**

---

## 本地运行（需要 Mac）

```bash
# 安装 XcodeGen
brew install xcodegen

# 生成 Xcode 项目
cd ios
xcodegen generate
pod install
cd ..

# 运行
flutter run -d <device-id>
```

---

## 常见问题

### Q: Codemagic 构建失败
- 检查 `codemagic.yaml` 格式是否正确
- 确保 GitHub 仓库是公开的（免费版限制）
- 查看构建日志中的具体错误信息

### Q: 轻松签安装失败
- 确保 App Key 在 Info.plist 中正确配置
- 确保 Bundle ID 是你开发者账号下注册的那个
- iPad 需要开启"允许不受信任的应用程序"（设置 → 通用 → VPN与设备管理）

### Q: 无人机连不上
- iOS 必须通过 USB 连接 DJI RC-N1 遥控器
- iPad 需要支持 USB OTG（部分 iPad 需要用官方 Camera Connection Kit）
- 检查 DJI App Key 是否与 Bundle ID 匹配

---

## 参考资料

- [DJI Mobile SDK V4 iOS 文档](https://developer.dji.com/document/76942407-070b-4542-8042-204cfb169168)
- [Codemagic Flutter iOS 构建指南](https://docs.codemagic.io/flutter/building/build-for-ios/)
- [Flutter Platform Channels](https://docs.flutter.dev/development/platform-integration/platform-channels)
- [轻松签 iOS 签名工具](https://la.svg8.top)
