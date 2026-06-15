---
name: arkts-dev
description: This skill should be used when developing HarmonyOS apps with ArkTS — building, deploying, debugging, creating pages, adding components, working with .ets files, or troubleshooting build/run errors. Activates on keywords: build, deploy, emulator, log, hilog, ArkTS, .ets, HarmonyOS app, OHOS app, Index.ets, EntryAbility, hvigor, build-profile.
---

# ArkTS Development Skill

## Overview

This skill teaches Claude how to develop HarmonyOS NEXT apps using devecocli and the deveco-mcp MCP server.

## Prerequisites

Check these before doing anything:

1. `devecocli --version` must succeed — verifies DevEco Studio is found by the ToolProvider.

   > If `devecocli --version` fails: "DevEco CLI not available. Run the env-setup skill first to configure your environment."

2. You must be in a HarmonyOS project directory (one that contains `build-profile.json5` at the root).

   > If not in a HarmonyOS project directory: suggest `devecocli create --app-name <name>` or ask the user which project to work on.

## Build & Run Workflow

### Preferred Command

```bash
devecocli run --module entry --build-mode debug
```

This builds, deploys to the connected device/emulator, and launches the app — all in one.

> **IMPORTANT**: NEVER use `devecocli build` standalone — it is known to crash in v1.0.0 with `Cannot read properties of undefined (reading 'some')`. If the user insists on build-only, use the hvigorw fallback described below.

### `devecocli run` Parameters

| Parameter | Description |
|---|---|
| `--module <name>` | Module to build/run (auto-detected if only one entry module) |
| `--device <name\|serial>` | Target device (optional; required if multiple devices) |
| `--product <name>` | Product name (default: `default`) |
| `--build-mode debug\|release` | Build mode (default: `debug`) |
| `--skip-build` | Deploy existing artifacts without rebuilding |
| `--uninstall` | Uninstall the app before deploying |
| `--ability <name>` | Ability to launch (default: `EntryAbility`) |

### Build Output

```
entry/build/default/outputs/default/entry-default-unsigned.hap
```

### Build-Only Fallback (hvigorw)

When `devecocli build` is needed but broken, use the raw hvigor wrapper:

```bash
rm -rf .hvigor
node "$(find /Applications -maxdepth 2 -name 'DevEco*Studio*.app' -type d 2>/dev/null | head -1)/Contents/tools/hvigor/bin/hvigorw.js" assembleHap --no-daemon
```

Or if `HVIGOR_HOME` is set in the environment:

```bash
rm -rf .hvigor && node $HVIGOR_HOME/bin/hvigorw.js assembleHap --no-daemon
```

## Project Scaffolding

```bash
devecocli create --app-name MyApp --bundle-name com.example.myapp --api-level 23
```

| Parameter | Constraints |
|---|---|
| `--app-name` | 1-200 chars, starts with letter, letters/digits/underscores only |
| `--bundle-name` | 7-128 chars, >=3 dot-separated segments; defaults to `com.example.<appname>` |
| `--api-level` | >= 17, max auto-detected from SDK, defaults to 23 |
| `--project-path` | Optional; defaults to `./<app-name>` |

## Emulator Management

All emulator operations go through devecocli:

| Command | Purpose |
|---|---|
| `devecocli emulator list` | List available emulators |
| `devecocli device list` | List connected devices / running emulators |
| `devecocli emulator license accept` | Accept license (required once before starting) |
| `devecocli emulator start <name>` | Start an emulator by name |
| `devecocli emulator stop <name>` | Stop an emulator (accepts name or serial like `127.0.0.1:5555`) |
| `devecocli emulator create <name> --device-type phone --os-version "..."` | Create a new emulator |
| `devecocli emulator image list` | List downloaded system images |
| `devecocli emulator image download --device-type phone --os-version "..." --force` | Download a system image |

> **Critical**: The emulator `os-version` MUST match the `compatibleSdkVersion` in `build-profile.json5` (e.g., both should be `"5.0.0(12)"`).

## Logging & Debugging

| Command | Purpose |
|---|---|
| `devecocli log --level E --tail 20` | Show last 20 error-level log lines |
| `devecocli log --follow --bundle-name com.example.app` | Follow real-time logs for a specific app |
| `devecocli log --crash --bundle-name com.example.app` | Show crash logs for a specific app |
| `devecocli log --from 5m --to 1m` | Logs in a time window (units: `s`/`m`/`h`) |
| `devecocli log --keyword Init` | Filter logs containing a keyword |

### Log Levels

| Level | Meaning |
|---|---|
| `D` | Debug |
| `I` | Info |
| `W` | Warn |
| `E` | Error |
| `F` | Fatal |

## Static Checking (deveco-mcp)

The MCP server provides the `check` tool for static syntax checking:

- **Tool**: `mcp__deveco-mcp__check` — accepts `files: string[]`, auto-detects the checker by file extension
- **Supported**: `.ets` (ArkTS) and C/C++ files

If the MCP server is not configured:

```bash
devecocli init --mcp
```

## Documentation (via devecocli)

Prefer `devecocli docs` over web search for HarmonyOS API docs — it is offline and always in sync with the installed SDK version.

| Command | Purpose |
|---|---|
| `devecocli docs search <keywords...>` | Search documentation |
| `devecocli docs read <documentId>` | Read a document by ID |
| `devecocli docs catalog` | List available documentation catalogs |
| `devecocli docs search ... --format json` | Output search results as JSON |
| `devecocli docs search ... --limit <n>` | Limit number of results |
| `devecocli docs search ... --catalog <name>` | Search within a specific catalog |

## Official Skills

devecocli provides 41 official skills. When relevant to the user's task, suggest installing them:

| Skill | Purpose |
|---|---|
| `hmos-arkts-syntax-checker` | ArkTS syntax checking |
| `hmos-arkui-develop-skill` | ArkUI component development |
| `deveco-studio-hilog` | Advanced log analysis |
| `deveco-studio-hvigor` | Build troubleshooting |
| `deveco-studio-emulator` | Emulator management |
| `hmos-arkui-mvvm-pattern` | MVVM architecture patterns |

Install with:

```bash
devecocli skills add --skill <name>
```

## Project Anatomy

For a detailed walkthrough of the HarmonyOS project directory structure, see [`references/project-structure.md`](references/project-structure.md).
