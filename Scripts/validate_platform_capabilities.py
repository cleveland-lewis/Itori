#!/usr/bin/env python3
"""
Platform Capability Matrix Validator

This script validates that UI patterns in the codebase comply with the
Platform Capability Matrix defined in PLATFORM_CAPABILITY_MATRIX.md

Usage:
    python3 Scripts/validate_platform_capabilities.py
    
Exit codes:
    0 - All checks passed
    1 - Violations found
"""

import re
import sys
from pathlib import Path
from typing import List, Dict, Tuple

# Platform-specific patterns that should be flagged
VIOLATIONS = {
    'watchOS': {
        'forbidden': [
            (r'NavigationView\s*\{[^}]*Sidebar', 'Sidebars forbidden on watchOS'),
            (r'\.contextMenu.*rightClick', 'Right-click context menus require pointer'),
            (r'\.keyboardShortcut', 'Keyboard shortcuts not available on watchOS'),
            (r'TabView.*\.tabViewStyle\(\.page\)', 'Page-style tab views should be used sparingly'),
        ],
        'discouraged': [],
    },
    'iOS': {
        'forbidden': [
            (r'\.menuBar', 'Menu bars are macOS only'),
            (r'NSWindow', 'Direct window manipulation is macOS only'),
            (r'\.windowStyle', 'Window styling is macOS only'),
        ],
        'discouraged': [
            (r'NavigationView\s*\{[^}]*Sidebar.*\}(?!.*horizontalSizeClass)', 'Sidebars should adapt to size class on iOS'),
            (r'\.keyboardShortcut(?!.*#if.*targetEnvironment.*macCatalyst)', 'Keyboard shortcuts should check for hardware keyboard availability'),
        ],
    },
    'iPadOS': {
        'forbidden': [
            (r'\.menuBar', 'Menu bars are macOS only'),
        ],
        'discouraged': [
            (r'TabView\s*\{.*\.tabItem\(', 'Tab bars discouraged on iPad; prefer sidebar'),
        ],
    },
    'macOS': {
        'forbidden': [
            (r'TabView.*\.tabItem\(.*Image\(systemName:', 'Use sidebar navigation, not tab bars on macOS'),
        ],
        'discouraged': [
            (r'\.sheet\((?!.*isPresented)', 'Prefer popovers or panels on macOS for auxiliary content'),
        ],
    },
}

# Platform detection patterns
PLATFORM_GUARDS = {
    'watchOS': r'#if\s+os\(watchOS\)',
    'iOS': r'#if\s+os\(iOS\)',
    'iPadOS': r'#if\s+os\(iOS\).*UIDevice\.current\.userInterfaceIdiom\s*==\s*\.pad',
    'macOS': r'#if\s+os\(macOS\)',
}

def find_swift_files(root_dir: Path) -> List[Path]:
    """Find all Swift files in the project."""
    swift_files = []
    for pattern in ['Platforms/**/*.swift', 'Shared/**/*.swift', 'SharedCore/**/*.swift']:
        swift_files.extend(root_dir.glob(pattern))
    return swift_files

def detect_platform_from_path(file_path: Path) -> str:
    """Detect which platform a file is intended for based on its path."""
    path_str = str(file_path)
    
    if '/watchOS/' in path_str or 'Watch' in path_str:
        return 'watchOS'
    elif '/macOS/' in path_str:
        return 'macOS'
    elif '/iOS/' in path_str:
        # Need to distinguish iPad-specific code
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()
            if 'UIDevice.current.userInterfaceIdiom == .pad' in content:
                return 'iPadOS'
        return 'iOS'
    elif '/Shared/' in path_str or '/SharedCore/' in path_str:
        return 'Shared'
    
    return 'Unknown'

def check_file(file_path: Path) -> List[Tuple[str, int, str]]:
    """Check a file for platform capability violations."""
    violations = []
    platform = detect_platform_from_path(file_path)
    
    if platform not in VIOLATIONS:
        return violations
    
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()
            lines = content.split('\n')
            
            # Check for forbidden patterns
            for pattern, message in VIOLATIONS[platform]['forbidden']:
                for i, line in enumerate(lines, 1):
                    if re.search(pattern, line):
                        violations.append((
                            'FORBIDDEN',
                            i,
                            f"{message}: {line.strip()}"
                        ))
            
            # Check for discouraged patterns
            for pattern, message in VIOLATIONS[platform]['discouraged']:
                for i, line in enumerate(lines, 1):
                    if re.search(pattern, line):
                        violations.append((
                            'DISCOURAGED',
                            i,
                            f"{message}: {line.strip()}"
                        ))
    
    except Exception as e:
        print(f"Error reading {file_path}: {e}", file=sys.stderr)
    
    return violations

def main():
    """Main validation function."""
    root_dir = Path(__file__).parent.parent
    swift_files = find_swift_files(root_dir)
    
    print("🔍 Platform Capability Matrix Validator")
    print(f"📁 Scanning {len(swift_files)} Swift files...\n")
    
    all_violations: Dict[str, List[Tuple[str, int, str]]] = {}
    
    for file_path in swift_files:
        violations = check_file(file_path)
        if violations:
            all_violations[str(file_path)] = violations
    
    if not all_violations:
        print("✅ No platform capability violations found!")
        return 0
    
    # Report violations
    print(f"❌ Found violations in {len(all_violations)} files:\n")
    
    forbidden_count = 0
    discouraged_count = 0
    
    for file_path, violations in all_violations.items():
        print(f"📄 {file_path}")
        for severity, line_num, message in violations:
            icon = "🚫" if severity == "FORBIDDEN" else "⚠️"
            print(f"  {icon} Line {line_num}: {message}")
            
            if severity == "FORBIDDEN":
                forbidden_count += 1
            else:
                discouraged_count += 1
        print()
    
    print("\n" + "="*70)
    print(f"Summary:")
    print(f"  🚫 Forbidden violations: {forbidden_count}")
    print(f"  ⚠️  Discouraged patterns: {discouraged_count}")
    print(f"  📋 See PLATFORM_CAPABILITY_MATRIX.md for details")
    print("="*70)
    
    return 1 if forbidden_count > 0 else 0

if __name__ == '__main__':
    sys.exit(main())
