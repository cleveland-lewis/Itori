import Foundation

public final class AIEngine: Sendable {
    public static let shared = AIEngine()

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

    public func request<P: AIPort>(
        _ portType: P.Type,
        input: P.Input,
        context: AIRequestContext = .init()
    ) async throws -> AIResult<P.Output> {
        // Enforce integration pattern
        guard AIIntegrationEnforcement.validateCaller() else {
            AIIntegrationEnforcement.reportViolation("Unauthorized AI integration attempt")
            throw AIEngineError.policyDenied(reason: "unauthorizedCaller")
        }
        return try await _executeWithGuards(portType: portType, input: input, context: context)
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
                &usedFallback
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
                    &validationFailed
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
        _ usedFallback: inout Bool
    ) async throws -> AIResult<P.Output> {
        // Use fallback immediately
        usedFallback = true
        let result = try await fallback.executeFallback(P.self, input: input, context: context)
        
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
        _ validationFailed: inout Bool
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
            (outJSON, diag) = try await budget.execute {
                try await provider.execute(port: P.id, inputJSON: finalInput, context: context)
            }
        } catch {
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
    static var healthMonitor = AIHealthMonitor()
    static var replayStore = AIPortReplayStore.shared

    func getHealthSnapshot() -> AIHealthMonitor.HealthSnapshot {
        AIEngine.healthMonitor.captureSnapshot(engine: self)
    }

    func exportHealthReport() -> String {
        getHealthSnapshot().exportJSON()
    }
}

#if DEBUG
extension AIEngine {
    func replay<P: AIPort>(
        _ portType: P.Type,
        index: Int = 0,
        context: AIRequestContext = .init()
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
