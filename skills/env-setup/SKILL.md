---
name: env-setup
description: This skill should be used when setting up the HarmonyOS development environment, installing or verifying the DevEco CLI toolchain, configuring Cangjie SDK, or when a dev skill reports missing prerequisites. Covers first-time setup and incremental reconfiguration.
---

# HarmonyOS Environment Setup

## Overview

This skill handles one-time HarmonyOS environment setup. It discovers installed tools, writes configuration to `~/.harmonyosdev/config.json`, and verifies the toolchain works. All Cangjie SDK paths are read from the config file after setup. The conventional default install location is `~/.harmonyosdev/sdk/cangjie/`.

`~/.harmonyosdev/` is the single root for all HarmonyOS-related local state. This skill does **not** modify `~/.zshrc` -- DevEco CLI auto-resolves everything through DevEco Studio's ToolProvider, and Cangjie environment variables are sourced per-invocation via the bundled `envsetup.sh`.

Running this skill is idempotent: running it again with existing config preserves current settings (incremental reconfiguration).

## Prerequisites

These must exist before this skill can complete setup:

1. **Node.js >= 18** -- required to install and run `devecocli`. Check with `node --version`.

2. **DevEco Studio >= 6.1.0** -- must be installed in `/Applications/DevEco Studio.app` or `~/Applications/DevEco Studio.app` on macOS. On Windows, found via Windows registry or `C:\Program Files\Huawei\DevEco Studio`. The `devecocli` npm package auto-discovers DevEco Studio through its ToolProvider, which also resolves Node.js, ohpm, hvigor, Java, SDK, HDC, and Emulator -- no separate CLI tool installs or env vars are needed.

3. **Cangjie SDK** (optional) -- only required for native Cangjie modules, not for pure ArkTS HarmonyOS apps. The user is asked during setup whether they need it.

## Setup Flow

### Step 1: Verify Node.js

```bash
node --version
```

Must be >= 18. If not met, instruct the user to install Node.js >= 18 (via `nvm`, `nodenv`, or direct download).

### Step 2: Verify DevEco CLI

```bash
devecocli --version
```

This implicitly verifies that DevEco Studio is found by ToolProvider. If `devecocli` is not found:

```bash
npm install -g @deveco/deveco-cli
```

If using `nodenv`, also run `nodenv rehash` after installation. Then verify again with `devecocli --version`.

If `devecocli --version` succeeds but reports an error about DevEco Studio not being found, instruct the user to install DevEco Studio >= 6.1.0 in `/Applications` on macOS.

### Step 3: Ask About Cangjie

Ask the user:

> Do you need Cangjie support? (Only required for native modules, not pure ArkTS apps.)

- **No** (or skip) -- Cangjie is not configured. `cangjie.enabled` remains `false` in config.
- **Yes** -- proceed to Step 4.

### Step 4: Set Up Cangjie SDK

If the user opted in, discover the Cangjie SDK. Check these locations in order:

1. `~/.harmonyosdev/config.json` — check if `cangjie.home` is already configured from a previous setup
2. `~/.harmonyosdev/sdk/cangjie/` — the conventional default location
3. Ask the user where their Cangjie SDK is installed

The config file is the source of truth — if `cangjie.home` is set and the path exists, use it directly.

For each candidate, look for `./bin/cjc` (the Cangjie compiler). Verify with:

```bash
<path>/bin/cjc --version
```

If found, source the bundled environment setup script:

```bash
source <skill_dir>/scripts/envsetup.sh
```

This sets `CANGJIE_HOME`, `DEVECO_SDK_HOME`, `PATH`, `LD_LIBRARY_PATH`, `SDKROOT`, and `OHOS_SDK_NATIVE_HOME`. It replaces the SDK's broken `envsetup.sh` which fails on macOS login shells due to a `ps` detection bug.

If Cangjie SDK is **not found** anywhere, instruct the user:

> Cangjie SDK not found. Please download it:
> 1. Go to https://cangjie-lang.cn/download
> 2. Download the **macOS arm64** package -- choose the **plain desktop** version (no ohos/ios/android suffix)
> 3. Extract the tarball. It creates a top-level `cangjie/` directory.
> 4. Move the contents into your Cangjie SDK directory. The convention is `~/.harmonyosdev/sdk/cangjie/` (this is the default that the config file falls back to), but you can install anywhere — the config file records the actual path:
>    ```bash
>    mkdir -p ~/.harmonyosdev/sdk/cangjie
>    # If the tarball creates a cangjie/ directory:
>    tar -xzf <downloaded>.tar.gz
>    mv cangjie/* ~/.harmonyosdev/sdk/cangjie/
>    ```
> 5. Remove macOS quarantine xattr:
>    ```bash
>    xattr -r -d com.apple.quarantine ~/.harmonyosdev/sdk/cangjie/
>    ```

Once installed, re-run this setup to detect and configure it.

### Step 5: Ask for Default Emulator Name

Ask the user:

> Do you have a default emulator name you'd like to save? (Optional -- you can skip this.)

- If provided, store it as `emulator.defaultName`. DevEco CLI emulator commands will use this as a fallback.
- If skipped, `emulator.defaultName` remains `null`. The user can always pass `--device` explicitly to `devecocli` commands.

### Step 6: Write Config File

Write `~/.harmonyosdev/config.json` using the schema defined below. Create the `~/.harmonyosdev/` directory if it does not already exist.

### Step 7: Write Claude Memory

Write a Claude memory fact recording that the HarmonyOS dev environment config exists at `~/.harmonyosdev/config.json`. Use the command:

```
user: please remember: HarmonyOS dev environment configured at ~/.harmonyosdev/config.json
```

This helps Claude recall the setup across sessions.

## Config File Schema

Path: `~/.harmonyosdev/config.json`

```json
{
  "version": "1",
  "cangjie": {
    "enabled": false
  },
  "emulator": {
    "defaultName": null
  },
  "devecoMCP": {
    "enabled": false
  }
}
```

### Fields

| Field | Type | Description |
|---|---|---|
| `version` | string | Schema version. Currently `"1"`. |
| `cangjie.enabled` | boolean | Whether Cangjie SDK support is configured. |
| `cangjie.home` | string | **(Only when enabled)** Absolute path to the Cangjie SDK root (the directory containing `bin/cjc`). |
| `emulator.defaultName` | string or null | Default emulator name for `devecocli emulator` commands. `null` if not set. |
| `devecoMCP.enabled` | boolean | Whether `deveco-mcp` MCP server is enabled. Defaults to `false`. |

### Example: With Cangjie

```json
{
  "version": "1",
  "cangjie": {
    "enabled": true,
    "home": "/Users/<user>/.harmonyosdev/sdk/cangjie"
  },
  "emulator": {
    "defaultName": "Pura 90"
  },
  "devecoMCP": {
    "enabled": false
  }
}
```

### Example: Without Cangjie

```json
{
  "version": "1",
  "cangjie": {
    "enabled": false
  },
  "emulator": {
    "defaultName": null
  },
  "devecoMCP": {
    "enabled": false
  }
}
```

## Incremental Reconfiguration

Running env-setup when `~/.harmonyosdev/config.json` already exists is an **incremental reconfiguration**:

1. Read the existing config first.
2. Preserve all existing settings (emulator name, devecoMCP status, etc.).
3. If the user previously skipped Cangjie and now answers "yes", add the Cangjie section with the discovered `cangjie.home` path and set `cangjie.enabled` to `true`.
4. If the user previously had Cangjie and answers "no", keep the Cangjie section but set `cangjie.enabled` to `false` (the user may re-enable later without re-discovering paths).
5. Re-write the config with merged settings.
6. Re-write the Claude memory fact.

## Important Notes

- **Single root**: `~/.harmonyosdev/` is the single root for all HarmonyOS-related local state -- SDKs, config, cached data. Nothing is scattered across the filesystem.
- **No .zshrc modification**: This skill does **not** write to `~/.zshrc`. DevEco CLI auto-resolves everything through DevEco Studio's ToolProvider. For Cangjie, environment variables are sourced per-invocation via the bundled `envsetup.sh` script in this skill's `scripts/` directory.
- **ToolProvider auto-resolution**: DevEco Studio's ToolProvider automatically discovers Node.js, ohpm, hvigor, Java, HarmonyOS SDK, HDC, and Emulator paths. No separate tool installs or environment variable exports are needed for the core DevEco toolchain.
- **Windows support**: On Windows, DevEco Studio is found via the Windows registry or at `C:\Program Files\Huawei\DevEco Studio`. Adjust Cangjie paths accordingly (`%USERPROFILE%\.harmonyosdev\sdk\cangjie\`).
- **Bundled scripts**: This skill may include a `scripts/` directory. `scripts/envsetup.sh` provides Cangjie environment setup that replaces the SDK's broken `envsetup.sh`.

## Troubleshooting

### "devecocli not found"

The npm package is not installed globally. Install it:

```bash
npm install -g @deveco/deveco-cli
```

If using a Node.js version manager (nodenv, nvm), rehash after:

```bash
nodenv rehash   # or: nvm reinstall-packages
```

Run `devecocli --version` to verify.

### "DevEco Studio not found"

DevEco Studio >= 6.1.0 must be installed on macOS at `/Applications/DevEco Studio.app` or `~/Applications/DevEco Studio.app`. Download from the official HarmonyOS developer site. On Windows, install to the default `C:\Program Files\Huawei\DevEco Studio` location so `devecocli` can discover it via the registry.

### "cjc not found"

Cangjie SDK is not installed or not at the configured path. Check the config file first:

```bash
# Read cangjie.home from config, falling back to the conventional default
CJ_HOME=$(jq -r '.cangjie.home // "~/.harmonyosdev/sdk/cangjie"' ~/.harmonyosdev/config.json | sed "s|^~|$HOME|")
ls "$CJ_HOME/bin/cjc"
```

If the path is wrong or missing, update `cangjie.home` in `~/.harmonyosdev/config.json` or re-run the env-setup skill.

If the config has no Cangjie section at all, download the Cangjie SDK from https://cangjie-lang.cn/download and extract to `~/.harmonyosdev/sdk/cangjie/` (or any path you prefer).

### "SDKROOT not set"

Cangjie native compilation requires the macOS SDK. The bundled `envsetup.sh` attempts to auto-detect `SDKROOT` from Xcode or Command Line Tools. If it fails:

1. Ensure Xcode or Command Line Tools are installed:
   ```bash
   xcode-select --install
   ```
2. Verify SDKROOT is set:
   ```bash
   xcrun --sdk macosx --show-sdk-path
   ```

### macOS 26.x + Cangjie <= 0.56.4 Linker Crash

Cangjie SDK versions <= 0.56.4 have a known linker crash on macOS 26.x+ due to a malformed `libSystem.tbd`. This is fixed in Cangjie 1.x. If you encounter a linker crash, upgrade to Cangjie 1.x from https://cangjie-lang.cn/download.

### "Invalid value of DEVECO_SDK_HOME"

This occurs when running Cangjie builds without sourcing the environment setup. Always source the bundled `envsetup.sh` before Cangjie commands:

```bash
source <path_to_skill>/scripts/envsetup.sh
```
