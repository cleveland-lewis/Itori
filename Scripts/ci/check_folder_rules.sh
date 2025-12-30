#!/usr/bin/env bash
set -euo pipefail

root_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

platform_mac="$root_dir/Platforms/macOS"
legacy_mac="$root_dir/_Deprecated_macOS"

if [[ -d "$platform_mac" && -d "$legacy_mac" ]]; then
  tmp_platform="$(mktemp)"
  tmp_legacy="$(mktemp)"
  find "$platform_mac" -type f \( -path "*/Scenes/*" -o -path "*/Views/*" \) 2>/dev/null \
    | xargs -I{} basename "{}" | sort -u > "$tmp_platform"
  find "$legacy_mac" -type f \( -path "*/Scenes/*" -o -path "*/Views/*" \) 2>/dev/null \
    | xargs -I{} basename "{}" | sort -u > "$tmp_legacy"
  dupes="$(comm -12 "$tmp_platform" "$tmp_legacy")"
  rm -f "$tmp_platform" "$tmp_legacy"
  if [[ -n "$dupes" ]]; then
    echo "Duplicate scene/view filenames across Platforms/macOS and _Deprecated_macOS:" >&2
    echo "$dupes" >&2
    exit 1
  fi
fi

if rg -n "import SwiftUI" "$root_dir/SharedCore/Services" >/dev/null 2>&1; then
  echo "SharedCore/Services must not import SwiftUI." >&2
  rg -n "import SwiftUI" "$root_dir/SharedCore/Services" >&2
  exit 1
fi
