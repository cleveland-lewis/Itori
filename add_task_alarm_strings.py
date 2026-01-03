#!/usr/bin/env python3
"""
Add Phase 4.3 task alarm localization strings to Localizable.xcstrings
"""

import json

# Load the existing strings file
with open('SharedCore/DesignSystem/Localizable.xcstrings', 'r', encoding='utf-8') as f:
    data = json.load(f)

# New strings to add
new_strings = {
    "timer.tasks.title": "Tasks",
    "timer.tasks.dueToday": "Due Today",
    "timer.tasks.dueThisWeek": "Due This Week",
    "timer.tasks.noDueToday": "No tasks due today",
    "timer.tasks.noDueThisWeek": "No tasks due this week",
    "timer.tasks.today": "Today",
    "timer.tasks.tomorrow": "Tomorrow",
    "timer.tasks.due": "Due",
    "timer.tasks.status": "Status",
    "timer.tasks.alarm.title": "Task Reminder",
    "timer.tasks.alarm.enabled": "Set Alarm",
    "timer.tasks.alarm.time": "Alarm Time",
    "timer.tasks.alarm.when": "When",
    "timer.tasks.alarm.sound": "Sound",
    "timer.tasks.alarm.sound.default": "Default",
    "timer.tasks.alarm.quick.1hour": "1 Hour Before",
    "timer.tasks.alarm.quick.morning": "Morning of",
    "timer.tasks.alarm.quick.dayBefore": "Day Before",
    "timer.tasks.alarm.quick.custom": "Custom",
    "timer.tasks.alarm.error": "Error",
    "task.alarm.title": "Task Reminder",
    "task.alarm.error.notAuthorized": "Alarm authorization required",
    "task.alarm.error.invalidDate": "Invalid alarm date",
    "task.alarm.error.schedulingFailed": "Failed to schedule alarm",
}

# Add each string to the catalog
for key, value in new_strings.items():
    if key not in data["strings"]:
        data["strings"][key] = {
            "localizations": {
                "en": {
                    "stringUnit": {
                        "state": "translated",
                        "value": value
                    }
                }
            }
        }
        print(f"✓ Added: {key}")
    else:
        print(f"⊙ Skipped (exists): {key}")

# Write back to file
with open('SharedCore/DesignSystem/Localizable.xcstrings', 'w', encoding='utf-8') as f:
    json.dump(data, f, indent=2, ensure_ascii=False)
    f.write('\n')  # Add trailing newline

print(f"\n✅ Added {len(new_strings)} localization strings")
