#!/usr/bin/env python3
import os
import json

# This script helps organize localization files properly
# The files already exist in *.lproj folders, we need to reference them in Xcode

print("Localization files exist in:")
for lang in ["en", "es", "fr", "it", "ru", "de", "ar", "zh-Hans", "zh-Hant", "yue", "is", "nl"]:
    path = f"{lang}.lproj/Localizable.strings"
    if os.path.exists(path):
        size = os.path.getsize(path)
        print(f"  {path} ({size} bytes)")

print("\nTo add to Xcode project:")
print("1. Open ItoriApp.xcodeproj in Xcode")
print("2. Right-click on project root > Add Files to 'ItoriApp'")
print("3. Select en.lproj/Localizable.strings")
print("4. Check 'Copy items if needed' is OFF")
print("5. Select Itori target")
print("6. In File Inspector, click 'Localize...' button")
print("7. Select 'English' as base")
print("8. Check all other languages in the list")
