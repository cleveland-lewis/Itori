import XCTest
@testable import SharedCore

/// CI test that enforces the single integration pattern
/// This test MUST fail if any code violates the approved AI integration pattern
final class AIIntegrationPatternEnforcementTests: XCTestCase {
    // MARK: - Pattern Enforcement Tests

    func testNoDirectProviderImportsInFeatures() throws {
        // Scan all Swift files in feature directories
        let featurePaths = [
            "Shared/Features",
            "Platforms/iOS/Features",
            "Platforms/macOS/Features",
            "Platforms/watchOS/Features"
        ]

        var violations: [String] = []

        for featurePath in featurePaths {
            let fullPath = projectRoot.appendingPathComponent(featurePath)
            guard FileManager.default.fileExists(atPath: fullPath.path) else { continue }

            let swiftFiles = try findSwiftFiles(in: fullPath)

            for file in swiftFiles {
                let content = try String(contentsOf: file, encoding: .utf8)

                // Check for direct provider imports
                if content.contains("import OpenAIProvider") ||
                    content.contains("import AnthropicProvider") ||
                    content.contains("import GeminiProvider")
                {
                    violations.append("\(file.lastPathComponent): Imports AI provider directly")
                }

                // Check for direct provider instantiation
                if content.contains("OpenAIProvider(") ||
                    content.contains("AnthropicProvider(") ||
                    content.contains("GeminiProvider(")
                {
                    violations.append("\(file.lastPathComponent): Instantiates AI provider directly")
                }
            }
        }

        XCTAssertTrue(violations.isEmpty, """
        ❌ AI Integration Pattern Violations Found:

        \(violations.joined(separator: "\n"))

        Features must only call AIEngine.request() or SafeAIPort.execute()
        Never import or instantiate providers directly.
        """)
    }

    func testNoProviderImportsOutsideAIEngine() throws {
        let projectRoot = self.projectRoot
        let swiftFiles = try findSwiftFiles(in: projectRoot)
        var violations: [String] = []

        for file in swiftFiles {
            let path = file.path
            if path.contains("/SharedCore/AIEngine/") {
                continue
            }
            let content = try String(contentsOf: file, encoding: .utf8)
            if content.contains("import OpenAIProvider") ||
                content.contains("import AnthropicProvider") ||
                content.contains("import GeminiProvider")
            {
                violations.append("\(file.lastPathComponent): Provider import outside AIEngine")
            }
        }

        XCTAssertTrue(violations.isEmpty, """
        ❌ AI Integration Pattern Violations Found:

        \(violations.joined(separator: "\n"))

        Provider imports must live inside AIEngine only.
        """)
    }

    func testNoDirectFallbackCallsInFeatures() throws {
        let featurePaths = [
            "Shared/Features",
            "Platforms/iOS/Features",
            "Platforms/macOS/Features",
            "Platforms/watchOS/Features"
        ]

        var violations: [String] = []

        for featurePath in featurePaths {
            let fullPath = projectRoot.appendingPathComponent(featurePath)
            guard FileManager.default.fileExists(atPath: fullPath.path) else { continue }

            let swiftFiles = try findSwiftFiles(in: fullPath)

            for file in swiftFiles {
                let content = try String(contentsOf: file, encoding: .utf8)

                // Check for direct fallback calls
                if content.contains("SchedulingFallbackEngine") ||
                    content.contains(".executeFallback(")
                {
                    violations.append("\(file.lastPathComponent): Calls fallback directly")
                }
            }
        }

        XCTAssertTrue(violations.isEmpty, """
        ❌ AI Integration Pattern Violations Found:

        \(violations.joined(separator: "\n"))

        Features must not call fallback implementations directly.
        Use AIEngine.request() which handles fallback automatically.
        """)
    }

    func testNoAICallsFromViews() throws {
        let viewPaths = [
            "Shared/Views",
            "Platforms/iOS/Views",
            "Platforms/macOS/Views",
            "Platforms/macOS/Scenes"
        ]

        var violations: [String] = []

        for viewPath in viewPaths {
            let fullPath = projectRoot.appendingPathComponent(viewPath)
            guard FileManager.default.fileExists(atPath: fullPath.path) else { continue }

            let swiftFiles = try findSwiftFiles(in: fullPath)

            for file in swiftFiles {
                // Skip ViewModels
                if file.lastPathComponent.contains("ViewModel") {
                    continue
                }

                let content = try String(contentsOf: file, encoding: .utf8)

                // Check for AI engine calls from Views
                if content.contains("AIEngine.shared.request") ||
                    content.contains("SafeAIPort")
                {
                    violations.append("\(file.lastPathComponent): Calls AI from View layer")
                }
            }
        }

        XCTAssertTrue(violations.isEmpty, """
        ❌ AI Integration Pattern Violations Found:

        \(violations.joined(separator: "\n"))

        Views must not call AI directly.
        Use ViewModels to handle all AI interactions.
        """)
    }

    func testNoLegacyAIProvidersOutsideLegacyModule() throws {
        let rootPaths = [
            "SharedCore",
            "Shared",
            "Platforms/iOS",
            "Platforms/macOS",
            "Platforms/watchOS"
        ]

        let forbiddenTokens = [
            "AIRouter",
            "SafeAIPort",
            "AppleIntelligenceProvider",
            "LocalModelProvider",
            "BYOProvider",
            "AIProvider("
        ]

        var violations: [String] = []

        for rootPath in rootPaths {
            let fullPath = projectRoot.appendingPathComponent(rootPath)
            guard FileManager.default.fileExists(atPath: fullPath.path) else { continue }

            let swiftFiles = try findSwiftFiles(in: fullPath)
            for file in swiftFiles {
                if file.path.contains("/SharedCore/AI/") {
                    continue
                }

                let content = try String(contentsOf: file, encoding: .utf8)
                if forbiddenTokens.contains(where: { content.contains($0) }) {
                    violations.append("\(file.lastPathComponent): Uses legacy AI providers")
                }
            }
        }

        XCTAssertTrue(violations.isEmpty, """
        ❌ Legacy AI provider usage found outside SharedCore/AI:

        \(violations.joined(separator: "\n"))

        Legacy provider APIs must be wrapped behind AIEngine or adapters only.
        """)
    }

    func testAIPortCallsOnlyFromAllowedLayers() throws {
        let swiftFiles = try findSwiftFiles(in: projectRoot)
        var violations: [String] = []

        let allowedPathSnippets = [
            "/ViewModel",
            "/Reducer",
            "/State/",
            "/AIEngine/",
            "/AI/",
            "/Services/FeatureServices/"
        ]
        let disallowedPathSnippets = [
            "/Views/",
            "/Scenes/"
        ]

        for file in swiftFiles {
            let content = try String(contentsOf: file, encoding: .utf8)
            guard content.contains("AIEngine.shared.request") else { continue }

            let path = file.path
            let isDisallowed = disallowedPathSnippets.contains { path.contains($0) }
            let isAllowed = allowedPathSnippets.contains { path.contains($0) }

            if isDisallowed || !isAllowed {
                violations.append("\(file.lastPathComponent): AIEngine call outside allowed layer")
            }
        }

        XCTAssertTrue(violations.isEmpty, """
        ❌ AI Integration Pattern Violations Found:

        \(violations.joined(separator: "\n"))

        AI ports may be called only from ViewModels, Reducers, background/import jobs, or AIEngine orchestrators.
        """)
    }

    func testScheduleSuggestionApplyCalledOnlyFromPlannerViews() throws {
        let swiftFiles = try findSwiftFiles(in: projectRoot)
        var violations: [String] = []
        let allowedFiles: Set<String> = [
            "IOSCorePages.swift",
            "PlannerPageView.swift"
        ]

        for file in swiftFiles {
            let content = try String(contentsOf: file, encoding: .utf8)
            guard content.contains("applyPendingScheduleSuggestion(") else { continue }
            if !allowedFiles.contains(file.lastPathComponent) {
                violations
                    .append("\(file.lastPathComponent): applyPendingScheduleSuggestion called outside Planner view")
            }
        }

        XCTAssertTrue(violations.isEmpty, """
        ❌ Schedule apply entrypoint violations found:

        \(violations.joined(separator: "\n"))

        applyPendingScheduleSuggestion() may be called only from Planner view entrypoints.
        """)
    }

    // MARK: - Monotonic Merge Guard Tests

    func testFieldMergeGuardPreventsStaleResults() {
        let guard = FieldMergeGuard(
            lastUserEditAt: Date(),
            lastAppliedAIAt: Date().addingTimeInterval(-60),
            lastAppliedAIInputHash: "abc123",
            isUserLocked: false
        )

        let staleResult = MockAIResult(
            inputHash: "abc123",
            computedAt: Date().addingTimeInterval(-120), // Computed before user edit
            confidence: AIConfidence(0.8)
        )

        XCTAssertFalse(
            guard .shouldApply(result: staleResult, currentInputHash: "abc123"),
            "Should not apply stale result computed before user edit"
        )
    }

    func testFieldMergeGuardRejectsUptimeRegression() {
        let guard = FieldMergeGuard(
            lastUserEditAt: Date(),
            lastUserEditUptime: 120,
            lastAppliedAIAt: nil,
            lastAppliedAIUptime: nil,
            lastAppliedAIInputHash: nil,
            isUserLocked: false
        )

        let result = MockAIResult(
            inputHash: "abc123",
            computedAt: Date(),
            confidence: AIConfidence(0.8),
            computedAtUptime: 60
        )

        XCTAssertFalse(
            guard .shouldApply(result: result, currentInputHash: "abc123"),
            "Should not apply when uptime indicates result is older than user edit"
        )
    }

    func testFieldMergeGuardPreventsInputMismatch() {
        let guard = FieldMergeGuard()

        let result = MockAIResult(
            inputHash: "abc123",
            computedAt: Date(),
            confidence: AIConfidence(0.8)
        )

        XCTAssertFalse(
            guard .shouldApply(result: result, currentInputHash: "xyz789"),
            "Should not apply result with mismatched input hash"
        )
    }

    func testFieldMergeGuardRespectsUserLock() {
        let guard = FieldMergeGuard(isUserLocked: true)

        let result = MockAIResult(
            inputHash: "abc123",
            computedAt: Date(),
            confidence: AIConfidence(0.8)
        )

        XCTAssertFalse(
            guard .shouldApply(result: result, currentInputHash: "abc123"),
            "Should never apply to user-locked field"
        )
    }

    func testFieldMergeGuardRejectsFeatureStateMismatch() {
        let guard = FieldMergeGuard()
        let result = MockAIResult(
            inputHash: "abc123",
            computedAt: Date(),
            confidence: AIConfidence(0.8),
            featureStateVersion: 2
        )

        XCTAssertFalse(
            guard .shouldApply(
                result: result,
                currentInputHash: "abc123",
                currentFeatureStateVersion: 1
            ),
            "Should not apply if feature state version changed"
        )
    }

    // MARK: - Schedule Diff Idempotency Tests

    func testScheduleDiffIsIdempotent() {
        let diff = ScheduleDiff(
            addedBlocks: [
                ProposedBlock(tempID: "add1", title: "Study", startDate: Date(), duration: 3600, reason: "test")
            ],
            movedBlocks: [
                MovedBlock(blockID: "mod1", newStartDate: Date(), reason: "test")
            ],
            resizedBlocks: [
                ResizedBlock(blockID: "resize1", newDuration: 5400, reason: "test")
            ],
            conflicts: [],
            reason: "test",
            confidence: AIConfidence(0.8)
        )

        XCTAssertTrue(diff.isIdempotent(), "Schedule diff should be idempotent with non-overlapping operations")
    }

    func testScheduleDiffDetectsNonIdempotent() {
        let diff = ScheduleDiff(
            addedBlocks: [
                ProposedBlock(tempID: "block1", title: "Study", startDate: Date(), duration: 3600, reason: "test")
            ],
            movedBlocks: [
                MovedBlock(blockID: "block1", newStartDate: Date(), reason: "test")
            ],
            resizedBlocks: [],
            conflicts: [],
            reason: "test",
            confidence: AIConfidence(0.8)
        )

        XCTAssertFalse(diff.isIdempotent(), "Schedule diff should detect overlapping operations")
    }

    func testScheduleDiffApplyIsStable() {
        let now = Date()
        let existing = [
            ScheduleBlockState(id: "block1", title: "Read", startDate: now, duration: 1800)
        ]
        let diff = ScheduleDiff(
            addedBlocks: [
                ProposedBlock(
                    tempID: "block2",
                    title: "Write",
                    startDate: now.addingTimeInterval(3600),
                    duration: 1200,
                    reason: "test"
                )
            ],
            movedBlocks: [
                MovedBlock(blockID: "block1", newStartDate: now.addingTimeInterval(900), reason: "test")
            ],
            resizedBlocks: [
                ResizedBlock(blockID: "block1", newDuration: 2400, reason: "test")
            ],
            conflicts: [],
            reason: "test",
            confidence: AIConfidence(0.8)
        )

        let once = apply(diff, to: existing)
        let twice = apply(diff, to: once)

        XCTAssertEqual(once, twice, "Applying the same diff twice should yield a stable state")
    }

    // MARK: - Merge Policy Tests

    func testDefaultOnlyPolicyDoesNotOverwriteUserEdits() {
        let policy = AIMergePolicy.defaultOnly
        let guard = FieldMergeGuard(lastUserEditAt: Date())
        let result = MockAIResult(
            inputHash: "abc123",
            computedAt: Date(),
            confidence: AIConfidence(0.8)
        )

        XCTAssertFalse(
            policy.shouldApply(result: result, guard: guard, currentInputHash: "abc123", isFieldEmpty: true),
            "Default-only policy should not overwrite user edits"
        )
    }

    func testSuggestOnlyPolicyNeverAutoApplies() {
        let policy = AIMergePolicy.suggestOnly
        let guard = FieldMergeGuard()
        let result = MockAIResult(
            inputHash: "abc123",
            computedAt: Date(),
            confidence: AIConfidence(0.9)
        )

        XCTAssertFalse(
            policy.shouldApply(result: result, guard: guard, currentInputHash: "abc123", isFieldEmpty: true),
            "Suggest-only policy should never auto-apply"
        )
    }

    func testExplicitApplyRequiredNeverAutoApplies() {
        let policy = AIMergePolicy.explicitApplyRequired
        let guard = FieldMergeGuard()
        let result = MockAIResult(
            inputHash: "abc123",
            computedAt: Date(),
            confidence: AIConfidence(0.95)
        )

        XCTAssertFalse(
            policy.shouldApply(result: result, guard: guard, currentInputHash: "abc123", isFieldEmpty: true),
            "Explicit-apply-required policy should never auto-apply"
        )
    }

    func testSchedulingPortsDeclareSuggestOnlyMergePolicy() {
        XCTAssertEqual(GenerateStudyPlanPort.mergePolicy, .suggestOnly)
        XCTAssertEqual(SchedulePlacementPort.mergePolicy, .suggestOnly)
        XCTAssertEqual(ConflictResolutionPort.mergePolicy, .suggestOnly)
    }

    // MARK: - Helper Methods

    private var projectRoot: URL {
        URL(fileURLWithPath: #file)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
    }

    private func findSwiftFiles(in directory: URL) throws -> [URL] {
        let fileManager = FileManager.default
        guard let enumerator = fileManager.enumerator(at: directory, includingPropertiesForKeys: nil) else {
            return []
        }

        var swiftFiles: [URL] = []
        for case let fileURL as URL in enumerator {
            if fileURL.pathExtension == "swift" {
                swiftFiles.append(fileURL)
            }
        }

        return swiftFiles
    }
}

// MARK: - Mock AI Result

private struct MockAIResult: AIResultProtocol {
    let inputHash: String
    let computedAt: Date
    let computedAtUptime: TimeInterval?
    let featureStateVersion: Int
    let confidence: AIConfidence
    let provenance: AIProvenance

    init(
        inputHash: String,
        computedAt: Date,
        confidence: AIConfidence,
        computedAtUptime: TimeInterval? = nil,
        featureStateVersion: Int = 0,
        provenance: AIProvenance = .fallback(.fallbackHeuristic)
    ) {
        self.inputHash = inputHash
        self.computedAt = computedAt
        self.computedAtUptime = computedAtUptime
        self.confidence = confidence
        self.featureStateVersion = featureStateVersion
        self.provenance = provenance
    }
}

private struct ScheduleBlockState: Equatable {
    let id: String
    let title: String
    let startDate: Date
    let duration: TimeInterval
}

private func apply(_ diff: ScheduleDiff, to blocks: [ScheduleBlockState]) -> [ScheduleBlockState] {
    var byID = Dictionary(uniqueKeysWithValues: blocks.map { ($0.id, $0) })

    for addition in diff.addedBlocks {
        byID[addition.tempID] = ScheduleBlockState(
            id: addition.tempID,
            title: addition.title,
            startDate: addition.startDate,
            duration: addition.duration
        )
    }

    for move in diff.movedBlocks {
        guard let existing = byID[move.blockID] else { continue }
        byID[move.blockID] = ScheduleBlockState(
            id: existing.id,
            title: existing.title,
            startDate: move.newStartDate,
            duration: existing.duration
        )
    }

    for resize in diff.resizedBlocks {
        guard let existing = byID[resize.blockID] else { continue }
        byID[resize.blockID] = ScheduleBlockState(
            id: existing.id,
            title: existing.title,
            startDate: existing.startDate,
            duration: resize.newDuration
        )
    }

    return byID.values.sorted { $0.id < $1.id }
}
