import Foundation

// MARK: - OpenAI API Client

/// OpenAI API client for chat completions
struct OpenAIClient {
    let apiKey: String
    let endpoint: String

    init(apiKey: String, endpoint: String? = nil) {
        self.apiKey = apiKey
        self.endpoint = endpoint ?? "https://api.openai.com/v1"
    }

    // MARK: - Request/Response Models

    struct ChatCompletionRequest: Codable {
        let model: String
        let messages: [Message]
        let temperature: Double
        let maxTokens: Int?
        let responseFormat: ResponseFormat?

        enum CodingKeys: String, CodingKey {
            case model
            case messages
            case temperature
            case maxTokens = "max_tokens"
            case responseFormat = "response_format"
        }

        struct Message: Codable {
            let role: String
            let content: String
        }

        struct ResponseFormat: Codable {
            let type: String
        }
    }

    struct ChatCompletionResponse: Codable {
        let id: String
        let object: String
        let created: Int
        let model: String
        let choices: [Choice]
        let usage: Usage?

        struct Choice: Codable {
            let index: Int
            let message: Message
            let finishReason: String?

            enum CodingKeys: String, CodingKey {
                case index
                case message
                case finishReason = "finish_reason"
            }

            struct Message: Codable {
                let role: String
                let content: String
            }
        }

        struct Usage: Codable {
            let promptTokens: Int
            let completionTokens: Int
            let totalTokens: Int

            enum CodingKeys: String, CodingKey {
                case promptTokens = "prompt_tokens"
                case completionTokens = "completion_tokens"
                case totalTokens = "total_tokens"
            }
        }
    }

    struct ErrorResponse: Codable {
        let error: ErrorDetail

        struct ErrorDetail: Codable {
            let message: String
            let type: String
            let code: String?
        }
    }

    // MARK: - API Methods

    func chatCompletion(
        prompt: String,
        temperature: Double,
        requireJSON: Bool
    ) async throws -> (text: String, tokenCount: Int) {
        let url = URL(string: "\(endpoint)/chat/completions")!

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let requestBody = ChatCompletionRequest(
            model: "gpt-4o-mini", // Default model
            messages: [
                ChatCompletionRequest.Message(role: "user", content: prompt)
            ],
            temperature: temperature,
            maxTokens: 4096,
            responseFormat: requireJSON ? ChatCompletionRequest.ResponseFormat(type: "json_object") : nil
        )

        let encoder = JSONEncoder()
        request.httpBody = try encoder.encode(requestBody)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw AIError.generationFailed("Invalid response from OpenAI")
        }

        // Handle errors
        if httpResponse.statusCode != 200 {
            let decoder = JSONDecoder()
            if let errorResponse = try? decoder.decode(ErrorResponse.self, from: data) {
                throw AIError.generationFailed("OpenAI Error: \(errorResponse.error.message)")
            }
            throw AIError.generationFailed("OpenAI HTTP \(httpResponse.statusCode)")
        }

        // Parse success response
        let decoder = JSONDecoder()
        let completion = try decoder.decode(ChatCompletionResponse.self, from: data)

        guard let firstChoice = completion.choices.first else {
            throw AIError.generationFailed("No choices in OpenAI response")
        }

        let text = firstChoice.message.content
        let tokenCount = completion.usage?.totalTokens ?? 0

        return (text, tokenCount)
    }
}
