# Claude Usage Monitor

[English](README.md) · [简体中文](README.zh-CN.md) · [日本語](README.ja.md) · [한국어](README.ko.md) · **Deutsch** · [Français](README.fr.md) · [Português](README.pt.md) · [Русский](README.ru.md)

Eine native macOS-Menüleisten-App, die die offiziellen Nutzungslimits und die geschätzten Kosten von **Claude Code** in Echtzeit überwacht.

> Die App-Oberfläche passt sich automatisch der macOS-Systemsprache an – Englisch, Vereinfachtes Chinesisch, Japanisch, Koreanisch, Deutsch, Französisch, Portugiesisch, Russisch – und fällt sonst auf Englisch zurück.

## Screenshots

<p align="center">
  <img src="docs/screenshot-dashboard.png" width="340" alt="Dashboard mit Nutzungslimits und Aktivität">
</p>
<p align="center">
  <img src="docs/screenshot-cost.png" width="520" alt="Geschätzte Kosten">
</p>

## Voraussetzungen

- macOS 13+
- **Claude Code** CLI installiert und angemeldet (die App liest die offiziellen Limits über `claude -p '/usage'`)

## Installation

1. Lade die neueste `Claude Usage Monitor.zip` aus den [Releases](../../releases) herunter und entpacke sie.
2. Ziehe `Claude Usage Monitor.app` in den Ordner „Programme".
3. Falls macOS den ersten Start blockiert: Rechtsklick auf die App → Öffnen; oder gehe zu Systemeinstellungen → Datenschutz & Sicherheit und klicke auf „Trotzdem öffnen".

> Die App ist lokal ad-hoc signiert und nicht von Apple notariell beglaubigt, daher ist beim ersten Start eine manuelle Freigabe nötig.

## Verwendung

Nach dem Start lebt sie nur in der **Menüleiste** – kein Dock-Symbol.

- Der Titel in der Menüleiste zeigt die aktuelle **höchste Limit-Auslastung (%)**; je näher am Limit, desto röter.
- **Klicke auf das Symbol**, um das Dashboard zu öffnen:
  - **Nutzungslimits · Offiziell** – Auslastung in Prozent + Reset-Zeit für die aktuelle Sitzung, die aktuelle Woche (alle Modelle) und die aktuelle Woche (Fable). Stimmt exakt mit `/usage` in Claude Code überein.
  - **Aktivitätsfenster** – Anzahl der Anfragen, Sitzungen und Anteil langer Kontexte für die letzten 24 Std. / 7 Tage.
  - **Hauptquellen** – die skills / plugins / MCP / subagents, die in den letzten 7 Tagen am meisten beigetragen haben.
  - **Geschätzte Kosten · Lokale Logs** – heutige / letzte 7 Tage / gesamte Kosten, geschätzt aus `~/.claude/projects/**/*.jsonl` zu öffentlichen Preisen, mit einem 14-Tage-Balkendiagramm.

Aktualisierungsintervall: offizielle Limits alle 5 Minuten, lokale Kosten alle 60 Sekunden.

### Beim Anmelden starten

Systemeinstellungen → Allgemein → Anmeldeobjekte → `Claude Usage Monitor.app` hinzufügen.

## Preise anpassen

Die Kosten werden zu den öffentlichen Preisen von Anthropic geschätzt (Fable/Mythos vorübergehend zum Opus-Tarif). Zum Überschreiben erstelle
`~/.config/claude-usage-monitor/pricing.json`, mit Einheiten in „USD pro Million Tokens":

```json
{
  "fable": { "input": 15, "output": 75, "cacheWrite5m": 18.75, "cacheWrite1h": 30, "cacheRead": 1.5 }
}
```

Schlüssel werden per Teilstring der Modell-ID abgeglichen (z. B. `opus`, `sonnet`, `haiku`, `fable`). Nicht-Anthropic-Modelle ohne Preis werden mit $0 Kosten gezählt, ihre Tokens werden aber weiterhin erfasst.

## Aus dem Quellcode bauen

```bash
./build.sh
open "dist/Claude Usage Monitor.app"
```

Erfordert Swift 6 (Xcode-Befehlszeilentools). Das Ergebnis landet in `dist/` (nicht versioniert).
