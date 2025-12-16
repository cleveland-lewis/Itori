# Storage Data Inventory

Complete inventory of all persisted entity types in Roots, including title/display name mappings and required fields for Storage Center UI.

**Version:** 1.0  
**Last Updated:** 2025-12-16  
**Related Issues:** #312 (Storage EPIC), #313 (Storage.A)

---

## Overview

This document catalogs every data type that is persisted to disk in the Roots application, organized by domain. Each entity includes:
- **Has Title Field**: Whether the entity has a native `title` property
- **Display Name Strategy**: How to generate a human-readable name for UI lists
- **Context Fields**: Associated course, semester, or date information
- **Storage Location**: Which store/manager handles persistence

---

## Entity Inventory

### 1. Academic Entities

#### 1.1 Course
**Store:** `CoursesStore`  
**Model:** `Course`  
**Has Title:** ✅ Yes (`title` property)  
**Display Name:** Use `title` directly  
**List Row Fields:**
- Title: `course.title`
- Type: "Course"
- Context: `course.code` (e.g., "CS 101")
- Semester: Lookup via `semesterId`
- Date: `createdDate` or use current date

**Search Fields:**
- `title`
- `code`
- `instructor`

---

#### 1.2 Semester
**Store:** `CoursesStore`  
**Model:** `Semester`  
**Has Title:** ❌ No (computed from properties)  
**Display Name:** Construct from `"\(semesterTerm) \(academicYear)"`  
Example: "Fall 2024-2025"

**List Row Fields:**
- Title: Computed name
- Type: "Semester"
- Context: Education level
- Date: `startDate`

**Search Fields:**
- Computed name
- `academicYear`

---

#### 1.3 Assignment/Task
**Store:** `AssignmentsStore`  
**Model:** `AssignmentTask` (inferred from store)  
**Has Title:** ✅ Yes (`title` or `name` property)  
**Display Name:** Use `title`/`name` directly  

**List Row Fields:**
- Title: `task.title`
- Type: "Assignment" / "Homework" / "Project" (based on type)
- Context: Course name via `courseId`
- Date: `dueDate` or `createdDate`

**Search Fields:**
- `title`
- Course name
- Type

---

#### 1.4 Grade Entry
**Store:** `GradesStore`  
**Model:** Grade data (structure TBD)  
**Has Title:** ❌ No (contextual to course)  
**Display Name:** Format as `"Grade for [Course Name]"`

**List Row Fields:**
- Title: Computed
- Type: "Grade"
- Context: Course name
- Date: Entry date or last updated

**Search Fields:**
- Course name
- Letter grade

---

### 2. Planning & Scheduling

#### 2.1 Planner Block
**Store:** `PlannerStore`  
**Model:** `PlannerBlock` or similar  
**Has Title:** ✅ Likely has title/description  
**Display Name:** Use title or generate from activity

**List Row Fields:**
- Title: Block title or activity summary
- Type: "Planner Block"
- Context: Date/time range
- Date: Block start date

**Search Fields:**
- Title/description
- Activity type

---

#### 2.2 Assignment Plan
**Store:** `AssignmentPlanStore`  
**Model:** `AssignmentPlan`  
**Has Title:** ❌ No (derived from assignment)  
**Display Name:** Format as `"Plan: [Assignment Title]"`

**List Row Fields:**
- Title: Computed from assignment
- Type: "Assignment Plan"
- Context: Course name
- Date: Plan creation date

**Search Fields:**
- Associated assignment title
- Course name

---

#### 2.3 Focus Session
**Store:** Focus-related store (if exists)  
**Model:** `FocusSession` (from FocusModels.swift)  
**Has Title:** ❌ No (activity-based)  
**Display Name:** Format as `"Focus: [Duration] - [Activity]"`

**List Row Fields:**
- Title: Computed description
- Type: "Focus Session"
- Context: Duration, activity type
- Date: Session start date

**Search Fields:**
- Activity description

---

### 3. Testing & Practice

#### 3.1 Practice Test
**Store:** `PracticeTestStore`  
**Model:** `PracticeTest`  
**Has Title:** ✅ Likely has name/title  
**Display Name:** Use title or generate from course + topic

**List Row Fields:**
- Title: Test name
- Type: "Practice Test"
- Context: Course name, topic
- Date: Created date

**Search Fields:**
- Title
- Course name
- Topics

---

#### 3.2 Test Blueprint
**Store:** Part of PracticeTestStore  
**Model:** `TestBlueprint` (from TestBlueprintModels.swift)  
**Has Title:** ✅ Likely has title  
**Display Name:** Use title

**List Row Fields:**
- Title: Blueprint title
- Type: "Test Blueprint"
- Context: Course, topics
- Date: Created date

**Search Fields:**
- Title
- Course name

---

### 4. Content & Files

#### 4.1 Course Outline Node
**Store:** Part of CoursesStore  
**Model:** `CourseOutlineNode`  
**Has Title:** ✅ Yes (`title` property)  
**Display Name:** Use title

**List Row Fields:**
- Title: Node title
- Type: "Course Outline" / "Module" / "Week"
- Context: Course name, parent hierarchy
- Date: Created/updated date

**Search Fields:**
- `title`
- Course name
- Content

---

#### 4.2 Course File
**Store:** Part of CoursesStore  
**Model:** `CourseFile`  
**Has Title:** ✅ Yes (`name` or `filename`)  
**Display Name:** Use filename

**List Row Fields:**
- Title: Filename
- Type: "File" / file type extension
- Context: Course name
- Date: Upload date or modification date

**Search Fields:**
- Filename
- Course name
- File type

---

#### 4.3 Attachment
**Store:** Various stores  
**Model:** `Attachment`  
**Has Title:** ✅ Yes (`name` or derived from URL)  
**Display Name:** Use name or filename from URL

**List Row Fields:**
- Title: Attachment name
- Type: "Attachment" + file type
- Context: Parent entity (assignment, course, etc.)
- Date: Added date

**Search Fields:**
- Filename
- Parent context

---

### 5. Syllabus & Parsing

#### 5.1 Parsed Syllabus
**Store:** `SyllabusParsingStore`  
**Model:** Parsed syllabus data  
**Has Title:** ❌ No (contextual to course)  
**Display Name:** Format as `"Syllabus for [Course Name]"`

**List Row Fields:**
- Title: Computed
- Type: "Syllabus"
- Context: Course name
- Date: Parse date

**Search Fields:**
- Course name
- Parsed content

---

#### 5.2 Parsed Assignment
**Store:** `SyllabusParsingStore`  
**Model:** Parsed assignment from syllabus  
**Has Title:** ✅ Yes (extracted title)  
**Display Name:** Use extracted title

**List Row Fields:**
- Title: Assignment title
- Type: "Parsed Assignment"
- Context: Course name, source syllabus
- Date: Due date (if extracted)

**Search Fields:**
- Title
- Course name

---

### 6. Calendar & Events

#### 6.1 Calendar Event
**Store:** `DeviceCalendarManager` / `CalendarManager`  
**Model:** `CalendarEvent` or `EKEvent`  
**Has Title:** ✅ Yes (`title` property)  
**Display Name:** Use title

**List Row Fields:**
- Title: Event title
- Type: "Event" + category (Class, Exam, etc.)
- Context: Calendar name, location
- Date: `startDate`

**Search Fields:**
- Title
- Location
- Category

---

### 7. Settings & Preferences

#### 7.1 Scheduler Preferences
**Store:** `SchedulerPreferencesStore`  
**Model:** Preference data structure  
**Has Title:** ❌ No (settings data)  
**Display Name:** Not applicable (excluded from user-facing storage list)

**List Row Fields:**
- N/A (system data)

---

#### 7.2 App Settings
**Store:** `AppSettingsModel`  
**Model:** Settings properties  
**Has Title:** ❌ No (settings data)  
**Display Name:** Not applicable (excluded from user-facing storage list)

**List Row Fields:**
- N/A (system data)

---

### 8. Timer & Focus

#### 8.1 Timer Session
**Store:** `TimerManager`  
**Model:** Timer data (from TimerModels.swift)  
**Has Title:** ❌ No (duration-based)  
**Display Name:** Format as `"Timer: [Duration] - [Activity]"`

**List Row Fields:**
- Title: Computed description
- Type: "Timer Session"
- Context: Activity/task associated
- Date: Session date

**Search Fields:**
- Activity name
- Associated task

---

## Summary Statistics

### Total Entity Types: 18

**By Title Field Availability:**
- ✅ Has Native Title: 10 entities
- ❌ Requires Computed Display Name: 8 entities

**By Category:**
- Academic: 4 entities
- Planning: 3 entities
- Testing: 2 entities
- Content: 3 entities
- Syllabus: 2 entities
- Calendar: 1 entity
- Settings: 2 entities (excluded from UI)
- Timer: 1 entity

**User-Facing Storage Items:** 16 entities (excluding system settings)

---

## Standard List Row Requirements

For every entity displayed in Storage Center, the following minimum fields must be available:

### Required Fields
1. **Display Title** - Human-readable name (native or computed)
2. **Entity Type** - Category label (e.g., "Course", "Assignment", "File")
3. **Context** - Related course/semester when applicable
4. **Date** - Most relevant timestamp (created, due, modified)

### Optional Fields
5. **Status** - Completion, archived, active state
6. **Size** - For files/attachments
7. **Owner** - User who created (if multi-user future)

### Search Requirements
- All entities must be searchable by their display title
- Course-related entities must be searchable by course name
- Date range filtering must be supported

---

## Display Name Mapping Reference

Quick reference for computed display names:

```swift
enum StorageEntityType {
    case course           // Use: course.title
    case semester         // Use: "\(term) \(year)"
    case assignment       // Use: task.title
    case grade            // Use: "Grade for \(courseName)"
    case plannerBlock     // Use: block.title or activity
    case assignmentPlan   // Use: "Plan: \(assignmentTitle)"
    case focusSession     // Use: "Focus: \(duration) - \(activity)"
    case practiceTest     // Use: test.title
    case testBlueprint    // Use: blueprint.title
    case courseOutline    // Use: node.title
    case courseFile       // Use: file.name
    case attachment       // Use: attachment.name
    case syllabus         // Use: "Syllabus for \(courseName)"
    case parsedAssignment // Use: extractedTitle
    case calendarEvent    // Use: event.title
    case timerSession     // Use: "Timer: \(duration) - \(activity)"
}
```

---

## Notes for Implementation

### Storage.B (List View)
- Use this inventory to build the unified data source
- Implement protocol `StorageListable` requiring: `displayTitle`, `entityType`, `contextDescription`, `primaryDate`
- Create adapters for each entity type to conform to protocol

### Storage.C (Search)
- Index all fields marked as "Search Fields"
- Support multi-field search (title + context)
- Implement fuzzy matching for typos

### Storage.D (Edit/Delete)
- Map entity type to appropriate edit view
- Cascade delete logic based on relationships
- Warn before deleting entities with dependencies

### Retention.G+ (Retention Policy)
- Use `primaryDate` field for age calculations
- Distinguish between "individual data" and "aggregate analytics"
- Implement soft delete for retention-eligible entities

---

## Maintenance

When adding new persisted entities:
1. Add entry to this inventory
2. Specify title strategy (native or computed)
3. Define list row fields
4. Update search field mappings
5. Implement `StorageListable` protocol
6. Update retention policy eligibility

---

**Document Owner:** Data Architecture  
**Review Cycle:** Update with each new persisted entity type  
**Related Docs:** Storage Center Architecture (TBD), Retention Policy Spec (TBD)
