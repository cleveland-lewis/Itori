//
//  UsageStatsTests.swift
//  RootsTests
//
//  Tests for UsageStats - Usage analytics models
//

import XCTest
@testable import Roots

@MainActor
final class UsageStatsTests: BaseTestCase {
    
    // MARK: - UsageStats Initialization Tests
    
    func testUsageStatsInitialization() {
        let start = Date()
        let end = Date().addingTimeInterval(86400)
        
        let stats = UsageStats(
            startDate: start,
            endDate: end,
            totalScheduledMinutes: 120,
            totalCompletedMinutes: 90,
            totalSkippedMinutes: 30,
            hourly: [],
            byTaskType: [],
            byDay: []
        )
        
        XCTAssertEqual(stats.startDate, start)
        XCTAssertEqual(stats.endDate, end)
        XCTAssertEqual(stats.totalScheduledMinutes, 120)
        XCTAssertEqual(stats.totalCompletedMinutes, 90)
        XCTAssertEqual(stats.totalSkippedMinutes, 30)
        XCTAssertEqual(stats.hourly.count, 0)
        XCTAssertEqual(stats.byTaskType.count, 0)
        XCTAssertEqual(stats.byDay.count, 0)
    }
    
    func testUsageStatsWithData() {
        let start = Date()
        let end = Date().addingTimeInterval(86400)
        
        let hourlyData = [
            UsageStats.HourlyPerformance(hour: 9, scheduledMinutes: 60, completedMinutes: 50),
            UsageStats.HourlyPerformance(hour: 14, scheduledMinutes: 45, completedMinutes: 40)
        ]
        
        let taskTypeData = [
            UsageStats.TaskTypeStats(
                type: .assignment,
                scheduledMinutes: 90,
                completedMinutes: 80,
                avgPlannedBlockMinutes: 30.0,
                avgActualBlockMinutes: 27.0
            )
        ]
        
        let dayData = [
            UsageStats.DayStats(date: start, scheduledMinutes: 120, completedMinutes: 100)
        ]
        
        let stats = UsageStats(
            startDate: start,
            endDate: end,
            totalScheduledMinutes: 120,
            totalCompletedMinutes: 100,
            totalSkippedMinutes: 20,
            hourly: hourlyData,
            byTaskType: taskTypeData,
            byDay: dayData
        )
        
        XCTAssertEqual(stats.hourly.count, 2)
        XCTAssertEqual(stats.byTaskType.count, 1)
        XCTAssertEqual(stats.byDay.count, 1)
    }
    
    func testUsageStatsCompletionCalculation() {
        let stats = UsageStats(
            startDate: Date(),
            endDate: Date(),
            totalScheduledMinutes: 100,
            totalCompletedMinutes: 75,
            totalSkippedMinutes: 25,
            hourly: [],
            byTaskType: [],
            byDay: []
        )
        
        let completionRate = Double(stats.totalCompletedMinutes) / Double(stats.totalScheduledMinutes)
        XCTAssertEqual(completionRate, 0.75, accuracy: 0.01)
    }
}

// MARK: - HourlyPerformance Tests

@MainActor
final class HourlyPerformanceTests: BaseTestCase {
    
    func testHourlyPerformanceInitialization() {
        let hourly = UsageStats.HourlyPerformance(
            hour: 10,
            scheduledMinutes: 60,
            completedMinutes: 45
        )
        
        XCTAssertEqual(hourly.hour, 10)
        XCTAssertEqual(hourly.scheduledMinutes, 60)
        XCTAssertEqual(hourly.completedMinutes, 45)
    }
    
    func testHourlyPerformanceValidHourRange() {
        let morning = UsageStats.HourlyPerformance(hour: 0, scheduledMinutes: 30, completedMinutes: 25)
        let evening = UsageStats.HourlyPerformance(hour: 23, scheduledMinutes: 45, completedMinutes: 40)
        
        XCTAssertEqual(morning.hour, 0)
        XCTAssertEqual(evening.hour, 23)
    }
    
    func testHourlyPerformanceCompletionRate() {
        let hourly = UsageStats.HourlyPerformance(
            hour: 14,
            scheduledMinutes: 60,
            completedMinutes: 48
        )
        
        let rate = Double(hourly.completedMinutes) / Double(hourly.scheduledMinutes)
        XCTAssertEqual(rate, 0.8, accuracy: 0.01)
    }
    
    func testHourlyPerformanceZeroScheduled() {
        let hourly = UsageStats.HourlyPerformance(
            hour: 5,
            scheduledMinutes: 0,
            completedMinutes: 0
        )
        
        XCTAssertEqual(hourly.scheduledMinutes, 0)
        XCTAssertEqual(hourly.completedMinutes, 0)
    }
}

// MARK: - TaskTypeStats Tests

@MainActor
final class TaskTypeStatsTests: BaseTestCase {
    
    func testTaskTypeStatsInitialization() {
        let stats = UsageStats.TaskTypeStats(
            type: .assignment,
            scheduledMinutes: 120,
            completedMinutes: 90,
            avgPlannedBlockMinutes: 30.0,
            avgActualBlockMinutes: 27.5
        )
        
        XCTAssertEqual(stats.type, .assignment)
        XCTAssertEqual(stats.scheduledMinutes, 120)
        XCTAssertEqual(stats.completedMinutes, 90)
        XCTAssertEqual(stats.avgPlannedBlockMinutes, 30.0)
        XCTAssertEqual(stats.avgActualBlockMinutes, 27.5)
    }
    
    func testTaskTypeStatsMultipleTypes() {
        let assignmentStats = UsageStats.TaskTypeStats(
            type: .assignment,
            scheduledMinutes: 120,
            completedMinutes: 100,
            avgPlannedBlockMinutes: 30.0,
            avgActualBlockMinutes: 28.0
        )
        
        let reviewStats = UsageStats.TaskTypeStats(
            type: .review,
            scheduledMinutes: 60,
            completedMinutes: 50,
            avgPlannedBlockMinutes: 20.0,
            avgActualBlockMinutes: 18.0
        )
        
        XCTAssertNotEqual(assignmentStats.type, reviewStats.type)
        XCTAssertGreaterThan(assignmentStats.scheduledMinutes, reviewStats.scheduledMinutes)
    }
    
    func testTaskTypeStatsAverageAccuracy() {
        let stats = UsageStats.TaskTypeStats(
            type: .assignment,
            scheduledMinutes: 180,
            completedMinutes: 150,
            avgPlannedBlockMinutes: 30.0,
            avgActualBlockMinutes: 25.0
        )
        
        // Average actual should be less than planned (work took less time)
        XCTAssertLessThan(stats.avgActualBlockMinutes, stats.avgPlannedBlockMinutes)
    }
    
    func testTaskTypeStatsCompletionRate() {
        let stats = UsageStats.TaskTypeStats(
            type: .assignment,
            scheduledMinutes: 100,
            completedMinutes: 85,
            avgPlannedBlockMinutes: 25.0,
            avgActualBlockMinutes: 21.25
        )
        
        let rate = Double(stats.completedMinutes) / Double(stats.scheduledMinutes)
        XCTAssertEqual(rate, 0.85, accuracy: 0.01)
    }
}

// MARK: - DayStats Tests

@MainActor
final class DayStatsTests: BaseTestCase {
    
    func testDayStatsInitialization() {
        let date = Date()
        let stats = UsageStats.DayStats(
            date: date,
            scheduledMinutes: 180,
            completedMinutes: 150
        )
        
        XCTAssertEqual(stats.date, date)
        XCTAssertEqual(stats.scheduledMinutes, 180)
        XCTAssertEqual(stats.completedMinutes, 150)
    }
    
    func testDayStatsSequence() {
        let today = Date()
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today)!
        
        let todayStats = UsageStats.DayStats(
            date: today,
            scheduledMinutes: 120,
            completedMinutes: 100
        )
        
        let yesterdayStats = UsageStats.DayStats(
            date: yesterday,
            scheduledMinutes: 90,
            completedMinutes: 80
        )
        
        XCTAssertNotEqual(todayStats.date, yesterdayStats.date)
        XCTAssertGreaterThan(todayStats.date, yesterdayStats.date)
    }
    
    func testDayStatsCompletionRate() {
        let stats = UsageStats.DayStats(
            date: Date(),
            scheduledMinutes: 200,
            completedMinutes: 160
        )
        
        let rate = Double(stats.completedMinutes) / Double(stats.scheduledMinutes)
        XCTAssertEqual(rate, 0.8, accuracy: 0.01)
    }
    
    func testDayStatsZeroCompletion() {
        let stats = UsageStats.DayStats(
            date: Date(),
            scheduledMinutes: 120,
            completedMinutes: 0
        )
        
        XCTAssertEqual(stats.completedMinutes, 0)
        XCTAssertGreaterThan(stats.scheduledMinutes, 0)
    }
    
    func testDayStatsOverCompletion() {
        // User completed more than scheduled
        let stats = UsageStats.DayStats(
            date: Date(),
            scheduledMinutes: 100,
            completedMinutes: 120
        )
        
        XCTAssertGreaterThan(stats.completedMinutes, stats.scheduledMinutes)
    }
}
