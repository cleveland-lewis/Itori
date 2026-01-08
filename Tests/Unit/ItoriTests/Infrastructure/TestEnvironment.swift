//
//  TestEnvironment.swift
//  ItoriTests
//
//  Centralized test hardening hooks for unit/integration suites.
//

import Foundation
@testable import Itori

@MainActor
final class TestEnvironment {
    private var settingsSnapshot: SettingsSnapshot?
    private var originalCoursesStore: CoursesStore?
    private var tempCoursesStoreURL: URL?

    func start() {
        snapshotSettings()
        applyTestSettings()
        replaceCoursesStoreIfNeeded()
    }

    func stop() {
        restoreCoursesStore()
        restoreSettings()
    }

    private func snapshotSettings() {
        let settings = AppSettingsModel.shared
        settingsSnapshot = SettingsSnapshot(
            enableICloudSync: settings.enableICloudSync,
            suppressICloudRestore: settings.suppressICloudRestore,
            enableAIPlanner: settings.enableAIPlanner,
            enableAutoReschedule: settings.enableAutoReschedule,
            notificationsEnabled: settings.notificationsEnabled,
            assignmentRemindersEnabled: settings.assignmentRemindersEnabled,
            timerAlertsEnabled: settings.timerAlertsEnabled,
            pomodoroAlertsEnabled: settings.pomodoroAlertsEnabled
        )
    }

    private func applyTestSettings() {
        let settings = AppSettingsModel.shared
        settings.enableICloudSync = false
        settings.suppressICloudRestore = true
        settings.enableAIPlanner = false
        settings.enableAutoReschedule = false
        settings.notificationsEnabled = false
        settings.assignmentRemindersEnabled = false
        settings.timerAlertsEnabled = false
        settings.pomodoroAlertsEnabled = false
    }

    private func replaceCoursesStoreIfNeeded() {
        originalCoursesStore = CoursesStore.shared
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent("ItoriTests-\(UUID().uuidString)")
        let storageURL = tempDir.appendingPathComponent("courses.json")
        tempCoursesStoreURL = storageURL
        CoursesStore.shared = CoursesStore(storageURL: storageURL)
    }

    private func restoreCoursesStore() {
        if let original = originalCoursesStore {
            CoursesStore.shared = original
        } else {
            CoursesStore.shared = nil
        }
        originalCoursesStore = nil
        if let url = tempCoursesStoreURL {
            try? FileManager.default.removeItem(at: url.deletingLastPathComponent())
        }
        tempCoursesStoreURL = nil
    }

    private func restoreSettings() {
        guard let snapshot = settingsSnapshot else { return }
        let settings = AppSettingsModel.shared
        settings.enableICloudSync = snapshot.enableICloudSync
        settings.suppressICloudRestore = snapshot.suppressICloudRestore
        settings.enableAIPlanner = snapshot.enableAIPlanner
        settings.enableAutoReschedule = snapshot.enableAutoReschedule
        settings.notificationsEnabled = snapshot.notificationsEnabled
        settings.assignmentRemindersEnabled = snapshot.assignmentRemindersEnabled
        settings.timerAlertsEnabled = snapshot.timerAlertsEnabled
        settings.pomodoroAlertsEnabled = snapshot.pomodoroAlertsEnabled
        settingsSnapshot = nil
    }
}

private struct SettingsSnapshot {
    let enableICloudSync: Bool
    let suppressICloudRestore: Bool
    let enableAIPlanner: Bool
    let enableAutoReschedule: Bool
    let notificationsEnabled: Bool
    let assignmentRemindersEnabled: Bool
    let timerAlertsEnabled: Bool
    let pomodoroAlertsEnabled: Bool
}
