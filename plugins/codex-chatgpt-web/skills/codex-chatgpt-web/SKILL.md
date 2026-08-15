---
name: codex-chatgpt-web
description: Operate, explain, or diagnose an explicitly installed Aerox912 codex-chatgpt-web launcher and Responses bridge. Use when the user mentions Codex ChatGPT Web, its launcher, ChatGPT Web models in Codex, bridge health, setup, updates, or removal.
---

# Codex ChatGPT Web

Treat the Codex plugin and the Codex ChatGPT Web application as separate lifecycle surfaces.

## Installation boundary

- Installing this companion plugin must not install the launcher, runtime, browser profile, models, tunnel, or connector.
- Do not install, update, start, stop, repair, or remove the application unless the user explicitly asks for that application operation.
- If the application is absent, provide guidance or inspect source and release metadata only. Do not turn a diagnostic request into an installation.

## Working with an existing installation

1. Establish whether the user means the companion plugin, desktop launcher, local Responses bridge, Codex model catalog, or optional full-harness MCP connector.
2. Prefer the launcher's visible health and doctor surfaces. Use source commands only when working from a checked-out repository.
3. Preserve the launcher configuration and ChatGPT browser profile during updates or repair.
4. Keep login artifacts, API keys, tunnel identifiers, prompts, and task content out of logs and reports.
5. Distinguish non-mutating health evidence from an actual browser turn, connector change, or Codex configuration mutation.

The bridge is unofficial browser automation. UI drift and missing account capabilities must fail explicitly; never claim a hidden API, authentication bypass, or unsupported model capability.
