import Foundation

// MARK: - Local Model Configuration

struct LocalModelConfig {
    let modelName: String
    let sizeBytes: Int64
    let platform: Platform
    
    enum Platform {
        case macOS
        case iOS
        case iPadOS
    }
    
    var sizeMB: Double {
        return Double(sizeBytes) / (1024 * 1024)
    }
    
    var displaySize: String {
        if sizeMB < 1024 {
            return String(format: "%.0f MB", sizeMB)
        } else {
            return String(format: "%.1f GB", sizeMB / 1024)
        }
    }
}

// MARK: - macOS Local Provider

class LocalModelProvider_macOS: AIProvider {
    let name = "LocalMacOS"
    
    let capabilities = AICapabilities(
        offline: true,
        supportsTools: false,
        supportsSchema: true,
        maxContextTokens: 32768,
        supportedTaskKinds: [.intentToAction, .summarize, .rewrite, .studyQuestionGen, .syllabusParser]
    )
    
    static let modelConfig = LocalModelConfig(
        modelName: "mlx-community/Meta-Llama-3-8B-Instruct-4bit",
        sizeBytes: 4_300_000_000, // ~4.3 GB
        platform: .macOS
    )
    
    private let llmService: LocalLLMService
    
    init() {
        // Initialize with MLX backend by default
        let config = LLMBackendConfig.mlxDefault
        self.llmService = LocalLLMService(config: config)
    }
    
    init(backend: LLMBackend) {
        // Allow custom backend injection for testing
        self.llmService = LocalLLMService(backend: backend)
    }
    
    func generate(prompt: String, taskKind: AITaskKind, options: AIGenerateOptions) async throws -> AIResult {
        guard capabilities.supportedTaskKinds.contains(taskKind) else {
            throw AIError.taskNotSupported(taskKind)
        }
        
        guard llmService.isAvailable else {
            throw AIError.modelNotDownloaded
        }
        
        let startTime = Date()
        
        // Build full prompt with task-specific instructions
        let fullPrompt = buildPrompt(for: taskKind, userPrompt: prompt, options: options)
        
        // Use LLM backend for inference
        let response: LLMResponse
        if options.schema != nil {
            // JSON mode requested
            let jsonString = try await llmService.backend.generateJSON(
                prompt: fullPrompt,
                schema: options.schema
            )
            response = LLMResponse(
                text: jsonString,
                tokensUsed: nil,
                finishReason: "stop",
                model: llmService.modelName,
                latencyMs: Date().timeIntervalSince(startTime) * 1000
            )
        } else {
            // Regular text generation
            response = try await llmService.backend.generate(prompt: fullPrompt)
        }
        
        let latencyMs = Int(response.latencyMs ?? Date().timeIntervalSince(startTime) * 1000)
        
        return AIResult(
            content: response.text,
            metadata: AIResultMetadata(
                provider: name,
                latencyMs: latencyMs,
                tokenCount: response.tokensUsed,
                model: response.model ?? llmService.modelName,
                timestamp: Date()
            )
        )
    }
    
    private func buildPrompt(for taskKind: AITaskKind, userPrompt: String, options: AIGenerateOptions) -> String {
        var prompt = ""
        
        // Add system prompt if provided
        if let systemPrompt = options.systemPrompt {
            prompt += systemPrompt + "\n\n"
        } else {
            // Use default system prompt for task kind
            prompt += defaultSystemPrompt(for: taskKind) + "\n\n"
        }
        
        // Add user prompt
        prompt += userPrompt
        
        return prompt
    }
    
    private func defaultSystemPrompt(for taskKind: AITaskKind) -> String {
        switch taskKind {
        case .intentToAction:
            return "You are a precise intent parser. Extract structured actions from user commands."
        case .summarize:
            return "You are a concise summarizer. Create clear, accurate summaries."
        case .rewrite:
            return "You are a skilled editor. Improve clarity while maintaining meaning."
        case .studyQuestionGen:
            return "You are an educational assistant. Generate thoughtful study questions."
        case .syllabusParser:
            return "You are a syllabus parser. Extract structured course information."
        default:
            return "You are a helpful assistant."
        }
    }
    
    // MARK: - Model Management
    
    func checkModelAvailability() async -> Bool {
        return llmService.isAvailable
    }
    
    func updateBackend(_ config: LLMBackendConfig) async {
        await llmService.updateBackend(config)
    }
}

// MARK: - iOS/iPadOS Local Provider (Lite)

class LocalModelProvider_iOS: AIProvider {
    let name = "LocaliOS"
    
    let capabilities = AICapabilities(
        offline: true,
        supportsTools: false,
        supportsSchema: true,
        maxContextTokens: 8192,
        supportedTaskKinds: [.intentToAction, .summarize, .syllabusParser]
    )
    
    static let modelConfig = LocalModelConfig(
        modelName: "ollama/llama3.2:3b",
        sizeBytes: 800_000_000, // ~800 MB
        platform: .iOS
    )
    
    private let llmService: LocalLLMService
    
    init() {
        // Initialize with Ollama backend by default (lighter than MLX)
        let config = LLMBackendConfig.ollamaDefault
        self.llmService = LocalLLMService(config: config)
    }
    
    init(backend: LLMBackend) {
        // Allow custom backend injection for testing
        self.llmService = LocalLLMService(backend: backend)
    }
    
    func generate(prompt: String, taskKind: AITaskKind, options: AIGenerateOptions) async throws -> AIResult {
        guard capabilities.supportedTaskKinds.contains(taskKind) else {
            throw AIError.taskNotSupported(taskKind)
        }
        
        guard llmService.isAvailable else {
            throw AIError.modelNotDownloaded
        }
        
        let startTime = Date()
        
        // Build full prompt with task-specific instructions
        let fullPrompt = buildPrompt(for: taskKind, userPrompt: prompt, options: options)
        
        // Use LLM backend for inference
        let response: LLMResponse
        if options.schema != nil {
            // JSON mode requested
            let jsonString = try await llmService.backend.generateJSON(
                prompt: fullPrompt,
                schema: options.schema
            )
            response = LLMResponse(
                text: jsonString,
                tokensUsed: nil,
                finishReason: "stop",
                model: llmService.modelName,
                latencyMs: Date().timeIntervalSince(startTime) * 1000
            )
        } else {
            // Regular text generation
            response = try await llmService.backend.generate(prompt: fullPrompt)
        }
        
        let latencyMs = Int(response.latencyMs ?? Date().timeIntervalSince(startTime) * 1000)
        
        return AIResult(
            content: response.text,
            metadata: AIResultMetadata(
                provider: name,
                latencyMs: latencyMs,
                tokenCount: response.tokensUsed,
                model: response.model ?? llmService.modelName,
                timestamp: Date()
            )
        )
    }
    
    private func buildPrompt(for taskKind: AITaskKind, userPrompt: String, options: AIGenerateOptions) -> String {
        var prompt = ""
        
        // Add system prompt if provided
        if let systemPrompt = options.systemPrompt {
            prompt += systemPrompt + "\n\n"
        } else {
            // Use default system prompt for task kind
            prompt += defaultSystemPrompt(for: taskKind) + "\n\n"
        }
        
        // Add user prompt
        prompt += userPrompt
        
        return prompt
    }
    
    private func defaultSystemPrompt(for taskKind: AITaskKind) -> String {
        switch taskKind {
        case .intentToAction:
            return "You are a precise intent parser. Extract structured actions from user commands."
        case .summarize:
            return "You are a concise summarizer. Create clear, accurate summaries."
        case .syllabusParser:
            return "You are a syllabus parser. Extract structured course information."
        default:
            return "You are a helpful assistant."
        }
    }
    
    // MARK: - Model Management
    
    func checkModelAvailability() async -> Bool {
        return llmService.isAvailable
    }
    
    func updateBackend(_ config: LLMBackendConfig) async {
        await llmService.updateBackend(config)
    }
}
