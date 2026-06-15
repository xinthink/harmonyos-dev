# Cangjie LSP — Claude Code Integration Guide

## Capabilities

The Cangjie LSPServer (`<cangjie.home>/tools/bin/LSPServer`, 24 MB, arm64) provides full LSP over stdio. It loads `libcangjie-lsp.dylib` (135 MB). Server info: `Cangjie language server v1.0`.

All major LSP features are supported: definition, references, hover, document/workspace symbols, completion (`.` and `` ` `` triggers), semantic tokens (full+delta), call hierarchy, type hierarchy, rename, signature help (`(` and `,` triggers), document links, code lens, document highlight, breakpoints, and incremental diagnostics.

## Environment Setup

Before the server can start, verify the SDK is intact:

```bash
export CANGJIE_HOME=$(jq -r '.cangjie.home' ~/.harmonyosdev/config.json)
ls "$CANGJIE_HOME/tools/bin/LSPServer"              # Must exist (24 MB)
ls "$CANGJIE_HOME/tools/lib/libcangjie-lsp.dylib"   # Must exist (135 MB)
export DYLD_LIBRARY_PATH="$CANGJIE_HOME/tools/lib:$CANGJIE_HOME/lib"
```

## `.lsp.json` Configuration

```json
{
  "cangjie": {
    "command": "<cangjie.home>/tools/bin/LSPServer",
    "extensionToLanguage": { ".cj": "cangjie" },
    "env": {
      "CANGJIE_HOME": "<cangjie.home>",
      "DYLD_LIBRARY_PATH": "<cangjie.home>/tools/lib:<cangjie.home>/lib"
    },
    "transport": "stdio",
    "startupTimeout": 10000,
    "maxRestarts": 3
  }
}
```

- `command`: Absolute path. No `args` needed — LSPServer uses stdio by default.
- `extensionToLanguage`: Maps `.cj` to `"cangjie"` (language ID in `textDocument/didOpen`).
- `env`: Required. Without `CANGJIE_HOME` and `DYLD_LIBRARY_PATH`, the dylib won't load.
- `startupTimeout: 10000` — generous window for the binary+dylib to initialize.
- `maxRestarts: 3` — Claude Code auto-restarts on crash.

A companion `plugin.json`:

```json
{
  "name": "cangjie-lsp",
  "version": "1.0.0",
  "description": "Cangjie language server for .cj files",
  "author": { "name": "Local" },
  "license": "MIT",
  "keywords": ["cangjie", "language-server", "harmonyos", "lsp"]
}
```

Register in `~/.claude/plugins/installed_plugins.json` (add `cangjie-lsp@local`) and enable in `~/.claude/settings.json` under `enabledPlugins`.

## Verification

After restarting Claude Code:

1. Open a `.cj` file (e.g., `samples/CangjieHello/src/main.cj`).
2. `LSP` with `operation: "documentSymbol"` → returns `main` function.
3. `LSP` with `operation: "hover"` on `println` → shows `std/core` signature.
4. `LSP` with `operation: "workspaceSymbol"`, `query: "main"` → finds the symbol.
5. Diagnostics appear automatically after edits.

## Troubleshooting

### dyld crash: `@rpath/libcangjie-lsp.dylib` not found

`DYLD_LIBRARY_PATH` in `.lsp.json` env is missing or wrong. The dylib is at `<cangjie.home>/tools/lib/`.

### Server timeout / won't start

```bash
echo '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"processId":null}}' \
  | "$CANGJIE_HOME/tools/bin/LSPServer" 2>/dev/null | head -c 500
```

Should return JSON-RPC with `"Cangjie language server"`.

### Binary exits immediately

- **Quarantine**: `xattr -dr com.apple.quarantine "$CANGJIE_HOME"` (fresh web downloads).
- **Arch mismatch**: arm64 SDK on Apple Silicon, x86_64 on Intel.
- **Deps**: `otool -L "$CANGJIE_HOME/tools/bin/LSPServer"` to check dylib resolution.

### Fallback: Shell wrapper

If `.lsp.json` env doesn't resolve everything, point `command` at a wrapper:

```bash
#!/bin/bash
export CANGJIE_HOME=$(jq -r '.cangjie.home' ~/.harmonyosdev/config.json)
export DYLD_LIBRARY_PATH="$CANGJIE_HOME/tools/lib:$CANGJIE_HOME/lib"
exec "$CANGJIE_HOME/tools/bin/LSPServer" "$@"
```
