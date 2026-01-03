# macOS Keyboard Navigation Implementation Plan

## Overview
Comprehensive keyboard navigation and shortcuts for maximum macOS HIG compliance and power-user efficiency.

---

## 1. Standard macOS Keyboard Behaviors

### Focus Navigation (Built-in, verify working)
- **Tab** - Move focus forward
- **Shift+Tab** - Move focus backward
- **Arrow Keys** - Navigate within lists/grids
- **Space** - Activate focused button/toggle
- **Return** - Activate default action

### Text Navigation (Built-in)
- **⌘+A** - Select all
- **⌘+C** - Copy
- **⌘+V** - Paste
- **⌘+X** - Cut
- **⌘+Z** - Undo
- **⌘+Shift+Z** - Redo

---

## 2. App-Level Shortcuts (Implement)

### Window Management
```swift
- ⌘+N - New window
- ⌘+W - Close window
- ⌘+M - Minimize window
- ⌘+Shift+W - Close all windows
- ⌘+` - Cycle between windows
```

### Navigation Between Tabs
```swift
- ⌘+1 - Dashboard
- ⌘+2 - Calendar
- ⌘+3 - Planner
- ⌘+4 - Assignments
- ⌘+5 - Courses
- ⌘+6 - Grades
- ⌘+7 - Timer
- ⌘+8 - Flashcards
- ⌘+9 - Practice

Alternative:
- ⌃+Tab - Next tab
- ⌃+Shift+Tab - Previous tab
```

### Search & Filter
```swift
- ⌘+F - Focus search field
- ⌘+Option+F - Advanced filter
- Escape - Clear search / Dismiss
```

---

## 3. Context-Specific Shortcuts

### Assignment Actions
```swift
- ⌘+T - New task/assignment
- ⌘+E - Edit selected
- ⌘+Delete - Delete selected
- ⌘+D - Duplicate selected
- Space - Mark complete/incomplete
- ⌘+I - Show info/details
```

### Course Management
```swift
- ⌘+Shift+N - New course
- ⌘+Shift+M - New module
- ⌘+Shift+F - Add file
- Return - Open selected course
```

### Calendar Navigation
```swift
- ⌘+T - Go to today
- ⌘+Left - Previous period
- ⌘+Right - Next period
- ⌘+1 - Day view
- ⌘+2 - Week view
- ⌘+3 - Month view
- ⌘+4 - Year view
```

### Timer Controls
```swift
- ⌘+Return - Start/Stop timer
- ⌘+R - Reset timer
- ⌘+P - Pause/Resume
- ⌘+K - Select activity (Quick Open style)
```

### Flashcards
```swift
- Space - Flip card
- 1-4 - Rate difficulty (Again, Hard, Good, Easy)
- Right Arrow - Next card
- Left Arrow - Previous card
- ⌘+Shift+D - New deck
```

---

## 4. Menu Bar Integration

### File Menu
```swift
CommandGroup(replacing: .newItem) {
    Button("New Assignment...") { }
        .keyboardShortcut("t", modifiers: .command)
    Button("New Course...") { }
        .keyboardShortcut("n", modifiers: [.command, .shift])
}
```

### Edit Menu
```swift
CommandGroup(after: .pasteboard) {
    Divider()
    Button("Duplicate") { }
        .keyboardShortcut("d", modifiers: .command)
}
```

### View Menu
```swift
CommandMenu("View") {
    Button("Dashboard") { }
        .keyboardShortcut("1", modifiers: .command)
    // ... all tabs
    
    Divider()
    
    Button("Today") { }
        .keyboardShortcut("t", modifiers: .command)
    
    Button("Find...") { }
        .keyboardShortcut("f", modifiers: .command)
}
```

### Go Menu
```swift
CommandMenu("Go") {
    Button("Back") { }
        .keyboardShortcut("[", modifiers: .command)
    Button("Forward") { }
        .keyboardShortcut("]", modifiers: .command)
    
    Divider()
    
    Button("Previous Day") { }
        .keyboardShortcut(.leftArrow, modifiers: .command)
    Button("Next Day") { }
        .keyboardShortcut(.rightArrow, modifiers: .command)
}
```

---

## 5. Implementation Strategy

### Phase 1: Foundation (Today)
1. **Create KeyboardShortcutsManager**
   - Centralized shortcut registration
   - Conflict detection
   - User customization support

2. **Add CommandGroup Modifiers**
   - File menu
   - Edit menu
   - View menu
   - Go menu

3. **Focus Management**
   - Ensure proper tab order
   - Add `.focusable()` where needed
   - Handle focus restoration

### Phase 2: Context Actions (Tomorrow)
1. **Assignment Page**
   - New, Edit, Delete shortcuts
   - Quick actions menu

2. **Course Page**
   - Navigation shortcuts
   - Quick add shortcuts

3. **Calendar**
   - View switching
   - Date navigation

### Phase 3: Advanced Features (Day 3)
1. **Quick Open (⌘+K)**
   - Spotlight-style command palette
   - Search all entities
   - Execute actions

2. **Custom Shortcuts**
   - Settings pane for customization
   - Conflict resolution
   - Export/Import

---

## 6. Accessibility Considerations

### VoiceOver Support
- All shortcuts announced
- Full keyboard operation without mouse
- Proper focus indicators

### Visual Feedback
```swift
.keyboardShortcut("n", modifiers: .command)
.help("New Assignment (⌘N)") // Tooltip shows shortcut
```

### Focus Indicators
```swift
.focusable()
.focusedSceneValue(\.selectedItem, item)
```

---

## 7. Testing Checklist

- [ ] All shortcuts work in all contexts
- [ ] No shortcut conflicts
- [ ] Shortcuts appear in menus
- [ ] Tooltips show shortcuts
- [ ] VoiceOver announces shortcuts
- [ ] Focus visible at all times
- [ ] Tab order logical
- [ ] Can complete all tasks without mouse

---

## 8. Code Structure

### Create Files:
```
SharedCore/
  Keyboard/
    KeyboardShortcuts.swift         # Shortcut definitions
    KeyboardShortcutsManager.swift  # Registration & management
    CommandGroups+Roots.swift       # Menu bar commands
    FocusManagement.swift           # Focus helpers
```

### Usage Pattern:
```swift
// In view
.keyboardShortcut("t", modifiers: .command)
.registerShortcut(.newTask, action: createTask)

// In App
.commands {
    RootsCommands()
}
```

---

## 9. Implementation Code Templates

### Shortcut Enum
```swift
enum AppShortcut: String, CaseIterable {
    case newAssignment
    case editItem
    case deleteItem
    case search
    case toggleComplete
    
    var keyEquivalent: KeyEquivalent {
        switch self {
        case .newAssignment: return "t"
        case .editItem: return "e"
        case .deleteItem: return .delete
        case .search: return "f"
        case .toggleComplete: return " "
        }
    }
    
    var modifiers: EventModifiers {
        switch self {
        case .newAssignment: return .command
        case .editItem: return .command
        case .deleteItem: return .command
        case .search: return .command
        case .toggleComplete: return []
        }
    }
}
```

### Command Groups
```swift
struct RootsCommands: Commands {
    var body: some Commands {
        CommandGroup(replacing: .newItem) {
            Button("New Assignment") { }
                .keyboardShortcut("t", modifiers: .command)
        }
        
        CommandMenu("Go") {
            Button("Dashboard") { }
                .keyboardShortcut("1", modifiers: .command)
        }
    }
}
```

---

## Priority Implementation Order

### 🔴 Critical (Implement Now)
1. Tab navigation shortcuts (⌘+1-9)
2. New/Edit/Delete for assignments
3. Search focus (⌘+F)
4. Menu bar commands

### 🟡 Important (Day 2)
1. Calendar navigation
2. Timer controls
3. Quick actions
4. Context menus with shortcuts

### 🟢 Nice to Have (Day 3)
1. Command palette (⌘+K)
2. Custom shortcut settings
3. Shortcut cheat sheet view
4. Advanced power-user shortcuts

---

## Acceptance Criteria

✅ All standard macOS shortcuts work
✅ Can navigate entire app without mouse
✅ Shortcuts shown in menus and tooltips
✅ VoiceOver announces all shortcuts
✅ No shortcut conflicts
✅ Focus always visible
✅ Tab order logical
✅ Power users can work 2x faster

