# Claude Usage Monitor

[English](../README.md) · [简体中文](README.zh-CN.md) · [日本語](README.ja.md) · [한국어](README.ko.md) · [Deutsch](README.de.md) · [Français](README.fr.md) · **Português** · [Русский](README.ru.md)

Um app nativo para a barra de menus do macOS que monitora em tempo real os limites de uso oficiais e os gastos estimados do **Claude Code**.

> A interface do app se adapta automaticamente ao idioma do sistema macOS — inglês, chinês simplificado, japonês, coreano, alemão, francês, português, russo — e recorre ao inglês nos demais casos.

## Capturas de tela

<p align="center">
  <img src="screenshot-dashboard.png" width="340" alt="Painel de limites de uso e atividade">
</p>
<p align="center">
  <img src="screenshot-cost.png" width="520" alt="Gasto estimado">
</p>

## Requisitos

- macOS 13+
- CLI do **Claude Code** instalado e conectado (o app lê os limites oficiais via `claude -p '/usage'`)

## Instalação

1. Baixe o `Claude Usage Monitor.zip` mais recente em [Releases](../../../releases) e descompacte.
2. Arraste `Claude Usage Monitor.app` para Aplicativos.
3. Se o macOS bloquear a primeira execução: clique com o botão direito no app → Abrir; ou vá em Ajustes do Sistema → Privacidade e Segurança e clique em "Abrir mesmo assim".

> O app tem assinatura ad-hoc local e não é autenticado pela Apple, então a primeira execução exige uma liberação manual.

## Uso

Após iniciar, ele vive apenas na **barra de menus** — sem ícone no Dock.

- O título na barra de menus mostra o **pico de uso dos limites (%)** atual; quanto mais perto do limite, mais vermelho.
- **Clique no ícone** para abrir o painel:
  - **Limites de uso · Oficial** — porcentagem de uso + horário de reinício para a sessão atual, a semana atual (todos os modelos) e a semana atual (Fable). Corresponde exatamente ao `/usage` no Claude Code.
  - **Janelas de atividade** — número de solicitações, sessões e proporção de contexto longo nas últimas 24 h / 7 dias.
  - **Principais fontes** — os skills / plugins / MCP / subagents que mais contribuíram nos últimos 7 dias.
  - **Custo estimado · Logs locais** — gasto de hoje / últimos 7 dias / total estimado a partir de `~/.claude/projects/**/*.jsonl` pelos preços públicos, com um gráfico de barras de 14 dias.

Frequência de atualização: limites oficiais a cada 5 minutos, custo local a cada 60 segundos.

### Iniciar ao fazer login

Ajustes do Sistema → Geral → Itens de Início → adicione `Claude Usage Monitor.app`.

## Preços personalizados

Os gastos são estimados pelos preços públicos da Anthropic (Fable/Mythos temporariamente cobrados no nível Opus). Para substituir, crie
`~/.claude/claude-usage-monitor/pricing.json`, com unidades em "USD por milhão de tokens":

```json
{
  "fable": { "input": 15, "output": 75, "cacheWrite5m": 18.75, "cacheWrite1h": 30, "cacheRead": 1.5 }
}
```

As chaves são correspondidas por substring do ID do modelo (ex.: `opus`, `sonnet`, `haiku`, `fable`). Modelos não-Anthropic sem preço são contabilizados como $0 no custo, mas seus tokens continuam sendo somados.

## Compilar a partir do código-fonte

```bash
./build.sh
open "dist/Claude Usage Monitor.app"
```

Requer Swift 6 (ferramentas de linha de comando do Xcode). O resultado vai para `dist/` (não versionado).
