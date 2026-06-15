# HarmonyOS / Cangjie toolchain environment setup (source this file).
#
# Drop-in replacement for the Cangjie SDK's envsetup.sh. The SDK script
# mis-detects the shell — `ps -o comm= $$` returns "-/bin/zsh" on macOS login
# shells (the full path with a leading dash, because login zsh is exec'd with
# `-l`), which its case statement rejects with:
#   [ERROR] Unsupported shell: -/bin/zsh, please switch to bash, sh or zsh.
# and then `return 1`s BEFORE exporting PATH/DYLD_LIBRARY_PATH/SDKROOT.
#
# This version does no shell detection at all, so it can't fail. It is safe to
# source from bash, sh, or zsh. Requires CANGJIE_HOME to already be exported:
#
#   export CANGJIE_HOME=$(jq -r '.cangjie.home // empty' ~/.harmonyosdev/config.json)
#   # Fall back to conventional default if not configured:
#   [ -z "$CANGJIE_HOME" ] && export CANGJIE_HOME="$HOME/.harmonyosdev/sdk/cangjie"
#   source "<path-to-plugin>/skills/env-setup/scripts/envsetup.sh"

# Nothing useful to do without a Cangjie SDK root.
if [ -z "${CANGJIE_HOME:-}" ]; then
  echo "envsetup.sh: CANGJIE_HOME is not set; export it before sourcing." >&2
  return 1 2>/dev/null || exit 1
fi

# --- PATH: Cangjie toolchain + cjpm take precedence over system tools ---
export PATH="$CANGJIE_HOME/bin:$CANGJIE_HOME/tools/bin:$HOME/.cjpm/bin:$PATH"

# --- DYLD_LIBRARY_PATH: Cangjie runtime libs (missing -> "image not found") ---
# Match the SDK's uname -m mapping: arm64 -> aarch64, else x86_64.
hw_arch=$(uname -m)
case "$hw_arch" in
  arm64) hw_arch=aarch64 ;;
  "")    hw_arch=x86_64  ;;
esac
# The runtime lib dir name varies by SDK generation: 0.5x = darwin_aarch64_llvm,
# 1.x = darwin_aarch64_cjnative. Glob to the actual dir so DYLD stays valid
# across versions rather than hardcoding the suffix.
_cj_rtlib=$(ls -d "$CANGJIE_HOME"/runtime/lib/darwin_${hw_arch}_* 2>/dev/null | head -1)
export DYLD_LIBRARY_PATH="${_cj_rtlib:+$_cj_rtlib:}$CANGJIE_HOME/tools/lib${DYLD_LIBRARY_PATH:+:$DYLD_LIBRARY_PATH}"
unset _cj_rtlib hw_arch

# --- SDKROOT: macOS SDK path for the Cangjie native compiler ---
if [ -z "${SDKROOT+x}" ]; then
  export SDKROOT="$(xcrun --sdk macosx --show-sdk-path)"
fi

# NOTE: The SDK's envsetup.sh also runs `xattr -dr com.apple.quarantine` and
# `codesign` on every source. Those are one-time install fixes (already applied
# here); they're omitted because codesign is slow to run on every shell start
# and can prompt the keychain. Re-run them manually once after a fresh SDK
# install if needed (see the Cangjie SDK's own envsetup.sh for reference).
