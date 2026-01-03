import Foundation

// MARK: - Anthropic API Client

/// Anthropic (Claude) API client for message completions
struct AnthropicClient {
    let apiKey: String
    let endpoint: String
    
    init(apiKey: String, endpoint: String? = nil) {
        self.apiKey = apiKey
        self.endpoint = endpoint ?? "https://api.anthropic.com/v1"
    }
    
    // MARK: - Request/Response Models
    
    struct MessageRequest: Codable {
        let model: String
        let messages: [Message]
        let maxTokens: Int
        let temperature: Double
        let system: String?
        
        enum CodingKeys: String, CodingKey {
            case model
            case messages
            case maxTokens = "max_tokens"
            case temperature
            case system
        }
        
        struct Message: Codable {
            let role: String
            let content: String
        }
    }
    
    struct MessageResponse: Codable {
        let id: String
        let type: String
        let role: String
        let content: [Content]
        let model: String
        let stopReason: String?
        let usage: Usage
        
        enum CodingKeys: String, CodingKey {
            case id
            case type
            case role
            case content
            case model
            case stopReason = "stop_reason"
            case usage
        }
        
        struct Content: Codable {
            let type: String
            let text: String
        }
        
        struct Usage: Codable {
            let inputTokens: Int
            let outputTokens: Int
            
            enum CodingKeys: String, CodingKey {
                case inputTokens = "input_tokens"
                case outputTokens = "output_tokens"
            }
        }
    }
    
    struct ErrorResponse: Codable {
        let type: String
        let error: ErrorDetail
        
        struct ErrorDetail: Codable {
            let type: String
            let message: String
        }
    }
    
    // MARK: - API Methods
    
    func messageCompletion(
        prompt: String,
        temperature: Double,
        systemPrompt: String? = nil
    ) async throws -> (text: String, tokenCount: Int) {
        let url = URL(string: "\(endpoint)/messages")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        
        let requestBody = MessageRequest(
            model: "claude-3-5-sonnet-20241022",  // Latest model
            messages: [
                MessageRequest.Message(role: "user", content: prompt)
            ],
            maxTokens: 4096,
            temperature: temperature,
            system: systemPrompt
        )
        
        let encoder = JSONEncoder()
        request.httpBody = try encoder.encode(requestBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AIError.generationFailed("Invalid response from Anthropic")
        }
        
        // Handle errors
        if httpResponse.statusCode != 200 {
            let decoder = JSONDecoder()
            if let errorResponse = try? decoder.decode(ErrorResponse.self, from: data) {
                throw AIError.generationFailed("Anthropic Error: \(errorResponse.error.message)")
            }
            throw AIError.generationFailed("Anthropic HTTP \(httpResponse.statusCode)")
        }
        
        // Parse success response
        let decoder = JSONDecoder()
        let message = try decoder.decode(MessageResponse.self, from: data)
        
        guard let firstContent = message.content.first else {
            throw AIError.generationFailed("No content in Anthropic response")
        }
        
        let text = firstContent.text
        let tokenCount = message.usage.inputTokens + message.usage.outputTokens
        
        return (text, tokenCount)
    }
}
