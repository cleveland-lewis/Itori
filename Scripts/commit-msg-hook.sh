#!/bin/bash
#
# Git Pre-Commit Hook - Commit Message Validation
# 
# Installation:
#   chmod +x .git/hooks/commit-msg
#   cp scripts/commit-msg-hook.sh .git/hooks/commit-msg
#
# This hook validates commit messages locally before they reach GitHub.
#

COMMIT_MSG_FILE=$1
COMMIT_MSG=$(cat "$COMMIT_MSG_FILE")

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo ""
echo "🔍 Validating commit message..."

# Extract first line (subject)
SUBJECT=$(echo "$COMMIT_MSG" | head -n 1)

# Allowed types
ALLOWED_TYPES="^(feat|fix|docs|style|refactor|perf|test|build|ci|chore|revert|security|deps|i18n|a11y|analytics|config|hotfix|release)"

ERRORS=0

# Rule 1: Must follow Conventional Commits format
if ! echo "$SUBJECT" | grep -qE "$ALLOWED_TYPES(\(.+\))?: .+"; then
    echo -e "${RED}❌ FAILED: Must follow format: type(scope): description${NC}"
    echo "   Allowed types: feat, fix, docs, style, refactor, perf, test, build, ci, chore,"
    echo "                  revert, security, deps, i18n, a11y, analytics, config, hotfix, release"
    ERRORS=$((ERRORS + 1))
fi

# Rule 2: Subject length (10-72 characters)
SUBJECT_LENGTH=${#SUBJECT}
if [ $SUBJECT_LENGTH -lt 10 ]; then
    echo -e "${RED}❌ FAILED: Subject too short ($SUBJECT_LENGTH chars). Minimum is 10 characters.${NC}"
    ERRORS=$((ERRORS + 1))
elif [ $SUBJECT_LENGTH -gt 72 ]; then
    echo -e "${RED}❌ FAILED: Subject too long ($SUBJECT_LENGTH chars). Maximum is 72 characters.${NC}"
    ERRORS=$((ERRORS + 1))
fi

# Rule 3: Description must start with lowercase
if echo "$SUBJECT" | grep -qE "$ALLOWED_TYPES(\(.+\))?: [A-Z]"; then
    echo -e "${RED}❌ FAILED: Description must start with lowercase letter${NC}"
    ERRORS=$((ERRORS + 1))
fi

# Rule 4: Must not end with period
if echo "$SUBJECT" | grep -qE "\.$"; then
    echo -e "${RED}❌ FAILED: Subject must not end with a period${NC}"
    ERRORS=$((ERRORS + 1))
fi

# Rule 5: Check for prohibited words
PROHIBITED_WORDS=("WIP" "wip" "TODO" "FIXME" "HACK" "XXX" "fuck" "shit" "damn" "crap" "stupid" "dumb")
for WORD in "${PROHIBITED_WORDS[@]}"; do
    if echo "$SUBJECT" | grep -iq "\b$WORD\b"; then
        echo -e "${RED}❌ FAILED: Prohibited word detected: '$WORD'${NC}"
        ERRORS=$((ERRORS + 1))
    fi
done

# Rule 6: No merge commits
if echo "$SUBJECT" | grep -qE "^Merge (branch|pull request)"; then
    echo -e "${RED}❌ FAILED: Merge commits not allowed. Please rebase.${NC}"
    ERRORS=$((ERRORS + 1))
fi

# Rule 7: Breaking changes notation
if echo "$COMMIT_MSG" | grep -qi "breaking change"; then
    if ! echo "$SUBJECT" | grep -qE "!:"; then
        echo -e "${YELLOW}⚠️  WARNING: Breaking changes should include '!' in type: 'feat!: description'${NC}"
    fi
fi

# Rule 8: Scope validation (if provided)
if echo "$SUBJECT" | grep -qE "\(.+\)"; then
    SCOPE=$(echo "$SUBJECT" | grep -oE "\([^)]+\)" | tr -d '()')
    SCOPE_LENGTH=${#SCOPE}
    if [ $SCOPE_LENGTH -lt 2 ] || [ $SCOPE_LENGTH -gt 20 ]; then
        echo -e "${RED}❌ FAILED: Scope must be 2-20 characters${NC}"
        ERRORS=$((ERRORS + 1))
    fi
    if ! echo "$SCOPE" | grep -qE "^[a-z0-9-]+$"; then
        echo -e "${RED}❌ FAILED: Scope must contain only lowercase letters, numbers, and hyphens${NC}"
        ERRORS=$((ERRORS + 1))
    fi
fi

# Rule 9: No leading/trailing whitespace
if echo "$SUBJECT" | grep -qE "^[[:space:]]|[[:space:]]$"; then
    echo -e "${RED}❌ FAILED: Subject must not have leading or trailing whitespace${NC}"
    ERRORS=$((ERRORS + 1))
fi

# Display result
echo ""
if [ $ERRORS -gt 0 ]; then
    echo -e "${RED}❌ Commit message validation failed with $ERRORS error(s)${NC}"
    echo ""
    echo "📖 Commit Message Guidelines:"
    echo "   Format: type(scope): description"
    echo ""
    echo "   Examples:"
    echo "   ✅ feat(auth): add oauth2 support"
    echo "   ✅ fix(api): handle null response from server"
    echo "   ✅ docs: update installation instructions"
    echo "   ✅ refactor(core): simplify state management"
    echo ""
    echo "   See .github/COMMIT_GUIDELINES.md for complete rules"
    echo ""
    exit 1
fi

echo -e "${GREEN}✅ Commit message is valid${NC}"
echo ""
exit 0
