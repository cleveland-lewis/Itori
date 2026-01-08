#!/bin/bash
# Accessibility Validation Script
# Checks Swift files for proper accessibility implementations

set -e

ERRORS=0
WARNINGS=0

# Colors for output
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

echo "🔍 Validating Accessibility Implementation..."
echo ""

# Get all staged Swift files
STAGED_FILES=$(git diff --cached --name-only --diff-filter=ACM | grep "\.swift$" || true)

if [ -z "$STAGED_FILES" ]; then
    echo "✅ No Swift files to check"
    exit 0
fi

# Function to check file for accessibility issues
check_file() {
    local file=$1
    local file_errors=0
    local file_warnings=0
    
    # Skip test files
    if [[ $file == *"Tests/"* ]] || [[ $file == *"UITests/"* ]]; then
        return 0
    fi
    
    # Skip certain files that don't need accessibility
    if [[ $file == *"Model"* ]] || [[ $file == *"Store"* ]] || [[ $file == *"Manager"* ]]; then
        return 0
    fi
    
    # Check for Button with Image(systemName:) without accessibility label
    if grep -q "Button.*{" "$file"; then
        # Find buttons with images but no accessibility labels nearby
        local button_lines=$(grep -n "Button.*{" "$file" | cut -d: -f1)
        for line_num in $button_lines; do
            # Check next 10 lines for Image and accessibilityLabel
            local context=$(sed -n "${line_num},$((line_num + 10))p" "$file")
            
            if echo "$context" | grep -q "Image(systemName:" && \
               ! echo "$context" | grep -q "accessibilityLabel\|Label.*systemImage"; then
                echo -e "${YELLOW}⚠️  WARNING${NC}: Button with icon missing accessibility label"
                echo "   File: $file:$line_num"
                echo "   Add: .accessibilityLabel(\"Description\")"
                echo ""
                ((file_warnings++))
            fi
        done
    fi
    
    # Check for decorative images without accessibilityHidden
    if grep -q "Image(systemName:" "$file"; then
        # Look for decorative patterns: badges, chevrons, decorative icons
        local decorative_patterns=(
            "chevron\."
            "\.badge"
            "\.fill.*\.opacity"
            "sparkles"
            "circle\.fill"
        )
        
        for pattern in "${decorative_patterns[@]}"; do
            if grep -B2 -A2 "$pattern" "$file" | grep -v "accessibilityHidden" | grep -q "Image(systemName:.*$pattern"; then
                local line_num=$(grep -n "$pattern" "$file" | head -1 | cut -d: -f1)
                echo -e "${YELLOW}⚠️  WARNING${NC}: Potentially decorative image not hidden"
                echo "   File: $file:$line_num"
                echo "   Pattern: $pattern"
                echo "   Consider: .accessibilityHidden(true) if decorative"
                echo ""
                ((file_warnings++))
            fi
        done
    fi
    
    # Check for Text with hardcoded strings (should use NSLocalizedString)
    if grep -q 'Text("' "$file" && ! grep -q "Text(verbatim:" "$file"; then
        local hardcoded_count=$(grep -c 'Text("' "$file" || echo "0")
        local localized_count=$(grep -c 'NSLocalizedString\|LocalizedStringKey' "$file" || echo "0")
        
        if [ "$hardcoded_count" -gt 3 ] && [ "$localized_count" -eq 0 ]; then
            echo -e "${YELLOW}⚠️  WARNING${NC}: Hardcoded strings found, localization may be missing"
            echo "   File: $file"
            echo "   Consider using NSLocalizedString for user-facing text"
            echo ""
            ((file_warnings++))
        fi
    fi
    
    # Check for Toggle without descriptive label
    if grep -q "Toggle(isOn:" "$file"; then
        local toggle_lines=$(grep -n "Toggle(isOn:" "$file" | cut -d: -f1)
        for line_num in $toggle_lines; do
            local context=$(sed -n "${line_num},$((line_num + 5))p" "$file")
            
            # Check if toggle has proper label structure
            if ! echo "$context" | grep -q "VStack.*Text\|Label.*Text"; then
                echo -e "${YELLOW}⚠️  WARNING${NC}: Toggle may need descriptive label"
                echo "   File: $file:$line_num"
                echo "   Consider adding descriptive VStack with title and subtitle"
                echo ""
                ((file_warnings++))
            fi
        done
    fi
    
    # Check for .font(.system(size:)) - should use semantic sizes
    if grep -q "\.font(\.system(size:" "$file"; then
        local fixed_font_lines=$(grep -n "\.font(\.system(size:" "$file" | cut -d: -f1)
        for line_num in $fixed_font_lines; do
            echo -e "${YELLOW}⚠️  WARNING${NC}: Fixed font size found"
            echo "   File: $file:$line_num"
            echo "   Consider using semantic sizes: .body, .headline, etc."
            echo "   This supports Dynamic Type for accessibility"
            echo ""
            ((file_warnings++))
        done
    fi
    
    ERRORS=$((ERRORS + file_errors))
    WARNINGS=$((WARNINGS + file_warnings))
    
    return 0
}

# Check each staged file
for file in $STAGED_FILES; do
    if [ -f "$file" ]; then
        check_file "$file"
    fi
done

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

if [ $ERRORS -gt 0 ]; then
    echo -e "${RED}❌ $ERRORS accessibility error(s) found${NC}"
    echo "Please fix these issues before committing"
    exit 1
elif [ $WARNINGS -gt 0 ]; then
    echo -e "${YELLOW}⚠️  $WARNINGS accessibility warning(s) found${NC}"
    echo ""
    echo "These are suggestions for improvement."
    echo "Review them and consider making changes."
    echo ""
    read -p "Continue with commit anyway? (y/N) " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Commit cancelled"
        exit 1
    fi
else
    echo -e "${GREEN}✅ All accessibility checks passed!${NC}"
fi

exit 0
