# Changelog

All notable changes to Itori will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [Unreleased]

### Added
- Production readiness gates (hygiene, threading, version checks)
- Release scope documentation (v1.0 feature freeze)
- Threading safety audit framework
- Layout stress test matrix
- Error state audit checklist
- iCloud sync strategy documentation

### Changed
- Enhanced `check_release_hygiene.sh` with additional checks
- Soft delete system with cascade behavior

### Fixed
- (TBD - to be filled during production prep)

---

## [1.0.0] - TBD

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

### Known Limitations
- Single semester selection only (multi-semester deferred to v1.1)
- Task alarm scheduling not included (deferred to v1.1)
- Basic iCloud conflict resolution (last-write-wins)

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
