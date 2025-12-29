import Foundation
import Combine

// MARK: - Integration Pattern Enforcement

/// Enforces that all AI integrations follow the approved pattern:
/// - Only AIEngine.request() allowed
/// - No direct provider access from features
/// - No direct fallback calls from features
/// - ViewModels only, never Views
public enum AIIntegrationEnforcement {
    static let appLaunchDate = Date()
    
    /// Validates that a caller is authorized to use AI
    public static func validateCaller(file: String = #file, function: String = #function) -> Bool {
        // In production, this would check that:
        // 1. Caller is a ViewModel (not a View)
        // 2. Caller doesn't import provider modules
        // 3. Call path goes through approved entry points
        
        #if DEBUG
        // Verify not called from SwiftUI View
        let isView = file.contains("View.swift") && !file.contains("ViewModel")
        if isView {
            assertionFailure("❌ AI integration violated: \(function) called from View layer. Use ViewModel only.")
            return false
        }
        #endif
        
        return true
    }
    
    /// Reports unauthorized integration attempts
    public static func reportViolation(_ message: String, file: String = #file, line: Int = #line) {
        #if DEBUG
        DebugLogger.log("⚠️ AI Integration Violation at \(file):\(line)")
        DebugLogger.log("   \(message)")
        assertionFailure(message)
        #endif
    }
}

// MARK: - Field-Level Monotonic Merge Guard

/// Tracks edit state to prevent late AI results from overwriting user edits
public struct FieldMergeGuard: Codable, Sendable {
    public let lastUserEditAt: Date?
    public let lastUserEditUptime: TimeInterval?
    public let lastAppliedAIAt: Date?
    public let lastAppliedAIUptime: TimeInterval?
    public let lastAppliedAIInputHash: String?
    public let isUserLocked: Bool
    
    public init(
        lastUserEditAt: Date? = nil,
        lastUserEditUptime: TimeInterval? = nil,
        lastAppliedAIAt: Date? = nil,
        lastAppliedAIUptime: TimeInterval? = nil,
        lastAppliedAIInputHash: String? = nil,
        isUserLocked: Bool = false
    ) {
        self.lastUserEditAt = lastUserEditAt
        self.lastUserEditUptime = lastUserEditUptime
        self.lastAppliedAIAt = lastAppliedAIAt
        self.lastAppliedAIUptime = lastAppliedAIUptime
        self.lastAppliedAIInputHash = lastAppliedAIInputHash
        self.isUserLocked = isUserLocked
    }
    
    /// Determines if an AI result should be applied to this field
    public func shouldApply(
        result: any AIResultProtocol,
        currentInputHash: String,
        currentFeatureStateVersion: Int? = nil
    ) -> Bool {
        // Never apply if user has locked the field
        guard !isUserLocked else {
            return false
        }
        
        // Never apply if result input doesn't match current state
        guard currentInputHash == result.inputHash else {
            return false
        }

        if let version = currentFeatureStateVersion, version != result.featureStateVersion {
            return false
        }
        
        // Never apply if user edited after result was computed
        if let userEditTime = lastUserEditAt,
           userEditTime >= result.computedAt {
            return false
        }

        if let userEditUptime = lastUserEditUptime,
           let resultUptime = result.computedAtUptime,
           userEditUptime >= resultUptime {
            return false
        }

        if result.computedAt < AIIntegrationEnforcement.appLaunchDate,
           lastUserEditAt != nil {
            return false
        }
        
        // Never apply stale results
        if let lastApplied = lastAppliedAIAt,
           result.computedAt < lastApplied {
            return false
        }

        if let lastAppliedUptime = lastAppliedAIUptime,
           let resultUptime = result.computedAtUptime,
           resultUptime < lastAppliedUptime {
            return false
        }
        
        return true
    }
    
    /// Records that user edited this field
    public func withUserEdit(at time: Date = Date()) -> FieldMergeGuard {
        FieldMergeGuard(
            lastUserEditAt: time,
            lastUserEditUptime: ProcessInfo.processInfo.systemUptime,
            lastAppliedAIAt: lastAppliedAIAt,
            lastAppliedAIUptime: lastAppliedAIUptime,
            lastAppliedAIInputHash: lastAppliedAIInputHash,
            isUserLocked: isUserLocked
        )
    }
    
    /// Records that AI result was applied
    public func withAIApplied(
        at time: Date = Date(),
        inputHash: String
    ) -> FieldMergeGuard {
        FieldMergeGuard(
            lastUserEditAt: lastUserEditAt,
            lastUserEditUptime: lastUserEditUptime,
            lastAppliedAIAt: time,
            lastAppliedAIUptime: ProcessInfo.processInfo.systemUptime,
            lastAppliedAIInputHash: inputHash,
            isUserLocked: isUserLocked
        )
    }
    
    /// Locks field to prevent any AI modifications
    public func locked() -> FieldMergeGuard {
        FieldMergeGuard(
            lastUserEditAt: lastUserEditAt,
            lastUserEditUptime: lastUserEditUptime,
            lastAppliedAIAt: lastAppliedAIAt,
            lastAppliedAIUptime: lastAppliedAIUptime,
            lastAppliedAIInputHash: lastAppliedAIInputHash,
            isUserLocked: true
        )
    }
}

// MARK: - AI Result Protocol

public protocol AIResultProtocol {
    var inputHash: String { get }
    var computedAt: Date { get }
    var computedAtUptime: TimeInterval? { get }
    var featureStateVersion: Int { get }
    var confidence: AIConfidence { get }
    var provenance: AIProvenance { get }
}

extension AIResult: AIResultProtocol {
    public var inputHash: String {
        metadata.inputHash
    }
    
    public var computedAt: Date {
        metadata.computedAt
    }

    public var computedAtUptime: TimeInterval? {
        metadata.computedAtUptime
    }

    public var featureStateVersion: Int {
        metadata.featureStateVersion
    }
}

// MARK: - Merge Policy

/// Defines the only allowed user-visible AI merge behaviors.
public enum AIMergePolicy: String, Codable, Sendable {
    /// AI provides default values only (user can edit).
    case defaultOnly
    /// AI suggests changes but never applies them.
    case suggestOnly
    /// AI requires explicit user approval before applying.
    case explicitApplyRequired
    
    /// Determines if result should be applied to the live field.
    public func shouldApply(
        result: any AIResultProtocol,
        guard: FieldMergeGuard,
        currentInputHash: String,
        isFieldEmpty: Bool
    ) -> Bool {
        guard `guard`.shouldApply(result: result, currentInputHash: currentInputHash) else {
            return false
        }
        
        switch self {
        case .defaultOnly:
            return isFieldEmpty && `guard`.lastUserEditAt == nil
        case .suggestOnly, .explicitApplyRequired:
            return false
        }
    }
}

// MARK: - Schedule Diff (Never Mutate Calendar Directly)

/// Represents proposed schedule changes without actually modifying calendar.
public struct ScheduleDiff: Codable, Sendable, Equatable {
    public let addedBlocks: [ProposedBlock]
    public let movedBlocks: [MovedBlock]
    public let resizedBlocks: [ResizedBlock]
    public let removedBlocks: [RemovedBlock]
    public let conflicts: [ScheduleConflict]
    public let reason: String
    public let confidence: AIConfidence
    
    public init(
        addedBlocks: [ProposedBlock] = [],
        movedBlocks: [MovedBlock] = [],
        resizedBlocks: [ResizedBlock] = [],
        removedBlocks: [RemovedBlock] = [],
        conflicts: [ScheduleConflict] = [],
        reason: String,
        confidence: AIConfidence
    ) {
        self.addedBlocks = addedBlocks
        self.movedBlocks = movedBlocks
        self.resizedBlocks = resizedBlocks
        self.removedBlocks = removedBlocks
        self.conflicts = conflicts
        self.reason = reason
        self.confidence = confidence
    }
    
    /// Returns true if applying this diff would be idempotent.
    public func isIdempotent() -> Bool {
        let addedIDs = Set(addedBlocks.map { $0.tempID })
        let movedIDs = Set(movedBlocks.map { $0.blockID })
        let resizedIDs = Set(resizedBlocks.map { $0.blockID })
        let removedIDs = Set(removedBlocks.map { $0.blockID })
        
        return addedIDs.isDisjoint(with: movedIDs) &&
               addedIDs.isDisjoint(with: resizedIDs) &&
               addedIDs.isDisjoint(with: removedIDs) &&
               movedIDs.isDisjoint(with: resizedIDs) &&
               movedIDs.isDisjoint(with: removedIDs) &&
               resizedIDs.isDisjoint(with: removedIDs)
    }
}

public struct ProposedBlock: Codable, Sendable, Identifiable, Equatable {
    public let id: UUID
    public let tempID: String
    public let title: String
    public let startDate: Date
    public let duration: TimeInterval
    public let reason: String
    
    public init(id: UUID = UUID(), tempID: String, title: String, startDate: Date, duration: TimeInterval, reason: String) {
        self.id = id
        self.tempID = tempID
        self.title = title
        self.startDate = startDate
        self.duration = duration
        self.reason = reason
    }
}

public struct MovedBlock: Codable, Sendable, Identifiable, Equatable {
    public let id: UUID
    public let blockID: String
    public let newStartDate: Date
    public let reason: String
    
    public init(id: UUID = UUID(), blockID: String, newStartDate: Date, reason: String) {
        self.id = id
        self.blockID = blockID
        self.newStartDate = newStartDate
        self.reason = reason
    }
}

public struct ResizedBlock: Codable, Sendable, Identifiable, Equatable {
    public let id: UUID
    public let blockID: String
    public let newDuration: TimeInterval
    public let reason: String
    
    public init(id: UUID = UUID(), blockID: String, newDuration: TimeInterval, reason: String) {
        self.id = id
        self.blockID = blockID
        self.newDuration = newDuration
        self.reason = reason
    }
}

public struct RemovedBlock: Codable, Sendable, Identifiable, Equatable {
    public let id: UUID
    public let blockID: String
    public let reason: String

    public init(id: UUID = UUID(), blockID: String, reason: String) {
        self.id = id
        self.blockID = blockID
        self.reason = reason
    }
}

public struct ScheduleConflict: Codable, Sendable, Identifiable, Equatable {
    public let id: UUID
    public let blockID: String
    public let conflictingBlockID: String?
    public let reason: String
    
    public init(id: UUID = UUID(), blockID: String, conflictingBlockID: String? = nil, reason: String) {
        self.id = id
        self.blockID = blockID
        self.conflictingBlockID = conflictingBlockID
        self.reason = reason
    }
}

// MARK: - Regression Tripwires

/// Monitors AI subsystem health and triggers alerts on degradation
@MainActor
public final class AIRegressionMonitor: ObservableObject {
    public static let shared = AIRegressionMonitor()
    
    @Published public private(set) var alerts: [RegressionAlert] = []
    
    private var baseline = HealthBaseline()
    private var current = HealthMetrics()
    
    private init() {}
    
    /// Records a port execution for monitoring
    public func recordExecution(
        port: AIPortID,
        usedFallback: Bool,
        latencyMs: Int,
        validationFailed: Bool,
        redactionDelta: Double
    ) {
        current.recordExecution(
            port: port,
            usedFallback: usedFallback,
            latencyMs: latencyMs,
            validationFailed: validationFailed,
            redactionDelta: redactionDelta
        )
        
        checkForRegressions()
    }
    
    private func checkForRegressions() {
        alerts.removeAll()
        
        // Check fallback usage spike
        let fallbackRate = current.fallbackRate
        if fallbackRate > baseline.fallbackRate * 1.3 {
            alerts.append(RegressionAlert(
                severity: .warning,
                message: "Fallback usage increased by \(Int((fallbackRate - baseline.fallbackRate) * 100))%",
                metric: "fallbackRate",
                current: fallbackRate,
                baseline: baseline.fallbackRate
            ))
        }
        
        // Check validation failure rate
        let validationFailureRate = current.validationFailureRate
        if validationFailureRate > 0.05 {
            alerts.append(RegressionAlert(
                severity: .error,
                message: "Validation failure rate above 5%: \(Int(validationFailureRate * 100))%",
                metric: "validationFailureRate",
                current: validationFailureRate,
                baseline: 0.05
            ))
        }
        
        // Check p95 latency
        if let p95 = current.p95Latency, p95 > baseline.latencyBudgetMs {
            alerts.append(RegressionAlert(
                severity: .warning,
                message: "P95 latency exceeds budget: \(p95)ms vs \(baseline.latencyBudgetMs)ms",
                metric: "p95Latency",
                current: Double(p95),
                baseline: Double(baseline.latencyBudgetMs)
            ))
        }
        
        // Check redaction delta
        let avgRedaction = current.avgRedactionDelta
        if avgRedaction > 0.3 {
            alerts.append(RegressionAlert(
                severity: .warning,
                message: "High redaction delta: \(Int(avgRedaction * 100))% of input redacted",
                metric: "redactionDelta",
                current: avgRedaction,
                baseline: 0.3
            ))
        }
    }
    
    /// Resets baseline to current metrics
    public func setBaseline() {
        baseline = HealthBaseline(
            fallbackRate: current.fallbackRate,
            validationFailureRate: current.validationFailureRate,
            latencyBudgetMs: 800
        )
    }
}

public struct RegressionAlert: Identifiable {
    public let id = UUID()
    public let severity: Severity
    public let message: String
    public let metric: String
    public let current: Double
    public let baseline: Double
    
    public enum Severity {
        case warning
        case error
    }
}

private struct HealthBaseline {
    var fallbackRate: Double = 0.2
    var validationFailureRate: Double = 0.01
    var latencyBudgetMs: Int = 800
}

private struct HealthMetrics {
    private var executions: [ExecutionRecord] = []
    
    var fallbackRate: Double {
        guard !executions.isEmpty else { return 0 }
        let fallbacks = executions.filter { $0.usedFallback }.count
        return Double(fallbacks) / Double(executions.count)
    }
    
    var validationFailureRate: Double {
        guard !executions.isEmpty else { return 0 }
        let failures = executions.filter { $0.validationFailed }.count
        return Double(failures) / Double(executions.count)
    }
    
    var p95Latency: Int? {
        guard !executions.isEmpty else { return nil }
        let sorted = executions.map { $0.latencyMs }.sorted()
        let index = Int(Double(sorted.count) * 0.95)
        return sorted[min(index, sorted.count - 1)]
    }
    
    var avgRedactionDelta: Double {
        guard !executions.isEmpty else { return 0 }
        let sum = executions.map { $0.redactionDelta }.reduce(0, +)
        return sum / Double(executions.count)
    }
    
    mutating func recordExecution(
        port: AIPortID,
        usedFallback: Bool,
        latencyMs: Int,
        validationFailed: Bool,
        redactionDelta: Double
    ) {
        executions.append(ExecutionRecord(
            port: port,
            usedFallback: usedFallback,
            latencyMs: latencyMs,
            validationFailed: validationFailed,
            redactionDelta: redactionDelta
        ))
        
        // Keep last 1000 executions
        if executions.count > 1000 {
            executions.removeFirst(executions.count - 1000)
        }
    }
}

private struct ExecutionRecord {
    let port: AIPortID
    let usedFallback: Bool
    let latencyMs: Int
    let validationFailed: Bool
    let redactionDelta: Double
}
