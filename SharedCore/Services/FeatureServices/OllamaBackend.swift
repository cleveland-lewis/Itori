import Foundation

/// Ollama LLM backend implementation
class OllamaBackend: LLMBackend {
    let config: LLMBackendConfig
    private let session: URLSession
    
    init(config: LLMBackendConfig) {
        self.config = config
        
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = config.timeout
        configuration.timeoutIntervalForResource = config.timeout * 2
        self.session = URLSession(configuration: configuration)
    }
    
    var isAvailable: Bool {
        get async {
            guard let host = config.ollamaHost else { return false }
            
            // Check if Ollama is running
            guard let url = URL(string: "\(host)/api/tags") else { return false }
            
            do {
                let (_, response) = try await session.data(from: url)
                if let httpResponse = response as? HTTPURLResponse {
                    return httpResponse.statusCode == 200
                }
                return false
            } catch {
                return false
            }
        }
    }
    
    func generate(prompt: String) async throws -> LLMResponse {
        guard let host = config.ollamaHost else {
            throw LLMBackendError.configurationError("Ollama host not configured")
        }
        
        guard let url = URL(string: "\(host)/api/generate") else {
            throw LLMBackendError.configurationError("Invalid Ollama URL")
        }
        
        let requestBody: [String: Any] = [
            "model": config.modelName,
            "prompt": prompt,
            "stream": false,
            "options": [
                "temperature": config.temperature,
                "num_predict": config.maxTokens
            ]
        ]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let startTime = Date()
        
        do {
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw LLMBackendError.networkError("Invalid response type")
            }
            
            if httpResponse.statusCode == 404 {
                throw LLMBackendError.modelNotFound(config.modelName)
            }
            
            guard httpResponse.statusCode == 200 else {
                throw LLMBackendError.networkError("HTTP \(httpResponse.statusCode)")
            }
            
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            guard let responseText = json?["response"] as? String else {
                throw LLMBackendError.invalidResponse("Missing 'response' field")
            }
            
            let latency = Date().timeIntervalSince(startTime) * 1000
            
            return LLMResponse(
                text: responseText,
                tokensUsed: json?["eval_count"] as? Int,
                finishReason: json?["done"] as? Bool == true ? "stop" : nil,
                model: config.modelName,
                latencyMs: latency
            )
            
        } catch let error as LLMBackendError {
            throw error
        } catch {
            throw LLMBackendError.networkError(error.localizedDescription)
        }
    }
    
    func generateJSON(prompt: String, schema: String?) async throws -> String {
        let jsonPrompt = """
        \(prompt)
        
        IMPORTANT: You must respond with ONLY valid JSON. No explanations, no markdown, no code blocks.
        Start your response with { and end with }
        """
        
        let response = try await generate(prompt: jsonPrompt)
        return extractJSON(from: response.text)
    }
    
    private func extractJSON(from text: String) -> String {
        // Remove markdown code blocks if present
        var cleaned = text
        if cleaned.contains("```json") {
            cleaned = cleaned.replacingOccurrences(of: "```json", with: "")
        }
        if cleaned.contains("```") {
            cleaned = cleaned.replacingOccurrences(of: "```", with: "")
        }
        
        // Find first { and last }
        if let firstBrace = cleaned.firstIndex(of: "{"),
           let lastBrace = cleaned.lastIndex(of: "}") {
            return String(cleaned[firstBrace...lastBrace])
        }
        
        return cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
