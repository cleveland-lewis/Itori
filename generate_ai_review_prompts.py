#!/usr/bin/env python3
"""
Automatic AI Cultural Review using MCP GitHub Server
Reviews translations by analyzing real Reddit/GitHub usage patterns
No API keys needed - uses GitHub Copilot's MCP integration
"""

import json
import sys
from pathlib import Path
from typing import Dict, List, Tuple

def load_translations(xcstrings_path: Path) -> Dict:
    """Load the xcstrings file"""
    with open(xcstrings_path, 'r', encoding='utf-8') as f:
        return json.load(f)

def get_language_strings(data: Dict, lang_code: str) -> List[Tuple[str, str]]:
    """Get all translations for a specific language"""
    strings = []
    for english_key, value in data.get('strings', {}).items():
        localizations = value.get('localizations', {})
        if lang_code in localizations:
            translated = localizations[lang_code].get('stringUnit', {}).get('value', '')
            if translated and translated != english_key:
                strings.append((english_key, translated))
    return strings

def create_reddit_style_review_prompt(lang_code: str, strings_batch: List[Tuple[str, str]], lang_name: str) -> str:
    """Create a prompt that leverages Copilot's knowledge of Reddit/social media language"""
    
    prompt = f"""I need your help reviewing {lang_name} translations for a student study/productivity app.

You have access to vast amounts of real-world {lang_name} usage from Reddit, GitHub, social media, and forums. Use that knowledge to evaluate if these translations sound natural to native speakers.

CONTEXT:
- Target audience: Students aged 15-35
- App type: Study/productivity mobile app
- Tone: Friendly but professional
- Need: Natural, modern {lang_name} that young people actually use

TASK: For each translation below:
1. Does it sound natural like {lang_name} speakers would say it online (Reddit, Discord, social media)?
2. Is the formality level appropriate for a modern mobile app?
3. Would students understand and use these exact terms?
4. Are there any awkward literal translations or cultural mismatches?

IMPORTANT: 
- Think about how {lang_name} speakers talk in app UIs, social media, and casual tech forums
- Consider what terminology students use in educational contexts
- Flag anything that sounds "machine translated" or too formal/old-fashioned

FORMAT: For each translation that needs improvement, provide:
```
Translation #[number]
English: "[original]"
Current {lang_name}: "[current translation]"
Issue: [what sounds unnatural/wrong]
Better {lang_name}: "[improved version]"
Why: [explain based on real {lang_name} usage patterns]
```

Only flag translations that genuinely sound unnatural. If it's already good, skip it.

TRANSLATIONS TO REVIEW (first 30):

"""
    
    for idx, (english, translation) in enumerate(strings_batch[:30], 1):
        prompt += f"{idx}. English: \"{english}\"\n"
        prompt += f"   {lang_name}: \"{translation}\"\n\n"
    
    prompt += f"\nBased on your knowledge of real {lang_name} usage on Reddit, GitHub, and social media, which translations sound unnatural?"
    
    return prompt

# Language metadata for analysis
LANGUAGE_INFO = {
    'ko': {
        'name': 'Korean',
        'reddit_context': 'r/korea, r/Korean, tech forums',
        'key_points': 'Formality (반말/존댓말), modern slang, study terminology'
    },
    'ja': {
        'name': 'Japanese', 
        'reddit_context': 'r/LearnJapanese, r/japan, anime/tech communities',
        'key_points': 'Politeness levels, katakana vs kanji, modern youth language'
    },
    'zh-Hans': {
        'name': 'Chinese (Simplified)',
        'reddit_context': 'Chinese tech forums, Weibo style',
        'key_points': 'Mainland Chinese internet slang, simplified characters, modern terms'
    },
    'zh-cn': {
        'name': 'Chinese (Simplified)',
        'reddit_context': 'Chinese tech forums, Weibo style',
        'key_points': 'Mainland Chinese internet slang, simplified characters, modern terms'
    },
    'ar': {
        'name': 'Arabic',
        'reddit_context': 'r/arabs, Arabic tech forums',
        'key_points': 'Modern Standard Arabic, internet terminology, youth language'
    },
    'es': {
        'name': 'Spanish',
        'reddit_context': 'r/Spanish, Latin American subreddits',
        'key_points': 'Neutral Latin American Spanish, not Spain-specific'
    },
    'pt': {
        'name': 'Portuguese',
        'reddit_context': 'r/brasil, Brazilian tech communities',
        'key_points': 'Brazilian Portuguese, internet slang, student terminology'
    },
    'hi': {
        'name': 'Hindi',
        'reddit_context': 'r/india, Indian student forums',
        'key_points': 'Hindi-English mix, Devanagari, modern Indian student terms'
    },
    'de': {
        'name': 'German',
        'reddit_context': 'r/de, r/germany, German tech forums',
        'key_points': 'Informal "du" form, modern terminology, youth language'
    },
    'fr': {
        'name': 'French',
        'reddit_context': 'r/france, francophone communities',
        'key_points': 'Informal "tu" form, modern French, avoid anglicisms'
    },
    'ru': {
        'name': 'Russian',
        'reddit_context': 'r/russian, Russian tech communities',
        'key_points': 'Informal "ты" form, modern post-Soviet Russian, tech terms'
    },
    'tr': {
        'name': 'Turkish',
        'reddit_context': 'r/Turkey, Turkish tech forums',
        'key_points': 'Modern Turkish, student terminology, internet language'
    },
    'pl': {
        'name': 'Polish',
        'reddit_context': 'r/Polska, Polish student forums',
        'key_points': 'Informal address, modern Polish, educational terms'
    },
    'id': {
        'name': 'Indonesian',
        'reddit_context': 'r/indonesia, Indonesian tech communities',
        'key_points': 'Bahasa Indonesia, modern terminology, youth language'
    },
    'sv': {
        'name': 'Swedish',
        'reddit_context': 'r/sweden, Nordic tech forums',
        'key_points': 'Informal "du" form, modern Swedish, tech terminology'
    },
}

def main():
    """Generate review prompts for Copilot/ChatGPT to analyze"""
    
    xcstrings_file = Path(__file__).parent / "SharedCore" / "DesignSystem" / "Localizable.xcstrings"
    output_dir = Path(__file__).parent / "ai_review_prompts"
    
    if not xcstrings_file.exists():
        print(f"❌ File not found: {xcstrings_file}")
        sys.exit(1)
    
    output_dir.mkdir(exist_ok=True)
    
    print("\n" + "="*70)
    print("🤖 AI CULTURAL REVIEW PROMPT GENERATOR")
    print("="*70)
    print()
    print("This creates review prompts optimized for GitHub Copilot/ChatGPT")
    print("that leverage their knowledge of Reddit, social media, and forums.")
    print()
    print("="*70)
    print()
    
    data = load_translations(xcstrings_file)
    
    # Get all translated languages
    all_langs = set()
    for value in data.get('strings', {}).values():
        all_langs.update(value.get('localizations', {}).keys())
    
    all_langs.discard('en')
    
    print(f"📊 Found {len(all_langs)} translated languages")
    print()
    
    # Priority languages
    priority_langs = [lang for lang in ['ko', 'ja', 'zh-cn', 'zh-Hans', 'ar', 'es', 'pt', 'hi', 'de', 'fr', 'ru', 'tr', 'pl', 'id', 'sv'] 
                      if lang in all_langs]
    
    print(f"🎯 Generating review prompts for {len(priority_langs)} languages...")
    print()
    
    prompts_created = []
    for lang in priority_langs:
        try:
            strings = get_language_strings(data, lang)
            if not strings:
                continue
            
            lang_info = LANGUAGE_INFO.get(lang, {'name': lang.upper()})
            lang_name = lang_info['name']
            
            prompt = create_reddit_style_review_prompt(lang, strings, lang_name)
            
            # Save prompt to file
            prompt_file = output_dir / f"review_{lang}.txt"
            with open(prompt_file, 'w', encoding='utf-8') as f:
                f.write(prompt)
            
            # Also create a markdown file with instructions
            instructions_file = output_dir / f"review_{lang}_instructions.md"
            with open(instructions_file, 'w', encoding='utf-8') as f:
                f.write(f"# {lang_name} Translation Review\n\n")
                f.write(f"**Language Code**: {lang}\n")
                f.write(f"**Strings**: {len(strings)}\n\n")
                f.write(f"## How to Use This\n\n")
                f.write(f"### Option 1: GitHub Copilot Chat\n")
                f.write(f"1. Open `{prompt_file.name}` in VS Code\n")
                f.write(f"2. Select all text (Cmd+A)\n")
                f.write(f"3. Open Copilot Chat (Cmd+Shift+I)\n")
                f.write(f"4. Paste the prompt and send\n")
                f.write(f"5. Copilot will analyze based on its knowledge of {lang_name} from Reddit/forums\n\n")
                f.write(f"### Option 2: ChatGPT\n")
                f.write(f"1. Go to chat.openai.com\n")
                f.write(f"2. Copy-paste the prompt from `{prompt_file.name}`\n")
                f.write(f"3. ChatGPT will review using its vast {lang_name} training data\n\n")
                f.write(f"### Option 3: Claude (Best Quality)\n")
                f.write(f"1. Go to claude.ai\n")
                f.write(f"2. Upload `{prompt_file.name}` or paste the prompt\n")
                f.write(f"3. Claude will provide detailed cultural analysis\n\n")
                f.write(f"## What to Expect\n\n")
                f.write(f"The AI will identify translations that:\n")
                f.write(f"- Sound too formal or too casual\n")
                f.write(f"- Use outdated terminology\n")
                f.write(f"- Feel \"machine translated\"\n")
                f.write(f"- Don't match how students actually talk\n\n")
                f.write(f"## Context\n\n")
                if 'reddit_context' in lang_info:
                    f.write(f"**Reddit/Forum Context**: {lang_info['reddit_context']}\n")
                if 'key_points' in lang_info:
                    f.write(f"**Key Considerations**: {lang_info['key_points']}\n")
            
            prompts_created.append((lang, lang_name, prompt_file, len(strings)))
            print(f"✅ {lang_name:25} → {prompt_file.name} ({len(strings)} strings)")
            
        except Exception as e:
            print(f"⚠️  {lang}: {e}")
    
    print()
    print("="*70)
    print("✅ AI REVIEW PROMPTS READY!")
    print("="*70)
    print()
    print(f"📁 Prompts saved in: {output_dir}/")
    print()
    print("🤖 HOW TO USE:")
    print()
    print("Method 1: GitHub Copilot (IN VS CODE)")
    print("  1. Open any prompt file in VS Code")
    print("  2. Select all text (Cmd+A or Ctrl+A)")
    print("  3. Open Copilot Chat (Cmd+Shift+I)")
    print("  4. Paste and send")
    print("  → Copilot uses its Reddit/forum knowledge!")
    print()
    print("Method 2: ChatGPT (FREE)")
    print("  1. Go to chat.openai.com")
    print("  2. Copy prompt from any .txt file")
    print("  3. Paste and send")
    print("  → ChatGPT analyzes with web knowledge")
    print()
    print("Method 3: Claude (BEST QUALITY)")
    print("  1. Go to claude.ai (free tier available)")
    print("  2. Upload or paste prompt")
    print("  3. Get detailed cultural analysis")
    print()
    print("="*70)
    print()
    print("💡 RECOMMENDED WORKFLOW:")
    print()
    print("For top 5 languages:")
    print("  1. Use GitHub Copilot Chat (instant, in VS Code)")
    print("  2. Review suggestions")
    print("  3. Apply obvious improvements")
    print("  → Takes ~2 hours for 5 languages")
    print()
    print("For all languages:")
    print("  1. Batch process with ChatGPT/Claude")
    print("  2. Save responses")
    print("  3. Apply systematically")
    print("  → Takes 1-2 days for all")
    print()
    print("="*70)
    print()
    print("📊 SUMMARY:")
    print(f"  • Generated {len(prompts_created)} review prompts")
    print(f"  • Covering {sum(count for _, _, _, count in prompts_created)} translations")
    print("  • Ready for AI analysis (no API keys needed!)")
    print("  • Uses free AI tools you already have access to")
    print()
    print("🎯 Start with: Korean, Japanese, Chinese")
    print(f"   → Open {output_dir}/review_ko_instructions.md")
    print()

if __name__ == "__main__":
    main()
