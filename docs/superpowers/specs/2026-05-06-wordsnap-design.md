# WordSnap 1.0 — 技术设计文档

> 2026-05-06 · 见词 WordSnap · Flutter + Riverpod + sqflite

## 一、产品概述

见词 WordSnap 是一款完全免费的 Android 个人词汇银行应用。核心流程：从生活中捕获生词（拍照/剪贴板/手动）→ 存入单词本 → 按基于次数的 SRS 系统复习 → 掌握。

- 无用户注册，纯本地存储（sqflite）
- JSON 导入/导出实现跨设备迁移
- 词典查询依赖 Free Dictionary API（免费）

## 二、技术决策

| 决策项 | 选择 | 说明 |
|--------|------|------|
| 平台 | Android | v1 仅 Android |
| 框架 | Flutter 3.x | 环境已就绪 |
| 状态管理 | Riverpod | 编译安全 |
| 本地数据库 | sqflite | |
| 词典 API | Free Dictionary API | api.dictionaryapi.dev，免费 |
| 路由 | GoRouter | |
| 数据同步 | 纯本地 + JSON 导入/导出 | 无服务端 |
| 付费模式 | 完全免费 | |

## 三、导航结构

NotebookLM 风格：顶部胶囊 Tab + 右上设置齿轮 + 底部双按钮 pill。

```
Scaffold
├── AppBar
│   ├── 产品名 "见词 WordSnap"（左）
│   ├── 设置齿轮图标（右）
│   └── 胶囊 Tabs: 记单词 | 单词本 | 档案卡
├── Body: TabBarView（三页）
│   ├── 记单词 → LearnPage
│   ├── 单词本 → WordbookPage
│   └── 档案卡 → ArchivePage
└── BottomBar: 紧凑胶囊 pill
    ├── 📷 拍照
    └── ✏️ 记录
```

底部 pill: `padding:4px`, 内按钮 `padding:6px 16px; font-size:13px`, 间距 `gap:24px`, 分隔线 `1px #ddd`。

路由：
- `/learn` — 记单词主页（默认）
- `/wordbook` — 单词本页（notebook 列表）
- `/wordbook/:id` — 单词本详情（该本子下的单词）
- `/archive` — 档案卡页（统计/成就）
- `/settings` — 设置页（导入/导出/关于）
- 记单词页底部弹出 BottomSheet — 学习设置（切换本子 + 每日上限）

## 四、数据模型

### Notebook（单词本）
```dart
Notebook {
  id: int (pk, auto)
  name: string
  isDefault: bool              // 拾词集 = true，不可删
  dailyNewWordLimit: int       // 每日新词上限，默认 10
  createdAt: DateTime
}
```

每个单词属于一个 Notebook。

### Word
```dart
Word {
  id: int (pk, auto)
  notebookId: int (fk)
  text: string
  phonetic: string?
  partOfSpeech: string?
  definitions: List<String>
  examples: List<String>
  contexts: List<WordContext>
  tags: List<String>
  imagePath: string?
  sourceUrl: string?
  isPhrase: bool
  // --- 基于次数的 SRS 字段 ---
  isNew: bool                  // 是否为新词（未学过）
  reviewCount: int             // 连续认识次数 (0-10)
  learnedAt: DateTime          // 首次录入/学习时间，用于 FIFO 排序
  isMastered: bool             // reviewCount >= 10 → true
  createdAt: DateTime
  updatedAt: DateTime
}

WordContext {
  type: enum (photo|clipboard|manual|web)
  source: string?
  imagePath: string?
  timestamp: DateTime
}
```

### ReviewSession
```dart
ReviewSession {
  id: int (pk, auto)
  date: DateTime
  wordsReviewed: int            // 当天复习总数（含新词+旧词）
  newWordsLearned: int          // 当天新学词数
  reviewWordsCorrect: int       // 复习答对数
  reviewWordsWrong: int         // 复习答错数
  isCompleted: bool
}
```

## 五、复习系统（基于次数，非基于天数）

### 核心规则

```
每学 10 个新词 → 穿插 1 个旧词复习
复习队列：FIFO，按 learnedAt 排序
掌握 = 连续 10 次答"认识"
失败 = 计数归零，回到队尾
```

### 三种模式自动切换

| 条件 | 模式 | 行为 |
|------|------|------|
| 新词 ≥ 10 | 正常模式 | 10 新 → 1 旧 → 10 新 → 1 旧 ... |
| 0 < 新词 < 10 | 过渡 | 学完剩余新词 → 自动切纯复习 |
| 新词 = 0 | 纯复习模式 | FIFO 循环复习所有词，直至每个词 10/10 |

### 学习计划

用户只需设置一个值：**每日新词上限**（默认 10）。

其余全部推导：
- **预计天数** = 剩余新词 ÷ 每日上限（向上取整）
- **复习触发** = 每学 10 个新词自动触发 1 次旧词复习
- **模式切换** = 新词用光后自动进入纯复习模式

记单词主页展示三列：每日新词 | 预计天数 | 新:复比（固定 10:1）

### 已掌握词汇维护

- 已掌握词不参与日常复习队列
- 系统每周随机抽 5 个已掌握词穿插复习
- 答错 → 退回学习状态（reviewCount = 0，重新排队）

## 六、页面设计

### 记单词页（LearnPage）

```
┌─────────────────────────────┐
│ 见词 WordSnap          ⚙️  │  ← 产品名 + 全局设置齿轮
│ ┌──────┐ ┌──────┐ ┌──────┐ │
│ │记单词│ │单词本│ │档案卡│ │  ← 胶囊 Tab
│ └──────┘ └──────┘ └──────┘ │
├─────────────────────────────┤
│ ┌─────────────────────────┐ │
│ │ 📖 拾词集          [✏️] │ │  ← 当前单词本 + 铅笔编辑图标
│ │ 12 待复习 21 掌握 35 总计│ │    点击 → 底部弹出学习设置
│ └─────────────────────────┘ │
│                             │
│  ┌──────┬──────┬──────┐    │
│  │ 10   │  23   │ 10:1 │    │  ← 每日新词/预计天数/新:复比
│  │每日  │预计   │新:复 │    │
│  └──────┴──────┴──────┘    │
│                             │
│  今日学习计划               │
│  ┌──────┐ ┌──────┐        │
│  │ 8    │ │ 6    │        │  ← 新学词/待复习
│  │新学词│ │待复习│        │
│  └──────┘ └──────┘        │
│                             │
│  ┌──────────────────────┐  │
│  │      开始学习         │  │  ← 蓝色全宽 pill
│  └──────────────────────┘  │
├─────────────────────────────┤
│      [📷 拍照] [✏️ 记录]    │  ← 底部紧凑 pill
└─────────────────────────────┘
```

**底部弹出 — 学习设置（BottomSheet）：**

```
┌─────────────────────────────┐
│        ━━━━ (拖拽手柄)       │
│        学习设置              │
│                             │
│  当前单词本                 │
│  ┌─────────────────────────┐│
│  │ 📖 拾词集          ▾   ││  ← 点击展开下拉搜索
│  └─────────────────────────┘│
│  ┌─────────────────────────┐│
│  │ 🔍 搜索单词本...        ││  ← 搜索框
│  │ ┌───────────────────────┐││
│  │ │ 📖 拾词集       35词 │││  ← 当前选中（蓝色高亮）
│  │ │ 📖 GRE 核心词汇  32词 │││
│  │ │ 📖 工作英语      18词 │││
│  │ └───────────────────────┘││
│  └─────────────────────────┘│
│                             │
│  每日新词上限               │
│  新词用完自动切纯复习   [− 10 +]  │
│                             │
│  ┌─────────────────────────┐│
│  │ 剩余 23 新词 · 预计 3 天││  ← 推导信息
│  └─────────────────────────┘│
│                             │
│  ┌──────────────────────┐  │
│  │        保存           │  │
│  └──────────────────────┘  │
└─────────────────────────────┘
```

### 单词本页（WordbookPage）

- 以 Notebook 卡片列表展示所有单词本
- 每个卡片：书图标 + 本子名称 + 词数统计
- 默认"拾词集"带有特殊标识（不可删除）
- 支持新建单词本、重命名、删除（拾词集除外）
- 点击进入该本子下的单词列表

### 档案卡页（ArchivePage）

- 学习统计：累计学习天数、掌握词汇量、复习总次数
- 学习成就/里程碑
- 复习趋势简图

### 复习页（学习流程中）

- 翻转卡片模式：正面显示单词 → 点击翻转 → 背面显示释义/例句
- 两个按钮："认识 ✓" / "不认识 ✗"
- 新词学习时：正面单词 + 背面释义，认识=加入复习队列，不认识=稍后再学
- 旧词复习时：正面单词，认识=计数+1，不认识=归零回队尾

## 七、项目结构

```
lib/
├── main.dart
├── app.dart
├── core/
│   ├── theme/
│   │   ├── colors.dart            # 墨水黑#0b0b0f 信号蓝#2f5cff 画布白#f9f9fb 琥珀闪#ffa940 薄荷#00c896 等
│   │   ├── typography.dart        # Source Serif 4(单词) Inter(UI) JetBrains Mono(数字)
│   │   ├── spacing.dart           # 4px 基准
│   │   └── radius.dart            # 100px pill / 20px card / 12px input
│   ├── database/
│   │   ├── database.dart
│   │   └── migrations.dart
│   ├── router/
│   │   └── app_router.dart
│   └── constants.dart
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
│       ├── dictionary_service.dart     # Free Dictionary API
│       ├── clipboard_service.dart      # 剪贴板监听
│       ├── review_service.dart         # 基于次数的复习逻辑
│       └── export_import_service.dart  # JSON 导入导出
├── features/
│   ├── learn/                         # 记单词 Tab
│   │   ├── learn_page.dart
│   │   ├── learn_settings_sheet.dart   # 底部弹出设置
│   │   ├── review_card.dart            # 翻转卡片
│   │   └── learn_provider.dart
│   ├── wordbook/                       # 单词本 Tab
│   │   ├── wordbook_page.dart          # Notebook 列表
│   │   ├── notebook_detail_page.dart   # 本子内单词
│   │   ├── create_notebook_page.dart
│   │   └── wordbook_provider.dart
│   ├── archive/                        # 档案卡 Tab
│   │   ├── archive_page.dart
│   │   └── archive_provider.dart
│   ├── capture/                        # 录入
│   │   ├── capture_sheet.dart          # 底部面板
│   │   ├── manual_input.dart
│   │   └── capture_provider.dart
│   └── settings/                       # 设置页
│       ├── settings_page.dart
│       ├── export_page.dart
│       └── import_page.dart
└── widgets/                            # 共享组件
    ├── book_icon.dart                  # 书本 SVG 图标
    ├── capsule_tab_bar.dart            # 胶囊 Tab
    ├── bottom_pill.dart                # 底部双按钮 pill
    └── empty_state.dart
```

## 八、复习服务核心逻辑（review_service.dart）

```dart
class ReviewService {
  // 每日新词上限（默认 10）
  int dailyNewWordLimit = 10;

  // 复习穿插比
  static const int newPerReview = 10;

  // 掌握阈值
  static const int masterThreshold = 10;

  // 获取今日学习队列
  List<Word> getTodayQueue(int notebookId) {
    final newWords = getNewWords(notebookId).take(dailyNewWordLimit);
    final reviewWords = getReviewFIFO(notebookId);
    // 穿插：每 newPerReview 个新词插入 1 个旧词
    return interleave(newWords, reviewWords, newPerReview);
  }

  // 纯复习模式队列
  List<Word> getPureReviewQueue(int notebookId) {
    return getReviewFIFO(notebookId); // 按 FIFO 循环
  }

  // 判定模式
  StudyMode getMode(int notebookId) {
    final newCount = getNewWordCount(notebookId);
    if (newCount >= 10) return StudyMode.normal;
    if (newCount > 0) return StudyMode.transition;
    return StudyMode.pureReview;
  }
}
```

## 九、设计系统

通过 Flutter `ThemeData` 落地 Signal Tech Design Tokens：

| Token | 值 | 用途 |
|-------|-----|------|
| 墨水黑 | #0b0b0f | 主文字 |
| 画布白 | #f9f9fb | 页面背景 |
| 信号蓝 | #2f5cff | 主按钮、选中态 |
| 琥珀闪 | #ffa940 | 待复习、提醒 |
| 薄荷 | #00c896 | 掌握、成功 |
| 薰衣草 | #7068f0 | 推导信息、二级强调 |
| 字体 | Source Serif 4 / Inter / JetBrains Mono | 单词 / UI / 数字 |
| 圆角 | 100px pill / 20px card / 12px input | |
| 边框 | 1px + #e2e2ea | 卡片层次（不用阴影） |

## 十、JSON 导入/导出格式

```json
{
  "version": "1.0",
  "exportedAt": "2026-05-06T...",
  "notebooks": [
    {
      "name": "拾词集",
      "isDefault": true,
      "dailyNewWordLimit": 10,
      "words": [
        {
          "text": "ephemeral",
          "phonetic": "/ɪˈfemərəl/",
          "definitions": ["lasting for a very short time"],
          "contexts": [{ "type": "clipboard", "source": "Browser", "timestamp": "..." }],
          "isNew": false,
          "reviewCount": 3,
          "learnedAt": "2026-05-01T...",
          "isMastered": false
        }
      ]
    }
  ]
}
```

导入时按 `notebook.name` + `word.text` 去重：已存在的词合并 contexts，新词直接插入。

## 十一、开发阶段

### P0 · MVP
- [ ] Flutter 项目初始化 + 主题系统
- [ ] sqflite 建表 + migration（Notebook, Word, ReviewSession）
- [ ] 单词模型 + CRUD
- [ ] Free Dictionary API 集成
- [ ] 手动输入录入流程
- [ ] 剪贴板监听录入流程
- [ ] 记单词页（含底部弹出学习设置）
- [ ] 单词本页（Notebook 列表 + 详情）
- [ ] 基于次数的复习系统（翻转卡片 + 三种模式切换）
- [ ] 顶部胶囊 Tab + 底部 pill + GoRouter
- [ ] 档案卡页（基础统计）
- [ ] JSON 导出功能

### P1 · 核心体验升级
- [ ] 拍照 OCR（ML Kit）
- [ ] 复习多样化（语境回想 / 辨音拼写 / 选择题）
- [ ] 冷启动互动引导
- [ ] 标签分类与筛选
- [ ] JSON 导入功能

### P2 · 生态扩展
- [ ] 浏览器插件（Chrome Extension）
- [ ] 数据统计面板（词汇量、复习趋势）
- [ ] 单词卡分享（图片生成）
- [ ] 主题皮肤（明/暗）

## 十二、测试策略

- **单元测试**：review_service 模式切换逻辑、FIFO 队列、掌握判定、导入导出
- **Widget 测试**：FlipCard、BottomPill、CapsuleTabBar
- **集成测试**：录入 → 存储 → 复习完整流程
