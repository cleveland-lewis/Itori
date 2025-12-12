#!/bin/bash
# Fail if EKEventStore( is used outside DeviceCalendarManager.swift
set -euo pipefail
repo_root="$(cd "$(dirname "$0")/../.." && pwd)"
matches=$(rg "EKEventStore\(" -g '!scripts/**' -S "$repo_root" || true)
if [ -z "$matches" ]; then
  echo "No EKEventStore usages found"
  exit 0
fi
# Filter out the allowed file
filtered=$(echo "$matches" | rg -v "DeviceCalendarManager.swift" || true)
if [ -n "$filtered" ]; then
  echo "Forbidden EKEventStore instantiations found outside DeviceCalendarManager:"
  echo "$filtered"
  exit 2
fi
echo "Only DeviceCalendarManager creates EKEventStore"
exit 0
