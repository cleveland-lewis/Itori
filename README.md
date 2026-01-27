# Itori

A comprehensive academic planning and productivity platform for students, designed to intelligently manage coursework, assignments, study sessions, and schedules across all your Apple devices.

## Overview

Itori is a native SwiftUI application that combines intelligent scheduling, assignment tracking, flashcard learning, and time management into a unified academic workflow. Built from the ground up for macOS, iOS, and iPadOS with iCloud sync.

### Key Features

- **Intelligent Planner** — AI-powered scheduling that adapts to your workload, deadlines, and energy levels
- **Assignment Management** — Track homework, projects, exams, and recurring tasks with automatic reminders
- **Flashcard System** — Spaced repetition learning with multi-deck support and progress tracking
- **Focus Timer** — Pomodoro and custom timer modes with session history and analytics
- **Calendar Integration** — Native EventKit integration with conflict detection and smart scheduling
- **Course Organization** — Semester-based course management with grade tracking and file organization
- **Practice Tests** — Generate timed practice exams from your coursework
- **Cross-Platform Sync** — Seamless iCloud synchronization across Mac, iPhone, and iPad

## Technical Architecture

### Platform Support
- **macOS** 13.0+ (Ventura and later)
- **iOS/iPadOS** 17.0+ (iOS 17 and later)
- Swift 5.9+, SwiftUI lifecycle

### Core Technologies
- **SwiftUI** — Modern declarative UI framework
- **Core Data + CloudKit** — Persistent storage with cloud sync
- **EventKit** — Native calendar and reminder integration
- **StoreKit 2** — In-app subscriptions and purchases
- **Combine** — Reactive data flow and state management
- **App Intents** — Siri shortcuts and system integration (iOS 16+)

### Architecture Pattern
- **MVVM** with `@Observable` (iOS 17+) and `ObservableObject` (iOS 16 compatibility)
- **Shared Core** — Business logic shared between platforms in `SharedCore/`
- **Platform Adapters** — Platform-specific UI in `Platforms/iOS/` and `Platforms/macOS/`
- **Feature Services** — Modular services for AI scheduling, notifications, file parsing, etc.

## Project Structure

```
Itori/
├── SharedCore/                 # Shared business logic
│   ├── Models/                 # Data models
│   ├── State/                  # State management (Stores, ViewModels)
│   ├── Persistence/            # Core Data stack and repositories
│   ├── Services/               # Business services
│   │   └── FeatureServices/    # Modular feature implementations
│   ├── Features/               # Feature modules (Scheduler, etc.)
│   └── Utilities/              # Helpers and extensions
├── Platforms/
│   ├── iOS/                    # iOS/iPadOS specific code
│   │   ├── App/                # App lifecycle
│   │   ├── Scenes/             # View controllers and scenes
│   │   └── Root/               # Navigation and shell
│   └── macOS/                  # macOS specific code
│       ├── App/                # App lifecycle and menu bar
│       ├── Scenes/             # Views and windows
│       └── PlatformAdapters/   # macOS-specific adapters
├── Tests/                      # Unit and UI tests
├── Config/                     # Configuration files
├── Scripts/                    # Build and automation scripts
└── Docs/                       # Technical documentation
```

## Getting Started

### Prerequisites
- Xcode 15.0 or later
- macOS 13.0 (Ventura) or later for development
- Apple Developer account (for iCloud and App Store features)

### Building the Project

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd Itori
   ```

2. **Open in Xcode**
   ```bash
   open ItoriApp.xcodeproj
   ```

3. **Select your target**
   - `Itori` — iOS/iPadOS app
   - `Itori (macOS)` — macOS app

4. **Configure signing**
   - Update the Development Team in project settings
   - Enable iCloud capability with your container

5. **Install Git hooks** (recommended)
   ```bash
   ./Scripts/install-git-hooks.sh
   ```

6. **Install development tools**
   ```bash
   brew install swiftlint swiftformat
   ```

7. **Build and run**
   - `Cmd+R` to build and run
   - Select target device/simulator

### Configuration

#### iCloud Setup
1. Enable iCloud capability in Xcode
2. Select CloudKit container: `iCloud.com.yourteam.itori`
3. Update `PersistenceController.swift` with your container ID

#### Subscription Setup (Optional)
1. Configure StoreKit products in `Config/ItoriSubscriptions.storekit`
2. Update `SubscriptionManager.swift` with your product IDs
3. Test with StoreKit Configuration file

## Development

### Pre-Commit Hooks

The project enforces code quality with pre-commit hooks that run automatically before each commit:

- [x] Repository hygiene (trailing whitespace, file sizes, naming)
- [x] Swift code quality (SwiftLint, SwiftFormat)
- [x] App rename enforcement (Roots → Itori)
- [x] Build sanity checks
- [x] Architectural guardrails (platform boundaries)
- [x] TODO/FIXME policy
- [x] Commit message discipline

**Install hooks:**
```bash
./Scripts/install-git-hooks.sh
```

**Documentation:**
- Full guide: [PRE_COMMIT_HOOKS_GUIDE_V2.md](PRE_COMMIT_HOOKS_GUIDE_V2.md)
- Quick reference: [PRE_COMMIT_HOOKS_QUICK_REF.md](PRE_COMMIT_HOOKS_QUICK_REF.md)

**Bypass (emergency only):**
```bash
git commit --no-verify
```

### Code Quality Tools

The project includes automated quality checks:

```bash
# Run SwiftLint
swiftlint

# Auto-fix SwiftLint issues
swiftlint --fix

# Format code with SwiftFormat
swiftformat .

# Check for code hygiene issues
bash Scripts/check_release_hygiene.sh

# Verify threading safety
bash Scripts/check_threading_safety.sh

# Check version synchronization
bash Scripts/check_version_sync.sh

# Run localization checks
python3 Scripts/localize_swift.py <file>
```

### Testing

```bash
# Run unit tests
xcodebuild test -scheme Itori -destination 'platform=iOS Simulator,name=iPhone 15'

# Run UI tests
xcodebuild test -scheme ItoriUITests -destination 'platform=iOS Simulator,name=iPhone 15'

# Quick test script
bash run-quick-tests.sh
```

### Localization

The app supports multiple languages:
- English (base)
- German (de)
- Hebrew (he)
- Spanish (es)
- French (fr)

Add new strings to `SharedCore/DesignSystem/Localizable.xcstrings`.

## Features in Development

### Current Focus (v1.0)
- Core assignment and course management
- Calendar integration with EventKit
- Basic flashcard system
- Pomodoro timer with session tracking
- iCloud sync for all data types
- AI-powered study plan generation (opt-in, in progress)
- Practice test generation (in progress)

### Planned (v1.1+)
See `BACKLOG.md` for the full roadmap.

## Architecture Decisions

### Why SwiftUI?
Native performance, modern APIs, and shared code between platforms.

### Why Core Data + CloudKit?
Robust offline-first architecture with automatic conflict resolution and reliable sync.

### Why Shared Core?
80% of business logic is platform-agnostic. SharedCore enables:
- Single source of truth for data models
- Unified testing across platforms
- Faster feature development

### Why No Third-Party Dependencies?
- Reduced maintenance burden
- Smaller app size
- Better long-term stability
- Full control over behavior

## Contributing

This is a private project. For inquiries, please contact the development team.

## Privacy & Data

- **Local-first**: All data stored locally in Core Data
- **Optional iCloud**: User controls cloud sync via settings
- **No analytics**: No third-party tracking or analytics
- **No ads**: Premium features via subscription only

## License

Proprietary. All rights reserved.

## Support

For support inquiries:
- Email: support@itori.app
- Documentation: See `Docs/` directory
- Issues: Internal issue tracker

---

**Version:** 1.0.0  
**Last Updated:** January 6, 2026  
**Minimum Deployment:** iOS 17.0, macOS 13.0
