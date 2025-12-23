# iOS Native Menus - Quick Reference

## Native Menu Patterns

### 1. Basic Menu

```swift
Menu {
    Button("Action 1") { /* ... */ }
    Button("Action 2") { /* ... */ }
} label: {
    Text("Open Menu")
}
```

### 2. Menu with Icons (Recommended)

```swift
Menu {
    Button {
        // Action
    } label: {
        Label("Dashboard", systemImage: "rectangle.grid.2x2")
    }
    
    Button {
        // Action
    } label: {
        Label("Settings", systemImage: "gearshape")
    }
} label: {
    Image(systemName: "ellipsis.circle")
}
```

**Note:** Icons appear on leading edge (iOS standard)

### 3. Menu with Sections (Using Divider)

```swift
Menu {
    // Section 1
    Button { /* ... */ } label: { Label("Item 1", systemImage: "1.circle") }
    Button { /* ... */ } label: { Label("Item 2", systemImage: "2.circle") }
    
    Divider()
    
    // Section 2
    Button { /* ... */ } label: { Label("Settings", systemImage: "gearshape") }
} label: {
    Image(systemName: "line.3.horizontal")
}
```

### 4. Menu with Disabled Items

```swift
Menu {
    Button { /* ... */ } label: { Label("Available", systemImage: "checkmark") }
    
    Button { /* ... */ } label: { Label("Unavailable", systemImage: "xmark") }
        .disabled(true)
} label: {
    Text("Options")
}
```

### 5. Menu with Destructive Action

```swift
Menu {
    Button { /* ... */ } label: { Label("Edit", systemImage: "pencil") }
    Button { /* ... */ } label: { Label("Duplicate", systemImage: "doc.on.doc") }
    
    Divider()
    
    Button(role: .destructive) {
        // Delete action
    } label: {
        Label("Delete", systemImage: "trash")
    }
} label: {
    Image(systemName: "ellipsis.circle")
}
```

**Note:** Destructive actions appear in red

### 6. Submenu (Nested Menu)

```swift
Menu {
    Button { /* ... */ } label: { Label("Quick Action", systemImage: "bolt") }
    
    Menu("More Options") {
        Button { /* ... */ } label: { Label("Option A", systemImage: "a.circle") }
        Button { /* ... */ } label: { Label("Option B", systemImage: "b.circle") }
    }
} label: {
    Image(systemName: "ellipsis.circle")
}
```

### 7. Context Menu (Long Press)

```swift
Text("Long press me")
    .contextMenu {
        Button { /* ... */ } label: { Label("Copy", systemImage: "doc.on.doc") }
        Button { /* ... */ } label: { Label("Share", systemImage: "square.and.arrow.up") }
        
        Divider()
        
        Button(role: .destructive) { /* ... */ } label: { Label("Delete", systemImage: "trash") }
    }
```

### 8. Picker as Menu

```swift
Picker("Sort By", selection: $sortOption) {
    Text("Name").tag(SortOption.name)
    Text("Date").tag(SortOption.date)
    Text("Priority").tag(SortOption.priority)
}
.pickerStyle(.menu)
```

**Note:** Use only for single-selection lists

## Current App Implementation

### Hamburger Menu (Navigation)
**Location:** `iOS/Root/IOSAppShell.swift`

```swift
Menu {
    // Navigation pages
    ForEach(allMenuPages, id: \.self) { page in
        Button {
            navigation.open(page: page, starredTabs: starred)
        } label: {
            Label(menuTitle(for: page), systemImage: page.systemImage)
        }
    }
    
    Divider()
    
    // Settings
    Button {
        navigation.openSettings()
    } label: {
        Label("Settings", systemImage: "gearshape")
    }
} label: {
    Image(systemName: "line.3.horizontal")
        .font(.system(size: 20, weight: .medium))
        .foregroundColor(.primary)
        .frame(width: 44, height: 44)
}
```

### Quick Add Menu (+)
**Location:** `iOS/Root/IOSAppShell.swift`

```swift
Menu {
    Button {
        handleQuickAction(.add_assignment)
    } label: {
        Label("Add Assignment", systemImage: "plus.square.on.square")
    }
    
    Button {
        handleQuickAction(.add_grade)
    } label: {
        Label("Add Grade", systemImage: "number.circle")
    }
    
    Button {
        handleQuickAction(.auto_schedule)
    } label: {
        Label("Auto Schedule", systemImage: "calendar.badge.clock")
    }
} label: {
    Image(systemName: "plus")
        .font(.system(size: 20, weight: .semibold))
        .foregroundColor(.primary)
        .frame(width: 44, height: 44)
}
```

### Filter Menus
**Location:** `iOS/Scenes/IOSCorePages.swift` - `IOSFilterHeaderView`

```swift
// Semester filter
Menu {
    Button("All Semesters") {
        filterState.setSemester(nil, availableCourseIds: availableCourseIds(for: nil))
    }
    ForEach(coursesStore.activeSemesters) { semester in
        Button(semester.name) {
            filterState.setSemester(semester.id, availableCourseIds: availableCourseIds(for: semester.id))
        }
    }
} label: {
    filterChip(label: semesterLabel, systemImage: "calendar")
}

// Course filter
Menu {
    Button("All Courses") {
        filterState.selectedCourseId = nil
    }
    ForEach(availableCourses) { course in
        Button(course.code.isEmpty ? course.title : course.code) {
            filterState.selectedCourseId = course.id
        }
    }
} label: {
    filterChip(label: courseLabel, systemImage: "book.closed")
}
```

## Common SF Symbols for Menus

### Navigation
- Dashboard: `rectangle.grid.2x2`
- Calendar: `calendar`
- List: `list.bullet`
- Settings: `gearshape`
- Profile: `person.circle`

### Actions
- Add: `plus`, `plus.circle`
- Edit: `pencil`, `pencil.circle`
- Delete: `trash`, `trash.circle`
- Share: `square.and.arrow.up`
- Copy: `doc.on.doc`
- Duplicate: `doc.on.doc.fill`

### States
- Checkmark: `checkmark`, `checkmark.circle`
- Star: `star`, `star.fill`
- Bookmark: `bookmark`, `bookmark.fill`
- Pin: `pin`, `pin.fill`

### More Actions
- More: `ellipsis`, `ellipsis.circle`
- Menu: `line.3.horizontal`, `line.3.horizontal.circle`
- Sort: `arrow.up.arrow.down`, `arrow.up.arrow.down.circle`
- Filter: `line.3.horizontal.decrease.circle`

## Design Guidelines

### Icon Placement
✅ **DO:** Use icons on leading edge (default)
```swift
Label("Settings", systemImage: "gearshape")
```

❌ **DON'T:** Put icons on trailing edge (non-standard)

### Menu Width
- System handles width automatically
- No need to specify width
- Adjusts to content

### Menu Height
- System handles scrolling automatically
- No need to specify max height
- Long menus scroll natively

### Button Labels
✅ **DO:** Use clear, concise text
```swift
Button { } label: { Label("Add Assignment", systemImage: "plus") }
```

❌ **DON'T:** Use overly long text
```swift
Button { } label: { Label("Add a new assignment to your list", systemImage: "plus") }
```

### Destructive Actions
✅ **DO:** Use `.role(.destructive)` and put at bottom
```swift
Divider()
Button(role: .destructive) { } label: { Label("Delete", systemImage: "trash") }
```

❌ **DON'T:** Put destructive actions first

### Sections
✅ **DO:** Use `Divider()` to separate logical groups
```swift
Button { } label: { Label("Action 1", systemImage: "1") }
Divider()
Button { } label: { Label("Settings", systemImage: "gear") }
```

❌ **DON'T:** Overuse dividers (too many sections)

## Migration Checklist

When replacing custom menus:

- [ ] Replace custom overlay with `Menu { }`
- [ ] Remove @State variables for menu visibility
- [ ] Use `Label` for items with icons
- [ ] Add `Divider()` for section separation
- [ ] Use `role: .destructive` for delete actions
- [ ] Remove custom positioning logic
- [ ] Remove custom animation code
- [ ] Remove custom styling code
- [ ] Test anchoring behavior
- [ ] Test accessibility with VoiceOver
- [ ] Test on iPad with keyboard/pointer

## When NOT to Use Menu

### Use `.sheet` Instead
For complex forms or multi-step processes:
```swift
.sheet(isPresented: $showingEditor) {
    TaskEditorView(task: task)
}
```

### Use `.confirmationDialog` Instead
For action sheets (bottom-up on iPhone):
```swift
.confirmationDialog("Delete Item?", isPresented: $showingConfirmation) {
    Button("Delete", role: .destructive) { /* ... */ }
    Button("Cancel", role: .cancel) { }
}
```

### Use `Picker` Instead
For single selection from a list (when showing current value):
```swift
Picker("Theme", selection: $theme) {
    Text("Light").tag(Theme.light)
    Text("Dark").tag(Theme.dark)
    Text("Auto").tag(Theme.auto)
}
.pickerStyle(.menu)
```

## Accessibility

### VoiceOver
- Menu buttons announce as "button, menu"
- Menu items read with icon descriptions
- Dividers provide pauses
- Destructive items announced with warning

### Dynamic Type
- Text automatically scales
- Icons maintain proportions
- Menu remains usable at all sizes

### Keyboard (iPad)
- Tab to menu button
- Space/Return opens menu
- Arrow keys navigate items
- Return selects item
- Escape closes menu

### Pointer (iPad)
- Hover highlights buttons
- Hover highlights menu items
- Click opens menus
- Click selects items

## Performance Tips

1. **ForEach Efficiency**
   - Use stable identifiers: `ForEach(items, id: \.id)`
   - Avoid inline closures in ForEach when possible

2. **Avoid Nested State**
   - Let Menu handle its own state
   - Don't wrap in custom state management

3. **Icon Loading**
   - SF Symbols are efficient
   - Use system symbols when possible
   - Avoid custom images in menus

## Troubleshooting

### Menu Not Appearing
- Check label is visible and tappable
- Ensure menu content isn't empty
- Verify no view modifiers blocking interaction

### Icons Not Showing
- Use `Label` not just `Text`
- Verify SF Symbol name is correct
- Check systemImage parameter syntax

### Menu Positioning Wrong
- Native Menu handles automatically
- Don't try to force position
- Use native anchoring

### Actions Not Working
- Ensure Button action closure is called
- Check for @State updates if needed
- Verify navigation/sheet presentation

## Code Snippets

### Converting from Custom to Native

**Before:**
```swift
@State private var showingMenu = false

Button {
    showingMenu.toggle()
}

if showingMenu {
    CustomMenuPanel {
        CustomMenuRow("Item 1") { }
        CustomMenuRow("Item 2") { }
    }
}
```

**After:**
```swift
Menu {
    Button { } label: { Label("Item 1", systemImage: "1") }
    Button { } label: { Label("Item 2", systemImage: "2") }
} label: {
    Image(systemName: "ellipsis.circle")
}
```

### Adding Checkmark for Selection

```swift
Menu {
    ForEach(options) { option in
        Button {
            selectedOption = option
        } label: {
            if selectedOption == option {
                Label(option.name, systemImage: "checkmark")
            } else {
                Text(option.name)
            }
        }
    }
} label: {
    Text(selectedOption.name)
}
```

## Resources

- [Apple HIG: Menus](https://developer.apple.com/design/human-interface-guidelines/menus)
- [SwiftUI Menu](https://developer.apple.com/documentation/swiftui/menu)
- [SwiftUI Label](https://developer.apple.com/documentation/swiftui/label)
- [SF Symbols App](https://developer.apple.com/sf-symbols/)
