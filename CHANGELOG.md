# Changelog

All notable changes to Itori will be documented in this file.

## [Unreleased]

### Added
- macOS Dashboard: Clickable assignments in "Upcoming Assignments" card - click any assignment to view/edit details
- macOS Dashboard: Modern popup UI for assignment creation and editing with SF Symbols icons and organized sections
- macOS Dashboard: Parsing status indicators for uploaded syllabus files (progress spinner and success badge)
- macOS Course Detail: Automatic syllabus parsing trigger when importing files
- macOS Course Detail: Real-time parsing status UI with assignment count display
- AddAssignmentView: Support for editing existing assignments (reuses same form for create/edit)

### Fixed
- macOS Dashboard: Fixed scrunched card layout by removing fixed height constraints - cards now properly expand
- macOS Dashboard: Fixed calendar date overflow - dates now fit properly within card boundaries with square aspect ratio
- macOS Dashboard: Responsive layout improvements - proper spacing between cards and sections
- macOS Course Import: Syllabus parsing now automatically triggered on file upload (was not being called)
- macOS Course Import: Added secure file access for sandboxed app file operations

### Changed
- macOS Dashboard: Removed `dashboardRowHeights()` function - cards use natural sizing with minimum heights
- macOS Dashboard: Updated calendar grid spacing from variable to fixed 4pt for better fit
- macOS Dashboard: Calendar date cells now maintain 1:1 aspect ratio
- AddAssignmentView: Complete UI redesign - NavigationStack with toolbar instead of AppCard layout
- AddAssignmentView: Sections now clearly separated with SF Symbols icons and dividers
- AddAssignmentView: Responsive frame sizing (600-800px wide, 500-700px tall)

## [Previous versions...]

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [Unreleased]

### Added
- Pre-commit hook: Markdown file enforcement to prevent documentation sprawl (2026-01-09)
  - Only 5 markdown files allowed: README.md, CHANGELOG.md, BACKLOG.md, PRIVACY_POLICY.md, PRIVACY_POLICY_ENHANCED.md
  - New markdown files are blocked with helpful guidance to use CHANGELOG.md or GitHub issues
  - Completed work → CHANGELOG.md, TODO items → GitHub issues
- Practice test generation system with web-enhanced research (2026-01-12)
  - Web search integration using DuckDuckGo and Wikipedia APIs
  - Generates original multiple-choice questions based on course topics
  - Comprehensive explanations for each question
  - Support for custom difficulty levels and topic selection
  - Mock generation for offline/fallback scenarios

### Changed
- Replaced floating tab bar with native macOS sidebar navigation (2026-01-12)
  - Native NavigationSplitView with collapsible sidebar
  - Improved navigation accessibility and standard macOS behavior
  - Energy indicator and settings moved to toolbar as glass pills
- Renamed all "Roots" references to "Itori" throughout codebase (2026-01-12)
  - Design system components (RootsRadius → ItoriRadius)
  - Window layout classes (RootsWindowLayout → ItoriWindowLayout)
  - Chart containers and UI components
  - Settings window and button styles
- Timer page improvements (2026-01-12)
  - Added timer mode selector (Pomodoro vs. Custom Timer)
  - Custom timer duration picker (1-120 minutes)
  - Timer now counts down from selected duration
  - Centered analog timer dials in card layout
- Improved toolbar layout (2026-01-12)
  - Energy indicator as separate glass pill
  - Settings button as separate glass pill
  - Better vertical alignment and spacing
  - Added accessibility labels and hints to all toolbar buttons

### Fixed
- SwiftFormat compliance across all Swift files
- Accessibility labels for toolbar buttons (energy indicator, settings)
- File naming conventions (test_practice_generation.swift → TestPracticeGeneration.swift)

---

## [1.0.0] - 2026-01-05

### Added
- Dashboard with upcoming tasks and calendar events
- Course management (add/edit/delete with soft delete)
- Assignment tracking (homework, exams, tasks)
- Timer functionality with Pomodoro support
- Calendar integration (read device calendar)
- Study analytics (trackStudyHours feature)
- Planner with auto-scheduling (PlannerEngine)
- iCloud sync (last-write-wins strategy)
- Multi-platform support (macOS, iOS, iPadOS)
- Localization support (English + translations)
- Design system with spacing tokens
- Dark mode support
- Basic accessibility (VoiceOver labels)

### Production Hardening (Fast Track)
- Added @MainActor to all 21 UI-facing State classes
- Removed 96+ backup files and merge artifacts
- Audited and normalized TODOs (44 → 10 deferred)
- Fixed 10 compilation errors across iOS/macOS
- Disabled 8 broken test files (documented for v1.1)
- Verified empty states in core views (Assignments, Dashboard)
- Verified error handling for LLM failures
- Enhanced CI gates (hygiene + threading + version + builds)

### Known Limitations
- Single semester selection only (multi-semester deferred to v1.1)
- Task alarm scheduling not included (deferred to v1.1)
- Basic iCloud conflict resolution (last-write-wins)
- 39 force unwraps in critical paths (deferred to v1.1)
- Generic empty state messages (deferred to v1.1)
- CalendarAccessBanner not integrated (deferred to v1.1)

### Technical Debt
- activeSemesterIds backend kept for migration (UI uses single semester)
- Some platform-specific tests disabled pending fixes
- Manual QA required for iCloud error handling
- Layout stress testing deferred to manual QA phase

---

## Release Notes Template

When cutting a release, copy this template:

```
## [X.Y.Z] - YYYY-MM-DD

### Added
- New feature description

### Changed
- Changed feature description

### Fixed
- Bug fix description

### Removed
- Deprecated feature removed
```
