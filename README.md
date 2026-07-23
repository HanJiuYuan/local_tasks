# LocalTasks

中文 | English

## 项目简介 / Overview

LocalTasks 是一个基于 Flutter 构建的本地优先生活管理应用，提供日常待办、饮食记录、出发检查和健身助手四个模块。所有业务数据均持久化保存在设备本地，不依赖账号或云端服务。

LocalTasks is a local-first life-management app built with Flutter. It includes four modules: daily tasks, nutrition tracking, departure checklists, and a workout assistant. All business data is persisted on the device without requiring an account or cloud service.

## 功能 / Features

### 日常待办 / Daily tasks

- 创建、完成和删除任务。
- 为任务添加标签。
- 设置日期和时间提醒，并使用系统本地通知。
- 应用启动时重新安排未完成任务的提醒，完成或删除任务后取消提醒。
- 任务及其完成状态持久化保存到本地 SQLite 数据库。

- Create, complete, and delete tasks.
- Add tags to tasks.
- Set date and time reminders with system local notifications.
- Reschedule reminders for incomplete tasks when the app starts and cancel them when tasks are completed or deleted.
- Tasks and completion states are persisted in a local SQLite database.

### 饮食记录 / Nutrition tracking

- 按早餐、午餐、晚餐和加餐记录食物。
- 提供主食、蛋白质、奶豆类、蔬菜、水果、坚果油脂和饮品分类。
- 从内置常见食物库中选择食物，按照每 100g 原始营养值和实际摄入克数计算热量、蛋白质、碳水、脂肪、膳食纤维、糖分和钠。
- 复用健身助手中的体重、体脂率和训练天数，计算减脂、维持或增肌时的每日热量与三大营养素目标。
- 查看今日已摄入、每日目标和实时剩余；超出目标时保留负数，不会把剩余值强制归零。
- 支持自定义食物的“每 100g 营养值”和“本次摄入总量”两种录入方式。
- 饮食记录和目标模式持久化保存，重启应用后仍可恢复。
- 营养值来自内置或用户填写的数据，属于估算值，不替代专业营养建议。

- Record breakfast, lunch, dinner, and snacks.
- Browse staple foods, protein, dairy and soy, vegetables, fruits, nuts and oils, and beverages.
- Select foods from the bundled food list and calculate calories, protein, carbohydrates, fat, fiber, sugar, and sodium from raw per-100-gram values and entered weight.
- Reuse body weight, body-fat percentage, and training days from the workout profile to calculate daily targets for fat loss, maintenance, or muscle gain.
- View consumed nutrition, daily targets, and live remaining values; over-target values remain negative instead of being clamped to zero.
- Enter custom foods either as per-100-gram nutrition or as the total nutrition for one serving.
- Nutrition entries and the selected goal are persisted and restored after the app restarts.
- Nutrition values come from bundled or user-entered estimates and are not a substitute for professional dietary advice.

## 营养算法 / Nutrition algorithm

### 1. 数据来源与职责

营养模块把“每日应该吃多少”和“今天实际吃了多少”分开计算：

```text
健身档案：体重 / 体脂率 / 身高 / 训练天数
                         ↓
每日目标：热量 / 蛋白质 / 脂肪 / 碳水

食物记录：食物的每 100g 原始营养值 + 实际摄入克数
                         ↓
今日摄入：按日期汇总所有饮食记录
                         ↓
剩余营养：每日目标 - 今日已摄入
```

实现位置：

- `Nutrition`：一组营养值，以及按重量换算的方法。
- `FoodNutrition`：食物库中的每 100g 原始数据。
- `FoodEntry`：用户的一条饮食记录，保存实际克数和每 100g 原始营养源。
- `DailyNutritionCalculator`：每日目标计算器。
- `NutritionTotals`：按日期汇总当天所有饮食记录。

### 2. 每日营养目标

当前产品策略使用 Katch-McArdle 类公式。体脂率在模型中以百分比保存，例如 `28` 代表 `28%`。

#### 瘦体重

```text
LBM = 体重 × (1 - 体脂率 / 100)
```

示例：

```text
体重 77kg，体脂率 28%
LBM = 77 × (1 - 0.28)
    = 55.44kg
```

#### 静息代谢与 TDEE

```text
RMR  = 370 + 21.6 × LBM
TDEE = RMR × 活动系数
```

活动系数是 App 的保守产品模型：

```dart
double activityFactor(int trainingDays) {
  if (trainingDays <= 0) return 1.20;
  if (trainingDays <= 2) return 1.30;
  if (trainingDays <= 4) return 1.40;
  if (trainingDays <= 6) return 1.50;
  return 1.55;
}
```

目标热量调整：

| 目标 | 目标热量 |
| --- | --- |
| 减脂 | `TDEE × 0.85` |
| 维持 | `TDEE × 1.00` |
| 增肌 | `TDEE × 1.08` |

这些数值属于产品策略参数，集中放在 `NutritionStrategyConfig` 中，后续可以替换为远程配置，不应被视为医学标准。

### 3. 三大营养素目标

计算顺序是：先蛋白质，再脂肪，最后把剩余热量分配给碳水。

```text
减脂蛋白质 = LBM × 2.3g
维持/增肌蛋白质 = 体重 × 1.6g

脂肪热量 = 目标热量 × 25%
脂肪克数 = 脂肪热量 / 9

蛋白质热量 = 蛋白质克数 × 4
碳水克数 = (目标热量 - 蛋白质热量 - 脂肪热量) / 4
```

因此理论上四个目标满足：

```text
目标热量 = 蛋白质 × 4 + 脂肪 × 9 + 碳水 × 4
```

计算过程保留浮点精度，界面显示时才进行四舍五入，避免因提前取整造成总热量不一致。

### 4. 单份食物的摄入量

所有营养项统一使用 `Nutrition.calculateByWeight()`：

```text
实际营养 = 每 100g 营养值 × 实际摄入克数 / 100
```

示例，某食物每 100g 为：

```text
热量 220 kcal，蛋白质 12g，碳水 20g，脂肪 10g
```

用户实际摄入 180g：

```text
热量   = 220 × 180 / 100 = 396 kcal
蛋白质 = 12  × 180 / 100 = 21.6g
碳水   = 20  × 180 / 100 = 36g
脂肪   = 10  × 180 / 100 = 18g
```

数据库保存的是：

```text
实际摄入克数：180g
每 100g 原始营养：220 kcal / 12g / 20g / 10g
```

这样如果用户把 180g 修改为 150g，可以重新计算，而不会基于旧的 396 kcal 累计误差。当前界面尚未提供编辑按钮；对于无法确定重量、直接填写“本次摄入总量”的自定义食物，记录会保留本次总量作为兼容例外。

### 5. 每日汇总与剩余

当天的早餐、午餐、加餐和晚餐记录都会参与汇总：

```text
今日热量   = Σ 每条记录的实际热量
今日蛋白质 = Σ 每条记录的实际蛋白质
今日碳水   = Σ 每条记录的实际碳水
今日脂肪   = Σ 每条记录的实际脂肪
```

剩余值只在运行时计算，不单独保存到数据库：

```text
剩余热量   = 每日热量目标 - 今日热量
剩余蛋白质 = 每日蛋白质目标 - 今日蛋白质
剩余碳水   = 每日碳水目标 - 今日碳水
剩余脂肪   = 每日脂肪目标 - 今日脂肪
```

剩余值允许为负数。例如目标为 `1900 kcal`、实际摄入 `2050 kcal` 时，界面显示 `-150 kcal`，表示今日已超出 150 kcal。

### 6. 本地存储

营养数据保存在 `nutrition.db`：

- `food_entries`：餐次、食物名称、实际克数、实际营养值、每 100g 原始营养字段和记录时间。
- `nutrition_settings`：当前目标模式（减脂、维持或增肌）。
- 数据库版本升级会为已有安装增加每 100g 原始营养字段；旧记录没有原始源时仍使用已保存的历史实际值。

每日目标所需的身体数据继续来自 `workout.db` 中的健身档案，营养页打开或恢复时重新读取，目标模式单独保存在 `nutrition.db`。

### 出发检查 / Departure checklist

- 首次使用时自动创建常用检查项，例如牙刷、手机、钱包/身份证和门窗检查。
- 勾选或取消检查项。
- 添加自定义检查项。
- 删除检查项，或一键重置全部完成状态。
- 检查项、排序和完成状态持久化保存到本地 SQLite 数据库。

- Seed a default checklist on first use, including items such as a toothbrush, phone, wallet/ID, and doors/windows.
- Check and uncheck items.
- Add custom checklist items.
- Delete items or reset all completion states at once.
- Checklist items, ordering, and completion states are persisted in SQLite.

### 健身助手 / Workout assistant

- 填写体重、身高、体脂率、训练天数和训练经验。
- 根据身体数据和训练经验估算建议起始重量。
- 按胸、背、肩、腿、手臂和核心浏览快捷动作，也支持自重动作。
- 添加自定义动作，调整重量、组数、次数和组间休息时间。
- 按“选择动作 → 训练准备 → 当前动作 → 完成动作 → 组间休息 → 今日总结”的流程完成训练。
- 每组记录 RIR（预留次数），训练结束后根据平均 RIR 给出下一次重量建议，并以 2.5 kg 为调整粒度。
- 保存健身档案、动作计划、训练进度、RIR 反馈、训练历史和下一次重量建议。
- 重量估算只用于制定保守的起始计划，不代表最大力量或安全上限；请根据实际动作质量和身体状态调整。

- Enter body weight, height, body-fat percentage, training days, and experience level.
- Estimate conservative starting weights from body data and training experience.
- Browse quick exercises by chest, back, shoulders, legs, arms, and core, including bodyweight exercises.
- Add custom exercises and adjust weight, sets, reps, and rest time.
- Follow the flow: select exercises → training preparation → current exercise → complete set → rest → daily summary.
- Record RIR (reps in reserve) for each set. After training, the app suggests a next-session weight in 2.5 kg increments.
- Persist workout profiles, exercise plans, training progress, RIR feedback, workout history, and next-weight recommendations.
- Weight estimates are conservative starting points, not one-rep-max or safety limits. Adjust them based on form and current condition.

## 技术栈 / Tech stack

- Flutter / Dart
- Material 3 UI
- `sqflite`、`path`、`path_provider`：本地 SQLite 数据存储 / local SQLite storage
- `flutter_local_notifications`、`flutter_timezone`、`timezone`：定时通知和时区处理 / scheduled notifications and timezone handling
- `cupertino_icons`：iOS 风格图标 / Cupertino-style icons

## 本地数据 / Local data

中文：所有业务数据均存储在应用本地文档目录中的 SQLite 数据库，不会上传到服务器。

- `local_tasks.db`：日常待办和出发检查项。
- `nutrition.db`：饮食记录。
- `workout.db`：健身档案、动作计划、训练进度和训练历史。

卸载应用或清除应用数据可能会删除本地记录。本地通知是否正常显示取决于 Android/iOS 的通知权限和系统调度策略。

English: All business data is stored in SQLite databases under the app's local documents directory and is never uploaded to a server.

- `local_tasks.db`: daily tasks and departure checklist items.
- `nutrition.db`: nutrition entries.
- `workout.db`: workout profiles, exercise plans, training progress, and workout history.

Uninstalling the app or clearing its data may remove local records. Local notification delivery depends on Android/iOS notification permissions and the operating system's scheduling policy.

## 项目结构 / Project structure

```text
lib/
├── main.dart                         # 应用入口 / app entry point
└── widget/
    ├── app/app_shell.dart             # 底部导航和页面容器 / navigation shell
    ├── home/                          # 日常待办 / daily tasks
    ├── nutrition/                     # 饮食记录和本地存储 / nutrition and storage
    ├── departure/                     # 出发检查 / departure checklist
    └── workout/                       # 健身助手和本地存储 / workout and storage
```

## 运行环境 / Requirements

中文：

- Flutter SDK，Dart SDK 版本需满足 `pubspec.yaml` 中的 `^3.7.2`。
- Android 或 iOS 开发环境；项目已包含 `android/` 和 `ios/` 平台目录。
- 在 iOS 真机或模拟器上运行需要 Xcode；在 Android 上运行需要 Android SDK 和可用的模拟器或设备。

English:

- Flutter SDK with a Dart SDK version compatible with `^3.7.2` in `pubspec.yaml`.
- An Android or iOS development environment; both `android/` and `ios/` platform directories are included.
- Xcode is required for iOS devices or simulators. Android requires the Android SDK and an available emulator or device.

## 快速开始 / Quick start

```bash
flutter pub get
flutter run
```

中文：可以运行 `flutter analyze` 检查代码，运行 `flutter test` 执行测试，运行 `flutter build apk --debug` 构建 Android 调试包。首次使用提醒功能时，请在系统弹窗中允许通知权限。

English: Run `flutter analyze` to check the code, `flutter test` to run tests, and `flutter build apk --debug` to build an Android debug APK. Allow notification permissions in the system prompt when using reminders for the first time.

## 设计与实现说明 / Design notes

中文：

- 应用使用底部导航在四个模块之间切换，并按需创建页面。
- 各模块使用本地 SQLite 数据库保存业务数据，应用重启后会从数据库恢复状态。
- 健身重量估算使用瘦体重、身高、训练天数和经验等级计算保守系数；填写首次测试重量和次数后，还会用估算的 1RM 对下一次建议重量进行上限约束。
- 饮食目标由 `DailyNutritionCalculator` 根据健身档案计算，食物摄入由 `Nutrition.calculateByWeight()` 根据每 100g 原始数据计算，日汇总由 `NutritionTotals` 完成。

English:

- The app uses bottom navigation for the four modules and creates pages lazily when needed.
- Each module stores its business data in local SQLite databases and restores its state after an app restart.
- Workout weight estimation uses lean mass, height, training days, and experience to calculate a conservative factor. When a first-test weight and rep count are provided, an estimated one-rep max is used to cap the next recommendation.
- Nutrition targets are calculated by `DailyNutritionCalculator` from the workout profile. Food intake is calculated by `Nutrition.calculateByWeight()` from raw per-100-gram data, and daily totals are produced by `NutritionTotals`.

## 当前限制与后续方向 / Current limitations and future directions

中文：当前版本采用本地存储，不提供数据导入导出、云同步、账号系统或跨设备同步。后续可以按需要加入这些能力，并补充更完整的多语言界面。

English: The current version uses local storage and does not provide data import/export, cloud sync, accounts, or cross-device synchronization. These capabilities and a more complete localized UI can be added in future iterations.

## 许可证 / License

本项目采用 MIT License 开源。你可以自由使用、修改、分发和商用，但需要保留许可证和版权声明。第三方依赖仍受其各自许可证约束。

This project is released under the MIT License. You may use, modify, distribute, and use it commercially, provided that the license and copyright notice are retained. Third-party dependencies remain subject to their respective licenses.
