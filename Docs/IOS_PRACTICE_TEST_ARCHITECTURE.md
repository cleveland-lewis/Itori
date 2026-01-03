# iOS Practice Test UI Architecture

## Component Diagram

```
┌─────────────────────────────────────────────────────────────────────┐
│                         iOS Practice Tab                             │
│                      (IOSPracticeView)                               │
├─────────────────────────────────────────────────────────────────────┤
│                                                                       │
│  ┌──────────────────┐  ┌──────────────────┐  ┌──────────────────┐  │
│  │  Scheduled Tests │  │  Practice Tests  │  │   Statistics     │  │
│  │      Card        │  │     Section      │  │      Card        │  │
│  └──────────────────┘  └──────────────────┘  └──────────────────┘  │
│                              │                                        │
│                              ├── [+] Generate Button                 │
│                              │                                        │
│                              ├── Current Test State:                 │
│                              │   • Generating (spinner)              │
│                              │   • Ready (play button)               │
│                              │   • In Progress (progress bar)        │
│                              │   • Completed (score)                 │
│                              │   • Failed (retry)                    │
│                              │                                        │
│                              └── Recent Tests List                   │
│                                                                       │
└───────────────────────┬───────────────────┬───────────────────────┬─┘
                        │                   │                       │
                        ▼                   ▼                       ▼
            ┌────────────────────┐  ┌──────────────────┐  ┌─────────────────┐
            │   Generate Sheet   │  │  Taking View     │  │  Results View   │
            │  (Form interface)  │  │  (Full screen)   │  │  (Full screen)  │
            └────────────────────┘  └──────────────────┘  └─────────────────┘
                        │                   │                       │
                        │                   │                       │
                        ▼                   ▼                       ▼
            ┌───────────────────────────────────────────────────────────────┐
            │                  PracticeTestStore                            │
            │                  (State Management)                           │
            └───────────────────────────────────────────────────────────────┘
                                        │
                                        ▼
            ┌───────────────────────────────────────────────────────────────┐
            │              AlgorithmicTestGenerator                         │
            │              (Blueprint-first generation)                     │
            └───────────────────────────────────────────────────────────────┘
                                        │
                                        ▼
            ┌───────────────────────────────────────────────────────────────┐
            │                   LocalLLMService                             │
            │               (LLM backend abstraction)                       │
            └───────────────────────────────────────────────────────────────┘
                                        │
                    ┌───────────────────┼───────────────────┐
                    ▼                   ▼                   ▼
            ┌──────────────┐    ┌──────────────┐    ┌──────────────┐
            │  MLX Backend │    │Ollama Backend│    │ Mock Backend │
            └──────────────┘    └──────────────┘    └──────────────┘
```

## Data Flow Diagram

```
User Action: Generate Test
    │
    ├─► Select Course
    ├─► Add Topics (optional)
    ├─► Choose Difficulty
    ├─► Select Question Count
    └─► Tap "Generate"
           │
           ▼
    PracticeTestRequest
    {
      courseId: UUID
      courseName: "Physics 101"
      topics: ["Mechanics", "Thermodynamics"]
      difficulty: .medium
      questionCount: 10
    }
           │
           ▼
    TestBlueprintGenerator
    (Deterministic algorithm)
           │
           ├─► Calculate topic quotas
           ├─► Distribute difficulty levels
           ├─► Assign Bloom taxonomy levels
           └─► Create question slots
           │
           ▼
    TestBlueprint
    {
      slots: [
        QuestionSlot(topic: "Mechanics", bloom: .remember, difficulty: .easy),
        QuestionSlot(topic: "Mechanics", bloom: .understand, difficulty: .medium),
        QuestionSlot(topic: "Thermodynamics", bloom: .apply, difficulty: .medium),
        ...
      ]
    }
           │
           ▼
    For Each Slot (parallel/sequential)
           │
           ├─► LocalLLMService.generateQuestionForSlot()
           │      │
           │      ├─► Build prompt with constraints
           │      ├─► Call LLM backend
           │      └─► Parse JSON response
           │      │
           │      ▼
           │   QuestionDraft
           │   {
           │     prompt: "What is Newton's first law?"
           │     choices: ["A", "B", "C", "D", "E"]
           │     correctAnswer: "A"
           │     correctIndex: 0
           │     rationale: "..."
           │   }
           │
           ├─► QuestionValidator.validateSchema()
           │      ├─► Check 5 choices
           │      ├─► Verify correctIndex (0-4)
           │      └─► Validate required fields
           │
           ├─► QuestionValidator.validateContent()
           │      ├─► Topic match
           │      ├─► Difficulty match
           │      ├─► Bloom level match
           │      └─► Banned phrases check
           │
           ├─► QuestionValidator.validateNoDuplicate()
           │      └─► Hash-based duplicate detection
           │
           └─► If validation passes:
                  ▼
               QuestionValidated
               {
                 question: PracticeQuestion
                 promptHash: "abc123..."
               }
           │
           └─► If validation fails:
                  ├─► Retry with repair instructions (max 5)
                  └─► Fallback to deterministic question
           │
           ▼
    All Slots Validated
           │
           ├─► QuestionValidator.validateDistribution()
           │      ├─► Check topic balance
           │      ├─► Check difficulty distribution
           │      └─► Check Bloom level coverage
           │
           └─► Success!
           │
           ▼
    PracticeTest (Ready)
    {
      status: .ready
      questions: [PracticeQuestion × 10]
    }
           │
           ▼
    Update UI → Show "Ready to Start"
```

## Test Taking Flow

```
User Taps "Start Test"
    │
    ├─► store.startTest(testId)
    │      └─► Update status to .inProgress
    │
    ▼
IOSPracticeTestTakingView (Full Screen)
    │
    ├─► Display Question 1
    │      ├─► Question prompt
    │      ├─► 5 answer choices (A-E)
    │      └─► Progress indicator
    │
    ├─► User taps answer "B"
    │      │
    │      ├─► Visual feedback (blue highlight)
    │      ├─► store.answerQuestion(testId, questionId, "B", timeSpent)
    │      │      │
    │      │      ├─► Validate answer
    │      │      ├─► Store in test.answers[questionId]
    │      │      └─► Save to UserDefaults
    │      │
    │      └─► Auto-advance to next question (0.5s)
    │
    ├─► User navigates (Previous/Next)
    │      └─► Update currentQuestionIndex
    │
    ├─► Progress bar updates
    │      └─► (answeredCount / totalCount)
    │
    └─► User taps "Submit"
           │
           ├─► Show confirmation dialog
           │      └─► "Are you sure? You cannot change answers."
           │
           └─► User confirms
                  │
                  ├─► store.submitTest(testId)
                  │      │
                  │      ├─► Update status to .submitted
                  │      ├─► Set submittedAt timestamp
                  │      ├─► Calculate score
                  │      └─► Update analytics
                  │
                  └─► Dismiss → Show results
```

## Results Display Flow

```
IOSPracticeTestResultsView (Full Screen)
    │
    ├─► Score Card
    │      ├─► Large percentage: "85%"
    │      ├─► Fraction: "17 out of 20"
    │      ├─► Color coding (green/blue/orange/red)
    │      └─► Interpretation message
    │
    ├─► Statistics Section
    │      ├─► Course name
    │      ├─► Difficulty level
    │      ├─► Topics covered
    │      └─► Completion date
    │
    └─► Question Review (Collapsible)
           │
           For Each Question:
              │
              ├─► Question Number Badge
              │      └─► Color: green (correct) / red (incorrect)
              │
              ├─► Collapsed View
              │      ├─► Status icon (✓/✗)
              │      ├─► Bloom level tag
              │      └─► Expand chevron
              │
              └─► Expanded View (on tap)
                     │
                     ├─► Question prompt
                     │
                     ├─► All 5 choices (A-E)
                     │      ├─► Green highlight: correct answer
                     │      ├─► Red highlight: user's wrong answer
                     │      └─► Checkmark/X indicators
                     │
                     └─► Explanation Section
                            ├─► Lightbulb icon
                            └─► Detailed rationale
```

## State Transitions

```
PracticeTest Status State Machine:

    [Create]
       │
       ▼
   GENERATING
   (isGenerating=true)
       │
       ├─► Success → READY
       │                │
       │                ▼
       │            [User starts]
       │                │
       │                ▼
       │           IN_PROGRESS
       │           (answering questions)
       │                │
       │                ├─► [User submits]
       │                │        │
       │                │        ▼
       │                │   SUBMITTED
       │                │   (show results)
       │                │
       │                └─► [User exits mid-test]
       │                         │
       │                         └─► IN_PROGRESS
       │                             (resume later)
       │
       └─► Failure → FAILED
                     (show error + retry)
                          │
                          └─► [User retries]
                                   │
                                   └─► GENERATING
```

## View Hierarchy

```
NavigationStack
└── ScrollView
    └── VStack
        ├── Scheduled Tests Card (Button)
        │   └── .sheet → IOSScheduledTestsView
        │
        ├── Practice Tests Section
        │   ├── Header + [+] Button
        │   │   └── .sheet → IOSPracticeTestGeneratorView
        │   │
        │   ├── Current Test Card (if exists)
        │   │   ├── Status: Generating
        │   │   │   └── ProgressView + "Creating questions..."
        │   │   │
        │   │   ├── Status: Ready
        │   │   │   └── Button → .fullScreenCover → IOSPracticeTestTakingView
        │   │   │
        │   │   ├── Status: In Progress
        │   │   │   └── Button → .fullScreenCover → IOSPracticeTestTakingView
        │   │   │
        │   │   ├── Status: Submitted
        │   │   │   └── Button → .fullScreenCover → IOSPracticeTestResultsView
        │   │   │
        │   │   └── Status: Failed
        │   │       └── Retry Button
        │   │
        │   ├── Recent Tests List (if no current test)
        │   │   └── ForEach test → recentTestRow
        │   │
        │   └── Empty State (if no tests)
        │       └── "Generate first test" CTA
        │
        └── Statistics Card (if tests > 0)
            ├── Total tests
            ├── Average score
            └── Total questions
```

## Class Relationships

```
┌─────────────────────────────────────────────────────────────────┐
│                     iOS View Layer                               │
├─────────────────────────────────────────────────────────────────┤
│                                                                   │
│  IOSPracticeView                                                 │
│  ├── @StateObject practiceStore: PracticeTestStore              │
│  ├── @StateObject scheduledTestsStore: ScheduledTestsStore      │
│  └── @EnvironmentObject coursesStore: CoursesStore              │
│                                                                   │
│  IOSPracticeTestGeneratorView                                    │
│  ├── @ObservedObject store: PracticeTestStore                   │
│  ├── @EnvironmentObject coursesStore: CoursesStore              │
│  └── @State selectedCourse: Course?                             │
│                                                                   │
│  IOSPracticeTestTakingView                                       │
│  ├── let test: PracticeTest                                     │
│  ├── @ObservedObject store: PracticeTestStore                   │
│  ├── @State currentQuestionIndex: Int                           │
│  └── @State userAnswers: [UUID: String]                         │
│                                                                   │
│  IOSPracticeTestResultsView                                      │
│  ├── let test: PracticeTest                                     │
│  ├── @ObservedObject store: PracticeTestStore                   │
│  └── @State expandedQuestionIds: Set<UUID>                      │
│                                                                   │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                    Business Logic Layer                          │
├─────────────────────────────────────────────────────────────────┤
│                                                                   │
│  PracticeTestStore: ObservableObject                            │
│  ├── @Published tests: [PracticeTest]                           │
│  ├── @Published currentTest: PracticeTest?                      │
│  ├── @Published isGenerating: Bool                              │
│  ├── @Published summary: PracticeTestSummary                    │
│  ├── llmService: LocalLLMService                                │
│  ├── algorithmicGenerator: AlgorithmicTestGenerator             │
│  └── Methods:                                                    │
│      ├── generateTest(request)                                  │
│      ├── startTest(testId)                                      │
│      ├── answerQuestion(testId, questionId, answer)             │
│      ├── submitTest(testId)                                     │
│      └── retryGeneration(testId)                                │
│                                                                   │
│  AlgorithmicTestGenerator: ObservableObject                     │
│  ├── @Published isGenerating: Bool                              │
│  ├── @Published stats: GenerationStats                          │
│  ├── llmService: LocalLLMService                                │
│  └── Methods:                                                    │
│      ├── generateTest(request) → GenerationResult               │
│      └── generateSlot(slot, context) → QuestionValidated        │
│                                                                   │
│  LocalLLMService: ObservableObject                              │
│  ├── @Published isAvailable: Bool                               │
│  ├── @Published backend: LLMBackend                             │
│  └── Methods:                                                    │
│      ├── generateQuestionForSlot(slot, context)                 │
│      └── validateAnswer(userAnswer, correctAnswer, format)      │
│                                                                   │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                       Model Layer                                │
├─────────────────────────────────────────────────────────────────┤
│                                                                   │
│  PracticeTest                                                    │
│  ├── id: UUID                                                    │
│  ├── courseId: UUID                                              │
│  ├── questions: [PracticeQuestion]                              │
│  ├── answers: [UUID: PracticeAnswer]                            │
│  ├── status: PracticeTestStatus                                 │
│  └── computed: score, correctCount                              │
│                                                                   │
│  PracticeQuestion                                                │
│  ├── id: UUID                                                    │
│  ├── prompt: String                                              │
│  ├── format: QuestionFormat (.multipleChoice)                   │
│  ├── options: [String]? (5 choices: A-E)                        │
│  ├── correctAnswer: String                                       │
│  ├── explanation: String                                         │
│  └── bloomsLevel: String?                                        │
│                                                                   │
│  TestBlueprint                                                   │
│  ├── slots: [QuestionSlot]                                      │
│  ├── topicQuotas: [String: Int]                                 │
│  ├── difficultyDistribution: [Difficulty: Int]                  │
│  └── bloomDistribution: [BloomLevel: Int]                       │
│                                                                   │
│  QuestionSlot                                                    │
│  ├── topic: String                                               │
│  ├── bloomLevel: BloomLevel                                     │
│  ├── difficulty: PracticeTestDifficulty                         │
│  ├── templateType: QuestionTemplateType                         │
│  └── maxPromptWords: Int                                         │
│                                                                   │
└─────────────────────────────────────────────────────────────────┘
```

## Sequence Diagram: Full User Journey

```
User    UI          Store           Generator       LLM         Validator
 │       │            │                │             │              │
 │  Tap "+"           │                │             │              │
 ├──────►│            │                │             │              │
 │       │  Show Generator              │             │              │
 │       │            │                │             │              │
 │  Select course     │                │             │              │
 ├──────►│            │                │             │              │
 │       │            │                │             │              │
 │  Tap "Generate"    │                │             │              │
 ├──────►│            │                │             │              │
 │       │  generateTest()             │             │              │
 │       ├───────────►│                │             │              │
 │       │            │  generateTest()│             │              │
 │       │            ├───────────────►│             │              │
 │       │            │                │  Blueprint  │              │
 │       │            │                │  created    │              │
 │       │            │                │             │              │
 │       │            │                │  For each slot:           │
 │       │            │                │  generateQuestionForSlot()│
 │       │            │                ├────────────►│              │
 │       │            │                │             │  Validate    │
 │       │            │                │             ├─────────────►│
 │       │            │                │             │◄─────────────┤
 │       │            │                │◄────────────┤              │
 │       │            │◄───────────────┤             │              │
 │       │◄───────────┤                │             │              │
 │       │  Show "Ready"               │             │              │
 │◄──────┤            │                │             │              │
 │       │            │                │             │              │
 │  Tap "Start"       │                │             │              │
 ├──────►│            │                │             │              │
 │       │  startTest()                │             │              │
 │       ├───────────►│                │             │              │
 │       │            │  status = .inProgress        │              │
 │       │◄───────────┤                │             │              │
 │       │  Show questions              │             │              │
 │◄──────┤            │                │             │              │
 │       │            │                │             │              │
 │  Select answer "B" │                │             │              │
 ├──────►│            │                │             │              │
 │       │  answerQuestion()           │             │              │
 │       ├───────────►│                │             │              │
 │       │            │  Save answer   │             │              │
 │       │◄───────────┤                │             │              │
 │       │  Next question               │             │              │
 │◄──────┤            │                │             │              │
 │       │            │                │             │              │
 │  ... answer all ... │               │             │              │
 │       │            │                │             │              │
 │  Tap "Submit"      │                │             │              │
 ├──────►│            │                │             │              │
 │       │  Show confirm               │             │              │
 │◄──────┤            │                │             │              │
 │       │            │                │             │              │
 │  Confirm           │                │             │              │
 ├──────►│            │                │             │              │
 │       │  submitTest()               │             │              │
 │       ├───────────►│                │             │              │
 │       │            │  Calculate score             │              │
 │       │            │  status = .submitted         │              │
 │       │◄───────────┤                │             │              │
 │       │  Show results               │             │              │
 │◄──────┤            │                │             │              │
 │       │            │                │             │              │
```

---

**Visual Guide Version**: 1.0  
**Last Updated**: January 2026
