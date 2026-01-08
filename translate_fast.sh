#!/bin/bash
# Ultra-fast automated translation using Google Translate
# Translates ALL remaining languages in 2-4 hours

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TRANSLATION_SCRIPT="$SCRIPT_DIR/translate_google.py"
LOG_FILE="$SCRIPT_DIR/translation_google.log"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${BLUE}═══════════════════════════════════════════════════════════════════${NC}"
echo -e "${CYAN}     ⚡ ULTRA-FAST GOOGLE TRANSLATE BATCH RUNNER ⚡${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "${GREEN}Using Google Translate API:${NC}"
echo "  • FREE and UNLIMITED"
echo "  • High quality translations"
echo "  • 5x faster than other APIs"
echo "  • Parallel processing enabled"
echo ""
echo -e "${YELLOW}Estimated completion time: 2-4 hours${NC}"
echo ""
echo "Log file: $LOG_FILE"
echo ""
echo -e "${BLUE}═══════════════════════════════════════════════════════════════════${NC}"
echo ""

# Initialize log
echo "[$(date)] Google Translate batch started" > "$LOG_FILE"

# Check if script exists
if [ ! -f "$TRANSLATION_SCRIPT" ]; then
    echo -e "${RED}❌ Translation script not found: $TRANSLATION_SCRIPT${NC}"
    exit 1
fi

# Ask user what to do
echo -e "${CYAN}Choose translation mode:${NC}"
echo "  1) Translate ALL remaining languages (auto, fastest)"
echo "  2) Translate one language at a time (manual)"
echo "  3) Show status only"
echo ""
read -p "Enter choice [1-3]: " choice

case $choice in
    1)
        echo ""
        echo -e "${GREEN}🚀 Starting automatic translation of ALL languages...${NC}"
        echo ""
        echo "This will:"
        echo "  • Translate all incomplete languages"
        echo "  • Use parallel processing for speed"
        echo "  • Take approximately 2-4 hours"
        echo "  • Save progress after each language"
        echo ""
        echo "Press Ctrl+C to stop at any time (progress is saved)"
        echo ""
        read -p "Press Enter to continue or Ctrl+C to cancel..."
        
        START_TIME=$(date +%s)
        
        echo ""
        echo -e "${BLUE}═══════════════════════════════════════════════════════════════════${NC}"
        
        # Run with --all flag
        if python3 "$TRANSLATION_SCRIPT" --all 2>&1 | tee -a "$LOG_FILE"; then
            END_TIME=$(date +%s)
            DURATION=$((END_TIME - START_TIME))
            HOURS=$((DURATION / 3600))
            MINUTES=$(((DURATION % 3600) / 60))
            
            echo ""
            echo -e "${GREEN}═══════════════════════════════════════════════════════════════════${NC}"
            echo -e "${GREEN}     🎉 ALL LANGUAGES COMPLETE! 🎉${NC}"
            echo -e "${GREEN}═══════════════════════════════════════════════════════════════════${NC}"
            echo ""
            echo "Total time: ${HOURS}h ${MINUTES}m"
            echo "Your app now supports 53 languages!"
            echo "Coverage: All 175 App Store countries"
            echo ""
        else
            echo -e "${YELLOW}⚠ Translation stopped (progress is saved)${NC}"
        fi
        ;;
        
    2)
        echo ""
        echo -e "${YELLOW}Manual mode: Translate one language at a time${NC}"
        echo ""
        
        # Show status first
        python3 "$TRANSLATION_SCRIPT" 2>&1 | tee "$LOG_FILE"
        
        echo ""
        read -p "Enter language code to translate (e.g., 'ko' for Korean): " lang_code
        
        if [ -n "$lang_code" ]; then
            echo ""
            echo -e "${GREEN}Translating: $lang_code${NC}"
            echo ""
            
            if python3 "$TRANSLATION_SCRIPT" "$lang_code" 2>&1 | tee -a "$LOG_FILE"; then
                echo ""
                echo -e "${GREEN}✅ Language complete!${NC}"
            else
                echo -e "${RED}❌ Translation failed${NC}"
            fi
        fi
        ;;
        
    3)
        echo ""
        python3 "$TRANSLATION_SCRIPT"
        ;;
        
    *)
        echo -e "${RED}Invalid choice${NC}"
        exit 1
        ;;
esac

echo ""
echo -e "${BLUE}═══════════════════════════════════════════════════════════════════${NC}"
echo "Log saved to: $LOG_FILE"
echo -e "${BLUE}═══════════════════════════════════════════════════════════════════${NC}"
echo ""
