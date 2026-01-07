import Foundation
import OSLog

fileprivate let aiLogger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "AIEngine", category: "AIEngine")

public final class AIEngine: Sendable {
    public static let shared = AIEngine()
    
    // MARK: - LLM Provider Attempt Tracking (Dev-Only)
    public static var healthMonitor = AIHealthMonitor()
    public static let auditLog = AIAuditLog()

    private let registry: AIPortRegistry
    private let providers: [AIEngineProvider]
    private let fallback: AIFallbackEngine
    private let privacyPolicy: AIPrivacyPolicy
    private let rateLimit: AIRateLimitPolicy
    private let capabilityPolicy: AICapabilityPolicy
    private let providerReliability = ProviderReliability()
    private let redactionPolicy = AIRedactionPolicy()
    private let determinismLock = NSLock()
    private var fallbackDeterminismCache: [String: String] = [:]

    public init(
        registry: AIPortRegistry? = nil,
        providers: [AIEngineProvider] = [],
        fallback: AIFallbackEngine = NoOpFallbackEngine(),
        privacyPolicy: AIPrivacyPolicy = DefaultPrivacyPolicy(),
        rateLimit: AIRateLimitPolicy = DefaultRateLimitPolicy(),
        capabilityPolicy: AICapabilityPolicy = DefaultCapabilityPolicy()
    ) {
        self.providers = providers
        self.fallback = fallback
        self.privacyPolicy = privacyPolicy
        self.rateLimit = rateLimit
        self.capabilityPolicy = capabilityPolicy
        self.registry = registry ?? AIPortRegistry(
            providers: providers,
            fallback: fallback,
            privacyPolicy: privacyPolicy,
            capabilityPolicy: capabilityPolicy
        )
    }

    @MainActor
    public func request<P: AIPort>(
        _ portType: P.Type,
        input: P.Input
    ) async throws -> AIResult<P.Output> {
        let context = await MainActor.run { AIRequestContext() }
        return try await request(portType, input: input, context: context)
    }

    public func request<P: AIPort>(
        _ portType: P.Type,
        input: P.Input,
        context: AIRequestContext
    ) async throws -> AIResult<P.Output> {
        // Enforce integration pattern
        guard AIIntegrationEnforcement.validateCaller() else {
            AIIntegrationEnforcement.reportViolation("Unauthorized AI integration attempt")
            throw AIEngineError.policyDenied(reason: "unauthorizedCaller")
        }
        return try await _executeWithGuards(portType: portType, input: input, context: context)
    }

    public func resetProviderState() {
        providerReliability.resetAll()
        determinismLock.lock()
        fallbackDeterminismCache.removeAll()
        determinismLock.unlock()
    }
    
    private enum ExecutionStrategy {
        case fallbackFirst  // For realtime ports
        case providerFirst  // For batch ports
    }

    private func _executeWithGuards<P: AIPort>(
        portType: P.Type,
        input: P.Input,
        context: AIRequestContext
    ) async throws -> AIResult<P.Output> {
        /// ═══════════════════════════════════════════════════════════════════════════════
        /// CRITICAL SYSTEM INVARIANT (Documented in Docs/Architecture/LLM_ENFORCEMENT_INVARIANT.md)
        ///
        /// IF enableLLMAssistance == false
        /// THEN providerAttemptCountTotal MUST == 0
        ///
        /// This is the ONLY enforcement point. Any violation is a critical bug.
        /// This kill-switch guarantees:
        /// - No provider execute() calls
        /// - No network requests to LLM services
        /// - Only deterministic fallbacks may run
        ///
        /// Protected by:
        /// - CI-blocking tests (Tests/LLMToggleEnforcementTests.swift)
        /// - DEBUG-only canary assertion (below)
        /// - Health monitor counters (HealthMonitor.swift)
        /// - Audit log provenance (AIAuditLog.swift)
        /// ═══════════════════════════════════════════════════════════════════════════════
        
        // CRITICAL: Single Kill-Switch Gate for LLM Toggle Enforcement
        // If enableLLMAssistance is OFF, skip all provider logic and use fallback only
        if !AppSettingsModel.shared.enableLLMAssistance {
            // Developer Mode: Log LLM suppression
            aiLogger.info("LLM | 🚫 LLM assistance disabled - using fallback only | port=\(P.id.rawValue) trigger=\(context.requestID.uuidString) reason=user_setting_disabled")
            
            let inputHash = try Self.computeInputHash(
                for: input,
                excludedKeys: P.inputHashExcludedKeys,
                unorderedArrayKeys: P.unorderedArrayKeys
            )

            AIEngine.healthMonitor.recordLLMSuppression(reason: "llm_toggle_disabled")
            await AIEngine.auditLog.log(AIAuditEntry(
                timestamp: Date(),
                requestID: context.requestID,
                portID: P.id.rawValue,
                providerID: nil,
                eventType: .suppressed,
                reasonCode: .llmDisabled,
                fallbackUsed: true,
                latencyMs: 0,
                success: true,
                inputHash: inputHash
            ))

            // Execute fallback-only path (no provider selection, no network)
            guard P.supportsDeterministicFallback && fallback.canFallback(for: P.id) else {
                aiLogger.error("LLM | ❌ No fallback available for port | port=\(P.id.rawValue) supportsFallback=\(String(describing: P.supportsDeterministicFallback))")
                throw AIEngineError.policyDenied(reason: "llm_disabled_no_fallback:\(P.id.rawValue)")
            }

            AIEngine.healthMonitor.recordFallbackOnly()
            
            let fallbackStart = Date()
            var result = try await fallback.executeFallback(P.self, input: input, context: context)
            let fallbackDuration = Date().timeIntervalSince(fallbackStart)
            
            aiLogger.debug("LLM | Fallback completed (LLM disabled) | port=\(P.id.rawValue) duration=\(String(format: "%.3fs", fallbackDuration))")
            
            result = result.withMetadata(
                AIResultMetadata(
                    inputHash: inputHash,
                    computedAt: Date(),
                    computedAtUptime: ProcessInfo.processInfo.systemUptime,
                    featureStateVersion: context.featureStateVersion
                )
            )
            result = enforceDeterministicFallback(
                result: result,
                port: P.id,
                inputHash: inputHash,
                portType: P.self
            )
            return result.addingReasonCodes(["llm_disabled", "fallback_only"])
        }
        
        guard capabilityPolicy.isPortEnabled(P.id) else {
            throw AIEngineError.policyDenied(reason: "portDisabled:\(P.id.rawValue)")
        }
        guard rateLimit.allows(port: P.id) else {
            throw AIEngineError.policyDenied(reason: "rateLimited:\(P.id.rawValue)")
        }

        try P.validate(input: input)

        let inputEncoder = JSONEncoder()
        inputEncoder.outputFormatting = [.sortedKeys]
        let rawInput = try inputEncoder.encode(input)
        let inputHash = AIInputHasher.hash(
            inputJSON: rawInput,
            excludedKeys: P.inputHashExcludedKeys,
            unorderedArrayKeys: P.unorderedArrayKeys
        )
        let privacyRedacted = try privacyPolicy.redactIfNeeded(inputJSON: rawInput, privacy: context.privacy)

#if DEBUG
        AIEngine.replayStore.recordInput(port: P.id, inputJSON: rawInput, inputHash: inputHash)
#endif

        let executionStrategy = determineStrategy(for: P.self, context: context)

        var result: AIResult<P.Output>
        var usedFallback = false
        var validationFailed = false
        var redactionDelta = 0.0

        switch executionStrategy {
        case .fallbackFirst:
            result = try await executeFallbackFirst(
                portType: P.self,
                input: input,
                context: context,
                inputHash: inputHash,
                usedFallback: &usedFallback
            )

        case .providerFirst:
            do {
                result = try await executeProviderFirst(
                    portType: P.self,
                    input: input,
                    context: context,
                    inputHash: inputHash,
                    privacyRedacted: privacyRedacted,
                    redactionDelta: &redactionDelta,
                    validationFailed: &validationFailed
                )
            } catch {
                if P.supportsDeterministicFallback && fallback.canFallback(for: P.id) {
                    usedFallback = true
                    let fallbackResult = try await fallback.executeFallback(P.self, input: input, context: context)
                    result = fallbackResult.withMetadata(
                        AIResultMetadata(
                            inputHash: inputHash,
                            computedAt: Date(),
                            computedAtUptime: ProcessInfo.processInfo.systemUptime,
                            featureStateVersion: context.featureStateVersion
                        )
                    )
                    result = enforceDeterministicFallback(
                        result: result,
                        port: P.id,
                        inputHash: inputHash,
                        portType: P.self
                    )
                    if error is TimeBudgetError {
                        result = result.addingReasonCodes(["timeout_fallback"])
                    } else {
                        result = result.addingReasonCodes(["provider_failed_fallback"])
                    }
                } else {
                    AIEngine.healthMonitor.recordPortRequest(
                        portName: P.id.rawValue,
                        provider: nil,
                        latencyMs: 0,
                        success: false,
                        usedFallback: false,
                        reasonCodes: [],
                        error: error.localizedDescription
                    )
                    throw error
                }
            }
        }

        do {
            try validateInvariants(port: P.self, input: input, output: result.output, result: result)
        } catch {
            validationFailed = true
            throw error
        }

        await AIRegressionMonitor.shared.recordExecution(
            port: P.id,
            usedFallback: usedFallback,
            latencyMs: result.diagnostic.latencyMs ?? 0,
            validationFailed: validationFailed,
            redactionDelta: redactionDelta
        )

        AIEngine.healthMonitor.recordPortRequest(
            portName: P.id.rawValue,
            provider: result.provenance.primaryProvider.rawValue,
            latencyMs: Double(result.diagnostic.latencyMs ?? 0),
            success: true,
            usedFallback: usedFallback,
            reasonCodes: result.diagnostic.reasonCodes
        )

        return result
    }
    
    private func determineStrategy<P: AIPort>(for portType: P.Type, context: AIRequestContext) -> ExecutionStrategy {
        if let suppression = AIEngine.healthMonitor.getSuppressionDecision(for: P.id.rawValue) {
            if suppression.mode == .preferFallback || suppression.mode == .skipProvider {
                return .fallbackFirst
            }
        }
        
        // Realtime ports should use fallback first for instant response
        let realtimePorts: Set<AIPortID> = [
            .estimateTaskDuration,
            .generateStudyPlan,
            .schedulePlacement,
            .conflictResolution
        ]
        
        if realtimePorts.contains(P.id) {
            return .fallbackFirst
        }
        
        return .providerFirst
    }
    
    private func executeFallbackFirst<P: AIPort>(
        portType: P.Type,
        input: P.Input,
        context: AIRequestContext,
        inputHash: String,
        usedFallback: inout Bool
    ) async throws -> AIResult<P.Output> {
        // Use fallback immediately
        usedFallback = true
        
        // Developer Mode: Log fallback execution
        aiLogger.info("LLM | 🔄 Using deterministic fallback (no LLM) | port=\(P.id.rawValue) reason=fallback-first strategy trigger=\(context.requestID.uuidString)")
        
        let fallbackStart = Date()
        let result = try await fallback.executeFallback(P.self, input: input, context: context)
        let fallbackDuration = Date().timeIntervalSince(fallbackStart)
        
        aiLogger.debug("LLM | Fallback completed | port=\(P.id.rawValue) duration=\(String(format: "%.3fs", fallbackDuration)) deterministic=true")
        
        // Optionally enhance with provider in background (not implemented yet)
        // This would update future defaults without blocking current response
        
        let withMetadata = result.withMetadata(
            AIResultMetadata(
                inputHash: inputHash,
                computedAt: Date(),
                computedAtUptime: ProcessInfo.processInfo.systemUptime,
                featureStateVersion: context.featureStateVersion
            )
        )
        return enforceDeterministicFallback(
            result: withMetadata,
            port: P.id,
            inputHash: inputHash,
            portType: P.self
        )
    }
    
    private func executeProviderFirst<P: AIPort>(
        portType: P.Type,
        input: P.Input,
        context: AIRequestContext,
        inputHash: String,
        privacyRedacted: Data,
        redactionDelta: inout Double,
        validationFailed: inout Bool
    ) async throws -> AIResult<P.Output> {
        let preference = P.preferredProviders
        let orderedProviders = providers.sorted {
            (preference.firstIndex(of: $0.id) ?? preference.count) <
            (preference.firstIndex(of: $1.id) ?? preference.count)
        }
        let viableProviders = orderedProviders
            .filter { $0.isAvailable() && $0.supports(port: P.id) }
            .filter { privacyPolicy.allows(provider: $0.id, for: context.privacy) }
            .filter { providerReliability.canUseProvider($0.id.rawValue) }

        guard let provider = viableProviders.first else {
            throw AIEngineError.capabilityUnavailable(port: P.id)
        }
        
        // CRITICAL: Record provider attempt (for LLM toggle enforcement tracking)
        AIEngine.healthMonitor.recordLLMProviderAttempt(
            portId: P.id.rawValue,
            providerId: provider.id.rawValue
        )
        
        // Log audit event for provider attempt
        let requestID = UUID()
        await AIEngine.auditLog.log(AIAuditEntry(
            timestamp: Date(),
            requestID: requestID,
            portID: P.id.rawValue,
            providerID: provider.id.rawValue,
            eventType: .providerAttempt,
            reasonCode: nil,
            fallbackUsed: false,
            latencyMs: 0,
            success: true,
            inputHash: inputHash
        ))
        
        let finalInput = try applyRedaction(
            inputJSON: privacyRedacted,
            port: P.id,
            provider: provider.id,
            privacy: context.privacy
        )
        redactionDelta = Double(privacyRedacted.count - finalInput.count) / Double(max(privacyRedacted.count, 1))

        let start = Date()
        let budget = timeBudget(for: P.id)
        let (outJSON, diag): (Data, AIDiagnostic)
        do {
            #if DEBUG
            // CANARY: Runtime invariant check (DEBUG-only)
            // This should NEVER fire if _executeWithGuards properly enforces the kill-switch
            if !AppSettingsModel.shared.enableLLMAssistance {
                let counters = AIEngine.healthMonitor.getLLMCounters()
                assertionFailure("""
                    ═══════════════════════════════════════════════════════════════
                    CRITICAL INVARIANT VIOLATION DETECTED
                    ═══════════════════════════════════════════════════════════════
                    
                    LLM toggle is OFF but provider.execute() is being called!
                    
                    This is a critical bug in AIEngine._executeWithGuards.
                    The kill-switch gate failed to prevent provider execution.
                    
                    Current State:
                    - enableLLMAssistance: false (SHOULD BLOCK PROVIDERS)
                    - providerAttemptCountTotal: \(counters.providerAttemptCountTotal)
                    - Provider: \(provider.id.rawValue)
                    - Port: \(P.id.rawValue)
                    
                    Action Required:
                    1. DO NOT SHIP THIS BUILD
                    2. Review AIEngine._executeWithGuards (lines ~67-117)
                    3. Verify toggle check happens BEFORE provider selection
                    4. Run LLMToggleEnforcementTests to reproduce
                    
                    See: Docs/Architecture/LLM_ENFORCEMENT_INVARIANT.md
                    ═══════════════════════════════════════════════════════════════
                    """)
            }
            #endif
            
            // Developer Mode: Log LLM execution start
            aiLogger.info("LLM | 🤖 Starting LLM request | provider=\(provider.id.rawValue) port=\(P.id.rawValue) trigger=\(context.requestID.uuidString) privacy=\(String(describing: context.privacy)) inputSize=\(finalInput.count) bytes timestamp=\(String(describing: Date()))")
            
            (outJSON, diag) = try await budget.execute {
                try await provider.execute(port: P.id, inputJSON: finalInput, context: context)
            }
            
            let executionDuration = Date().timeIntervalSince(start)
            
            // Developer Mode: Log LLM execution completion  
            aiLogger.info("LLM | ✅ LLM request completed | provider=\(provider.id.rawValue) port=\(P.id.rawValue) duration=\(String(format: "%.3fs", executionDuration)) outputSize=\(outJSON.count) bytes latency=\(diag.latencyMs.map { "\($0)ms" } ?? "unknown") reasonCodes=\(diag.reasonCodes.joined(separator: ", ")) success=true")
            
            // Developer Mode: Log output preview (first 200 chars)
            if let outputString = String(data: outJSON, encoding: .utf8) {
                let preview = String(outputString.prefix(200))
                aiLogger.debug("LLM | Output preview | provider=\(provider.id.rawValue) preview=\(preview + (outputString.count > 200 ? "..." : ""))")
            }
        } catch {
            let executionDuration = Date().timeIntervalSince(start)
            
            // Developer Mode: Log LLM execution failure
            aiLogger.error("LLM | ❌ LLM request failed | provider=\(provider.id.rawValue) port=\(P.id.rawValue) duration=\(String(format: "%.3fs", executionDuration)) error=\(String(describing: error)) willRetry=false")
            
            providerReliability.recordProviderFailure(provider.id.rawValue)
            throw error
        }
        let latency = Int(Date().timeIntervalSince(start) * 1000)

        let output = try JSONDecoder().decode(P.Output.self, from: outJSON)
        
        do {
            try P.validate(output: output)
        } catch {
            validationFailed = true
            throw error
        }

        var notes = diag.notes
        notes["inputHash"] = inputHash
        notes["redactionDelta"] = String(format: "%.2f", redactionDelta)
        
        let mergedDiag = AIDiagnostic(
            reasonCodes: diag.reasonCodes,
            latencyMs: latency,
            notes: notes
        )

        providerReliability.recordProviderSuccess(provider.id.rawValue)

        return AIResult(
            output: output,
            confidence: AIConfidence(0.75),
            provenance: .provider(provider.id),
            diagnostic: mergedDiag,
            metadata: AIResultMetadata(
                inputHash: inputHash,
                computedAt: Date(),
                computedAtUptime: ProcessInfo.processInfo.systemUptime,
                featureStateVersion: context.featureStateVersion
            )
        )
    }

    public func capabilitySnapshot() -> [AIPortAvailability] {
        registry.snapshot()
    }

    private func timeBudget(for port: AIPortID) -> TimeBudget {
        switch port {
        case .estimateTaskDuration:
            return TimeBudget(budget: TimeBudget.estimate, portName: port.rawValue)
        case .workloadForecast:
            return TimeBudget(budget: TimeBudget.forecast, portName: port.rawValue)
        case .generateStudyPlan, .schedulePlacement, .conflictResolution:
            return TimeBudget(budget: TimeBudget.schedule, portName: port.rawValue)
        case .documentIngest, .academicEntityExtract:
            return TimeBudget(budget: TimeBudget.parse, portName: port.rawValue)
        case .assignmentCreation:
            return TimeBudget(budget: TimeBudget.decompose, portName: port.rawValue)
        }
    }

    private func applyRedaction(
        inputJSON: Data,
        port: AIPortID,
        provider: AIProviderID,
        privacy: AIPrivacyLevel
    ) throws -> Data {
        guard redactionPolicy.shouldRedact(for: port, providerID: provider) else {
            return inputJSON
        }
        let level = redactionPolicy.redactionLevel(for: port, privacy: privacy)
        let redactor = AIRedactor(level: level)
        return try AIRedactionTransformer.redactJSONStrings(inputJSON, using: redactor)
    }

    private func enforceDeterministicFallback<P: AIPort>(
        result: AIResult<P.Output>,
        port: AIPortID,
        inputHash: String,
        portType: P.Type
    ) -> AIResult<P.Output> {
        let outputHash = stableOutputHash(result.output)
        let cacheKey = "\(port.rawValue)|\(inputHash)"
        determinismLock.lock()
        defer { determinismLock.unlock() }
        if let existing = fallbackDeterminismCache[cacheKey], existing != outputHash {
            let diag = AIDiagnostic(
                reasonCodes: result.diagnostic.reasonCodes + ["nonDeterministicFallback"],
                latencyMs: result.diagnostic.latencyMs ?? 0,
                notes: result.diagnostic.notes
            )
            return AIResult(
                output: result.output,
                confidence: result.confidence,
                provenance: result.provenance,
                diagnostic: diag,
                metadata: result.metadata
            )
        }
        fallbackDeterminismCache[cacheKey] = outputHash
        return result
    }

    private func stableOutputHash<T: Encodable>(_ output: T) -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        let data = (try? encoder.encode(output)) ?? Data()
        return data.sha256Hash()
    }
}

extension AIEngine {
    static var replayStore = AIPortReplayStore.shared

    // Deferred: async AIHealthMonitorWrapper integration
    // func getHealthSnapshot() -> AIHealthMonitor.HealthSnapshot {
    //     AIEngine.healthMonitor.captureSnapshot(engine: self)
    // }

    // func exportHealthReport() -> String {
    //     getHealthSnapshot().exportJSON()
    // }
}

private extension AIEngine {
    // MARK: - Helper Methods for Kill-Switch Enforcement
    static func computeInputHash<T: Encodable>(
        for input: T,
        excludedKeys: Set<String> = [],
        unorderedArrayKeys: Set<String> = []
    ) throws -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        let rawInput = try encoder.encode(input)
        return AIInputHasher.hash(
            inputJSON: rawInput,
            excludedKeys: excludedKeys,
            unorderedArrayKeys: unorderedArrayKeys
        )
    }
}

#if DEBUG
extension AIEngine {
    @MainActor
    func replay<P: AIPort>(
        _ portType: P.Type,
        index: Int = 0
    ) async throws -> AIPortReplayResult? {
        let context = await MainActor.run { AIRequestContext() }
        return try await replay(portType, index: index, context: context)
    }

    func replay<P: AIPort>(
        _ portType: P.Type,
        index: Int = 0,
        context: AIRequestContext
    ) async throws -> AIPortReplayResult? {
        guard let record = AIEngine.replayStore.record(for: P.id, index: index) else {
            return nil
        }
        
        let input = try JSONDecoder().decode(P.Input.self, from: record.inputJSON)
        let redactedInput = try privacyPolicy.redactIfNeeded(inputJSON: record.inputJSON, privacy: context.privacy)
        
        var providerOutputJSON: String?
        var providerError: String?
        var providerID: AIProviderID?
        var fallbackOutputJSON: String?
        var fallbackError: String?
        
        if let provider = providers.first(where: { $0.isAvailable() && $0.supports(port: P.id) }) {
            providerID = provider.id
            do {
                #if DEBUG
                // CANARY: Debug replay path should also respect toggle
                if !AppSettingsModel.shared.enableLLMAssistance {
                    print("⚠️ WARNING: Replay mode called provider while toggle OFF (debug-only)")
                }
                #endif
                
                let (outJSON, _) = try await provider.execute(port: P.id, inputJSON: redactedInput, context: context)
                providerOutputJSON = String(data: outJSON, encoding: .utf8)
            } catch {
                providerError = error.localizedDescription
            }
        }
        
        if fallback.canFallback(for: P.id) {
            do {
                let fallbackResult = try await fallback.executeFallback(P.self, input: input, context: context)
                let encoded = try JSONEncoder().encode(fallbackResult.output)
                fallbackOutputJSON = String(data: encoded, encoding: .utf8)
            } catch {
                fallbackError = error.localizedDescription
            }
        }
        
        let outputsMatch: Bool?
        if let providerJSON = providerOutputJSON, let fallbackJSON = fallbackOutputJSON {
            outputsMatch = providerJSON == fallbackJSON
        } else {
            outputsMatch = nil
        }
        
        return AIPortReplayResult(
            port: P.id,
            inputHash: record.inputHash,
            providerID: providerID,
            providerOutputJSON: providerOutputJSON,
            providerError: providerError,
            fallbackOutputJSON: fallbackOutputJSON,
            fallbackError: fallbackError,
            outputsMatch: outputsMatch,
            timestamp: record.timestamp
        )
    }
    
}
#endif

private extension AIResult {
    func addingReasonCodes(_ newCodes: [String]) -> AIResult<Output> {
        let mergedCodes = diagnostic.reasonCodes + newCodes
        let mergedDiag = AIDiagnostic(
            reasonCodes: mergedCodes,
            latencyMs: diagnostic.latencyMs,
            notes: diagnostic.notes
        )
        return AIResult(
            output: output,
            confidence: confidence,
            provenance: provenance,
            diagnostic: mergedDiag,
            metadata: metadata
        )
    }
}
