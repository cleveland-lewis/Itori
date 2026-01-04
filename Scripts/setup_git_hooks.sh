#!/bin/bash
#
# Setup Git Hooks for Itori Project
# Run this script to install development hooks
#

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
HOOKS_DIR="$PROJECT_ROOT/.git/hooks"

echo "🔧 Setting up Git hooks for Itori..."
echo ""

# Check if .git directory exists
if [ ! -d "$PROJECT_ROOT/.git" ]; then
    echo "❌ Error: Not a git repository"
    echo "   Run this script from within the Itori project"
    exit 1
fi

# Create hooks directory if it doesn't exist
mkdir -p "$HOOKS_DIR"

# Install pre-commit hook
echo "📝 Installing pre-commit hook..."
cat > "$HOOKS_DIR/pre-commit" << 'HOOK'
#!/bin/bash
#
# Pre-commit hook to enforce localization on Swift files
# Checks for hardcoded strings in Text(), Label(), Button(), Toggle()
#

RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

echo "🔍 Checking for hardcoded strings..."

# Get list of Swift files being committed
SWIFT_FILES=$(git diff --cached --name-only --diff-filter=ACM | grep '\.swift$' | grep -E 'Platforms/(macOS|iOS)')

if [ -z "$SWIFT_FILES" ]; then
    echo "✅ No Swift UI files to check"
    exit 0
fi

FOUND_HARDCODED=0
VIOLATIONS=""

for file in $SWIFT_FILES; do
    if [ -f "$file" ]; then
        # Check for hardcoded strings (excluding already localized ones)
        HARDCODED=$(grep -n 'Text("\|Label("\|Button("\|Toggle("' "$file" | \
                   grep -v 'NSLocalizedString\|LocalizedStringKey\|\.localized' | \
                   grep -v 'Text("\\' | \
                   grep -v '\/\/' | \
                   grep -v 'Text("")' | \
                   grep -v 'Text(" ")' | \
                   grep -v 'Text("·")' | \
                   grep -v 'Text("—")' | \
                   grep -v 'Text("-")')
        
        if [ ! -z "$HARDCODED" ]; then
            FOUND_HARDCODED=1
            VIOLATIONS="${VIOLATIONS}\n${YELLOW}${file}:${NC}\n${HARDCODED}\n"
        fi
    fi
done

if [ $FOUND_HARDCODED -eq 1 ]; then
    echo ""
    echo -e "${RED}❌ COMMIT BLOCKED: Hardcoded strings detected!${NC}"
    echo ""
    echo -e "${YELLOW}The following files contain hardcoded UI strings:${NC}"
    echo -e "$VIOLATIONS"
    echo ""
    echo -e "${GREEN}To fix:${NC}"
    echo "  1. Run the localization script:"
    echo "     ${GREEN}python3 Scripts/localize_swift.py <file>${NC}"
    echo ""
    echo "  2. Or manually wrap strings in NSLocalizedString():"
    echo "     ${GREEN}Text(NSLocalizedString(\"key\", value: \"Text\", comment: \"Description\"))${NC}"
    echo ""
    echo "  3. Then stage and commit again"
    echo ""
    echo -e "${YELLOW}To bypass this check (not recommended):${NC}"
    echo "     git commit --no-verify"
    echo ""
    exit 1
fi

echo "✅ All strings are properly localized"
exit 0
HOOK

chmod +x "$HOOKS_DIR/pre-commit"

echo "✅ Pre-commit hook installed"
echo ""
echo "📋 What this hook does:"
echo "   - Checks all Swift files for hardcoded UI strings"
echo "   - Blocks commits containing unlocalizable strings"
echo "   - Suggests using Scripts/localize_swift.py to fix"
echo ""
echo "🚀 Setup complete! Your commits will now be checked for localization."
echo ""
echo "💡 To test the hook:"
echo "   1. Create a Swift file with: Text(\"Hardcoded\")"
echo "   2. Try to commit it"
echo "   3. The hook will block and suggest fixes"
echo ""
