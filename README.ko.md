# Claude Usage Monitor

[English](README.md) · [简体中文](README.zh-CN.md) · [日本語](README.ja.md) · **한국어** · [Deutsch](README.de.md) · [Français](README.fr.md) · [Português](README.pt.md) · [Русский](README.ru.md)

**Claude Code**의 공식 사용량 한도와 예상 비용을 실시간으로 모니터링하는 네이티브 macOS 메뉴 막대 앱입니다.

> 앱 UI는 macOS 시스템 언어에 자동으로 맞춰집니다(영어·중국어 간체·일본어·한국어·독일어·프랑스어·포르투갈어·러시아어). 그 외 언어는 영어로 대체됩니다.

## 스크린샷

<p align="center">
  <img src="docs/screenshot-dashboard.png" width="340" alt="사용량 한도 및 활동 대시보드">
</p>
<p align="center">
  <img src="docs/screenshot-cost.png" width="520" alt="예상 비용">
</p>

## 요구 사항

- macOS 13 이상
- **Claude Code** CLI 설치 및 로그인 완료(앱은 `claude -p '/usage'`로 공식 한도를 읽습니다)

## 설치

1. [Releases](../../releases)에서 최신 `Claude Usage Monitor.zip`을 다운로드하고 압축을 풉니다.
2. `Claude Usage Monitor.app`을 응용 프로그램으로 드래그합니다.
3. 첫 실행이 차단되면: 앱을 마우스 오른쪽 클릭 → 열기; 또는 시스템 설정 → 개인정보 보호 및 보안에서 "그래도 열기"를 클릭합니다.

> 이 앱은 로컬 ad-hoc 서명이며 Apple 공증을 받지 않았으므로 첫 실행 시 수동 허용이 필요합니다.

## 사용법

실행하면 **메뉴 막대**에만 표시되며 Dock 아이콘은 없습니다.

- 메뉴 막대 제목에는 현재 **최고 한도 사용률(%)** 이 표시되며, 한도에 가까울수록 빨갛게 표시됩니다.
- **아이콘을 클릭**하면 대시보드가 열립니다:
  - **사용량 한도 · 공식** —— 현재 세션, 이번 주(전체 모델), 이번 주(Fable)의 사용률 + 재설정 시각. Claude Code의 `/usage`와 완전히 일치합니다.
  - **활동 창** —— 최근 24시간 / 7일의 요청 수, 세션 수, 롱 컨텍스트 비율.
  - **주요 출처** —— 최근 7일 동안 가장 많이 기여한 skills / plugins / MCP / subagents.
  - **예상 비용 · 로컬 로그** —— `~/.claude/projects/**/*.jsonl`에서 공개 요금으로 추정한 오늘 / 최근 7일 / 전체 비용과 14일 막대 차트.

새로 고침 주기: 공식 한도는 5분마다, 로컬 비용은 60초마다.

### 로그인 시 실행

시스템 설정 → 일반 → 로그인 항목 → `Claude Usage Monitor.app` 추가.

## 요금 사용자 지정

비용은 Anthropic의 공개 요금으로 추정됩니다(Fable/Mythos는 임시로 Opus 등급으로 청구). 재정의하려면
`~/.config/claude-usage-monitor/pricing.json`을 만듭니다. 단위는 "100만 토큰당 USD"입니다:

```json
{
  "fable": { "input": 15, "output": 75, "cacheWrite5m": 18.75, "cacheWrite1h": 30, "cacheRead": 1.5 }
}
```

키는 모델 ID 부분 문자열로 매칭됩니다(예: `opus`, `sonnet`, `haiku`, `fable`). 요금이 없는 비-Anthropic 모델은 비용 $0으로 계산되지만 토큰은 계속 집계됩니다.

## 소스에서 빌드

```bash
./build.sh
open "dist/Claude Usage Monitor.app"
```

Swift 6(Xcode 명령줄 도구)이 필요합니다. 결과물은 `dist/`에 생성됩니다(버전 관리 대상 아님).
