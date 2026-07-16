# Claude Usage Monitor

[English](../README.md) · **简体中文** · [日本語](README.ja.md) · [한국어](README.ko.md) · [Deutsch](README.de.md) · [Français](README.fr.md) · [Português](README.pt.md) · [Русский](README.ru.md)

一个原生 macOS 菜单栏小工具,实时监控 **Claude Code** 的官方用量限额与花费。

> App 界面会自动跟随 macOS 系统语言 —— 英文、简体中文、日文、韩语、德语、法语、葡萄牙语、俄语 —— 其余语言回退到英文。

## 截图

<p align="center">
  <img src="screenshot-dashboard.png" width="340" alt="用量限额与活动窗口仪表盘">
</p>
<p align="center">
  <img src="screenshot-cost.png" width="520" alt="花费估算">
</p>

## 前置要求

- macOS 13+
- 已安装并登录 **Claude Code** CLI(工具通过 `claude -p '/usage'` 读取官方限额)

## 安装

1. 从 [Releases](../../../releases) 下载最新的 `Claude Usage Monitor.zip`,解压。
2. 把 `Claude Usage Monitor.app` 拖到「应用程序」。
3. 首次打开若被拦截:右键 App → 打开;或到「系统设置 → 隐私与安全性」点「仍要打开」。

> App 为本地 ad-hoc 签名,未做 Apple 公证,所以首次需手动放行。

## 使用

启动后只在**菜单栏**显示图标,无 Dock 图标。

- 菜单栏标题显示当前**最高的限额使用率(%)**,越接近限额越红。
- **点击图标**展开仪表盘:
  - **用量限额 · 官方** —— 当前 session、本周(全模型)、本周(Fable)的使用百分比 + 重置时间。与 Claude Code 里 `/usage` 完全一致。
  - **活动窗口** —— 近 24h / 近 7d 的请求数、会话数、长上下文占比。
  - **主要来源** —— 近 7d 贡献最多的 skills / plugins / MCP / subagents。
  - **花费估算 · 本地日志** —— 从 `~/.claude/projects/**/*.jsonl` 按公开单价估算的今日 / 近 7 天 / 全部花费,附近 14 天柱状图。

刷新频率:官方限额每 5 分钟一次,本地花费每 60 秒一次。

### 开机自启

系统设置 → 通用 → 登录项 → 添加 `Claude Usage Monitor.app`。

## 自定义定价

花费按 Anthropic 公开单价估算(Fable/Mythos 暂按 Opus 档)。要覆盖,创建
`~/.config/claude-usage-monitor/pricing.json`,单位是「美元 / 百万 token」:

```json
{
  "fable": { "input": 15, "output": 75, "cacheWrite5m": 18.75, "cacheWrite1h": 30, "cacheRead": 1.5 }
}
```

键名按模型 id 子串匹配(如 `opus`、`sonnet`、`haiku`、`fable`)。非 Anthropic 模型无单价时花费计为 0,但 token 仍会统计。

## 从源码构建

```bash
./build.sh
open "dist/Claude Usage Monitor.app"
```

需要 Swift 6(Xcode 命令行工具)。产物在 `dist/`(不纳入版本管理)。
