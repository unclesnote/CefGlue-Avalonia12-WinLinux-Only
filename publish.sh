#!/usr/bin/env bash
# Builds the CefGlue.Common and CefGlue.Avalonia NuGet packages into Nuget/output.
# The packages contain the Windows and Linux x64 browser process only (see CefGlue.WinLinuxOnly.targets);
# ARM64 is not supported by this fork.
#
#   ./publish.sh                      # Release
#   CONFIGURATION=Debug ./publish.sh
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

PLATFORM="x64"

CONFIGURATION="${CONFIGURATION:-Release}"
VERSION="$(sed -n 's:.*<Version>\(.*\)</Version>.*:\1:p' "$ROOT_DIR/Directory.Build.props" | head -n 1 | tr -d '\r[:space:]')"
OUTPUT_DIR="$ROOT_DIR/Nuget/output"
PACKAGES=(
    "$OUTPUT_DIR/CefGlue.Common.$VERSION.nupkg"
    "$OUTPUT_DIR/CefGlue.Avalonia.$VERSION.nupkg"
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
