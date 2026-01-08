#!/bin/bash
# Automated batch translation runner
# Runs translations continuously with smart rate limiting and progress tracking

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TRANSLATION_SCRIPT="$SCRIPT_DIR/translate_all_languages.py"
LOG_FILE="$SCRIPT_DIR/translation_batch.log"
PROGRESS_FILE="$SCRIPT_DIR/.translation_progress.json"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
BATCH_DELAY=5           # Seconds between batches
DAILY_LIMIT=4500        # Conservative limit (MyMemory allows 5000/day)
REQUESTS_PER_BATCH=100  # Strings per batch

echo -e "${BLUE}═══════════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}     AUTOMATED TRANSLATION BATCH RUNNER${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════════════${NC}"
echo ""
echo "Configuration:"
echo "  • Daily limit: $DAILY_LIMIT requests"
echo "  • Batch size: $REQUESTS_PER_BATCH strings"
echo "  • Delay between batches: ${BATCH_DELAY}s"
echo "  • Max batches per day: $((DAILY_LIMIT / REQUESTS_PER_BATCH))"
echo ""
echo "Log file: $LOG_FILE"
echo ""
echo -e "${BLUE}═══════════════════════════════════════════════════════════════════${NC}"
echo ""

# Initialize log
echo "[$(date)] Batch translation started" > "$LOG_FILE"

# Counter for requests today
REQUESTS_TODAY=0
BATCHES_RUN=0
START_TIME=$(date +%s)

# Function to run a single batch
run_batch() {
    local batch_num=$1
    
    echo -e "${YELLOW}[Batch $batch_num]${NC} Starting translation batch..."
    echo "[$(date)] Running batch $batch_num" >> "$LOG_FILE"
    
    # Run translation script
    if python3 "$TRANSLATION_SCRIPT" 2>&1 | tee -a "$LOG_FILE"; then
        REQUESTS_TODAY=$((REQUESTS_TODAY + REQUESTS_PER_BATCH))
        BATCHES_RUN=$((BATCHES_RUN + 1))
        
        echo -e "${GREEN}✓${NC} Batch $batch_num complete"
        echo -e "  Requests today: $REQUESTS_TODAY / $DAILY_LIMIT"
        echo ""
        
        return 0
    else
        echo -e "${RED}✗${NC} Batch $batch_num failed"
        return 1
    fi
}

# Function to check if we should continue
should_continue() {
    # Check if we hit daily limit
    if [ $REQUESTS_TODAY -ge $DAILY_LIMIT ]; then
        echo -e "${YELLOW}⚠${NC}  Daily request limit reached ($REQUESTS_TODAY/$DAILY_LIMIT)"
        return 1
    fi
    
    # Check if all languages are complete (script will exit 0 if complete)
    if python3 -c "
import json
from pathlib import Path

xcstrings = Path('$SCRIPT_DIR/SharedCore/DesignSystem/Localizable.xcstrings')
with open(xcstrings) as f:
    data = json.load(f)

strings = data.get('strings', {})
total = len(strings)

# Count languages to translate (all except 'en')
target_languages = 53  # Total languages in APP_STORE_LANGUAGES minus 'en'

# Check if we have at least target_languages complete
complete_count = 0
for lang_code in ['ar','da','de','es','fa','fi','fr','he','is','it','ja','nl','ru','sw','th','uk','vi','zh-HK','zh-Hans','zh-Hant','ko','pt-BR','pt-PT','pl','tr','id','sv','no','ro','cs','hu','el','sk','hr','bg','lt','ms','tl','hi','bn','ta','te','ur','kn','ca','sr','sl','lv','et','mk','sq','ka']:
    translated = sum(1 for s in strings.values() if lang_code in s.get('localizations', {}))
    if translated == total:
        complete_count += 1

if complete_count >= target_languages:
    exit(0)  # All complete
else:
    exit(1)  # More to do
" 2>/dev/null; then
        echo -e "${GREEN}🎉 All languages complete!${NC}"
        return 1
    fi
    
    return 0
}

# Function to show final summary
show_summary() {
    local end_time=$(date +%s)
    local duration=$((end_time - START_TIME))
    local hours=$((duration / 3600))
    local minutes=$(((duration % 3600) / 60))
    local seconds=$((duration % 60))
    
    echo ""
    echo -e "${BLUE}═══════════════════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}     BATCH RUN SUMMARY${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════════════════${NC}"
    echo ""
    echo "Statistics:"
    echo "  • Batches completed: $BATCHES_RUN"
    echo "  • Requests made: $REQUESTS_TODAY"
    echo "  • Duration: ${hours}h ${minutes}m ${seconds}s"
    echo ""
    
    # Show final status
    echo "Final Status:"
    python3 "$TRANSLATION_SCRIPT" --status 2>/dev/null || true
    echo ""
    echo -e "${BLUE}═══════════════════════════════════════════════════════════════════${NC}"
    echo ""
    echo "Log saved to: $LOG_FILE"
}

# Trap Ctrl+C to show summary before exit
trap 'echo ""; echo "Interrupted by user."; show_summary; exit 130' INT TERM

# Main loop
echo "Starting batch processing..."
echo "Press Ctrl+C to stop"
echo ""

BATCH_NUM=1
while should_continue; do
    if run_batch $BATCH_NUM; then
        # Only sleep between batches if we're continuing
        if should_continue; then
            echo "Waiting ${BATCH_DELAY}s before next batch..."
            sleep $BATCH_DELAY
        fi
    else
        echo -e "${RED}Batch failed. Stopping.${NC}"
        break
    fi
    
    BATCH_NUM=$((BATCH_NUM + 1))
done

# Show final summary
show_summary

echo -e "${GREEN}Batch runner finished.${NC}"
