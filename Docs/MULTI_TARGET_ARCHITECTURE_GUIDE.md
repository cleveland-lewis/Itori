# Itori Multi-Target Architecture - Implementation Guide

## Overview
This guide restructures Itori into a clean multi-target architecture with maximum code sharing and platform-native UIs.

## Architecture Goals
✅ Multiple targets: iOS/iPadOS + macOS  
✅ Shared Swift Package (`ItoriShared`) with cross-platform logic  
✅ Platform-specific UI in each target  
✅ No code duplication for business logic  
✅ Apple-native (SwiftUI, no Catalyst)  
✅ Clean dependency injection  

---

## Part 1: Recommended Folder Layout

```
Itori/
├── Itori.xcodeproj/
│
├── ItoriShared/                           # Swift Package (cross-platform)
│   ├── Package.swift
│   ├── Sources/
│   │   └── ItoriShared/
│   │       ├── Models/
│   │       │   ├── Course.swift
│   │       │   ├── Assignment.swift
│   │       │   ├── Exam.swift
│   │       │   ├── Schedule.swift
│   │       │   ├── Semester.swift
│   │       │   ├── Grade.swift
│   │       │   └── PlanningModels.swift
│   │       ├── Services/
│   │       │   ├── Protocols/
│   │       │   │   ├── PersistenceService.swift
│   │       │   │   ├── SchedulingEngine.swift
│   │       │   │   └── PlanningEngine.swift
│   │       │   ├── AssignmentPlanEngine.swift
│   │       │   ├── SchedulerAdaptation.swift
│   │       │   ├── AutoScheduler.swift
│   │       │   └── CalendarManager.swift
│   │       ├── Persistence/
│   │       │   ├── PersistenceContainer.swift
│   │       │   ├── CoreDataStack.swift
│   │       │   └── PersistenceFactory.swift
│   │       ├── Utilities/
│   │       │   ├── DateHelpers.swift
│   │       │   ├── Formatters.swift
│   │       │   ├── Validation.swift
│   │       │   └── Constants.swift
│   │       ├── DesignTokens/
│   │       │   ├── Spacing.swift
│   │       │   ├── Typography.swift
│   │       │   ├── BorderRadius.swift
│   │       │   └── Layout.swift
│   │       └── Localization/
│   │           └── LocalizationKeys.swift
│   └── Tests/
│       └── ItoriSharedTests/
│
├── ItoriApp/                              # iOS/iPadOS Target
│   ├── ItoriApp.swift                     # App entry point
│   ├── Info.plist
│   ├── Itori.entitlements
│   ├── Views/
│   │   ├── Dashboard/
│   │   ├── Calendar/
│   │   ├── Planner/
│   │   ├── Assignments/
│   │   ├── Courses/
│   │   ├── Timer/
│   │   └── Settings/
│   ├── Navigation/
│   │   ├── IOSRootView.swift
│   │   ├── IOSTabBar.swift
│   │   └── IOSNavigationCoordinator.swift
│   ├── PlatformExtensions/
│   │   ├── Color+iOS.swift               # Platform-specific color extensions
│   │   ├── Assignment+iOS.swift          # iOS-specific Assignment extensions
│   │   └── EventKit+iOS.swift
│   ├── DependencyInjection/
│   │   └── AppDependencies.swift
│   └── Assets.xcassets/
│
├── ItoriMac/                              # macOS Target
│   ├── ItoriMacApp.swift                  # App entry point
│   ├── Info.plist
│   ├── ItoriMac.entitlements
│   ├── Views/
│   │   ├── Dashboard/
│   │   ├── Calendar/
│   │   ├── Planner/
│   │   ├── Assignments/
│   │   ├── Courses/
│   │   ├── Timer/
│   │   └── Settings/
│   ├── Navigation/
│   │   ├── MacRootView.swift
│   │   ├── MacSidebar.swift
│   │   └── MacCommands.swift
│   ├── PlatformExtensions/
│   │   ├── Color+macOS.swift             # Platform-specific color extensions
│   │   ├── Assignment+macOS.swift        # macOS-specific Assignment extensions
│   │   └── EventKit+macOS.swift
│   ├── DependencyInjection/
│   │   └── AppDependencies.swift
│   └── Assets.xcassets/
│
└── ItoriTests/                            # Shared tests (optional)
    └── ItoriSharedTests/
```

---

## Part 2: Xcode Steps to Create Multi-Target Architecture

### Step 1: Create the Shared Swift Package

1. **In Finder**, navigate to your `Itori` project folder
2. Create a new folder named `ItoriShared` at the root level (same level as `Itori.xcodeproj`)
3. **In Terminal**, navigate to the `ItoriShared` folder:
   ```bash
   cd /path/to/Itori/ItoriShared
   ```
4. Create a new Swift Package:
   ```bash
   swift package init --type library --name ItoriShared
   ```
5. Edit `Package.swift` to match the structure below

### Step 2: Add ItoriShared Package to Xcode Project

1. Open `Itori.xcodeproj` in Xcode
2. **File → Add Package Dependencies...**
3. Click **"Add Local..."** button
4. Navigate to and select the `ItoriShared` folder
5. Click **"Add Package"**
6. In the dialog, select **both targets** (iOS and macOS)
7. Click **"Add Package"**

### Step 3: Add macOS Target

1. In Xcode, select your project in the navigator
2. Click the **"+"** button at the bottom of the targets list
3. Choose **macOS → App**
4. Fill in:
   - Product Name: `ItoriMac`
   - Team: Your development team
   - Organization Identifier: `com.yourcompany`
   - Interface: **SwiftUI**
   - Language: **Swift**
   - ✅ Include Tests
5. Click **"Finish"**
6. When prompted to create schemes, click **"Activate"**

### Step 4: Rename iOS Target (Optional but Recommended)

1. Select the iOS target in the project navigator
2. Click on the target name (it might be "Itori")
3. Rename it to `ItoriApp`
4. Update the scheme name to match

### Step 5: Configure Target Dependencies

**For iOS Target (ItoriApp)**:
1. Select `ItoriApp` target → **General** tab
2. Scroll to **Frameworks, Libraries, and Embedded Content**
3. Click **"+"** → Add `ItoriShared`
4. Set to **"Do Not Embed"** (it's a static library)

**For macOS Target (ItoriMac)**:
1. Select `ItoriMac` target → **General** tab
2. Scroll to **Frameworks, Libraries, and Embedded Content**
3. Click **"+"** → Add `ItoriShared`
4. Set to **"Do Not Embed"**

### Step 6: Configure Build Settings

**For Both Targets**:
1. Select target → **Build Settings**
2. Search for "Swift Language Version"
3. Set to **Swift 5** or later
4. Search for "Minimum Deployments"
   - iOS: **17.0** (or your minimum)
   - macOS: **14.0** (or your minimum)

---

## Part 3: Swift Package Structure

### Package.swift

```swift
// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "ItoriShared",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "ItoriShared",
            targets: ["ItoriShared"]
        )
    ],
    dependencies: [
        // Add any cross-platform dependencies here
        // Example: .package(url: "https://github.com/...", from: "1.0.0")
    ],
    targets: [
        .target(
            name: "ItoriShared",
            dependencies: [],
            path: "Sources/ItoriShared"
        ),
        .testTarget(
            name: "ItoriSharedTests",
            dependencies: ["ItoriShared"],
            path: "Tests/ItoriSharedTests"
        )
    ]
)
```

---

## Part 4: Shared Code Examples

### ItoriShared/Sources/ItoriShared/Models/Course.swift

```swift
import Foundation

/// Cross-platform Course model
/// Platform-specific extensions (colors, etc.) live in each target
public struct Course: Identifiable, Codable, Hashable, Sendable {
    public let id: UUID
    public var title: String
    public var code: String
    public var semesterId: UUID
    public var credits: Double
    public var syllabus: String?
    public var professorName: String?
    public var location: String?
    
    // Color stored as hex string (platform-agnostic)
    public var colorHex: String
    
    public init(
        id: UUID = UUID(),
        title: String,
        code: String,
        semesterId: UUID,
        credits: Double = 3.0,
        colorHex: String = "#007AFF",
        syllabus: String? = nil,
        professorName: String? = nil,
        location: String? = nil
    ) {
        self.id = id
        self.title = title
        self.code = code
        self.semesterId = semesterId
        self.credits = credits
        self.colorHex = colorHex
        self.syllabus = syllabus
        self.professorName = professorName
        self.location = location
    }
}
```

### ItoriShared/Sources/ItoriShared/Models/Assignment.swift

```swift
import Foundation

public enum AssignmentUrgency: String, Codable, Hashable, Sendable, CaseIterable {
    case low, medium, high, critical
    
    public var label: String {
        switch self {
        case .low: return "Low"
        case .medium: return "Medium"
        case .high: return "High"
        case .critical: return "Critical"
        }
    }
    
    // NO Color here - that's platform-specific
    // See Color+iOS.swift and Color+macOS.swift for platform extensions
}

public struct Assignment: Identifiable, Codable, Hashable, Sendable {
    public let id: UUID
    public var courseId: UUID?
    public var title: String
    public var dueDate: Date
    public var estimatedMinutes: Int
    public var urgency: AssignmentUrgency
    public var isCompleted: Bool
    public var notes: String?
    
    public init(
        id: UUID = UUID(),
        courseId: UUID? = nil,
        title: String,
        dueDate: Date,
        estimatedMinutes: Int = 60,
        urgency: AssignmentUrgency = .medium,
        isCompleted: Bool = false,
        notes: String? = nil
    ) {
        self.id = id
        self.courseId = courseId
        self.title = title
        self.dueDate = dueDate
        self.estimatedMinutes = estimatedMinutes
        self.urgency = urgency
        self.isCompleted = isCompleted
        self.notes = notes
    }
}
```

### ItoriShared/Sources/ItoriShared/Services/Protocols/PersistenceService.swift

```swift
import Foundation

/// Protocol for persistence operations (platform-agnostic)
public protocol PersistenceService: Actor {
    func saveCourse(_ course: Course) async throws
    func fetchCourses() async throws -> [Course]
    func deleteCourse(_ id: UUID) async throws
    
    func saveAssignment(_ assignment: Assignment) async throws
    func fetchAssignments() async throws -> [Assignment]
    func deleteAssignment(_ id: UUID) async throws
    
    func saveSchedule(_ schedule: Schedule) async throws
    func fetchSchedules() async throws -> [Schedule]
}
```

### ItoriShared/Sources/ItoriShared/Services/AssignmentPlanEngine.swift

```swift
import Foundation

/// Cross-platform assignment planning engine
public struct AssignmentPlanEngine: Sendable {
    
    public init() {}
    
    /// Generate a study plan for an assignment
    public func generatePlan(
        for assignment: Assignment,
        startDate: Date,
        endDate: Date,
        dailyHoursAvailable: Double
    ) -> [PlanStep] {
        let totalMinutes = assignment.estimatedMinutes
        let daysAvailable = Calendar.current.dateComponents([.day], from: startDate, to: endDate).day ?? 1
        let minutesPerDay = Double(totalMinutes) / Double(max(1, daysAvailable))
        
        var steps: [PlanStep] = []
        var currentDate = startDate
        
        while currentDate < endDate {
            let step = PlanStep(
                id: UUID(),
                assignmentId: assignment.id,
                date: currentDate,
                expectedMinutes: Int(minutesPerDay),
                isCompleted: false
            )
            steps.append(step)
            
            guard let nextDate = Calendar.current.date(byAdding: .day, value: 1, to: currentDate) else {
                break
            }
            currentDate = nextDate
        }
        
        return steps
    }
}

public struct PlanStep: Identifiable, Codable, Hashable, Sendable {
    public let id: UUID
    public var assignmentId: UUID
    public var date: Date
    public var expectedMinutes: Int
    public var isCompleted: Bool
    
    public init(
        id: UUID = UUID(),
        assignmentId: UUID,
        date: Date,
        expectedMinutes: Int,
        isCompleted: Bool = false
    ) {
        self.id = id
        self.assignmentId = assignmentId
        self.date = date
        self.expectedMinutes = expectedMinutes
        self.isCompleted = isCompleted
    }
}
```

### ItoriShared/Sources/ItoriShared/DesignTokens/Spacing.swift

```swift
import Foundation

/// Platform-neutral spacing tokens (8pt grid)
public struct Spacing {
    public static let xxsmall: CGFloat = 2
    public static let xsmall: CGFloat = 4
    public static let small: CGFloat = 8
    public static let medium: CGFloat = 16
    public static let large: CGFloat = 24
    public static let xlarge: CGFloat = 32
    public static let xxlarge: CGFloat = 48
    
    private init() {}
}

public struct BorderRadius {
    public static let small: CGFloat = 8
    public static let medium: CGFloat = 12
    public static let large: CGFloat = 16
    public static let xlarge: CGFloat = 24
    
    private init() {}
}
```

### ItoriShared/Sources/ItoriShared/Utilities/DateHelpers.swift

```swift
import Foundation

public extension Date {
    /// Check if date is today
    var isToday: Bool {
        Calendar.current.isDateInToday(self)
    }
    
    /// Check if date is in the past
    var isPast: Bool {
        self < Date()
    }
    
    /// Get start of day
    var startOfDay: Date {
        Calendar.current.startOfDay(for: self)
    }
    
    /// Get end of day
    var endOfDay: Date {
        Calendar.current.date(bySettingHour: 23, minute: 59, second: 59, of: self) ?? self
    }
    
    /// Days until this date
    func daysUntil(from: Date = Date()) -> Int {
        Calendar.current.dateComponents([.day], from: from.startOfDay, to: self.startOfDay).day ?? 0
    }
}
```

---

## Part 5: Platform-Specific Extensions

### ItoriApp/PlatformExtensions/Color+iOS.swift

```swift
import SwiftUI
import ItoriShared

#if os(iOS)
extension AssignmentUrgency {
    /// iOS-specific color for urgency
    public var color: Color {
        switch self {
        case .low: return .gray
        case .medium: return .blue
        case .high: return .orange
        case .critical: return .red
        }
    }
}

extension Course {
    /// Convert hex string to iOS Color
    public var color: Color {
        Color(hex: colorHex) ?? .blue
    }
}

extension Color {
    init?(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            return nil
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
#endif
```

### ItoriMac/PlatformExtensions/Color+macOS.swift

```swift
import SwiftUI
import ItoriShared

#if os(macOS)
extension AssignmentUrgency {
    /// macOS-specific color for urgency
    public var color: Color {
        switch self {
        case .low: return .gray
        case .medium: return .blue
        case .high: return .orange
        case .critical: return .red
        }
    }
}

extension Course {
    /// Convert hex string to macOS Color
    public var color: Color {
        Color(hex: colorHex) ?? .blue
    }
}

extension Color {
    init?(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            return nil
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
#endif
```

---

## Part 6: Dependency Injection Pattern

### ItoriShared/Sources/ItoriShared/DependencyInjection/AppContainer.swift

```swift
import Foundation

/// Shared dependency container (platform-agnostic)
@MainActor
public final class AppContainer: ObservableObject {
    
    // MARK: - Services
    
    public let persistenceService: any PersistenceService
    public let planEngine: AssignmentPlanEngine
    
    // MARK: - Stores (Observable State)
    
    @Published public private(set) var courses: [Course] = []
    @Published public private(set) var assignments: [Assignment] = []
    
    // MARK: - Initialization
    
    public init(persistenceService: any PersistenceService) {
        self.persistenceService = persistenceService
        self.planEngine = AssignmentPlanEngine()
    }
    
    // MARK: - Data Operations
    
    public func loadData() async {
        do {
            courses = try await persistenceService.fetchCourses()
            assignments = try await persistenceService.fetchAssignments()
        } catch {
            print("Failed to load data: \(error)")
        }
    }
    
    public func addCourse(_ course: Course) async {
        do {
            try await persistenceService.saveCourse(course)
            courses.append(course)
        } catch {
            print("Failed to save course: \(error)")
        }
    }
    
    public func addAssignment(_ assignment: Assignment) async {
        do {
            try await persistenceService.saveAssignment(assignment)
            assignments.append(assignment)
        } catch {
            print("Failed to save assignment: \(error)")
        }
    }
}
```

### ItoriApp/DependencyInjection/AppDependencies.swift (iOS)

```swift
import SwiftUI
import ItoriShared

#if os(iOS)
/// iOS-specific dependency setup
@MainActor
final class AppDependencies {
    
    static let shared = AppDependencies()
    
    let container: AppContainer
    
    private init() {
        // Create platform-specific persistence service
        let persistence = IOSPersistenceService()
        
        // Initialize shared container
        self.container = AppContainer(persistenceService: persistence)
    }
}

/// iOS-specific persistence implementation
actor IOSPersistenceService: PersistenceService {
    
    // Implement using CoreData, SwiftData, or other iOS storage
    
    func saveCourse(_ course: Course) async throws {
        // iOS-specific CoreData save
    }
    
    func fetchCourses() async throws -> [Course] {
        // iOS-specific CoreData fetch
        return []
    }
    
    func deleteCourse(_ id: UUID) async throws {
        // iOS-specific CoreData delete
    }
    
    func saveAssignment(_ assignment: Assignment) async throws {
        // iOS-specific save
    }
    
    func fetchAssignments() async throws -> [Assignment] {
        // iOS-specific fetch
        return []
    }
    
    func deleteAssignment(_ id: UUID) async throws {
        // iOS-specific delete
    }
    
    func saveSchedule(_ schedule: Schedule) async throws {
        // iOS-specific save
    }
    
    func fetchSchedules() async throws -> [Schedule] {
        // iOS-specific fetch
        return []
    }
}

// Placeholder Schedule type
public struct Schedule: Identifiable, Codable, Hashable, Sendable {
    public let id: UUID
}
#endif
```

### ItoriMac/DependencyInjection/AppDependencies.swift (macOS)

```swift
import SwiftUI
import ItoriShared

#if os(macOS)
/// macOS-specific dependency setup
@MainActor
final class AppDependencies {
    
    static let shared = AppDependencies()
    
    let container: AppContainer
    
    private init() {
        // Create platform-specific persistence service
        let persistence = MacPersistenceService()
        
        // Initialize shared container
        self.container = AppContainer(persistenceService: persistence)
    }
}

/// macOS-specific persistence implementation
actor MacPersistenceService: PersistenceService {
    
    // Implement using CoreData, SwiftData, or other macOS storage
    
    func saveCourse(_ course: Course) async throws {
        // macOS-specific CoreData save
    }
    
    func fetchCourses() async throws -> [Course] {
        // macOS-specific CoreData fetch
        return []
    }
    
    func deleteCourse(_ id: UUID) async throws {
        // macOS-specific CoreData delete
    }
    
    func saveAssignment(_ assignment: Assignment) async throws {
        // macOS-specific save
    }
    
    func fetchAssignments() async throws -> [Assignment] {
        // macOS-specific fetch
        return []
    }
    
    func deleteAssignment(_ id: UUID) async throws {
        // macOS-specific delete
    }
    
    func saveSchedule(_ schedule: Schedule) async throws {
        // macOS-specific save
    }
    
    func fetchSchedules() async throws -> [Schedule] {
        // macOS-specific fetch
        return []
    }
}

// Placeholder Schedule type
public struct Schedule: Identifiable, Codable, Hashable, Sendable {
    public let id: UUID
}
#endif
```

### ItoriApp/ItoriApp.swift (iOS Entry Point)

```swift
import SwiftUI
import ItoriShared

#if os(iOS)
@main
struct ItoriApp: App {
    
    @StateObject private var container = AppDependencies.shared.container
    
    var body: some Scene {
        WindowGroup {
            IOSRootView()
                .environmentObject(container)
                .task {
                    await container.loadData()
                }
        }
    }
}
#endif
```

### ItoriMac/ItoriMacApp.swift (macOS Entry Point)

```swift
import SwiftUI
import ItoriShared

#if os(macOS)
@main
struct ItoriMacApp: App {
    
    @StateObject private var container = AppDependencies.shared.container
    
    var body: some Scene {
        WindowGroup {
            MacRootView()
                .environmentObject(container)
                .task {
                    await container.loadData()
                }
        }
        
        Settings {
            MacSettingsView()
                .environmentObject(container)
        }
    }
}
#endif
```

---

## Part 7: Entitlements & Capabilities

### Entitlements Location

**iOS**: `ItoriApp/Itori.entitlements`  
**macOS**: `ItoriMac/ItoriMac.entitlements`

### Adding Capabilities (Future)

**For iCloud/CloudKit**:
1. Select target → **Signing & Capabilities**
2. Click **"+ Capability"**
3. Add **"iCloud"**
4. Enable **"CloudKit"**
5. Configure container identifier

**For StoreKit**:
1. Select target → **Signing & Capabilities**
2. Click **"+ Capability"**
3. Add **"In-App Purchase"**

### iOS Entitlements Template

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.security.application-groups</key>
    <array>
        <string>group.com.yourcompany.roots</string>
    </array>
    <!-- Add iCloud/CloudKit here when ready -->
    <!-- <key>com.apple.developer.icloud-container-identifiers</key> -->
    <!-- <array>
        <string>iCloud.com.yourcompany.roots</string>
    </array> -->
</dict>
</plist>
```

### macOS Entitlements Template

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.security.app-sandbox</key>
    <true/>
    <key>com.apple.security.files.user-selected.read-write</key>
    <true/>
    <key>com.apple.security.application-groups</key>
    <array>
        <string>group.com.yourcompany.roots</string>
    </array>
    <!-- Add iCloud/CloudKit here when ready -->
</dict>
</plist>
```

---

## Part 8: Implementation Checklist

### Phase 1: Setup Package Structure
- [ ] Create `ItoriShared` folder
- [ ] Run `swift package init` in folder
- [ ] Edit `Package.swift` with correct structure
- [ ] Add package to Xcode project
- [ ] Verify package builds in both targets

### Phase 2: Add macOS Target
- [ ] Create new macOS target in Xcode
- [ ] Rename iOS target to `ItoriApp`
- [ ] Configure build settings for both targets
- [ ] Add `ItoriShared` dependency to both targets

### Phase 3: Move Shared Code
- [ ] Move domain models to `ItoriShared/Models/`
- [ ] Move services to `ItoriShared/Services/`
- [ ] Move persistence protocols to `ItoriShared/Persistence/`
- [ ] Move utilities to `ItoriShared/Utilities/`
- [ ] Move design tokens to `ItoriShared/DesignTokens/`
- [ ] Verify all imports use `import ItoriShared`

### Phase 4: Create Platform Extensions
- [ ] Create `Color+iOS.swift` in iOS target
- [ ] Create `Color+macOS.swift` in macOS target
- [ ] Create platform-specific extensions for models
- [ ] Verify colors compile on both platforms

### Phase 5: Setup Dependency Injection
- [ ] Create `AppContainer` in `ItoriShared`
- [ ] Create `AppDependencies.swift` in iOS target
- [ ] Create `AppDependencies.swift` in macOS target
- [ ] Wire up container in both app entry points
- [ ] Test data flow works

### Phase 6: Build & Test
- [ ] Build iOS target → should succeed
- [ ] Build macOS target → should succeed
- [ ] Run iOS app → verify UI works
- [ ] Run macOS app → verify UI works
- [ ] Verify shared code changes affect both targets

### Phase 7: Configure Capabilities (Future)
- [ ] Add entitlements files
- [ ] Configure iCloud/CloudKit when needed
- [ ] Configure StoreKit when needed
- [ ] Test sync across devices

---

## Part 9: Key Principles

### ✅ DO:
- Put business logic in `ItoriShared`
- Put UI code in platform targets
- Use protocols for platform-specific implementations
- Store colors as hex strings in models
- Use platform extensions for `Color` conversions
- Keep entitlements in target folders

### ❌ DON'T:
- Import `SwiftUI` in shared models (unless necessary)
- Use `UIColor` or `NSColor` in `ItoriShared`
- Duplicate business logic across targets
- Put platform-specific APIs in shared package
- Mix persistence implementation with interfaces

---

## Part 10: Build & Run Verification

### iOS Build Command
```bash
xcodebuild -project Itori.xcodeproj -scheme ItoriApp -sdk iphonesimulator build
```

### macOS Build Command
```bash
xcodebuild -project Itori.xcodeproj -scheme ItoriMac -sdk macosx build
```

### Expected Result
Both commands should complete with **BUILD SUCCEEDED**.

---

## Conclusion

This architecture provides:
✅ Maximum code sharing (models, services, utilities)  
✅ Platform-native UIs (SwiftUI for each platform)  
✅ Clean separation of concerns  
✅ Easy testing (shared package is testable)  
✅ Future-proof (add watchOS, tvOS later)  
✅ Apple-native (no hacks or workarounds)  

The key is to keep the shared package **platform-agnostic** and use **platform extensions** for anything that differs between iOS and macOS.
