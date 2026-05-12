# WordSnap — 断点续接指南

> 最后更新：2026-05-12（Session 41 — WordChat 交互打磨 + 拍照直传聊天）

## 一、现在到哪了

**阶段：AI 配置完成 + WordChat 交互打磨。待真机验证。**

### 本轮改动（Session 41）
1. **已收录单词隐藏按钮**：`WordRepository` 双端加 `existsByText`，WordChat 本地查词结果用 `FutureBuilder<bool>` 判断，已收录则不显示"收录到单词本"
2. **每日一词居中**：单词+聊天图标用 `Center`+`mainAxisSize.min` 居中，单词在前图标在后
3. **WordChat 提示文本**：工具栏下方根据模式显示灰色小字 — 本地→"基于ECDICT+Tatoeba离线数据"，AI→"内容由AI生成 仅供参考"
4. **空状态图标**：本地查词搜索图标/AI 机器人图标，灰色→`signalBlue`，48→64px，文字 14→15px/`#999`→`#666`
5. **QuickChip 垂直居中**：`_QuickChip` Container 加 `height:28`+`alignment:center`，文字在胶囊内上下居中
6. **输入栏抬高**：底部 padding `8`→`14`（远离导航键）
7. **输入框去线框**：`OutlineInputBorder`+`BorderSide` → `BorderSide.none`+`filled:true`+`#F0F0F5` 浅灰底
8. **相机按钮**：输入栏左侧加相机按钮→拍照→涂抹OCR→单词确认→自动丢回聊天查词（`source=chat` 参数跳过结果页/保存页）
9. **APK**：`build/dist/WordSnap-v1.0.0-debug-20260512.apk`

### 本轮涉及文件
```
lib/features/chat/word_chat_page.dart              — 图标/文字/胶囊/输入栏/相机按钮
lib/features/capture/photo_capture_page.dart       — source=chat 简化确认页 + pop(word)
lib/core/router/app_router.dart                    — source 参数传递
lib/features/learn/learn_page.dart                 — 每日一词居中
lib/data/repositories/word_repository.dart          — existsByText (SQLite)
lib/data/repositories/word_repository_web.dart      — existsByText (Web)
test/services/review_service_test.dart              — FakeWordRepository.existsByText
```

### 待处理
- **问题1**：WordChat 本地查词释义与每日一词/单词详情不一致（ECDICT `definition`=英文, `translation`=中文，需真机验证）
- 真机验证全流程
- git commit
- `scripts/`、`images/` 设计素材整理

---

## Session 39 part 3 — UI 细节打磨 + 按压反馈（2026-05-12）

### 改动

1. **Pill 图标**：去掉 `color: Colors.white` 着色，PNG 原生颜色显示，outline↔filled 按压切换可见
2. **导航栏设置图标**：20→24px，新增按压态（品牌蓝↔灰），`_SettingsIconButton` StatefulWidget
3. **WordChat 标题**：`centerTitle: true`
4. **AppBar ☰**：从聊天记录改为打开设置抽屉（AI Key / Base URL / Model / 测试连接）
5. **工具栏 4 按钮**：全部`_ToolButton` 改为 StatefulWidget，按压态品牌蓝高亮
6. **"新对话"按钮**：当前会话无消息时禁用（Opacity 0.3，不响应点击）
7. **双抽屉架构**：`_drawerType` 切换 settings / history，一个 Scaffold.endDrawer 两种内容

### 涉及文件
```
lib/widgets/bottom_pill.dart                       — 去掉 color: Colors.white
lib/widgets/navigation_shell.dart                  — 设置图标 24px + 按压态 + AppColors import
lib/features/chat/word_chat_page.dart              — centerTitle / settings drawer / press feedback / 新对话禁用
```

---

## Session 39 part 2 — 图标替换 + WordChat 多会话（2026-05-12）

### 1. 图标整理 + 替换
- `icon/` 目录下 5 个自定义 PNG → `assets/icons/`（settings/edit_outlined/edit_filled/upload_outlined/upload_filled）
- pubspec.yaml 注册 `assets/icons/`
- navigation_shell.dart：`Icons.menu` → `Image.asset('assets/icons/settings.png')`
- bottom_pill.dart：编辑/上传按钮改用 PNG 资源，`_IconPillButton` 扩展支持 `outlinedAsset`/`filledAsset`
- 新增 `lucide_icons_flutter` 包（v3.1.13），4 个 WordChat 按钮图标：
  - `LucideIcons.bookMarked` — 本地查词
  - `LucideIcons.bot` — AI辅助
  - `LucideIcons.history` — 聊天记录
  - `LucideIcons.messageSquarePlus` — 新对话

### 2. WordChat 多会话架构
- **DB v5 migration**：新增 `chat_sessions` 表（id/mode/anchored_word/created_at/updated_at），`word_chat` 表新增 `session_id` 列 + FK
- **_onCreate** 也创建 chat_sessions 表，全新安装可用
- **Provider 重写**：
  - 新增 `ChatSession` 模型
  - `WordChatState` 新增 `sessions`/`currentSessionId`
  - `init()` — 加载/创建会话列表
  - `newSession()` — 创建空会话并切换
  - `switchSession(id)` — 切换到指定会话并加载消息
  - `deleteSession(id)` — 删除会话及消息
  - `_saveMessage()` 记录 session_id
- **UI 重写**：
  - 移除 AppBar 模式切换按钮
  - 4 按钮工具栏（`_ToolButton`）：本地查词/AI辅助/聊天记录/新对话
  - 活跃模式按钮品牌蓝高亮
  - 历史抽屉（`endDrawer`）：左侧滑出会话列表，点击切换/左滑删除
  - AI 图标统一改为 `LucideIcons.bot`

### 3. Web 构建修复
- `word_repository_web.dart` 缺少 `insertBatch()` → 添加

### 涉及文件
```
assets/icons/                                      — 5 个自定义 PNG
pubspec.yaml                                       — lucide_icons_flutter + assets/icons/
lib/core/database/database_helper.dart             — v5 migration
lib/features/chat/word_chat_provider.dart          — 多会话重写
lib/features/chat/word_chat_page.dart              — 4按钮工具栏 + 历史抽屉
lib/widgets/navigation_shell.dart                  — 设置图标
lib/widgets/bottom_pill.dart                       — 编辑/上传 PNG 图标
lib/data/repositories/word_repository_web.dart     — 补充 insertBatch
test/services/review_service_test.dart             — FakeWordRepository.insertBatch
```

---

## Session 39 — 5 项 Bug 修复（2026-05-12）

### 1. WordChat 入口红屏修复 + UI 调整

**问题：** 每日一词卡片和单词详情页 Chat 入口显示红屏；底部 Pill 入口标题显示 "AI 单词助手"；本地/AI 模式切换在页面顶部占用空间；退出后再进入状态残留。

**修复：**
- 标题：`AI 单词助手` → `WordChat`；有单词时 `与 $word 聊`
- 模式切换：从页面顶部 tab 改为 AppBar 右侧图标按钮（`menu_book_outlined` / `auto_awesome`）
- 状态重置：从 Pill 进入（无 initialWord）时调用 `WordChatNotifier.reset()`
- 移除未使用的 `Notebook` import

### 2. 拍照涂抹选词修复

**问题：** 涂抹手势不响应，无法在照片上涂抹选中单词。

**根因：** `GestureDetector` 在 Stack 中无 child，`deferToChild` 行为不会接收事件。

**修复：** `GestureDetector` 包裹 `Positioned.fill` + `behavior: HitTestBehavior.opaque`

### 3. 底部渐变背景不生效

**问题：** 底部渐变完全看不见，背景仍是纯白。

**根因：** 原渐变颜色 `#E8ECFC`（极浅淡紫）与背景 `#F9F9FB`（画布白）几乎同色。

**修复：**
- 渐变颜色改为品牌蓝 30% 透明度 → 全透明
- 覆盖高度 30% → 42% 屏幕高度
- 颜色使用 `Color(0x4D2F5CFF)` → `Color(0x002F5CFF)`

### 4. 底部 Pill 变细

**修复：** 外容器 padding top 8→6, bottom 24→18; 内容器 vertical 14→10

### 5. 文件导入生成单词本（新增功能）

**需求：** Pill 加文件上传入口，上传单词表文件自动生成单词本。

**实现：**
- `WordRepository.insertBatch()`：批量插入，使用 batch 事务
- `ImportWordlistSheet`：选择文件 → 解析预览 → 命名单词本 → 批量入库 → 完成
  - 支持纯文本（每行一个单词）和两列 CSV（word,definition）
  - 底部弹窗，与 CaptureSheet 一致
- `BottomPill`：新增 `upload_file` 图标按钮（第4个）

### 拍照涂抹选词修复（第二轮）

**问题：** 第一轮修复（Positioned.fill + HitTestBehavior.opaque）未生效。

**根因推测：** GestureDetector 在 Stack 内部与 Image/CustomPaint 层叠，Android hit testing 行为不可预期。

**修复：** GestureDetector 移到 ClipRRect 外层包裹，Stack 内只保留 Image + CustomPaint。

### 涉及文件
```
lib/data/repositories/word_repository.dart         — insertBatch()
lib/features/wordbook/import_wordlist_sheet.dart    — 新建
lib/widgets/bottom_pill.dart                       — 上传按钮 + 拍照涂抹修复2
lib/features/capture/photo_capture_page.dart       — 拍照涂抹修复2（GestureDetector 外移）
```

### 拍照涂抹：BoxFit.contain 坐标映射修复

**问题：** 涂抹生效后，OCR 识别不到单词或识别错误单词。

**根因：** `BoxFit.contain` 下图片居中缩放会留黑边，原代码直接用控件尺寸映射到原图，未考虑 letterbox 偏移。

**修复：** `confirmSelection()` 中计算 fitted 区域 + offset，涂抹坐标减去 offset 后按 fitted 尺寸缩放映射。

### 文件导入修复：中文过滤 + 滑动删除 + 键盘适配

**问题：** TXT 文件中英文/中文混排，中文被解析为单词；预览列表不能编辑删除；输入法遮挡标题输入框。

**修复：**
- TXT 解析改用 `[a-zA-Z]+` 提取英文单词，中文行自动跳过
- 预览列表项支持左滑删除（Dismissible）
- 底部留白适配 `viewInsets.bottom`，键盘弹起时自动撑高

### 学习页修复：每日一词刷新 + 标题英文对称

**问题：** 清空单词本后每日一词不消失；"正在学习的单词本""今日学习计划"右侧空白不对称。

**修复：**
- `ref.listen` 从 build 移到 initState，去掉 `prev!=null` 守卫
- 正在学习的单词本 → 右侧加 `Active Notebook`
- 今日学习计划 → 右侧加 `Today's Plan · May 12`

### 本次涉及文件
```
lib/features/capture/photo_capture_page.dart       — GestureDetector 移出 Stack 外包裹
lib/features/capture/photo_capture_provider.dart    — BoxFit.contain 坐标映射
lib/data/repositories/word_repository.dart          — insertBatch()
lib/features/wordbook/import_wordlist_sheet.dart     — 文件导入完整流程
lib/widgets/bottom_pill.dart                        — 上传按钮
lib/features/learn/learn_page.dart                  — 每日一词刷新 + 英文标题
```

---

## Session 38 — UI 打磨：底部渐变 + 卡片阴影 + Pill 全宽（2026-05-11）

### 改动

#### 1. NavigationShell 底部渐变背景
- body Column → Stack：底部叠加 30% 屏幕高度的淡蓝渐变（#E8ECFC → 透明）
- IgnorePointer 包裹不影响交互

#### 2. LearnPage 卡片去边框改阴影
- _NotebookCard / _StudyPlanCard / _DailyWordCard（含空状态）：border → boxShadow
- 阴影参数：黑色 4% 透明度、blurRadius 12、偏移 (0, 2)

#### 3. BottomPill 全宽
- 左右 padding 48 → 20，与"开始学习"按钮等宽
- vertical padding 12 → 14（视觉补偿）

### 涉及文件
```
lib/widgets/navigation_shell.dart           — 底部渐变 Stack 叠加
lib/widgets/bottom_pill.dart               — 全宽 padding
lib/features/learn/learn_page.dart          — 4 处卡片 border → boxShadow
```

#### 4. APK 构建
- Debug APK 构建成功：`build/app/outputs/flutter-apk/app-debug.apk` (208MB)
- 包含 Session 36-38 全部改动（WordChat + 涂抹选词 + UI 打磨）

---

## Session 37 — 拍照涂抹选词（2026-05-11）

### 需求
拍照查词交互优化：拍照 → 手指涂抹选中单词区域 → 裁剪区域 OCR → 结果页。替代原来的全图 OCR + word chip 列表。

### 改动

#### 1. OcrService 新增区域裁剪 OCR
- `processCroppedRegion()`：根据显示坐标 + 原图尺寸比例缩放 → 裁剪 + padding → 灰度化 → Tesseract → 返回第一个英文单词

#### 2. PhotoCaptureProvider 新增 selecting 步骤
- `PhotoStep` 枚举新增 `selecting`
- `processImage()`：跳过全图 OCR，拍照后直接进入 selecting
- `confirmSelection()`：裁剪原图 → 调用 `processCroppedRegion` → 查词
- `backToWords()`：回到 selecting 而非 ready

#### 3. PhotoCapturePage 涂抹选择 UI
- `_buildSelectingView()`：Stack（原图 + GestureDetector + CustomPaint 高亮笔触）
- 笔触效果：品牌蓝 30% 透明度、36px 圆头描边
- `_HighlighterPainter`：绘制所有笔触路径
- `_confirmCrop()`：计算所有笔触的 bounding rect → 缩放裁剪 OCR
- 底部按钮：撤销（清除最后一笔）+ 确认
- 移除 `_WordChip` 类
- 重拍/再拍一张按钮修复：重置 `_cameraOpened` 标志并重新打开相机

### 涉及文件
```
lib/data/services/ocr_service.dart                   — 新增 processCroppedRegion()
lib/features/capture/photo_capture_provider.dart      — 新增 selecting 步骤 + confirmSelection
lib/features/capture/photo_capture_page.dart          — 涂抹选择 UI + HighlighterPainter
```

---

## Session 36 — WordChat 功能完成（2026-05-11）

### 需求
用户确认 WordChat 设计方案后实施：底部 Pill 三按钮、本地查词+AI 辅助双模式、设置独立开关、全入口接入。

### 已完成（3 个任务）

#### 1. Bottom Pill 添加 Chat 按钮
- `bottom_pill.dart`：StatelessWidget→ConsumerWidget，拍照/记录右侧新增聊天气泡图标
- 按钮受 WordChat 开关控制（`wordChatEnabledProvider`），关闭时隐藏
- 点击跳转 `/chat` 路由

#### 2. 全应用入口接入
- `app_router.dart`：新增 `/chat` 路由，支持 `?word=` 查询参数 → WordChatPage
- `word_detail_page.dart`：AppBar 右侧新增聊天气泡按钮，传入当前单词
- `learn_page.dart`：每日一词卡片音标行右侧新增聊天气泡按钮
- `capture_result_page.dart`：保存按钮上方新增「AI 聊这个词」outline 按钮

#### 3. Settings WordChat 开关
- `api_config_provider.dart`：新增 `wordChatEnabledProvider` + `WordChatToggleNotifier`，默认开启，持久化到 config 表（key: `wordchat_enabled`）
- `settings_page.dart`：「AI 查词」区域新增 WordChat 开关行，显示当前状态文字

### 涉及文件
```
新增:
lib/features/chat/word_chat_page.dart           — 完整聊天 UI（Session 35 完成）
lib/features/chat/word_chat_provider.dart        — 状态管理（Session 35 完成）

修改:
lib/core/database/database_helper.dart           — v4 迁移 word_chat 表
lib/data/services/llm_dictionary_service.dart     — chatStream() SSE 流式对话
lib/core/router/app_router.dart                  — /chat 路由
lib/widgets/bottom_pill.dart                     — Chat 按钮
lib/features/wordbook/word_detail_page.dart       — AppBar 聊天气泡
lib/features/learn/learn_page.dart               — 每日一词聊天气泡
lib/features/capture/capture_result_page.dart     — AI 聊这个词按钮
lib/features/settings/api_config_provider.dart    — WordChat 开关 provider
lib/features/settings/settings_page.dart          — WordChat 开关 UI
```

### WordChat 架构
- **数据库**：`word_chat` 表（v4 迁移），存储对话历史
- **双模式**：local（ECDICT+Tatoeba 离线查词 + 收录）+ AI（LLM SSE 流式对话）
- **快速提问**：AI 模式提供 5 个快捷 chips（造个句子/近义词辨析/常见搭配/语法要点/词根词缀）
- **状态管理**：`WordChatNotifier` 管理 messages/mode/isStreaming/localResult/anchoredWord

---

## Session 35 — 例句三层数据源（2026-05-11）

### 根因
1. **ECDICT 无例句**：表结构确认只有 `word/phonetic/definition/translation/pos/tag/exchange`，无 example 列
2. **LLM 可能静默失败**：`print()` 在 release APK 不可见，失败时回退 ECDICT → 无例句
3. **toCacheMap bug**：包含 `partOfSpeech` 列但 `dictionary_cache` 表没有这列 → insert 抛异常被 `catch (_) {}` 吞掉 → 缓存永远写不进去

### 修复：三层例句数据源

**新查词链路：** 缓存 → ECDICT(释义) → LLM完整 → LLM轻量例句 → Tatoeba离线 → 返回

1. **`dictionary_result.dart`** — `toCacheMap` 移除 `partOfSpeech`
2. **`dictionary_service.dart`** — 重写 lookup()：ECDICT 先查(100%有释义) → LLM full → LLM example-only → Tatoeba fallback
3. **`llm_dictionary_service.dart`** — 新增 `lookupExample()`，极简 prompt 只请求 `{"sentence":"...","translation":"..."}`
4. **`tatoeba_service.dart`**（新）— Tatoeba 离线句子库查询，与 ECDICT 同架构（assets → app doc dir → read-only SQLite）
5. **`scripts/build_tatoeba_db.py`**（新）— 自动下载 Tatoeba sentences.csv + links.csv → 过滤 eng→cmn 句对 → 按 ECDICT 词表筛选 → 构建 word 索引 SQLite
6. **`word_detail_page.dart`** — 例句为空显示"暂无例句"
7. **`pubspec.yaml`** — 新增 `assets/tatoeba_slim.db`

### Tatoeba 数据
- 来源：tatoeba.org 每周导出
- 201 万英句 × 8.5 万中句 → 7.6 万 eng→cmn 句对
- 按 ECDICT 词表过滤后：69,378 句对 / 160,859 条词索引
- 数据库大小：18.1 MB

### APK
`build/dist/wordsnap-v1.0.0-20260511-1940.apk`（94MB）

### 涉及文件
```
新增:
lib/data/services/tatoeba_service.dart
scripts/build_tatoeba_db.py

修改:
lib/data/services/dictionary_result.dart       — toCacheMap 移除 partOfSpeech
lib/data/services/dictionary_service.dart       — ECDICT→LLM→Tatoeba 三层链
lib/data/services/llm_dictionary_service.dart    — 新增 lookupExample()
lib/features/wordbook/word_detail_page.dart      — 空例句提示
pubspec.yaml                                     — tatoeba_slim.db 资产
```

---

## Session 34 — 输入查词交互重构 + 例句 + 卡片交互（2026-05-11）

### 1. LLM 例句强制生成
- prompt 增加 `MUST be provided, never leave empty or null` 强制要求
- 追加兜底指令：`If you are unsure about the word, create a natural example sentence`

### 2. 单词本卡片点击跳转
- `_NotebookCard` 新增 `notebookId` 参数
- 封面图标和名称均可点击 → `/wordbook/:id`

### 3. 每日一词增强
- 点击单词文字 → `/word/:id` 单词详情页
- 新增「↻ 换一个」按钮，随时手动切换
- 换词逻辑：`(日期种子 + dailyWordIndex) % 词数`，同一天不会重复

### 涉及文件
```
lib/data/services/llm_dictionary_service.dart — prompt 强化例句要求
lib/features/learn/learn_provider.dart         — dailyWordIndex + nextDailyWord()
lib/features/learn/learn_page.dart             — 封面/标题/单词可点击 + 换一个按钮
```

---

## Session 34 前半 — 输入查词交互重构（2026-05-11）

### 问题
CaptureSheet 底部弹出层交互混乱：500ms debounce 自动查询，用户打字过程中结果闪现；缺少显式"确认"操作；提示字过大（20px）。

### 方案
两步交互：输入→确认→跳转结果页（可修改重查）→保存

### 改动

#### 1. CaptureSheet 简化
- 移除 debounce 自动查询、行内结果展示、单词本选择器、保存按钮
- 只保留：输入框 + 确认按钮
- hint: `请输入或粘贴你想记录的单词`（14px 灰色）
- 支持键盘 `done` 和按钮两种确认方式
- 确认后：setInput → lookup → pop sheet → push `/capture/result`

#### 2. 新建 CaptureResultPage（全屏页面）
- 顶部：可编辑输入框（预填单词）+ 搜索图标按钮，支持修改后重新查询
- 中间：查询结果卡片（复用 _ResultCard）
- 底部：单词本选择器 + 取消/确认添加按钮
- AppBar 带返回箭头

#### 3. CaptureNotifier 新增 reset()
- 每次打开 CaptureSheet 重置状态，避免上次残留

#### 4. 路由
- 新增 `/capture/result` → CaptureResultPage

### 涉及文件
```
新增:
lib/features/capture/capture_result_page.dart

修改:
lib/features/capture/capture_sheet.dart        — 大幅简化，仅输入+确认
lib/features/capture/capture_provider.dart      — 新增 reset()
lib/core/router/app_router.dart                 — 新增 /capture/result 路由
```

---

## Session 33 — 3 个 Bug 修复 + 展示格式 Round 2（2026-05-11）

### Bug 1：空数据状态下每日新学显示 10

**根因：** `database_helper.dart` `_onCreate` 创建默认笔记本"拾词集"时硬编码 `dailyNewWordLimit: 10`

**修复：** `dailyNewWordLimit: 10` → `0`，用户未主动设置学习计划时不显示默认值

涉及文件：`lib/core/database/database_helper.dart`

### Bug 2：每日一词 / 单词详情 / 学习界面格式错误

三个子问题：
1. **发音胶囊显示的不是音标** — ECDICT phonetic 格式与 LLM 不一致
2. **显示英文释义而非"词性+中文释义"** — ECDICT translation 带词性前缀（如 "n. "），与 `partOfSpeech` 冗余
3. **例句没有播放按钮** — `_DailyWordCard` 缺失

**修复：**
- `dictionary_result.dart`：`primaryDefinition` 正则去除 ECDICT 词性前缀 `^[a-z]+\.\s*`
- `learn_page.dart` `_DailyWordCard`：释义行合并 `partOfSpeech + definition`，例句添加播放按钮+翻译
- `study_page.dart` `_DefinitionView`：释义格式统一 + 例句翻译支持
- `word_detail_page.dart`：释义格式统一 + 例句翻译填入实际数据

涉及文件：`lib/data/services/dictionary_result.dart`、`lib/features/learn/learn_page.dart`、`lib/features/learn/study_page.dart`、`lib/features/wordbook/word_detail_page.dart`

### Bug 3：记录按钮输入即查 + OCR 不灵敏

**Bug 3a 根因：** `capture_sheet.dart` `_onInputChanged` 输入 ≥2 字符即触发查词，无 debounce

**修复：** 添加 500ms `Timer` debounce，用户停止输入后才触发查词

**Bug 3b 根因：** Tesseract 默认参数对屏幕文字（反光、摩尔纹）不友好；`tesseract_ocr` 0.5.0 包的 `extractText` 未转发 PSM 配置

**修复：**
- `ocr_service.dart`：OCR 前加灰度化预处理（`image` 包），减少屏幕照片的彩色噪声
- `pubspec.yaml`：新增 `image: ^4.5.4` 依赖

涉及文件：`lib/features/capture/capture_sheet.dart`、`lib/data/services/ocr_service.dart`、`pubspec.yaml`

---

## Session 32 — Logo 字标程序化重渲染 + 构建脚本 + 横板 logo（2026-05-10）

### 需求
- 查词结果展示太多条释义（ECDICT translation 包含所有词性释义）
- 每日一词显示全部释义 + 硬编码占位符 "名声是短暂的..."
- 用户期望格式：发音 → 中文释义 → 例句 → 例句翻译
- 接入 AI 大模型查词，用户可自定义 API Key

### 已完成

#### 1. LLM 查词服务
- 新增 `LlmDictionaryService`：OpenAI 兼容协议，prompt 返回 JSON `{phonetic, definition, example, exampleTranslation}`
- 新增 `ConfigRepository`：API 配置持久化到 SQLite config 表
- 新增 `api_config_provider.dart`：Riverpod 状态管理
- 默认预设：智谱 API (`open.bigmodel.cn`)，模型 `glm-4-flash`（完全免费）

#### 2. 查词流程重构
- `DictionaryService.lookup()` 三级策略：
  1. 查本地缓存（`dictionary_cache` 表）
  2. LLM 查词（需已配置 API Key）
  3. ECDICT 离线兜底
- 查词结果自动写入缓存，同一单词不重复调 API

#### 3. 数据库 v3 迁移
- `words` 表新增 `exampleSentence`、`exampleTranslation` 列
- 新增 `dictionary_cache` 表（word 为主键，缓存查词结果）
- 新增 `config` 表（key-value 存储 API 配置）
- `_onUpgrade` v2→v3：ALTER TABLE + CREATE TABLE IF NOT EXISTS

#### 4. 模型更新
- `DictionaryResult`：新增 `exampleSentence`、`exampleTranslation`、`primaryDefinition` getter、`fromLlmJson`/`fromCache`/`toCacheMap`
- `Word`：新增 `exampleSentence`、`exampleTranslation` 字段（copyWith/toMap/fromMap 全部更新）

#### 5. 释义展示统一优化
- **查词结果卡片**（capture_sheet / photo_capture_page / share_receipt_sheet）：
  - 单词 → 音标胶囊（美 /phonetic/ 🔊） → 中文释义 → 例句（斜体） → 例句翻译
  - 不再显示英文释义和词性标签
  - 例句区域仅在有数据时显示
- **每日一词卡片**（learn_page）：
  - 同等格式：单词 → 音标 → 中文释义 → 例句 → 例句翻译
  - 移除硬编码占位符 "名声是短暂的，不要追逐它。"

#### 6. 保存逻辑修复
- 三个 save 方法（capture / photo / share）统一改为存储 `primaryDefinition`（首行释义）
- 不再把所有释义拼成一个大字符串

#### 7. 设置页
- 新增「AI 查词」配置区：Base URL / API Key / Model
- 测试连接按钮（查 "hello" 验证配置）
- 状态指示：未配置（灰色）/ 已配置（绿色 + 模型名）

### 涉及文件

```
新增:
lib/data/services/llm_dictionary_service.dart
lib/data/repositories/config_repository.dart
lib/features/settings/api_config_provider.dart

修改:
lib/core/database/database_helper.dart         — v3 迁移
lib/data/models/word.dart                      — 新增 2 字段
lib/data/services/dictionary_result.dart        — 新增字段 + LLM/缓存工厂
lib/data/services/dictionary_service.dart       — LLM优先 + 缓存 + ECDICT兜底
lib/features/capture/capture_provider.dart      — save 精简
lib/features/capture/photo_capture_provider.dart — save 精简
lib/features/capture/capture_sheet.dart         — ResultCard 新格式
lib/features/capture/photo_capture_page.dart    — ResultCard 新格式
lib/features/capture/share_receipt_sheet.dart   — save + ResultCard 新格式
lib/features/learn/learn_page.dart              — DailyWordCard 新格式
lib/features/settings/settings_page.dart        — API 配置区
```

### 架构决策
- LLM API 用 OpenAI 兼容协议（`/chat/completions`），方便用户切换任意厂商
- 默认内置智谱免费 API（`glm-4-flash` 完全免费不限量），零成本起步
- 缓存用 SQLite 而非文件，利用已有 sqflite 依赖，查词毫秒级响应
- API 配置存 config 表而非 shared_preferences，避免新增依赖
- ECDICT 保留作为兜底，确保离线可用

---

## Session 30 — LLM 连接修复 + 缓存污染 + 学习计划空状态（2026-05-10）

### 问题
用户测试报告三个 bug：
1. LLM 大模型连接失败（智谱 API 有余额但调用不成功）
2. 新增单词没有例句和例句翻译
3. 新装 APP 学习计划显示 10/1/10 而非 0/0/10

### 修复

#### 1. ECDICT 缓存污染（Bug #2 根因）
- `dictionary_service.dart`：ECDICT 回退结果不再写入缓存（`_putCache(ecdict)` 移除）
- 之前：LLM 失败 → ECDICT 兜底 → 缓存 ECDICT 结果 → 同一单词再查直接命中缓存 → LLM 永不再试
- 现在：只有 LLM 成功结果才缓存，ECDICT 每次实时查询

#### 2. LLM 错误日志
- `llm_dictionary_service.dart`：所有错误路径添加 `print()` 输出
  - HTTP 非 200 → 打印状态码和响应体
  - choices 为空 → 打印完整响应
  - content 为空 → 打印提示
  - JSON 解析失败 → 打印原始 content
  - 异常 → 打印 `$e`
- 新增 `testConnection()` 方法：返回具体错误信息（HTTP 状态码 + 响应片段）
- `settings_page.dart`：测试连接改用 `testConnection()`，SnackBar 显示 "连接失败: HTTP 401: ..." 而非泛化的 "连接失败，请检查配置"

#### 3. 学习计划空状态防护
- `learn_provider.dart`：配额计算增加 `.clamp(0, dbNewCount)` / `.clamp(0, dbReviewCount)`
- 即使 `totalWords` 非零，配额也不会超过实际可用词数
- 增强调试日志：`print` 增加 dbNew/dbReview 值

### 涉及文件
```
lib/data/services/dictionary_service.dart     — ECDICT 不再缓存
lib/data/services/llm_dictionary_service.dart — 错误日志 + testConnection()
lib/features/learn/learn_provider.dart        — 配额 clamp 到实际词数
lib/features/settings/settings_page.dart      — 测试连接显示详细错误
```

### 下一步
1. 真机测试 LLM 连接（设置 → 测试连接 → 查看具体错误信息）
2. 确认新词例句是否正常（LLM 成功后自动缓存，下次免调 API）
3. 确认学习计划空状态（全新安装应为 0/0/10）

---

## Session 32 — Logo 字标程序化重渲染 + 构建脚本 + 横板 logo（2026-05-10）

### 已完成

#### 横板 Logo 设计
- 参考 `字母样式.png` 设计稿，Python/Pillow 像素级着色生成 wordmark
- `w` 区域 → 品牌蓝 `#2F5CFF`，`ordsnap` 区域 → 墨黑 `#0B0B0F`，`p` 反色区 → 橙色 `#FFA940`
- 6 轮脚本迭代（analyze_letters → generate_wordmark v1-v4 → render_wordmark_final → render_wordmark_clean）
- 最终采用用户 Photoshop 精修版（反锯齿优于程序化渲染）
- 输出：`横板logo.png`、`横板logo.psd`

#### 构建脚本
- 新增 `scripts/build_apk.py`：自动读取 pubspec.yaml 版本号，输出命名 APK 到 `build/dist/`
- 命名格式：`WordSnap-v{版本号}-{release/debug}-{日期}.apk`

#### 图像素材
- `images/` 目录：设计中间文件和参考素材（ordsnap_colored.png, wordsnap_text_colored.png 等）

---

## Session 31 — APK 构建成功（2026-05-10）

### 问题
`sqlite3` 包 native assets hook 需从 GitHub 下载 `libsqlite3.so`，直连超时导致构建失败。

### 解决
- 用户开启代理后 `flutter build apk --debug` 成功
- APK: `build/app/outputs/flutter-apk/app-debug.apk` (183MB)
- `pubspec.yaml` 新增 `sqlite3_flutter_libs: ^0.5.34` 依赖

---

## Session 28 — Logo 字标定稿 + 导航栏接入（2026-05-10）

### 已完成

#### Logo 字标
- 最终设计：纯文字版 `w`(品牌蓝) + `ordsnap`(墨黑) + `p`孔橙色填充，无图标
- 用户用 Photoshop 完成最终渲染 + 裁切（去掉左侧图标）
- 程序化裁切失败：gap detection 误判，裁掉了 "wor" 只留 "dsnap"
- 文件：`assets/logo/wordmark.png`（用户裁切后替换）
- 品牌色：蓝 `#2F5CFF`、橙 `#FFA940`、墨黑 `#0B0B0F`

#### 导航栏接入
- `navigation_shell.dart`：AppBar 标题改为 `Image.asset('assets/logo/wordmark.png', height: 44)`
- 去掉了左侧图标，只保留文字字标
- toolbarHeight: 72, titleSpacing: 16

#### 空数据配额修复
- `learn_provider.dart`：`totalWords == 0` 时新学词和待复习配额强制为 0

### 教训
- Python/Pillow 做像素级 logo 精修不适合：反馈循环太慢，白边/反锯齿处理不精确
- 程序化裁切也不可靠：gap/edge detection 容易误判
- Photoshop 才是 logo 设计和裁切的正确工具

### 构建命名规范
- 格式：`WordSnap-v{版本号}-{release/debug}-{日期}.apk`
- 脚本：`python scripts/build_apk.py [release|debug]`
- 输出：`build/dist/`

### 下一步
1. GitHub 推送：`WordSnap-github/` 关联远程仓库并 push
2. 可选：web 启动页、设置页等处同步更新 logo

## Session 27 — 开源准备 + 品牌重塑（2026-05-10）

### 已完成

#### 1. 开源准备
- 创建 `WordSnap-github/` 干净发布目录（119 files, 独立 git 仓库）
- 添加 Apache 2.0 LICENSE
- 重写 README.md（中英文功能列表、技术栈、截图、SRS 算法）
- 拷贝 `screenshots/` 4 张精选截图
- `.gitignore` 已配置完整排除规则

#### 2. 项目目录清理
- 删除 `%LOCALAPPDATA%/` （4781个 npm 缓存文件）
- 删除 `WordSnap 1.0/` 备份目录
- 删除 40+ 根目录调试截图 PNG
- 删除 `snap.txt`、`wordsnap.iml`、`.flutter-plugins-dependencies`
- 新建 `dev/` 目录，CONTINUE.md 移入
- `git commit` — 5158 files changed, -1,065,045 lines

#### 3. 去中文名
- 所有 "见词" → "WordSnap"
- 涉及文件：`app.dart`、`navigation_shell.dart`、`settings_page.dart`、`AndroidManifest.xml`、`web/index.html`、`README.md`、`CONTINUE.md`

**阶段：P0/P1 全部完成，测试体系建立。41 个测试全部通过。**

## Session 26 — 补全测试（2026-05-10）

### 模型单元测试（22 tests）

| 文件 | 测试数 | 覆盖 |
|------|--------|------|
| `test/models/word_test.dart` | 6 | toMap/fromMap roundtrip, null fields, copyWith |
| `test/models/notebook_test.dart` | 4 | toMap/fromMap roundtrip, defaults, copyWith |
| `test/models/review_session_test.dart` | 3 | toMap/fromMap roundtrip, defaults, copyWith |
| `test/models/word_context_test.dart` | 3 | all ContextType values, null source, omit null |
| `test/models/dictionary_result_test.dart` | 6 | fromEcdict full/partial/empty, _expandPos, fromJson |

### ReviewService 单元测试（12 tests）

| 测试组 | 测试数 | 覆盖 |
|--------|--------|------|
| getMode | 3 | normal (≥10新词), transition (1-9), pureReview (0) |
| getTodayQueue | 3 | 10:1 interleave, dailyLimit, learnedAt 排序 |
| getPureReviewQueue | 1 | 排除 mastered，按 learnedAt 排序 |
| markCorrect | 3 | +1, 阈值10=掌握, 持久化 |
| markIncorrect | 1 | reviewCount 归零 |
| markNewCorrect | 1 | isNew→false, reviewCount→1 |

使用 `FakeWordRepository` (in-memory) 模拟数据库，无需 mock 框架。

### Widget 测试（7 tests）

| 页面 | 测试数 | 覆盖 |
|------|--------|------|
| LearnPage | 5 | loading spinner, error 重试, 学习计划, 每日一词, 空状态 |
| ArchivePage | 1 | 已掌握/总量/学习天数 统计数字 |
| WordbookPage | 1 | 多单词本卡片名称渲染 |

使用 ProviderScope + overrideWith 注入 fake notifiers，避免数据库依赖。

### 测试架构

```
test/
├── models/
│   ├── word_test.dart
│   ├── notebook_test.dart
│   ├── review_session_test.dart
│   ├── word_context_test.dart
│   └── dictionary_result_test.dart
├── services/
│   └── review_service_test.dart
└── widgets/
    └── core_pages_test.dart
```

### 运行测试

```bash
flutter test                    # 全部 41 tests
flutter test test/models/       # 仅模型
flutter test test/services/     # 仅服务
flutter test test/widgets/      # 仅 widget
```

### 集成测试（3 flows，需真机）

| 测试 | 覆盖 |
|------|------|
| App 启动 → LearnPage | 启动页渲染，notebook card + 学习计划 |
| 底部 Tab 切换 | Learn ↔ Wordbook ↔ Archive 三页切换 |
| 新建单词本 | 弹 Sheet → 输入名称 → 创建 → 列表出现 |
| 跳转学习页 | 点"开始学习" → 进入 StudyPage |

运行（需要连接设备）：
```bash
flutter test integration_test/ -d <device_id>
```

---

## Session 25 — 数据复活 bug 修复

### 根因两条

1. **`_onUpgrade` 毁库重建**：DB 版本 1→2 时 `_onUpgrade` DROP 全部表再 `_onCreate`，用户数据全丢。`seedIfEmpty` 守卫 `notebooks > 1` 在只剩 1 个笔记本时触发重新播种，23 个种子词全部复现。

2. **`seedIfEmpty` 守卫脆弱**：判断 `COUNT(*) FROM notebooks > 1` 作为"是否已播种"标志。用户删掉 2 个预置笔记本只剩默认时，守卫失效。

### 修复

- `_onUpgrade`：DROP TABLE 改为空实现（v1→v2 schema 无变化）
- `seedIfEmpty`：守卫改为 `COUNT(*) FROM words > 0`
- **移除种子数据调用**：`main()` 不再调用 `seedIfEmpty()`。全新安装只有空默认单词本"拾词集"

---

## 启动页白方块问题——完整排查记录

### 现象
vivo 真机（Android 12+）启动时出现白色方块/圆底板，持续多轮尝试（Session 9 ~ Session 23）。

### 最终根因（两条）

**1. Android 12+ 系统启动页对非 adaptive 图标的白色底板**
- Android 12（API 31）引入了强制系统启动页，显示 `windowSplashScreenBackground` + `windowSplashScreenAnimatedIcon`
- 如果 App 没有 adaptive launcher icon（`mipmap-anydpi-v26/ic_launcher.xml`），系统将默认 App 图标（非 adaptive PNG）渲染在白色圆形底板上
- 即使不设置 `windowSplashScreenAnimatedIcon`，系统也会用默认 App 图标并加白底板

**2. Flutter 端多余的启动层（`_SplashImage`）造成闪烁**
- Flutter 的 `Image.asset` 需要异步加载，加载前显示空白
- 原生 `windowBackground` 本就可以桥接到 Flutter 首帧，无需 Flutter 层再画一层

### 错误尝试（Session 9 ~ 22，均无效）

| 尝试 | 做法 | 结果 |
|------|------|------|
| 1 | `_SplashImage` 用 `Image.asset` 显示启动图 | 白方块（图片异步加载延迟） |
| 2 | 加 `Container(color: blue)` 包裹 | 蓝屏→白方块→图片，更差 |
| 3 | Python 合成蓝底+logo 合并图，2秒延迟 | 蓝屏先出现 |
| 4 | `precacheImage` 预加载 | 仍有一帧白 |
| 5 | 原生 `launch_background.xml` 替换为全屏图 bitmap | APK 解析失败（`<bitmap>` 不能作为 windowBackground 根元素） |
| 6 | `<bitmap>` 根元素作为 `splash_icon` drawable | 白方块（`<bitmap>` 不是有效的 `AnimationDrawable`） |
| 7 | 移除 `windowSplashScreenAnimatedIcon` | 白方块（系统回退到非 adaptive App 图标） |
| 8 | `<animation-list>` 包裹 bitmap | 白方块（仍不是系统期望的格式） |
| 9 | `<layer-list>` 包裹 bitmap | 白方块（同上） |

### 正确方案（Session 23）

**三步修复，缺一不可：**

**第一步：创建 adaptive launcher icon**
```xml
<!-- mipmap-anydpi-v26/ic_launcher.xml -->
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@color/splash_bg"/>
    <foreground android:drawable="@drawable/ic_launcher_foreground"/>
</adaptive-icon>

<!-- drawable/ic_launcher_foreground.xml -->
<inset xmlns:android="http://schemas.android.com/apk/res/android"
    android:drawable="@drawable/splash_logo"
    android:inset="18dp" />
```
- adaptive icon 不会被 Android 12+ 加白色底板
- 18dp inset = (108dp画布 - 72dp安全区) / 2，保证图标不越界

**第二步：NormalTheme.windowBackground 改为品牌蓝色**
```xml
<!-- 所有 values*/styles.xml 中 -->
<style name="NormalTheme">
    <item name="android:windowBackground">@color/splash_bg</item>
</style>
```
- 防止 LaunchTheme→NormalTheme 切换时的白屏间隙

**第三步：删除 Flutter 端启动层**
- `_SplashImage` 完全移除，`StatefulWidget`→`StatelessWidget`
- 原生 `windowBackground`（launch_background.xml 全屏图）直接桥接到 Flutter 首帧

### 教训
1. **Android 12+ 启动页 = 系统层 + Activity层 + Flutter层，三层都要处理**
2. **Android 12+ 系统启动页图标必须是 adaptive 格式，否则自动加白底板**
3. **不要用 `<bitmap>` 作为 drawable 根元素——`windowSplashScreenAnimatedIcon` 要求 `AnimationDrawable`**
4. **Flutter 端不要加启动页——原生的 `windowBackground` 天然桥接 Flutter 首帧**
5. **NormalTheme 的 background 要和 LaunchTheme 一致，避免切换白屏**

---

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

### Session 20：splash 最终方案 — 使用设计截图（2026-05-09）

**问题：** 之前所有方案（原生 XML / 第二个 MaterialApp / precacheImage + builder 叠加 / Python 合成图）都无法在 vivo 上正常显示 splash logo，始终显示白色方块。

**最终方案：** 直接用原始设计截图 `00-启动页.png` 作为 splash 图片。
- 复制到 `assets/logo/splash.png`，用 Pillow 从 400×860 放大到 1080×2322
- `app.dart`：`_showSplash ? _SplashImage() : ProviderScope(...)` — 最简洁的 if/else
- `_SplashImage` = `Image.asset('assets/logo/splash.png', fit: BoxFit.cover)` — 纯一张图，无 builder/无 Stack/无任何分层
- 2 秒固定显示时长

#### 修改文件（Session 20）
```
assets/logo/splash.png                            — 最终启动页图片（基于设计截图）
lib/app.dart                                      — 最简 splash：条件渲染，单张图
```

### Session 19：splash 合并图片 + 胶囊对齐 + padding 微调（2026-05-09）

| # | 问题 | 根因 | 修复 |
|---|------|------|------|
| 1 | 启动页蓝底先出，logo 后出且一闪而过 | precacheImage 异步等待 → logo 加载完才显示，100ms 后消失 | 用 Pillow 生成 `splash_combined.png`（蓝底+logo 合并），`Image.asset` 直接全屏显示，1.5s 固定时长 |
| 2 | 发音胶囊不对称 | '美'(11px) 和音标(12px) 字号不同，Row center 对齐仍有视觉偏差 | 统一字号为 12 |
| 3 | 单词本底部 padding 过多 | 80 留白太大 | 80 → 20 |

#### 新增文件
```
assets/logo/splash_combined.png                  — Python Pillow 生成：1080×2400 蓝底 + 180×180 logo 居中
```

#### 修复文件（Session 19）
```
lib/app.dart                                     — 使用 splash_combined.png 单图，1.5s 固定显示
lib/features/learn/learn_page.dart               — '美' 字号 11→12
lib/features/wordbook/wordbook_page.dart          — 底部 80→20
```

### Session 21：splash 最终修复（2026-05-09）

**问题链条：**
1. 启动时先显示品牌蓝屏，再出现启动图 → 过渡不流畅
2. 蓝屏来自 Android 原生 `LaunchTheme.windowBackground` = `@drawable/launch_background`（layer-list：纯蓝底色 + 居中 logo bitmap，vivo 上 bitmap 不渲染）
3. 尝试新增 `splash_background.xml`（独立 `<bitmap>` 根元素）→ 导致"软件包无法解析"

**最终方案：**
- `launch_background.xml` 内容改为单层完整启动图：`<bitmap android:gravity="fill" android:src="@drawable/splash_full" />`
- 不新增 XML 文件，styles 保持引用 `@drawable/launch_background`
- `splash_full.png`：基于设计图 `00-启动页.png`，Pillow 放大到 1080×2322 放入 drawable 目录
- Flutter 端：`_SplashImage` = 纯 `Image.asset('splash.png', fit: BoxFit.cover)`，2 秒后切换到主应用

**架构：** Android 原生 windowBackground = 完整启动图 → Flutter 首帧 = 同一张图 → 无缝衔接

#### 修改文件（Session 21）
```
android/app/src/main/res/drawable/launch_background.xml    — 图层改为单张完整图
android/app/src/main/res/drawable/splash_full.png          — 完整启动图素材
assets/logo/splash.png                                     — Flutter 端启动图
lib/app.dart                                               — _SplashImage 纯单图
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

## Session 24 — 数据刷新 + 每日一词 fallback + UI 细节

### 数据刷新机制（dataRefreshTrigger）

**问题：** 删除/移动/清空单词后，单词本数量、LearnPage 统计、每日一词全都不更新。根因是 Riverpod `FutureProvider.family` 缓存永久有效，没有失效机制。

**方案：** 全局 `dataRefreshTrigger` StateProvider 计数器，所有数据依赖方 watch 它。

```dart
// wordbook_provider.dart
final dataRefreshTrigger = StateProvider<int>((ref) => 0);

final notebookStatsProvider = FutureProvider.family<NotebookStats, int>((ref, notebookId) async {
  ref.watch(dataRefreshTrigger); // 任何数据变更后重新查询
  // ...
});
```

**所有需要通知变更的位置 bump trigger：**

| 文件 | 位置 |
|------|------|
| `notebook_detail_page.dart` | 删除单词、批量删除、清空单词本、移动单词、批量移动、删除单词本 |
| `word_detail_page.dart` | 删除单词、移动单词 |
| `learn_page.dart` | `ref.listen(dataRefreshTrigger)` 自动 reload |
| `study_page.dart` | 3 个退出路径均 bump trigger |
| `capture_sheet.dart` | 保存后 bump |
| `photo_capture_page.dart` | 保存后 bump |
| `share_receipt_sheet.dart` | 保存后 bump |

### 级联删除

`NotebookRepository.delete()` 删除单词本前先删除所有关联单词：
```dart
await db.delete('words', where: 'notebookId = ?', whereArgs: [id]);
await db.delete('notebooks', where: 'id = ?', whereArgs: [id]);
```

### 学习设置改进

- 每日新词上限步长从 1 改为 10
- 减号按钮最低到 10（而非 0）
- 新增重置按钮（设为 0）
- 宽度调整：28→36 以容纳三位数

### 每日一词跨单词本 fallback

**问题：** 当前单词本清空后，即使其他单词本有单词，每日一词也显示空状态。

**修复：** `learn_provider.dart` 选词逻辑先尝试当前单词本，没词则 fallback 到其他单词本；`_DailyWordCard` 改为 `dailyWord == null` 判定空状态（而非 `total == 0`），来源标签显示实际单词本名称。

### 弹窗底部 padding

`notebook_detail_page.dart` 和 `word_detail_page.dart` 的 `_showNotebookPicker()` 均加上 `MediaQuery.of(ctx).padding.bottom`。

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
# Debug APK: build/app/outputs/flutter-apk/app-debug.apk (203MB)

flutter build apk --release
# Release APK: build/app/outputs/flutter-apk/app-release.apk (83MB, 已签名)
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
- [x] 图片关联（已移除该功能，用户不需要）
- [x] 每日一词实际数据（日期确定性选取，支持跨单词本 fallback，Session 22/24 完成）
- [x] 全局数据刷新机制（dataRefreshTrigger 统一变更通知，Session 24 完成）
- [x] 级联删除（删除单词本先删关联单词，Session 24 完成）
- [x] 学习设置：步长 10 + 重置按钮 + 移动弹窗底部 padding（Session 24 完成）

### 测试
- [x] 真机基础测试（OCR + 词典离线化已修复，2026-05-09）
- [x] 真机完整流程测试（拍照→OCR→查词→保存→学习，Session 9 修复保存崩溃）
- [x] Widget test（Session 26：41 tests，模型 22 + 服务 12 + Widget 7）
- [x] Integration test（Session 26：3 flows，需真机运行 `flutter test integration_test/`）

### 构建
- [x] Release APK 签名配置（Session 22：生成 RSA 2048 keystore + key.properties + build.gradle.kts 签名配置，83MB release APK 构建通过）
- [x] App 图标替换（Session 22：flutter_launcher_icons 生成品牌图标）

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
   - 导出文件实际写入/分享（Session 22 已实现：writeExportFile 写入文档目录 + share_plus 系统分享）
   - 真机/模拟器测试验证
   - P2 功能（每日一词实际数据、图片关联、release 签名+图标）
8. Session 22（05-09）：App 品牌图标替换 + Release APK 签名配置 + imagePath 功能移除 + JSON 导出显示保存位置 + 每日一词实际数据
   - 完成 App 图标：flutter_launcher_icons 从 assets/logo/wordsnap-icon-app.png 生成 android 密度图标
   - 完成 Release 签名：生成 RSA 2048 keystore（wordsnap-release.jks，36500天有效期），key.properties 配置 + build.gradle.kts 读取签名信息
   - 完成 imagePath 移除：从 Word、WordContext、数据库 schema 中完全移除
   - 完成 JSON 导出：保存到 getApplicationDocumentsDirectory()，导出成功弹窗显示目录路径+文件名
   - 完成每日一词：根据当前日期和总词数确定性选取真实词条
   - .gitignore 添加 android/key.properties + android/*.jks
9. Session 23（05-09）：启动页白方块彻底修复——经历 9 次错误尝试后找到根因
   - 根因1：Android 12+ 对非 adaptive 图标加白色底板 → 创建 `mipmap-anydpi-v26/ic_launcher.xml` adaptive icon
   - 根因2：Flutter `_SplashImage` 多余 → 删除，原生 `windowBackground` 直接桥接
   - 根因3：`NormalTheme.windowBackground` 为白色 → 改为品牌蓝 `@color/splash_bg`
   - 附加修复：adaptive icon 前景加 18dp inset（108dp画布→72dp安全区）
   - 详见上方"启动页白方块问题——完整排查记录"
