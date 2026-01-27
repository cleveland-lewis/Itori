#!/bin/bash
#
# Markdown Consolidation Audit
# Identifies markdown files that should be consolidated into allowed files
#

set -euo pipefail

REPO_ROOT="/Users/clevelandlewis/Desktop/Itori"
cd "$REPO_ROOT"

# Allowed markdown files
ALLOWED_FILES=(
    "README.md"
    "CHANGELOG.md"
    "BACKLOG.md"
    "PRIVACY_POLICY.md"
    "PRIVACY_POLICY_ENHANCED.md"
)

# Output file
REPORT="MARKDOWN_AUDIT_REPORT_$(date +%Y%m%d_%H%M%S).md"

echo "# Markdown Files Audit - $(date)" > "$REPORT"
echo "" >> "$REPORT"
echo "This report identifies markdown files that violate the project rule:" >> "$REPORT"
echo "**Only the following markdown files are allowed at root level:**" >> "$REPORT"
for file in "${ALLOWED_FILES[@]}"; do
    echo "- $file" >> "$REPORT"
done
echo "" >> "$REPORT"
echo "All other documentation should be consolidated into these files or removed." >> "$REPORT"
echo "" >> "$REPORT"
echo "---" >> "$REPORT"
echo "" >> "$REPORT"

# Find all markdown files
MARKDOWN_FILES=$(find . -name "*.md" -type f | grep -v node_modules | grep -v ".build" | grep -v ".git" | sort)
MARKDOWN_COUNT=$(echo "$MARKDOWN_FILES" | wc -l)

# Categorize files
declare -a TO_DELETE=()
declare -a TO_CONSOLIDATE_CHANGELOG=()
declare -a TO_CONSOLIDATE_BACKLOG=()
declare -a TO_CONSOLIDATE_DOCS=()
declare -a ALLOWED=()

for file in $MARKDOWN_FILES; do
    basename_file=$(basename "$file")
    
    # Check if allowed
    is_allowed=false
    for allowed in "${ALLOWED_FILES[@]}"; do
        if [ "$basename_file" == "$allowed" ] && [ "$file" == "./$allowed" ]; then
            is_allowed=true
            ALLOWED+=("$file")
            break
        fi
    done
    
    [ "$is_allowed" = true ] && continue
    
    # Categorize by content/location
    if [[ "$file" =~ (STATUS|SUMMARY|COMPLETE|PROGRESS|FINAL|SESSION|PHASE) ]]; then
        TO_DELETE+=("$file")
    elif [[ "$file" =~ (GUIDE|INSTRUCTIONS|SETUP|QUICK|CREDITS|TROUBLESHOOTING) ]]; then
        TO_CONSOLIDATE_DOCS+=("$file")
    elif [[ "$file" =~ (ROADMAP|PLAN|IMPLEMENTATION|ARCHITECTURE|REFERENCE) ]]; then
        TO_CONSOLIDATE_BACKLOG+=("$file")
    elif [[ "$file" =~ (FIX|REPORT|ANALYSIS|AUDIT|INDEX) ]]; then
        TO_CONSOLIDATE_CHANGELOG+=("$file")
    else
        TO_CONSOLIDATE_DOCS+=("$file")
    fi
done

# Report statistics
echo "## Summary Statistics" >> "$REPORT"
echo "" >> "$REPORT"
echo "- **Total markdown files found:** $MARKDOWN_COUNT" >> "$REPORT"
echo "- **Allowed files:** ${#ALLOWED[@]}" >> "$REPORT"
echo "- **Files to delete:** ${#TO_DELETE[@]}" >> "$REPORT"
echo "- **Files to consolidate into CHANGELOG:** ${#TO_CONSOLIDATE_CHANGELOG[@]}" >> "$REPORT"
echo "- **Files to consolidate into BACKLOG:** ${#TO_CONSOLIDATE_BACKLOG[@]}" >> "$REPORT"
echo "- **Files to consolidate into Docs:** ${#TO_CONSOLIDATE_DOCS[@]}" >> "$REPORT"
echo "" >> "$REPORT"
echo "---" >> "$REPORT"
echo "" >> "$REPORT"

# Category 1: Files to Delete (obsolete status files)
if [ ${#TO_DELETE[@]} -gt 0 ]; then
    echo "## ❌ Files to Delete (Obsolete)" >> "$REPORT"
    echo "" >> "$REPORT"
    echo "These are temporary status files that are no longer needed:" >> "$REPORT"
    echo "" >> "$REPORT"
    for file in "${TO_DELETE[@]}"; do
        size=$(wc -l < "$file" 2>/dev/null || echo "0")
        echo "- \`$file\` ($size lines)" >> "$REPORT"
    done
    echo "" >> "$REPORT"
    echo "**Action:** Delete these files" >> "$REPORT"
    echo '```bash' >> "$REPORT"
    for file in "${TO_DELETE[@]}"; do
        echo "rm \"$file\"" >> "$REPORT"
    done
    echo '```' >> "$REPORT"
    echo "" >> "$REPORT"
    echo "---" >> "$REPORT"
    echo "" >> "$REPORT"
fi

# Category 2: Consolidate into CHANGELOG
if [ ${#TO_CONSOLIDATE_CHANGELOG[@]} -gt 0 ]; then
    echo "## 📝 Consolidate into CHANGELOG.md" >> "$REPORT"
    echo "" >> "$REPORT"
    echo "These files document completed work and should be added to CHANGELOG:" >> "$REPORT"
    echo "" >> "$REPORT"
    for file in "${TO_CONSOLIDATE_CHANGELOG[@]}"; do
        size=$(wc -l < "$file" 2>/dev/null || echo "0")
        echo "### \`$file\` ($size lines)" >> "$REPORT"
        echo "" >> "$REPORT"
        echo "**Preview:**" >> "$REPORT"
        echo '```' >> "$REPORT"
        head -10 "$file" 2>/dev/null || echo "[Empty file]"
        echo '```' >> "$REPORT"
        echo "" >> "$REPORT"
    done
    echo "**Action:** Extract relevant content and add to CHANGELOG.md, then delete" >> "$REPORT"
    echo "" >> "$REPORT"
    echo "---" >> "$REPORT"
    echo "" >> "$REPORT"
fi

# Category 3: Consolidate into BACKLOG
if [ ${#TO_CONSOLIDATE_BACKLOG[@]} -gt 0 ]; then
    echo "## 📋 Consolidate into BACKLOG.md" >> "$REPORT"
    echo "" >> "$REPORT"
    echo "These files contain future plans that should be tracked in BACKLOG:" >> "$REPORT"
    echo "" >> "$REPORT"
    for file in "${TO_CONSOLIDATE_BACKLOG[@]}"; do
        size=$(wc -l < "$file" 2>/dev/null || echo "0")
        echo "### \`$file\` ($size lines)" >> "$REPORT"
        echo "" >> "$REPORT"
        echo "**Preview:**" >> "$REPORT"
        echo '```' >> "$REPORT"
        head -10 "$file" 2>/dev/null || echo "[Empty file]"
        echo '```' >> "$REPORT"
        echo "" >> "$REPORT"
    done
    echo "**Action:** Extract relevant tasks and add to BACKLOG.md, then delete" >> "$REPORT"
    echo "" >> "$REPORT"
    echo "---" >> "$REPORT"
    echo "" >> "$REPORT"
fi

# Category 4: Consolidate into single Docs file
if [ ${#TO_CONSOLIDATE_DOCS[@]} -gt 0 ]; then
    echo "## 📚 Consolidate Documentation" >> "$REPORT"
    echo "" >> "$REPORT"
    echo "These files contain documentation that should be in code comments, README, or removed:" >> "$REPORT"
    echo "" >> "$REPORT"
    for file in "${TO_CONSOLIDATE_DOCS[@]}"; do
        size=$(wc -l < "$file" 2>/dev/null || echo "0")
        echo "### \`$file\` ($size lines)" >> "$REPORT"
        echo "" >> "$REPORT"
        echo "**Preview:**" >> "$REPORT"
        echo '```' >> "$REPORT"
        head -10 "$file" 2>/dev/null || echo "[Empty file]"
        echo '```' >> "$REPORT"
        echo "" >> "$REPORT"
    done
    echo "**Action:** Move essential info to README.md or inline code comments, then delete" >> "$REPORT"
    echo "" >> "$REPORT"
    echo "---" >> "$REPORT"
    echo "" >> "$REPORT"
fi

# Generate cleanup script
CLEANUP_SCRIPT="cleanup_markdown.sh"
echo "#!/bin/bash" > "$CLEANUP_SCRIPT"
echo "#" >> "$CLEANUP_SCRIPT"
echo "# Auto-generated markdown cleanup script" >> "$CLEANUP_SCRIPT"
echo "# Generated: $(date)" >> "$CLEANUP_SCRIPT"
echo "#" >> "$CLEANUP_SCRIPT"
echo "" >> "$CLEANUP_SCRIPT"
echo "set -euo pipefail" >> "$CLEANUP_SCRIPT"
echo "" >> "$CLEANUP_SCRIPT"
echo "echo 'Cleaning up unauthorized markdown files...'" >> "$CLEANUP_SCRIPT"
echo "" >> "$CLEANUP_SCRIPT"

ALL_TO_REMOVE=("${TO_DELETE[@]}" "${TO_CONSOLIDATE_CHANGELOG[@]}" "${TO_CONSOLIDATE_BACKLOG[@]}" "${TO_CONSOLIDATE_DOCS[@]}")
for file in "${ALL_TO_REMOVE[@]}"; do
    echo "echo 'Removing $file'" >> "$CLEANUP_SCRIPT"
    echo "rm -f \"$file\"" >> "$CLEANUP_SCRIPT"
done

echo "" >> "$CLEANUP_SCRIPT"
echo "echo 'Cleanup complete!'" >> "$CLEANUP_SCRIPT"
echo "echo 'Total files removed: ${#ALL_TO_REMOVE[@]}'" >> "$CLEANUP_SCRIPT"

chmod +x "$CLEANUP_SCRIPT"

echo "## Cleanup Script Generated" >> "$REPORT"
echo "" >> "$REPORT"
echo "A cleanup script has been generated: \`$CLEANUP_SCRIPT\`" >> "$REPORT"
echo "" >> "$REPORT"
echo "**⚠️  WARNING:** Review this report carefully before running the cleanup script!" >> "$REPORT"
echo "" >> "$REPORT"
echo "To execute cleanup:" >> "$REPORT"
echo '```bash' >> "$REPORT"
echo "./$CLEANUP_SCRIPT" >> "$REPORT"
echo '```' >> "$REPORT"
echo "" >> "$REPORT"

echo "✅ Audit complete!"
echo "📄 Report saved to: $REPORT"
echo "🧹 Cleanup script saved to: $CLEANUP_SCRIPT"
echo ""
echo "Found ${#ALL_TO_REMOVE[@]} files that violate the markdown policy"
