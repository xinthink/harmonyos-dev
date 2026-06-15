# HarmonyOS Project Anatomy

```
HelloWorld/                        ← project root (contains build-profile.json5 with "app")
├── build-profile.json5           ← root build config: compatibleSdkVersion, runtimeOS, modules, signing
├── hvigorfile.ts                 ← root hvigor tasks (imports appTasks from @ohos/hvigor-ohos-plugin)
├── oh-package.json5              ← root package manifest (dependencies on @ohos/ and @kit.*)
├── hvigor/
│   └── hvigor-config.json5       ← hvigor engine config (modelVersion must match SDK)
├── AppScope/
│   └── app.json5                 ← app manifest (bundleName, version, icon, label)
└── entry/                        ← HAP module (one app = one or more HAPs)
    ├── build-profile.json5       ← module build targets (runtimeOS: "HarmonyOS")
    ├── hvigorfile.ts             ← module hvigor tasks (imports hapTasks)
    ├── oh-package.json5          ← module dependencies
    └── src/main/
        ├── ets/
        │   ├── entryability/
        │   │   └── EntryAbility.ets   ← UIAbility — app lifecycle entry point
        │   └── pages/
        │       └── Index.ets          ← @Entry @Component main page
        ├── resources/                ← string, color, media resources
        └── module.json5              ← module manifest (abilities, skills, permissions)
```

## Key Concepts

### `compatibleSdkVersion`

Format: `"5.0.0(12)"` — version number followed by API level in parentheses. This MUST match the emulator image's `os-version`. Mismatched versions cause deploy failures.

### `runtimeOS`

- `"HarmonyOS"` — full HarmonyOS NEXT (production devices)
- `"OpenHarmony"` — OpenHarmony baseline

### `hvigorfile.ts`

- **Root level**: imports `appTasks` from `@ohos/hvigor-ohos-plugin` — orchestrates all modules
- **Module level**: imports `hapTasks` — builds the HAP artifact
- **Cangjie projects**: use `@ohos/cangjie-build-support` plugin instead

### `oh-package.json5`

Dependencies prefixed with `@ohos/` and `@kit.` resolve through the local SDK, not a remote registry. This is equivalent to the SDK's bundled libraries.

### `hvigor-config.json5`

```json5
{
  modelVersion: "5.0.0",
  daemon: false
}
```

- `modelVersion` must match the SDK generation (found in `$DEVECO_SDK_HOME/default/openharmony/ets/build-tools/hvigor`)
- `daemon: false` is recommended for headless or CI builds; `true` (default) caches build state but can become poisoned — if builds fail mysteriously, `rm -rf .hvigor` to clear it

## Multi-Module Projects

For projects with multiple HAP/HSP modules:

```
MyApp/
├── build-profile.json5       ← modules array lists all sub-modules
├── entry/                    ← main HAP (entry module)
├── feature/                  ← additional HAP
└── library/                  ← HSP (HarmonyOS Shared Package)
```

Each module gets its own `build-profile.json5`, `hvigorfile.ts`, and `oh-package.json5`. The root `build-profile.json5` declares them in its `modules` array.
