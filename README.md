# 见词 WordSnap

一个完全离线的英语词汇学习 App，支持拍照 OCR 取词、SRS 间隔复习、多单词本管理、数据导入导出。

<p align="center">
  <img src="screenshots/01-learn.png" width="24%" alt="记单词主页" />
  <img src="screenshots/02-study.png" width="24%" alt="学习卡片" />
  <img src="screenshots/03-wordbooks.png" width="24%" alt="单词本列表" />
  <img src="screenshots/04-archive.png" width="24%" alt="档案卡" />
</p>

## 功能

- **拍照取词** — Tesseract OCR 离线识别，拍一张照即可收录单词
- **手动查词** — 内置 ECDICT 精简词库（58K 词条），中英文释义、音标、词形变化
- **SRS 间隔复习** — 10:1 新词复习比，10 次正确 = 掌握
- **多单词本** — 自由创建、编辑、移动、批量管理单词
- **学习档案** — 已掌握/复习中/词汇总量统计 + 10 个成就里程碑
- **数据自由** — JSON 导入/导出 + 系统分享，数据完全由你控制
- **完全离线** — 不依赖任何网络服务，OCR + 词典全部本地运行
- **剪贴板监听** — 复制英文即弹出收录提示

## 技术栈

| 层 | 技术 |
|---|------|
| 框架 | Flutter 3.x (Dart) |
| 状态管理 | flutter_riverpod |
| 路由 | GoRouter (StatefulShellRoute) |
| 数据库 | sqflite (SQLite) + ECDICT 精简词库 |
| OCR | Tesseract (tesseract_ocr) |
| TTS | flutter_tts |
| 平台 | Android |

## 快速开始

```bash
# 克隆
git clone https://github.com/yclee5206-create/wordsnap.git
cd wordsnap

# 安装依赖
flutter pub get

# 调试运行（需连接 Android 设备）
flutter run

# 构建 Release APK（约 83MB）
flutter build apk --release
```

> **注意**：Release 构建需要配置 Android 签名。参考 [Flutter 官方文档](https://docs.flutter.dev/deployment/android#signing-the-app) 创建 `android/key.properties`。

## 项目结构

```
lib/
├── app.dart                    # MaterialApp.router + 主题
├── main.dart                   # 入口
├── core/
│   ├── database/               # SQLite 单例
│   ├── router/                 # GoRouter 配置
│   └── theme/                  # 颜色/字体/间距/圆角
├── data/
│   ├── models/                 # Word, Notebook, ReviewSession
│   ├── repositories/           # 数据访问层
│   └── services/               # 词典/OCR/SRS/剪贴板/TTS/导入导出
├── features/
│   ├── learn/                  # 记单词主页 + 学习页
│   ├── wordbook/               # 单词本列表 + 详情 + 单词详情
│   ├── capture/                # 手动录入 + 拍照识别
│   ├── archive/                # 档案卡（统计+成就）
│   └── settings/               # 设置（导出/导入）
└── widgets/                    # 底部 Pill Bar + 导航壳
```

## SRS 算法

```
新词:复习 = 10:1 交错排列
认识 → reviewCount+1 → 满 10 次 = 掌握
不认识 → reviewCount 归零 → 重新排队

三种模式：
  normal       ≥10 新词可用
  transition   1-9 新词可用
  pureReview   0 新词，全部复习
```

## 运行测试

```bash
flutter test                    # 41 单元 + widget tests
flutter test integration_test/ -d <device_id>  # 集成测试（需真机）
```

## 离线词库

基于 [ECDICT](https://github.com/skywind3000/ECDICT) 免费词库，筛选 CET4/6 + 托福 + 雅思 + 考研 + GRE + 高频词，共 58K 词条，精简为 15MB SQLite 数据库随 App 安装。

## License

[Apache License 2.0](LICENSE) © 2026 yclee5206-create
