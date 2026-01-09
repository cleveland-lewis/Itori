import Foundation

/// Health monitoring and observability for the AI Engine
/// Dev-only panel for diagnosing port behavior without exposing "AI" to users
public struct AIHealthMonitor {
    // MARK: - LLM Provider Attempt Tracking (Dev-Only Kill-Switch Enforcement)

    /// Comprehensive counters for LLM provider attempts vs fallback-only execution
    public struct LLMProviderCounters: Codable {
        var providerAttemptCountTotal: Int = 0
        var providerAttemptCountByProvider: [String: Int] = [:]
        var providerAttemptCountByPort: [String: Int] = [:]
        var suppressedByLLMToggleCount: Int = 0
        var fallbackOnlyCount: Int = 0
        var lastAttemptTimestamp: Date?
        var lastSuppressionReason: String?
        var lastSuppressionTimestamp: Date?

        mutating func recordProviderAttempt(portId: String, providerId: String) {
            providerAttemptCountTotal += 1
            providerAttemptCountByProvider[providerId, default: 0] += 1
            providerAttemptCountByPort[portId, default: 0] += 1
            lastAttemptTimestamp = Date()
        }

        mutating func recordSuppression(reason: String) {
            suppressedByLLMToggleCount += 1
            lastSuppressionReason = reason
            lastSuppressionTimestamp = Date()
        }

        mutating func recordFallbackOnly() {
            fallbackOnlyCount += 1
        }

        mutating func reset() {
            providerAttemptCountTotal = 0
            providerAttemptCountByProvider.removeAll()
            providerAttemptCountByPort.removeAll()
            suppressedByLLMToggleCount = 0
            fallbackOnlyCount = 0
            lastAttemptTimestamp = nil
            lastSuppressionReason = nil
            lastSuppressionTimestamp = nil
        }

        func exportJSON() -> String {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            encoder.dateEncodingStrategy = .iso8601

            guard let data = try? encoder.encode(self),
                  let json = String(data: data, encoding: .utf8)
            else {
                return "{\"error\": \"Failed to encode LLM counters\"}"
            }

            return json
        }
    }

    // MARK: - Per-Port Metrics

    public struct PortMetrics: Codable {
        let portName: String
        var bestProvider: String?
        var fallbackAvailable: Bool
        var lastLatencyMs: Double?
        var averageLatencyMs: Double
        var successRate: Double
        var totalRequests: Int
        var successfulRequests: Int
        var failedRequests: Int
        var fallbackRequests: Int
        var lastError: String?
        var lastErrorTime: Date?
        var recentReasonCodes: [String: Int] // Reason code frequency
        var recentOutcomes: [Bool]
        var latencySamples: [Double]
        var stickyReasonCodes: [String: Int]
        var suppressionDecision: SuppressionDecision?
        var consecutiveSuccessesUnderBudget: Int

        mutating func recordSuccess(latencyMs: Double, reasonCodes: [String], usedFallback: Bool, budgetMs: Double) {
            totalRequests += 1
            successfulRequests += 1
            if usedFallback {
                fallbackRequests += 1
            }

            lastLatencyMs = latencyMs
            averageLatencyMs = (averageLatencyMs * Double(totalRequests - 1) + latencyMs) / Double(totalRequests)
            successRate = Double(successfulRequests) / Double(totalRequests)
            if latencyMs <= budgetMs {
                consecutiveSuccessesUnderBudget += 1
            } else {
                consecutiveSuccessesUnderBudget = 0
            }
            recordOutcome(success: true, latencyMs: latencyMs)

            for code in reasonCodes {
                recentReasonCodes[code, default: 0] += 1
            }
        }

        mutating func recordFailure(error: String) {
            totalRequests += 1
            failedRequests += 1
            lastError = error
            lastErrorTime = Date()
            successRate = Double(successfulRequests) / Double(totalRequests)
            consecutiveSuccessesUnderBudget = 0
            recordOutcome(success: false, latencyMs: nil)
        }

        mutating func recordOutcome(success: Bool, latencyMs: Double?) {
            recentOutcomes.append(success)
            if recentOutcomes.count > 50 {
                recentOutcomes.removeFirst(recentOutcomes.count - 50)
            }

            if let latencyMs {
                latencySamples.append(latencyMs)
                if latencySamples.count > 50 {
                    latencySamples.removeFirst(latencySamples.count - 50)
                }
            }
        }

        func recentSuccessRate(minSamples: Int) -> Double? {
            guard recentOutcomes.count >= minSamples else { return nil }
            let successes = recentOutcomes.filter { $0 }.count
            return Double(successes) / Double(recentOutcomes.count)
        }

        func p95LatencyMs() -> Double? {
            guard !latencySamples.isEmpty else { return nil }
            let sorted = latencySamples.sorted()
            let index = Int(Double(sorted.count - 1) * 0.95)
            return sorted[index]
        }
    }

    // MARK: - Global Health

    struct HealthSnapshot: Codable {
        let timestamp: Date
        let portMetrics: [String: PortMetrics]
        let providerStatuses: [String: ProviderStatus]
        let systemHealth: SystemHealth
        let suppressionDecisions: [String: SuppressionDecision]

        struct ProviderStatus: Codable {
            let name: String
            let isAvailable: Bool
            let circuitBreakerState: String
            let consecutiveFailures: Int
            let lastSuccessTime: Date?
            let lastFailureTime: Date?
        }

        struct SystemHealth: Codable {
            let overallSuccessRate: Double
            let averageLatencyMs: Double
            let fallbackUsageRate: Double
            let activeCircuitBreakers: Int
        }

        func exportJSON() -> String {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            encoder.dateEncodingStrategy = .iso8601

            guard let data = try? encoder.encode(self),
                  let json = String(data: data, encoding: .utf8)
            else {
                return "{\"error\": \"Failed to encode health snapshot\"}"
            }

            return json
        }
    }

    // MARK: - Monitor State

    private var portMetrics: [String: PortMetrics] = [:]
    private var llmCounters = LLMProviderCounters()
    private let lock = NSLock()
    private var suppressionDecisions: [String: SuppressionDecision] = [:]

    private let successRateThreshold = 0.8
    private let successRateSampleSize = 20
    private let defaultLatencyBudgetMs = 800.0
    private let successStreakToUnsuppress = 5
    private let suppressionDurationMinutes = 60

    // MARK: - Recording

    mutating func recordPortRequest(
        portName: String,
        provider: String?,
        latencyMs: Double,
        success: Bool,
        usedFallback: Bool,
        reasonCodes: [String],
        error: String? = nil
    ) {
        lock.lock()
        defer { lock.unlock() }

        if portMetrics[portName] == nil {
            portMetrics[portName] = PortMetrics(
                portName: portName,
                bestProvider: provider,
                fallbackAvailable: true,
                lastLatencyMs: nil,
                averageLatencyMs: 0,
                successRate: 0,
                totalRequests: 0,
                successfulRequests: 0,
                failedRequests: 0,
                fallbackRequests: 0,
                lastError: nil,
                lastErrorTime: nil,
                recentReasonCodes: [:],
                recentOutcomes: [],
                latencySamples: [],
                stickyReasonCodes: [:],
                suppressionDecision: nil,
                consecutiveSuccessesUnderBudget: 0
            )
        }

        let budgetMs = latencyBudgetMs(for: portName)
        if success {
            portMetrics[portName]?.recordSuccess(
                latencyMs: latencyMs,
                reasonCodes: reasonCodes,
                usedFallback: usedFallback,
                budgetMs: budgetMs
            )
        } else if let error {
            portMetrics[portName]?.recordFailure(error: error)
        }

        updateSuppressionDecision(for: portName)
    }

    func getMetrics(for portName: String) -> PortMetrics? {
        lock.lock()
        defer { lock.unlock() }
        return portMetrics[portName]
    }

    func getAllMetrics() -> [String: PortMetrics] {
        lock.lock()
        defer { lock.unlock() }
        return portMetrics
    }

    // MARK: - LLM Provider Attempt Tracking

    /// Record a provider attempt (increment counters)
    mutating func recordLLMProviderAttempt(portId: String, providerId: String) {
        lock.lock()
        defer { lock.unlock() }
        llmCounters.recordProviderAttempt(portId: portId, providerId: providerId)
    }

    /// Record suppression due to toggle being OFF
    mutating func recordLLMSuppression(reason: String) {
        lock.lock()
        defer { lock.unlock() }
        llmCounters.recordSuppression(reason: reason)
    }

    /// Record fallback-only execution (no provider attempt)
    mutating func recordFallbackOnly() {
        lock.lock()
        defer { lock.unlock() }
        llmCounters.recordFallbackOnly()
    }

    /// Get current LLM counters (for dev UI)
    func getLLMCounters() -> LLMProviderCounters {
        lock.lock()
        defer { lock.unlock() }
        return llmCounters
    }

    /// Reset LLM counters (dev-only action)
    mutating func resetLLMCounters() {
        lock.lock()
        defer { lock.unlock() }
        llmCounters.reset()
    }

    mutating func getSuppressionDecision(for portName: String) -> SuppressionDecision? {
        lock.lock()
        defer { lock.unlock() }

        if let decision = suppressionDecisions[portName], !decision.isExpired(at: Date()) {
            return decision
        }

        suppressionDecisions[portName] = nil
        return nil
    }

    // MARK: - Health Snapshot

    func captureSnapshot(
        engine _: AIEngine,
        providers _: [String: Any] = [:]
    ) -> HealthSnapshot {
        lock.lock()
        defer { lock.unlock() }

        // Calculate system-wide metrics
        let totalRequests = portMetrics.values.reduce(0) { $0 + $1.totalRequests }
        let successfulRequests = portMetrics.values.reduce(0) { $0 + $1.successfulRequests }
        let fallbackRequests = portMetrics.values.reduce(0) { $0 + $1.fallbackRequests }
        let totalLatency = portMetrics.values.reduce(0.0) { $0 + ($1.averageLatencyMs * Double($1.totalRequests)) }

        let overallSuccessRate = totalRequests > 0 ? Double(successfulRequests) / Double(totalRequests) : 1.0
        let averageLatencyMs = totalRequests > 0 ? totalLatency / Double(totalRequests) : 0
        let fallbackUsageRate = totalRequests > 0 ? Double(fallbackRequests) / Double(totalRequests) : 0

        let systemHealth = HealthSnapshot.SystemHealth(
            overallSuccessRate: overallSuccessRate,
            averageLatencyMs: averageLatencyMs,
            fallbackUsageRate: fallbackUsageRate,
            activeCircuitBreakers: 0 // Deferred: circuit breaker tracking
        )

        // Provider statuses (placeholder - would need actual provider state)
        let providerStatuses: [String: HealthSnapshot.ProviderStatus] = [:]

        return HealthSnapshot(
            timestamp: Date(),
            portMetrics: portMetrics,
            providerStatuses: providerStatuses,
            systemHealth: systemHealth,
            suppressionDecisions: suppressionDecisions.filter { !$0.value.isExpired(at: Date()) }
        )
    }

    // MARK: - Alerts

    struct HealthAlert {
        enum Severity {
            case info, warning, critical
        }

        let severity: Severity
        let portName: String
        let message: String
        let timestamp: Date
    }

    func generateAlerts() -> [HealthAlert] {
        lock.lock()
        defer { lock.unlock() }

        var alerts: [HealthAlert] = []

        for (name, metrics) in portMetrics {
            // Alert: Low success rate
            if metrics.successRate < 0.8 && metrics.totalRequests > 10 {
                alerts.append(HealthAlert(
                    severity: .warning,
                    portName: name,
                    message: "Success rate below 80%: \(String(format: "%.1f%%", metrics.successRate * 100))",
                    timestamp: Date()
                ))
            }

            // Alert: High latency
            if let latency = metrics.lastLatencyMs, latency > 1000 {
                alerts.append(HealthAlert(
                    severity: .warning,
                    portName: name,
                    message: "High latency: \(Int(latency))ms",
                    timestamp: Date()
                ))
            }

            // Alert: Recent errors
            if let lastErrorTime = metrics.lastErrorTime,
               Date().timeIntervalSince(lastErrorTime) < 60
            {
                alerts.append(HealthAlert(
                    severity: .critical,
                    portName: name,
                    message: "Recent error: \(metrics.lastError ?? "Unknown")",
                    timestamp: lastErrorTime
                ))
            }

            // Alert: High fallback usage
            let fallbackRate = Double(metrics.fallbackRequests) / Double(metrics.totalRequests)
            if fallbackRate > 0.5 && metrics.totalRequests > 10 {
                alerts.append(HealthAlert(
                    severity: .info,
                    portName: name,
                    message: "High fallback usage: \(String(format: "%.1f%%", fallbackRate * 100))",
                    timestamp: Date()
                ))
            }
        }

        return alerts
    }

    // MARK: - Suppression Decisions

    struct SuppressionDecision: Codable {
        enum Mode: String, Codable {
            case preferFallback
            case skipProvider
        }

        let mode: Mode
        let reasonCodes: [String]
        let decidedAt: Date
        let expiresAt: Date?

        func isExpired(at date: Date) -> Bool {
            guard let expiresAt else { return false }
            return date >= expiresAt
        }
    }

    private mutating func updateSuppressionDecision(for portName: String) {
        guard var metrics = portMetrics[portName] else { return }
        let budgetMs = latencyBudgetMs(for: portName)

        if metrics.consecutiveSuccessesUnderBudget >= successStreakToUnsuppress {
            suppressionDecisions[portName] = nil
            metrics.suppressionDecision = nil
        }

        if let recentRate = metrics.recentSuccessRate(minSamples: successRateSampleSize),
           recentRate < successRateThreshold
        {
            let decision = SuppressionDecision(
                mode: .preferFallback,
                reasonCodes: ["success_rate_below_threshold"],
                decidedAt: Date(),
                expiresAt: Calendar.current.date(byAdding: .minute, value: suppressionDurationMinutes, to: Date())
            )
            suppressionDecisions[portName] = decision
            metrics.suppressionDecision = decision
            metrics.stickyReasonCodes["success_rate_below_threshold", default: 0] += 1
        }

        if let p95 = metrics.p95LatencyMs(), p95 > budgetMs {
            let decision = SuppressionDecision(
                mode: .skipProvider,
                reasonCodes: ["latency_p95_exceeded"],
                decidedAt: Date(),
                expiresAt: Calendar.current.date(byAdding: .minute, value: suppressionDurationMinutes, to: Date())
            )
            suppressionDecisions[portName] = decision
            metrics.suppressionDecision = decision
            metrics.stickyReasonCodes["latency_p95_exceeded", default: 0] += 1
        }

        portMetrics[portName] = metrics
    }

    private func latencyBudgetMs(for portName: String) -> Double {
        guard let portID = AIPortID(rawValue: portName) else {
            return defaultLatencyBudgetMs
        }
        switch portID {
        case .estimateTaskDuration:
            return 200
        case .generateStudyPlan, .schedulePlacement, .conflictResolution:
            return 300
        case .documentIngest, .academicEntityExtract, .assignmentCreation, .workloadForecast:
            return defaultLatencyBudgetMs
        }
    }
}

// MARK: - Thread-Safe Wrapper for Actor-Compatible Access

/// Thread-safe wrapper for AIHealthMonitor (since it's a struct with mutating methods)
public actor AIHealthMonitorWrapper {
    private var monitor = AIHealthMonitor()

    public init() {}

    public func recordLLMProviderAttempt(portId: String, providerId: String) {
        monitor.recordLLMProviderAttempt(portId: portId, providerId: providerId)
    }

    public func recordLLMSuppression(reason: String) {
        monitor.recordLLMSuppression(reason: reason)
    }

    public func recordFallbackOnly() {
        monitor.recordFallbackOnly()
    }

    public func getLLMCounters() -> AIHealthMonitor.LLMProviderCounters {
        monitor.getLLMCounters()
    }

    public func resetLLMCounters() {
        monitor.resetLLMCounters()
    }

    public func recordPortRequest(
        portName: String,
        provider: String?,
        latencyMs: Double,
        success: Bool,
        usedFallback: Bool,
        reasonCodes: [String],
        error: String? = nil
    ) {
        monitor.recordPortRequest(
            portName: portName,
            provider: provider,
            latencyMs: latencyMs,
            success: success,
            usedFallback: usedFallback,
            reasonCodes: reasonCodes,
            error: error
        )
    }

    public func getMetrics(for portName: String) -> AIHealthMonitor.PortMetrics? {
        monitor.getMetrics(for: portName)
    }

    public func getAllMetrics() -> [String: AIHealthMonitor.PortMetrics] {
        monitor.getAllMetrics()
    }
}

// MARK: - Shared Monitor Instance
