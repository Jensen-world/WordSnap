# 见词 WordSnap — 断点续接指南

> 最后更新：2026-05-09（Session 18：5 个真机问题修复）

## 一、现在到哪了

**阶段：P0 MVP 全部实现完成，真机测试问题修复，APK 构建通过（203MB debug APK）。**

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

### Session 9：真机测试问题修复 + 启动页（2026-05-09）

#### 6 个真机 Bug 修复

| # | 问题 | 根因 | 修复 |
|---|------|------|------|
| 1 | 启动页不显示 | Android 12+ 缺少 splash 配置；launch_background.xml 用硬编码颜色 | 新增 `values-v31/styles.xml`（windowSplashScreenBackground）+ `colors.xml`，launch_background 改用颜色资源 |
| 2 | 主页不能滚动 | ListView 底部 padding 仅 16px，Pill 遮挡下方内容 | 底部 padding 改为 `MediaQuery.padding.bottom + 120`（Pill 高度） |
| 3 | 毛玻璃效果不明显 | Pill 背景 80% 不透明（0xCC），模糊穿透不够 | 降为 10%（0x19） |
| 4 | 学习设置保存按钮被遮挡 | BottomSheet 底部 padding 仅计算键盘高度，未算 Pill | 底部 padding 增加 Pill 高度（+120px） |
| 5 | 批量管理按钮被导航键遮挡 | 底部操作栏未考虑系统导航栏高度 | padding 增加 `MediaQuery.padding.bottom` |
| 6 | 拍照/输入保存崩溃 | `_NotebookSelector.notebooks` 泛型缺失 `List`→`List<Notebook>`，`orElse: () => null` 类型推断失败 | 加泛型 + import Notebook，`orElse` 改为 for-loop 查找 |

#### 启动页（Web + Android）

| 平台 | 实现 |
|------|------|
| Android | `launch_background.xml`：品牌蓝 #2F5CFF + splash_logo 居中；`values-v31/styles.xml`：Android 12+ splash API |
| Web | `index.html`：全屏蓝色 overlay + 居中 logo，`flutter-first-frame` 事件后淡出（0.3s） |

**设计稿参考**：纯 `#2F5CFF` 蓝色背景，居中白色 "W" logo（右上角橙色圆点点缀），无文字，极简风格。

#### 修复文件（Session 9）
```
lib/features/capture/capture_sheet.dart          — _NotebookSelector 泛型修复
lib/features/capture/photo_capture_page.dart     — _NotebookSelector 泛型修复
lib/features/learn/learn_page.dart               — ListView 底部 padding
lib/features/learn/learn_settings_sheet.dart     — BottomSheet 底部 padding
lib/features/wordbook/notebook_detail_page.dart  — 批量管理底部 padding
lib/widgets/bottom_pill.dart                     — 透明度 0xCC→0x19
android/app/src/main/res/drawable/launch_background.xml  — 颜色资源化
android/app/src/main/res/values/colors.xml               — 新增 splash_bg
android/app/src/main/res/values-v31/styles.xml           — Android 12+ splash
web/index.html                                  — 启动页 splash overlay
assets/logo/splash-logo.png                     — 启动页 logo
```

### 构建注意事项
- `flutter build web` 后可能有旧 Python 进程残留，需 `pkill` 后重启
- 浏览器 service worker 会缓存旧版本，换端口（8080→9090）可绕过
- 端口 8080 被多个 Python 进程监听时，`build/web` 目录无法删除

### Session 10：第二轮真机测试修复（2026-05-09）

#### 6 个 Bug 修复

| # | 问题 | 根因 | 修复 |
|---|------|------|------|
| 1 | 主页滑过头，大片空白 | 底部 padding `MediaQuery.padding.bottom + 120` 过大 | 改为 `16 + 80 + MediaQuery.padding.bottom`（learn_page.dart） |
| 2 | 底部椭圆按钮看不清 | 误改了 Pill 按钮颜色（0xCC→0x19），应改背景白色区域 | 恢复按钮 0xCC2F5CFF，添加白色半透明背景容器（0x10FFFFFF） |
| 3 | 学习设置底部大片空白 | 底部 padding 过大 | 改为 `bottomInset + 24 + 80 + MediaQuery.padding.bottom` |
| 4 | 拍照识别底部被导航键遮住 | `_resultView` ListView padding 未计算导航栏高度 | `EdgeInsets.all(20)` → `EdgeInsets.fromLTRB(20, 20, 20, 20 + padding.bottom)` |
| 5 | 输入单词不能存入 + 底部按钮被遮 | capture_sheet Column 不能滚动，bottom padding 未算导航栏 | 包裹 `SingleChildScrollView`，padding 增加 `MediaQuery.padding.bottom` |
| 6 | 拍照/输入显示英文释义而非中文 | `_ResultCard` 未使用 `result.translation` 字段 | 两个 `_ResultCard` 增加 `result.translation` 中文释义展示 |

#### 中文释义展示

`_ResultCard`（photo_capture_page.dart + capture_sheet.dart）：
- 单词 → 音标+喇叭 → **中文翻译**（`result.translation`，14px inkBlack）→ 词性 → 英文定义

#### 修复文件（Session 10）
```
lib/features/capture/photo_capture_page.dart  — _resultView 底部 padding + _ResultCard 中文翻译
lib/features/capture/capture_sheet.dart        — SingleChildScrollView + 底部 padding + _ResultCard 中文翻译
```

### Session 11：第三轮真机测试修复（2026-05-09）

#### 4 个 Bug 修复

| # | 问题 | 根因 | 修复 |
|---|------|------|------|
| 1 | 启动页无 logo | Android 12+ splash API 缺少 `windowSplashScreenAnimatedIcon` | values-v31/styles.xml 添加 `android:windowSplashScreenAnimatedIcon`→`@drawable/splash_logo` |
| 2 | 主页仍然滑过头 | 底部 padding 80px 仍过大 | 80 → 60（learn_page.dart） |
| 3 | Pill 白色背景不透明 | 背景高度 24px 过高，透明度 0x10 太低 | top padding 24→8，透明度 0x10→0x05（6%→2%） |
| 4 | 输入单词同时显示结果和错误提示 | `copyWith` 传 `null` 无法清除 nullable 字段（`null ?? oldValue` 返回旧值） | capture_provider.dart + photo_capture_provider.dart 的 `copyWith` 增加 `clearResult`/`clearError`/`clearSelectedWord`/`clearLookupResult` 布尔标志 |

#### copyWith nullable 字段清除方案

**问题：** 标准 `field: value ?? this.field` 模式无法将字段显式设为 `null`。

**修复：** `CaptureState.copyWith` 和 `PhotoCaptureState.copyWith` 增加显式清除标志：
```dart
CaptureState copyWith({
    ...
    bool clearResult = false,
    bool clearError = false,
}) => CaptureState(
    result: clearResult ? null : (result ?? this.result),
    errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    ...
);
```

调用处：
- `setInput`: `copyWith(input: input, clearResult: true, clearError: true)`
- `lookup` 前: `copyWith(searching: true, clearError: true)`
- `lookup` 成功: `copyWith(searching: false, result: result, clearError: true)`

#### 修复文件（Session 11）
```
android/app/src/main/res/values-v31/styles.xml    — 添加 splash icon
lib/widgets/bottom_pill.dart                      — 背景高度+透明度
lib/features/learn/learn_page.dart                — 底部 padding 60
lib/features/capture/capture_provider.dart         — copyWith 清除标志
lib/features/capture/photo_capture_provider.dart   — copyWith 清除标志
```

### Session 12：第四轮真机测试修复（2026-05-09）

#### 4 个 Bug 修复

| # | 问题 | 根因 | 修复 |
|---|------|------|------|
| 1 | 单词详情页显示不出来 | `_loadWord()` 没有 try-catch，`getById` 抛异常时 loading 永不休眠 | 加 try-catch + 改用 `ref.read()` 替代 `ProviderScope.containerOf()` |
| 2 | 编辑单词本/学习设置底部被 Pill 遮挡 | `showModalBottomSheet` 在分支导航器上显示，Pill 在外层 scaffold | 4 处调用添加 `useRootNavigator: true`（wordbook/learn/bottom_pill） |
| 3 | 新增单词后 LearnPage 新词数不更新 | 保存后未触发 LearnPage 数据刷新（Session 8 只修了 study 路径） | capture_sheet + photo_capture_page 保存成功后调用 `learnStateProvider.notifier.load()` |
| 4 | 档案卡页面不能滑动 | ListView padding 未计算底部 Pill 高度 | 底部 padding 增加 `MediaQuery.padding.bottom + 60` |

#### useRootNavigator 方案

**问题：** 底部 Pill 是 Scaffold 的 `bottomNavigationBar`，模态 BottomSheet 在分支路由内显示时会覆盖在 Pill 下方。

**修复：** 所有 `showModalBottomSheet` 调用添加 `useRootNavigator: true`，让 Sheet 在根导航器上显示，盖过整个 NavigationShell（含 Pill）。

涉及文件：`wordbook_page.dart`（新建/编辑）、`learn_page.dart`（学习设置）、`bottom_pill.dart`（输入单词）。

#### 修复文件（Session 12）
```
lib/features/wordbook/word_detail_page.dart        — try-catch + ref.read
lib/features/wordbook/wordbook_page.dart           — useRootNavigator
lib/features/learn/learn_page.dart                 — useRootNavigator
lib/widgets/bottom_pill.dart                       — useRootNavigator
lib/features/archive/archive_page.dart             — 底部 padding
lib/features/capture/capture_sheet.dart            — learnStateProvider.load() + import
lib/features/capture/photo_capture_page.dart       — learnStateProvider.load() + import
```

### Session 13：底部 padding 微调（2026-05-09）

| 页面 | 改动 | 原因 |
|------|------|------|
| LearnPage | 底部 60 → 30 | 仍有空白 |
| ArchivePage | 底部 60 → 30 | 仍有空白 |
| LearnSettingsSheet | 底部 80 → 40 | 保存按钮只需不被导航键遮挡 |
| CreateNotebookSheet | 增加 `MediaQuery.padding.bottom` | 取消按钮被导航键遮挡 |

#### 修复文件（Session 13）
```
lib/features/learn/learn_page.dart                 — 底部 60→30
lib/features/archive/archive_page.dart             — 底部 60→30
lib/features/learn/learn_settings_sheet.dart       — 底部 80→40
lib/features/wordbook/create_notebook_sheet.dart   — 加导航栏 padding
```

### Session 14：第四轮底部 padding 微调（2026-05-09）

| 页面 | 改动 | 原因 |
|------|------|------|
| LearnPage | 底部 30 → 10 → 5 | 仍有空白 |
| ArchivePage | 底部 30 → 10 → 0 | 仍有空白 |
| LearnSettingsSheet | 底部 40 → 10 → 5 | 保存按钮只需不被导航键遮挡 |

### Session 15-16：启动页 logo 持续排查（2026-05-09）

**问题：** vivo Funtouch OS 上启动页只显示蓝色背景，logo 始终不显示。

**多轮尝试全部失败：**
| 尝试 | 改动 | 结果 |
|------|------|------|
| 1 | `values-v31/styles.xml` 加 `windowSplashScreenAnimatedIcon` | 不显示 |
| 2 | 修复 `drawable-v21/launch_background.xml`（原始为 Flutter 默认白底无 logo）→ 加入 `<bitmap>` + logo | 不显示 |
| 3 | 创建 `drawable/splash_icon.xml` 包装 bitmap | 不显示 |
| 4 | 添加 `values-night-v31/styles.xml` 深色模式配置 | 不显示 |

**根因分析：** `<layer-list>` 内 `<bitmap android:gravity="center">` 在 vivo Funtouch OS 上不渲染。1440×1440 PNG 可能超出 Android 12 splash API 图标区域（192dp 圆）。

#### 最终方案：Flutter 层 splash（Session 17）

**放弃原生 XML splash，改用 Flutter 渲染第一帧。**

`lib/app.dart` 完全重写：
- `App` 从 `StatelessWidget` → `StatefulWidget`，增加 `_showSplash` 状态
- 初始化时显示 `_SplashScreen` widget（蓝色背景 + 居中 `AssetImage('assets/logo/splash-logo.png')` 120×120）
- 100ms 延迟后 `setState` 切换到 `ProviderScope(child: MaterialApp.router(...))`
- 原生层仅保留蓝色背景（`LaunchTheme` 的 `windowBackground`），logo 完全由 Flutter 负责

**优势：** 跨所有 Android 版本和 OEM skin 一致可靠。

#### 修复文件（Session 14-17）
```
lib/app.dart                                       — 完全重写：Flutter 层 splash screen
android/app/src/main/res/drawable-v21/launch_background.xml — 添加 logo bitmap
android/app/src/main/res/drawable/splash_icon.xml  — 新增：Android 12+ splash icon 包装
android/app/src/main/res/values-v31/styles.xml     — 添加 splash icon
android/app/src/main/res/values-night-v31/styles.xml — 新增：深色模式 splash
lib/features/learn/learn_page.dart                 — 底部 padding 30→10→5
lib/features/archive/archive_page.dart             — 底部 padding 30→10→0
lib/features/learn/learn_settings_sheet.dart       — 底部 padding 40→10→5
```

### Session 18：第五轮真机测试修复（2026-05-09）

#### 5 个 Bug 修复

| # | 问题 | 根因 | 修复 |
|---|------|------|------|
| 1 | 启动页白色方块 | 单独 MaterialApp 中 AssetImage 加载失败 | app.dart 重写：precacheImage 预加载 + MaterialApp.router builder 叠加 splash，不再创建第二个 MaterialApp |
| 2 | 每日一词发音胶囊不对称 | 胶囊 padding:3 左右太窄，"美"和喇叭紧贴边缘 | 改为 symmetric(horizontal:12, vertical:4)，SizedBox(width:6) 均匀分隔 |
| 3 | 单词本满屏时新建按钮被遮 | ListView 底部 padding 仅 8px，extendBody 下被 Pill 遮挡 | 加至 `80 + padding.bottom`，给 Pill 留足空间 |
| 4 | 单词列表底部被导航键遮 | 对称 padding 底部仅 12px，没有导航栏高度 | 改为 `fromLTRB(16, 12, 16, 12 + padding.bottom)` |
| 5 | 拾词集默认单词本显示删除按钮 | PopupMenu 无条件显示"删除单词本" | 检查 `isDefault`，默认单词本不显示删除选项；标题改为动态取 notebook.name |

#### 修复文件（Session 18）
```
lib/app.dart                                     — splash 改用 builder 叠加 + precacheImage
lib/features/learn/learn_page.dart               — 发音胶囊 padding + spacing
lib/features/wordbook/wordbook_page.dart          — ListView 底部 padding
lib/features/wordbook/notebook_detail_page.dart   — 底部 padding + isDefault 隐藏删除
```

### Session 8：数据联动 + 自动播放 + 单词管理 + UI 打磨（2026-05-09）

#### LearnPage 数据刷新修复

**问题：** 学习完返回主页，新学词/待复习等数据不变。

**根因：** `LearnNotifier.load()` 只在 `initState` 调用一次；`review_sessions` 表学习过程中从未写入。

**修复：**
| 文件 | 改动 |
|------|------|
| `study_provider.dart` | `startSession` 创建/获取今日 session；`markCorrect`/`markIncorrect` 按新词/复习分类递增 session 字段并写入 DB |
| `study_page.dart` | 三个退出路径 pop 前调用 `learnStateProvider.notifier.load()` 刷新 |

#### LearnPage 文案修正
- 拾词集卡片：`新学` → `新词`
- 学习计划底部：`每日新词` → `每日新学`

#### 英美发音切换移除

**问题：** 美/英切换只改标签文字，音标数据不变——ECDICT 仅有单条音标。

**修复：** 6 个文件中所有 `swap_horiz` 图标 + 切换交互移除，"美"改为静态标签。`word_detail_page` 还修复了切到"英"时音标变空字符串的 bug。

#### 底部 Pill 毛玻璃效果
- `bottom_pill.dart`：`ClipRRect` + `BackdropFilter(ImageFilter.blur(10px))` 包裹
- `navigation_shell.dart`：Scaffold 加 `extendBody: true`，让页面内容延伸到 Pill 后方供模糊

#### 学习自动播放 TTS
- `_CardView` → `ConsumerStatefulWidget`：`initState` + `didUpdateWidget` 自动朗读单词
- `_DefinitionView` → `ConsumerStatefulWidget`：`initState` 串联朗读 单词→例句，`dispose` 取消
- "不认识"/"认识"/"下一词" 先 `tts.stop()` 再切换

#### 单词本卡片数据展示
- `wordbook_provider.dart`：新增 `NotebookStats`（newCount/reviewCount/masteredCount/totalCount）
- `notebookStatsProvider` 替代旧的 `notebookWordCountProvider`，按三种状态分别查询
- `wordbook_page.dart`：卡片从单纯的 `N 个词` 改为彩色标签行 `3新词 6待复习 3掌握`

#### 单词管理功能完善

**NotebookDetail 页面：**
| 功能 | 实现 |
|------|------|
| 管理→批量管理 | 选择模式：复选框 + 底部"移动"/"删除"按钮 |
| 管理→清空单词本 | 确认弹窗 → 删除全部单词 |
| 单词 more_horiz | PopupMenu：移动 / 删除 |
| 移动逻辑 | 弹单词本选择器 → `isNew=true, reviewCount=0, isMastered=false` 从头开始 |

**WordDetail 页面：**
| 改动 | 说明 |
|------|------|
| 右上角铅笔（废弃编辑模式） | → `more_vert` 弹出菜单：移动到其他单词本 / 删除单词 |
| 移除编辑状态 | `_editing`、`_textCtrl`、TextField 全部移除，`_WordHeader` 简化为纯展示 |

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
- [x] 单词移动/删除/批量管理（Session 8）
- [x] 学习自动播放 TTS（Session 8）
- [x] 数据联动刷新（review_session 写入 + 返回刷新，Session 8）
- [ ] 图片关联（imagePath 字段已有，但 UI 未接）
- [ ] 每日一词实际数据（当前为硬编码 ephemeral 示例）

### 测试
- [x] 真机基础测试（OCR + 词典离线化已修复，2026-05-09）
- [x] 真机完整流程测试（拍照→OCR→查词→保存→学习，Session 9 修复保存崩溃）
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
4. Session 4-7：底部 Pill 重构 + 空状态 UI + 配额逻辑 + 卡片 bug 修复 + OCR/词典离线化
5. Session 8（05-09）：数据联动刷新（review_session 写入 + 返回时 load）+ 自动播放 TTS + 单词管理（移动/删除/批量管理）+ 底部 Pill 毛玻璃 + 英美切换移除 + 单词本卡片数据展示 + 文案修正
6. Session 9（05-09）：真机测试 6 个 Bug 修复（启动页/滚动/毛玻璃透明度/设置保存遮挡/批量管理遮挡/拍照保存崩溃）+ 启动页（Web + Android）+ review_session Web 持久化
7. P1 全部完成。下一步可选方向：
   - 导出文件实际写入/分享（当前 exportToJson 生成字符串但未保存到文件）
   - 真机/模拟器测试验证
   - P2 功能（每日一词实际数据、图片关联、release 签名+图标）
