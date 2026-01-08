//
//  AppShortcuts.swift
//  Itori
//
//  Centralized keyboard shortcut definitions
//  Created: 2026-01-03
//

import SwiftUI

/// Application-wide keyboard shortcuts
enum AppShortcut: String, CaseIterable, Identifiable {
    var id: String { rawValue }
    
    // MARK: - Navigation
    case dashboard
    case calendar
    case planner
    case assignments
    case courses
    case grades
    
    // MARK: - Actions
    case newAssignment
    case newCourse
    case newModule
    case newDeck
    case editItem
    case deleteItem
    case duplicateItem
    case showInfo
    
    // MARK: - Search & Filter
    case focusSearch
    case clearSearch
    case advancedFilter
    
    // MARK: - Calendar
    case goToday
    case previousPeriod
    case nextPeriod
    case dayView
    case weekView
    case monthView
    case yearView
    
    // MARK: - Timer
    case startStopTimer
    case resetTimer
    case pauseTimer
    case selectActivity
    
    // MARK: - Flashcards
    case flipCard
    case nextCard
    case previousCard
    case rateAgain
    case rateHard
    case rateGood
    case rateEasy
    
    // MARK: - Common
    case toggleComplete
    case refresh
    case save
    case cancel
    
    var keyEquivalent: KeyEquivalent {
        switch self {
        // Navigation (⌘+number)
        case .dashboard: return "1"
        case .calendar: return "2"
        case .planner: return "3"
        case .assignments: return "4"
        case .courses: return "5"
        case .grades: return "6"
            
        // Actions
        case .newAssignment: return "t"
        case .newCourse: return "n"
        case .newModule: return "m"
        case .newDeck: return "d"
        case .editItem: return "e"
        case .deleteItem: return .delete
        case .duplicateItem: return "d"
        case .showInfo: return "i"
            
        // Search
        case .focusSearch: return "f"
        case .clearSearch: return .escape
        case .advancedFilter: return "f"
            
        // Calendar
        case .goToday: return "t"
        case .previousPeriod: return .leftArrow
        case .nextPeriod: return .rightArrow
        case .dayView: return "1"
        case .weekView: return "2"
        case .monthView: return "3"
        case .yearView: return "4"
            
        // Timer
        case .startStopTimer: return .return
        case .resetTimer: return "r"
        case .pauseTimer: return "p"
        case .selectActivity: return "k"
            
        // Flashcards
        case .flipCard: return " "
        case .nextCard: return .rightArrow
        case .previousCard: return .leftArrow
        case .rateAgain: return "1"
        case .rateHard: return "2"
        case .rateGood: return "3"
        case .rateEasy: return "4"
            
        // Common
        case .toggleComplete: return " "
        case .refresh: return "r"
        case .save: return "s"
        case .cancel: return .escape
        }
    }
    
    var modifiers: EventModifiers {
        switch self {
        // Tab navigation
        case .dashboard, .calendar, .planner, .assignments,
             .courses, .grades:
            return .command
            
        // New items with Shift
        case .newCourse, .newModule, .newDeck:
            return [.command, .shift]
            
        // Regular actions
        case .newAssignment, .editItem, .deleteItem, .showInfo,
             .focusSearch, .save:
            return .command
            
        // Duplicate (conflict resolution)
        case .duplicateItem:
            return .command
            
        // Advanced filter
        case .advancedFilter:
            return [.command, .option]
            
        // Calendar navigation with command
        case .goToday, .previousPeriod, .nextPeriod:
            return .command
            
        // Calendar views (in calendar context, no modifier needed)
        case .dayView, .weekView, .monthView, .yearView:
            return []
            
        // Timer shortcuts
        case .startStopTimer:
            return .command
        case .resetTimer, .pauseTimer:
            return .command
        case .selectActivity:
            return .command
            
        // Flashcards (no modifiers, space/arrows)
        case .flipCard, .nextCard, .previousCard,
             .rateAgain, .rateHard, .rateGood, .rateEasy:
            return []
            
        // Simple actions
        case .toggleComplete, .clearSearch, .cancel, .refresh:
            return []
        }
    }
    
    var title: String {
        switch self {
        case .dashboard: return "Dashboard"
        case .calendar: return "Calendar"
        case .planner: return "Planner"
        case .assignments: return "Assignments"
        case .courses: return "Courses"
        case .grades: return "Grades"
            
        case .newAssignment: return "New Assignment"
        case .newCourse: return "New Course"
        case .newModule: return "New Module"
        case .newDeck: return "New Deck"
        case .editItem: return "Edit"
        case .deleteItem: return "Delete"
        case .duplicateItem: return "Duplicate"
        case .showInfo: return "Show Info"
            
        case .focusSearch: return "Find"
        case .clearSearch: return "Clear Search"
        case .advancedFilter: return "Advanced Filter"
            
        case .goToday: return "Go to Today"
        case .previousPeriod: return "Previous"
        case .nextPeriod: return "Next"
        case .dayView: return "Day View"
        case .weekView: return "Week View"
        case .monthView: return "Month View"
        case .yearView: return "Year View"
            
        case .startStopTimer: return "Start/Stop Timer"
        case .resetTimer: return "Reset Timer"
        case .pauseTimer: return "Pause Timer"
        case .selectActivity: return "Select Activity"
            
        case .flipCard: return "Flip Card"
        case .nextCard: return "Next Card"
        case .previousCard: return "Previous Card"
        case .rateAgain: return "Rate: Again"
        case .rateHard: return "Rate: Hard"
        case .rateGood: return "Rate: Good"
        case .rateEasy: return "Rate: Easy"
            
        case .toggleComplete: return "Toggle Complete"
        case .refresh: return "Refresh"
        case .save: return "Save"
        case .cancel: return "Cancel"
        }
    }
    
    var helpText: String {
        let modStr = modifierString
        let key = keyString
        return modStr.isEmpty ? key : "\(modStr)\(key)"
    }
    
    private var modifierString: String {
        var parts: [String] = []
        if modifiers.contains(.command) { parts.append("⌘") }
        if modifiers.contains(.option) { parts.append("⌥") }
        if modifiers.contains(.control) { parts.append("⌃") }
        if modifiers.contains(.shift) { parts.append("⇧") }
        return parts.joined()
    }
    
    private var keyString: String {
        switch keyEquivalent {
        case .escape: return "⎋"
        case .delete: return "⌫"
        case .deleteForward: return "⌦"
        case .return: return "↩"
        case .space: return "Space"
        case .tab: return "⇥"
        case .upArrow: return "↑"
        case .downArrow: return "↓"
        case .leftArrow: return "←"
        case .rightArrow: return "→"
        default: return keyEquivalent.character.uppercased()
        }
    }
}

// MARK: - View Modifier

struct KeyboardShortcutModifier: ViewModifier {
    let shortcut: AppShortcut
    let action: () -> Void
    
    func body(content: Content) -> some View {
        content
            .keyboardShortcut(shortcut.keyEquivalent, modifiers: shortcut.modifiers)
            .help("\(shortcut.title) (\(shortcut.helpText))")
    }
}

extension View {
    func shortcut(_ shortcut: AppShortcut, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            self
        }
        .keyboardShortcut(shortcut.keyEquivalent, modifiers: shortcut.modifiers)
        .buttonStyle(.plain)
    }
    
    func shortcutHelp(_ shortcut: AppShortcut) -> some View {
        self.help("\(shortcut.title) (\(shortcut.helpText))")
    }
}
