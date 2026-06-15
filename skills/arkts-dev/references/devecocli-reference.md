# devecocli Command Reference

Quick reference cheat sheet. All commands are invoked as `devecocli <command>`.

## Build & Run

| Command | Description |
|---|---|
| `devecocli run --module <name> [--build-mode debug\|release]` | Build + deploy + launch (preferred over standalone build) |
| `devecocli run --module <name> --skip-build` | Deploy + launch without rebuilding |
| `devecocli run --module <name> --uninstall` | Uninstall app before deploying |
| `devecocli run --module <name> --device <name\|serial>` | Target a specific device |
| `devecocli run --module <name> --product <name>` | Target a specific product (default: `default`) |
| `devecocli run --module <name> --ability <name>` | Launch a specific ability (default: `EntryAbility`) |

> **WARNING**: Do not use `devecocli build` — it crashes in v1.0.0. Use `devecocli run` or the hvigorw fallback.

## Project Management

| Command | Flags / Args |
|---|---|
| `devecocli create --app-name <name>` | `--bundle-name <name>` (default: `com.example.<appname>`) |
| | `--api-level <n>` (>= 17, default: 23) |
| | `--project-path <path>` (default: `./<app-name>`) |
| `devecocli init --mcp` | Initialize MCP server configuration |

## Emulator Management

| Command | Flags / Args |
|---|---|
| `devecocli emulator list` | `--verbose` for extended details |
| `devecocli emulator start <name>` | Name or serial (e.g., `127.0.0.1:5555`) |
| `devecocli emulator stop <name>` | Name or serial |
| `devecocli emulator license accept` | Required once before starting any emulator |
| `devecocli emulator create <name>` | `--device-type phone\|tablet\|tv\|car\|wearable` |
| | `--os-version "HarmonyOS X.X.X(XX)"` (must match compatibleSdkVersion) |
| `devecocli emulator delete <name>` | Remove an emulator |
| `devecocli emulator image list` | List downloaded system images |
| `devecocli emulator image download` | `--device-type phone` |
| | `--os-version "..."` |
| | `--force` (allow re-download) |

## Device Management

| Command | Description |
|---|---|
| `devecocli device list` | List all connected devices and running emulators |
| `devecocli device info [serial]` | Show details for a specific device |

## Logs (hilog)

| Command | Flags / Args |
|---|---|
| `devecocli log` | Dump recent logs |
| `devecocli log --level D\|I\|W\|E\|F` | Filter by log level |
| `devecocli log --tail <n>` | Show last N lines |
| `devecocli log --follow` | Stream logs in real time |
| `devecocli log --bundle-name <name>` | Filter by app bundle |
| `devecocli log --crash` | Show only crash logs |
| `devecocli log --keyword <term>` | Filter by keyword |
| `devecocli log --from <duration> --to <duration>` | Time window (units: `s`, `m`, `h`; e.g., `--from 5m --to 1m`) |
| `devecocli log --format json\|default` | Output format |

## Documentation

| Command | Flags / Args |
|---|---|
| `devecocli docs search <keywords...>` | `--catalog <name>` — restrict to a catalog |
| | `--limit <n>` — max results |
| | `--format json\|default` |
| `devecocli docs read <documentId>` | Open a document by ID |
| `devecocli docs catalog` | List available documentation catalogs |

## Static Checking (MCP)

| Command / Tool | Description |
|---|---|
| `devecocli init --mcp` | Register the MCP server in the environment |
| `mcp__deveco-mcp__check` | Check `.ets` (ArkTS) or C/C++ files for syntax/type errors |
| | Accepts `files: string[]` — extension auto-detects the checker |

## Skills

| Command | Description |
|---|---|
| `devecocli skills list` | List all 41 available official skills |
| `devecocli skills add --skill <name>` | Install an official skill |
| `devecocli skills info --skill <name>` | Show details about a skill |

## Environment & Diagnostics

| Command | Description |
|---|---|
| `devecocli --version` | Print CLI version (also verifies DevEco Studio is found) |
| `devecocli --help` | Show top-level help |
| `devecocli <command> --help` | Show help for a specific command |
