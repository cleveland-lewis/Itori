# iOS Practice Test UI - Quick Reference

## Overview
Complete iOS UI for AI-powered practice test generation with 5-choice (A-E) multiple-choice questions.

## New Files

### UI Views (Platforms/iOS/Scenes/)
1. **IOSPracticeTestGeneratorView.swift** - Test configuration and generation
2. **IOSPracticeTestTakingView.swift** - Interactive test-taking experience  
3. **IOSPracticeTestResultsView.swift** - Score display and answer review

### Updated Files
4. **IOSCorePages.swift** - Enhanced IOSPracticeView with new features
5. **LocalLLMService.swift** - 5-choice question generation
6. **AlgorithmicTestGenerator.swift** - 5-choice fallback questions
7. **QuestionValidator.swift** - 5-choice validation rules

## Key Features

### Test Generation
- Course selection picker
- Optional topic tags (add/remove)
- Difficulty selector (Easy/Medium/Hard)
- Question count (5, 10, 15, 20, 25)
- Automatic AI generation via LLM backends

### Test Taking
- Full-screen immersive mode
- A-E answer buttons with letter labels
- Progress tracking (X/Y answered)
- Previous/Next navigation
- Auto-advance after selection
- Submit with confirmation dialog

### Results Review
- Large score percentage display
- Color-coded performance (🟢🔵🟠🔴)
- Score interpretation message
- Test statistics (course, difficulty, date)
- Expandable question review cards
- Answer explanations for learning

### Practice Hub
- Generate new test button
- Current test status cards:
  - Generating (progress spinner)
  - Ready (play button)
  - In Progress (progress bar)
  - Completed (score badge)
  - Failed (retry button)
- Recent tests list (last 5)
- Statistics summary (tests/score/questions)

## Usage Examples

### Generate a Test
```swift
// User flow:
// 1. Tap "+" in Practice tab
// 2. Select course
// 3. (Optional) Add topics
// 4. Choose difficulty
// 5. Select question count
// 6. Tap "Generate"

// Code:
let request = PracticeTestRequest(
    courseId: course.id,
    courseName: course.code,
    topics: ["Algebra", "Calculus"],
    difficulty: .medium,
    questionCount: 10,
    includeMultipleChoice: true,
    includeShortAnswer: false,
    includeExplanation: false
)
await store.generateTest(request: request)
```

### Take a Test
```swift
// Presented automatically when test is ready/in-progress
IOSPracticeTestTakingView(test: test, store: practiceStore)

// User interactions:
// - Tap answer choice → saves and auto-advances
// - Tap Previous/Next → manual navigation
// - Tap Submit → confirmation dialog → results
```

### View Results
```swift
// Presented automatically when test is submitted
IOSPracticeTestResultsView(test: test, store: practiceStore)

// Features:
// - Tap question card → expand/collapse
// - See correct answer (✓) and your answer (✗)
// - Read explanation
// - Tap "Done" → return to practice hub
```

## Data Models

### PracticeTestRequest
```swift
struct PracticeTestRequest {
    var courseId: UUID
    var courseName: String
    var topics: [String]           // Optional
    var difficulty: PracticeTestDifficulty
    var questionCount: Int
    var includeMultipleChoice: Bool // Always true for iOS
    var includeShortAnswer: Bool    // Always false for iOS
    var includeExplanation: Bool    // Always false for iOS
}
```

### PracticeQuestion (5 choices)
```swift
struct PracticeQuestion {
    var prompt: String
    var format: QuestionFormat      // .multipleChoice
    var options: [String]?          // 5 choices (A-E)
    var correctAnswer: String
    var explanation: String
    var bloomsLevel: String?        // e.g., "Remember", "Analyze"
}
```

### PracticeTestStatus
```swift
enum PracticeTestStatus {
    case generating  // AI creating questions
    case ready       // Ready to take
    case inProgress  // Partially completed
    case submitted   // Completed, scored
    case failed      // Generation error
}
```

## LLM Integration

### Backend Selection
Settings → LLM Backend:
- **MLX**: On-device (Apple Silicon)
- **Ollama**: Local server
- **OpenAI Compatible**: Custom API
- **Mock**: Deterministic testing

### Generation Flow
```
PracticeTestRequest
  ↓
TestBlueprint (deterministic)
  ↓
QuestionSlots (topic, difficulty, Bloom level)
  ↓
LLMService.generateQuestionForSlot()
  ↓
QuestionDraft (5 choices)
  ↓
Validation (schema, content, duplicates)
  ↓
QuestionValidated
  ↓
PracticeQuestion
  ↓
PracticeTest
```

### Validation Rules (5 Choices)
- ✅ Exactly 5 choices (A, B, C, D, E)
- ✅ correctIndex: 0-4
- ✅ All choices unique
- ✅ Rationale ≥ 10 words
- ✅ Topic match
- ✅ Difficulty match
- ✅ Bloom level match
- ✅ No duplicates (hash-based)

### Fallback Strategy
1. Retry with repair instructions (max 5 attempts/slot)
2. Fallback to deterministic question
3. Retry full test (max 3 attempts)
4. Report failure with error details

## UI Components

### Answer Button (A-E Format)
```
┌─────────────────────────────────────┐
│  [A]  Choice text here              │
│       spanning multiple lines       │
└─────────────────────────────────────┘

States:
- Unselected: Gray background
- Selected: Blue background + border
- Correct (results): Green background + ✓
- Incorrect (results): Red background + ✗
```

### Progress Header
```
┌─────────────────────────────────────┐
│ Question 3 of 10      7 answered    │
│ ────────────────────                │
└─────────────────────────────────────┘
Progress bar: 70% filled (blue)
```

### Score Display
```
┌─────────────────────────────────────┐
│              85%                    │
│         (17 out of 20)              │
│                                     │
│   Great work! Strong understanding  │
└─────────────────────────────────────┘
```

## State Management

### PracticeTestStore
```swift
@StateObject private var practiceStore = PracticeTestStore.shared

// Properties:
practiceStore.tests           // All tests
practiceStore.currentTest     // Active test
practiceStore.isGenerating    // Generation status
practiceStore.summary         // Statistics

// Actions:
await practiceStore.generateTest(request)
practiceStore.startTest(testId)
practiceStore.answerQuestion(testId, questionId, answer, timeSpent)
practiceStore.submitTest(testId)
practiceStore.retryGeneration(testId)
practiceStore.clearCurrentTest()
```

## Colors & Icons

### Status Colors
- 🟢 Green: Ready, Correct (90%+)
- 🔵 Blue: In Progress, Good (70-89%)
- 🟠 Orange: Generating, Fair (50-69%)
- 🔴 Red: Failed, Incorrect (<50%)

### Status Icons
- `play.circle.fill`: Ready to start
- `arrow.clockwise.circle.fill`: In progress
- `checkmark.circle.fill`: Completed/Correct
- `xmark.circle.fill`: Incorrect
- `exclamationmark.triangle.fill`: Failed
- `hourglass`: Generating

## Navigation Pattern

```
Practice Tab (IOSPracticeView)
  ├─ [+] Generate Test
  │   └─ .sheet → IOSPracticeTestGeneratorView
  │       └─ Generate → dismiss
  │
  ├─ [Play] Ready Test
  │   └─ .fullScreenCover → IOSPracticeTestTakingView
  │       └─ Submit → dismiss
  │
  └─ [Score] Completed Test
      └─ .fullScreenCover → IOSPracticeTestResultsView
          └─ Done → dismiss
```

## Accessibility

### Labels
- All buttons have accessibility labels
- Answer choices: "Choice A: [text]"
- Progress: "Question 3 of 10, 7 answered"
- Score: "85 percent, 17 out of 20 correct"

### Touch Targets
- Minimum 44pt × 44pt
- Large answer buttons
- Clear tap areas

### Dynamic Type
- All text respects user font size preferences
- Layout adapts to larger text

## Error Handling

### Generation Errors
```swift
// Display in UI:
"Generation Failed"
[Error message]
[Retry Button]

// Log to console:
"[TestGen.Algorithm] ERROR: Slot S3 failed: Contract violation"
```

### Network Errors
```swift
// Handled by LLMBackend:
- Timeout → fallback to deterministic
- API error → retry with backoff
- No connection → use mock backend
```

## Performance

### Metrics
- Test generation: 5-30s (depends on LLM)
- Test taking: Smooth 60fps animations
- Results rendering: <100ms for 20 questions
- Memory: <10MB for typical test session

### Optimization
- Lazy loading of test list
- Efficient state updates
- Background LLM generation
- Cached validation results

## Development Tips

### Debug Mode
```swift
// Enable in PracticeTestStore:
let generator = AlgorithmicTestGenerator(
    llmService: llmService,
    enableDevLogs: true  // Shows generation logs
)
```

### Mock Testing
```swift
// Use mock backend for testing:
Settings → LLM Backend → Mock
// Generates deterministic questions instantly
```

### Test Data
```swift
// Clear all tests:
PracticeTestStore.shared.resetAll()

// Generate sample test:
let request = PracticeTestRequest(
    courseId: UUID(),
    courseName: "Test Course",
    topics: [],
    difficulty: .medium,
    questionCount: 5
)
```

## Common Issues

### "No courses available"
→ Add a course first in Courses tab

### "Generation failed"
→ Check LLM backend status
→ Try Mock backend
→ Check console logs

### Test not appearing
→ Verify test status in `practiceStore.tests`
→ Check `practiceStore.currentTest`

### Submit button disabled
→ Must answer all questions first
→ Or force submit (shows unanswered warning)

## Related Documentation

- `HYBRID_AI_QUICK_REFERENCE.md` - AI architecture
- `IOS_PRACTICE_TEST_IMPLEMENTATION.md` - Full details
- `PLATFORM_UNIFICATION_QUICK_REFERENCE.md` - iOS/macOS patterns
- `TEST_BLUEPRINT_MODELS.md` - Question generation models

## Support

For issues or questions:
1. Check console logs for errors
2. Verify LLM backend status
3. Test with Mock backend first
4. Review validation error messages
5. Check `PracticeTestStore` state

---

**Version**: 1.0  
**Last Updated**: January 2026  
**Platform**: iOS 17.0+  
**Swift**: 5.9+
