#!/usr/bin/env python3
"""
Complete remaining Farsi translations manually
Handles the failed strings from automated translation
"""

import json
import sys

# Manual translations for failed strings
MANUAL_TRANSLATIONS = {
    "How far ahead to schedule tasks and events for visual planning": "چند روز جلوتر برای برنامه ریزی بصری وظایف و رویدادها را برنامه ریزی کنید",
    "This will clear all debug logs and reset counters. Continue?": "این کار تمام گزارش های اشکال زدایی را پاک کرده و شمارنده ها را بازنشانی می کند. ادامه؟",
    "Pomodoro Cycles": "چرخه های پومودورو",
    "Long Break": "استراحت طولانی",
    "Alert at each pomodoro phase change": "هشدار در هر تغییر فاز پومودورو",
    "Timer Duration": "مدت زمان تایمر",
    "The Study Coach helps you maintain focus and flow during study sessions.": "مربی مطالعه به شما کمک می کند تا در طول جلسات مطالعه تمرکز و جریان خود را حفظ کنید.",
    "These counters must remain zero when no features are active.": "زمانی که هیچ ویژگی فعال نیست، این شمارنده ها باید صفر بمانند.",
    "This will permanently delete all records. Continue?": "این کار تمام رکوردها را برای همیشه حذف می کند. ادامه؟",
    "Add Grade": "افزودن نمره",
    "None": "هیچ یک",
    "Updated %@": "به روز شد %@",
    "View History": "مشاهده تاریخچه",
    "When enabled, the app emits structured telemetry to help diagnose issues.": "هنگامی که فعال است، برنامه تله متری ساختاریافته را برای کمک به تشخیص مشکلات منتشر می کند.",
    
    # Additional common strings
    "common.button.next": "بعدی",
    "On": "روشن",
    "Off": "خاموش",
    "On Date": "در تاریخ",
    "AM": "قبل از ظهر",
    "PM": "بعد از ظهر",
    "Today": "امروز",
    "Yesterday": "دیروز",
    "Tomorrow": "فردا",
    "This Week": "این هفته",
    "Next Week": "هفته بعد",
    "All Day": "تمام روز",
    "Repeat": "تکرار",
    "Never": "هرگز",
    "Daily": "روزانه",
    "Weekly": "هفتگی",
    "Monthly": "ماهانه",
    "Yearly": "سالانه",
    "Custom": "سفارشی",
    "High": "بالا",
    "Medium": "متوسط",
    "Low": "پایین",
    "Notes": "یادداشت ها",
    "Location": "مکان",
    "URL": "آدرس وب",
    "Attachments": "پیوست ها",
    "Priority": "اولویت",
    "Status": "وضعیت",
    "Tags": "برچسب ها",
    "Category": "دسته بندی",
    "Due Date": "سررسید",
    "Start Date": "تاریخ شروع",
    "End Date": "تاریخ پایان",
    "Notification": "اطلاعیه",
    "Reminder": "یادآوری",
    "Alert": "هشدار",
    "Sound": "صدا",
    "Badge": "نشان",
    "Banner": "بنر",
}

def complete_farsi_translations(file_path):
    """Complete remaining Farsi translations"""
    
    print("📖 Loading localization file...")
    with open(file_path, 'r', encoding='utf-8') as f:
        data = json.load(f)
    
    completed = 0
    still_missing = []
    
    print("🔧 Completing Farsi translations...\n")
    
    for key, value in data['strings'].items():
        if not value or 'localizations' not in value:
            continue
        
        # Check if needs translation
        if 'fa' not in value['localizations']:
            value['localizations']['fa'] = {
                'stringUnit': {
                    'state': 'needs_review',
                    'value': key
                }
            }
        
        fa_entry = value['localizations']['fa']
        
        # Skip already translated
        if fa_entry['stringUnit']['state'] == 'translated':
            continue
        
        # Get source text
        en_entry = value['localizations'].get('en', {})
        source_text = en_entry.get('stringUnit', {}).get('value', key)
        
        # Try manual translation
        if source_text in MANUAL_TRANSLATIONS:
            fa_entry['stringUnit']['value'] = MANUAL_TRANSLATIONS[source_text]
            fa_entry['stringUnit']['state'] = 'translated'
            completed += 1
            print(f"✅ {source_text[:50]}... → {MANUAL_TRANSLATIONS[source_text][:50]}...")
        elif key in MANUAL_TRANSLATIONS:
            fa_entry['stringUnit']['value'] = MANUAL_TRANSLATIONS[key]
            fa_entry['stringUnit']['state'] = 'translated'
            completed += 1
            print(f"✅ {key[:50]}... → {MANUAL_TRANSLATIONS[key][:50]}...")
        else:
            # Keep as needs_review but use English as fallback
            fa_entry['stringUnit']['value'] = source_text
            still_missing.append((key, source_text))
    
    # Save
    print("\n💾 Saving translations...")
    with open(file_path, 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
    
    print("\n" + "="*60)
    print("✅ Farsi completion done!")
    print("="*60)
    print(f"   Completed: {completed}")
    print(f"   Still needs review: {len(still_missing)}")
    
    if still_missing:
        print("\n⚠️  Strings still needing translation:")
        for key, text in still_missing[:10]:
            print(f"   • {text[:60]}")
        if len(still_missing) > 10:
            print(f"   ... and {len(still_missing) - 10} more")
    
    print("="*60)

if __name__ == '__main__':
    file_path = 'SharedCore/DesignSystem/Localizable.xcstrings'
    complete_farsi_translations(file_path)
