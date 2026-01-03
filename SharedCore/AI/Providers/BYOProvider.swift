import Foundation

// MARK: - BYO Provider Type

/// Supported BYO provider types
public enum BYOProviderType: String, Codable, CaseIterable, Identifiable {
    case openai
    case anthropic
    case custom
    
    public var id: String { rawValue }
    
    public var displayName: String {
        switch self {
        case .openai:
            return "OpenAI"
        case .anthropic:
            return "Anthropic"
        case .custom:
            return "Custom API"
        }
    }
}

// MARK: - BYO Provider

/// Bring Your Own provider implementation
public final class BYOProvider: AIProvider {
    public let name: String
    private let type: BYOProviderType
    private let apiKey: String
    private let endpoint: String?
    
    public var capabilities: AICapabilities {
        AICapabilities(
            isOffline: false,  // Network required
            supportsTools: true,
            supportsSchema: true,
            maxContextLength: 100000,  // Depends on provider
            supportedTasks: Set([
                .intentToAction,
                .summarize,
                .rewrite,
                .studyQuestionGen,
                .textCompletion,
                .chat
            ]),
            estimatedLatency: 2.0  // Network latency
        )
    }
    
    public init(type: BYOProviderType, apiKey: String, endpoint: String? = nil) {
        self.type = type
        self.apiKey = apiKey
        self.endpoint = endpoint
        self.name = "BYO (\(type.displayName))"
    }
    
    public func generate(
        prompt: String,
        task: AITaskKind,
        schema: [String: Any]?,
        temperature: Double
    ) async throws -> AIProviderResult {
        let startTime = Date()
        
        // Prepare prompt with JSON schema if needed
        let finalPrompt = if let schema = schema {
            enhancePromptWithSchema(prompt: prompt, schema: schema)
        } else {
            prompt
        }
        
        // Call appropriate client based on provider type
        let (text, tokenCount): (String, Int)
        
        switch type {
        case .openai:
            let client = OpenAIClient(apiKey: apiKey, endpoint: endpoint)
            (text, tokenCount) = try await client.chatCompletion(
                prompt: finalPrompt,
                temperature: temperature,
                requireJSON: schema != nil
            )
            
        case .anthropic:
            let client = AnthropicClient(apiKey: apiKey, endpoint: endpoint)
            let systemPrompt = schema != nil ? "Always respond with valid JSON." : nil
            (text, tokenCount) = try await client.messageCompletion(
                prompt: finalPrompt,
                temperature: temperature,
                systemPrompt: systemPrompt
            )
            
        case .custom:
            guard let endpoint = endpoint else {
                throw AIError.providerNotConfigured("Custom API endpoint required")
            }
            let client = CustomAPIClient(apiKey: apiKey, endpoint: endpoint)
            (text, tokenCount) = try await client.chatCompletion(
                prompt: finalPrompt,
                temperature: temperature
            )
        }
        
        let latency = Int(Date().timeIntervalSince(startTime) * 1000)
        
        // Parse JSON if schema was provided
        let structuredData: [String: Any]? = if schema != nil {
            try? parseJSONResponse(text: text)
        } else {
            nil
        }
        
        return AIProviderResult(
            text: text,
            provider: name,
            latencyMs: latency,
            tokenCount: tokenCount,
            cached: false,
            structuredData: structuredData
        )
    }
    
    // MARK: - Helper Methods
    
    private func enhancePromptWithSchema(prompt: String, schema: [String: Any]) -> String {
        let schemaJSON = try? JSONSerialization.data(withJSONObject: schema, options: .prettyPrinted)
        let schemaString = schemaJSON.flatMap { String(data: $0, encoding: .utf8) } ?? "{}"
        
        return """
        \(prompt)
        
        Respond with valid JSON matching this schema:
        \(schemaString)
        """
    }
    
    private func parseJSONResponse(text: String) throws -> [String: Any] {
        // Extract JSON from markdown code blocks if present
        let cleanedText = text
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard let data = cleanedText.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw AIError.invalidSchema
        }
        
        return json
    }
    
    public func isAvailable() async -> Bool {
        // Check if API key is provided
        guard !apiKey.isEmpty else { return false }
        
        // For custom provider, endpoint is required
        if type == .custom && endpoint == nil {
            return false
        }
        
        // Quick availability check - try a minimal request
        do {
            switch type {
            case .openai:
                let client = OpenAIClient(apiKey: apiKey, endpoint: endpoint)
                // Test with minimal prompt
                _ = try await client.chatCompletion(
                    prompt: "Say 'OK'",
                    temperature: 0.0,
                    requireJSON: false
                )
                return true
                
            case .anthropic:
                let client = AnthropicClient(apiKey: apiKey, endpoint: endpoint)
                _ = try await client.messageCompletion(
                    prompt: "Say 'OK'",
                    temperature: 0.0
                )
                return true
                
            case .custom:
                guard let endpoint = endpoint else { return false }
                let client = CustomAPIClient(apiKey: apiKey, endpoint: endpoint)
                _ = try await client.chatCompletion(
                    prompt: "Say 'OK'",
                    temperature: 0.0
                )
                return true
            }
        } catch {
            LOG_AI(.warn, "BYOProvider", "Availability check failed", metadata: [
                "provider": type.rawValue,
                "error": error.localizedDescription
            ])
            return false
        }
    }
}
