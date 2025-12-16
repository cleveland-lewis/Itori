import Foundation

/// Factory for creating LLM backends
class LLMBackendFactory {
    
    static func createBackend(config: LLMBackendConfig) -> LLMBackend {
        switch config.type {
        case .mock:
            return MockLLMBackend(config: config)
            
        case .mlx:
            return MLXBackend(config: config)
            
        case .ollama:
            return OllamaBackend(config: config)
            
        case .openaiCompatible:
            return OpenAICompatibleBackend(config: config)
        }
    }
    
    /// Auto-detect available backend
    static func detectAvailableBackend() async -> LLMBackend {
        // Try Ollama first (most common for local dev)
        let ollamaConfig = LLMBackendConfig.ollamaDefault
        let ollama = OllamaBackend(config: ollamaConfig)
        if await ollama.isAvailable {
            print("[LLM] Detected Ollama backend")
            return ollama
        }
        
        // Try MLX
        let mlxConfig = LLMBackendConfig.mlxDefault
        let mlx = MLXBackend(config: mlxConfig)
        if await mlx.isAvailable {
            print("[LLM] Detected MLX backend")
            return mlx
        }
        
        // Fall back to mock
        print("[LLM] No real backend detected, using mock")
        return MockLLMBackend()
    }
    
    /// Create backend from user defaults
    static func createFromUserDefaults() -> LLMBackend {
        guard let configData = UserDefaults.standard.data(forKey: "llm_backend_config"),
              let config = try? JSONDecoder().decode(LLMBackendConfig.self, from: configData) else {
            return MockLLMBackend()
        }
        
        return createBackend(config: config)
    }
    
    /// Save backend config to user defaults
    static func saveConfig(_ config: LLMBackendConfig) {
        if let data = try? JSONEncoder().encode(config) {
            UserDefaults.standard.set(data, forKey: "llm_backend_config")
        }
    }
}
