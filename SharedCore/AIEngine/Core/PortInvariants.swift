import Foundation

// MARK: - Port Invariants

/// Defines and enforces invariants that every port must satisfy
public enum PortInvariants {
    private static var fallbackOutputHashes: [String: String] = [:]
    private static let fallbackLock = NSLock()

    /// Validates that output satisfies all invariants
    public static func validate<P: AIPort>(
        port: P.Type,
        input: P.Input,
        output: P.Output,
        result: AIResult<P.Output>
    ) throws {
        // 1. Output must be schema-valid (already checked by JSONDecoder)

        // 2. Output must be bounded (no invalid values)
        try validateBounded(output: output, port: port)

        // 3. Output must be monotonic where expected
        try validateMonotonic(output: output, port: port)

        // 4. Output must include reasonCodes for low confidence
        try validateReasonCodes(result: result)

        // 5. Output must be idempotent for same input when using fallback
        try validateIdempotent(port: port, input: input, output: output, provenance: result.provenance)
    }

    // MARK: - Bounded Validation

    private static func validateBounded(output: some Any, port _: any AIPort.Type) throws {
        let mirror = Mirror(reflecting: output)

        for child in mirror.children {
            guard let label = child.label else { continue }

            // Check numeric bounds
            if let minutes = child.value as? Int, label.contains("minutes") || label.contains("Minutes") {
                guard minutes >= 0 && minutes <= 10080 else { // 0 to 1 week
                    throw PortInvariantViolation.boundViolation(
                        field: label,
                        value: String(minutes),
                        constraint: "0 <= minutes <= 10080"
                    )
                }
            }

            // Check date bounds
            if let date = child.value as? Date {
                let now = Date()
                let tenYears = now.addingTimeInterval(10 * 365 * 24 * 3600)
                let hundredYearsAgo = now.addingTimeInterval(-100 * 365 * 24 * 3600)

                guard date >= hundredYearsAgo && date <= tenYears else {
                    throw PortInvariantViolation.boundViolation(
                        field: label,
                        value: date.description,
                        constraint: "within 100 years past to 10 years future"
                    )
                }
            }

            // Check confidence bounds
            if let confidence = child.value as? AIConfidence {
                guard confidence.value >= 0 && confidence.value <= 1 else {
                    throw PortInvariantViolation.boundViolation(
                        field: label,
                        value: String(confidence.value),
                        constraint: "0.0 <= confidence <= 1.0"
                    )
                }
            }
        }
    }

    // MARK: - Monotonic Validation

    private static func validateMonotonic(output: some Any, port _: any AIPort.Type) throws {
        let mirror = Mirror(reflecting: output)
        var minValue: Int?
        var estValue: Int?
        var maxValue: Int?

        for child in mirror.children {
            guard let label = child.label else { continue }

            if label.contains("min") && label.contains("Minutes"), let value = child.value as? Int {
                minValue = value
            } else if label.contains("estimated") && label.contains("Minutes"), let value = child.value as? Int {
                estValue = value
            } else if label.contains("max") && label.contains("Minutes"), let value = child.value as? Int {
                maxValue = value
            }
        }

        // Check monotonicity: min <= est <= max
        if let min = minValue, let est = estValue {
            guard min <= est else {
                throw PortInvariantViolation.monotonicViolation(
                    relation: "minMinutes <= estimatedMinutes",
                    actual: "\(min) > \(est)"
                )
            }
        }

        if let est = estValue, let max = maxValue {
            guard est <= max else {
                throw PortInvariantViolation.monotonicViolation(
                    relation: "estimatedMinutes <= maxMinutes",
                    actual: "\(est) > \(max)"
                )
            }
        }

        if let min = minValue, let max = maxValue {
            guard min <= max else {
                throw PortInvariantViolation.monotonicViolation(
                    relation: "minMinutes <= maxMinutes",
                    actual: "\(min) > \(max)"
                )
            }
        }
    }

    // MARK: - Reason Codes Validation

    private static func validateReasonCodes(result: AIResult<some Any>) throws {
        let confidenceThreshold = 0.6

        if result.confidence.value < confidenceThreshold {
            guard !result.diagnostic.reasonCodes.isEmpty else {
                throw PortInvariantViolation.missingReasonCodes(
                    confidence: result.confidence.value,
                    threshold: confidenceThreshold
                )
            }
        }
    }

    // MARK: - Idempotency Validation

    private static func validateIdempotent<P: AIPort>(
        port: P.Type,
        input: P.Input,
        output: P.Output,
        provenance: AIProvenance
    ) throws {
        if case .fallback = provenance {
            let inputData = try JSONEncoder().encode(input)
            let outputData = try JSONEncoder().encode(output)
            let inputHash = AIInputHasher.hash(
                inputJSON: inputData,
                excludedKeys: port.inputHashExcludedKeys,
                unorderedArrayKeys: port.unorderedArrayKeys
            )
            let outputHash = outputData.sha256Hash()

            fallbackLock.lock()
            defer { fallbackLock.unlock() }

            if let prior = fallbackOutputHashes[inputHash], prior != outputHash {
                throw PortInvariantViolation.nonIdempotent(
                    port: String(describing: port),
                    inputHash: inputHash
                )
            }

            fallbackOutputHashes[inputHash] = outputHash
        }
    }
}

// MARK: - Port Invariant Violations

public enum PortInvariantViolation: Error, LocalizedError {
    case boundViolation(field: String, value: String, constraint: String)
    case monotonicViolation(relation: String, actual: String)
    case missingReasonCodes(confidence: Double, threshold: Double)
    case nonIdempotent(port: String, inputHash: String)

    public var errorDescription: String? {
        switch self {
        case let .boundViolation(field, value, constraint):
            "Port invariant violated: field '\(field)' with value '\(value)' violates constraint '\(constraint)'"
        case let .monotonicViolation(relation, actual):
            "Port invariant violated: expected '\(relation)', but got '\(actual)'"
        case let .missingReasonCodes(confidence, threshold):
            "Port invariant violated: confidence \(confidence) < \(threshold) but no reasonCodes provided"
        case let .nonIdempotent(port, inputHash):
            "Port invariant violated: port '\(port)' produced different output for same input hash '\(inputHash)'"
        }
    }
}
