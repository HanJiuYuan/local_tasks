# LocalTasks

中文 | English

## 项目简介 / Overview

LocalTasks 是一个基于 Flutter 构建的本地优先（local-first）生活管理应用，提供日常待办、饮食记录、出发检查和健身助手四个模块。应用不依赖账号或云端服务，适合在设备本地快速记录和管理个人信息。

LocalTasks is a local-first life-management app built with Flutter. It includes four modules: daily tasks, nutrition tracking, departure checklists, and a workout assistant. The app does not require an account or cloud service, making it suitable for quick, on-device personal tracking.

> [!NOTE]
> 当前只有日常待办和出发检查会持久化到本地数据库；饮食记录、健身档案和训练历史目前仅在当前应用会话中保存。详见[数据与隐私 / Data and privacy](#数据与隐私--data-and-privacy)。
>
> Only daily tasks and departure checklists are currently persisted locally. Nutrition entries, workout profiles, and workout history are kept for the current app session only. See [Data and privacy](#数据与隐私--data-and-privacy) for details.

## 功能 / Features

### 日常待办 / Daily tasks

- 创建、完成和删除任务。
- 为任务添加标签。
- 设置日期和时间提醒；支持系统本地通知。
- 未完成任务在应用启动时重新安排提醒，完成或删除任务后会取消提醒。
- 任务数据保存在 SQLite 数据库中。

- Create, complete, and delete tasks.
- Add tags to tasks.
- Set date and time reminders with system local notifications.
- Pending reminders are rescheduled when the app starts; completing or deleting a task cancels its reminder.
- Task data is stored in a local SQLite database.

### 饮食记录 / Nutrition tracking

- 按早餐、午餐、晚餐和加餐记录食物。
- 提供主食、蛋白质、奶豆类、蔬菜、水果、坚果油脂和饮品分类。
- 支持从内置常见食物库中选择食物，并按照克数估算热量、蛋白质、碳水和脂肪。
- 显示当天摄入总量及各餐记录，并支持删除记录。
- 营养值来自内置的每 100 克数据，属于估算值，不替代专业营养建议。

- Record breakfast, lunch, dinner, and snacks.
- Browse staple foods, protein, dairy and soy, vegetables, fruits, nuts and oils, and beverages.
- Select foods from the bundled food list and estimate calories, protein, carbohydrates, and fat from the entered weight.
- View daily totals and meal entries, and delete entries when needed.
- Nutrition values are bundled per-100-gram estimates and are not a substitute for professional dietary advice.

### 出发检查 / Departure checklist

- 首次使用时自动创建常用检查项，例如牙刷、手机、钱包/身份证和门窗检查。
- 勾选或取消检查项。
- 添加自定义检查项。
- 删除检查项，或一键重置全部完成状态。
- 检查项和完成状态保存在 SQLite 数据库中。

- Seed a default checklist on first use, including items such as a toothbrush, phone, wallet/ID, and doors/windows.
- Check and uncheck items.
- Add custom checklist items.
- Delete items or reset all completion states at once.
- Checklist items and their completion states are stored in SQLite.

### 健身助手 / Workout assistant

- 填写体重、身高、体脂率、训练天数和训练经验。
- 根据身体数据和训练经验估算建议起始重量。
- 按胸、背、肩、腿、手臂和核心浏览快捷动作，也支持自重动作。
- 添加自定义动作，调整重量、组数、次数和组间休息时间。
- 按“选择动作 → 训练准备 → 当前动作 → 完成动作 → 组间休息 → 今日总结”的流程完成训练。
- 每组可记录 RIR（预留次数），训练结束后根据平均 RIR 给出下一次重量建议，并以 2.5 kg 为调整粒度。
- 支持训练提示音开关、训练容量、完成组数、训练时长和当前会话内的历史数据查看。
- 重量估算只用于制定保守的起始计划，不代表最大力量或安全上限；请根据实际动作质量和身体状态调整。

- Enter body weight, height, body-fat percentage, training days, and experience level.
- Estimate conservative starting weights from body data and training experience.
- Browse quick exercises by chest, back, shoulders, legs, arms, and core, including bodyweight exercises.
- Add custom exercises and adjust weight, sets, reps, and rest time.
- Follow the flow: select exercises → training preparation → current exercise → complete set → rest → daily summary.
- Record RIR (reps in reserve) for each set. After training, the app suggests a next-session weight from average RIR in 2.5 kg increments.
- Toggle rest countdown sounds and review volume, completed sets, duration, and session history.
- Weight estimates are conservative starting points, not one-rep-max or safety limits. Adjust them based on form and current condition.

## 技术栈 / Tech stack

- Flutter / Dart
- Material 3 UI
- `sqflite`、`path`、`path_provider`：本地 SQLite 数据存储 / local SQLite storage
- `flutter_local_notifications`、`flutter_timezone`、`timezone`：定时通知和时区处理 / scheduled notifications and timezone handling
- `cupertino_icons`：iOS 风格图标 / Cupertino-style icons

## 项目结构 / Project structure

```text
lib/
├── main.dart                         # 应用入口 / app entry point
└── widget/
    ├── app/app_shell.dart             # 底部导航和页面容器 / navigation shell
    ├── home/                          # 日常待办 / daily tasks
    ├── nutrition/                     # 饮食记录 / nutrition tracking
    ├── departure/                     # 出发检查 / departure checklist
    └── workout/                       # 健身助手 / workout assistant
```

## 运行环境 / Requirements

中文：

- Flutter SDK，Dart SDK 版本需满足 `pubspec.yaml` 中的 `^3.7.2`。
- Android 或 iOS 开发环境；项目已包含 `android/` 和 `ios/` 平台目录。
- 在 iOS 真机或模拟器上运行时，需要使用 Xcode；在 Android 上运行时，需要使用 Android SDK 和可用的模拟器或设备。

English:

- Flutter SDK with a Dart SDK version compatible with `^3.7.2` in `pubspec.yaml`.
- An Android or iOS development environment; both `android/` and `ios/` platform directories are included.
- Xcode is required for iOS devices or simulators. Android requires the Android SDK and an available emulator or device.

## 快速开始 / Quick start

```bash
flutter pub get
flutter run
```

中文：如需检查代码，可以运行 `flutter analyze`；如需构建 Android 调试包，可以运行 `flutter build apk --debug`。首次使用提醒功能时，请在系统弹窗中允许通知权限。

English: Run `flutter analyze` to check the code. To build an Android debug APK, run `flutter build apk --debug`. When using reminders for the first time, allow notification permissions in the system prompt.

## GitHub 开源审计 / GitHub open-source audit

### 可以提交 / Safe to commit

中文：在确认代码、图标和其他资源均由你拥有或具有相应授权的前提下，以下内容可以提交：

- `lib/`、`test/` 和项目配置源码。
- `android/`、`ios/` 中的原生项目文件，以及 `Podfile` 和 `Podfile.lock`。
- `pubspec.yaml`、`pubspec.lock`、`analysis_options.yaml`、README 和许可证文件。
- 应用自己的图标、启动图和其他资源。

English: Assuming that you own or are authorized to distribute the source, icons, and other assets, the following are safe to commit:

- `lib/`, `test/`, and project configuration source files.
- Native project files under `android/` and `ios/`, including `Podfile` and `Podfile.lock`.
- `pubspec.yaml`, `pubspec.lock`, `analysis_options.yaml`, the README, and license files.
- Your own app icons, launch images, and other assets.

### 不要提交 / Do not commit

中文：以下文件包含本机路径、构建缓存或本地凭据，应留在开发机上：

- `android/local.properties`：包含本机 Android SDK 和 Flutter SDK 路径。
- `ios/Flutter/Generated.xcconfig`、`ios/Flutter/flutter_export_environment.sh`：Flutter 自动生成且包含本机绝对路径。
- `.dart_tool/`、`.flutter-plugins`、`.flutter-plugins-dependencies`、`build/`。
- `android/.gradle/`、`android/**/.cxx/`、`ios/Pods/`、`ios/.symlinks/`。
- `.DS_Store`、IDE 工作区状态文件、`.env*`、`key.properties`、`*.jks`、`*.keystore`、`*.p12`、`*.pem` 和 `*.mobileprovision`。
- 如果未来接入 Firebase 或其他服务，不要提交 `GoogleService-Info.plist`、`google-services.json` 或任何包含密钥的配置文件。

这些规则已经写入项目根目录的 `.gitignore`。当前这些本地文件仍可能存在于工作目录中，但正常执行 `git add .` 时不会被加入；如果某文件过去已经被 Git 跟踪，需要先从索引移除后再提交。

English: The following files contain machine-specific paths, build caches, or local credentials and should stay on the development machine:

- `android/local.properties`: contains local Android SDK and Flutter SDK paths.
- `ios/Flutter/Generated.xcconfig` and `ios/Flutter/flutter_export_environment.sh`: generated by Flutter and contain absolute local paths.
- `.dart_tool/`, `.flutter-plugins`, `.flutter-plugins-dependencies`, and `build/`.
- `android/.gradle/`, `android/**/.cxx/`, `ios/Pods/`, and `ios/.symlinks/`.
- `.DS_Store`, IDE workspace state, `.env*`, `key.properties`, `*.jks`, `*.keystore`, `*.p12`, `*.pem`, and `*.mobileprovision`.
- If Firebase or another service is added later, do not commit `GoogleService-Info.plist`, `google-services.json`, or any configuration containing secrets.

These rules are included in the root `.gitignore`. The local files may still exist in the working directory, but a normal `git add .` will not include them. If a file was already tracked, remove it from the Git index before committing.

### 首次公开发布前 / Before the first public release

中文：

- 将 Android 的 `com.example.local_tasks` 和 iOS 的 Bundle Identifier 改成你自己的唯一标识；它们不是秘密，但当前仍是模板默认值。
- 为 Release 构建配置正式签名。当前 Android Release 配置使用 debug signing，仅适合开发验证，不适合应用商店发布。
- 检查图标、启动图、字体和第三方素材的版权与许可证。
- 将 `LICENSE` 中的 `LocalTasks contributors` 换成实际版权持有者或组织名称。

English:

- Replace Android's `com.example.local_tasks` and the iOS Bundle Identifier with your own unique identifiers. They are not secrets, but they are still template defaults.
- Configure proper release signing. The current Android Release build uses debug signing, which is suitable for development checks but not for store distribution.
- Check the copyright and licenses for icons, launch images, fonts, and third-party assets.
- Replace `LocalTasks contributors` in `LICENSE` with the actual copyright holder or organization name.

## 数据与隐私 / Data and privacy

中文：

- 应用不请求网络接口，也没有账号、云同步或远程数据库。
- SQLite 数据库文件名为 `local_tasks.db`，保存在系统为应用提供的文档目录中。
- `tasks` 表保存日常待办；`check_items` 表保存出发检查项。
- 饮食记录、健身个人资料、动作完成进度和训练历史当前只保存在内存中，重启应用后不会恢复。
- 本地通知依赖 Android/iOS 的通知权限和系统调度策略；关闭权限或系统限制后台活动可能导致提醒无法显示。

English:

- The app does not call network APIs and has no accounts, cloud sync, or remote database.
- The SQLite file is named `local_tasks.db` and is stored in the application documents directory provided by the operating system.
- The `tasks` table stores daily tasks, while `check_items` stores departure checklist items.
- Nutrition entries, workout profiles, exercise progress, and workout history are currently held in memory and are not restored after an app restart.
- Local notifications depend on Android/iOS notification permissions and the operating system's scheduling policy. Disabled permissions or background restrictions may prevent reminders from appearing.

## 设计与实现说明 / Design notes

中文：

- 应用使用底部导航在四个模块之间切换，并按需创建后续页面。
- 待办和出发检查共用同一个 SQLite 数据库文件，但使用不同的数据表。
- 健身重量估算使用瘦体重、身高、训练天数和经验等级计算保守系数；如果填写首次测试重量和次数，还会用估算的 1RM 对下一次建议重量进行上限约束。
- 饮食营养计算按“每 100 克营养值 × 实际克数 / 100”进行。

English:

- The app uses bottom navigation for the four modules and creates secondary pages lazily when needed.
- Daily tasks and departure checks share one SQLite file but use separate tables.
- Workout weight estimation uses lean mass, height, training days, and experience to calculate a conservative factor. When a first-test weight and rep count are provided, an estimated one-rep max is also used to cap the next recommendation.
- Nutrition values are calculated as `per-100g value × entered grams / 100`.

## 当前限制与后续方向 / Current limitations and future directions

中文：当前版本尚未实现饮食和训练数据的持久化、数据导入导出、云同步、账号系统以及跨设备同步。后续可以按需要加入这些能力，并补充自动化测试和更完整的多语言界面。

English: The current version does not yet persist nutrition or workout data, support import/export, cloud sync, accounts, or cross-device synchronization. These capabilities, along with automated tests and a complete localized UI, can be added in future iterations.

## 许可证 / License

本项目采用 MIT License 开源。你可以自由使用、修改、分发和商用，但需要保留许可证和版权声明。第三方依赖仍受其各自许可证约束。

This project is released under the MIT License. You may use, modify, distribute, and use it commercially, provided that the license and copyright notice are retained. Third-party dependencies remain subject to their respective licenses.
