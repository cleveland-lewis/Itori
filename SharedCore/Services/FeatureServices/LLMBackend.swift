import Foundation

/// LLM Backend configuration and types
enum LLMBackendType: String, Codable, CaseIterable {
    case mock = "Mock"
    case mlx = "MLX"
    case ollama = "Ollama"
    case openaiCompatible = "OpenAI Compatible"
    
    var requiresAPIKey: Bool {
        switch self {
        case .openaiCompatible:
            return true
        case .mock, .mlx, .ollama:
            return false
        }
    }
    
    var supportsStreaming: Bool {
        switch self {
        case .mlx, .ollama, .openaiCompatible:
            return true
        case .mock:
            return false
        }
    }
}

/// LLM Backend configuration
struct LLMBackendConfig: Codable {
    var type: LLMBackendType
    var modelName: String
    var apiEndpoint: String?
    var apiKey: String?
    var temperature: Double
    var maxTokens: Int
    var timeout: TimeInterval
    
    // MLX-specific
    var mlxModelPath: String?
    
    // Ollama-specific
    var ollamaHost: String?
    
    init(
        type: LLMBackendType = .mock,
        modelName: String = "mock-model",
        apiEndpoint: String? = nil,
        apiKey: String? = nil,
        temperature: Double = 0.7,
        maxTokens: Int = 2048,
        timeout: TimeInterval = 60,
        mlxModelPath: String? = nil,
        ollamaHost: String? = nil
    ) {
        self.type = type
        self.modelName = modelName
        self.apiEndpoint = apiEndpoint
        self.apiKey = apiKey
        self.temperature = temperature
        self.maxTokens = maxTokens
        self.timeout = timeout
        self.mlxModelPath = mlxModelPath
        self.ollamaHost = ollamaHost
    }
    
    // Preset configurations
    static var mockConfig: LLMBackendConfig {
        LLMBackendConfig(type: .mock, modelName: "mock-model")
    }
    
    static var mlxDefault: LLMBackendConfig {
        LLMBackendConfig(
            type: .mlx,
            modelName: "mlx-community/Meta-Llama-3-8B-Instruct-4bit",
            mlxModelPath: nil // Auto-downloads to cache
        )
    }
    
    static var ollamaDefault: LLMBackendConfig {
        LLMBackendConfig(
            type: .ollama,
            modelName: "llama3.2:3b",
            ollamaHost: "http://localhost:11434"
        )
    }
    
    static func openaiCompatible(apiKey: String, endpoint: String = "https://api.openai.com/v1") -> LLMBackendConfig {
        LLMBackendConfig(
            type: .openaiCompatible,
            modelName: "gpt-4",
            apiEndpoint: endpoint,
            apiKey: apiKey
        )
    }
}

/// LLM Response from backend
struct LLMResponse: Codable {
    var text: String
    var tokensUsed: Int?
    var finishReason: String?
    var model: String?
    var latencyMs: Double?
}

/// Protocol for LLM backend implementations
protocol LLMBackend {
    var config: LLMBackendConfig { get }
    var isAvailable: Bool { get async }
    
    func generate(prompt: String) async throws -> LLMResponse
    func generateJSON(prompt: String, schema: String?) async throws -> String
}

/// Errors that can occur during LLM operations
enum LLMBackendError: Error, LocalizedError {
    case notAvailable(String)
    case configurationError(String)
    case networkError(String)
    case timeoutError
    case invalidResponse(String)
    case apiKeyMissing
    case modelNotFound(String)
    
    var errorDescription: String? {
        switch self {
        case .notAvailable(let reason):
            return "LLM backend not available: \(reason)"
        case .configurationError(let details):
            return "Configuration error: \(details)"
        case .networkError(let details):
            return "Network error: \(details)"
        case .timeoutError:
            return "Request timed out"
        case .invalidResponse(let details):
            return "Invalid response: \(details)"
        case .apiKeyMissing:
            return "API key is required but not provided"
        case .modelNotFound(let model):
            return "Model not found: \(model)"
        }
    }
}
