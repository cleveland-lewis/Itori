#!/bin/bash
# Script to create GitHub issues from test failure analysis
# Usage: ./create_test_issues.sh

set -e

cd "$(dirname "$0")"

echo "🐛 Creating GitHub Issues for Unit Test Failures..."
echo ""

# Check if gh is installed
if ! command -v gh &> /dev/null; then
    echo "❌ GitHub CLI (gh) not found. Please install it:"
    echo "   brew install gh"
    echo ""
    echo "Or create issues manually from the ISSUE_*.md files"
    exit 1
fi

# Check if authenticated
if ! gh auth status &> /dev/null; then
    echo "❌ Not authenticated with GitHub. Run: gh auth login"
    exit 1
fi

echo "✅ GitHub CLI ready"
echo ""

# Issue 1: RecurrenceRule Missing
echo "📝 Creating Issue 1: Missing RecurrenceRule Type..."
gh issue create \
  --title "[BUG] Missing RecurrenceRule Type Breaks Build" \
  --body-file ISSUE_RECURRENCE_RULE_MISSING.md \
  --label "bug,critical,build-failure,testing,models" \
  && echo "✅ Issue 1 created" || echo "❌ Issue 1 failed"

echo ""

# Issue 2: CodingKeys Privacy
echo "📝 Creating Issue 2: AppTask CodingKeys Privacy..."
gh issue create \
  --title "[BUG] AppTask CodingKeys Privacy Breaks Protocol Conformance" \
  --body-file ISSUE_APPTASK_CODING_KEYS_PRIVATE.md \
  --label "bug,critical,build-failure,testing,swift,models" \
  && echo "✅ Issue 2 created" || echo "❌ Issue 2 failed"

echo ""

# Issue 3: Init Call Sites
echo "📝 Creating Issue 3: AppTask Initializer Call Sites..."
gh issue create \
  --title "[BUG] AppTask Initializer Call Sites Out of Sync" \
  --body-file ISSUE_APPTASK_INIT_CALL_SITES.md \
  --label "bug,critical,build-failure,testing,refactoring,models" \
  && echo "✅ Issue 3 created" || echo "❌ Issue 3 failed"

echo ""

# Issue 4: Type Confusion (Discussion)
echo "📝 Creating Issue 4: RecurrenceRule Type Confusion..."
gh issue create \
  --title "[DISCUSSION] TaskRecurrence vs RecurrenceRule - Type Confusion" \
  --body-file ISSUE_RECURRENCE_TYPE_CONFUSION.md \
  --label "discussion,architecture,models,recurring-tasks,decision-needed" \
  && echo "✅ Issue 4 created" || echo "❌ Issue 4 failed"

echo ""
echo "🎉 Done! Check GitHub issues page for created issues."
echo ""
echo "View issues:"
echo "  gh issue list --label \"build-failure\""
echo ""
