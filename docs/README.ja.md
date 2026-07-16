# Claude Usage Monitor

[English](../README.md) · [简体中文](README.zh-CN.md) · **日本語** · [한국어](README.ko.md) · [Deutsch](README.de.md) · [Français](README.fr.md) · [Português](README.pt.md) · [Русский](README.ru.md)

**Claude Code** の公式な使用量上限と推定コストをリアルタイムで監視する、ネイティブ macOS メニューバーアプリです。

> アプリの UI は macOS のシステム言語に自動で追従します（英語・簡体字中国語・日本語・韓国語・ドイツ語・フランス語・ポルトガル語・ロシア語）。それ以外は英語にフォールバックします。

## スクリーンショット

<p align="center">
  <img src="screenshot-dashboard.png" width="340" alt="使用量上限とアクティビティのダッシュボード">
</p>
<p align="center">
  <img src="screenshot-cost.png" width="520" alt="推定コスト">
</p>

## 必要条件

- macOS 13 以降
- **Claude Code** CLI がインストール・ログイン済み（アプリは `claude -p '/usage'` で公式の上限を取得します）

## インストール

1. [Releases](../../../releases) から最新の `Claude Usage Monitor.zip` をダウンロードして解凍します。
2. `Claude Usage Monitor.app` を「アプリケーション」にドラッグします。
3. 初回起動がブロックされたら: アプリを右クリック →「開く」。または「システム設定 → プライバシーとセキュリティ」で「このまま開く」をクリックします。

> このアプリはローカルの ad-hoc 署名で、Apple の公証は受けていないため、初回のみ手動での許可が必要です。

## 使い方

起動後は **メニューバー** にのみ表示され、Dock アイコンはありません。

- メニューバーのタイトルには現在の **最も高い上限使用率（%）** が表示され、上限に近いほど赤くなります。
- **アイコンをクリック** するとダッシュボードが開きます:
  - **使用量上限 · 公式** —— 現在のセッション、今週（全モデル）、今週（Fable）の使用率 + リセット時刻。Claude Code の `/usage` と完全に一致します。
  - **アクティビティウィンドウ** —— 直近 24 時間 / 7 日間のリクエスト数、セッション数、ロングコンテキストの割合。
  - **主な内訳** —— 直近 7 日間で最も寄与した skills / plugins / MCP / subagents。
  - **推定コスト · ローカルログ** —— `~/.claude/projects/**/*.jsonl` から公開料金で推定した本日 / 直近 7 日間 / 全期間のコストと、14 日間の棒グラフ。

更新間隔: 公式の上限は 5 分ごと、ローカルのコストは 60 秒ごと。

### ログイン時に起動

システム設定 → 一般 → ログイン項目 → `Claude Usage Monitor.app` を追加。

## 料金のカスタマイズ

コストは Anthropic の公開料金で推定します（Fable/Mythos は暫定的に Opus 料金で計算）。上書きするには
`~/.config/claude-usage-monitor/pricing.json` を作成します。単位は「100 万トークンあたりの USD」です:

```json
{
  "fable": { "input": 15, "output": 75, "cacheWrite5m": 18.75, "cacheWrite1h": 30, "cacheRead": 1.5 }
}
```

キーはモデル ID の部分一致で照合されます（例: `opus`、`sonnet`、`haiku`、`fable`）。料金のない非 Anthropic モデルはコスト $0 として扱われますが、トークンは引き続き集計されます。

## ソースからビルド

```bash
./build.sh
open "dist/Claude Usage Monitor.app"
```

Swift 6（Xcode コマンドラインツール）が必要です。成果物は `dist/` に出力されます（バージョン管理対象外）。
