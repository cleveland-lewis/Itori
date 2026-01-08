#!/usr/bin/env python3
"""
Contrast Audit Script for Itori
Checks color combinations against WCAG AA standards
"""

import re
import sys
from pathlib import Path
from typing import List, Tuple

# WCAG AA Contrast Requirements
WCAG_AA_NORMAL = 4.5  # Normal text (< 18pt or < 14pt bold)
WCAG_AA_LARGE = 3.0   # Large text (>= 18pt or >= 14pt bold)
WCAG_AAA_NORMAL = 7.0
WCAG_AAA_LARGE = 4.5

# Common SwiftUI colors (light mode approximations)
SWIFTUI_COLORS = {
    '.white': (255, 255, 255),
    '.black': (0, 0, 0),
    '.gray': (142, 142, 147),
    '.red': (255, 59, 48),
    '.orange': (255, 149, 0),
    '.yellow': (255, 204, 0),
    '.green': (52, 199, 89),
    '.blue': (0, 122, 255),
    '.purple': (175, 82, 222),
    '.pink': (255, 45, 85),
    '.primary': (0, 0, 0),      # Light mode
    '.secondary': (60, 60, 67),  # Light mode
}

# Dark mode variants
SWIFTUI_COLORS_DARK = {
    '.primary': (255, 255, 255),
    '.secondary': (235, 235, 245),
}

def relative_luminance(rgb: Tuple[int, int, int]) -> float:
    """Calculate relative luminance per WCAG formula"""
    r, g, b = [x / 255.0 for x in rgb]
    
    def adjust(c):
        return c / 12.92 if c <= 0.03928 else ((c + 0.055) / 1.055) ** 2.4
    
    r, g, b = adjust(r), adjust(g), adjust(b)
    return 0.2126 * r + 0.7152 * g + 0.0722 * b

def contrast_ratio(color1: Tuple[int, int, int], color2: Tuple[int, int, int]) -> float:
    """Calculate contrast ratio between two colors"""
    l1 = relative_luminance(color1)
    l2 = relative_luminance(color2)
    lighter = max(l1, l2)
    darker = min(l1, l2)
    return (lighter + 0.05) / (darker + 0.05)

def check_contrast(fg: str, bg: str, context: str = "normal") -> dict:
    """Check if contrast meets WCAG standards"""
    if fg not in SWIFTUI_COLORS or bg not in SWIFTUI_COLORS:
        return {'valid': None, 'ratio': None, 'message': 'Unknown color'}
    
    ratio = contrast_ratio(SWIFTUI_COLORS[fg], SWIFTUI_COLORS[bg])
    required = WCAG_AA_LARGE if context == "large" else WCAG_AA_NORMAL
    
    return {
        'ratio': ratio,
        'required': required,
        'passes_aa': ratio >= required,
        'passes_aaa': ratio >= (WCAG_AAA_LARGE if context == "large" else WCAG_AAA_NORMAL),
        'message': f"{ratio:.2f}:1 (need {required}:1)"
    }

def scan_file(filepath: Path) -> List[dict]:
    """Scan a Swift file for potential contrast issues"""
    issues = []
    
    try:
        content = filepath.read_text()
        lines = content.split('\n')
        
        for i, line in enumerate(lines, 1):
            # Look for foreground + background combinations
            # Pattern: .foregroundColor(.xxx) with .background
            if '.foregroundColor(' in line or '.foregroundStyle(' in line:
                for color in SWIFTUI_COLORS.keys():
                    if color in line:
                        # Check surrounding lines for background
                        context = '\n'.join(lines[max(0, i-3):min(len(lines), i+3)])
                        
                        # Look for common problematic patterns
                        if '.red' in line and 'opacity(0.15)' in context:
                            issues.append({
                                'file': str(filepath),
                                'line': i,
                                'issue': 'Red text on red background with low opacity',
                                'severity': 'warning',
                                'suggestion': 'Use higher contrast or add stroke'
                            })
                        
                        if color in ['.yellow', '.pink'] and '.white' in context:
                            issues.append({
                                'file': str(filepath),
                                'line': i,
                                'issue': f'{color} on white may have insufficient contrast',
                                'severity': 'warning',
                                'suggestion': 'Test contrast ratio or use darker shade'
                            })
        
    except Exception as e:
        print(f"Error scanning {filepath}: {e}", file=sys.stderr)
    
    return issues

def main():
    print("🎨 Running Contrast Audit for Itori\n")
    print("=" * 60)
    
    # Common color combinations to check
    print("\n📊 Common Color Combinations:")
    print("-" * 60)
    
    combinations = [
        (('.white', '.black'), 'normal'),
        (('.black', '.white'), 'normal'),
        (('.blue', '.white'), 'normal'),
        (('.red', '.white'), 'normal'),
        (('.green', '.white'), 'normal'),
        (('.orange', '.white'), 'normal'),
        (('.purple', '.white'), 'normal'),
        (('.yellow', '.white'), 'normal'),
        (('.pink', '.white'), 'normal'),
        (('.gray', '.white'), 'normal'),
        (('.secondary', '.white'), 'normal'),
        (('.white', '.blue'), 'normal'),
        (('.white', '.red'), 'normal'),
        (('.white', '.green'), 'normal'),
    ]
    
    passed = 0
    failed = 0
    
    for (fg, bg), context in combinations:
        result = check_contrast(fg, bg, context)
        status = "✅" if result['passes_aa'] else "❌"
        aaa_status = " (AAA ✅)" if result['passes_aaa'] else " (AAA ❌)" if result['passes_aa'] else ""
        
        print(f"{status} {fg:12} on {bg:12} → {result['message']}{aaa_status}")
        
        if result['passes_aa']:
            passed += 1
        else:
            failed += 1
    
    print("\n" + "=" * 60)
    print(f"Summary: {passed} passed, {failed} failed")
    
    # Scan iOS files for potential issues
    print("\n🔍 Scanning iOS files for potential contrast issues...")
    print("-" * 60)
    
    ios_path = Path("Platforms/iOS")
    all_issues = []
    
    if ios_path.exists():
        swift_files = list(ios_path.rglob("*.swift"))
        for filepath in swift_files:
            issues = scan_file(filepath)
            all_issues.extend(issues)
        
        if all_issues:
            print(f"\n⚠️  Found {len(all_issues)} potential issues:\n")
            for issue in all_issues:
                print(f"  {issue['file']}:{issue['line']}")
                print(f"    Issue: {issue['issue']}")
                print(f"    Suggestion: {issue['suggestion']}\n")
        else:
            print("✅ No obvious contrast issues found in code")
    
    print("\n" + "=" * 60)
    print("\n📋 Recommendations:\n")
    print("1. Use Xcode Accessibility Inspector to verify contrast ratios")
    print("2. Test in both Light and Dark modes")
    print("3. Test with Increase Contrast enabled")
    print("4. Use semantic colors (.primary, .secondary) when possible")
    print("5. Avoid pure yellow or pink on white backgrounds")
    print("\n✨ Manual Testing Required:")
    print("   Settings → Accessibility → Display & Text Size → Increase Contrast")
    print("   Verify all UI elements remain visible and readable")
    
    return 0 if failed == 0 else 1

if __name__ == "__main__":
    sys.exit(main())
