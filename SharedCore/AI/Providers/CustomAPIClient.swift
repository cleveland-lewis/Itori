import Foundation

// MARK: - Custom API Client

/// Generic API client for custom OpenAI-compatible endpoints
/// Supports any API that follows the OpenAI chat completion format
struct CustomAPIClient {
    let apiKey: String
    let endpoint: String
    let model: String

    init(apiKey: String, endpoint: String, model: String = "default") {
        self.apiKey = apiKey
        self.endpoint = endpoint
        self.model = model
    }

    // MARK: - Request/Response Models

    struct ChatCompletionRequest: Codable {
        let model: String
        let messages: [Message]
        let temperature: Double
        let maxTokens: Int?

        enum CodingKeys: String, CodingKey {
            case model
            case messages
            case temperature
            case maxTokens = "max_tokens"
        }

        struct Message: Codable {
            let role: String
            let content: String
        }
    }

    struct ChatCompletionResponse: Codable {
        let id: String?
        let object: String?
        let created: Int?
        let model: String?
        let choices: [Choice]
        let usage: Usage?

        struct Choice: Codable {
            let index: Int?
            let message: Message?
            let finishReason: String?

            enum CodingKeys: String, CodingKey {
                case index
                case message
                case finishReason = "finish_reason"
            }

            struct Message: Codable {
                let role: String?
                let content: String
            }
        }

        struct Usage: Codable {
            let promptTokens: Int?
            let completionTokens: Int?
            let totalTokens: Int?

            enum CodingKeys: String, CodingKey {
                case promptTokens = "prompt_tokens"
                case completionTokens = "completion_tokens"
                case totalTokens = "total_tokens"
            }
        }
    }

    struct ErrorResponse: Codable {
        let error: ErrorDetail?
        let message: String?

        struct ErrorDetail: Codable {
            let message: String
            let type: String?
            let code: String?
        }
    }

    // MARK: - API Methods

    func chatCompletion(
        prompt: String,
        temperature: Double
    ) async throws -> (text: String, tokenCount: Int) {
        // Ensure endpoint has /chat/completions or use as-is
        let apiURL = if endpoint.hasSuffix("/chat/completions") {
            URL(string: endpoint)!
        } else if endpoint.hasSuffix("/v1") {
            URL(string: "\(endpoint)/chat/completions")!
        } else {
            // Assume endpoint is complete URL
            URL(string: endpoint)!
        }

        var request = URLRequest(url: apiURL)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 60

        let requestBody = ChatCompletionRequest(
            model: model,
            messages: [
                ChatCompletionRequest.Message(role: "user", content: prompt)
            ],
            temperature: temperature,
            maxTokens: 4096
        )

        let encoder = JSONEncoder()
        request.httpBody = try encoder.encode(requestBody)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw AIError.generationFailed("Invalid response from custom API")
        }

        // Handle errors
        if httpResponse.statusCode != 200 {
            let decoder = JSONDecoder()

            // Try to parse error response
            if let errorResponse = try? decoder.decode(ErrorResponse.self, from: data) {
                let errorMessage = errorResponse.error?.message ?? errorResponse.message ?? "Unknown error"
                throw AIError.generationFailed("Custom API Error: \(errorMessage)")
            }

            // If can't parse, return HTTP status
            throw AIError.generationFailed("Custom API HTTP \(httpResponse.statusCode)")
        }

        // Parse success response
        let decoder = JSONDecoder()
        let completion = try decoder.decode(ChatCompletionResponse.self, from: data)

        guard let firstChoice = completion.choices.first,
              let message = firstChoice.message
        else {
            throw AIError.generationFailed("No choices in custom API response")
        }

        let text = message.content
        let tokenCount = completion.usage?.totalTokens ?? 0

        return (text, tokenCount)
    }
}
