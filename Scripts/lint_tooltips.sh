#!/bin/bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

echo "🔎 Checking macOS tooltips: use .accessibilityLabelWithTooltip(...) instead of .accessibilityLabel(...)"

matches=$(rg -n "\\.accessibilityLabel\\(" Platforms/macOS SharedCore -g "*.swift" -g "!SharedCore/Extensions/View+Accessibility.swift" || true)

if [[ -n "$matches" ]]; then
  echo ""
  echo "❌ Tooltip lint failed. Use .accessibilityLabelWithTooltip(...) in macOS code paths."
  echo "$matches"
  exit 1
fi

echo "✅ Tooltip lint passed."
