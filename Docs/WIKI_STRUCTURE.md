# GitHub Wiki Structure

This document outlines the intended structure and content for the Roots GitHub Wiki. The Wiki serves as comprehensive user documentation.

---

## Wiki Page Hierarchy

### 1. Home

**Purpose:** Entry point and navigation hub

**Content:**
- Brief application overview (2-3 sentences)
- Feature summary (bullet list, non-technical)
- Platform compatibility statement
- Navigation links to all major sections
- Status disclaimer (active development, no warranties)
- Link to LICENSE and repository terms

**Tone:** Neutral, professional, informative

---

### 2. Getting Started

**Purpose:** Initial setup and orientation for new users

**Content:**
- System requirements (macOS version, hardware)
- Installation overview (no source build instructions)
- First launch behavior and data initialization
- Account/profile setup (if applicable)
- Basic navigation concepts
- Settings location and initial configuration recommendations

**What NOT to include:**
- Source code compilation steps
- Development environment setup
- Contributing guidelines

---

### 3. Core Concepts

**Purpose:** Explain fundamental data models and relationships

**Content:**

#### Semesters
- What a semester represents in the application
- Academic year cycles and term structures
- How semesters relate to courses
- Active vs. archived semester behavior
- Semester metadata (dates, credits, status)

#### Courses
- Course structure and properties
- Credit hours and grading scales
- Course codes, titles, and descriptions
- Instructor information handling
- Archiving and deletion behavior
- Course-assignment relationships

#### Modules / Structural Units
- How courses can be subdivided (if applicable)
- Module-based organization of content
- Relationship between modules and assignments

#### Assignments
- Assignment categories (Exam, Quiz, Project, Homework, Reading)
- Assignment properties:
  - Due dates and time specificity
  - Priority and importance levels
  - Estimated duration and effort
  - Category-specific attributes
- Assignment lifecycle (creation → completion → archiving)
- Relationship to courses and planner sessions

---

### 4. Planner & Scheduler

**Purpose:** Explain how the automated planning system works from a user perspective

**Content:**

#### Planner Overview
- What the planner does (transforms assignments into scheduled sessions)
- Time block structure (30-minute increments, daily schedule range)
- Session types (Study Session, Work Session, Reading Block)
- Relationship between assignments and generated sessions

#### How Scheduling Works
- Assignment → session generation logic (user-facing explanation)
- Priority and due date influence on scheduling order
- Energy level matching (if user configures energy preferences)
- Multi-day distribution for long-term assignments
- Handling of fixed vs. flexible time slots

#### Overflow Queue
- What happens when sessions cannot fit into available time
- How users can address overflow
- Manual rescheduling options

#### Manual Adjustments
- Moving sessions between time slots
- Marking sessions complete
- Rescheduling and regeneration triggers

**What NOT to include:**
- Algorithmic formulas or implementation details
- Internal variable names or code references
- Proprietary scheduling heuristics

---

### 5. Calendar & Timeline Views

**Purpose:** Explain visual interfaces for viewing scheduled time

**Content:**
- Day, week, and month views (if applicable)
- Timeline visualization (time-blocked schedule display)
- Color coding and visual indicators
- Session detail inspection
- Filtering options (by course, by category, by status)
- Calendar export/import behavior (if supported)
- Integration with system calendars (read-only vs. bidirectional)

---

### 6. Dashboard

**Purpose:** Explain the information aggregation interface

**Content:**
- Dashboard card types and their purpose
- Active task summary behavior
- Upcoming deadlines display
- GPA / grade summary presentation
- Quick action shortcuts
- Customization options (if available)
- Data refresh and update behavior

---

### 7. Grades & Performance Tracking

**Purpose:** Explain grade calculation and academic performance features

**Content:**
- Grade entry and calculation methods
- Grading scales and configurations
- Weighted vs. unweighted GPA
- Grade component types (if supported: assignments, exams, participation)
- Grade projection and "what-if" scenarios
- Transcript-style views
- Grade history and trend analysis

**What NOT to include:**
- Internal calculation formulas beyond basic weighted averages
- Implementation details of grade storage

---

### 8. Focus & Productivity Tools

**Purpose:** Explain timer-based productivity features

**Content:**
- Focus timer functionality (Pomodoro-style or general)
- Session duration configuration
- Break intervals and automation
- Notification behavior
- Focus mode integration with system features (Do Not Disturb, etc.)
- Session history and tracking
- Productivity metrics (if displayed)

---

### 9. Practice Tests

**Purpose:** Explain question-based review and self-testing features

**Content:**
- What practice tests are and their purpose
- Creating practice test sets (if user-facing)
- Question types supported
- Test-taking interface and behavior
- Results, scoring, and feedback
- Review and retry options
- Integration with assignments or courses

**What NOT to include:**
- AI-generated content algorithms or prompts
- Question generation implementation details
- Internal storage schema for test data

---

### 10. Data & Storage

**Purpose:** Explain how user data is handled

**Content:**

#### Local Storage
- Where data is stored (application container, documents, etc.)
- Data persistence guarantees
- What is stored locally vs. remotely (if applicable)

#### Cloud Sync (if applicable)
- iCloud sync behavior and requirements
- Conflict resolution approach (user-facing)
- Sync status indicators and troubleshooting

#### Backup & Export
- Export formats supported (if any)
- Data portability options
- Backup recommendations
- Data retention policies

#### Privacy
- What data is collected (if any)
- Third-party service usage (analytics, crash reporting)
- Data transmission policies
- Local-only operation guarantees

**What NOT to include:**
- Database schema details
- Internal data model structures
- File format specifications intended for reverse engineering

---

### 11. Settings & Configuration

**Purpose:** Explain user-configurable options

**Content:**

#### General Settings
- Application preferences overview
- Visual/appearance customization
- Notification configuration
- Default behaviors and automation settings

#### Scheduling Preferences
- Time window configuration (daily schedule range)
- Energy profile setup (if applicable)
- Priority and sorting preferences
- Session duration defaults

#### Integration Settings
- Calendar connections
- External service configurations (if any)
- API key management (if user-facing)

#### Advanced Settings
- Developer mode (if exposed to users)
- Logging and diagnostics
- Reset and data clearing options

---

### 12. FAQ / Troubleshooting

**Purpose:** Address common questions and issues

**Content:**

#### General Questions
- What platforms are supported?
- Is an internet connection required?
- How is data stored and synchronized?
- Can data be exported?

#### Common Issues
- Scheduling sessions not appearing
- Assignments not generating sessions
- Calendar sync problems
- Performance or responsiveness issues
- Data loss or corruption scenarios

#### Limitations
- Known feature limitations
- Platform-specific constraints
- Unsupported configurations

**What NOT to include:**
- Bug workarounds that expose implementation details
- Instructions for modifying source code or configuration files

---

### 13. Known Limitations

**Purpose:** Document current constraints and missing features

**Content:**
- Features planned but not yet implemented
- Platform-specific limitations (macOS vs. iOS, etc.)
- Performance constraints (maximum data volumes, etc.)
- Integration limitations with external services
- Accessibility limitations

**Tone:** Factual, non-defensive, forward-looking without making promises

---

## Wiki Maintenance

### Style Guidelines
- Use neutral, professional tone throughout
- Write in third person or imperative mood (avoid "you" where possible)
- Prioritize clarity over completeness
- Use consistent terminology across pages
- Include visual aids (screenshots, diagrams) where helpful
- Avoid implementation jargon unless necessary for user understanding

### Update Cadence
- Update Wiki with each major feature release
- Document breaking changes immediately
- Keep FAQ updated based on actual user questions
- Review for accuracy quarterly

### Cross-Referencing
- Link between related Wiki pages extensively
- Use consistent section anchors for deep linking
- Maintain table of contents on longer pages
- Reference LICENSE and SECURITY.md where relevant

---

## Implementation Notes

This structure document should be used to create actual Wiki pages on GitHub. Each section above represents a separate Wiki page.

GitHub Wiki pages are created through the repository's Wiki tab and are maintained in a separate Git repository (`.wiki`).

---

Last Updated: December 17, 2025
