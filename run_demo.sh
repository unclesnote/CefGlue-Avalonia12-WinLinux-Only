#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

UNAME_S="$(uname -s)"
case "$UNAME_S" in
    Linux*)
        OS_TYPE="linux"
        EXE_NAME="Xilium.CefGlue.Demo.Avalonia"
        ;;
    MINGW*|MSYS*|CYGWIN*)
        OS_TYPE="win"
        EXE_NAME="Xilium.CefGlue.Demo.Avalonia.exe"
        ;;
    *)
        echo "Unsupported OS: $UNAME_S (this fork supports Avalonia on Windows and Linux only)" >&2
        exit 1
        ;;
esac

UNAME_M="$(uname -m)"
case "$UNAME_M" in
    x86_64|amd64|AMD64)
        PLATFORM="x64"
        ARCH_RID="x64"
        ;;
    *)
        echo "Unsupported architecture: $UNAME_M (this fork supports x64 only)" >&2
        exit 1
        ;;
esac

CONFIGURATION="${CONFIGURATION:-Debug}"
TFM="$(sed -n 's:.*<DotnetVersion>\(.*\)</DotnetVersion>.*:\1:p' "$ROOT_DIR/Directory.Build.props" | head -n 1 | tr -d '\r[:space:]')"
TFM="${TFM:-net10.0}"

DEMO_PROJECT="$ROOT_DIR/CefGlue.Demo.Avalonia/CefGlue.Demo.Avalonia.csproj"
OUT_DIR="$ROOT_DIR/CefGlue.Demo.Avalonia/bin/$PLATFORM/$CONFIGURATION/$TFM"
DEMO_BIN="$OUT_DIR/$EXE_NAME"
SUBPROCESS_DIR="$OUT_DIR/CefGlueBrowserProcess"

PROJECTS=(
    "$ROOT_DIR/CefGlue/CefGlue.csproj"
    "$ROOT_DIR/CefGlue.Common.Shared/CefGlue.Common.Shared.csproj"
    "$ROOT_DIR/CefGlue.BrowserProcess/CefGlue.BrowserProcess.csproj"
    "$ROOT_DIR/CefGlue.Common/CefGlue.Common.csproj"
    "$ROOT_DIR/CefGlue.Avalonia/CefGlue.Avalonia.csproj"
    "$DEMO_PROJECT"
    "$ROOT_DIR/CefGlue.Tests/CefGlue.Tests.csproj"
)

echo "Target environment: OS=$OS_TYPE, Platform=$PLATFORM, Configuration=$CONFIGURATION, TFM=$TFM"

DO_CLEAN_BUILD=0
if [[ -f "$DEMO_BIN" && -d "$SUBPROCESS_DIR" ]]; then
    echo "Existing build found: $DEMO_BIN"
    read -r -p "Existing build found. Clean and rebuild the entire library? [y/N]: " answer || answer=""
    if [[ "$answer" =~ ^[Yy]$ ]]; then
        DO_CLEAN_BUILD=1
    fi
else
    echo "No existing build found for $OS_TYPE/$PLATFORM ($CONFIGURATION, $TFM)."
    DO_CLEAN_BUILD=1
fi

if [[ "$DO_CLEAN_BUILD" -eq 1 ]]; then
    echo "Cleaning all projects for Platform=$PLATFORM ($CONFIGURATION)..."
    for proj in "${PROJECTS[@]}"; do
        dotnet clean "$proj" -c "$CONFIGURATION" -p:Platform="$PLATFORM"
        proj_dir="$(dirname "$proj")"
        rm -rf "$proj_dir/bin/$PLATFORM/$CONFIGURATION" "$proj_dir/obj/$PLATFORM/$CONFIGURATION"
    done

    echo "Building all projects for Platform=$PLATFORM ($CONFIGURATION)..."
    for proj in "${PROJECTS[@]}"; do
        dotnet build "$proj" -c "$CONFIGURATION" -p:Platform="$PLATFORM"
    done
fi

if [[ ! -f "$DEMO_BIN" ]]; then
    echo "Error: Demo executable not found at $DEMO_BIN" >&2
    exit 1
fi

if [[ "$OS_TYPE" != "win" ]]; then
    chmod +x "$DEMO_BIN"
fi

if [[ -z "${DOTNET_ROOT:-}" ]] && command -v dotnet >/dev/null 2>&1; then
    DOTNET_BIN="$(command -v dotnet)"
    if command -v realpath >/dev/null 2>&1; then
        DOTNET_BIN="$(realpath "$DOTNET_BIN")"
    elif readlink -f "$DOTNET_BIN" >/dev/null 2>&1; then
        DOTNET_BIN="$(readlink -f "$DOTNET_BIN")"
    fi
    export DOTNET_ROOT="$(dirname "$DOTNET_BIN")"
fi

if [[ "$OS_TYPE" == "linux" ]]; then
    HARFBUZZ_SO="$OUT_DIR/runtimes/linux-${ARCH_RID}/native/libHarfBuzzSharp.so"
    if [[ -f "$HARFBUZZ_SO" ]]; then
        export LD_PRELOAD="${HARFBUZZ_SO}${LD_PRELOAD:+:$LD_PRELOAD}"
    fi
fi

echo "Launching: $DEMO_BIN"
cd "$OUT_DIR"
exec "$DEMO_BIN" "$@"
