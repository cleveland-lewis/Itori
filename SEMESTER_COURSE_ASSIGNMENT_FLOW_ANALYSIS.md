# Semester → Course → Assignment User Flow Analysis

## Architecture Overview

### Data Model Hierarchy
```
Semester (CourseModels.swift)
├── id: UUID
├── startDate, endDate: Date
├── semesterTerm: SemesterType (Fall, Spring, Summer I/II, Winter)
├── educationLevel: EducationLevel (Middle School, High School, College, Grad School)
├── isCurrent: Bool
└── isArchived: Bool

Course (CourseModels.swift)
├── id: UUID
├── semesterId: UUID (parent reference)
├── title: String
├── code: String
├── instructor: String
├── credits: Double
├── color: Color
├── meetings: [CourseMeeting]
└── attachments: [Attachment]

AppTask/Assignment (AssignmentModels.swift)
├── id: UUID
├── courseId: UUID (parent reference)
├── title: String
├── type: TaskType (project, exam, quiz, homework, reading, review)
├── due: Date?
├── estimatedMinutes: Int
├── isCompleted: Bool
├── urgency: AssignmentUrgency
├── status: AssignmentStatus
└── planSteps: [PlanStep]
```

### State Management

**CoursesStore** (SharedCore/State/CoursesStore.swift)
- Central store for semesters, courses, and related data
- Published properties: `@Published var semesters: [Semester]`, `@Published var courses: [Course]`
- Singleton pattern: `static weak var shared: CoursesStore?`
- Persistence: Local JSON + optional iCloud sync
- Key methods:
  - `addSemester(_ semester: Semester)`
  - `setCurrentSemester(_ semester: Semester)`
  - `addCourse(_ course: Course)`
  - `courses(in semester: Semester) -> [Course]`

**AssignmentsStore** (Assumed similar pattern)
- Manages all assignments/tasks
- Published property: tasks filtered by courseId
- Methods to create, update, delete assignments

---

## User Flow Paths

### Path 1: macOS Flow (Traditional Desktop Pattern)

#### A. Starting Point: CoursesView
**File**: `Platforms/macOS/Scenes/CoursesView.swift`

```swift
struct CoursesView: View {
    @EnvironmentObject private var coursesStore: CoursesStore
    @State private var showingAddSemester = false
    @State private var showingAddCourse = false
```

**User Actions**:
1. **Select Semester**: 
   - Segmented picker shows all semesters
   - Sets `coursesStore.currentSemesterId`
   - Updates: `coursesStore.setCurrentSemester(sem)`

2. **Add Semester**:
   - Button → `showingAddSemester = true`
   - Sheet presents: `AddSemesterSheet`
   - On save: `coursesStore.addSemester(semester)`

3. **Add Course**:
   - Button → `showingAddCourse = true`
   - Sheet presents: `AddCourseSheet`
   - On save: `coursesStore.addCourse(course)` with current `semesterId`

4. **View Course Details**:
   - Grid of course cards (CardGrid)
   - Click on course → NavigationLink/Sheet to `CourseDetailView`

#### B. Course Detail View
**File**: `Platforms/macOS/Views/CourseDetailView.swift`

```swift
struct CourseDetailView: View {
    let course: Course
    let semester: Semester
    @EnvironmentObject private var assignmentsStore: AssignmentsStore
```

**Displays**:
- Course header (title, instructor, credits, grade)
- Cards for:
  - Assignments (filtered by courseId)
  - Exams (filtered by courseId + type)
  - Materials/attachments
  - Upcoming deadlines
  - Modules
  - Practice quizzes

**User Actions**:
1. **Add Assignment** (from course detail):
   - Opens `AddAssignmentView`
   - Course is pre-selected (preselectedCourseId)
   - Assignment inherits courseId

#### C. Add Assignment View
**File**: `Platforms/macOS/Views/AddAssignmentView.swift`

```swift
struct AddAssignmentView: View {
    @State private var selectedCourseId: UUID? = nil
    
    init(initialType: TaskType = .project, 
         preselectedCourseId: UUID? = nil, 
         onSave: @escaping (AppTask) -> Void)
```

**Flow**:
1. Form fields: title, due date, estimated minutes, type
2. Course picker (dropdown showing courses from current semester)
3. Advanced options: urgency, status, recurrence, dependencies
4. Save → Creates `AppTask` with `courseId = selectedCourseId`
5. Callback: `onSave(task)` → `assignmentsStore.addTask(task)`

**Key Feature**: Can be opened with or without pre-selected course

---

### Path 2: iOS Flow (Modern Mobile Pattern)

#### A. Tab-Based Navigation
**File**: `Platforms/iOS/Root/IOSRootView.swift`

```swift
TabView(selection: $selectedTab) {
    ForEach(starredTabs) { tab in
        IOSAppShell(title: tab.title) {
            tabView(for: tab)
        }
    }
}
```

**Available Tabs** (from TabRegistry):
- Dashboard
- Planner
- Courses
- Assignments
- Flashcards
- Practice

#### B. Dashboard View
**File**: `Platforms/iOS/Scenes/IOSDashboardView.swift` (assumed)

**Likely Shows**:
- Current semester summary
- Courses in current semester
- Due today/upcoming assignments
- Quick actions: Add Assignment, Add Course

#### C. Courses Tab
**File**: Likely follows similar pattern to macOS:

```
CoursesDashboardSidebar (left) | CoursesDashboardDetail (right)
```

**Sidebar**: 
- Search + semester filter
- List of courses with color indicators
- Tap course → selects it, updates detail view

**Detail**:
- Course header with grade progress
- Meetings card
- Syllabus card
- (Likely) Assignments list for this course

#### D. iOS Add Assignment Flow
**File**: `Platforms/iOS/Scenes/IOSCorePages.swift` (contains page definitions)

**Triggering Points**:
1. From Dashboard: Floating "+" button
2. From Course Detail: "Add Assignment" button
3. From Assignments tab: "+" button
4. From Planner: Quick add

**Sheet Presentation**:
```swift
.sheet(item: $sheetRouter.activeSheet) { sheet in
    sheetContent(for: sheet)
}
```

**IOSSheetRouter** manages which sheet to show:
- `.addAssignment(preselectedCourseId: UUID?)`
- Form similar to macOS but mobile-optimized

---

## Key User Flow Patterns

### Pattern 1: Top-Down Creation
**Semester → Course → Assignment**

1. User creates semester (e.g., "Fall 2025")
2. User marks it as current semester
3. User adds courses to this semester
4. User adds assignments within each course

**Enforcement**:
- Assignments MUST have a courseId (form validation: `isSaveDisabled`)
- Courses MUST have a semesterId
- Current semester acts as default context

### Pattern 2: Context-Aware Assignment Creation
**From Course Detail View**

1. User is viewing "CS 101" course
2. Clicks "Add Assignment"
3. `AddAssignmentView` opens with `preselectedCourseId = course.id`
4. User only needs to fill: title, due date, type
5. Course field is pre-filled and can be changed if needed

### Pattern 3: Cross-Semester Filtering
**From Assignments View**

1. User can see ALL assignments across all semesters
2. Filter by:
   - Course (which implies semester)
   - Due date
   - Completion status
   - Type (exam, project, homework)

### Pattern 4: Semester Lifecycle

```
Create Semester
    ↓
Mark as Current → Courses appear in UI
    ↓
Add Courses
    ↓
Add Assignments
    ↓
Complete Semester → Archive
    ↓
Recently Deleted (soft delete with deletedAt timestamp)
    ↓
Permanent Deletion (or restore)
```

---

## Data Flow Diagram

```
┌─────────────────────────────────────────────────┐
│ User Action: "Add New Semester"                 │
│ Location: CoursesView / Settings                │
└────────────────┬────────────────────────────────┘
                 ↓
┌─────────────────────────────────────────────────┐
│ AddSemesterSheet                                │
│ - Choose term (Fall/Spring/Summer)              │
│ - Set start/end dates                           │
│ - Choose education level                        │
│ - Mark as current (optional)                    │
└────────────────┬────────────────────────────────┘
                 ↓
┌─────────────────────────────────────────────────┐
│ CoursesStore.addSemester(semester)              │
│ - Appends to semesters array                    │
│ - If isCurrent, sets currentSemesterId          │
│ - Persists to disk/iCloud                       │
└────────────────┬────────────────────────────────┘
                 ↓
┌─────────────────────────────────────────────────┐
│ UI Updates (via @Published)                     │
│ - Semester picker refreshes                     │
│ - Course list filters to new semester           │
└─────────────────────────────────────────────────┘

                                ↓

┌─────────────────────────────────────────────────┐
│ User Action: "Add New Course"                   │
│ Location: CoursesView                           │
└────────────────┬────────────────────────────────┘
                 ↓
┌─────────────────────────────────────────────────┐
│ AddCourseSheet                                  │
│ - Title, code, instructor                       │
│ - Credits, color                                │
│ - Meetings (days/times)                         │
│ - semesterId = coursesStore.currentSemesterId   │
└────────────────┬────────────────────────────────┘
                 ↓
┌─────────────────────────────────────────────────┐
│ CoursesStore.addCourse(course)                  │
│ - Appends to courses array                      │
│ - Course.semesterId links to semester           │
│ - Persists to disk/iCloud                       │
└────────────────┬────────────────────────────────┘
                 ↓
┌─────────────────────────────────────────────────┐
│ UI Updates                                      │
│ - Course grid shows new course card             │
│ - Calendar may add course meetings              │
└─────────────────────────────────────────────────┘

                                ↓

┌─────────────────────────────────────────────────┐
│ User Action: "Add Assignment to Course"         │
│ Location: CourseDetailView or Global +          │
└────────────────┬────────────────────────────────┘
                 ↓
┌─────────────────────────────────────────────────┐
│ AddAssignmentView                               │
│ - Title, due date, type                         │
│ - Course picker (filtered to current semester)  │
│ - If from CourseDetailView:                     │
│     preselectedCourseId = course.id             │
│ - Estimated minutes                             │
│ - Advanced: urgency, recurrence, dependencies   │
└────────────────┬────────────────────────────────┘
                 ↓
┌─────────────────────────────────────────────────┐
│ Validation                                      │
│ - title.isEmpty → Save disabled                 │
│ - selectedCourseId == nil → Save disabled       │
└────────────────┬────────────────────────────────┘
                 ↓
┌─────────────────────────────────────────────────┐
│ AssignmentsStore.addTask(task)                  │
│ - task.courseId links to course                 │
│ - Course.semesterId → indirect semester link    │
│ - Persists to disk                              │
│ - May trigger planner regeneration              │
└────────────────┬────────────────────────────────┘
                 ↓
┌─────────────────────────────────────────────────┐
│ UI Updates                                      │
│ - Assignment appears in course detail           │
│ - Appears in assignments list                   │
│ - Appears in planner (if due date set)          │
│ - Appears in dashboard "Due Today" widget       │
└─────────────────────────────────────────────────┘
```

---

## Navigation Hierarchy

### macOS
```
Main Window
├── Sidebar (tab selection)
│   ├── Dashboard
│   ├── Planner  
│   ├── Courses ← Entry point
│   ├── Assignments
│   ├── Flashcards
│   └── Practice
│
└── Content Area
    ├── CoursesView
    │   ├── Semester selector (top)
    │   ├── Course grid (main)
    │   │   └── CourseDetailView (sheet/nav)
    │   │       ├── Assignments card
    │   │       ├── Exams card
    │   │       └── Add Assignment button → AddAssignmentView
    │   │
    │   ├── Add Semester button → AddSemesterSheet
    │   └── Add Course button → AddCourseSheet
    │
    └── Settings
        └── Semesters Settings
            ├── Manage semesters
            ├── Archive semesters
            └── Recently deleted
```

### iOS
```
TabView
├── Dashboard Tab
│   ├── Current semester summary
│   ├── Course cards (quick view)
│   └── Assignments due today
│
├── Planner Tab
│   ├── Calendar view
│   ├── Scheduled sessions
│   └── Can add assignments here
│
├── Courses Tab ← Primary entry point
│   └── NavigationSplitView (iPad)
│       ├── Sidebar
│       │   ├── Search bar
│       │   ├── Semester filter
│       │   └── Course list
│       └── Detail
│           ├── Course info
│           ├── Assignments for course
│           └── Add Assignment (context-aware)
│
├── Assignments Tab
│   ├── Filter bar (course, date, status)
│   ├── Assignment list (all courses)
│   └── Add Assignment (no course preselected)
│
└── Settings (hidden in hamburger menu)
    └── Semesters
        └── Similar to macOS
```

---

## Critical Observations

### Strengths

1. **Strong Data Relationships**:
   - Clear parent-child: Semester → Course → Assignment
   - UUID-based references (not brittle string IDs)
   - Cascading lookups: Get assignments → filter by courseId → get course → get semesterId

2. **Context Awareness**:
   - Current semester acts as default filter
   - Assignment creation can pre-populate course
   - Course detail view naturally scopes to that course

3. **Flexible Entry Points**:
   - Can add assignment from:
     - Course detail (pre-filled)
     - Global "+" menu (manual selection)
     - Dashboard quick add
     - Planner view

4. **State Management**:
   - Centralized stores (CoursesStore, AssignmentsStore)
   - @Published properties trigger UI updates
   - Persistence handled at store level

### Potential Issues

1. **Orphaned Data Risk**:
   - What happens if a course is deleted but assignments still reference it?
   - Current: Likely filtered out in queries (`courses.first(where: { $0.id == courseId })`)
   - Better: Cascade delete or soft-delete with retention policy

2. **Current Semester Confusion**:
   - Only one semester can be "current" at a time
   - What if user is taking summer courses while fall is "current"?
   - Solution: May need "active semesters" (plural) vs "current" (singular)

3. **Assignment Without Course**:
   - Form validation prevents saving without courseId
   - But what about personal tasks unrelated to courses?
   - May need "no course" or "personal" option

4. **Cross-Semester Assignments**:
   - Example: Research project spans fall → spring
   - Current model: Assignment belongs to one course → one semester
   - Workaround: Duplicate assignment or use dependencies

5. **Semester Picker Scalability**:
   - Segmented picker works for 2-4 semesters
   - After several years, could become cluttered
   - Solution: Dropdown or hierarchical (Academic Year → Semester)

---

## Recommended Improvements

### 1. Add Semester Hierarchy
```swift
struct AcademicYear: Identifiable {
    let id: UUID
    let year: String // "2024-2025"
    let semesters: [Semester]
}
```

### 2. Soft Delete with Cascade
```swift
func deleteCourse(_ course: Course) {
    // Soft delete course
    course.deletedAt = Date()
    
    // Soft delete related assignments
    let relatedAssignments = assignments.filter { $0.courseId == course.id }
    relatedAssignments.forEach { $0.deletedAt = Date() }
    
    persist()
}
```

### 3. "Active Semesters" Concept
```swift
// Instead of single currentSemesterId
@Published var activeSemesterIds: Set<UUID> = []

var activeSemesters: [Semester] {
    semesters.filter { activeSemesterIds.contains($0.id) }
}
```

### 4. Personal Tasks Category
```swift
// Allow assignments without courseId
struct AppTask {
    var courseId: UUID? // Make optional
    var isPersonal: Bool { courseId == nil }
}
```

### 5. Assignment Linking
```swift
// For cross-semester projects
struct AppTask {
    var linkedAssignmentIds: [UUID]? // Related assignments
    var parentAssignmentId: UUID? // If part of larger project
}
```

---

## Summary

The semester → course → assignment flow is well-structured with:
- **Clear hierarchy**: Semester contains courses, courses contain assignments
- **Flexible navigation**: Multiple entry points to create assignments
- **Context awareness**: Pre-fills course when adding from course detail
- **Centralized state**: CoursesStore manages the data graph

Main areas for enhancement:
- Handling deleted entity references
- Supporting multi-semester workflows
- Scaling semester picker for long-term use
- Adding personal/non-course tasks

The architecture supports academic workflows effectively but could be extended for edge cases like cross-semester projects, summer courses, and personal productivity tracking.
