#!/usr/bin/env bash
# Builds the CefGlue.Common and CefGlue.Avalonia NuGet packages into Nuget/output.
# The packages contain the Windows and Linux browser process only (see CefGlue.WinLinuxOnly.targets).
#
#   ./publish.sh                      # Release, host architecture
#   CONFIGURATION=Debug ./publish.sh
#   PLATFORM=ARM64 ./publish.sh       # CefGlue.Common.ARM64 / CefGlue.Avalonia.ARM64
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

UNAME_S="$(uname -s)"
case "$UNAME_S" in
    Linux*|MINGW*|MSYS*|CYGWIN*)
        ;;
    *)
        echo "Unsupported OS: $UNAME_S (this fork supports Avalonia on Windows and Linux only)" >&2
        exit 1
        ;;
esac

if [[ -z "${PLATFORM:-}" ]]; then
    UNAME_M="$(uname -m)"
    case "$UNAME_M" in
        x86_64|amd64|AMD64)
            PLATFORM="x64"
            ;;
        aarch64|arm64|ARM64)
            PLATFORM="ARM64"
            ;;
        *)
            echo "Unsupported architecture: $UNAME_M" >&2
            exit 1
            ;;
    esac
fi

case "$PLATFORM" in
    x64) PACKAGE_SUFFIX="" ;;
    ARM64) PACKAGE_SUFFIX=".ARM64" ;;
    *)
        echo "Unsupported PLATFORM: $PLATFORM (expected x64 or ARM64)" >&2
        exit 1
        ;;
esac

CONFIGURATION="${CONFIGURATION:-Release}"
VERSION="$(sed -n 's:.*<Version>\(.*\)</Version>.*:\1:p' "$ROOT_DIR/Directory.Build.props" | head -n 1 | tr -d '\r[:space:]')"
OUTPUT_DIR="$ROOT_DIR/Nuget/output"
PACKAGES=(
    "$OUTPUT_DIR/CefGlue.Common$PACKAGE_SUFFIX.$VERSION.nupkg"
    "$OUTPUT_DIR/CefGlue.Avalonia$PACKAGE_SUFFIX.$VERSION.nupkg"
)

echo "Packing: Platform=$PLATFORM, Configuration=$CONFIGURATION, Version=$VERSION"

# Remove this version's packages first so a failed build can't leave a stale package behind.
rm -f "${PACKAGES[@]}"

# Building CefGlue.Avalonia also builds CefGlue.Common and the browser process; both projects
# generate their package on build. --no-incremental makes sure the browser process is republished.
dotnet build "$ROOT_DIR/CefGlue.Avalonia/CefGlue.Avalonia.csproj" \
    -c "$CONFIGURATION" \
    -p:Platform="$PLATFORM" \
    --no-incremental

for package in "${PACKAGES[@]}"; do
    if [[ ! -f "$package" ]]; then
        echo "Error: package not created: $package" >&2
        exit 1
    fi
done

echo "Packages:"
ls -lh "${PACKAGES[@]}"
