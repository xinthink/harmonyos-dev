# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## TL;DR

```bash
# ArkTS build+deploy+run
cd <project> && devecocli run --module entry --build-mode debug

# Cangjie build+run
source skills/env-setup/scripts/envsetup.sh && cd <project> && cjpm build && cjpm run

# Error logs
devecocli log --level E --tail 20
```

## Repo Purpose

This is a **Claude Code plugin** for HarmonyOS NEXT development. It provides skills that teach Claude how to use the DevEco CLI toolchain, the deveco-mcp MCP server, and official HarmonyOS skills. It is **not** an application repo.

## Plugin Structure

```
harmonyos-dev/
├── skills/
│   ├── env-setup/        # One-time toolchain setup → ~/.harmonyosdev/config.json
│   ├── arkts-dev/        # ArkTS build/deploy/debug/log workflow
│   └── cangjie-dev/      # Cangjie build/run/test/LSP workflow
├── .lsp.json             # Cangjie language server config
└── .claude-plugin/plugin.json
```

## Skills

| Skill | Invoke when |
|---|---|
| `env-setup` | First session, toolchain not found, or adding Cangjie |
| `arkts-dev` | Building `.ets` files, deploying, debugging, emulator, logs |
| `cangjie-dev` | Working with `.cj` files, cjpm, cjc, Cangjie LSP |

All Cangjie SDK paths are read from `~/.harmonyosdev/config.json` (`cangjie.home`), falling back to the conventional default `~/.harmonyosdev/sdk/cangjie/`. The `.lsp.json` file must be regenerated from config if the SDK is at a non-default location (see `cangjie-dev` skill).

## DevEco CLI (devecocli)

- **Prerequisites**: Node.js >= 18 + DevEco Studio >= 6.1.0 in `/Applications` (macOS)
- devecocli auto-discovers all tools from DevEco Studio's `.app` bundle — no env vars, no separate CLI tools download
- Install: `npm install -g @deveco/deveco-cli`
- **Known bug** (v1.0.0): `devecocli build` standalone crashes. Use `devecocli run` instead.

## Key Commands

| Command | Purpose |
|---|---|
| `devecocli run --module entry --build-mode debug` | Build + deploy + launch |
| `devecocli create --app-name X` | Scaffold new project |
| `devecocli log --level E --tail 20 --follow` | Error log streaming |
| `devecocli emulator start <name>` | Start emulator |
| `devecocli emulator license accept` | Accept licenses (first time) |
| `devecocli device list` | List connected devices |
| `devecocli docs search <q>` | Search offline HarmonyOS docs |
| `devecocli init --mcp` | Configure deveco-mcp for syntax checking |
| `cjpm build` | Build Cangjie project |
| `cjpm run` | Build + run Cangjie project |

## Cangjie

- Cangjie SDK is separate from DevEco Studio — install from https://cangjie-lang.cn/download
- Source env before use: `source skills/env-setup/scripts/envsetup.sh`
- Known issues: macOS login shell detection bug in SDK's envsetup.sh (use ours); Cangjie ≤0.56.4 + macOS ≥26.x linker crash (fixed in 1.x)
