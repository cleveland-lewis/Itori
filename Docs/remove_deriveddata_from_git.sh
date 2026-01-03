#!/bin/bash

# Script to remove .derivedData from git tracking
# Run this from your project root directory

echo "Removing .derivedData from git tracking..."

# Remove from git index (keeps local files)
git rm -r --cached .derivedData

echo ""
echo "✅ Removed .derivedData from git tracking"
echo ""
echo "Now commit and push:"
echo "  git commit -m 'Remove .derivedData from version control'"
echo "  git push origin main"
echo ""
echo "The .derivedData directory is already in .gitignore and will not be tracked again."
