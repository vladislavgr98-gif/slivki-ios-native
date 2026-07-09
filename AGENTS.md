# Slivki agent workflow

Native iOS app for [slivki-shop.ru](https://slivki-shop.ru). Mobile site = visual
reference only. Active crew lives in `.cursor/agents/` (Cursor) and
`.codex/agents/` (Codex TOML source).

## Connected crew (12)

1. `swift-expert` — iOS/SwiftUI implementation
2. `mobile-app-developer` — multi-screen product flows
3. `ui-fixer` — tiny UI patches after reproduction
4. `ui-designer` — layout/interaction decisions
5. `php-pro` — production PHP / mobile API
6. `api-designer` — mobile-v1 contracts
7. `debugger` — root-cause isolation
8. `browser-debugger` — live-site evidence
9. `reviewer` — PR-style review
10. `qa-expert` — acceptance / risk QA
11. `deployment-engineer` — deploy & release safety
12. `security-auditor` — auth/secrets/SSH boundary review

Upstream source: `/Users/slivki/Documents/Slivki/awesome-codex-subagents`
(VoltAgent/awesome-codex-subagents). Extra unused Codex agents remain in
`.codex/agents/` for on-demand install.

## How to invoke in Cursor

Ask explicitly, for example:

- «Запусти `browser-debugger` и сверни home с сайтом»
- «Через `ui-fixer` поправь empty cart»
- «`reviewer` посмотри diff»
- «`php-pro` посмотрите `/api/mobile/v1` на prod»

Main chat should auto-delegate using `.cursor/rules/slivki-crew.mdc`.

## Current execution priorities

1. Native UI parity vs mobile site (guest + auth)
2. Keep local Simulator + `swift test` green
3. Backend next: SMS auth token, server cart, real orders, product slug lookup
4. Release later: AASA / Universal Links after Apple Team ID

## SSH

```bash
ssh slivki-prod
ssh slivki-prod-admin
```
