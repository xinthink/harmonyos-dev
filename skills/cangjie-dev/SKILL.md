---
name: cangjie-dev
description: This skill should be used when developing with Cangjie language — compiling .cj files, using cjpm, cjc, cjfmt, cjlint, setting up Cangjie LSP, cross-compiling to HarmonyOS native modules, or troubleshooting Cangjie build issues. Activates on keywords: Cangjie, .cj, cjpm, cjc, cjfmt, cjlint, cangjie, native module, LSPServer, cross-compile.
---

# Cangjie Development Skill

## Overview

This skill teaches Claude how to develop Cangjie programs — both desktop/macOS native executables and HarmonyOS native modules. Cangjie is Huawei's systems programming language with its own toolchain (`cjpm`, `cjc`) independent of `devecocli`.

## Prerequisites

Check these before doing anything:

1. `~/.harmonyosdev/config.json` must have `cangjie.enabled: true`.

   > If the config file or `cangjie.enabled` key is missing: "Cangjie is not configured. Run the env-setup skill and opt into Cangjie support."

2. `cjc --version` must succeed after sourcing `envsetup.sh`.

   > If the config exists but `cjc` fails: "Cangjie SDK not found. Check the `cangjie.home` path in `~/.harmonyosdev/config.json` or re-run the env-setup skill."

## Environment Setup

Do this before running any Cangjie command:

```bash
# Read cangjie.home from config, fall back to conventional default
export CANGJIE_HOME=$(jq -r '.cangjie.home // empty' ~/.harmonyosdev/config.json)
if [ -z "$CANGJIE_HOME" ]; then
  export CANGJIE_HOME="$HOME/.harmonyosdev/sdk/cangjie"
fi

# Source the bundled envsetup.sh (this repo's skill-provided version):
source <repo-root>/skills/env-setup/scripts/envsetup.sh
```

Our `envsetup.sh` sets:

| Variable | Value |
|---|---|
| `PATH` | `cangjie/bin`, `cangjie/tools/bin`, `~/.cjpm/bin` prepended |
| `DYLD_LIBRARY_PATH` | `cangjie/runtime` libs (see note below) |
| `SDKROOT` | macOS SDK path (needed for native compilation) |

**Why our script**: The Cangjie SDK's own `envsetup.sh` has a bug on macOS login shells — it mis-detects `-/bin/zsh` (the login-shell prefix) and refuses to set the environment. Our script at `skills/env-setup/scripts/envsetup.sh` skips shell detection entirely and always works.

**Runtime lib dir compatibility**: 0.5x SDKs use `runtime/lib/darwin_aarch64_llvm`, while 1.x SDKs use `runtime/lib/darwin_aarch64_cjnative`. Our `envsetup.sh` uses a glob to stay compatible with both.

## Build and Run (Desktop Native Target)

Commands for the standard desktop executable workflow:

| Command | Purpose |
|---|---|
| `cjpm build` | Compile `.cj` sources to `target/release/bin/<name>` |
| `cjpm run` | Build and execute the binary |
| `cjpm test` | Run tests (requires `--test` compile option) |
| `cjpm clean` | Remove `target/` directory |
| `cjpm init` | Scaffold a new `cjpm.toml` project |

## Package Management

- `cjpm add <package>` — add a dependency
- `cjpm update` — update all dependencies
- `cjpm install` — install a package from the registry
- `cjpm.lock` — lockfile (equivalent to Cargo.lock)

**`cjpm.toml` key fields:**

| Field | Description |
|---|---|
| `cjc-version` | Required SDK version (e.g., `"1.1.3"`) |
| `output-type` | `"executable"` (desktop binary), `"static"` (`.a`), or `"dynamic"` (`.so`/`.dylib`) |
| `compile-option` | Additional compiler flags passed to `cjc` |
| `link-option` | Additional linker flags |
| `package-configuration` | Per-package build config overrides |

## Compiler (`cjc`) Flags

Important flags for the Cangjie compiler:

| Flag | Purpose |
|---|---|
| `--test` | Compile in test mode |
| `--output-type obj\|lib\|executable` | Override `cjpm.toml` output type |
| `--compile-target <target>` | Cross-compile target (e.g., `ohos-arm64`) |
| `--import-path <path>` | Add `.cjo` search path |
| `--static` | Link statically (executables only) |
| `--dy-std` | Link stdlib dynamically (mutually exclusive with `--static`) |
| `--no-prelude` | Don't auto-import `std/core` (advanced) |
| `--pgo-instr-gen=<path>` | PGO instrumentation (ohos targets only) |
| `--experimental` | Enable experimental features |

## Toolchain Tools

| Tool | Function |
|---|---|
| `cjfmt` | Code formatter (format `.cj` files) |
| `cjlint` | Linter (static analysis) |
| `cjdb` | Debugger (symlink to `lldb` with Cangjie extensions) |
| `cjcov` | Code coverage |
| `cjprof` | Profiling |
| `cjtrace-recover` | Trace recovery |
| `chir-dis` | CHIR (Cangjie IR) disassembly |

## Cross-compiling to HarmonyOS (ohos Target)

To build a Cangjie native module for a HarmonyOS app:

1. **SDK requirement**: Must use the HarmonyOS-targeted Cangjie SDK bundled with the DevEco Studio Cangjie plugin. The desktop SDK from `cangjie-lang.cn` does not include ohos targets.

2. **In `hvigorfile.ts`**: Use `@ohos/cangjie-build-support` instead of the standard `hapTasks`:

   ```ts
   import { cangjieTasks } from '@ohos/cangjie-build-support';
   export default cangjieTasks;
   ```

3. **In `cjpm.toml`**: Set `output-type = "static"` or `"dynamic"` depending on module type.

4. **Compile target**: Pass `--compile-target ohos-arm64` (or let the build-support plugin handle it).

5. **NAPI interop**: Cangjie modules communicate with ArkTS via NAPI native interfaces. See `references/mixed-dev.md` for details.

## LSP Setup

The Cangjie SDK ships a full LSP server. For Claude Code integration:

- **LSPServer binary**: `<cangjie.home>/tools/bin/LSPServer` (24 MB native arm64)
- **LSP library**: `<cangjie.home>/tools/lib/libcangjie-lsp.dylib` (135 MB)
- **Config**: The `.lsp.json` file at the plugin root declares the Cangjie LSP server to Claude Code
- **Path resolution**: `cangjie.home` from `~/.harmonyosdev/config.json` is used in `.lsp.json`

Confirmed capabilities: go-to-definition, find-references, hover, document/workspace symbols, completion, semantic tokens, call hierarchy, type hierarchy, rename, signature help, code lens, diagnostics, and more.

For detailed setup instructions, see `references/lsp-setup.md`.

## Known Issues

1. **macOS login shell bug**: SDK's `envsetup.sh` rejects `-/bin/zsh` — use this repo's bundled `envsetup.sh` instead.
2. **macOS 26.x + Cangjie <= 0.56.4**: Linker crashes on `libSystem.tbd` — upgrade to Cangjie 1.x.
3. **SDKROOT required**: Must be set for native desktop compilation. Our `envsetup.sh` handles this automatically via `xcrun`.
4. **DYLD_LIBRARY_PATH**: Runtime libs must be on the library path, or you'll get "image not found" errors at link and runtime.
5. **xattr quarantine**: Fresh Cangjie SDK downloads from the web need `xattr -dr com.apple.quarantine <sdk-dir>` before binaries will execute.
6. **Runtime lib dir change**: 0.5x SDKs use `runtime/lib/darwin_aarch64_llvm`; 1.x SDKs use `runtime/lib/darwin_aarch64_cjnative`. Our `envsetup.sh` globs to stay compatible.
