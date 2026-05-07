# 见词 WordSnap — 断点续接指南

> 最后更新：2026-05-07

## 一、现在到哪了

**阶段：设计审阅中。** 9 个页面 mockup 已全部在浏览器中展示，正在逐页审阅调整。

已完成：
- 产品定位：Android 本地词汇银行，完全免费，无注册
- 技术选型：Flutter + Riverpod + sqflite + GoRouter
- 复习系统：基于次数（非天数），10新→1旧穿插，FIFO 队列，连续10次=掌握
- UI 设计：9 个页面的完整布局（NotebookLM 风格，Signal Tech 设计系统）
- 视觉辅助：浏览器 mockup 展示全部页面（6.7 英寸手机框）
- **页面 1（记单词主页）已审阅完成**
- Git 仓库已初始化，首次提交已存档

当前待办：
- **逐页审阅页面 2-8** → 确认后进入实现规划

## 二、关键文件

| 文件 | 说明 |
|------|------|
| `docs/superpowers/specs/2026-05-06-wordsnap-design.md` | **技术设计文档** |
| `WordSnap 1.0/Document/见词_产品设计文档_v1.md` | 原始产品文档 |
| `WordSnap 1.0/Document/见词_pencil_reference.md` | 设计系统参考（颜色/字体/间距） |
| `.superpowers/brainstorm/970-1778067419/content/all-pages.html` | **全部页面 mockup**（浏览器看） |
| `.superpowers/brainstorm/970-1778067419/rebuild.js` | **重建脚本**（`node rebuild.js` 即可重新生成） |
| `.superpowers/brainstorm/970-1778067419/content/review-final.html` | 记单词页+学习设置详细版 |

## 三、如何启动视觉辅助

```bash
# 视觉辅助服务器已配置在 .superpowers/brainstorm/970-1778067419/
# 打开浏览器访问: http://localhost:57519/all-pages.html
# 如果服务器没启动，告诉 Claude: "启动视觉辅助"
```

## 四、Mockup 重建

```bash
cd .superpowers/brainstorm/970-1778067419
node rebuild.js
# 刷新浏览器即可看到最新效果
```

## 五、页面清单（9 个）

```
1. 记单词主页       /learn          Tab 页，当前本子+每日一词+今日计划+开始学习
2. 学习设置        BottomSheet     铅笔图标触发，切换本子+每日上限
3a. 学习卡片       /learn/study    单词卡片 + 认识/不认识
3b. 学习释义       /learn/study    释义+例句 + 下一词
4. 单词本列表       /wordbook       Tab 页，Notebook 卡片+新建
5. 单词本详情       /wordbook/:id   本子内单词列表+SRS 状态
6. 档案卡           /archive        Tab 页，统计+成就
7. 设置             /settings       导入导出+剪贴板开关
8. 录入弹出        BottomSheet     拍照/手动输入
```

## 六、页面 1（记单词主页）设计要点

- **正在学习的单词本**：书名+待复习/掌握/总计 + 铅笔编辑按钮
- **今日学习计划**：新学词/待复习大数字 + 每日新词/预计天数/新复比统计 + 开始学习按钮
- **每日一词**：随机从所有单词本抽取，包含：
  - 单词（Source Serif 4，居中）
  - 美式/英式切换按钮 + 音标 + 发音按钮
  - 词性（adj./v./n.）+ 中文释义
  - 例句 + 中文翻译
- 手机框：6.7 英寸（屏幕 400×860px），深色边框 + 状态栏 + 底部横条

## 七、下一步做什么

**第 1 步：继续逐页审阅**（页面 2 → 8）
打开 `http://localhost:57519/all-pages.html`，一页一页调整。

**第 2 步：审阅设计文档**
确认导航结构、数据模型、复习规则无异议。

**第 3 步：开始实现**
跟 Claude 说"可以开始实现了"，进入实现规划。

## 八、快速对话模板

下次打开 Claude Code，在项目目录下说：

> "打开了，看 CONTINUE.md，继续逐页审阅。"
