# Cangjie LSP — Claude Code Integration Guide

## Capabilities

The Cangjie LSPServer (`<cangjie.home>/tools/bin/LSPServer`, 24 MB, arm64) provides full LSP over stdio. It loads `libcangjie-lsp.dylib` (135 MB). Server info: `Cangjie language server v1.0`.

All major LSP features are supported: definition, references, hover, document/workspace symbols, completion (`.` and `` ` `` triggers), semantic tokens (full+delta), call hierarchy, type hierarchy, rename, signature help (`(` and `,` triggers), document links, code lens, document highlight, breakpoints, and incremental diagnostics.

## Environment Setup

Before the server can start, verify the SDK is intact:

```bash
# Read cangjie.home from config, fall back to conventional default
export CANGJIE_HOME=$(jq -r '.cangjie.home // empty' ~/.harmonyosdev/config.json)
if [ -z "$CANGJIE_HOME" ]; then
  export CANGJIE_HOME="$HOME/.harmonyosdev/sdk/cangjie"
fi
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

If `.lsp.json` env doesn't resolve everything, or if the Cangjie SDK is at a non-default location, point `command` at a wrapper:

```bash
#!/bin/bash
export CANGJIE_HOME=$(jq -r '.cangjie.home // empty' ~/.harmonyosdev/config.json)
if [ -z "$CANGJIE_HOME" ]; then
  export CANGJIE_HOME="$HOME/.harmonyosdev/sdk/cangjie"
fi
export DYLD_LIBRARY_PATH="$CANGJIE_HOME/tools/lib:$CANGJIE_HOME/lib"
exec "$CANGJIE_HOME/tools/bin/LSPServer" "$@"
```

### Regenerating `.lsp.json` for Non-Default SDK Locations

The shipped `.lsp.json` uses the conventional default path `~/.harmonyosdev/sdk/cangjie/`. If your `cangjie.home` in config points elsewhere, regenerate `.lsp.json` with the actual path:

```bash
CJ_HOME=$(jq -r '.cangjie.home // empty' ~/.harmonyosdev/config.json)
if [ -z "$CJ_HOME" ]; then
  CJ_HOME="$HOME/.harmonyosdev/sdk/cangjie"
fi

cat > .lsp.json << EOF
{
  "cangjie": {
    "command": "$CJ_HOME/tools/bin/LSPServer",
    "extensionToLanguage": {
      ".cj": "cangjie"
    },
    "env": {
      "CANGJIE_HOME": "$CJ_HOME",
      "DYLD_LIBRARY_PATH": "$CJ_HOME/tools/lib:\${DYLD_LIBRARY_PATH}"
    },
    "transport": "stdio",
    "startupTimeout": 10000,
    "maxRestarts": 3
  }
}
EOF
```

Restart Claude Code after regenerating for the LSP server to pick up the new path.
