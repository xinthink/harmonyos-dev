# harmonyos-dev

Claude Code plugin for HarmonyOS NEXT development — environment setup, ArkTS build/deploy/debug, and Cangjie native development with LSP code intelligence.

## Prerequisites

- **Node.js** >= 18
- **DevEco Studio** >= 6.1.0 in `/Applications` or `~/Applications` (macOS) — devecocli auto-discovers it
- **Cangjie SDK** (optional, only needed for native module development)

## Install

```bash
# Install the plugin into Claude Code
claude plugin install harmonyos-dev

# Install DevEco CLI (if not already installed)
npm install -g @deveco/deveco-cli
```

On first use, the `env-setup` skill will guide you through environment setup — discovering tools, configuring Cangjie (optional), and writing `~/.harmonyosdev/config.json`.

## Skills

| Skill | Purpose |
|---|---|
| `env-setup` | One-time environment setup — discovers DevEco Studio, configures Cangjie SDK, writes local config |
| `arkts-dev` | ArkTS app development — build, deploy, debug, emulator, logs, static checking, docs |
| `cangjie-dev` | Cangjie language development — build, run, test, LSP, cross-compile to HarmonyOS |

All tool paths are resolved automatically by devecocli's ToolProvider from DevEco Studio — no environment variables needed.

## Quick Start

```bash
# 1. Create a new project
devecocli create --app-name MyApp
cd MyApp

# 2. Build, deploy, and launch on emulator
devecocli emulator start Phone
devecocli run --module entry --build-mode debug

# 3. View logs
devecocli log --level E --tail 20 --follow
```

## Cangjie Setup (optional)

```bash
# Download Cangjie SDK to ~/.harmonyosdev/sdk/cangjie/ (default; can be customized in config.json)
# Then source the bundled env script before use:
source <plugin-path>/skills/env-setup/scripts/envsetup.sh

# Build and run a Cangjie project
cjpm build
cjpm run
```

For LSP code intelligence on `.cj` files, this plugin ships `.lsp.json` — it will be activated automatically when the plugin is enabled.

## Documentation

devecocli bundles offline HarmonyOS docs:

```bash
devecocli docs search <keywords>
devecocli docs read <documentId>
devecocli docs catalog
```

## Configuration

Environment configuration is stored at `~/.harmonyosdev/config.json`:

```json
{
  "version": "1",
  "cangjie": { "enabled": false },
  "emulator": { "defaultName": null },
  "devecoMCP": { "enabled": false }
}
```

All paths are local to `~/.harmonyosdev/` — no system-wide dotfile modifications.

## License

MIT
