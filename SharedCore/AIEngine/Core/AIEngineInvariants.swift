import Foundation

extension AIEngine {
    func validateInvariants<P: AIPort>(
        port: P.Type,
        input: P.Input,
        output: P.Output,
        result: AIResult<P.Output>
    ) throws {
        try PortInvariants.validate(port: port, input: input, output: output, result: result)
        guard (0...1).contains(result.confidence.value) else {
            throw AIEngineError.validationFailed(reason: "confidence out of bounds")
        }

        switch P.id {
        /* Disabled - scheduling ports unavailable
        case .generateStudyPlan:
            guard let output = output as? GenerateStudyPlanPort.Output else { return }
            guard !output.sessions.isEmpty else {
                throw AIEngineError.validationFailed(reason: "no sessions returned")
            }
            for session in output.sessions {
                guard session.estimatedMinutes > 0 else {
                    throw AIEngineError.validationFailed(reason: "session duration non-positive")
                }
                guard session.sessionIndex > 0, session.sessionCount >= session.sessionIndex else {
                    throw AIEngineError.validationFailed(reason: "invalid session index")
                }
            }

        case .schedulePlacement:
            guard let output = output as? SchedulePlacementPort.Output else { return }
            for block in output.scheduled {
                guard block.end > block.start else {
                    throw AIEngineError.validationFailed(reason: "scheduled block end before start")
                }
            }

        case .conflictResolution:
            guard let output = output as? ConflictResolutionPort.Output else { return }
            for block in output.scheduled {
                guard block.end > block.start else {
                    throw AIEngineError.validationFailed(reason: "conflict block end before start")
                }
            }
        */
        default:
            break
        }
    }
}
