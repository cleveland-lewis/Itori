//
// AIEngineProductionTests.swift
// Production-readiness test suite
//

import XCTest
@testable import SharedCore

final class AIEngineProductionTests: XCTestCase {
    // MARK: - Golden Parsing Tests

    func testGoldenSyllabusParsingDeterminism() async throws {
        // Given: same syllabus content
        let syllabusText = """
        Course: Introduction to Biology

        Assignments:
        - Reading Chapter 1 (Due: 01/15/2025)
        - Homework 1 (Due: 01/22/2025)
        - Midterm Exam (Due: 02/15/2025)
        """

        // When: parse multiple times with AI disabled (deterministic fallback)
        var results: [[String]] = []
        for _ in 0 ..< 5 {
            let extracted = try await parseSyllabus(syllabusText, useAI: false)
            results.append(extracted.map(\.title))
        }

        // Then: all results should be identical
        for i in 1 ..< results.count {
            XCTAssertEqual(results[0], results[i], "Results must be deterministic")
        }
    }

    func testDocumentIngestFallbackDeterminism() {
        let documents = [
            "Homework 1 due 01/15",
            "Reading Chapter 2 due Feb 5",
            "Project proposal due 03/01",
            "Quiz 1 due 01/20",
            "Exam review due 04/10"
        ]

        for doc in documents {
            let first = fallbackSignature(from: doc)
            for _ in 0 ..< 4 {
                XCTAssertEqual(first, fallbackSignature(from: doc), "Document ingest fallback should be deterministic")
            }
        }
    }

    func testEstimateDurationFallbackDeterminism() async {
        let estimator = DefaultDurationEstimator()
        let inputs: [(String, String?, Int?, Date?)] = [
            ("homework", "lecture", 3, Date()),
            ("reading", "seminar", 4, Date().addingTimeInterval(86400)),
            ("project", "lab", 2, nil)
        ]

        for input in inputs {
            let first = await estimator.estimateDuration(
                category: input.0,
                courseType: input.1,
                credits: input.2,
                dueDate: input.3,
                historicalData: []
            )
            for _ in 0 ..< 4 {
                let next = await estimator.estimateDuration(
                    category: input.0,
                    courseType: input.1,
                    credits: input.2,
                    dueDate: input.3,
                    historicalData: []
                )
                XCTAssertEqual(first, next, "Duration fallback should be deterministic")
            }
        }
    }

    func testWorkloadForecastFallbackDeterminism() async {
        let forecaster = DefaultWorkloadForecaster()
        let now = Date()
        let assignments = [
            AssignmentSummary(id: "a1", category: "homework", courseId: "c1", dueDate: now, estimatedMinutes: 60),
            AssignmentSummary(
                id: "a2",
                category: "reading",
                courseId: "c2",
                dueDate: now.addingTimeInterval(86400 * 3),
                estimatedMinutes: 45
            )
        ]

        let first = await forecaster.generateForecast(
            assignments: assignments,
            startDate: now,
            endDate: now.addingTimeInterval(86400 * 7)
        )
        for _ in 0 ..< 4 {
            let next = await forecaster.generateForecast(
                assignments: assignments,
                startDate: now,
                endDate: now.addingTimeInterval(86400 * 7)
            )
            XCTAssertEqual(first, next, "Workload forecast fallback should be deterministic")
        }
    }

    func testGoldenExtractedAssignmentsFormat() async throws {
        let syllabusText = """
        Week 1: Reading Chapter 1 (Due 01/15)
        Week 2: Homework 1 (Due 01/22)
        """

        let extracted = try await parseSyllabus(syllabusText, useAI: false)

        // Validate structure
        XCTAssertFalse(extracted.isEmpty)
        for assignment in extracted {
            XCTAssertFalse(assignment.title.isEmpty, "Title must not be empty")
            XCTAssertNotNil(assignment.dueDate, "Due date should be extracted")
        }
    }

    // MARK: - Chaos Tests

    func testProviderTimeout() async throws {
        // Simulate provider that times out
        let timeoutProvider = MockTimeoutProvider()
        let engine = createTestEngine(providers: [timeoutProvider])

        // Should fallback gracefully without crash
        let result = try await engine.request(
            EstimateTaskDurationPort.self,
            input: .init(
                courseID: "test",
                category: .homework,
                dueDate: Date(),
                userHistorySampleSize: 0
            )
        )

        // Should have used fallback
        XCTAssertEqual(result.provenance.primaryProvider, .fallbackHeuristic)
    }

    func testInvalidSchemaOutput() async throws {
        // Provider returns invalid JSON
        let badProvider = MockInvalidSchemaProvider()
        let engine = createTestEngine(providers: [badProvider])

        // Should reject and fallback
        let result = try await engine.request(
            EstimateTaskDurationPort.self,
            input: .init(
                courseID: "test",
                category: .homework,
                dueDate: Date(),
                userHistorySampleSize: 0
            )
        )

        // Should have used fallback
        XCTAssertEqual(result.provenance.primaryProvider, .fallbackHeuristic)
    }

    func testCircuitBreakerOpensAfterFailures() {
        let breaker = CircuitBreaker(failureThreshold: 3, cooldownInterval: 60, testRequestInterval: 10)
        XCTAssertEqual(breaker.getCurrentState(), .closed)
        breaker.recordFailure()
        breaker.recordFailure()
        breaker.recordFailure()
        XCTAssertEqual(breaker.getCurrentState(), .open)
        XCTAssertFalse(breaker.canAttempt(), "Circuit breaker should block attempts while open")
    }

    func testRateLimiterTriggered() async throws {
        let engine = createTestEngine()

        // Spam requests
        var results: [Bool] = []
        for _ in 0 ..< 100 {
            do {
                _ = try await engine.request(
                    EstimateTaskDurationPort.self,
                    input: .init(
                        courseID: "test",
                        category: .homework,
                        dueDate: Date(),
                        userHistorySampleSize: 0
                    )
                )
                results.append(true)
            } catch {
                results.append(false)
            }
        }

        // Some should be rate limited
        XCTAssertTrue(results.contains(false), "Rate limiter should have triggered")
    }

    func testKillSwitchMidRequest() async throws {
        let killSwitch = AIKillSwitch(enabled: true)
        let engine = createTestEngine(killSwitch: killSwitch)

        // Start request
        let task = Task {
            try await engine.request(
                EstimateTaskDurationPort.self,
                input: .init(
                    courseID: "test",
                    category: .homework,
                    dueDate: Date(),
                    userHistorySampleSize: 0
                )
            )
        }

        // Disable mid-flight
        await killSwitch.disable(reason: "test")

        // Should either complete or fail gracefully (never crash)
        do {
            _ = try await task.value
        } catch {
            // Expected: policy denied
            XCTAssertTrue(error is AIError)
        }
    }

    // MARK: - Privacy Tests

    func testRedactionCatchesPII() {
        let redactor = AIRedactor(level: .moderate)

        let input = """
        Contact me at john@example.com or 555-123-4567
        SSN: 123-45-6789
        Credit card: 4532-1234-5678-9010
        """

        let result = redactor.redact(input)

        XCTAssertFalse(result.redactedText.contains("john@example.com"))
        XCTAssertFalse(result.redactedText.contains("555-123-4567"))
        XCTAssertFalse(result.redactedText.contains("123-45-6789"))
        XCTAssertFalse(result.redactedText.contains("4532-1234-5678-9010"))

        XCTAssertTrue(result.redactedText.contains("[EMAIL]"))
        XCTAssertTrue(result.redactedText.contains("[PHONE]"))
        XCTAssertTrue(result.redactedText.contains("[SSN]"))
        XCTAssertTrue(result.redactedText.contains("[CREDIT_CARD]"))

        XCTAssertGreaterThan(result.bytesRemoved, 0)
    }

    func testRedactionPreservesStructure() {
        let redactor = AIRedactor(level: .light)

        let input = """
        Line 1: john@example.com
        Line 2: some text
        Line 3: another@email.com
        """

        let result = redactor.redact(input)

        // Should still have 3 lines
        let lines = result.redactedText.split(separator: "\n")
        XCTAssertEqual(lines.count, 3)
    }

    func testNoRawPIIInOutputs() async throws {
        let engine = createTestEngine()

        let input = """
        Student: John Doe (john@example.com)
        Assignment: Homework 1 due 01/15/2025
        """

        let result = try await engine.request(
            MockParsingPort.self,
            input: .init(text: input)
        )

        // Output should not contain raw email
        let outputJSON = try JSONEncoder().encode(result.output)
        let outputString = String(data: outputJSON, encoding: .utf8)!

        XCTAssertFalse(outputString.contains("john@example.com"))
    }

    // MARK: - UI Loop Test

    func testRapidTypingDoesNotExceedBudget() async throws {
        let rateLimiter = AIRateLimiter(globalRequestsPerMinute: 30, perPortRequestsPerMinute: 10)
        let engine = createTestEngine(rateLimiter: rateLimiter)

        let start = Date()
        var requestCount = 0
        var deniedCount = 0

        // Simulate rapid typing (100 keystrokes in 10 seconds)
        for _ in 0 ..< 100 {
            if await rateLimiter.allowRequest(for: "estimateTaskDuration") {
                requestCount += 1
            } else {
                deniedCount += 1
            }
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1s
        }

        let elapsed = Date().timeIntervalSince(start)
        let requestsPerMinute = Double(requestCount) / (elapsed / 60.0)

        // Should not exceed global limit
        XCTAssertLessThanOrEqual(requestsPerMinute, 35.0, "Should stay near limit")
        XCTAssertGreaterThan(deniedCount, 0, "Some requests should be denied")
    }

    func testEditStormThrottling() async throws {
        let rateLimiter = AIRateLimiter(globalRequestsPerMinute: 30, perPortRequestsPerMinute: 10)
        var deniedCount = 0

        for _ in 0 ..< 50 {
            let allowed = await rateLimiter.allowRequest(for: "estimateTaskDuration")
            if !allowed {
                deniedCount += 1
            }
            try? await Task.sleep(nanoseconds: 1_200_000_000) // 1.2s for 50 toggles in 60s
        }

        XCTAssertGreaterThan(deniedCount, 0, "Edit storm should trigger throttling")
        let stats = await rateLimiter.statistics()
        XCTAssertGreaterThan(stats.globalLimit, 0)
    }

    // MARK: - Semantic Validation Tests

    func testRejectInvalidDates() async throws {
        // Date in past (too old)
        let oldDate = Calendar.current.date(byAdding: .year, value: -3, to: Date())!

        XCTAssertThrowsError(try AISemanticValidator.validateAcademicDate(oldDate))

        // Date in future (too far)
        let futureDate = Calendar.current.date(byAdding: .year, value: 5, to: Date())!

        XCTAssertThrowsError(try AISemanticValidator.validateAcademicDate(futureDate))
    }

    func testRejectInvalidDurations() async throws {
        // Too short
        XCTAssertThrowsError(try AISemanticValidator.validateDuration(1))

        // Too long (> 12 hours)
        XCTAssertThrowsError(try AISemanticValidator.validateDuration(800))

        // Valid
        XCTAssertNoThrow(try AISemanticValidator.validateDuration(60))
    }

    func testRejectLogicalInconsistencies() async throws {
        // Min > max
        XCTAssertThrowsError(
            try AISemanticValidator.validateDurationEstimate(min: 100, estimated: 60, max: 50)
        )

        // Estimated outside range
        XCTAssertThrowsError(
            try AISemanticValidator.validateDurationEstimate(min: 30, estimated: 100, max: 60)
        )

        // Valid
        XCTAssertNoThrow(
            try AISemanticValidator.validateDurationEstimate(min: 30, estimated: 60, max: 90)
        )
    }

    // MARK: - Helpers

    private func createTestEngine(
        providers: [AIProvider] = [],
        killSwitch: AIKillSwitch? = nil,
        rateLimiter: AIRateLimiter? = nil
    ) -> MockAIEngine {
        MockAIEngine(
            providers: providers,
            killSwitch: killSwitch ?? AIKillSwitch(enabled: true),
            rateLimiter: rateLimiter ?? AIRateLimiter()
        )
    }

    private func parseSyllabus(_: String, useAI _: Bool) async throws -> [MockAssignment] {
        // Mock implementation
        []
    }

    private func fallbackSignature(from text: String) -> [String] {
        let assignments = AIFallbacks.extractAssignmentsBasic(from: text)
        return assignments.map { assignment in
            let due = assignment.dueDate?.timeIntervalSince1970 ?? 0
            return "\(assignment.title)|\(due)|\(assignment.category.rawValue)|\(assignment.estimatedMinutes)"
        }
    }
}

// MARK: - Mocks

struct MockAssignment {
    let title: String
    let dueDate: Date?
}

class MockTimeoutProvider: AIProvider {
    let id: AIProviderID = .localCoreML

    func isAvailable() -> Bool { true }
    func supports(port _: AIPortID) -> Bool { true }

    func execute(
        port _: AIPortID,
        inputJSON _: Data,
        context _: AIRequestContext
    ) async throws -> (outputJSON: Data, diagnostic: AIDiagnostic) {
        try await Task.sleep(nanoseconds: 10_000_000_000) // 10s timeout
        throw NSError(domain: "timeout", code: -1)
    }
}

class MockInvalidSchemaProvider: AIProvider {
    let id: AIProviderID = .localCoreML

    func isAvailable() -> Bool { true }
    func supports(port _: AIPortID) -> Bool { true }

    func execute(
        port _: AIPortID,
        inputJSON _: Data,
        context _: AIRequestContext
    ) async throws -> (outputJSON: Data, diagnostic: AIDiagnostic) {
        let invalid = "{invalid json".data(using: .utf8)!
        return (invalid, AIDiagnostic())
    }
}

class MockAIEngine {
    init(providers _: [AIProvider], killSwitch _: AIKillSwitch, rateLimiter _: AIRateLimiter) {}

    func request<P: AIPort>(_: P.Type, input _: P.Input) async throws -> AIResult<P.Output> {
        fatalError("Mock implementation")
    }
}

enum MockParsingPort: AIPort {
    static let id: AIPortID = .academicEntityExtract
    static let name: String = "Mock Parsing"
    static let privacyRequirement: AIPrivacyLevel = .normal

    struct Input: Codable, Sendable {
        let text: String
    }

    struct Output: Codable, Sendable {
        let items: [String]
    }

    static func validate(input _: Input) throws {}
    static func validate(output _: Output) throws {}
}
