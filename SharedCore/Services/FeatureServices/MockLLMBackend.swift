import Foundation

/// Mock LLM backend for testing and development
class MockLLMBackend: LLMBackend {
    let config: LLMBackendConfig
    private let delay: TimeInterval
    
    init(config: LLMBackendConfig = .mockConfig, delay: TimeInterval = 0.5) {
        self.config = config
        self.delay = delay
    }
    
    var isAvailable: Bool {
        get async { true }
    }
    
    func generate(prompt: String) async throws -> LLMResponse {
        try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
        
        // Generate mock response based on prompt content
        let response = generateMockResponse(for: prompt)
        
        return LLMResponse(
            text: response,
            tokensUsed: response.components(separatedBy: .whitespaces).count,
            finishReason: "stop",
            model: config.modelName,
            latencyMs: delay * 1000
        )
    }
    
    func generateJSON(prompt: String, schema: String?) async throws -> String {
        try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
        
        // Extract slot information from prompt if present
        if prompt.contains("Topic:") {
            return generateSlotJSON(from: prompt)
        }
        
        // Generic mock JSON
        return """
        {
            "response": "This is a mock JSON response",
            "status": "success"
        }
        """
    }
    
    private func generateMockResponse(for prompt: String) -> String {
        if prompt.contains("Generate ONE multiple-choice question") {
            return "This is a mock response to a question generation request."
        }
        
        if prompt.contains("practice test") || prompt.contains("questions") {
            return "Mock response: Here are some practice questions based on your request."
        }
        
        return "Mock LLM response for: \(prompt.prefix(50))..."
    }
    
    private func generateSlotJSON(from prompt: String) -> String {
        // Parse slot requirements from prompt
        var topic = "General Topic"
        var difficulty = "Medium"
        var bloomLevel = "Understand"
        var templateType = "concept_id"
        
        // Extract values
        if let topicRange = prompt.range(of: "Topic: ([^\n]+)", options: .regularExpression) {
            topic = String(prompt[topicRange]).replacingOccurrences(of: "Topic: ", with: "")
        }
        if let diffRange = prompt.range(of: "Difficulty: ([^\n]+)", options: .regularExpression) {
            difficulty = String(prompt[diffRange]).replacingOccurrences(of: "Difficulty: ", with: "")
        }
        if let bloomRange = prompt.range(of: "Bloom's Level: ([^\n]+)", options: .regularExpression) {
            bloomLevel = String(prompt[bloomRange]).replacingOccurrences(of: "Bloom's Level: ", with: "")
        }
        if let templateRange = prompt.range(of: "Template Type: ([^\n]+)", options: .regularExpression) {
            templateType = String(prompt[templateRange]).replacingOccurrences(of: "Template Type: ", with: "")
        }
        
        // Generate appropriate question based on template
        let (questionPrompt, choices) = generateQuestionForTemplate(
            topic: topic,
            difficulty: difficulty,
            bloomLevel: bloomLevel,
            templateType: templateType
        )
        
        let correctIndex = Int.random(in: 0...4)
        
        return """
        {
            "prompt": "\(questionPrompt)",
            "choices": ["\(choices[0])", "\(choices[1])", "\(choices[2])", "\(choices[3])"],
            "correctAnswer": "\(choices[correctIndex])",
            "correctIndex": \(correctIndex),
            "rationale": "This is the correct answer because it accurately reflects the principles of \(topic) at the \(bloomLevel) cognitive level. The other options either misrepresent the concept or present incorrect applications.",
            "topic": "\(topic)",
            "bloomLevel": "\(bloomLevel)",
            "difficulty": "\(difficulty)",
            "templateType": "\(templateType)"
        }
        """
    }
    
    private func generateQuestionForTemplate(
        topic: String,
        difficulty: String,
        bloomLevel: String,
        templateType: String
    ) -> (prompt: String, choices: [String]) {
        let prompt: String
        let choices: [String]
        
        switch templateType {
        case "concept_id", "concept_identification":
            prompt = "Which statement best identifies the core concept of \(topic)?"
            choices = [
                "A fundamental principle that forms the basis of \(topic)",
                "An advanced technique used only in specialized applications",
                "A deprecated approach that is no longer recommended",
                "An alternative methodology with limited practical use",
                "A foundational idea that connects \(topic) to broader theories"
            ]
            
        case "cause_effect":
            prompt = "What is the primary effect when applying \(topic) principles?"
            choices = [
                "Enhanced understanding and practical application capabilities",
                "Reduced flexibility in problem-solving approaches",
                "Increased complexity without tangible benefits",
                "Limited applicability to real-world scenarios",
                "Improved consistency in results across similar scenarios"
            ]
            
        case "scenario_change":
            prompt = "How would the outcome change if \(topic) principles were applied differently?"
            choices = [
                "The results would align more closely with theoretical expectations",
                "The system would become less predictable and harder to control",
                "There would be no significant change in outcomes",
                "The approach would contradict established best practices",
                "The conclusions would shift toward alternative interpretations"
            ]
            
        case "data_interpretation":
            prompt = "When analyzing data related to \(topic), which interpretation is most accurate?"
            choices = [
                "The data demonstrates clear patterns consistent with \(topic) theory",
                "The data shows inconsistencies that contradict current understanding",
                "The data is insufficient to draw meaningful conclusions",
                "The data supports alternative explanations over \(topic)",
                "The data indicates a partial alignment with \(topic)"
            ]
            
        case "compare_contrast":
            prompt = "How does \(topic) compare to related concepts in the field?"
            choices = [
                "\(topic) provides unique insights while building on foundational concepts",
                "\(topic) completely replaces all previous approaches",
                "\(topic) is largely redundant with existing methods",
                "\(topic) contradicts most established principles",
                "\(topic) complements related approaches without replacing them"
            ]
            
        default:
            prompt = "What is a key aspect of \(topic)?"
            choices = [
                "It represents an important concept in the field",
                "It is rarely used in practice",
                "It has been completely superseded",
                "It only applies in theoretical contexts",
                "It offers practical guidance for applied problems"
            ]
        }
        
        return (prompt, choices)
    }
}
