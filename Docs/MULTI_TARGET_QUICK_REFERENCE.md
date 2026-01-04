# Multi-Target Quick Reference Card

## When to Put Code in ItoriShared vs Platform Targets

### ✅ ItoriShared (Cross-Platform)

**Models**
```swift
// YES - Business entities
struct Course { }
struct Assignment { }
struct Exam { }

// YES - Enums without platform UI types
enum AssignmentUrgency: String {
    case low, medium, high, critical
    var label: String { "Low" }
}
```

**Services**
```swift
// YES - Business logic
struct AssignmentPlanEngine { }
actor SchedulingService { }

// YES - Protocols for platform implementations
protocol PersistenceService { }
```

**Utilities**
```swift
// YES - Date/String helpers
extension Date { }
extension String { }

// YES - Formatters
struct DateFormatter { }
```

**Design Tokens**
```swift
// YES - Platform-neutral layout values
struct Spacing {
    static let small: CGFloat = 8
}

// YES - Typography names (not actual fonts)
struct TypographyNames {
    static let body = "body"
}
```

### ❌ Platform Targets (iOS/macOS)

**SwiftUI Views**
```swift
// Platform-specific
struct DashboardView: View { }
struct CalendarView: View { }
```

**Platform Extensions**
```swift
// Platform-specific color mapping
extension AssignmentUrgency {
    var color: Color { .red }
}

extension Course {
    var color: Color { Color(hex: colorHex) }
}
```

**Platform Capabilities**
```swift
// iOS EventKit integration
class IOSEventKitManager { }

// macOS Commands
struct MacCommands: Commands { }
```

**App Entry Points**
```swift
@main
struct ItoriApp: App { }
```

---

## Quick Decision Tree

```
Is this code...

├─ A data model?
│  ├─ Does it use Color/UIColor/NSColor?
│  │  ├─ Yes → Store as hex string in ItoriShared + platform extension
│  │  └─ No → Put in ItoriShared
│  └─ Yes → Put in ItoriShared
│
├─ Business logic?
│  ├─ Does it call platform APIs?
│  │  ├─ Yes → Protocol in ItoriShared, implementation in target
│  │  └─ No → Put in ItoriShared
│  └─ Yes → Put in ItoriShared
│
├─ A SwiftUI View?
│  └─ Always put in platform target
│
├─ An extension adding Color?
│  └─ Always put in platform target
│
└─ Platform capability (EventKit, Menus, Windows)?
   └─ Always put in platform target
```

---

## Import Statements

### In ItoriShared
```swift
import Foundation  // ✅ Always OK
import SwiftUI     // ⚠️  Only if needed for @Observable, etc.
// NO UIKit, AppKit, EventKit, etc.
```

### In Platform Targets
```swift
import SwiftUI     // ✅ Always OK
import ItoriShared // ✅ Always needed
import EventKit    // ✅ OK (platform-specific)
```

---

## Common Patterns

### Pattern 1: Model with Platform-Specific Colors

**ItoriShared**:
```swift
public struct Course {
    public let id: UUID
    public var colorHex: String  // ← Stored as hex
}
```

**iOS/macOS Target**:
```swift
import SwiftUI
import ItoriShared

extension Course {
    var color: Color {
        Color(hex: colorHex) ?? .blue
    }
}
```

### Pattern 2: Protocol + Platform Implementation

**ItoriShared**:
```swift
public protocol PersistenceService: Actor {
    func saveCourse(_ course: Course) async throws
}
```

**iOS Target**:
```swift
import ItoriShared

actor IOSPersistenceService: PersistenceService {
    func saveCourse(_ course: Course) async throws {
        // CoreData implementation
    }
}
```

**macOS Target**:
```swift
import ItoriShared

actor MacPersistenceService: PersistenceService {
    func saveCourse(_ course: Course) async throws {
        // CoreData implementation
    }
}
```

### Pattern 3: Shared Container + Platform Injection

**ItoriShared**:
```swift
@MainActor
public final class AppContainer: ObservableObject {
    public let persistenceService: any PersistenceService
    public init(persistenceService: any PersistenceService) {
        self.persistenceService = persistenceService
    }
}
```

**iOS App**:
```swift
@main
struct ItoriApp: App {
    @StateObject private var container = AppContainer(
        persistenceService: IOSPersistenceService()
    )
    
    var body: some Scene {
        WindowGroup {
            IOSRootView()
                .environmentObject(container)
        }
    }
}
```

**macOS App**:
```swift
@main
struct ItoriMacApp: App {
    @StateObject private var container = AppContainer(
        persistenceService: MacPersistenceService()
    )
    
    var body: some Scene {
        WindowGroup {
            MacRootView()
                .environmentObject(container)
        }
    }
}
```

---

## File Naming Conventions

| Type | Location | Example |
|------|----------|---------|
| Model | `ItoriShared/Models/` | `Course.swift` |
| Service | `ItoriShared/Services/` | `AssignmentPlanEngine.swift` |
| Protocol | `ItoriShared/Services/Protocols/` | `PersistenceService.swift` |
| iOS View | `ItoriApp/Views/` | `DashboardView.swift` |
| macOS View | `ItoriMac/Views/` | `DashboardView.swift` |
| iOS Extension | `ItoriApp/PlatformExtensions/` | `Color+iOS.swift` |
| macOS Extension | `ItoriMac/PlatformExtensions/` | `Color+macOS.swift` |

---

## Testing Strategy

### Test Shared Code
```swift
// ItoriSharedTests/AssignmentPlanEngineTests.swift
import XCTest
@testable import ItoriShared

final class AssignmentPlanEngineTests: XCTestCase {
    func testGeneratePlan() {
        let engine = AssignmentPlanEngine()
        // Test cross-platform logic
    }
}
```

### Test Platform Code
```swift
// ItoriTests/IOSViewTests.swift
import XCTest
@testable import ItoriApp

final class IOSViewTests: XCTestCase {
    func testDashboardView() {
        // Test iOS-specific view logic
    }
}
```

---

## Build Commands

```bash
# Build iOS
xcodebuild -project Itori.xcodeproj -scheme ItoriApp -sdk iphonesimulator

# Build macOS
xcodebuild -project Itori.xcodeproj -scheme ItoriMac -sdk macosx

# Build and Test Shared Package
cd ItoriShared
swift build
swift test

# Build All Targets
xcodebuild -project Itori.xcodeproj -scheme "All" build
```

---

## Troubleshooting

### "Cannot find 'ItoriShared' in scope"
→ Verify `ItoriShared` is added to target dependencies  
→ Check `import ItoriShared` statement  
→ Clean build folder (⇧⌘K)

### "Type 'Color' not found"
→ Make sure you're using hex strings in models  
→ Create platform extension for `var color: Color`  
→ Import `SwiftUI` in extension file

### "Duplicate symbol" errors
→ Make sure code isn't duplicated in both targets  
→ Check that shared code is only in `ItoriShared`  
→ Verify platform extensions use `#if os(...)` guards

### Package doesn't update
→ File → Packages → Reset Package Caches  
→ File → Packages → Update to Latest Package Versions  
→ Clean build folder

---

## Migration Checklist (Existing Code → New Architecture)

1. **Identify shared code**
   - [ ] List all model files
   - [ ] List all service/business logic files
   - [ ] List all utility files

2. **Move to ItoriShared**
   - [ ] Move models (remove Color properties)
   - [ ] Move services
   - [ ] Move utilities
   - [ ] Update imports to `import Foundation`

3. **Create platform extensions**
   - [ ] Create `Color+iOS.swift`
   - [ ] Create `Color+macOS.swift`
   - [ ] Add color computed properties

4. **Update views**
   - [ ] Add `import ItoriShared` to all views
   - [ ] Update color references to use extensions
   - [ ] Verify compilation

5. **Test**
   - [ ] Build iOS target
   - [ ] Build macOS target
   - [ ] Run both apps
   - [ ] Verify shared changes affect both

---

## Remember

**The Golden Rule**: If it compiles without `import SwiftUI`, `import UIKit`, or `import AppKit`, it belongs in `ItoriShared`.

**The Color Rule**: Models store hex strings. Platform targets provide `var color: Color` computed properties.

**The Service Rule**: Protocols in `ItoriShared`, implementations in platform targets.

**The View Rule**: All SwiftUI views live in platform targets. No exceptions.
