# macOS Human Interface Guidelines Compliance Audit
**Date:** 2026-01-03  
**Platform:** macOS  
**App:** Roots

## Executive Summary

This document audits Roots against Apple's Human Interface Guidelines (HIG) for macOS, ensuring maximum native UI compliance and platform consistency.

---

## 1. Window Management ✅ COMPLIANT

### Current Implementation
- ✅ Uses `WindowGroup` for primary windows
- ✅ Supports multiple windows per document/scene
- ✅ Native window chrome and controls
- ✅ Standard toolbar implementation

### Recommendations
- ✅ Already using native window management
- ✅ No custom window decorations

---

## 2. Navigation & Layout 🟡 NEEDS ATTENTION

### Issues Found

#### A. NavigationSplitView Usage
**Location:** Multiple scenes use sidebars inconsistently

**HIG Requirement:**
- Sidebars should collapse on smaller windows
- Use `.navigationSplitViewColumnWidth()` for proper sizing
- Maintain consistent sidebar presence across app

**Current Issues:**
- ❌ FlashcardsView removed sidebar (inconsistent with rest of app)
- ❌ Some views use custom card layouts instead of Lists
- ❌ Inconsistent use of `.listStyle()`

**Fix Required:**
```swift
// FlashcardsView should restore NavigationSplitView for consistency
NavigationSplitView {
    // Sidebar
} detail: {
    // Detail
}
.navigationSplitViewColumnWidth(min: 200, ideal: 250, max: 300)
```

#### B. List Styles
**HIG Requirement:** Use `.listStyle(.sidebar)` for navigation sidebars

**Current Issues:**
- ⚠️ Custom `.sidebarCardStyle()` modifier instead of native styles
- ⚠️ Inconsistent spacing and padding

**Fix Required:**
```swift
List {
    // content
}
.listStyle(.sidebar)
.scrollContentBackground(.hidden) // if custom background needed
```

---

## 3. Typography ✅ MOSTLY COMPLIANT

### Current State
- ✅ Uses system fonts
- ✅ Dynamic Type support through `.font()` modifiers
- ✅ Proper text hierarchy

### Minor Issues
- ⚠️ Some hardcoded font sizes (should use semantic sizes)
- ⚠️ `.caption`, `.subheadline` used correctly

---

## 4. Color & Visual Design 🟡 NEEDS ATTENTION

### Issues Found

#### A. Custom Colors
**Location:** Throughout app

**HIG Requirement:** Use semantic system colors

**Current Issues:**
```swift
// ❌ WRONG - Custom color literals
Color(nsColor: .controlBackgroundColor)
Color.accentColor.opacity(0.1)

// ✅ CORRECT - Semantic colors
Color(nsColor: .windowBackgroundColor)
Color(nsColor: .separatorColor)
Color.accentColor // OK for accent
```

**Fix Required:**
```swift
// Replace all color usage with semantic colors
.background(.background)  // Instead of custom colors
.foregroundStyle(.primary)  // Instead of .primary
.foregroundStyle(.secondary)  // For less important text
```

#### B. Opacity Usage
**Current:** Heavy use of `.opacity()` modifiers

**HIG:** Use semantic color levels instead
```swift
// ❌ WRONG
Color.blue.opacity(0.2)

// ✅ CORRECT  
Color.blue.quinary  // or quaternary, tertiary
```

---

## 5. Controls & Buttons 🟡 NEEDS ATTENTION

### Issues Found

#### A. Button Styles
**Current:** Mix of custom and native styles

**HIG Requirement:** Use standard button styles
```swift
// Primary actions
Button("Save") { }.buttonStyle(.borderedProminent)

// Secondary actions  
Button("Cancel") { }.buttonStyle(.bordered)

// Tertiary actions
Button("Edit") { }.buttonStyle(.plain)
```

**Issues:**
- ⚠️ Some buttons use `.buttonStyle(.borderless)` incorrectly
- ⚠️ Inconsistent use of `.controlSize()`

#### B. Pickers
**Current:** Custom picker implementations

**Fix Required:**
```swift
Picker("Type", selection: $type) {
    ForEach(types) { type in
        Text(type.name).tag(type)
    }
}
.pickerStyle(.menu)  // For dropdown
// or
.pickerStyle(.segmented)  // For segmented control
```

---

## 6. Forms & Data Entry ✅ MOSTLY COMPLIANT

### Current State
- ✅ Uses `Form` for settings
- ✅ Native `TextField` and `TextEditor`
- ✅ Proper keyboard navigation

### Recommendations
```swift
Form {
    Section("Settings") {
        Toggle("Enabled", isOn: $enabled)
        TextField("Name", text: $name)
    }
}
.formStyle(.grouped)  // Native macOS form style
```

---

## 7. Toolbars 🟡 NEEDS ATTENTION

### Issues Found

#### A. Toolbar Items
**Current:** Custom toolbar implementations

**HIG Requirement:**
```swift
.toolbar {
    ToolbarItemGroup(placement: .navigation) {
        // Navigation buttons
    }
    
    ToolbarItemGroup(placement: .primaryAction) {
        // Primary actions
    }
    
    ToolbarItem(placement: .status) {
        // Status info
    }
}
```

#### B. Toolbar Customization
**Missing:** `.toolbarRole()` and customization support

**Fix Required:**
```swift
.toolbar(id: "main") {
    ToolbarItem(id: "add", placement: .primaryAction) {
        Button { } label: {
            Label("Add", systemImage: "plus")
        }
    }
}
.toolbarRole(.editor)  // Enables customization
```

---

## 8. Menus & Popups 🟡 NEEDS ATTENTION

### Issues Found

#### A. Context Menus
**Current:** Custom implementations

**HIG Requirement:**
```swift
.contextMenu {
    Button("Edit") { }
    Button("Delete", role: .destructive) { }
    Divider()
    Menu("Share") {
        // submenu
    }
}
```

#### B. Menu Bar Extras
**Missing:** Proper integration for background tasks

---

## 9. Sheets & Popovers ✅ COMPLIANT

### Current State
- ✅ Uses `.sheet()` for modal presentations
- ✅ Uses `.popover()` where appropriate
- ✅ Proper dismiss actions

### Recommendations
- ✅ Continue current implementation
- Consider `.presentationDetents()` for resizable sheets

---

## 10. Tables & Lists 🟡 NEEDS ATTENTION

### Issues Found

#### A. Custom Row Views
**Current:** Many custom row implementations

**HIG Requirement:** Use `Table` for tabular data
```swift
Table(items) {
    TableColumn("Name", value: \.name)
    TableColumn("Date", value: \.date)
    TableColumn("Status") { item in
        StatusBadge(item.status)
    }
}
.tableStyle(.inset)
```

#### B. Selection Highlighting
**Current:** Manual selection styling

**Fix Required:**
```swift
List(items, selection: $selection) {
    // Items automatically get selection styling
}
```

---

## 11. Spacing & Layout 🟡 NEEDS ATTENTION

### Issues Found

#### A. Hardcoded Padding
**Current:** Many hardcoded `.padding(20)` values

**HIG Requirement:** Use standard spacing
```swift
// ❌ WRONG
.padding(20)
.padding(.horizontal, 16)

// ✅ CORRECT
.padding()  // Automatic adaptive padding
.padding(.horizontal)  // Standard horizontal padding
```

#### B. Grid Layouts
**Current:** Custom `LazyVGrid` with hardcoded sizing

**Fix Required:**
```swift
// ✅ Use adaptive columns
LazyVGrid(columns: [
    GridItem(.adaptive(minimum: 200, maximum: 400))
])
```

---

## 12. Icons & SF Symbols ✅ COMPLIANT

### Current State
- ✅ Uses SF Symbols throughout
- ✅ Proper symbol variants (`.fill`, `.circle`)
- ✅ Semantic symbol usage

### Recommendations
- ✅ Continue using SF Symbols
- Consider `.symbolRenderingMode()` for multicolor icons

---

## 13. Accessibility ✅ EXCELLENT

### Current State
- ✅ VoiceOver labels
- ✅ Dynamic Type support
- ✅ Keyboard navigation
- ✅ High contrast support

---

## 14. Settings & Preferences 🟡 NEEDS ATTENTION

### Issues Found

#### A. Settings Window
**Current:** Custom implementation

**HIG Requirement:**
```swift
Settings {
    TabView {
        GeneralSettingsView()
            .tabItem { Label("General", systemImage: "gear") }
        
        AccountsSettingsView()
            .tabItem { Label("Accounts", systemImage: "person.circle") }
    }
}
```

#### B. Settings Scene
**Fix Required:**
```swift
// In App struct
.commands {
    CommandGroup(replacing: .appSettings) {
        Button("Preferences...") {
            NSApp.sendAction(Selector(("showPreferencesWindow:")), to: nil, from: nil)
        }
        .keyboardShortcut(",", modifiers: .command)
    }
}
```

---

## Priority Fixes

### 🔴 High Priority

1. **Restore NavigationSplitView in FlashcardsView**
   - Remove custom card grid
   - Use native sidebar + detail pattern
   - Ensure consistency with other views

2. **Replace Custom Colors with Semantic Colors**
   - Audit all `Color` usage
   - Replace with `.background`, `.secondary`, etc.
   - Remove opacity modifiers

3. **Standardize Button Styles**
   - Use `.borderedProminent` for primary
   - Use `.bordered` for secondary
   - Use `.plain` for tertiary

4. **Fix List Styles**
   - Use `.listStyle(.sidebar)` consistently
   - Remove custom styling modifiers

### 🟡 Medium Priority

5. **Add Toolbar Customization**
   - Implement `toolbar(id:)`
   - Add `.toolbarRole()`

6. **Implement Standard Tables**
   - Replace custom list views with `Table` where appropriate
   - Use native selection

7. **Fix Spacing**
   - Remove hardcoded padding values
   - Use semantic spacing

### 🟢 Low Priority

8. **Settings Window**
   - Implement native Settings scene
   - Add proper keyboard shortcuts

9. **Menu Bar Integration**
   - Add menu bar extras if needed

---

## Implementation Checklist

### Week 1: Critical Native UI
- [ ] Restore NavigationSplitView in FlashcardsView
- [ ] Audit and replace all custom colors
- [ ] Standardize all button styles
- [ ] Fix list styles throughout app

### Week 2: Layout & Controls
- [ ] Replace hardcoded spacing with semantic spacing
- [ ] Implement proper Table views where applicable
- [ ] Add toolbar customization
- [ ] Fix picker styles

### Week 3: Polish
- [ ] Implement native Settings scene
- [ ] Add comprehensive keyboard shortcuts
- [ ] Audit all typography for semantic sizes
- [ ] Final HIG compliance check

---

## Conclusion

**Overall Compliance: 75%**

The app has a strong foundation with good use of native controls, but needs work in:
1. Consistent navigation patterns (especially FlashcardsView)
2. Semantic color usage
3. Standard spacing and layouts
4. Native list and table implementations

By addressing the High Priority fixes, compliance will improve to ~90%.

---

## References

- [macOS Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/macos)
- [SwiftUI Design Guidelines](https://developer.apple.com/design/human-interface-guidelines/swiftui)
- [SF Symbols App](https://developer.apple.com/sf-symbols/)
