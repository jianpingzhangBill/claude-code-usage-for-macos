# Claude Usage Monitor

一个原生 macOS 菜单栏小工具，实时监控 **Claude Code** 的官方用量限额与花费。

菜单栏显示当前最高的限额使用率（%），颜色随接近限额变红；点击展开仪表盘：

- **用量限额 · 官方** —— 直接来自 `claude -p '/usage'`：当前 session、本周（全模型）、本周（Fable）
  的使用百分比 + 重置时间。**这是官方权威数据**，和你在 Claude Code 里 `/usage` 看到的完全一致。
- **活动窗口** —— 近 24h / 近 7d 的请求数、会话数、长上下文占比
- **主要来源** —— 近 7d 贡献最多的 skills / plugins / MCP / subagents
- **花费估算 · 本地日志** —— 从 `~/.claude/projects/**/*.jsonl` 按公开单价估算的今日/近 7 天/全部花费
  + 近 14 天柱状图（`/usage` 只给百分比，不给美元，这部分补上）

## 数据来源与鉴权

- **官方限额**：工具通过登录 shell 执行 `claude -p '/usage'` 抓取。**它不直接接触任何 token 或
  环境变量** —— 由 `claude` CLI 自己完成鉴权（无论你是订阅、直连 API、还是走企业代理都通用），
  所以免维护、不会因为端点变化而失效。
- **花费估算**：纯本地读日志，离线、精确到 token，仅美元为估算值。

> 注：官方限额每 5 分钟刷新一次（每次会拉起一次 `claude`，稍有开销）；本地花费每 60 秒刷新。

## 构建 & 运行

```bash
./build.sh
open "dist/Claude Usage Monitor.app"
```

需要 macOS 13+ 和 Swift 6（Xcode 命令行工具）。构建产物是一个 `LSUIElement` 应用
（只在菜单栏，无 Dock 图标）。

想开机自启：系统设置 → 通用 → 登录项 → 添加 `dist/Claude Usage Monitor.app`。

## 自定义定价

花费是按 Anthropic 公开单价估算的（Fable/Mythos 暂按 Opus 档估算）。要覆盖，创建
`~/.config/claude-usage-monitor/pricing.json`，单位是「美元 / 百万 token」：

```json
{
  "fable": { "input": 15, "output": 75, "cacheWrite5m": 18.75, "cacheWrite1h": 30, "cacheRead": 1.5 }
}
```

键名按模型 id 子串匹配（如 `opus`、`sonnet`、`haiku`、`fable`）。非 Anthropic 模型
（如 deepseek）无单价时花费计为 0，但 token 仍会统计。

## 实现说明

- `UsageStore.swift` —— 解析 JSONL、按 `message.id` 去重、按天/模型/5 小时窗口聚合
- `Pricing.swift` —— 定价表与花费估算
- `App.swift` / `DashboardView.swift` —— `MenuBarExtra` 界面与图表
- token 口径 = input + output + cache write(5m/1h) + cache read；仅统计 assistant 回合，跳过 `<synthetic>`
