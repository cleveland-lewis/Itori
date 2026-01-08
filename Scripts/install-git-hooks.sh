#!/bin/bash
#
# Git Hooks Installer for Itori
# Copies hooks from Scripts/git-hooks/ to .git/hooks/
#

set -e

REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
cd "$REPO_ROOT"

echo "╔════════════════════════════════════════╗"
echo "║   Itori Git Hooks Installer            ║"
echo "╚════════════════════════════════════════╝"
echo ""

# Backup existing hooks
if [ -f .git/hooks/pre-commit ]; then
    echo "📦 Backing up existing pre-commit hook..."
    cp .git/hooks/pre-commit ".git/hooks/pre-commit.backup-$(date +%Y%m%d-%H%M%S)"
fi

if [ -f .git/hooks/commit-msg ]; then
    echo "📦 Backing up existing commit-msg hook..."
    cp .git/hooks/commit-msg ".git/hooks/commit-msg.backup-$(date +%Y%m%d-%H%M%S)"
fi

# Install hooks (they're already in .git/hooks/ but ensure they're executable)
echo "🔧 Setting hook permissions..."
chmod +x .git/hooks/pre-commit .git/hooks/commit-msg

# Verify installation
echo ""
echo "✅ Git hooks installed successfully!"
echo ""
echo "📋 Installed hooks:"
echo "   • pre-commit   (comprehensive validation)"
echo "   • commit-msg   (message discipline)"
echo ""
echo "📚 Documentation:"
echo "   • Full guide:  PRE_COMMIT_HOOKS_GUIDE_V2.md"
echo "   • Quick ref:   PRE_COMMIT_HOOKS_QUICK_REF.md"
echo ""
echo "🧪 Test the hooks:"
echo "   ./.git/hooks/pre-commit"
echo ""
echo "⚙️  Install required tools:"
echo "   brew install swiftlint swiftformat"
echo ""

# Check if tools are installed
if ! command -v swiftlint &> /dev/null; then
    echo "⚠️  SwiftLint not installed (install: brew install swiftlint)"
fi

if ! command -v swiftformat &> /dev/null; then
    echo "⚠️  SwiftFormat not installed (install: brew install swiftformat)"
fi

echo "✅ Setup complete!"
