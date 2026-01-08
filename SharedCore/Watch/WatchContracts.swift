import Foundation
import SwiftUI

// TimerMode is defined in SharedCore/Models/TimerModels.swift

public enum EnergyLevel: String, Codable, CaseIterable {
    case low
    case medium
    case high
    
    public var label: String {
        switch self {
        case .low: return "Low"
        case .medium: return "Med"
        case .high: return "High"
        }
    }
    
    public var color: Color {
        switch self {
        case .low: return .orange
        case .medium: return .blue
        case .high: return .green
        }
    }
}

public struct ActiveTimerSummary: Codable {
    public let id: UUID
    public let mode: TimerMode
    public let durationSeconds: Int?
    public let startedAtISO: String
    
    public init(id: UUID, mode: TimerMode, durationSeconds: Int?, startedAtISO: String) {
        self.id = id
        self.mode = mode
        self.durationSeconds = durationSeconds
        self.startedAtISO = startedAtISO
    }
}

public struct TaskSummary: Codable, Identifiable {
    public let id: UUID
    public let title: String
    public let dueISO: String?
    public let isComplete: Bool
    
    public init(id: UUID, title: String, dueISO: String?, isComplete: Bool) {
        self.id = id
        self.title = title
        self.dueISO = dueISO
        self.isComplete = isComplete
    }
}

public struct WatchSnapshot: Codable {
    public var activeTimer: ActiveTimerSummary?
    public var todaysTasks: [TaskSummary]
    public var energyToday: EnergyLevel?
    public var lastSyncISO: String
    
    public init(activeTimer: ActiveTimerSummary? = nil, todaysTasks: [TaskSummary] = [], energyToday: EnergyLevel? = nil, lastSyncISO: String? = nil) {
        self.activeTimer = activeTimer
        self.todaysTasks = todaysTasks
        self.energyToday = energyToday
        self.lastSyncISO = lastSyncISO ?? ISO8601DateFormatter().string(from: Date())
    }
}

public enum WatchCommand: Codable {
    case startTimer(mode: TimerMode, durationSeconds: Int?)
    case completeTask(id: UUID)
    case setEnergy(level: EnergyLevel, dateISO: String)

    enum CodingKeys: String, CodingKey {
        case type
        case mode
        case durationSeconds
        case id
        case level
        case dateISO
    }

    enum CommandType: String, Codable {
        case startTimer
        case completeTask
        case setEnergy
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case let .startTimer(mode, duration):
            try container.encode(CommandType.startTimer, forKey: .type)
            try container.encode(mode, forKey: .mode)
            try container.encodeIfPresent(duration, forKey: .durationSeconds)
        case let .completeTask(id):
            try container.encode(CommandType.completeTask, forKey: .type)
            try container.encode(id, forKey: .id)
        case let .setEnergy(level, dateISO):
            try container.encode(CommandType.setEnergy, forKey: .type)
            try container.encode(level, forKey: .level)
            try container.encode(dateISO, forKey: .dateISO)
        }
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(CommandType.self, forKey: .type)
        switch type {
        case .startTimer:
            let mode = try container.decode(TimerMode.self, forKey: .mode)
            let duration = try container.decodeIfPresent(Int.self, forKey: .durationSeconds)
            self = .startTimer(mode: mode, durationSeconds: duration)
        case .completeTask:
            let id = try container.decode(UUID.self, forKey: .id)
            self = .completeTask(id: id)
        case .setEnergy:
            let level = try container.decode(EnergyLevel.self, forKey: .level)
            let dateISO = try container.decode(String.self, forKey: .dateISO)
            self = .setEnergy(level: level, dateISO: dateISO)
        }
    }
}
