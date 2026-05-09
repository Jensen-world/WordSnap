# 见词 WordSnap — 断点续接指南

> 最后更新：2026-05-09（Session 7：真机网络问题修复 — OCR 离线化 + 词典本地化）

## 一、现在到哪了

**阶段：P0 MVP 全部实现完成，APK 构建通过（174MB debug APK）。**

### P0 MVP 完成清单（12/12）

| # | 模块 | 状态 |
|---|------|------|
| 1 | 项目脚手架 + 主题（colors/typo/spacing/radius） | ✓ |
| 2 | SQLite 数据库（3表：notebooks/words/review_sessions） | ✓ |
| 3 | Repository 层（Notebook/Word/Review） | ✓ |
| 4 | 路由 + 导航壳（StatefulShellRoute + CapsuleTabBar + BottomPill） | ✓ |
| 5 | 记单词主页（LearnPage + LearnSettingsSheet） | ✓ |
| 6 | SRS 学习流程（新词/复习 10:1 交错，10次正确=掌握） | ✓ |
| 7 | 单词本列表 + 新建/编辑（WordbookPage + CreateNotebookSheet） | ✓ |
| 8 | 单词本详情 + 单词详情（NotebookDetail + WordDetail） | ✓ |
| 9 | 档案卡（ArchivePage + 10 成就里程碑） | ✓ |
| 10 | 手动录入 + 词典查词（CaptureSheet + Free Dictionary API） | ✓ |
| 11 | 剪贴板监听 + JSON 导出（ClipboardService + ExportImportService） | ✓ |
| 12 | 拍照识别 OCR（ML Kit + image_picker） | ✓ |

### Session 2 追加：边缘情况处理（2026-05-08）

| 场景 | 处理 |
|------|------|
| 字典查词失败/无网络 | 红色提示文字"查不到该单词，请检查拼写或网络" |
| 导出失败 | SnackBar "导出失败，请稍后重试" |
| OCR 处理失败 | "文字识别失败，请重试或确认图片清晰" |
| 回退键退出保护 | PopScope + 2 秒内双击退出 |
| 数据加载失败 | 各页面统一重试按钮（蓝色 TextButton） |
| 下拉刷新 | Learn/Wordbook/Archive/NotebookDetail 全部加 RefreshIndicator |
| 导入按钮 | 占位 SnackBar "导入功能即将上线" |

### Session 4：底部 Pill Bar 重构（2026-05-08）

| 改动 | 说明 |
|------|------|
| 颜色 | 品牌蓝 #2F5CFF 80% 不透明度（0xCC2F5CFF），代替灰底 |
| 按钮样式 | 去除白色胶囊+文字，改为纯白色图标（24px） |
| 拍照图标 | camera_alt_outlined / camera_alt（按住切换实体） |
| 记录图标 | edit_note_outlined / edit_note（按住切换实体，松手弹 CaptureSheet） |
| 布局 | Row + MainAxisAlignment.spaceEvenly，两端分散无分隔线 |
| 间距 | 左右 48px，底部 32px + 系统导航栏高度 |
| 交互 | GestureDetector onTapDown/onTapUp/onTapCancel 切换图标状态 |

**构建工作流改进**：`flutter run` 热重载不稳定 → 改用 `flutter build web` + Python HTTP 服务器，刷新浏览器一定生效。

### Session 4 后续：路由 + 图标一致性（2026-05-08）

| 改动 | 说明 |
|------|------|
| 单词本详情路由 | `/wordbook/:id` 从分支内移到顶层路由，进入全屏独立页面（无底栏） |
| 返回按钮修复 | 改用 `GoRouter.of(context).go('/wordbook')` 直接返回列表 |
| 下拉菜单图标 | 📖 emoji → `menu_book_rounded` 图标，与主页卡片统一，选中态白色 |
| 空单词本开始学习 | 区分空队列 vs 真正学完，空时显示"暂无单词需要学习" |

#### 空数据状态 UI 调整完成清单

| 页面 | 空状态表现 |
|------|-----------|
| 记单词主页 | 拾词集卡片（0词）+ 学习计划（0新词/0待复习）+ 每日一词空态提示 |
| 单词本列表 | 默认"拾词集"笔记本，可新建/编辑 |
| 单词本详情 | 全屏独立页，暂无单词提示 |
| 底部 Pill Bar | 品牌蓝80%透明、白色图标（拍照/edit_note）、两端分散 |

### Session 5：LearnPage 今日配额逻辑（2026-05-09）

| 改动 | 说明 |
|------|------|
| LearnPage 新学词/待复习 | 改为今日会话配额：`dailyLimit − 今日已学`，新复比 10:1（ceil） |
| 新复比计算 | 新词 ≤10 → 1 复习；11~20 → 2 复习；以此类推 |
| WebStorage 默认 dailyLimit | 从 0 改为 10，与 SQLite 版一致 |
| 种子数据双存储 | seed_data.dart 条件导出：web 用 seed_data_web.dart（WebStorage），native 用 seed_data_native.dart（DatabaseHelper） |
| ReviewRepository web stub | `getToday()` 返回 null → 初始配额 = dailyLimit；`getOrCreateToday()` 不持久化 |

### Session 6：有数据状态测试 + 卡片 bug 修复（2026-05-09）

| 测试项 | 结果 |
|--------|------|
| LearnPage 配额 | ✓ 新学词=10、待复习=1，配额公式正确 |
| 拾词集卡片（修复后） | ✓ 3新学 / 6待复习 / 3掌握 / 12总计（数据库真实值） |
| ArchivePage | ✓ 已掌握6 / 词汇总量23 / 复习中10 / 3单词本，里程碑数据正确 |
| WordbookPage | ✓ 3个单词本卡片：拾词集12词 / 日常英语6词 / 商务词汇5词 |
| NotebookDetail | ✓ 12个单词全部显示，返回按钮+筛选标签+管理按钮正常 |
| WordDetail | ✓ ephemeral 详情：新词 0/10、剪贴板来源 |
| StudyPage 队列 | ✓ 3新+6复习=9词，10:1 交错，ephemeral 第一条 |

#### 卡片统计数据 bug（已修复，commit 9aeff15）

**问题：** Session 5 配额重构把 `state.newWords`/`state.reviewWords` 从数据库计数改为会话配额，但拾词集卡片仍用这些字段，导致卡片显示"10 待复习"（=新学配额）而非数据库真实的"3 新学 + 6 待复习"。

**修复：** LearnState 新增 `dbNewWords` / `dbReviewWords` 分别存储数据库计数，卡片用数据库值，学习计划区用会话配额。

#### Flutter Web 自动化测试限制
- Flutter canvas 渲染不响应 Playwright `page.mouse.click()` / `PointerEvent`
- 可通过直接 URL 导航 + 截图验证页面内容
- 坐标点击不可靠，交互测试需真机或模拟器

### Session 7：真机网络问题修复 — OCR 离线化 + 词典本地化（2026-05-09）

**问题：** 真机测试拍照 OCR 和词典查词均报错。根因——ML Kit standalone 需从 Google 服务器下载模型，Free Dictionary API 托管海外，国内网络均不可达。

**修复：两大核心依赖全部离线化**

#### OCR：ML Kit → Tesseract

| 改动 | 说明 |
|------|------|
| 移除 `google_mlkit_text_recognition` | 模型运行时下载，国内不可用 |
| 添加 `tesseract_ocr: ^0.5.0` | Tesseract4Android 离线引擎 |
| 内置 `eng.traineddata`（4MB） | 英文识别模型，随 APK 安装 |

#### 词典：Free Dictionary API → ECDICT 本地 SQLite

| 改动 | 说明 |
|------|------|
| 下载 ECDICT 全量库（207MB zip） | 340 万词条，通过代理下载 |
| 筛选创建 `ecdict_slim.db`（15MB） | CET4/6+托福+雅思+考研+GRE+高频词，58K 词条 |
| `DictionaryService` 重写 | HTTP API → 本地 SQLite 只读查询 |
| `DictionaryResult` 新增字段 | `translation`（中文释义）、`exchange`（词形变化）、`tag`（考级标签） |
| 三个 save() 方法更新 | photo_capture / capture / share_receipt 均存储中文翻译和标签 |
| 错误提示更新 | 去除"请检查网络"，改为"请检查拼写" |

#### 构建产物

| 文件 | 大小 |
|------|------|
| `assets/ecdict_slim.db` | 15MB（58K 词条） |
| `assets/tessdata/eng.traineddata` | 4MB（英文模型） |
| APK 增量 | 约 +19MB |
| Debug APK | 203MB |

#### pubspec.yaml 依赖变更

```
- google_mlkit_text_recognition: ^0.14.0
+ tesseract_ocr: ^0.5.0
assets 新增: tessdata_config.json, tessdata/, ecdict_slim.db
```

### 构建注意事项
- `flutter build web` 后可能有旧 Python 进程残留，需 `pkill` 后重启
- 浏览器 service worker 会缓存旧版本，换端口（8080→9090）可绕过
- 端口 8080 被多个 Python 进程监听时，`build/web` 目录无法删除

## 二、关键技术决策

### 架构
- **状态管理**：flutter_riverpod（StateNotifierProvider + AsyncNotifierProvider + FutureProvider）
- **路由**：GoRouter StatefulShellRoute.indexedStack（3-tab 导航）
- **数据库**：sqflite，单例 DatabaseHelper，3 张表带索引
- **API**：ECDICT 本地 SQLite 数据库（15MB 精简版，58K 词条，完全离线）
- **OCR**：Tesseract（tesseract_ocr 包，eng.traineddata 4MB 模型随 APK 安装）
- **拍照**：image_picker（调用系统相机）

### SRS 算法
- 10:1 新词/复习交错比例
- 认识 → reviewCount+1，10 次正确 = 掌握（isMastered=true）
- 不认识 → reviewCount 归零，重新排入队列
- 三种模式：normal（≥10 新词）、transition（1-9 新词）、pureReview（0 新词）

### 配色
- 信号蓝 #2F5CFF（主色）、琥珀闪 #FFA940（强调）、薄荷 #00C896（掌握/成功）、薰衣草 #7068F0（词性/预计天数）
- 墨黑 #0B0B0F、画布白 #F9F9FB、边框 #E2E2EA

## 三、项目文件结构

```
lib/
├── app.dart                          # MaterialApp.router + ThemeData
├── main.dart                         # 入口，竖屏锁定
├── core/
│   ├── database/database_helper.dart # SQLite 单例
│   ├── router/app_router.dart        # GoRouter 配置
│   └── theme/
│       ├── colors.dart               # AppColors
│       ├── typography.dart           # AppTypography (GoogleFonts)
│       ├── spacing.dart              # 4px base unit
│       └── radius.dart               # AppRadius (pill/card/input/sheet)
├── data/
│   ├── models/
│   │   ├── notebook.dart
│   │   ├── word.dart
│   │   ├── word_context.dart
│   │   └── review_session.dart
│   ├── repositories/
│   │   ├── notebook_repository.dart
│   │   ├── word_repository.dart
│   │   └── review_repository.dart
│   └── services/
│       ├── dictionary_service.dart   # ECDICT 本地 SQLite
│       ├── dictionary_result.dart
│       ├── review_service.dart       # SRS 算法
│       ├── clipboard_service.dart    # Timer 轮询剪贴板
│       ├── ocr_service.dart          # Tesseract 离线识别
│       └── export_import_service.dart # JSON 导入导出
├── features/
│   ├── learn/
│   │   ├── learn_page.dart           # 记单词主页
│   │   ├── learn_provider.dart
│   │   ├── learn_settings_sheet.dart # 学习设置 BottomSheet
│   │   ├── study_page.dart           # 学习卡片/释义
│   │   └── study_provider.dart
│   ├── wordbook/
│   │   ├── wordbook_page.dart        # 单词本列表
│   │   ├── wordbook_provider.dart    # 所有 repository providers
│   │   ├── create_notebook_sheet.dart
│   │   ├── notebook_detail_page.dart # 单词本详情
│   │   └── word_detail_page.dart     # 单词详情
│   ├── capture/
│   │   ├── capture_sheet.dart        # 手动输入 BottomSheet
│   │   ├── capture_provider.dart
│   │   ├── photo_capture_page.dart   # 拍照识别
│   │   └── photo_capture_provider.dart
│   ├── archive/
│   │   ├── archive_page.dart         # 档案卡
│   │   └── archive_provider.dart
│   └── settings/
│       └── settings_page.dart        # 设置（导出/导入/剪贴板/关于）
└── widgets/
    ├── navigation_shell.dart         # Scaffold + AppBar + PopScope
    ├── capsule_tab_bar.dart          # 记单词/单词本/档案卡
    └── bottom_pill.dart              # 拍照 + 记录 底部按钮
```

## 四、Android 构建配置

### 镜像加速（中国网络必需）
- `android/gradle/wrapper/gradle-wrapper.properties`：Gradle 8.14-bin 使用腾讯云镜像
- `android/settings.gradle.kts`：Maven 使用阿里云镜像
- `android/build.gradle.kts`：同上
- `android/gradle.properties`：`kotlin.incremental=false`（避免增量编译缓存问题）

### 权限（AndroidManifest.xml）
- INTERNET（词典 API）
- CAMERA（拍照识别）

### 依赖（pubspec.yaml）
```
tesseract_ocr: ^0.5.0
image_picker: ^1.1.2
flutter_riverpod: ^2.6.1
go_router: ^14.8.1
sqflite: ^2.4.2
google_fonts: ^6.2.1
http: ^1.6.0
```

### 构建命令
```bash
flutter clean && flutter pub get && flutter build apk --debug
# APK: build/app/outputs/flutter-apk/app-debug.apk (203MB)
```

## 五、已知待办

### 功能缺失
- [x] JSON 导入 UI（file_picker + 导入预览 Dialog + 导入结果 Dialog，Session 3 完成）
- [x] 分享收录（8c — MethodChannel + ShareReceiptSheet，Session 3 完成）
- [x] 标签管理（InputChip 可删除 + 弹窗添加，Session 3 完成）
- [x] TTS 发音（flutter_tts + TtsService，8 个喇叭按钮全部接线，Session 3 完成）
- [ ] 图片关联（imagePath 字段已有，但 UI 未接）
- [ ] 每日一词实际数据（当前为硬编码 ephemeral 示例）

### 测试
- [x] 真机基础测试（OCR + 词典离线化已修复，2026-05-09）
- [ ] 真机完整流程测试（拍照→OCR→查词→保存→学习）
- [ ] Widget test
- [ ] Integration test

### 构建
- [ ] Release APK 签名配置
- [ ] App 图标替换（当前使用默认 Flutter 图标）

## 六、明天回顾要点

1. Session 1（05-07 下午）：全部 15 页面 mockup 审阅 + 品牌/logo/截图
2. Session 2（05-07 晚上 ~ 05-08 凌晨）：P0 MVP 12 项全部实现 + 边缘情况处理 + APK 构建通过
3. Session 3（05-08）：JSON 导入 UI + TTS 发音 + 标签管理 + 分享收录 完成
   - 新增 file_picker + flutter_tts 依赖
   - ExportImportService 新增 analyzeJson + ImportPreview/NotebookPreview 数据类
   - 设置页：选取 JSON 文件 → 导入预览 → 确认导入 → 结果摘要
   - TtsService：封装 flutter_tts，8 个喇叭按钮全部接线
   - 标签管理：单词详情页支持添加/删除标签（InputChip + 弹窗输入）
   - 分享收录：Android ACTION_SEND intent filter + MethodChannel（无额外依赖），ShareReceiptSheet 自动查词 + 收录
4. P1 全部完成。下一步可选方向：
   - 导出文件实际写入/分享（当前 exportToJson 生成字符串但未保存到文件）
   - 真机/模拟器测试验证
   - P2 功能（每日一词实际数据、图片关联、release 签名+图标）
