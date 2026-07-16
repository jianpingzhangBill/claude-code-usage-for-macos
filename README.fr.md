# Claude Usage Monitor

[English](README.md) · [简体中文](README.zh-CN.md) · [日本語](README.ja.md) · [한국어](README.ko.md) · [Deutsch](README.de.md) · **Français** · [Português](README.pt.md) · [Русский](README.ru.md)

Une application native pour la barre de menus macOS qui surveille en temps réel les limites d'utilisation officielles et les dépenses estimées de **Claude Code**.

> L'interface de l'application s'adapte automatiquement à la langue du système macOS — anglais, chinois simplifié, japonais, coréen, allemand, français, portugais, russe — et revient à l'anglais sinon.

## Captures d'écran

<p align="center">
  <img src="docs/screenshot-dashboard.png" width="340" alt="Tableau de bord des limites d'utilisation et de l'activité">
</p>
<p align="center">
  <img src="docs/screenshot-cost.png" width="520" alt="Dépenses estimées">
</p>

## Prérequis

- macOS 13+
- CLI **Claude Code** installé et connecté (l'application lit les limites officielles via `claude -p '/usage'`)

## Installation

1. Téléchargez le dernier `Claude Usage Monitor.zip` depuis les [Releases](../../releases) et décompressez-le.
2. Glissez `Claude Usage Monitor.app` dans Applications.
3. Si macOS bloque le premier lancement : clic droit sur l'application → Ouvrir ; ou allez dans Réglages Système → Confidentialité et sécurité et cliquez sur « Ouvrir quand même ».

> L'application est signée ad-hoc localement et non notariée par Apple, le premier lancement nécessite donc une autorisation manuelle.

## Utilisation

Après le lancement, elle vit uniquement dans la **barre de menus** — pas d'icône dans le Dock.

- Le titre de la barre de menus affiche le **pic d'utilisation des limites (%)** actuel ; plus on approche de la limite, plus c'est rouge.
- **Cliquez sur l'icône** pour ouvrir le tableau de bord :
  - **Limites d'utilisation · Officiel** — pourcentage d'utilisation + heure de réinitialisation pour la session actuelle, la semaine en cours (tous modèles) et la semaine en cours (Fable). Correspond exactement à `/usage` dans Claude Code.
  - **Fenêtres d'activité** — nombre de requêtes, de sessions et part de contexte long pour les dernières 24 h / 7 j.
  - **Principales sources** — les skills / plugins / MCP / subagents ayant le plus contribué sur les 7 derniers jours.
  - **Coût estimé · Journaux locaux** — dépenses d'aujourd'hui / des 7 derniers jours / totales estimées à partir de `~/.claude/projects/**/*.jsonl` aux tarifs publics, avec un histogramme sur 14 jours.

Fréquence de rafraîchissement : limites officielles toutes les 5 minutes, dépenses locales toutes les 60 secondes.

### Lancer à la connexion

Réglages Système → Général → Ouverture → ajouter `Claude Usage Monitor.app`.

## Tarification personnalisée

Les dépenses sont estimées aux tarifs publics d'Anthropic (Fable/Mythos facturés temporairement au niveau Opus). Pour les remplacer, créez
`~/.config/claude-usage-monitor/pricing.json`, avec des unités en « USD par million de tokens » :

```json
{
  "fable": { "input": 15, "output": 75, "cacheWrite5m": 18.75, "cacheWrite1h": 30, "cacheRead": 1.5 }
}
```

Les clés sont associées par sous-chaîne d'ID de modèle (par ex. `opus`, `sonnet`, `haiku`, `fable`). Les modèles non-Anthropic sans tarif sont comptés à 0 $, mais leurs tokens sont tout de même comptabilisés.

## Compiler depuis les sources

```bash
./build.sh
open "dist/Claude Usage Monitor.app"
```

Nécessite Swift 6 (outils en ligne de commande Xcode). Le résultat est placé dans `dist/` (non suivi par le contrôle de version).
