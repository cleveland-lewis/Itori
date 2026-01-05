#!/usr/bin/env python3
"""
Automated Swift Localization Script
Finds hardcoded strings and wraps them in NSLocalizedString()
"""

import re
import sys
import os
from pathlib import Path

def generate_key(text, context=""):
    """Generate a localization key from text"""
    # Clean the text
    clean = text.lower()
    # Remove special characters
    clean = re.sub(r'[^\w\s]', '', clean)
    # Replace spaces with dots
    clean = re.sub(r'\s+', '.', clean.strip())
    # Limit length
    if len(clean) > 50:
        words = clean.split('.')
        clean = '.'.join(words[:5])
    return clean

def extract_category_from_path(filepath):
    """Extract category from file path"""
    path = Path(filepath)
    if 'Settings' in path.name:
        return 'settings'
    elif 'View' in path.name:
        name = path.stem.replace('View', '').replace('Page', '')
        return name.lower()
    return 'ui'

def localize_text_calls(content, filepath):
    """Localize Text() calls"""
    category = extract_category_from_path(filepath)
    
    # Pattern for Text("...") that's not already localized
    pattern = r'Text\("([^"\\]*(?:\\.[^"\\]*)*)"\)'
    
    def replace_text(match):
        text = match.group(1)
        
        # Skip if it's a variable interpolation
        if '\\(' in text:
            return match.group(0)
        
        # Skip common symbols
        if text in ['·', '—', ' ', '-']:
            return match.group(0)
            
        # Skip if it looks like a format string result
        if text.startswith('%'):
            return match.group(0)
        
        # Generate key
        key = f"{category}.{generate_key(text)}"
        
        # Create localized version
        comment = f"{text[:50]}..." if len(text) > 50 else text
        localized = f'Text(NSLocalizedString("{key}", value: "{text}", comment: "{comment}"))'
        
        return localized
    
    return re.sub(pattern, replace_text, content)

def localize_label_calls(content, filepath):
    """Localize Label("...") calls"""
    category = extract_category_from_path(filepath)
    
    # Pattern for Label("...")
    pattern = r'Label\("([^"\\]*(?:\\.[^"\\]*)*)"\s*,\s*systemImage:'
    
    def replace_label(match):
        text = match.group(1)
        key = f"{category}.label.{generate_key(text)}"
        comment = text[:50]
        
        localized = f'Label(NSLocalizedString("{key}", value: "{text}", comment: "{comment}"), systemImage:'
        return localized
    
    return re.sub(pattern, replace_label, content)

def localize_button_calls(content, filepath):
    """Localize Button("...") calls"""
    category = extract_category_from_path(filepath)
    
    # Pattern for Button("...")
    pattern = r'Button\("([^"\\]*(?:\\.[^"\\]*)*)"\)'
    
    def replace_button(match):
        text = match.group(1)
        key = f"{category}.button.{generate_key(text)}"
        comment = text
        
        localized = f'Button(NSLocalizedString("{key}", value: "{text}", comment: "{comment}"))'
        return localized
    
    return re.sub(pattern, replace_button, content)

def localize_toggle_calls(content, filepath):
    """Localize Toggle("...") calls"""
    category = extract_category_from_path(filepath)
    
    pattern = r'Toggle\("([^"\\]*(?:\\.[^"\\]*)*)"\s*,\s*isOn:'
    
    def replace_toggle(match):
        text = match.group(1)
        key = f"{category}.toggle.{generate_key(text)}"
        comment = text[:50]
        
        localized = f'Toggle(NSLocalizedString("{key}", value: "{text}", comment: "{comment}"), isOn:'
        return localized
    
    return re.sub(pattern, replace_toggle, content)

def process_file(filepath):
    """Process a single Swift file"""
    try:
        with open(filepath, 'r', encoding='utf-8') as f:
            content = f.read()
        
        # Skip if already heavily localized
        if content.count('NSLocalizedString') > 20:
            print(f"⏭️  Skipping {filepath} (already localized)")
            return False
        
        original = content
        
        # Apply localizations
        content = localize_text_calls(content, filepath)
        content = localize_label_calls(content, filepath)
        content = localize_button_calls(content, filepath)
        content = localize_toggle_calls(content, filepath)
        
        # Check if anything changed
        if content != original:
            with open(filepath, 'w', encoding='utf-8') as f:
                f.write(content)
            
            changes = content.count('NSLocalizedString') - original.count('NSLocalizedString')
            print(f"✅ Localized {filepath}: +{changes} strings")
            return True
        else:
            print(f"⚪ No changes: {filepath}")
            return False
            
    except Exception as e:
        print(f"❌ Error processing {filepath}: {e}")
        return False

def main():
    if len(sys.argv) < 2:
        print("Usage: python3 localize_swift.py <file_or_directory>")
        sys.exit(1)
    
    target = sys.argv[1]
    
    if os.path.isfile(target):
        process_file(target)
    elif os.path.isdir(target):
        swift_files = Path(target).rglob('*.swift')
        count = 0
        for filepath in swift_files:
            if process_file(str(filepath)):
                count += 1
        print(f"\n📊 Processed {count} files successfully")
    else:
        print(f"❌ Invalid target: {target}")
        sys.exit(1)

if __name__ == '__main__':
    main()
