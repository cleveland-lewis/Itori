import Foundation
import CoreML

#if os(iOS) || os(iPadOS)

/// Local Model Provider for iOS/iPadOS (Lite Model)
///
/// Target: 100-200MB model optimized for mobile
public final class LocalModelProvider_iOS: AIProvider {
    public let name = "Local Model (iOS Lite)"
    
    public var capabilities: AICapabilities {
        AICapabilities(
            isOffline: true,
            supportsTools: false,
            supportsSchema: true,
            maxContextLength: 2048,
            supportedTasks: [
                .intentToAction,
                .summarize,
                .rewrite,
                .textCompletion
            ],
            estimatedLatency: 2.0
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
            LOG_AI(.info, "LocalModel", "No CoreML model available for iOS")
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
            structuredData: schema != nil ? ["local": true, "platform": "iOS"] : nil
        )
    }
    
    public func isAvailable() async -> Bool {
        if await modelURL() == nil {
            LOG_AI(.info, "LocalModel", "iOS model not found in Application Support")
            return false
        }
        return true
    }
    
    private func modelURL() async -> URL? {
        await MainActor.run {
            try? LocalModelManager.shared.getModelURL(.iOSLite)
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
