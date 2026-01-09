import Foundation

// MARK: - TaskType Localization

extension TaskType {
    /// Localized display name - NEVER use rawValue for UI
    var localizedName: String {
        switch self {
        case .homework:
            "task.type.homework".localized
        case .quiz:
            "task.type.quiz".localized
        case .exam:
            "task.type.exam".localized
        case .reading:
            "task.type.reading".localized
        case .review:
            "task.type.review".localized
        case .project:
            "task.type.project".localized
        case .study:
            "task.type.study".localized
        case .practiceTest:
            "task.type.practice_test".localized
        }
    }
}

// MARK: - Timer Mode Localization

extension TimerMode {
    // displayName already exists in TimerModels.swift
    // Keep that implementation to avoid breaking changes
}

// MARK: - Common Localizations Helper

enum CommonLocalizations {
    static let today = "common.today".localized
    static let due = "common.due".localized
    static let noDate = "common.no_date".localized
    static let noCourse = "common.no_course".localized
    static let edit = "common.edit".localized
    static let done = "common.done".localized
    static let menu = "common.menu".localized

    static let importance = "attribute.importance".localized
    static let difficulty = "attribute.difficulty".localized
}

// MARK: - Planner Localizations

enum PlannerLocalizations {
    static let today = "planner.today".localized
    static let generate = "planner.generate".localized
    static let howItWorks = "planner.how_it_works".localized
    static let emptyTitle = "planner.empty.title".localized
    static let emptySubtitle = "planner.empty.subtitle".localized
    static let noPlan = "planner.no_plan".localized

    static func allowedHours(min: Int, max: Int) -> String {
        String.localizedStringWithFormat("planner.allowed_hours".localized, min, max)
    }

    static func stepsCount(completed: Int, total: Int) -> String {
        String.localizedStringWithFormat("planner.steps_count".localized, completed, total)
    }

    static func minutesTotal(_ minutes: Int) -> String {
        String.localizedStringWithFormat("planner.minutes_total".localized, minutes)
    }

    static func progress(_ percentage: Int) -> String {
        String.localizedStringWithFormat("planner.progress".localized, percentage)
    }

    static func updated(_ timeAgo: String) -> String {
        String.localizedStringWithFormat("planner.updated".localized, timeAgo)
    }

    static func dueDate(_ date: String) -> String {
        String.localizedStringWithFormat("plans.due_date".localized, date)
    }
}

// MARK: - Dashboard Localizations

enum DashboardLocalizations {
    static let emptyCalendar = "dashboard.empty.calendar".localized
    static let emptyEvents = "dashboard.empty.events".localized
    static let emptyTasks = "dashboard.empty.tasks".localized
    static let sectionTodaysWork = "dashboard.section.todays_work".localized

    static func tasksDueCount(_ count: Int) -> String {
        if count == 0 {
            "No tasks due"
        } else if count == 1 {
            "1 task due"
        } else {
            "\(count) tasks due"
        }
    }

    static func assignmentsPlanned(_ count: Int) -> String {
        if count == 0 {
            "No assignments planned"
        } else if count == 1 {
            "1 assignment planned"
        } else {
            "\(count) assignments planned"
        }
    }

    static func minutesScheduled(_ minutes: Int) -> String {
        "\(minutes) min scheduled"
    }
}

// MARK: - Quick Add Localizations

enum QuickAddLocalizations {
    static let assignment = "quick_add.assignment".localized
    static let grade = "quick_add.grade".localized
    static let schedule = "quick_add.schedule".localized
}

// MARK: - Menu Localizations

enum MenuLocalizations {
    static let starredTabs = "menu.starred_tabs".localized
    static let starredTabsFooter = "menu.starred_tabs.footer".localized
    static let pinLimit = "menu.pin_limit".localized
}
