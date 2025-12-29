# Comprehensive Roots App Test Plan
## Test Date: December 29, 2025

### Test Objective
Verify complete end-to-end functionality of the Roots study planning system including:
1. Academic structure setup (semesters & courses)
2. Assignment creation across multiple types
3. Automatic plan generation
4. Study event scheduling with tasks
5. Dynamic rescheduling based on progress

---

## Phase 1: Academic Structure Setup

### 1.1 Create Semester
- [ ] Open app and navigate to Courses/Semesters
- [ ] Create new semester: "Spring 2026"
- [ ] Set dates: Jan 13, 2026 - May 8, 2026
- [ ] Verify semester appears in list

### 1.2 Create Full Course Load (5 Courses)
Create the following courses:

1. **CS 301 - Algorithms & Data Structures**
   - Credit Hours: 4
   - Instructor: Dr. Johnson
   - Color: Blue

2. **MATH 251 - Calculus III**
   - Credit Hours: 4
   - Instructor: Prof. Williams
   - Color: Red

3. **ENG 202 - Technical Writing**
   - Credit Hours: 3
   - Instructor: Dr. Martinez
   - Color: Green

4. **PHYS 201 - Modern Physics**
   - Credit Hours: 4
   - Instructor: Prof. Chen
   - Color: Purple

5. **HIST 105 - World History**
   - Credit Hours: 3
   - Instructor: Dr. Anderson
   - Color: Orange

**Verification Points:**
- [ ] All 5 courses created successfully
- [ ] Total: 18 credit hours
- [ ] All courses linked to Spring 2026 semester
- [ ] Each course has distinct color

---

## Phase 2: Assignment Creation

### 2.1 CS 301 - Algorithms (5 assignments)
1. **Programming Project 1**
   - Type: Project
   - Due: Feb 5, 2026
   - Estimated Hours: 15
   - Priority: High

2. **Midterm Exam**
   - Type: Midterm
   - Due: Mar 12, 2026
   - Study Hours: 10
   - Priority: High

3. **Lab Assignment 3**
   - Type: Lab
   - Due: Mar 20, 2026
   - Estimated Hours: 5
   - Priority: Medium

4. **Programming Project 2**
   - Type: Project
   - Due: Apr 10, 2026
   - Estimated Hours: 20
   - Priority: High

5. **Final Exam**
   - Type: Final
   - Due: May 6, 2026
   - Study Hours: 15
   - Priority: High

### 2.2 MATH 251 - Calculus (5 assignments)
1. **Problem Set 1**
   - Type: Homework
   - Due: Jan 25, 2026
   - Estimated Hours: 6
   - Priority: Medium

2. **Midterm Exam**
   - Type: Midterm
   - Due: Mar 5, 2026
   - Study Hours: 12
   - Priority: High

3. **Lab Report**
   - Type: Lab
   - Due: Mar 28, 2026
   - Estimated Hours: 4
   - Priority: Medium

4. **Practice Test**
   - Type: Practice Test
   - Due: Apr 15, 2026
   - Study Hours: 8
   - Priority: Medium

5. **Final Exam**
   - Type: Final
   - Due: May 7, 2026
   - Study Hours: 18
   - Priority: High

### 2.3 ENG 202 - Technical Writing (5 assignments)
1. **Essay 1: Technical Description**
   - Type: Essay
   - Due: Feb 10, 2026
   - Estimated Hours: 8
   - Priority: Medium

2. **Midterm Portfolio**
   - Type: Midterm
   - Due: Mar 15, 2026
   - Estimated Hours: 10
   - Priority: High

3. **Research Paper Draft**
   - Type: Essay
   - Due: Apr 5, 2026
   - Estimated Hours: 12
   - Priority: High

4. **Presentation Project**
   - Type: Project
   - Due: Apr 20, 2026
   - Estimated Hours: 6
   - Priority: Medium

5. **Final Research Paper**
   - Type: Final
   - Due: May 5, 2026
   - Estimated Hours: 15
   - Priority: High

### 2.4 PHYS 201 - Modern Physics (5 assignments)
1. **Lab Report 1**
   - Type: Lab
   - Due: Feb 3, 2026
   - Estimated Hours: 5
   - Priority: Medium

2. **Problem Set 3**
   - Type: Homework
   - Due: Feb 28, 2026
   - Estimated Hours: 7
   - Priority: Medium

3. **Midterm Exam**
   - Type: Midterm
   - Due: Mar 18, 2026
   - Study Hours: 14
   - Priority: High

4. **Lab Report 2**
   - Type: Lab
   - Due: Apr 8, 2026
   - Estimated Hours: 6
   - Priority: Medium

5. **Final Exam**
   - Type: Final
   - Due: May 8, 2026
   - Study Hours: 16
   - Priority: High

### 2.5 HIST 105 - World History (5 assignments)
1. **Reading Response 1**
   - Type: Essay
   - Due: Jan 30, 2026
   - Estimated Hours: 4
   - Priority: Low

2. **Midterm Exam**
   - Type: Midterm
   - Due: Mar 8, 2026
   - Study Hours: 8
   - Priority: High

3. **Research Essay**
   - Type: Essay
   - Due: Apr 1, 2026
   - Estimated Hours: 10
   - Priority: Medium

4. **Practice Quiz**
   - Type: Practice Test
   - Due: Apr 18, 2026
   - Study Hours: 5
   - Priority: Low

5. **Final Exam**
   - Type: Final
   - Due: May 4, 2026
   - Study Hours: 12
   - Priority: High

**Total Assignments: 25 across 5 courses**

---

## Phase 3: Planner Verification

### 3.1 Check Auto-Planning
- [ ] Navigate to Planner view
- [ ] Verify plans exist for ALL 25 assignments
- [ ] Check that each plan has:
  - Start date (calculated from due date)
  - Daily study blocks
  - Appropriate time allocation

### 3.2 Verify Plan Distribution
For each assignment type, verify appropriate planning:

**Projects:**
- [ ] Multi-day sessions
- [ ] Building/coding blocks
- [ ] Testing periods

**Essays:**
- [ ] Research phase
- [ ] Drafting sessions
- [ ] Revision periods

**Labs:**
- [ ] Pre-lab reading
- [ ] Execution time
- [ ] Report writing

**Exams (Midterms/Finals):**
- [ ] Multiple study sessions
- [ ] Review periods
- [ ] Practice testing

---

## Phase 4: Study Event Scheduling

### 4.1 Verify Calendar Events Created
Navigate to Calendar view and verify:

#### Event Types Should Include:
- [ ] **"Studying"** events - Active learning sessions
- [ ] **"Reading"** events - Textbook/material review
- [ ] **"Reviewing"** events - Flashcard practice
- [ ] **"Practice Testing"** events - Mock exams/quizzes

### 4.2 Event Verification Checklist
For each scheduled event, verify:
- [ ] Event has clear title (e.g., "Studying: CS 301 Midterm")
- [ ] Event has assigned time block
- [ ] Event is linked to correct course
- [ ] Event appears on correct date
- [ ] Events don't overlap inappropriately

### 4.3 Task Association
For each calendar event, verify:
- [ ] Event has associated tasks
- [ ] Tasks are specific (e.g., "Review Chapter 5 notes")
- [ ] Tasks align with assignment requirements
- [ ] Tasks have checkboxes/completion status
- [ ] Task count is reasonable (2-5 per session)

### 4.4 Study Event Examples to Find

**For CS 301 Midterm (Mar 12):**
- [ ] "Studying: Algorithms Review" (multiple days)
- [ ] "Practice Testing: Algorithm Problems"
- [ ] "Reviewing: Data Structure Flashcards"

**For MATH 251 Final (May 7):**
- [ ] "Reading: Calculus Chapters 8-12"
- [ ] "Studying: Integration Techniques"
- [ ] "Practice Testing: Past Exams"
- [ ] "Reviewing: Formula Flashcards"

**For ENG 202 Research Paper (May 5):**
- [ ] "Reading: Source Materials"
- [ ] "Studying: Writing Outline"
- [ ] "Reviewing: Draft Feedback"

---

## Phase 5: Priority Algorithm & Dynamic Rescheduling

### 5.1 Test Task Completion Effects

#### Test Scenario 1: Complete Tasks On Time
1. [ ] Select a "Studying" event with 3 tasks
2. [ ] Mark all tasks as complete
3. [ ] Verify next study session adjusts appropriately
4. [ ] Check that schedule doesn't add unnecessary sessions

#### Test Scenario 2: Miss/Skip Tasks
1. [ ] Select a "Reading" event with tasks
2. [ ] Let event time pass WITHOUT completing tasks
3. [ ] Verify system responds:
   - [ ] Reschedules missed work
   - [ ] Adds catch-up sessions
   - [ ] Adjusts future sessions

#### Test Scenario 3: Partial Completion
1. [ ] Complete 2 out of 4 tasks in an event
2. [ ] Mark event as done
3. [ ] Verify:
   - [ ] Incomplete tasks carry forward
   - [ ] Schedule adds compensating time
   - [ ] Priority recalculates

### 5.2 Test Event Adjustment

#### Scenario 1: Move an Event
1. [ ] Find a "Studying" event scheduled for tomorrow
2. [ ] Drag/move event to different day
3. [ ] Verify:
   - [ ] System accepts the change
   - [ ] Dependent tasks reschedule
   - [ ] No conflicts created
   - [ ] Priority matrix updates

#### Scenario 2: Delete an Event
1. [ ] Delete a "Practice Testing" event
2. [ ] Verify:
   - [ ] Tasks redistribute to other sessions
   - [ ] Total study time maintained
   - [ ] Schedule rebalances

### 5.3 Priority Matrix Verification

The system should prioritize based on:
1. **Due Date Proximity** (closer = higher priority)
2. **Assignment Type** (Finals > Midterms > Projects > Homework)
3. **Completion Status** (incomplete/behind = higher)
4. **Credit Hours** (4-credit courses > 3-credit)

#### Test Priority Sorting:
- [ ] Create list of all current tasks
- [ ] Verify sorting follows priority rules
- [ ] Check high-priority items scheduled first
- [ ] Confirm low-priority items can be moved

#### Test Rebalancing:
1. [ ] Mark several high-priority tasks complete
2. [ ] Verify medium-priority tasks move up
3. [ ] Check schedule redistributes time
4. [ ] Confirm algorithm adjusts appropriately

---

## Phase 6: Edge Cases & Stress Tests

### 6.1 Overlapping Deadlines
- [ ] Check behavior when 3+ assignments due same week
- [ ] Verify fair time distribution
- [ ] Confirm no single course dominates

### 6.2 Last-Minute Assignments
- [ ] Add new assignment due in 3 days
- [ ] Verify emergency scheduling
- [ ] Check priority boost

### 6.3 Long-Term Planning
- [ ] Navigate to May 2026 (end of semester)
- [ ] Verify finals week is properly scheduled
- [ ] Check for study session clustering
- [ ] Confirm no conflicts

---

## Success Criteria

### ✅ Phase 1: Structure
- 1 semester created
- 5 courses created
- All courses properly linked

### ✅ Phase 2: Content
- 25 assignments created (5 per course)
- All assignment types represented
- Varied due dates throughout semester

### ✅ Phase 3: Planning
- Auto-planner creates plan for every assignment
- Plans have reasonable time allocations
- Plans respect course priorities

### ✅ Phase 4: Scheduling
- Calendar shows study events for all assignments
- Events have appropriate titles (Studying, Reading, Reviewing, Practice Testing)
- Each event contains specific tasks
- Tasks align with assignment goals

### ✅ Phase 5: Dynamics
- Completing tasks updates schedule
- Missing tasks triggers rescheduling
- Moving events causes rebalancing
- Priority algorithm functions correctly

---

## Failure Points to Document

If any test fails, document:
1. What was expected
2. What actually happened
3. Error messages (if any)
4. Steps to reproduce
5. Potential cause

---

## Testing Environment

- **Platform:** macOS / iOS (specify)
- **App Version:** Current build
- **Test Date:** December 29, 2025
- **Tester:** [Name]

---

## Notes Section

Use this space to document observations, bugs, or suggestions during testing.

