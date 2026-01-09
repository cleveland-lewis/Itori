//
//  ItoriCommands.swift
//  Itori
//
//  Menu bar keyboard shortcuts
//  Created: 2026-01-03
//

import SwiftUI

/// Main application commands and shortcuts
struct ItoriCommands: Commands {
    @FocusedBinding(\.selectedTab) var selectedTab: RootTab?
    @FocusedValue(\.canCreateAssignment) var canCreateAssignment: Bool?
    @FocusedValue(\.canEditItem) var canEditItem: Bool?
    @FocusedValue(\.canDeleteItem) var canDeleteItem: Bool?

    var body: some Commands {
        // Replace default New Item
        CommandGroup(replacing: .newItem) {
            Button(AppShortcut.newAssignment.title) {
                NotificationCenter.default.post(name: .createNewAssignment, object: nil)
            }
            .keyboardShortcut(AppShortcut.newAssignment.keyEquivalent, modifiers: AppShortcut.newAssignment.modifiers)
            .disabled(!(canCreateAssignment ?? false))

            Button(AppShortcut.newCourse.title) {
                NotificationCenter.default.post(name: .createNewCourse, object: nil)
            }
            .keyboardShortcut(AppShortcut.newCourse.keyEquivalent, modifiers: AppShortcut.newCourse.modifiers)

            Button(AppShortcut.newDeck.title) {
                NotificationCenter.default.post(name: .createNewDeck, object: nil)
            }
            .keyboardShortcut(AppShortcut.newDeck.keyEquivalent, modifiers: AppShortcut.newDeck.modifiers)
        }

        // Enhance Edit menu
        CommandGroup(after: .pasteboard) {
            Divider()

            Button(AppShortcut.editItem.title) {
                NotificationCenter.default.post(name: .editSelectedItem, object: nil)
            }
            .keyboardShortcut(AppShortcut.editItem.keyEquivalent, modifiers: AppShortcut.editItem.modifiers)
            .disabled(!(canEditItem ?? false))

            Button(AppShortcut.duplicateItem.title) {
                NotificationCenter.default.post(name: .duplicateSelectedItem, object: nil)
            }
            .keyboardShortcut(AppShortcut.duplicateItem.keyEquivalent, modifiers: AppShortcut.duplicateItem.modifiers)
            .disabled(!(canEditItem ?? false))

            Button(AppShortcut.deleteItem.title) {
                NotificationCenter.default.post(name: .deleteSelectedItem, object: nil)
            }
            .keyboardShortcut(AppShortcut.deleteItem.keyEquivalent, modifiers: AppShortcut.deleteItem.modifiers)
            .disabled(!(canDeleteItem ?? false))

            Divider()

            Button(AppShortcut.showInfo.title) {
                NotificationCenter.default.post(name: .showItemInfo, object: nil)
            }
            .keyboardShortcut(AppShortcut.showInfo.keyEquivalent, modifiers: AppShortcut.showInfo.modifiers)
            .disabled(!(canEditItem ?? false))
        }

        // View menu for navigation
        CommandMenu("View") {
            Button(AppShortcut.dashboard.title) {
                NotificationCenter.default.post(name: .switchToTab, object: RootTab.dashboard)
            }
            .keyboardShortcut(AppShortcut.dashboard.keyEquivalent, modifiers: AppShortcut.dashboard.modifiers)

            Button(AppShortcut.calendar.title) {
                NotificationCenter.default.post(name: .switchToTab, object: RootTab.calendar)
            }
            .keyboardShortcut(AppShortcut.calendar.keyEquivalent, modifiers: AppShortcut.calendar.modifiers)

            Button(AppShortcut.planner.title) {
                NotificationCenter.default.post(name: .switchToTab, object: RootTab.planner)
            }
            .keyboardShortcut(AppShortcut.planner.keyEquivalent, modifiers: AppShortcut.planner.modifiers)

            Button(AppShortcut.assignments.title) {
                NotificationCenter.default.post(name: .switchToTab, object: RootTab.assignments)
            }
            .keyboardShortcut(AppShortcut.assignments.keyEquivalent, modifiers: AppShortcut.assignments.modifiers)

            Button(AppShortcut.courses.title) {
                NotificationCenter.default.post(name: .switchToTab, object: RootTab.courses)
            }
            .keyboardShortcut(AppShortcut.courses.keyEquivalent, modifiers: AppShortcut.courses.modifiers)

            Button(AppShortcut.grades.title) {
                NotificationCenter.default.post(name: .switchToTab, object: RootTab.grades)
            }
            .keyboardShortcut(AppShortcut.grades.keyEquivalent, modifiers: AppShortcut.grades.modifiers)

            Divider()

            Button(AppShortcut.focusSearch.title) {
                NotificationCenter.default.post(name: .focusSearchField, object: nil)
            }
            .keyboardShortcut(AppShortcut.focusSearch.keyEquivalent, modifiers: AppShortcut.focusSearch.modifiers)
        }

        // Go menu for navigation
        CommandMenu("Go") {
            Button(AppShortcut.goToday.title) {
                NotificationCenter.default.post(name: .goToTodayNotification, object: nil)
            }
            .keyboardShortcut(AppShortcut.goToday.keyEquivalent, modifiers: AppShortcut.goToday.modifiers)

            Divider()

            Button(AppShortcut.previousPeriod.title) {
                NotificationCenter.default.post(name: .navigatePrevious, object: nil)
            }
            .keyboardShortcut(AppShortcut.previousPeriod.keyEquivalent, modifiers: AppShortcut.previousPeriod.modifiers)

            Button(AppShortcut.nextPeriod.title) {
                NotificationCenter.default.post(name: .navigateNext, object: nil)
            }
            .keyboardShortcut(AppShortcut.nextPeriod.keyEquivalent, modifiers: AppShortcut.nextPeriod.modifiers)
        }
    }
}

// MARK: - Focused Values

extension FocusedValues {
    struct CanCreateAssignmentKey: FocusedValueKey {
        typealias Value = Bool
    }

    struct CanEditItemKey: FocusedValueKey {
        typealias Value = Bool
    }

    struct CanDeleteItemKey: FocusedValueKey {
        typealias Value = Bool
    }

    struct SelectedTabKey: FocusedValueKey {
        typealias Value = Binding<RootTab>
    }

    var canCreateAssignment: CanCreateAssignmentKey.Value? {
        get { self[CanCreateAssignmentKey.self] }
        set { self[CanCreateAssignmentKey.self] = newValue }
    }

    var canEditItem: CanEditItemKey.Value? {
        get { self[CanEditItemKey.self] }
        set { self[CanEditItemKey.self] = newValue }
    }

    var canDeleteItem: CanDeleteItemKey.Value? {
        get { self[CanDeleteItemKey.self] }
        set { self[CanDeleteItemKey.self] = newValue }
    }

    var selectedTab: SelectedTabKey.Value? {
        get { self[SelectedTabKey.self] }
        set { self[SelectedTabKey.self] = newValue }
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let createNewAssignment = Notification.Name("createNewAssignment")
    static let createNewCourse = Notification.Name("createNewCourse")
    static let createNewDeck = Notification.Name("createNewDeck")
    static let editSelectedItem = Notification.Name("editSelectedItem")
    static let duplicateSelectedItem = Notification.Name("duplicateSelectedItem")
    static let deleteSelectedItem = Notification.Name("deleteSelectedItem")
    static let showItemInfo = Notification.Name("showItemInfo")
    static let switchToTab = Notification.Name("switchToTab")
    static let focusSearchField = Notification.Name("focusSearchField")
    // Navigation notifications used by the Go menu
}
