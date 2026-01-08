#!/bin/bash
# Localization Validation Script
# Checks for missing localization strings and hardcoded text

set -e

ERRORS=0
WARNINGS=0

# Colors
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
NC='\033[0m'

echo "🌍 Validating Localization..."
echo ""

# Get staged Swift files
STAGED_FILES=$(git diff --cached --name-only --diff-filter=ACM | grep "\.swift$" || true)

if [ -z "$STAGED_FILES" ]; then
    echo "✅ No Swift files to check"
    exit 0
fi

# Function to check file for localization issues
check_file() {
    local file=$1
    local file_errors=0
    local file_warnings=0
    
    # Skip test files and models
    if [[ $file == *"Tests/"* ]] || [[ $file == *"UITests/"* ]] || \
       [[ $file == *"Model"* ]] || [[ $file == *"Store"* ]]; then
        return 0
    fi
    
    # Check for Text with hardcoded English strings
    local hardcoded_texts=$(grep -n 'Text("' "$file" | grep -v "Text(verbatim:" || true)
    
    if [ ! -z "$hardcoded_texts" ]; then
        while IFS= read -r line; do
            local line_num=$(echo "$line" | cut -d: -f1)
            local content=$(echo "$line" | cut -d: -f2-)
            
            # Check if it looks like user-facing text (has letters and spaces)
            if echo "$content" | grep -qE 'Text\(".*[a-zA-Z].*[a-zA-Z].*"\)'; then
                # Ignore if it's a number or single character
                if ! echo "$content" | grep -qE 'Text\("[0-9]+"?\)|Text\("[a-zA-Z]"\)'; then
                    echo -e "${YELLOW}⚠️  WARNING${NC}: Hardcoded user-facing text found"
                    echo "   File: $file:$line_num"
                    echo "   Text: $(echo "$content" | grep -o 'Text("[^"]*")' | head -1)"
                    echo "   Fix: Use NSLocalizedString(\"key\", value: \"$content\", comment: \"\")"
                    echo ""
                    ((file_warnings++))
                fi
            fi
        done <<< "$hardcoded_texts"
    fi
    
    # Check for Label with hardcoded strings
    local hardcoded_labels=$(grep -n 'Label("' "$file" | grep -v 'Label(verbatim:' || true)
    
    if [ ! -z "$hardcoded_labels" ]; then
        while IFS= read -r line; do
            local line_num=$(echo "$line" | cut -d: -f1)
            echo -e "${YELLOW}⚠️  WARNING${NC}: Hardcoded label text found"
            echo "   File: $file:$line_num"
            echo "   Fix: Use NSLocalizedString for label text"
            echo ""
            ((file_warnings++))
        done <<< "$hardcoded_labels"
    fi
    
    # Check for alert titles and messages
    if grep -q "\.alert(" "$file"; then
        local alert_lines=$(grep -n "\.alert(" "$file" | cut -d: -f1)
        for line_num in $alert_lines; do
            local context=$(sed -n "${line_num},$((line_num + 5))p" "$file")
            
            if echo "$context" | grep -q '"' && ! echo "$context" | grep -q "NSLocalizedString"; then
                echo -e "${YELLOW}⚠️  WARNING${NC}: Alert with hardcoded text"
                echo "   File: $file:$line_num"
                echo "   Alerts should be localized"
                echo ""
                ((file_warnings++))
            fi
        done
    fi
    
    # Check if file uses NSLocalizedString and extract keys
    if grep -q "NSLocalizedString" "$file"; then
        # Extract all localization keys from this file
        local keys=$(grep -o 'NSLocalizedString("[^"]*"' "$file" | sed 's/NSLocalizedString("//;s/"$//' || true)
        
        if [ ! -z "$keys" ]; then
            # Check if these keys exist in Localizable.strings
            local localizable_files=$(find . -name "Localizable.strings" -path "*/en.lproj/*" 2>/dev/null || true)
            
            if [ ! -z "$localizable_files" ]; then
                for key in $keys; do
                    local key_found=false
                    for strings_file in $localizable_files; do
                        if grep -q "\"$key\"" "$strings_file" 2>/dev/null; then
                            key_found=true
                            break
                        fi
                    done
                    
                    if [ "$key_found" = false ]; then
                        echo -e "${YELLOW}⚠️  WARNING${NC}: Localization key not found in Localizable.strings"
                        echo "   File: $file"
                        echo "   Key: \"$key\""
                        echo "   Add this key to Localizable.strings files"
                        echo ""
                        ((file_warnings++))
                    fi
                done
            fi
        fi
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
    echo -e "${RED}❌ $ERRORS localization error(s) found${NC}"
    echo "Please fix these issues before committing"
    exit 1
elif [ $WARNINGS -gt 0 ]; then
    echo -e "${YELLOW}⚠️  $WARNINGS localization warning(s) found${NC}"
    echo ""
    echo "These are suggestions for improvement."
    echo "Consider localizing user-facing text."
    echo ""
    read -p "Continue with commit anyway? (y/N) " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Commit cancelled"
        exit 1
    fi
else
    echo -e "${GREEN}✅ All localization checks passed!${NC}"
fi

exit 0
