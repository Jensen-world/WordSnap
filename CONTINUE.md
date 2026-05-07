# 见词 WordSnap — 断点续接指南

> 最后更新：2026-05-06

## 一、现在到哪了

**阶段：设计收尾。** 经过完整的产品设计+UI设计+技术设计，所有页面布局已确定，即将进入实现阶段。

已完成：
- 产品定位：Android 本地词汇银行，完全免费，无注册
- 技术选型：Flutter + Riverpod + sqflite + GoRouter
- 复习系统：基于次数（非天数），10新→1旧穿插，FIFO 队列，连续10次=掌握
- UI 设计：8 个页面的完整布局（NotebookLM 风格，Signal Tech 设计系统）
- 视觉辅助：浏览器 mockup 展示全部页面

当前待办：
- **审阅设计文档** → 确认后进入实现规划

## 二、关键文件

| 文件 | 说明 |
|------|------|
| `docs/superpowers/specs/2026-05-06-wordsnap-design.md` | **技术设计文档**（先看这个，确认无异议） |
| `WordSnap 1.0/Document/见词_产品设计文档_v1.md` | 原始产品文档 |
| `WordSnap 1.0/Document/见词_pencil_reference.md` | 设计系统参考（颜色/字体/间距） |
| `.superpowers/brainstorm/970-1778067419/content/all-pages.html` | **全部页面 mockup**（浏览器看） |
| `.superpowers/brainstorm/970-1778067419/content/review-final.html` | 记单词页+学习设置详细版 |

## 三、如何启动视觉辅助

```bash
# 视觉辅助服务器已配置在 .superpowers/brainstorm/970-1778067419/
# 打开浏览器访问: http://localhost:57519
# 如果服务器没启动，告诉 Claude: "启动视觉辅助"
```

## 四、下一步做什么

**第 1 步：审阅设计文档**（5分钟）
打开 `docs/superpowers/specs/2026-05-06-wordsnap-design.md`，确认：
- 导航结构对不对
- 数据模型合理吗
- 复习规则有没有遗漏

**第 2 步：跟 Claude 说"可以开始实现了"**
Claude 会自动进入实现规划（writing-plans），拆分开发任务。

**第 3 步：开始写代码**
按 P0 → P1 → P2 顺序，约 2 周完成 MVP。

## 五、核心设计速览

### 页面清单（8 个）

```
1. 记单词主页       /learn          Tab 页，当前本子+今日计划+开始学习
2. 学习设置        BottomSheet     铅笔图标触发，切换本子+每日上限
3. 学习/复习中     /learn/study    翻转卡片+认识/不认识
4. 单词本列表       /wordbook       Tab 页，Notebook 卡片+新建
5. 单词本详情       /wordbook/:id   本子内单词列表+SRS 状态
6. 档案卡           /archive        Tab 页，统计+成就
7. 设置             /settings       导入导出+剪贴板开关
8. 录入弹出        BottomSheet     拍照/手动输入
```

### 复习规则（一句话）

> 每学 10 个新词穿插 1 个旧词复习，按学习先后 FIFO 排队，连续 10 次认识=掌握，1 次失败=归零回队尾。新词不够 10 个时自动切纯复习模式。

### 关键数据模型

```
Notebook（单词本） → Word（单词） → WordContext（遇词场景）
                         ↓
                   ReviewSession（学习记录）
```

### 用户只需设一个值

**每日新词上限**（默认 10）。预计天数 = 剩余新词 ÷ 上限，自动算。

## 六、快速对话模板

明天打开 Claude Code，在项目目录下说：

> "打开了，看 CONTINUE.md 和设计文档，继续推进。"

或者更具体：

> "审阅了设计文档，没问题，开始实现规划。"
