const fs = require('fs');

const head = `<!DOCTYPE html>
<html lang="zh-CN">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>见词 WordSnap · 全部页面</title>
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&family=JetBrains+Mono:wght@400;500;600&family=Source+Serif+4:wght@600;700&display=swap" rel="stylesheet">
<style>
  *, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }
  body {
    font-family: Inter, -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
    background: #f9f9fb;
    color: #0b0b0f;
    padding: 24px;
    -webkit-font-smoothing: antialiased;
  }
  h2 {
    font-family: Inter, sans-serif;
    font-size: 24px;
    font-weight: 600;
    color: #0b0b0f;
    margin-bottom: 4px;
  }
  h3 {
    font-family: Inter, sans-serif;
    font-size: 16px;
    font-weight: 600;
    color: #0b0b0f;
    margin-bottom: 12px;
  }
  .subtitle {
    font-family: Inter, sans-serif;
    font-size: 13px;
    color: #999;
    margin-bottom: 20px;
  }
  .section {
    margin-bottom: 8px;
  }
  .mockup-header {
    font-family: Inter, sans-serif;
    font-size: 12px;
    font-weight: 600;
    color: #666;
    padding: 8px 12px;
    background: #f0f0f5;
    border-radius: 10px 10px 0 0;
    border: 1px solid #e2e2ea;
    border-bottom: none;
  }
  .mockup-body {
    border: 1px solid #e2e2ea;
    border-top: none;
    border-radius: 0 0 10px 10px;
    overflow: hidden;
  }
  table { border-collapse: collapse; }
  th { font-family: Inter, sans-serif; font-size: 11px; font-weight: 600; }
  td { font-family: Inter, sans-serif; font-size: 12px; }
  button { cursor: pointer; }
</style>
</head>
<body>

<h2>见词 WordSnap · 全部页面</h2>
<p class="subtitle">从左到右：记单词 → 学习设置 → 学习卡片 → 学习释义 → 单词本 → 单词本详情 → 档案卡 → 设置 → 录入弹出</p>
`;

const tail = `
<div class="section" style="margin-top:20px">
  <h3>页面清单</h3>
  <table style="width:100%">
    <tr style="border-bottom:1px solid #e2e2ea">
      <th style="text-align:left;padding:8px;color:#999">#</th>
      <th style="text-align:left;padding:8px;color:#999">页面</th>
      <th style="text-align:left;padding:8px;color:#999">路由</th>
      <th style="text-align:left;padding:8px;color:#999">说明</th>
    </tr>
    <tr style="border-bottom:1px solid #e2e2ea"><td style="padding:8px">1</td><td style="padding:8px">记单词</td><td style="padding:8px;font-family:JetBrains Mono,monospace;font-size:11px">/learn</td><td style="padding:8px">默认 Tab，含当前本子卡片、计划摘要、今日学习</td></tr>
    <tr style="border-bottom:1px solid #e2e2ea"><td style="padding:8px">2</td><td style="padding:8px">学习设置</td><td style="padding:8px;font-family:JetBrains Mono,monospace;font-size:11px">BottomSheet</td><td style="padding:8px">从铅笔图标弹出，切换本子 + 每日上限</td></tr>
    <tr style="border-bottom:1px solid #e2e2ea"><td style="padding:8px">3</td><td style="padding:8px">学习/复习中</td><td style="padding:8px;font-family:JetBrains Mono,monospace;font-size:11px">/learn/study</td><td style="padding:8px">翻转卡片 + 认识/不认识 + 进度条</td></tr>
    <tr style="border-bottom:1px solid #e2e2ea"><td style="padding:8px">4</td><td style="padding:8px">单词本列表</td><td style="padding:8px;font-family:JetBrains Mono,monospace;font-size:11px">/wordbook</td><td style="padding:8px">Notebook 卡片列表 + 新建入口</td></tr>
    <tr style="border-bottom:1px solid #e2e2ea"><td style="padding:8px">新建</td><td style="padding:8px">新建单词本</td><td style="padding:8px;font-family:JetBrains Mono,monospace;font-size:11px">BottomSheet</td><td style="padding:8px">输入名称即创建，上限默认10</td></tr>
    <tr style="border-bottom:1px solid #e2e2ea"><td style="padding:8px">5</td><td style="padding:8px">单词本详情</td><td style="padding:8px;font-family:JetBrains Mono,monospace;font-size:11px">/wordbook/:id</td><td style="padding:8px">本子内单词列表（含 SRS 状态）</td></tr>
    <tr style="border-bottom:1px solid #e2e2ea"><td style="padding:8px">单词</td><td style="padding:8px">单词详情</td><td style="padding:8px;font-family:JetBrains Mono,monospace;font-size:11px">/word/:id</td><td style="padding:8px">释义+例句+SRS状态+标签+来源</td></tr>
    <tr style="border-bottom:1px solid #e2e2ea"><td style="padding:8px">6</td><td style="padding:8px">档案卡</td><td style="padding:8px;font-family:JetBrains Mono,monospace;font-size:11px">/archive</td><td style="padding:8px">学习统计 + 成就里程碑</td></tr>
    <tr style="border-bottom:1px solid #e2e2ea"><td style="padding:8px">7</td><td style="padding:8px">设置</td><td style="padding:8px;font-family:JetBrains Mono,monospace;font-size:11px">/settings</td><td style="padding:8px">导入/导出 + 剪贴板开关 + 关于</td></tr>
    <tr><td style="padding:8px">8</td><td style="padding:8px">录入弹出</td><td style="padding:8px;font-family:JetBrains Mono,monospace;font-size:11px">BottomSheet</td><td style="padding:8px">底部拍照/手动输入选择，含存入本子提示</td></tr>
  </table>
</div>

</body>
</html>
`;

// Shared styles — fixed phone width
// 6.7-inch phone dimensions (412×915dp ≈ 400×860 CSS)
const PW = 416;  // outer frame width
const SW = 400;  // screen width
const PH = 860;  // screen height
const SCREEN = `background:#f9f9fb;min-height:${PH}px;padding:0;display:flex;flex-direction:column`;

// Phone frame: dark bezel + status bar + home indicator
function phoneFrame(screenStyle, content) {
  return `
    <div style="background:#1a1a2e;border-radius:28px;padding:10px 8px 8px;box-shadow:0 4px 24px rgba(0,0,0,0.18);width:${PW}px;flex-shrink:0">
      <div style="display:flex;justify-content:space-between;align-items:center;padding:2px 12px 4px;font-family:Inter,系统默认,-apple-system,sans-serif;font-size:10px;color:rgba(255,255,255,0.65)">
        <span>9:41</span>
        <span style="font-size:9px">Wi-Fi &nbsp;▮▮▮▮</span>
      </div>
      <div style="border-radius:18px;overflow:hidden;width:${SW}px;${screenStyle}">
${content}
      </div>
      <div style="display:flex;justify-content:center;padding:6px 0 2px">
        <div style="width:80px;height:4px;border-radius:2px;background:rgba(255,255,255,0.15)"></div>
      </div>
    </div>`;
}

// Icons
const menuI = (c) => `<svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="${c||'#999'}" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"><line x1="3" y1="6" x2="21" y2="6"/><line x1="3" y1="12" x2="21" y2="12"/><line x1="3" y1="18" x2="21" y2="18"/></svg>`;
const bookI = (c) => `<svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="${c||'#2f5cff'}" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round"><path d="M2 3h7a2 2 0 0 1 2 2v14a2 2 0 0 0-2-2H2z"/><path d="M22 3h-7a2 2 0 0 0-2 2v14a2 2 0 0 1 2-2h7z"/></svg>`;
const smallBookI = (c) => `<svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="${c||'#2f5cff'}" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round"><path d="M2 3h7a2 2 0 0 1 2 2v14a2 2 0 0 0-2-2H2z"/><path d="M22 3h-7a2 2 0 0 0-2 2v14a2 2 0 0 1 2-2h7z"/></svg>`;
const smallBookI2 = (c) => `<svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="${c||'#999'}" stroke-width="1.5" stroke-linecap="round"><path d="M2 3h7a2 2 0 0 1 2 2v14a2 2 0 0 0-2-2H2z"/><path d="M22 3h-7a2 2 0 0 0-2 2v14a2 2 0 0 1 2-2h7z"/></svg>`;
const pencilI = `<svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="#999" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round"><path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"/><path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z"/></svg>`;
const chevronD = `<svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="#999" stroke-width="2"><polyline points="6 9 12 15 18 9"/></svg>`;
const searchI = `<svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="#999" stroke-width="1.5"><circle cx="11" cy="11" r="8"/><path d="M21 21l-4.35-4.35"/></svg>`;
const cameraI = `<svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="#0b0b0f" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round"><rect x="2" y="5" width="20" height="15" rx="3"/><circle cx="12" cy="13" r="4"/><path d="M12 2v4"/></svg>`;
const recordI = `<svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="#0b0b0f" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round"><path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"/><polyline points="14 2 14 8 20 8"/><line x1="12" y1="18" x2="12" y2="12"/><line x1="9" y1="15" x2="15" y2="15"/></svg>`;
const cameraBigI = `<svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="#0b0b0f" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round"><rect x="2" y="5" width="20" height="15" rx="3"/><circle cx="12" cy="13" r="4"/><polyline points="8 2 16 2"/></svg>`;

function headerBar(active) {
  return `
    <div style="background:#fff;border-bottom:1px solid #e2e2ea;padding:14px 16px 12px">
      <div style="display:flex;align-items:center;justify-content:space-between;padding:0 0 14px 4px">
        <div style="display:flex;align-items:center;gap:6px">
          <span style="font-family:Inter,sans-serif;font-size:18px;font-weight:600;color:#0b0b0f">见词</span>
          <span style="font-family:Inter,sans-serif;font-size:13px;color:#bbb">WordSnap</span>
        </div>
        ${menuI(active === 'settings' ? '#999' : '#bbb')}
      </div>
      <div style="display:flex;gap:6px;padding:0 0 0 4px">${['learn','wordbook','archive'].map(t => `
        <div style="padding:7px 15px;border-radius:100px;background:${active===t?'#2f5cff':'#f0f0f5'};font-family:Inter,sans-serif;font-size:13px;${active===t?'font-weight:500;color:#fff':'color:#999'}">${t==='learn'?'记单词':t==='wordbook'?'单词本':'档案卡'}</div>`).join('')}
      </div>
    </div>`;
}

function bottomPill() {
  return `
    <div style="padding:0 14px 12px">
      <div style="display:flex;align-items:center;justify-content:center;background:#f0f0f5;border-radius:100px;padding:4px;gap:20px">
        <button style="padding:5px 12px;border-radius:100px;border:none;background:#fff;font-family:Inter,sans-serif;font-size:12px;color:#0b0b0f;display:flex;align-items:center;gap:4px">${cameraI} 拍照</button>
        <div style="width:1px;height:10px;background:#ddd"></div>
        <button style="padding:5px 12px;border-radius:100px;border:none;background:#fff;font-family:Inter,sans-serif;font-size:12px;color:#0b0b0f;display:flex;align-items:center;gap:4px">${recordI} 记录</button>
      </div>
    </div>`;
}

function mockup(num, title, screenStyle, content) {
  return `
<!-- ${num}. ${title} -->
<div class="mockup" style="width:${PW}px;flex-shrink:0">
  <div class="mockup-header">${num}. ${title}</div>
  ${phoneFrame(screenStyle, content)}
</div>`;
}

// ===== PAGE 1 =====
const speakerI = `<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="#2f5cff" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round"><polygon points="11 5 6 9 2 9 2 15 6 15 11 19 11 5"/><path d="M19.07 4.93a10 10 0 0 1 0 14.14"/><path d="M15.54 8.46a5 5 0 0 1 0 7.07"/></svg>`;

const p1 = mockup('1', '记单词 · 主页', SCREEN, `
${headerBar('learn')}
    <div style="flex:1;padding:16px;display:flex;flex-direction:column;gap:10px">
      <div style="background:#fff;border:1px solid #e2e2ea;border-radius:16px;padding:18px 18px 14px;display:flex;flex-direction:column;gap:14px">
        <div style="font-family:Inter,sans-serif;font-size:10px;font-weight:600;color:#999;text-transform:uppercase;letter-spacing:0.06em">正在学习的单词本</div>
        <div style="display:flex;align-items:center;gap:16px">
          <div style="width:64px;height:84px;border-radius:5px;background:linear-gradient(135deg,#f0f0f5,#e8e8f0);display:flex;align-items:center;justify-content:center;flex-shrink:0;border:1px solid #e2e2ea">
            <svg width="32" height="32" viewBox="0 0 24 24" fill="none" stroke="#2f5cff" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"><path d="M2 3h7a2 2 0 0 1 2 2v14a2 2 0 0 0-2-2H2z"/><path d="M22 3h-7a2 2 0 0 0-2 2v14a2 2 0 0 1 2-2h7z"/></svg>
          </div>
          <div style="flex:1;min-width:0">
            <div style="font-family:Inter,sans-serif;font-size:16px;font-weight:600;color:#0b0b0f">拾词集</div>
            <div style="display:flex;gap:12px;margin-top:4px">
              <span style="font-family:JetBrains Mono,monospace;font-size:11px;color:#2f5cff">12 待复习</span>
              <span style="font-family:JetBrains Mono,monospace;font-size:11px;color:#00c896">21 掌握</span>
              <span style="font-family:JetBrains Mono,monospace;font-size:11px;color:#999">35 总计</span>
            </div>
          </div>
          <button style="width:34px;height:34px;border:1px solid #e2e2ea;border-radius:50%;background:#fff;display:flex;align-items:center;justify-content:center;flex-shrink:0">
            <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="#999" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round"><path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"/><path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z"/></svg>
          </button>
        </div>
        <div style="height:4px;background:#f0f0f5;border-radius:2px;overflow:hidden">
          <div style="width:60%;height:100%;background:#00c896;border-radius:2px"></div>
        </div>
        <div style="display:flex;justify-content:space-between">
          <span style="font-family:Inter,sans-serif;font-size:9px;color:#00c896;font-weight:500">已掌握 60%</span>
          <span style="font-family:Inter,sans-serif;font-size:9px;color:#bbb">21 / 35</span>
        </div>
      </div>
      <div style="background:#fff;border:1px solid #e2e2ea;border-radius:16px;padding:16px;display:flex;flex-direction:column;gap:14px">
        <div style="font-family:Inter,sans-serif;font-size:10px;font-weight:600;color:#999;text-transform:uppercase;letter-spacing:0.06em">今日学习计划</div>
        <div style="display:flex;gap:12px">
          <div style="flex:1;background:#f9f9fb;border:1px solid #e2e2ea;border-radius:14px;padding:18px 14px;text-align:center">
            <div style="font-family:JetBrains Mono,monospace;font-size:32px;font-weight:500;color:#2f5cff;line-height:1">8</div>
            <div style="font-family:Inter,sans-serif;font-size:11px;color:#999;margin-top:4px">新学词</div>
          </div>
          <div style="flex:1;background:#f9f9fb;border:1px solid #e2e2ea;border-radius:14px;padding:18px 14px;text-align:center">
            <div style="font-family:JetBrains Mono,monospace;font-size:32px;font-weight:500;color:#ffa940;line-height:1">6</div>
            <div style="font-family:Inter,sans-serif;font-size:11px;color:#999;margin-top:4px">待复习</div>
          </div>
        </div>
        <div style="display:flex;justify-content:space-around;text-align:center;padding:4px 0">
          <div><div style="font-family:JetBrains Mono,monospace;font-size:18px;font-weight:500;color:#0b0b0f">10</div><div style="font-family:Inter,sans-serif;font-size:10px;color:#999;margin-top:2px">每日新词</div></div>
          <div style="width:1px;background:#e2e2ea"></div>
          <div><div style="font-family:JetBrains Mono,monospace;font-size:18px;font-weight:500;color:#7068f0">23</div><div style="font-family:Inter,sans-serif;font-size:10px;color:#999;margin-top:2px">预计天数</div></div>
          <div style="width:1px;background:#e2e2ea"></div>
          <div><div style="font-family:JetBrains Mono,monospace;font-size:18px;font-weight:500;color:#0b0b0f">10:1</div><div style="font-family:Inter,sans-serif;font-size:10px;color:#999;margin-top:2px">新复比</div></div>
        </div>
        <button style="padding:14px;border:none;border-radius:100px;background:#2f5cff;font-family:Inter,sans-serif;font-size:15px;color:#fff;font-weight:600;letter-spacing:0.03em">开始学习</button>
      </div>
      <div style="background:#fff;border:1px solid #e2e2ea;border-radius:16px;padding:16px;display:flex;flex-direction:column;align-items:center;gap:8px;text-align:center">
        <div style="display:flex;align-items:center;justify-content:space-between;width:100%">
          <span style="font-family:Inter,sans-serif;font-size:10px;font-weight:600;color:#999;text-transform:uppercase;letter-spacing:0.06em">每日一词</span>
          <span style="font-family:Inter,sans-serif;font-size:10px;color:#bbb">来自 GRE 核心词汇</span>
        </div>
        <span style="font-family:Source Serif 4,serif;font-size:22px;font-weight:600;color:#0b0b0f">ephemeral</span>
	        <div style="display:flex;align-items:center;justify-content:center">
	          <div style="display:flex;align-items:center;gap:0;background:#f0f0f5;border-radius:100px;padding:3px">
	            <button style="padding:5px 10px;border:none;border-radius:100px;background:#fff;font-family:Inter,sans-serif;font-size:11px;color:#0b0b0f;font-weight:600;display:flex;align-items:center;gap:5px">
	              美
	              <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="#999" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polyline points="1 4 1 10 7 10"/><polyline points="23 20 23 14 17 14"/><path d="M20.49 9A9 9 0 0 0 5.64 5.64L1 10m22 4l-4.64 4.36A9 9 0 0 1 3.51 15"/></svg>
	            </button>
	            <span style="font-family:Inter,sans-serif;font-size:12px;color:#999;padding:0 8px">/ɪˈfemərəl/</span>
	            <button style="width:28px;height:28px;border:none;border-radius:50%;background:#eef0ff;display:flex;align-items:center;justify-content:center">${speakerI}</button>
	          </div>
	        </div>
        <div style="font-family:Inter,sans-serif;font-size:13px;color:#0b0b0f;line-height:1.5">
          <span style="font-weight:600;color:#2f5cff">adj.</span> 短暂的，转瞬即逝的
        </div>
        <div style="font-family:Inter,sans-serif;font-size:11px;color:#666;font-style:italic;line-height:1.6;padding:8px 0;border-top:1px solid #f0f0f5;border-bottom:1px solid #f0f0f5;width:100%">
          "Fame is ephemeral — don't chase it." <button style="width:22px;height:22px;border:none;border-radius:50%;background:#eef0ff;display:inline-flex;align-items:center;justify-content:center;vertical-align:middle;margin-left:4px"><svg width="11" height="11" viewBox="0 0 24 24" fill="none" stroke="#2f5cff" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round"><polygon points="11 5 6 9 2 9 2 15 6 15 11 19 11 5"/><path d="M19.07 4.93a10 10 0 0 1 0 14.14"/><path d="M15.54 8.46a5 5 0 0 1 0 7.07"/></svg></button>
        </div>
        <div style="font-family:Inter,sans-serif;font-size:11px;color:#999">名声是短暂的，不要追逐它。</div>
      </div>
    </div>
${bottomPill()}`);

// ===== PAGE 2 =====
const p2 = mockup('2', '学习设置（弹出）', SCREEN+';position:relative', `
    <div style="flex:1;background:rgba(0,0,0,0.15);display:flex;align-items:flex-end">
      <div style="background:#fff;border-radius:18px 18px 0 0;width:100%;padding:18px 18px 22px;display:flex;flex-direction:column;gap:14px">
        <div style="width:30px;height:4px;border-radius:2px;background:#ddd;margin:0 auto -4px"></div>
        <div style="font-family:Inter,sans-serif;font-size:16px;font-weight:600;color:#0b0b0f;text-align:center">学习设置</div>
        <div>
          <div style="font-family:Inter,sans-serif;font-size:10px;font-weight:600;color:#999;text-transform:uppercase;margin-bottom:6px">切换单词本</div>
          <div style="background:#fff;border:1px solid #e2e2ea;border-radius:10px;padding:10px 12px;display:flex;align-items:center;justify-content:space-between">
            <div style="display:flex;align-items:center;gap:8px">
              <div style="width:24px;height:32px;border-radius:3px;background:linear-gradient(135deg,#f0f0f5,#e8e8f0);display:flex;align-items:center;justify-content:center;border:1px solid #e2e2ea">${smallBookI()}</div>
              <span style="font-family:Inter,sans-serif;font-size:13px;font-weight:600;color:#0b0b0f">拾词集</span>
            </div>
            ${chevronD}
          </div>
          <div style="margin-top:5px;background:#f9f9fb;border:1px solid #e2e2ea;border-radius:10px;overflow:hidden">
            <div style="padding:8px 10px;border-bottom:1px solid #e2e2ea;display:flex;align-items:center;gap:6px">${searchI}<span style="font-family:Inter,sans-serif;font-size:11px;color:#ccc">搜索单词本...</span></div>
            <div style="padding:4px">
              <div style="padding:8px;border-radius:6px;background:#2f5cff;display:flex;align-items:center;gap:6px">${smallBookI2('rgba(255,255,255,0.8)')}<span style="font-family:Inter,sans-serif;font-size:12px;font-weight:500;color:#fff">拾词集</span><span style="font-family:JetBrains Mono,monospace;font-size:9px;color:rgba(255,255,255,0.6);margin-left:auto">35词</span></div>
              <div style="padding:8px;border-radius:6px;display:flex;align-items:center;gap:6px">${smallBookI2()}<span style="font-family:Inter,sans-serif;font-size:12px;color:#0b0b0f">GRE 核心词汇</span><span style="font-family:JetBrains Mono,monospace;font-size:9px;color:#999;margin-left:auto">32词</span></div>
              <div style="padding:8px;border-radius:6px;display:flex;align-items:center;gap:6px">${smallBookI2()}<span style="font-family:Inter,sans-serif;font-size:12px;color:#0b0b0f">工作英语</span><span style="font-family:JetBrains Mono,monospace;font-size:9px;color:#999;margin-left:auto">18词</span></div>
            </div>
          </div>
        </div>
        <div>
          <div style="font-family:Inter,sans-serif;font-size:10px;font-weight:600;color:#999;text-transform:uppercase;margin-bottom:6px">每日新词上限</div>
          <div style="display:flex;align-items:center;justify-content:space-between;background:#f9f9fb;border-radius:10px;padding:10px 14px">
            <span style="font-family:Inter,sans-serif;font-size:12px;color:#999">新词用完自动切纯复习</span>
            <div style="display:flex;align-items:center;gap:10px">
              <button style="width:30px;height:30px;border-radius:50%;border:1px solid #e2e2ea;background:#fff;font-size:16px;color:#0b0b0f;line-height:1">−</button>
              <span style="font-family:JetBrains Mono,monospace;font-size:16px;font-weight:600">10</span>
              <button style="width:30px;height:30px;border-radius:50%;border:1px solid #e2e2ea;background:#fff;font-size:16px;color:#0b0b0f;line-height:1">+</button>
            </div>
          </div>
        </div>
        <div style="background:#f0f0f5;border-radius:8px;padding:10px 12px;display:flex;justify-content:space-between">
          <span style="font-family:Inter,sans-serif;font-size:11px;color:#999">剩余 23 个新词</span>
          <span style="font-family:Inter,sans-serif;font-size:11px;color:#7068f0">预计 <strong>3 天</strong> 学完</span>
        </div>
        <button style="padding:13px;border:none;border-radius:100px;background:#2f5cff;font-family:Inter,sans-serif;font-size:14px;color:#fff;font-weight:600">保存</button>
      </div>
    </div>`);

// ===== PAGE 3a =====
const p3a = mockup('3a', '学习 · 卡片', SCREEN, `
    <div style="background:#fff;border-bottom:1px solid #e2e2ea;padding:12px 14px;display:flex;align-items:center;gap:12px">
      <span style="font-size:16px;color:#0b0b0f;cursor:pointer">&larr;</span>
      <div style="flex:1;font-family:Inter,sans-serif;font-size:14px;font-weight:600;color:#0b0b0f">拾词集 · 学习中</div>
      <div style="font-family:JetBrains Mono,monospace;font-size:12px;color:#999">3/8</div>
    </div>
    <div style="flex:1;padding:20px;display:flex;flex-direction:column;align-items:center;justify-content:center;gap:24px">
      <div style="font-family:Inter,sans-serif;font-size:11px;color:#999">新词</div>
	      <div style="width:100%;max-width:280px;aspect-ratio:1.5;background:#fff;border:1px solid #e2e2ea;border-radius:20px;display:flex;align-items:center;justify-content:center;flex-direction:column;gap:14px">
	        <span style="font-family:Source Serif 4,serif;font-size:32px;color:#0b0b0f">ephemeral</span>
	        <div style="display:flex;align-items:center;background:#f0f0f5;border-radius:100px;padding:3px">
	          <button style="padding:5px 10px;border:none;border-radius:100px;background:#fff;font-family:Inter,sans-serif;font-size:11px;color:#0b0b0f;font-weight:600;display:flex;align-items:center;gap:5px">
	            美
	            <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="#999" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polyline points="1 4 1 10 7 10"/><polyline points="23 20 23 14 17 14"/><path d="M20.49 9A9 9 0 0 0 5.64 5.64L1 10m22 4l-4.64 4.36A9 9 0 0 1 3.51 15"/></svg>
	          </button>
	          <span style="font-family:Inter,sans-serif;font-size:12px;color:#999;padding:0 8px">/ɪˈfemərəl/</span>
	          <button style="width:28px;height:28px;border:none;border-radius:50%;background:#eef0ff;display:flex;align-items:center;justify-content:center">${speakerI}</button>
	        </div>
	      </div>
      <div style="display:flex;gap:12px;width:100%;max-width:260px">
        <button style="flex:1;padding:12px;border:1px solid #e2e2ea;border-radius:100px;background:#fff;font-family:Inter,sans-serif;font-size:14px;color:#0b0b0f">不认识</button>
        <button style="flex:1;padding:12px;border:none;border-radius:100px;background:#2f5cff;font-family:Inter,sans-serif;font-size:14px;color:#fff;font-weight:600">认识 ✓</button>
      </div>
    </div>
    <div style="padding:0 20px 12px">
      <div style="height:4px;background:#f0f0f5;border-radius:2px;overflow:hidden"><div style="width:30%;height:100%;background:#2f5cff;border-radius:2px"></div></div>
      <div style="display:flex;justify-content:space-between;margin-top:4px">
        <span style="font-family:JetBrains Mono,monospace;font-size:10px;color:#00c896">✓ 4</span>
        <span style="font-family:JetBrains Mono,monospace;font-size:10px;color:#999">✗ 1</span>
      </div>
    </div>`);

// ===== PAGE 3b =====
const p3b = mockup('3b', '学习 · 释义', SCREEN, `
    <div style="background:#fff;border-bottom:1px solid #e2e2ea;padding:12px 14px;display:flex;align-items:center;gap:12px">
      <span style="font-size:16px;color:#0b0b0f;cursor:pointer">&larr;</span>
      <div style="flex:1;font-family:Inter,sans-serif;font-size:14px;font-weight:600;color:#0b0b0f">拾词集 · 释义</div>
      <div style="font-family:JetBrains Mono,monospace;font-size:12px;color:#999">3/8</div>
    </div>
    <div style="flex:1;padding:20px;display:flex;flex-direction:column;gap:16px;overflow-y:auto">
	      <div style="text-align:center">
	        <div style="font-family:Source Serif 4,serif;font-size:28px;color:#0b0b0f;font-weight:600">ephemeral</div>
	        <div style="display:flex;align-items:center;justify-content:center;margin-top:10px">
	          <div style="display:flex;align-items:center;background:#f0f0f5;border-radius:100px;padding:3px">
	            <button style="padding:5px 10px;border:none;border-radius:100px;background:#fff;font-family:Inter,sans-serif;font-size:11px;color:#0b0b0f;font-weight:600;display:flex;align-items:center;gap:5px">
	              美
	              <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="#999" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polyline points="1 4 1 10 7 10"/><polyline points="23 20 23 14 17 14"/><path d="M20.49 9A9 9 0 0 0 5.64 5.64L1 10m22 4l-4.64 4.36A9 9 0 0 1 3.51 15"/></svg>
	            </button>
	            <span style="font-family:Inter,sans-serif;font-size:12px;color:#999;padding:0 8px">/ɪˈfemərəl/</span>
	            <button style="width:28px;height:28px;border:none;border-radius:50%;background:#eef0ff;display:flex;align-items:center;justify-content:center">${speakerI}</button>
	          </div>
	        </div>
	      </div>
	      <div style="background:#fff;border:1px solid #e2e2ea;border-radius:12px;padding:14px">
	        <div style="font-family:Inter,sans-serif;font-size:10px;font-weight:600;color:#999;text-transform:uppercase;margin-bottom:6px">释义</div>
	        <div style="font-family:Inter,sans-serif;font-size:13px;color:#0b0b0f;line-height:1.6"><span style="font-weight:600;color:#2f5cff">adj.</span></div>
        <div style="font-family:Inter,sans-serif;font-size:13px;color:#0b0b0f;line-height:1.6;margin-top:6px">1. 短暂的，转瞬即逝的<br>2. 朝生暮死的（生物）</div>
	      </div>
	      <div style="background:#fff;border:1px solid #e2e2ea;border-radius:12px;padding:14px">
	        <div style="font-family:Inter,sans-serif;font-size:10px;font-weight:600;color:#999;text-transform:uppercase;margin-bottom:8px">例句</div>
	        <div style="font-family:Inter,sans-serif;font-size:12px;color:#666;line-height:1.8;margin-bottom:6px">"Fame is ephemeral — don't chase it." <button style="width:22px;height:22px;border:none;border-radius:50%;background:#eef0ff;display:inline-flex;align-items:center;justify-content:center;vertical-align:middle;margin-left:4px"><svg width="11" height="11" viewBox="0 0 24 24" fill="none" stroke="#2f5cff" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round"><polygon points="11 5 6 9 2 9 2 15 6 15 11 19 11 5"/><path d="M19.07 4.93a10 10 0 0 1 0 14.14"/><path d="M15.54 8.46a5 5 0 0 1 0 7.07"/></svg></button></div>
	        <div style="font-family:Inter,sans-serif;font-size:11px;color:#999;margin-bottom:12px">名声是短暂的，不要追逐它。</div>
	        <div style="font-family:Inter,sans-serif;font-size:12px;color:#666;line-height:1.8;margin-bottom:6px">"The cherry blossoms are ephemeral, lasting only a few days." <button style="width:22px;height:22px;border:none;border-radius:50%;background:#eef0ff;display:inline-flex;align-items:center;justify-content:center;vertical-align:middle;margin-left:4px"><svg width="11" height="11" viewBox="0 0 24 24" fill="none" stroke="#2f5cff" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round"><polygon points="11 5 6 9 2 9 2 15 6 15 11 19 11 5"/><path d="M19.07 4.93a10 10 0 0 1 0 14.14"/><path d="M15.54 8.46a5 5 0 0 1 0 7.07"/></svg></button></div>
	        <div style="font-family:Inter,sans-serif;font-size:11px;color:#999">樱花转瞬即逝，只开几天。</div>
	      </div>
      <button style="padding:12px;border:none;border-radius:100px;background:#2f5cff;font-family:Inter,sans-serif;font-size:14px;color:#fff;font-weight:600;margin-top:auto">下一词 →</button>
    </div>`);

// ===== PAGE 4 =====
const notebookCard = (name, badge, stats) => `
      <div style="background:#fff;border:1px solid #e2e2ea;border-radius:14px;padding:14px;display:flex;align-items:center;gap:12px">
        <div style="width:40px;height:50px;border-radius:5px;background:#f0f0f5;display:flex;align-items:center;justify-content:center;border:1px solid #e2e2ea;flex-shrink:0">${name==='拾词集'?bookI():`<svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="#0b0b0f" stroke-width="1.5"><path d="M2 3h8v16H2z"/><path d="M10 3h8l4 4v12H10z"/><path d="M14 3v4h4"/></svg>`}</div>
        <div style="flex:1;min-width:0">
          <div style="display:flex;align-items:center;gap:6px"><span style="font-family:Inter,sans-serif;font-size:14px;font-weight:600;color:#0b0b0f">${name}</span>${badge?`<span style="padding:1px 6px;border-radius:4px;background:#f0f0f5;font-family:Inter,sans-serif;font-size:9px;color:#999">${badge}</span>`:''}</div>
          <div style="font-family:Inter,sans-serif;font-size:11px;color:#999;margin-top:2px">${stats}</div>
        </div>
        <button style="width:30px;height:30px;border:1px solid #e2e2ea;border-radius:50%;background:#fff;display:flex;align-items:center;justify-content:center;flex-shrink:0">
	          <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="#999" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round"><path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"/><path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z"/></svg>
	        </button>
      </div>`;

const p4 = mockup('4', '单词本（Notebook 列表）', SCREEN, `
${headerBar('wordbook')}
    <div style="flex:1;padding:14px;display:flex;flex-direction:column;gap:8px;overflow-y:auto">
${notebookCard('拾词集', '默认', '12待复习 · 21掌握 · 35总计')}
${notebookCard('GRE 核心词汇', null, '8待复习 · 21掌握 · 32总计')}
${notebookCard('工作英语', null, '13待复习 · 5掌握 · 18总计')}
      <button style="padding:12px;border:1px dashed #e2e2ea;border-radius:12px;background:#fff;font-family:Inter,sans-serif;font-size:13px;color:#999">+ 新建单词本</button>
    </div>
${bottomPill()}`);


// ===== PAGE 4b · 新建单词本 =====
const p4b = mockup('新建', '新建单词本（弹出）', SCREEN+';position:relative', `
    <div style="flex:1;background:rgba(0,0,0,0.15);display:flex;align-items:flex-end">
      <div style="background:#fff;border-radius:18px 18px 0 0;width:100%;padding:18px 18px 24px;display:flex;flex-direction:column;gap:18px">
        <div style="width:30px;height:4px;border-radius:2px;background:#ddd;margin:0 auto -6px"></div>
        <div style="font-family:Inter,sans-serif;font-size:17px;font-weight:600;color:#0b0b0f;text-align:center">新建单词本</div>
        <div>
          <div style="font-family:Inter,sans-serif;font-size:10px;font-weight:600;color:#999;text-transform:uppercase;margin-bottom:8px">名称</div>
          <input style="width:100%;padding:12px 14px;border:1px solid #e2e2ea;border-radius:12px;font-family:Inter,sans-serif;font-size:14px;color:#0b0b0f;outline:none;background:#f9f9fb" placeholder="输入单词本名称...">
        </div>
        <button style="padding:14px;border:none;border-radius:100px;background:#2f5cff;font-family:Inter,sans-serif;font-size:15px;color:#fff;font-weight:600">创建</button>
        <button style="padding:0;border:none;background:none;font-family:Inter,sans-serif;font-size:13px;color:#999;text-align:center">取消</button>
      </div>
    </div>`);

// ===== PAGE 5 =====
const menuDots = '<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="#999" stroke-width="1.5" stroke-linecap="round"><circle cx="12" cy="5" r="1.5" fill="#999"/><circle cx="12" cy="12" r="1.5" fill="#999"/><circle cx="12" cy="19" r="1.5" fill="#999"/></svg>';

const wordRow5 = (word, pos, def) => `
	      <div style="background:#fff;border-bottom:1px solid #f0f0f5;padding:14px 16px;display:flex;align-items:center;gap:10px">
	        <div style="flex:1;min-width:0">
	          <div style="display:flex;align-items:baseline;gap:6px">
	            <span style="font-family:Source Serif 4,serif;font-size:16px;color:#0b0b0f;font-weight:600">${word}</span>
	            <span style="font-family:Inter,sans-serif;font-size:11px;color:#2f5cff;font-weight:500">${pos}</span>
	            <span style="font-family:Inter,sans-serif;font-size:12px;color:#999">${def}</span>
	          </div>
	        </div>
	        <button style="width:28px;height:28px;border:none;border-radius:50%;background:transparent;display:flex;align-items:center;justify-content:center;flex-shrink:0">${menuDots}</button>
	      </div>`;

const dateHeader = (label) => `
	      <div style="font-family:Inter,sans-serif;font-size:11px;font-weight:600;color:#bbb;padding:10px 16px 4px;text-transform:uppercase;letter-spacing:0.04em">${label}</div>`;

const p5 = mockup('5', '单词本详情（本子内单词）', SCREEN, `
	    <div style="background:#fff;border-bottom:1px solid #e2e2ea;padding:12px 14px;display:flex;align-items:center;gap:12px">
	      <span style="font-size:18px;color:#0b0b0f;cursor:pointer">&larr;</span>
	      <span style="font-family:Inter,sans-serif;font-size:15px;font-weight:600;color:#0b0b0f">拾词集</span>
	      <button style="margin-left:auto;padding:5px 12px;border:1px solid #e2e2ea;border-radius:100px;background:#fff;font-family:Inter,sans-serif;font-size:12px;color:#666;display:flex;align-items:center;gap:4px">
	        管理
	        <svg width="10" height="10" viewBox="0 0 24 24" fill="none" stroke="#999" stroke-width="2"><polyline points="6 9 12 15 18 9"/></svg>
	      </button>
	    </div>
	    <div style="background:#fff;border-bottom:1px solid #e2e2ea;padding:0 14px;display:flex;gap:0">
	      <button style="padding:8px 18px;border:none;border-bottom:2px solid #2f5cff;background:transparent;font-family:Inter,sans-serif;font-size:12px;font-weight:600;color:#2f5cff">全部</button>
	      <button style="padding:8px 18px;border:none;border-bottom:2px solid transparent;background:transparent;font-family:Inter,sans-serif;font-size:12px;color:#999">新词</button>
	      <button style="padding:8px 18px;border:none;border-bottom:2px solid transparent;background:transparent;font-family:Inter,sans-serif;font-size:12px;color:#999">掌握</button>
	    </div>
	    <div style="flex:1;display:flex;flex-direction:column;overflow-y:auto">
${dateHeader('5月7日')}
${wordRow5('ephemeral', 'adj.', '短暂的')}
${wordRow5('serendipity', 'n.', '意外发现')}
${dateHeader('5月5日')}
${wordRow5('ubiquitous', 'adj.', '无处不在的')}
${wordRow5('eloquent', 'adj.', '雄辩的')}
${dateHeader('2025/12/3')}
${wordRow5('pragmatic', 'adj.', '务实的')}
${wordRow5('resilience', 'n.', '韧性')}
	    </div>`);

// ===== PAGE 5b · 单词详情 =====
const p5b = mockup('单词', '单词详情', SCREEN, `
	    <div style="background:#fff;border-bottom:1px solid #e2e2ea;padding:12px 14px;display:flex;align-items:center;gap:12px">
	      <span style="font-size:18px;color:#0b0b0f;cursor:pointer">&larr;</span>
	      <span style="font-family:Inter,sans-serif;font-size:15px;font-weight:600;color:#0b0b0f">单词详情</span>
	      <button style="margin-left:auto;width:30px;height:30px;border:1px solid #e2e2ea;border-radius:50%;background:#fff;display:flex;align-items:center;justify-content:center">
	        <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="#999" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round"><path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"/><path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z"/></svg>
	      </button>
	    </div>
	    <div style="flex:1;padding:16px;display:flex;flex-direction:column;gap:12px;overflow-y:auto">
	      <div style="text-align:center">
	        <div style="font-family:Source Serif 4,serif;font-size:28px;color:#0b0b0f;font-weight:600">ephemeral</div>
	        <div style="display:flex;align-items:center;justify-content:center;margin-top:10px">
	          <div style="display:flex;align-items:center;background:#f0f0f5;border-radius:100px;padding:3px">
	            <button style="padding:5px 10px;border:none;border-radius:100px;background:#fff;font-family:Inter,sans-serif;font-size:11px;color:#0b0b0f;font-weight:600;display:flex;align-items:center;gap:5px">
	              美
	              <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="#999" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polyline points="1 4 1 10 7 10"/><polyline points="23 20 23 14 17 14"/><path d="M20.49 9A9 9 0 0 0 5.64 5.64L1 10m22 4l-4.64 4.36A9 9 0 0 1 3.51 15"/></svg>
	            </button>
	            <span style="font-family:Inter,sans-serif;font-size:12px;color:#999;padding:0 8px">/ɪˈfemərəl/</span>
	            <button style="width:28px;height:28px;border:none;border-radius:50%;background:#eef0ff;display:flex;align-items:center;justify-content:center">${speakerI}</button>
	          </div>
	        </div>
	      </div>
	      <div style="background:#fff;border:1px solid #e2e2ea;border-radius:12px;padding:14px">
	        <div style="font-family:Inter,sans-serif;font-size:10px;font-weight:600;color:#999;text-transform:uppercase;margin-bottom:6px">释义</div>
	        <div style="font-family:Inter,sans-serif;font-size:13px;color:#0b0b0f;line-height:1.6"><span style="font-weight:600;color:#2f5cff">adj.</span></div>
	        <div style="font-family:Inter,sans-serif;font-size:13px;color:#0b0b0f;line-height:1.6;margin-top:6px">1. 短暂的，转瞬即逝的<br>2. 朝生暮死的（生物）</div>
	      </div>
	      <div style="background:#fff;border:1px solid #e2e2ea;border-radius:12px;padding:14px">
	        <div style="font-family:Inter,sans-serif;font-size:10px;font-weight:600;color:#999;text-transform:uppercase;margin-bottom:8px">例句</div>
	        <div style="font-family:Inter,sans-serif;font-size:12px;color:#666;line-height:1.8;margin-bottom:6px">"Fame is ephemeral — don't chase it." <button style="width:22px;height:22px;border:none;border-radius:50%;background:#eef0ff;display:inline-flex;align-items:center;justify-content:center;vertical-align:middle;margin-left:4px"><svg width="11" height="11" viewBox="0 0 24 24" fill="none" stroke="#2f5cff" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round"><polygon points="11 5 6 9 2 9 2 15 6 15 11 19 11 5"/><path d="M19.07 4.93a10 10 0 0 1 0 14.14"/><path d="M15.54 8.46a5 5 0 0 1 0 7.07"/></svg></button></div>
	        <div style="font-family:Inter,sans-serif;font-size:11px;color:#999;margin-bottom:12px">名声是短暂的，不要追逐它。</div>
	        <div style="font-family:Inter,sans-serif;font-size:12px;color:#666;line-height:1.8;margin-bottom:6px">"The cherry blossoms are ephemeral, lasting only a few days." <button style="width:22px;height:22px;border:none;border-radius:50%;background:#eef0ff;display:inline-flex;align-items:center;justify-content:center;vertical-align:middle;margin-left:4px"><svg width="11" height="11" viewBox="0 0 24 24" fill="none" stroke="#2f5cff" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round"><polygon points="11 5 6 9 2 9 2 15 6 15 11 19 11 5"/><path d="M19.07 4.93a10 10 0 0 1 0 14.14"/><path d="M15.54 8.46a5 5 0 0 1 0 7.07"/></svg></button></div>
	        <div style="font-family:Inter,sans-serif;font-size:11px;color:#999">樱花转瞬即逝，只开几天。</div>
	      </div>
		      <div style="background:#fff;border:1px solid #e2e2ea;border-radius:12px;padding:14px">
		        <div style="font-family:Inter,sans-serif;font-size:10px;font-weight:600;color:#999;text-transform:uppercase;margin-bottom:8px">学习状态</div>
		        <div style="display:flex;text-align:center">
		          <div style="flex:1"><span style="font-family:Inter,sans-serif;font-size:11px;color:#999">录入时间</span><div style="font-family:Inter,sans-serif;font-size:13px;color:#0b0b0f;margin-top:2px">2026/5/7</div></div>
		          <div style="flex:1"><span style="font-family:Inter,sans-serif;font-size:11px;color:#999">状态</span><div style="font-family:Inter,sans-serif;font-size:13px;color:#ffa940;font-weight:500;margin-top:2px">复习中</div></div>
		          <div style="flex:1"><span style="font-family:Inter,sans-serif;font-size:11px;color:#999">复习次数</span><div style="font-family:JetBrains Mono,monospace;font-size:16px;color:#ffa940;margin-top:2px">7/10</div></div>
		        </div>
		      </div>
	      <div style="background:#fff;border:1px solid #e2e2ea;border-radius:12px;padding:14px">
	        <div style="font-family:Inter,sans-serif;font-size:10px;font-weight:600;color:#999;text-transform:uppercase;margin-bottom:8px">标签</div>
	        <div style="display:flex;gap:6px;flex-wrap:wrap;align-items:center">
	          <span style="padding:3px 10px;border-radius:100px;background:#f0f0f5;font-family:Inter,sans-serif;font-size:11px;color:#666">GRE</span>
	          <span style="padding:3px 10px;border-radius:100px;background:#f0f0f5;font-family:Inter,sans-serif;font-size:11px;color:#666">高频</span>
	          <button style="padding:3px 10px;border:1px dashed #ddd;border-radius:100px;background:transparent;font-family:Inter,sans-serif;font-size:11px;color:#bbb">+ 添加</button>
	        </div>
	      </div>
	      <div style="background:#fff;border:1px solid #e2e2ea;border-radius:12px;padding:14px">
	        <div style="font-family:Inter,sans-serif;font-size:10px;font-weight:600;color:#999;text-transform:uppercase;margin-bottom:8px">录入来源</div>
	        <div style="display:flex;align-items:center;gap:8px">
	          <span style="font-size:15px">📋</span>
	          <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="#0b0b0f" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round"><path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"/><polyline points="14 2 14 8 20 8"/><line x1="12" y1="18" x2="12" y2="12"/><line x1="9" y1="15" x2="15" y2="15"/></svg>
	          <span style="font-family:Inter,sans-serif;font-size:11px;color:#bbb">2026/5/7</span>
	        </div>
	      </div>
	    </div>`);


// ===== PAGE 6 =====
const p6 = mockup('6', '档案卡', SCREEN, `
${headerBar('archive')}
    <div style="flex:1;padding:14px;display:flex;flex-direction:column;gap:12px;overflow-y:auto">
      <div style="background:#fff;border:1px solid #e2e2ea;border-radius:14px;padding:16px;text-align:center">
        <div style="display:flex;align-items:center;justify-content:center;gap:6px">
          <svg width="28" height="28" viewBox="0 0 24 24" fill="none" stroke="#ffa940" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"><path d="M12 2C8 2 4 6 4 10c0 6 8 12 8 12s8-6 8-12c0-4-4-8-8-8z"/><path d="M12 10a2 2 0 1 0 0-4 2 2 0 0 0 0 4z"/></svg>
          <span style="font-family:JetBrains Mono,monospace;font-size:36px;color:#ffa940">12</span>
        </div>
        <div style="font-family:Inter,sans-serif;font-size:13px;color:#999;margin-top:4px">累计学习天数</div>
      </div>
      <div style="display:flex;gap:8px">
        <div style="flex:1;background:#fff;border:1px solid #e2e2ea;border-radius:12px;padding:12px;text-align:center">
          <div style="font-family:JetBrains Mono,monospace;font-size:22px;color:#0b0b0f">89</div>
          <div style="font-family:Inter,sans-serif;font-size:10px;color:#999;margin-top:2px">词汇总量</div>
        </div>
        <div style="flex:1;background:#fff;border:1px solid #e2e2ea;border-radius:12px;padding:12px;text-align:center">
          <div style="font-family:JetBrains Mono,monospace;font-size:22px;color:#00c896">42</div>
          <div style="font-family:Inter,sans-serif;font-size:10px;color:#999;margin-top:2px">已掌握</div>
        </div>
        <div style="flex:1;background:#fff;border:1px solid #e2e2ea;border-radius:12px;padding:12px;text-align:center">
          <div style="font-family:JetBrains Mono,monospace;font-size:22px;color:#ffa940">47</div>
          <div style="font-family:Inter,sans-serif;font-size:10px;color:#999;margin-top:2px">复习中</div>
        </div>
      </div>
      <div style="background:#fff;border:1px solid #e2e2ea;border-radius:12px;padding:12px;text-align:center">
        <div style="font-family:JetBrains Mono,monospace;font-size:18px;color:#7068f0">3</div>
        <div style="font-family:Inter,sans-serif;font-size:10px;color:#999;margin-top:2px">单词本数</div>
      </div>
      <div style="font-family:Inter,sans-serif;font-size:10px;font-weight:600;color:#999;text-transform:uppercase;letter-spacing:0.05em">成就</div>
      <div style="background:#fff;border:1px solid #e2e2ea;border-radius:12px;overflow:hidden">
        <div style="padding:10px 14px;display:flex;align-items:center;gap:10px;border-bottom:1px solid #f0f0f5"><span style="font-size:16px">✓</span><span style="font-family:Inter,sans-serif;font-size:13px;color:#0b0b0f">首个单词</span></div>
        <div style="padding:10px 14px;display:flex;align-items:center;gap:10px;border-bottom:1px solid #f0f0f5"><span style="font-size:16px">✓</span><span style="font-family:Inter,sans-serif;font-size:13px;color:#0b0b0f">掌握 20 词</span></div>
        <div style="padding:10px 14px;display:flex;align-items:center;gap:10px;border-bottom:1px solid #f0f0f5"><span style="font-size:16px">✓</span><span style="font-family:Inter,sans-serif;font-size:13px;color:#0b0b0f">连续学习 7 天</span></div>
        <div style="padding:10px 14px;display:flex;align-items:center;gap:10px"><span style="font-size:14px;color:#ddd">○</span><span style="font-family:Inter,sans-serif;font-size:13px;color:#bbb">掌握 100 词</span><span style="font-family:JetBrains Mono,monospace;font-size:10px;color:#ddd;margin-left:auto">0%</span></div>
      </div>
    </div>
${bottomPill()}`);

// ===== PAGE 7 =====
const p7 = mockup('7', '设置', SCREEN, `
    <div style="background:#fff;border-bottom:1px solid #e2e2ea;padding:12px 14px;display:flex;align-items:center;gap:12px">
      <span style="font-size:18px;color:#0b0b0f;cursor:pointer">&larr;</span>
      <span style="font-family:Inter,sans-serif;font-size:15px;font-weight:600;color:#0b0b0f">设置</span>
    </div>
    <div style="flex:1;padding:14px;display:flex;flex-direction:column;gap:12px;overflow-y:auto">
      <div style="font-family:Inter,sans-serif;font-size:10px;font-weight:600;color:#999;text-transform:uppercase">数据管理</div>
      <div style="background:#fff;border:1px solid #e2e2ea;border-radius:14px;overflow:hidden">
        <div style="padding:14px;display:flex;align-items:center;justify-content:space-between;border-bottom:1px solid #f0f0f5">
          <div><div style="font-family:Inter,sans-serif;font-size:14px;color:#0b0b0f">导出数据</div><div style="font-family:Inter,sans-serif;font-size:11px;color:#999;margin-top:2px">JSON 文件，含所有单词本和单词</div></div>
          <span style="font-family:Inter,sans-serif;font-size:13px;color:#bbb">▸</span>
        </div>
        <div style="padding:14px;display:flex;align-items:center;justify-content:space-between;">
          <div><div style="font-family:Inter,sans-serif;font-size:14px;color:#0b0b0f">导入数据</div><div style="font-family:Inter,sans-serif;font-size:11px;color:#999;margin-top:2px">从 JSON 文件恢复，同名去重合并</div></div>
          <span style="font-family:Inter,sans-serif;font-size:13px;color:#bbb">▸</span>
        </div>
      </div>
      <div style="font-family:Inter,sans-serif;font-size:10px;font-weight:600;color:#999;text-transform:uppercase;margin-top:4px">其他</div>
      <div style="background:#fff;border:1px solid #e2e2ea;border-radius:14px;overflow:hidden">
        <div style="padding:14px;display:flex;align-items:center;justify-content:space-between;border-bottom:1px solid #f0f0f5">
          <span style="font-family:Inter,sans-serif;font-size:14px;color:#0b0b0f">剪贴板监听</span>
          <div style="width:36px;height:20px;border-radius:10px;background:#2f5cff;position:relative"><div style="position:absolute;top:2px;right:2px;width:16px;height:16px;border-radius:50%;background:#fff"></div></div>
        </div>
        <div style="padding:14px;display:flex;align-items:center;justify-content:space-between;">
          <span style="font-family:Inter,sans-serif;font-size:14px;color:#0b0b0f">关于见词</span>
          <span style="font-family:JetBrains Mono,monospace;font-size:11px;color:#bbb">v1.0.0</span>
        </div>
      </div>
    </div>`);

// ===== PAGE 8 =====
const p8 = mockup('8', '录入弹出（点底部拍照/记录）', SCREEN+';position:relative', `
    <div style="flex:1;background:rgba(0,0,0,0.15);display:flex;align-items:flex-end">
      <div style="background:#fff;border-radius:18px 18px 0 0;width:100%;padding:18px 18px 22px;display:flex;flex-direction:column;gap:14px">
        <div style="width:30px;height:4px;border-radius:2px;background:#ddd;margin:0 auto -4px"></div>
        <div style="font-family:Inter,sans-serif;font-size:16px;font-weight:600;color:#0b0b0f;text-align:center">记录生词</div>
        <div style="background:#fff;border:1px solid #e2e2ea;border-radius:12px;padding:14px;display:flex;align-items:center;gap:12px">
          <div style="width:36px;height:36px;border-radius:50%;background:#f0f0f5;display:flex;align-items:center;justify-content:center">${cameraBigI}</div>
          <div><div style="font-family:Inter,sans-serif;font-size:14px;font-weight:600;color:#0b0b0f">拍照识别</div><div style="font-family:Inter,sans-serif;font-size:11px;color:#999;margin-top:1px">OCR 提取单词，自动查释义</div></div>
        </div>
        <div style="background:#fff;border:1px solid #e2e2ea;border-radius:12px;padding:14px;display:flex;align-items:center;gap:12px">
          <div style="width:36px;height:36px;border-radius:50%;background:#f0f0f5;display:flex;align-items:center;justify-content:center">
            <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="#0b0b0f" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round"><path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"/><polyline points="14 2 14 8 20 8"/><line x1="12" y1="18" x2="12" y2="12"/><line x1="9" y1="15" x2="15" y2="15"/></svg>
          </div>
          <div><div style="font-family:Inter,sans-serif;font-size:14px;font-weight:600;color:#0b0b0f">手动输入</div><div style="font-family:Inter,sans-serif;font-size:11px;color:#999;margin-top:1px">直接输入单词，自动查释义</div></div>
        </div>
        <div style="background:#f0f0f5;border-radius:8px;padding:10px 12px;text-align:center">
          <span style="font-family:Inter,sans-serif;font-size:11px;color:#999">存入 </span><span style="font-family:Inter,sans-serif;font-size:11px;font-weight:600;color:#0b0b0f">拾词集</span>
        </div>
        <button style="padding:12px;border:1px solid #e2e2ea;border-radius:100px;background:#fff;font-family:Inter,sans-serif;font-size:13px;color:#999">取消</button>
      </div>
    </div>`);

// ===== ASSEMBLE =====
const allMockups = [p1, p2, p3a, p3b, p4, p4b, p5, p5b, p6, p7, p8].join('\n\n');

const result = head +
  '\n<div class="section" style="display:flex;gap:12px;align-items:flex-start;flex-wrap:wrap">\n' +
  allMockups +
  '\n</div>\n\n' +
  tail;

fs.writeFileSync('D:/Project/CodeProjects/ClaudeWork/WordSnap/.superpowers/brainstorm/970-1778067419/content/all-pages.html', result, 'utf8');
console.log('Rebuilt successfully. Total size:', result.length, 'bytes');
console.log('Mockup count:', allMockups.match(/class="mockup"/g).length);
