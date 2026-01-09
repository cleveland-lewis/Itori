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
        case .dashboard: "1"
        case .calendar: "2"
        case .planner: "3"
        case .assignments: "4"
        case .courses: "5"
        case .grades: "6"
        // Actions
        case .newAssignment: "t"
        case .newCourse: "n"
        case .newModule: "m"
        case .newDeck: "d"
        case .editItem: "e"
        case .deleteItem: .delete
        case .duplicateItem: "d"
        case .showInfo: "i"
        // Search
        case .focusSearch: "f"
        case .clearSearch: .escape
        case .advancedFilter: "f"
        // Calendar
        case .goToday: "t"
        case .previousPeriod: .leftArrow
        case .nextPeriod: .rightArrow
        case .dayView: "1"
        case .weekView: "2"
        case .monthView: "3"
        case .yearView: "4"
        // Timer
        case .startStopTimer: .return
        case .resetTimer: "r"
        case .pauseTimer: "p"
        case .selectActivity: "k"
        // Flashcards
        case .flipCard: " "
        case .nextCard: .rightArrow
        case .previousCard: .leftArrow
        case .rateAgain: "1"
        case .rateHard: "2"
        case .rateGood: "3"
        case .rateEasy: "4"
        // Common
        case .toggleComplete: " "
        case .refresh: "r"
        case .save: "s"
        case .cancel: .escape
        }
    }

    var modifiers: EventModifiers {
        switch self {
        // Tab navigation
        case .dashboard, .calendar, .planner, .assignments,
             .courses, .grades:
            .command

        // New items with Shift
        case .newCourse, .newModule, .newDeck:
            [.command, .shift]

        // Regular actions
        case .newAssignment, .editItem, .deleteItem, .showInfo,
             .focusSearch, .save:
            .command

        // Duplicate (conflict resolution)
        case .duplicateItem:
            .command

        // Advanced filter
        case .advancedFilter:
            [.command, .option]

        // Calendar navigation with command
        case .goToday, .previousPeriod, .nextPeriod:
            .command

        // Calendar views (in calendar context, no modifier needed)
        case .dayView, .weekView, .monthView, .yearView:
            []

        // Timer shortcuts
        case .startStopTimer:
            .command

        case .resetTimer, .pauseTimer:
            .command

        case .selectActivity:
            .command

        // Flashcards (no modifiers, space/arrows)
        case .flipCard, .nextCard, .previousCard,
             .rateAgain, .rateHard, .rateGood, .rateEasy:
            []

        // Simple actions
        case .toggleComplete, .clearSearch, .cancel, .refresh:
            []
        }
    }

    var title: String {
        switch self {
        case .dashboard: "Dashboard"
        case .calendar: "Calendar"
        case .planner: "Planner"
        case .assignments: "Assignments"
        case .courses: "Courses"
        case .grades: "Grades"
        case .newAssignment: "New Assignment"
        case .newCourse: "New Course"
        case .newModule: "New Module"
        case .newDeck: "New Deck"
        case .editItem: "Edit"
        case .deleteItem: "Delete"
        case .duplicateItem: "Duplicate"
        case .showInfo: "Show Info"
        case .focusSearch: "Find"
        case .clearSearch: "Clear Search"
        case .advancedFilter: "Advanced Filter"
        case .goToday: "Go to Today"
        case .previousPeriod: "Previous"
        case .nextPeriod: "Next"
        case .dayView: "Day View"
        case .weekView: "Week View"
        case .monthView: "Month View"
        case .yearView: "Year View"
        case .startStopTimer: "Start/Stop Timer"
        case .resetTimer: "Reset Timer"
        case .pauseTimer: "Pause Timer"
        case .selectActivity: "Select Activity"
        case .flipCard: "Flip Card"
        case .nextCard: "Next Card"
        case .previousCard: "Previous Card"
        case .rateAgain: "Rate: Again"
        case .rateHard: "Rate: Hard"
        case .rateGood: "Rate: Good"
        case .rateEasy: "Rate: Easy"
        case .toggleComplete: "Toggle Complete"
        case .refresh: "Refresh"
        case .save: "Save"
        case .cancel: "Cancel"
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
        case .escape: "⎋"
        case .delete: "⌫"
        case .deleteForward: "⌦"
        case .return: "↩"
        case .space: "Space"
        case .tab: "⇥"
        case .upArrow: "↑"
        case .downArrow: "↓"
        case .leftArrow: "←"
        case .rightArrow: "→"
        default: keyEquivalent.character.uppercased()
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
