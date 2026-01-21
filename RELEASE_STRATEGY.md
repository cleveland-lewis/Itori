# Itori Release Strategy

## Current Status
- **Current Version**: 1.0.0 (in VERSION file)
- **Current State**: Development with unreleased features

---

## Release Plan

### Phase 1: v1.1.0 - Distribution Build (Base Version)
**Target**: First App Store release
**Status**: Ready to prepare
**Timeline**: 1-2 days

**Features INCLUDED:**
- ✅ Core planner functionality
- ✅ Course management
- ✅ Assignment tracking
- ✅ Timer/Pomodoro
- ✅ Calendar integration
- ✅ Study analytics
- ✅ Auto-scheduling
- ✅ iCloud sync
- ✅ Syllabus PDF parsing
- ✅ Dashboard improvements
- ⚠️ **Flashcards: BASIC** (current state)

**Features EXCLUDED:**
- ❌ Practice test feature (completely removed)
- ❌ Practice test page/tab
- ❌ Practice test generation
- ❌ Practice test taking UI
- ❌ Practice test scheduling in planner
- ⚠️ **Users take exams externally** (on paper, in class, other platforms)

**Changes Needed:**
1. Remove "Practice" tab from navigation (macOS + iOS)
2. Remove PracticeTestPageView entirely
3. Remove PracticeTestGeneratorView entirely
4. Remove PracticeTestStore and related models (keep in codebase, don't initialize)
5. Disable practice test scheduling in PlannerEngine
6. Remove practice test references from Dashboard
7. Update marketing materials: "Plan your study schedule, track assignments, manage courses"

---

### Phase 2: v2.0.0 - Practice Test Generation
**Target**: Major update with AI features
**Status**: Code exists, needs refinement
**Timeline**: 2-4 weeks after v1.1

**New Features:**
- ✅ AI-powered practice test generation
- ✅ Web-enhanced question creation (DuckDuckGo/Wikipedia)
- ✅ Progress tracking with time estimation
- ✅ Multiple question types
- ✅ Difficulty levels
- ✅ Bloom's taxonomy integration
- ✅ Export/import practice tests

**Requirements:**
- User configures their own LLM (Ollama/MLX/OpenAI)
- Network access required
- macOS only (iOS view-only)

---

### Phase 3: v3.0.0 - Advanced Flashcards
**Target**: Complete learning toolkit
**Status**: Planning phase
**Timeline**: 4-8 weeks after v2.0

**New Features:**
- Spaced repetition algorithm (SM-2 or Leitner)
- Card decks with categories
- Import from Anki/Quizlet
- Text-to-speech for cards
- Image support
- Progress tracking and analytics
- Study session recommendations
- Card generation from notes/assignments

---

## Implementation Steps for v1.1.0

### Step 1: Create Release Branch
```bash
git checkout -b release/v1.1.0
```

### Step 2: Version Bump
- Update VERSION file: `1.0.0` → `1.1.0`
- Update Xcode project marketing version
- Update Info.plist versions

### Step 3: Remove Practice Test Feature Completely
**Files to DELETE or DISABLE:**
- [ ] Remove "Practice" from navigation tabs (macOS sidebar + iOS tab bar)
- [ ] `Platforms/macOS/Scenes/PracticeTestPageView.swift` - Don't compile
- [ ] `Platforms/iOS/Scenes/IOSPracticeTestGeneratorView.swift` - Don't compile
- [ ] `Platforms/iOS/Scenes/IOSPracticeTestTakingView.swift` - Don't compile
- [ ] `Platforms/iOS/Scenes/IOSPracticeTestResultsView.swift` - Don't compile
- [ ] `Platforms/macOS/Views/PracticeTestGeneratorView.swift` - Don't compile
- [ ] `Platforms/macOS/Views/PracticeTestTakingView.swift` - Don't compile
- [ ] `Platforms/macOS/Views/PracticeTestResultsView.swift` - Don't compile

**Files to KEEP (but don't initialize):**
- [ ] `SharedCore/State/PracticeTestStore.swift` - Keep for v2.0
- [ ] `SharedCore/Models/PracticeTestModels.swift` - Keep for v2.0
- [ ] `SharedCore/Services/FeatureServices/WebEnhancedTestGenerator.swift` - Keep for v2.0
- [ ] `SharedCore/Services/FeatureServices/AlgorithmicTestGenerator.swift` - Keep for v2.0

**Files to MODIFY:**
- [ ] Remove PracticeTestStore initialization from AppModel/AppShell
- [ ] Remove Practice tab from TabConfiguration
- [ ] Remove practice test icon/badge from navigation

### Step 4: Disable Practice Test Scheduling in Planner
**Files to modify:**
- [ ] `SharedCore/Services/FeatureServices/PlannerEngine.swift` - Comment out practice test scheduling
- [ ] `SharedCore/Services/FeatureServices/PlannerService+Generation.swift` - Disable test suggestions

### Step 5: Update CHANGELOG
Move all unreleased items to [1.1.0] section

### Step 6: Build & Test
- [ ] Clean build for macOS
- [ ] Clean build for iOS
- [ ] Test all core features
- [ ] Test practice test import
- [ ] Verify no generation UI appears

### Step 7: Archive & Notarize
```bash
# Build archive
xcodebuild archive \
  -project ItoriApp.xcodeproj \
  -scheme Itori \
  -destination 'platform=macOS' \
  -archivePath ./build/Itori.xcarchive

# Export for App Store
xcodebuild -exportArchive \
  -archivePath ./build/Itori.xcarchive \
  -exportPath ./build/Export \
  -exportOptionsPlist ExportOptions.plist

# Notarize (requires Apple Developer account)
xcrun notarytool submit ./build/Export/Itori.pkg \
  --apple-id "your@email.com" \
  --team-id "TEAM_ID" \
  --password "app-specific-password"
```

### Step 8: App Store Submission
- [ ] Upload via Xcode or Transporter
- [ ] Fill out App Store metadata
- [ ] Add screenshots
- [ ] Submit for review

---

## Implementation Steps for v2.0.0

### Step 1: Create Feature Branch
```bash
git checkout -b feature/practice-test-generation
git checkout main  # or release/v1.1.0
git merge feature/practice-test-generation
```

### Step 2: Re-enable Practice Test Features
- [ ] Restore `PracticeTestGeneratorView.swift`
- [ ] Update UI to show generation option
- [ ] Add LLM configuration in Settings
- [ ] Add user onboarding for LLM setup

### Step 3: Add LLM Setup UI
**New files:**
- [ ] `Platforms/macOS/Views/Settings/LLMSetupView.swift`
- [ ] Guide for installing Ollama/MLX
- [ ] Connection testing

### Step 4: Version Bump
- Update to 2.0.0
- Major CHANGELOG update

### Step 5: Beta Testing
- TestFlight for macOS
- Gather feedback on LLM integration

---

## Implementation Steps for v3.0.0

### Step 1: Design Flashcard System
- [ ] Data models
- [ ] Spaced repetition algorithm
- [ ] UI/UX mockups

### Step 2: Implement Core Features
(Detailed plan TBD)

---

## Marketing Version Naming

### App Store Display
- **v1.1**: "Itori - Student Planner"
- **v2.0**: "Itori - AI Study Assistant"
- **v3.0**: "Itori - Complete Learning Toolkit"

**What's New in App Store:**
**v1.1:**
```
• Intelligent course planning and scheduling
• Automatic assignment detection from syllabi
• Calendar integration and sync
• Study timer with Pomodoro technique
• Track courses, assignments, and deadlines
• Dark mode support
• iCloud sync across devices

Note: Practice test features coming in v2.0!
Users can track exam dates and study for tests externally.
```

**v2.0:**
```
• 🤖 AI-powered practice test generation
• 🌐 Web-enhanced question research
• ⏱️ Real-time progress tracking
• 📊 Advanced analytics
• 🎯 Difficulty customization
```

**v3.0:**
```
• 🃏 Advanced flashcard system
• 🧠 Spaced repetition learning
• 📥 Import from Anki/Quizlet
• 📸 Image support
• 🎤 Text-to-speech
```

---

## Branching Strategy

```
main (stable)
├── release/v1.1.0 (distribution)
├── release/v2.0.0 (practice tests)
└── release/v3.0.0 (flashcards)

develop (active development)
├── feature/practice-test-import (v1.1)
├── feature/llm-integration (v2.0)
└── feature/flashcards-v3 (v3.0)
```

---

## Questions to Answer

1. **Do you have an Apple Developer account?**
   - Needed for: App Store distribution, notarization, TestFlight

2. **Which platforms to prioritize?**
   - macOS only?
   - iOS + macOS?
   - iPadOS?

3. **Pricing strategy?**
   - Free with IAP?
   - One-time purchase?
   - Subscription?

4. **Beta testing?**
   - TestFlight?
   - Public beta?

5. **LLM requirement for v2.0?**
   - Require users to set up their own (Ollama/MLX)?
   - Or provide cloud API option?

---

## Next Immediate Steps

1. **Confirm**: Remove practice test generation for v1.1?
2. **Decide**: Keep basic flashcards or remove completely for v1.1?
3. **Choose**: Start with macOS-only or iOS too?
4. **Create**: Release branch and start version bump?

Let me know your answers and I'll start implementing!
