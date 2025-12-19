import Foundation

/// OpenAI-compatible API backend (works with OpenAI, Azure OpenAI, local LM Studio, etc.)
class OpenAICompatibleBackend: LLMBackend {
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
            guard config.apiKey != nil || config.apiEndpoint?.contains("localhost") == true else {
                return false
            }
            
            // Try to ping the models endpoint
            guard let endpoint = config.apiEndpoint,
                  let url = URL(string: "\(endpoint)/models") else {
                return false
            }
            
            var request = URLRequest(url: url)
            if let apiKey = config.apiKey {
                request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
            }
            
            do {
                let (_, response) = try await session.data(for: request)
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
        guard let endpoint = config.apiEndpoint else {
            throw LLMBackendError.configurationError("API endpoint not configured")
        }
        
        guard let url = URL(string: "\(endpoint)/chat/completions") else {
            throw LLMBackendError.configurationError("Invalid API endpoint")
        }
        
        let messages: [[String: String]] = [
            ["role": "user", "content": prompt]
        ]
        
        let requestBody: [String: Any] = [
            "model": config.modelName,
            "messages": messages,
            "temperature": config.temperature,
            "max_tokens": config.maxTokens,
            "stream": false
        ]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let apiKey = config.apiKey {
            request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        }
        
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let startTime = Date()
        
        do {
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw LLMBackendError.networkError("Invalid response type")
            }
            
            guard httpResponse.statusCode == 200 else {
                let errorBody = String(data: data, encoding: .utf8) ?? "Unknown error"
                throw LLMBackendError.networkError("HTTP \(httpResponse.statusCode): \(errorBody)")
            }
            
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            
            guard let choices = json?["choices"] as? [[String: Any]],
                  let firstChoice = choices.first,
                  let message = firstChoice["message"] as? [String: Any],
                  let content = message["content"] as? String else {
                throw LLMBackendError.invalidResponse("Invalid OpenAI response format")
            }
            
            let usage = json?["usage"] as? [String: Any]
            let tokensUsed = usage?["total_tokens"] as? Int
            let finishReason = firstChoice["finish_reason"] as? String
            
            let latency = Date().timeIntervalSince(startTime) * 1000
            
            return LLMResponse(
                text: content,
                tokensUsed: tokensUsed,
                finishReason: finishReason,
                model: json?["model"] as? String ?? config.modelName,
                latencyMs: latency
            )
            
        } catch let error as LLMBackendError {
            throw error
        } catch {
            throw LLMBackendError.networkError(error.localizedDescription)
        }
    }
    
    func generateJSON(prompt: String, schema: String?) async throws -> String {
        // OpenAI supports JSON mode
        guard let endpoint = config.apiEndpoint else {
            throw LLMBackendError.configurationError("API endpoint not configured")
        }
        
        guard let url = URL(string: "\(endpoint)/chat/completions") else {
            throw LLMBackendError.configurationError("Invalid API endpoint")
        }
        
        let systemMessage = "You are a helpful assistant that responds only with valid JSON."
        let userPrompt = """
        \(prompt)
        
        Respond with ONLY valid JSON. No explanations, no markdown.
        """
        
        let messages: [[String: String]] = [
            ["role": "system", "content": systemMessage],
            ["role": "user", "content": userPrompt]
        ]
        
        var requestBody: [String: Any] = [
            "model": config.modelName,
            "messages": messages,
            "temperature": config.temperature,
            "max_tokens": config.maxTokens,
            "stream": false
        ]
        
        // Use JSON mode if supported (OpenAI GPT-4, GPT-3.5)
        if config.modelName.contains("gpt-4") || config.modelName.contains("gpt-3.5") {
            requestBody["response_format"] = ["type": "json_object"]
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let apiKey = config.apiKey {
            request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        }
        
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        do {
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw LLMBackendError.networkError("Invalid response type")
            }
            
            guard httpResponse.statusCode == 200 else {
                let errorBody = String(data: data, encoding: .utf8) ?? "Unknown error"
                throw LLMBackendError.networkError("HTTP \(httpResponse.statusCode): \(errorBody)")
            }
            
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            
            guard let choices = json?["choices"] as? [[String: Any]],
                  let firstChoice = choices.first,
                  let message = firstChoice["message"] as? [String: Any],
                  let content = message["content"] as? String else {
                throw LLMBackendError.invalidResponse("Invalid OpenAI response format")
            }
            
            return extractJSON(from: content)
            
        } catch let error as LLMBackendError {
            throw error
        } catch {
            throw LLMBackendError.networkError(error.localizedDescription)
        }
    }
    
    private func extractJSON(from text: String) -> String {
        var cleaned = text
        
        // Remove markdown code blocks
        if cleaned.contains("```json") {
            cleaned = cleaned.replacingOccurrences(of: "```json", with: "")
        }
        if cleaned.contains("```") {
            cleaned = cleaned.replacingOccurrences(of: "```", with: "")
        }
        
        // Find JSON boundaries
        if let firstBrace = cleaned.firstIndex(of: "{"),
           let lastBrace = cleaned.lastIndex(of: "}") {
            return String(cleaned[firstBrace...lastBrace])
        }
        
        return cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
