#!/bin/bash
#
# Install Git Hooks for Commit Validation
#
# This script sets up local git hooks to validate commit messages
# before they are pushed to GitHub.
#

set -e

echo "🔧 Installing Git Hooks for Commit Validation"
echo ""

# Check if we're in a git repository
if [ ! -d ".git" ]; then
    echo "❌ Error: Not a git repository"
    echo "   Run this script from the repository root"
    exit 1
fi

# Create hooks directory if it doesn't exist
mkdir -p .git/hooks

# Copy commit-msg hook
echo "📝 Installing commit-msg hook..."
cp Scripts/commit-msg-hook.sh .git/hooks/commit-msg
chmod +x .git/hooks/commit-msg

echo "✅ Git hooks installed successfully!"
echo ""
echo "📋 What's been set up:"
echo "   • commit-msg hook - validates commit message format"
echo ""
echo "🎯 Your commits will now be validated locally before push"
echo ""
echo "Optional: Install commitlint for even stricter validation"
echo "   npm install -g @commitlint/cli @commitlint/config-conventional"
echo "   npm install -g husky"
echo "   npx husky install"
echo "   npx husky add .git/hooks/commit-msg 'npx commitlint --edit \$1'"
echo ""
echo "📖 See .github/COMMIT_GUIDELINES.md for complete rules"
