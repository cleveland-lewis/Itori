import Foundation
import CoreML

#if os(macOS)

/// Local Model Provider for macOS (Standard Model)
///
/// Target: 500-800MB model with full reasoning capabilities
public final class LocalModelProvider_macOS: AIProvider {
    public let name = "Local Model (macOS Standard)"
    
    public var capabilities: AICapabilities {
        AICapabilities(
            isOffline: true,
            supportsTools: false,
            supportsSchema: true,
            maxContextLength: 4096,
            supportedTasks: [
                .intentToAction,
                .summarize,
                .rewrite,
                .studyQuestionGen,
                .textCompletion
            ],
            estimatedLatency: 1.5
        )
    }
    
    private var model: MLModel?
    
    public init() {}
    
    public func generate(
        prompt: String,
        task: AITaskKind,
        schema: [String: Any]?,
        temperature: Double
    ) async throws -> AIProviderResult {
        guard let modelURL = await modelURL() else {
            LOG_AI(.info, "LocalModel", "No CoreML model available for macOS")
            throw AIError.providerUnavailable("Local CoreML model not available")
        }

        if model == nil {
            try loadModel(from: modelURL)
        }

        guard let model else {
            throw AIError.providerUnavailable("Local CoreML model failed to load")
        }

        let startTime = Date()
        let outputText = try runInference(prompt: prompt, model: model)
        let latency = Int(Date().timeIntervalSince(startTime) * 1000)

        return AIProviderResult(
            text: outputText,
            provider: name,
            latencyMs: latency,
            tokenCount: nil,
            cached: false,
            structuredData: schema != nil ? ["local": true, "platform": "macOS"] : nil
        )
    }
    
    public func isAvailable() async -> Bool {
        if await modelURL() == nil {
            LOG_AI(.info, "LocalModel", "macOS model not found in Application Support")
            return false
        }
        return true
    }
    
    private func modelURL() async -> URL? {
        await MainActor.run {
            try? LocalModelManager.shared.getModelURL(.macOSStandard)
        }
    }

    private func loadModel(from url: URL) throws {
        model = try MLModel(contentsOf: url)
    }

    private func runInference(prompt: String, model: MLModel) throws -> String {
        let inputName = model.modelDescription.inputDescriptionsByName
            .first(where: { $0.value.type == .string })?.key
        let outputName = model.modelDescription.outputDescriptionsByName
            .first(where: { $0.value.type == .string })?.key

        guard let inputName, let outputName else {
            throw AIError.generationFailed("Model input/output schema unsupported for text inference")
        }

        let input = try MLDictionaryFeatureProvider(dictionary: [inputName: prompt])
        let output = try model.prediction(from: input)
        if let text = output.featureValue(for: outputName)?.stringValue {
            return text
        }
        throw AIError.generationFailed("Model returned empty response")
    }
}

#endif
