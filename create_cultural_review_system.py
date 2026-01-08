#!/usr/bin/env python3
"""
AI-Powered Cultural Translation Refinement System
Uses Claude/GPT to review and improve translations for cultural appropriateness
"""

import json
import os
import sys
from pathlib import Path
from typing import Dict, List, Tuple
import time

# Cultural refinement prompts for each language
CULTURAL_CONTEXTS = {
    'ko': {
        'name': 'Korean',
        'context': 'Korean culture values respect, hierarchy, and formal/informal speech levels. Ensure translations use appropriate formality (반말/존댓말).',
        'considerations': [
            'Use appropriate honorifics',
            'Match formality level for app UI (usually semi-formal)',
            'Consider Korean study culture and terminology',
            'Avoid direct translations of English idioms'
        ]
    },
    'ja': {
        'name': 'Japanese',
        'context': 'Japanese requires careful consideration of politeness levels (keigo) and cultural nuance.',
        'considerations': [
            'Use appropriate politeness level (丁寧語 for most UI)',
            'Katakana vs Kanji choices for technical terms',
            'Cultural context for educational/study terminology',
            'Avoid overly casual or overly formal language'
        ]
    },
    'zh-cn': {
        'name': 'Chinese (Simplified)',
        'context': 'Mainland Chinese culture and terminology preferences.',
        'considerations': [
            'Use simplified characters appropriate for mainland China',
            'Consider Chinese educational system terminology',
            'Use contemporary internet/app vocabulary',
            'Avoid Taiwan or Hong Kong specific terms'
        ]
    },
    'ar': {
        'name': 'Arabic',
        'context': 'Arabic is RTL and has cultural/religious considerations.',
        'considerations': [
            'Ensure Modern Standard Arabic (MSA) for broad appeal',
            'Cultural sensitivity to Islamic values',
            'Appropriate terminology for educational contexts',
            'Consider gender-neutral options where appropriate'
        ]
    },
    'es': {
        'name': 'Spanish',
        'context': 'Spanish varies across regions (Spain vs Latin America).',
        'considerations': [
            'Use neutral Latin American Spanish for broad appeal',
            'Avoid Spain-specific slang (vosotros, etc.)',
            'Consider terms used across Mexico, Colombia, Argentina',
            'Educational terminology should be universal'
        ]
    },
    'pt': {
        'name': 'Portuguese',
        'context': 'Portuguese for Brazilian market primarily.',
        'considerations': [
            'Brazilian Portuguese (not European)',
            'Use terms familiar to Brazilian students',
            'Consider Brazilian educational system',
            'Avoid Portugal-specific vocabulary'
        ]
    },
    'hi': {
        'name': 'Hindi',
        'context': 'Hindi for Indian market with cultural sensitivity.',
        'considerations': [
            'Use Devanagari script appropriately',
            'Consider Indian educational terminology',
            'Balance Hindi and English loanwords',
            'Cultural sensitivity to diverse Indian contexts'
        ]
    },
    'de': {
        'name': 'German',
        'context': 'German with appropriate formality level.',
        'considerations': [
            'Use informal "du" for modern app UI',
            'Compound words should be natural',
            'Educational terminology for German-speaking countries',
            'Avoid overly formal business German'
        ]
    },
    'fr': {
        'name': 'French',
        'context': 'French with broad francophone appeal.',
        'considerations': [
            'Use "tu" form for modern app (not "vous")',
            'Terminology should work for France, Canada, Africa',
            'Avoid anglicisms where good French exists',
            'Educational terms should be standard French'
        ]
    },
    'ru': {
        'name': 'Russian',
        'context': 'Russian for post-Soviet market.',
        'considerations': [
            'Use informal "ты" for app UI',
            'Modern Russian vocabulary (not Soviet-era)',
            'Educational terminology familiar to Russian students',
            'Cyrillic character usage'
        ]
    },
    'tr': {
        'name': 'Turkish',
        'context': 'Turkish with modern vocabulary.',
        'considerations': [
            'Use modern Turkish (not Ottoman)',
            'Educational terms from Turkish system',
            'Balance Turkish roots vs loanwords',
            'Consider Turkish students\' terminology'
        ]
    }
}

# Add cultural context for remaining languages
ADDITIONAL_CONTEXTS = {
    'pl': 'Polish - formal vs informal address, educational terminology',
    'id': 'Indonesian - Bahasa Indonesia formal register for apps',
    'sv': 'Swedish - informal "du" form, Nordic educational terms',
    'no': 'Norwegian - Bokmål standard, modern terminology',
    'cs': 'Czech - informal address, Central European context',
    'hu': 'Hungarian - agglutinative language, unique grammar',
    'el': 'Greek - modern vs ancient distinctions, educational terms',
    'th': 'Thai - appropriate politeness particles, Buddhist culture',
    'vi': 'Vietnamese - Northern vs Southern dialect neutrality',
    'uk': 'Ukrainian - distinct from Russian, modern terminology',
    'ro': 'Romanian - Latin roots, contemporary vocabulary',
    'hr': 'Croatian - distinct from Serbian, Latin script',
    'bg': 'Bulgarian - Cyrillic, Slavic context',
    'sr': 'Serbian - Cyrillic/Latin, Balkan context',
}

def load_translations(xcstrings_path: Path) -> Dict:
    """Load the xcstrings file"""
    with open(xcstrings_path, 'r', encoding='utf-8') as f:
        return json.load(f)

def save_translations(xcstrings_path: Path, data: Dict):
    """Save the xcstrings file"""
    with open(xcstrings_path, 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, indent=2)

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

def create_cultural_review_prompt(lang_code: str, strings_batch: List[Tuple[str, str]]) -> str:
    """Create a prompt for AI to review translations culturally"""
    
    context = CULTURAL_CONTEXTS.get(lang_code, {})
    lang_name = context.get('name', lang_code.upper())
    cultural_context = context.get('context', f'{lang_name} cultural context')
    considerations = context.get('considerations', [])
    
    prompt = f"""You are a native {lang_name} speaker and expert translator reviewing app UI translations for cultural appropriateness and fluency.

CONTEXT: Student productivity/study app interface
TARGET AUDIENCE: Students aged 15-35 using a mobile app

CULTURAL CONSIDERATIONS for {lang_name}:
{cultural_context}

Key points:
"""
    
    for consideration in considerations:
        prompt += f"- {consideration}\n"
    
    prompt += f"""

TASK: Review these English → {lang_name} translations and:
1. Identify translations that are too literal or culturally awkward
2. Suggest more natural, culturally appropriate alternatives
3. Ensure terminology matches what students actually use
4. Keep the tone consistent (friendly but professional for a study app)

FORMAT YOUR RESPONSE AS JSON:
{{
  "translations_to_improve": [
    {{
      "english": "original English text",
      "current_translation": "current translation",
      "issue": "what's wrong (too literal/awkward/wrong formality/etc)",
      "suggested_improvement": "better translation",
      "reasoning": "why this is more culturally appropriate"
    }}
  ]
}}

ONLY include translations that need improvement. If a translation is already good, skip it.

TRANSLATIONS TO REVIEW:

"""
    
    for idx, (english, translation) in enumerate(strings_batch[:50], 1):
        prompt += f"{idx}. English: \"{english}\"\n"
        prompt += f"   {lang_name}: \"{translation}\"\n\n"
    
    prompt += "\nProvide your review as JSON:"
    
    return prompt

def create_review_guide(xcstrings_path: Path, lang_code: str, output_dir: Path):
    """Create a comprehensive review guide for manual or AI review"""
    
    data = load_translations(xcstrings_path)
    strings = get_language_strings(data, lang_code)
    
    context = CULTURAL_CONTEXTS.get(lang_code, {})
    lang_name = context.get('name', lang_code.upper())
    
    guide_path = output_dir / f"cultural_review_{lang_code}.md"
    
    with open(guide_path, 'w', encoding='utf-8') as f:
        f.write(f"# Cultural Review Guide: {lang_name}\n\n")
        f.write(f"**Language Code**: {lang_code}\n")
        f.write(f"**Total Translations**: {len(strings)}\n")
        f.write(f"**Generated**: {time.strftime('%Y-%m-%d %H:%M')}\n\n")
        
        f.write("## Cultural Context\n\n")
        if context:
            f.write(f"{context.get('context', '')}\n\n")
            f.write("### Key Considerations:\n\n")
            for consideration in context.get('considerations', []):
                f.write(f"- {consideration}\n")
            f.write("\n")
        
        f.write("## Review Instructions\n\n")
        f.write("For each translation below, check:\n\n")
        f.write("1. **Cultural Appropriateness**: Does it sound natural to native speakers?\n")
        f.write("2. **Formality Level**: Is it appropriate for a student app UI?\n")
        f.write("3. **Terminology**: Do students actually use these terms?\n")
        f.write("4. **Context**: Does it fit the educational/productivity context?\n")
        f.write("5. **Length**: Will it fit in UI buttons/labels?\n\n")
        
        f.write("## Translations to Review\n\n")
        f.write("| # | English | Current Translation | Notes |\n")
        f.write("|---|---------|-------------------|-------|\n")
        
        for idx, (english, translation) in enumerate(strings[:100], 1):
            # Escape pipe characters
            english_safe = english.replace('|', '\\|')
            translation_safe = translation.replace('|', '\\|')
            f.write(f"| {idx} | {english_safe} | {translation_safe} | |\n")
        
        if len(strings) > 100:
            f.write(f"\n... and {len(strings) - 100} more translations\n")
    
    return guide_path

def create_ai_review_script(output_dir: Path):
    """Create a script for using Claude/GPT API to review translations"""
    
    script_path = output_dir / "ai_cultural_review.py"
    
    with open(script_path, 'w', encoding='utf-8') as f:
        f.write('''#!/usr/bin/env python3
"""
AI Cultural Review using Claude or GPT API
Requires: pip install anthropic openai
"""

import json
import os
import sys
from pathlib import Path

# Choose your AI provider
USE_CLAUDE = True  # Set to False to use OpenAI instead

if USE_CLAUDE:
    try:
        import anthropic
        CLAUDE_API_KEY = os.getenv('ANTHROPIC_API_KEY')
        if not CLAUDE_API_KEY:
            print("❌ Set ANTHROPIC_API_KEY environment variable")
            print("   Get key from: https://console.anthropic.com/")
            sys.exit(1)
    except ImportError:
        print("❌ Install: pip install anthropic")
        sys.exit(1)
else:
    try:
        import openai
        OPENAI_API_KEY = os.getenv('OPENAI_API_KEY')
        if not OPENAI_API_KEY:
            print("❌ Set OPENAI_API_KEY environment variable")
            sys.exit(1)
        openai.api_key = OPENAI_API_KEY
    except ImportError:
        print("❌ Install: pip install openai")
        sys.exit(1)

def review_with_claude(prompt: str) -> str:
    """Use Claude to review translations"""
    client = anthropic.Anthropic(api_key=CLAUDE_API_KEY)
    
    message = client.messages.create(
        model="claude-3-5-sonnet-20241022",
        max_tokens=4000,
        messages=[
            {"role": "user", "content": prompt}
        ]
    )
    
    return message.content[0].text

def review_with_gpt(prompt: str) -> str:
    """Use GPT-4 to review translations"""
    response = openai.ChatCompletion.create(
        model="gpt-4-turbo-preview",
        messages=[
            {"role": "system", "content": "You are an expert translator and cultural consultant."},
            {"role": "user", "content": prompt}
        ],
        temperature=0.3
    )
    
    return response.choices[0].message.content

def main():
    print("🤖 AI Cultural Translation Review")
    print("="*70)
    
    # Load review prompt from file
    if len(sys.argv) < 2:
        print("Usage: python ai_cultural_review.py <review_prompt_file.txt>")
        sys.exit(1)
    
    prompt_file = Path(sys.argv[1])
    if not prompt_file.exists():
        print(f"❌ File not found: {prompt_file}")
        sys.exit(1)
    
    with open(prompt_file, 'r', encoding='utf-8') as f:
        prompt = f.read()
    
    print(f"📝 Loaded prompt from {prompt_file}")
    print(f"🤖 Using {'Claude' if USE_CLAUDE else 'GPT-4'} for review...")
    print()
    
    try:
        if USE_CLAUDE:
            result = review_with_claude(prompt)
        else:
            result = review_with_gpt(prompt)
        
        print("✅ Review complete!")
        print()
        print(result)
        
        # Save results
        output_file = prompt_file.parent / f"review_results_{prompt_file.stem}.json"
        with open(output_file, 'w', encoding='utf-8') as f:
            f.write(result)
        
        print()
        print(f"💾 Results saved to: {output_file}")
        
    except Exception as e:
        print(f"❌ Error: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()
''')
    
    os.chmod(script_path, 0o755)
    return script_path

def main():
    """Generate cultural review system"""
    
    xcstrings_file = Path(__file__).parent / "SharedCore" / "DesignSystem" / "Localizable.xcstrings"
    output_dir = Path(__file__).parent / "translation_reviews"
    
    if not xcstrings_file.exists():
        print(f"❌ File not found: {xcstrings_file}")
        sys.exit(1)
    
    output_dir.mkdir(exist_ok=True)
    
    print("\n" + "="*70)
    print("🎨 CULTURAL TRANSLATION REFINEMENT SYSTEM")
    print("="*70)
    print()
    print("This system helps you refine machine translations to be")
    print("culturally appropriate and natural-sounding.")
    print()
    print("="*70)
    print()
    
    data = load_translations(xcstrings_file)
    
    # Get all translated languages
    all_langs = set()
    for value in data.get('strings', {}).values():
        all_langs.update(value.get('localizations', {}).keys())
    
    all_langs.discard('en')  # Remove English
    
    print(f"📊 Found {len(all_langs)} translated languages")
    print()
    
    # Generate review guides for priority languages
    priority_langs = ['ko', 'ja', 'zh-cn', 'ar', 'es', 'pt', 'hi', 'de', 'fr', 'ru']
    priority_langs = [lang for lang in priority_langs if lang in all_langs or 
                     any(l for l in all_langs if l.lower().startswith(lang))]
    
    print(f"🎯 Generating cultural review guides for {len(priority_langs)} priority languages...")
    print()
    
    guides_created = []
    for lang in priority_langs:
        # Find matching language in data
        actual_lang = lang
        for l in all_langs:
            if l.lower() == lang.lower() or l.lower().startswith(lang):
                actual_lang = l
                break
        
        try:
            guide_path = create_review_guide(xcstrings_file, actual_lang, output_dir)
            guides_created.append((actual_lang, guide_path))
            
            context = CULTURAL_CONTEXTS.get(lang, {})
            lang_name = context.get('name', actual_lang.upper())
            print(f"✅ {lang_name:20} → {guide_path.name}")
        except Exception as e:
            print(f"⚠️  {lang}: {e}")
    
    print()
    
    # Create AI review script
    ai_script = create_ai_review_script(output_dir)
    print(f"🤖 AI review script  → {ai_script.name}")
    print()
    
    print("="*70)
    print("✅ CULTURAL REVIEW SYSTEM READY!")
    print("="*70)
    print()
    print("📁 Review guides created in:", output_dir)
    print()
    print("🔍 NEXT STEPS:")
    print()
    print("Option 1: Manual Review (FREE)")
    print(f"  • Open files in {output_dir}/")
    print("  • Have native speakers review each language")
    print("  • Mark translations that need improvement")
    print()
    print("Option 2: AI Review (Requires API)")
    print("  • Set up Claude API: export ANTHROPIC_API_KEY=your_key")
    print("  • Or OpenAI API: export OPENAI_API_KEY=your_key")
    print(f"  • Run: python {ai_script}")
    print()
    print("Option 3: Hybrid Approach (RECOMMENDED)")
    print("  • Use AI to flag potential issues quickly")
    print("  • Have native speakers review AI suggestions")
    print("  • Apply improvements to xcstrings file")
    print()
    print("="*70)

if __name__ == "__main__":
    main()
