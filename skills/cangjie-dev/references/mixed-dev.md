# ArkTS + Cangjie Mixed Development

## Concept

A HarmonyOS app can call into Cangjie native modules through **NAPI** (Native API). The ArkTS/ArkUI layer handles UI and application lifecycle, while Cangjie modules provide performance-critical or systems-level logic (computation, drivers, platform services).

The interop path is:

```
ArkTS (.ets) → NAPI bridge → Cangjie native (.cj) → HarmonyOS system libs
```

## SDK Distinction

There are two distinct Cangjie SDK distributions:

| SDK | Source | Target | Output |
|---|---|---|---|
| **Desktop SDK** | `cangjie-lang.cn` / Cangjie Lang website | macOS, Linux desktop | `executable`, `dylib` |
| **HarmonyOS SDK** | Bundled with DevEco Studio Cangjie plugin | `ohos-arm64`, other ohos targets | `static`, `dynamic` |

**The HarmonyOS-targeted SDK is required for mixed development.** It includes cross-compilation targets (`ohos-arm64`, etc.) and the NAPI runtime headers. The desktop SDK cannot produce HarmonyOS native modules.

## Project Layout

A typical mixed-development module looks like:

```
entry/
├── src/
│   ├── main/
│   │   ├── ets/                  # ArkTS source
│   │   │   └── pages/Index.ets
│   │   ├── cj/                   # Cangjie native source
│   │   │   ├── cjpm.toml         # output-type = "static" or "dynamic"
│   │   │   ├── src/
│   │   │   │   └── native.cj     # NAPI-exported functions
│   │   │   └── target/
│   │   └── module.json5          # Module manifest
├── hvigorfile.ts                 # Uses @ohos/cangjie-build-support
└── build-profile.json5
```

## Build System Integration

In the module's `hvigorfile.ts`, replace the standard `hapTasks` with the Cangjie build support:

```ts
// Standard ArkTS-only module:
// import { hapTasks } from '@ohos/hvigor-ohos-plugin';

// Mixed ArkTS + Cangjie module:
import { cangjieTasks } from '@ohos/cangjie-build-support';
export default cangjieTasks;
```

The `@ohos/cangjie-build-support` plugin:
- Invokes `cjpm build` for the Cangjie sources with `--compile-target ohos-arm64`
- Produces a `.so` (dynamic) or `.a` (static) library
- Packages the native library into the final HAP

## NAPI Interop

Cangjie functions intended for ArkTS callers are annotated with NAPI export macros. The exact Cangjie NAPI API depends on the SDK version — refer to the DevEco Studio Cangjie plugin documentation.

A simplified conceptual pattern:

1. **Cangjie side**: Implement functions that follow the NAPI calling convention and register them with the module.
2. **ArkTS side**: Import the native module via `import native from 'lib<module>.so'` and call exported functions directly.

## Cross-compilation

The key build flag is:

```bash
cjpm build -- --compile-target ohos-arm64
```

This tells `cjc` to target HarmonyOS ABI instead of the host platform. The resulting binary runs on HarmonyOS devices and emulators (arm64 architecture), not on the development macOS machine.

## Key Differences from Desktop Cangjie

| Aspect | Desktop | HarmonyOS (ohos) |
|---|---|---|
| Target triple | `aarch64-apple-darwin` | `aarch64-ohos` |
| Output type | `executable` | `static` or `dynamic` |
| stdlib | Desktop Cangjie std | HarmonyOS Cangjie std |
| Runtime | macOS Cangjie runtime | ArkTS/Cangjie hybrid runtime |
| Debugging | `cjdb` (lldb wrapper) | DevEco debugger |
| Profiling / PGO | Standard tools | `--pgo-instr-gen` for ohos targets |
