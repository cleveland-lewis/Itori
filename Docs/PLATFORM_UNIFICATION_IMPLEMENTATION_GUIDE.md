# Platform Unification Implementation Guide

## How to Use the Framework

This guide shows practical examples of using the Platform Unification Framework in your code.

## Table of Contents

1. [Platform Detection](#platform-detection)
2. [Capability Checking](#capability-checking)
3. [Adaptive Components](#adaptive-components)
4. [Custom Platform-Aware Views](#custom-platform-aware-views)
5. [Layout Patterns](#layout-patterns)
6. [Common Scenarios](#common-scenarios)

---

## Platform Detection

### Basic Platform Check

```swift
import SharedCore

// Check specific platform
if Platform.isPhone {
    // iPhone-specific code
}

if Platform.isTablet {
    // iPad-specific code
}

if Platform.isDesktop {
    // macOS-specific code
}

// Check platform tier
switch Platform.current {
case .watchOS:
    print("Running on Apple Watch")
case .iOS:
    print("Running on iPhone")
case .iPadOS:
    print("Running on iPad")
case .macOS:
    print("Running on Mac")
}

// Compare platform tiers
if Platform.current >= .iPadOS {
    // Code for iPad and Mac
}
```

---

## Capability Checking

### Layout Capabilities

```swift
import SharedCore

// Check if multi-pane layouts are supported
if CapabilityDomain.Layout.supportsMultiPane {
    // Show split view on iPad/Mac
    NavigationSplitView {
        SidebarView()
    } detail: {
        DetailView()
    }
} else {
    // Show stack navigation on iPhone/Watch
    NavigationStack {
        ContentView()
    }
}

// Check navigation depth limit
let maxDepth = CapabilityDomain.Layout.maxNavigationDepth
if currentDepth > maxDepth {
    // Show warning or prevent deeper navigation
}
```

### Interaction Capabilities

```swift
// Add hover effects only on capable platforms
Button("Action") {
    performAction()
}
.platformHoverEffect()  // Automatically applied only where supported

// Add keyboard shortcut only on capable platforms
if CapabilityDomain.Interaction.supportsKeyboardShortcuts {
    Button("Save") {
        save()
    }
    .keyboardShortcut("s", modifiers: .command)
}

// Add context menu only on capable platforms
Text("Item")
    .platformContextMenu {
        Button("Edit") { edit() }
        Button("Delete") { delete() }
    }
```

### Density Capabilities

```swift
// Get appropriate padding
let padding = CapabilityDomain.Density.paddingScale * 16

// Get minimum tap target size
let minSize = CapabilityDomain.Density.minTapTargetSize

// Check UI density
switch CapabilityDomain.Density.uiDensity {
case .minimal:
    // Show 1-2 items (watchOS)
    showMinimalUI()
case .standard:
    // Show 3-5 items (iOS)
    showStandardUI()
case .comfortable:
    // Show 5-8 items (iPadOS)
    showComfortableUI()
case .dense:
    // Show 10+ items (macOS)
    showDenseUI()
}
```

---

## Adaptive Components

### AdaptiveCard

```swift
import SharedCore

AdaptiveCard {
    VStack {
        Text("Title")
            .font(.headline)
        Text("Content")
            .font(.body)
    }
}
// Automatically uses:
// - watchOS: 8pt corner radius, thick material
// - iOS: 12pt corner radius, regular material
// - iPadOS: 16pt corner radius, regular material
// - macOS: 12pt corner radius, thin material
```

### AdaptiveButton

```swift
AdaptiveButton(action: {
    performAction()
}) {
    Label("Action", systemImage: "star")
}
// Automatically ensures minimum tap target size per platform
// Adds hover effect on capable platforms
```

### AdaptiveGrid

```swift
AdaptiveGrid {
    ForEach(items) { item in
        ItemCard(item: item)
    }
}
// Automatically uses:
// - watchOS: 1 column
// - iOS: 2 columns
// - iPadOS: 3 columns
// - macOS: 4 columns
```

### AdaptiveVStack / AdaptiveHStack

```swift
AdaptiveVStack {
    Text("Item 1")
    Text("Item 2")
    Text("Item 3")
}
// Automatically uses platform-appropriate spacing
```

---

## Custom Platform-Aware Views

### Creating a Platform-Aware Navigation Container

```swift
import SharedCore

struct ContentNavigationView: View {
    var body: some View {
        if CapabilityDomain.Visual.prefersSidebar {
            // iPad/Mac: Sidebar navigation
            NavigationSplitView {
                List {
                    NavigationLink("Dashboard", destination: DashboardView())
                    NavigationLink("Calendar", destination: CalendarView())
                    NavigationLink("Courses", destination: CoursesView())
                }
            } detail: {
                Text("Select an item")
            }
        } else {
            // iPhone/Watch: Tab bar navigation
            TabView {
                DashboardView()
                    .tabItem {
                        Label("Dashboard", systemImage: "house")
                    }
                CalendarView()
                    .tabItem {
                        Label("Calendar", systemImage: "calendar")
                    }
                CoursesView()
                    .tabItem {
                        Label("Courses", systemImage: "book")
                    }
            }
        }
    }
}
```

### Creating a Platform-Aware Card

```swift
struct PlatformCard<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .platformPadding()
            .background {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(.regularMaterial)
            }
            .platformHoverEffect()
    }
    
    private var cornerRadius: CGFloat {
        switch Platform.current {
        case .watchOS: return 8
        case .iOS: return 12
        case .iPadOS: return 16
        case .macOS: return 12
        }
    }
}
```

### Creating Platform-Appropriate Modals

```swift
struct ContentView: View {
    @State private var showingDetail = false
    
    var body: some View {
        Button("Show Detail") {
            showingDetail = true
        }
        .adaptiveModal(isPresented: $showingDetail) {
            DetailView()
        }
        // Automatically shows:
        // - Full-screen sheet on iPhone/Watch
        // - Sized sheet on iPad/Mac
    }
}
```

---

## Layout Patterns

### Responsive Layout Based on Density

```swift
struct DashboardView: View {
    var body: some View {
        Group {
            switch CapabilityDomain.Density.uiDensity {
            case .minimal:
                // watchOS: Single key metric
                MinimalDashboard()
            case .standard:
                // iOS: 3-5 key metrics
                StandardDashboard()
            case .comfortable:
                // iPadOS: 5-8 metrics in grid
                ComfortableDashboard()
            case .dense:
                // macOS: 10+ metrics with details
                DenseDashboard()
            }
        }
    }
}
```

### Conditional Feature Rendering

```swift
struct FeatureView: View {
    var body: some View {
        VStack {
            // Always show
            BasicContent()
            
            // Show only on platforms with multi-pane support
            if PlatformFeature.isEnabled(.splitView) {
                SecondaryPane()
            }
            
            // Show only on platforms with keyboard support
            if PlatformFeature.isEnabled(.keyboardShortcuts) {
                KeyboardShortcutHints()
            }
            
            // Show only on macOS
            if PlatformFeature.isEnabled(.menuBar) {
                AdvancedControls()
            }
        }
    }
}
```

---

## Common Scenarios

### Scenario 1: Different Detail Level by Platform

```swift
struct CourseView: View {
    let course: Course
    
    var body: some View {
        AdaptiveVStack(alignment: .leading) {
            // Always show
            Text(course.name)
                .font(.headline)
            
            // Show on all except watchOS
            if Platform.current > .watchOS {
                Text(course.instructor)
                    .font(.subheadline)
            }
            
            // Show only on iPad and Mac
            if Platform.current >= .iPadOS {
                Text(course.description)
                    .font(.body)
                    .lineLimit(3)
            }
            
            // Show only on Mac
            if Platform.isDesktop {
                CourseStatistics(course: course)
            }
        }
        .platformPadding()
    }
}
```

### Scenario 2: Platform-Appropriate Navigation

```swift
struct NavigationExample: View {
    @State private var path: [String] = []
    
    var body: some View {
        Group {
            if CapabilityDomain.Navigation.navigationStyle == .stack {
                // iPhone/Watch: Stack navigation
                NavigationStack(path: $path) {
                    rootView
                }
            } else if CapabilityDomain.Navigation.navigationStyle == .splitView {
                // iPad: Split view
                NavigationSplitView {
                    sidebarView
                } detail: {
                    detailView
                }
            } else {
                // Mac: Sidebar with breadcrumbs
                NavigationSplitView {
                    sidebarView
                } content: {
                    contentView
                } detail: {
                    detailView
                }
            }
        }
    }
    
    // ... view definitions
}
```

### Scenario 3: Touch vs Pointer Interactions

```swift
struct InteractionExample: View {
    @State private var isHovered = false
    
    var body: some View {
        Button("Action") {
            performAction()
        }
        .frame(minWidth: CapabilityDomain.Density.minTapTargetSize,
               minHeight: CapabilityDomain.Density.minTapTargetSize)
        .platformConditional(CapabilityDomain.Interaction.supportsHover) { view in
            view.onHover { hovering in
                isHovered = hovering
            }
            .opacity(isHovered ? 0.7 : 1.0)
        }
        .platformConditional(CapabilityDomain.Interaction.isTouchFirst) { view in
            view.buttonStyle(.bordered)
        }
    }
}
```

### Scenario 4: Responsive Grid Layout

```swift
struct ResponsiveGridView: View {
    let items: [Item]
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: spacing) {
                ForEach(items) { item in
                    ItemCard(item: item)
                }
            }
            .platformPadding()
        }
    }
    
    private var columns: [GridItem] {
        let count: Int
        switch CapabilityDomain.Density.uiDensity {
        case .minimal:
            count = 1
        case .standard:
            count = 2
        case .comfortable:
            count = 3
        case .dense:
            count = 4
        }
        return Array(repeating: GridItem(.flexible()), count: count)
    }
    
    private var spacing: CGFloat {
        CapabilityDomain.Density.paddingScale * 12
    }
}
```

### Scenario 5: Platform-Specific Settings

```swift
struct SettingsView: View {
    var body: some View {
        Form {
            // Always show
            Section("General") {
                GeneralSettings()
            }
            
            // Show only on platforms with keyboard support
            if CapabilityDomain.Interaction.supportsKeyboardShortcuts {
                Section("Keyboard") {
                    KeyboardSettings()
                }
            }
            
            // Show only on macOS
            if Platform.isDesktop {
                Section("Advanced") {
                    AdvancedSettings()
                }
            }
        }
    }
}
```

---

## Testing Your Platform Code

### Debug View

```swift
#if DEBUG
import SharedCore

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            ContentView()
            Divider()
            PlatformDebugView()
        }
    }
}
#endif
```

### Validation

```swift
func application(_ application: UIApplication, didFinishLaunchingWithOptions...) -> Bool {
    #if DEBUG
    // Validate platform rules on startup
    let errors = PlatformValidation.validate()
    if !errors.isEmpty {
        print("⚠️ Platform validation errors:")
        errors.forEach { print($0) }
    }
    #endif
    
    return true
}
```

---

## Best Practices

1. **Always use capability checks, not platform checks**
   ```swift
   // ✅ Good
   if CapabilityDomain.Layout.supportsMultiPane { ... }
   
   // ❌ Avoid
   if Platform.isTablet { ... }
   ```

2. **Use adaptive components when possible**
   ```swift
   // ✅ Good
   AdaptiveCard { content }
   
   // ❌ Avoid
   if Platform.isPhone {
       iOSCard { content }
   } else if Platform.isTablet {
       iPadCard { content }
   } // ...
   ```

3. **Respect platform guidelines**
   ```swift
   // ✅ Good
   let depth = CapabilityDomain.Layout.maxNavigationDepth
   
   // ❌ Avoid
   let depth = 10 // Same for all platforms
   ```

4. **Test on all platforms**
   - Use Xcode previews for quick testing
   - Run unit tests on all platforms
   - Validate platform rules in CI/CD

---

## Resources

- [Platform Unification Framework Documentation](PLATFORM_UNIFICATION_FRAMEWORK.md)
- [Quick Reference](PLATFORM_UNIFICATION_QUICK_REFERENCE.md)
- [Apple HIG](https://developer.apple.com/design/human-interface-guidelines/)

---

**Last Updated**: January 3, 2026
