#!/bin/bash
#
# Verify Git Hooks Installation
#

set -e

REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
cd "$REPO_ROOT"

echo "╔════════════════════════════════════════╗"
echo "║   Git Hooks Verification                ║"
echo "╚════════════════════════════════════════╝"
echo ""

# Check hooks exist
echo "📋 Checking hook files..."
HOOKS_OK=true

if [ -f .git/hooks/pre-commit ]; then
    echo "  ✅ pre-commit exists"
else
    echo "  ❌ pre-commit missing"
    HOOKS_OK=false
fi

if [ -f .git/hooks/commit-msg ]; then
    echo "  ✅ commit-msg exists"
else
    echo "  ❌ commit-msg missing"
    HOOKS_OK=false
fi

# Check hooks are executable
echo ""
echo "🔐 Checking hook permissions..."

if [ -x .git/hooks/pre-commit ]; then
    echo "  ✅ pre-commit is executable"
else
    echo "  ❌ pre-commit not executable"
    HOOKS_OK=false
fi

if [ -x .git/hooks/commit-msg ]; then
    echo "  ✅ commit-msg is executable"
else
    echo "  ❌ commit-msg not executable"
    HOOKS_OK=false
fi

# Check configuration files
echo ""
echo "⚙️  Checking configuration files..."

if [ -f .swiftlint.yml ]; then
    echo "  ✅ .swiftlint.yml exists"
else
    echo "  ⚠️  .swiftlint.yml missing"
fi

if [ -f .swiftformat ]; then
    echo "  ✅ .swiftformat exists"
else
    echo "  ⚠️  .swiftformat missing"
fi

# Check tools installation
echo ""
echo "🛠️  Checking required tools..."

if command -v swiftlint &> /dev/null; then
    VERSION=$(swiftlint version)
    echo "  ✅ swiftlint installed (v$VERSION)"
else
    echo "  ⚠️  swiftlint not installed"
    echo "     Install: brew install swiftlint"
fi

if command -v swiftformat &> /dev/null; then
    VERSION=$(swiftformat --version)
    echo "  ✅ swiftformat installed ($VERSION)"
else
    echo "  ⚠️  swiftformat not installed"
    echo "     Install: brew install swiftformat"
fi

# Test hook execution
echo ""
echo "🧪 Testing hook execution..."

if ./.git/hooks/pre-commit > /dev/null 2>&1; then
    echo "  ✅ pre-commit executes successfully"
else
    echo "  ℹ️  pre-commit requires staged files to test"
fi

# Summary
echo ""
echo "╔════════════════════════════════════════╗"

if [ "$HOOKS_OK" = true ]; then
    echo "║  ✅ All hooks properly installed!      ║"
    echo "║                                        ║"
    echo "║  Try committing to test the hooks.    ║"
else
    echo "║  ⚠️  Some issues found                 ║"
    echo "║                                        ║"
    echo "║  Run: ./Scripts/install-git-hooks.sh   ║"
fi

echo "╚════════════════════════════════════════╝"
echo ""
