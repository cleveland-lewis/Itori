import Combine
import Foundation

/// Web-enhanced practice test generator that uses live Wikipedia research
@MainActor
final class WebEnhancedTestGenerator: ObservableObject {
    @Published var isGenerating: Bool = false
    @Published var currentPhase: GenerationPhase = .idle

    private let webSearchService: WebSearchService
    private let llmService: LocalLLMService

    enum GenerationPhase: String {
        case idle = "Idle"
        case extractingContent = "Extracting course content"
        case researchingTopics = "Researching topics online"
        case generatingQuestions = "Generating questions"
        case validating = "Validating questions"
        case complete = "Complete"
    }

    init(
        webSearchService: WebSearchService = .init(),
        llmService: LocalLLMService = .init()
    ) {
        self.webSearchService = webSearchService
        self.llmService = llmService
    }

    nonisolated init(useMockData _: Bool) {
        self.webSearchService = .init()
        self.llmService = .init()
    }

    nonisolated init(backend: LLMBackend) {
        self.webSearchService = .init()
        self.llmService = .init(backend: backend)
    }

    // MARK: - Main Generation Flow

    func generateTest(request: PracticeTestRequest) async -> Result<[PracticeQuestion], TestGenerationError> {
        isGenerating = true
        defer { isGenerating = false }

        // Phase 1: Extract course content
        currentPhase = .extractingContent
        let courseContext = await extractCourseContext(courseId: request.courseId)

        // Phase 2: Research topics using web search
        currentPhase = .researchingTopics
        let researchResult = await researchTopics(
            topics: request.topics,
            courseName: request.courseName,
            courseContext: courseContext
        )

        switch researchResult {
        case let .success(research):
            // Phase 3: Generate questions using templates + research
            currentPhase = .generatingQuestions
            let questionsResult = await generateQuestionsWithResearch(
                request: request,
                research: research,
                courseContext: courseContext
            )

            switch questionsResult {
            case let .success(questions):
                currentPhase = .complete
                return .success(questions)

            case let .failure(error):
                currentPhase = .idle
                return .failure(error)
            }

        case let .failure(error):
            currentPhase = .idle
            return .failure(error)
        }
    }

    // MARK: - Phase 1: Extract Course Content

    private func extractCourseContext(courseId: UUID) async -> CourseContext {
        // Get assignments and course details
        // Access stores through shared instances
        let assignments = await MainActor.run {
            AssignmentsStore.shared.tasks.filter { $0.courseId == courseId }
        }

        let course = await MainActor.run {
            CoursesStore.shared?.courses.first { $0.id == courseId }
        }

        return CourseContext(
            courseName: course?.title ?? "Unknown Course",
            courseCode: course?.code,
            assignmentTitles: assignments.map(\.title),
            assignmentDescriptions: assignments.compactMap(\.notes),
            topics: assignments.flatMap { task -> [String] in
                // Extract keywords from task titles and notes
                var topics: [String] = []
                if let notes = task.notes, !notes.isEmpty {
                    topics.append(notes)
                }
                topics.append(task.title)
                return topics
            }
        )
    }

    // MARK: - Phase 2: Research Topics

    private func researchTopics(
        topics: [String],
        courseName: String,
        courseContext: CourseContext
    ) async -> Result<TopicResearch, TestGenerationError> {
        do {
            // Use web search to research each topic
            var topicData: [String: ResearchedTopic] = [:]

            for topic in topics.isEmpty ? [courseName] : topics {
                let searchQuery = "\(topic) \(courseName) concepts definitions"
                let searchResult = try await webSearchService.search(query: searchQuery)

                // Parse research into structured data
                let researched = parseResearchResult(
                    topic: topic,
                    searchResult: searchResult,
                    courseContext: courseContext
                )

                topicData[topic] = researched
            }

            return .success(TopicResearch(topics: topicData))

        } catch {
            return .failure(.noInternetConnection(
                message: "Practice tests can only be generated when an active internet connection is available and live sources can be consulted."
            ))
        }
    }

    private func parseResearchResult(
        topic: String,
        searchResult: WebSearchResult,
        courseContext _: CourseContext
    ) -> ResearchedTopic {
        // Extract concepts, definitions, and related terms from search results
        var concepts: [String] = []
        var definitions: [String: String] = [:]
        var relatedTerms: [String] = []

        // Parse the search result content
        for result in searchResult.results {
            // Extract key concepts from titles and snippets
            let text = "\(result.title) \(result.snippet)"

            // Simple keyword extraction (could be enhanced)
            let words = text.components(separatedBy: CharacterSet.alphanumerics.inverted)
            let filteredWords = words.filter { $0.count > 3 }

            concepts.append(contentsOf: filteredWords.prefix(5))
        }

        return ResearchedTopic(
            name: topic,
            concepts: Array(Set(concepts)).prefix(10).map { String($0) },
            definitions: definitions,
            relatedTerms: relatedTerms,
            sourceUrls: searchResult.results.map(\.url)
        )
    }

    // MARK: - Phase 3: Generate Questions

    private func generateQuestionsWithResearch(
        request: PracticeTestRequest,
        research: TopicResearch,
        courseContext: CourseContext
    ) async -> Result<[PracticeQuestion], TestGenerationError> {
        currentPhase = .generatingQuestions

        do {
            // Build the generation prompt
            let prompt = buildGenerationPrompt(
                request: request,
                research: research,
                courseContext: courseContext
            )

            // Call LLM with the research-enhanced prompt
            let response = try await llmService.generateWithCustomPrompt(prompt)

            // Parse and validate questions
            let questions = try parseQuestions(from: response)

            currentPhase = .validating
            let validatedQuestions = validateQuestions(questions, request: request)

            if validatedQuestions.isEmpty {
                // Check if the issue is insufficient content
                let hasMinimalResearch = research.topics.values.contains { topic in
                    !topic.concepts.isEmpty || !topic.definitions.isEmpty
                }
                
                if !hasMinimalResearch {
                    return .failure(.validationFailed(
                        message: "Not enough course content available to generate test questions. Please add more assignments, notes, or course materials to enable test generation."
                    ))
                } else if questions.isEmpty {
                    return .failure(.validationFailed(
                        message: "The AI was unable to generate questions from the available content. Try adding more detailed course materials or assignment descriptions."
                    ))
                } else {
                    return .failure(.validationFailed(
                        message: "No valid questions could be generated from the available content. The generated questions did not meet quality standards."
                    ))
                }
            }

            return .success(validatedQuestions)

        } catch {
            return .failure(.llmError(message: error.localizedDescription))
        }
    }

    private func buildGenerationPrompt(
        request: PracticeTestRequest,
        research: TopicResearch,
        courseContext: CourseContext
    ) -> String {
        let currentDate = ISO8601DateFormatter().string(from: Date())

        return """
        # Role: Adaptive Practice Question Generator (Online Only)

        You are an AI that generates ORIGINAL practice questions using **Wikipedia as a concept source**, not as text to copy.

        ## Input Information

        ```json
        {
          "subject": "\(courseContext.courseName)",
          "topics": \(research.topics.keys.map { "\"\($0)\"" }),
          "level": "\(request.difficulty.rawValue.lowercased())",
          "num_questions": \(request.questionCount),
          "difficulty_profile": {
            "easy": 0.3,
            "medium": 0.5,
            "hard": 0.2
          }
        }
        ```

        <current_datetime>\(currentDate)</current_datetime>

        ## Course Context

        Course: \(courseContext.courseName)
        \(courseContext.courseCode.map { "Code: \($0)" } ?? "")

        Recent Assignments:
        \(courseContext.assignmentTitles.prefix(5).map { "- \($0)" }.joined(separator: "\n"))

        ## Researched Content

        \(research.topics.map { topic, data in
            """
            ### \(topic)
            Key Concepts: \(data.concepts.joined(separator: ", "))
            Related Terms: \(data.relatedTerms.joined(separator: ", "))
            """
        }.joined(separator: "\n\n"))

        ## Your Task

        Generate \(request.questionCount) ORIGINAL multiple-choice questions that:
        1. Test understanding of the researched concepts
        2. Use your own wording (never copy Wikipedia text)
        3. Include 4-5 answer options with one correct answer
        4. Provide clear explanations for the correct answer
        5. Match the specified difficulty distribution

        ## Output Format

        Return ONLY valid JSON in this exact format:

        ```json
        {
          "status": "success",
          "questions": [
            {
              "prompt": "Your original question here",
              "options": ["Option A", "Option B", "Option C", "Option D"],
              "correct_answer": "Option A",
              "explanation": "Why this answer is correct",
              "difficulty": "medium",
              "bloom_level": "Understand"
            }
          ]
        }
        ```

        If you cannot access the internet, return:
        ```json
        {
          "status": "error",
          "error_type": "no_internet",
          "message": "Practice tests can only be generated when an active internet connection is available."
        }
        ```
        """
    }

    private func parseQuestions(from response: String) throws -> [PracticeQuestion] {
        // Extract JSON from response (handle markdown code blocks)
        let jsonString = extractJSON(from: response)

        guard let data = jsonString.data(using: .utf8) else {
            throw TestGenerationError.parsingFailed(message: "Could not encode response as UTF-8")
        }

        let decoder = JSONDecoder()
        do {
            let response = try decoder.decode(QuestionGenerationResponse.self, from: data)

            if response.status == "error" {
                throw TestGenerationError.noInternetConnection(
                    message: response.message ?? "Unknown error"
                )
            }

            return response.questions?.map { dto in
                PracticeQuestion(
                    prompt: dto.prompt,
                    format: .multipleChoice,
                    options: dto.options,
                    correctAnswer: dto.correctAnswer,
                    explanation: dto.explanation,
                    bloomsLevel: dto.bloomLevel
                )
            } ?? []
        } catch let DecodingError.keyNotFound(key, context) {
            throw TestGenerationError.parsingFailed(
                message: "Missing required field '\(key.stringValue)' in LLM response. Path: \(context.codingPath.map(\.stringValue).joined(separator: "."))"
            )
        } catch let DecodingError.typeMismatch(type, context) {
            throw TestGenerationError.parsingFailed(
                message: "Type mismatch for '\(context.codingPath.last?.stringValue ?? "unknown")': expected \(type)"
            )
        } catch let DecodingError.valueNotFound(type, context) {
            throw TestGenerationError.parsingFailed(
                message: "Missing value for '\(context.codingPath.last?.stringValue ?? "unknown")' (expected \(type))"
            )
        } catch {
            throw TestGenerationError.parsingFailed(
                message: "Failed to parse LLM response: \(error.localizedDescription). Response preview: \(String(jsonString.prefix(200)))"
            )
        }
    }

    private func extractJSON(from text: String) -> String {
        // Remove markdown code blocks
        let pattern = "```json\\s*([\\s\\S]*?)```"
        if let regex = try? NSRegularExpression(pattern: pattern, options: []),
           let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
           let range = Range(match.range(at: 1), in: text)
        {
            return String(text[range])
        }

        // Try to find JSON object
        if let start = text.firstIndex(of: "{"),
           let end = text.lastIndex(of: "}")
        {
            return String(text[start ... end])
        }

        return text
    }

    private func validateQuestions(
        _ questions: [PracticeQuestion],
        request _: PracticeTestRequest
    ) -> [PracticeQuestion] {
        questions.filter { question in
            // Basic validation
            guard !question.prompt.isEmpty,
                  !question.correctAnswer.isEmpty,
                  !question.explanation.isEmpty
            else {
                return false
            }

            // Multiple choice must have options
            if question.format == .multipleChoice {
                guard let options = question.options,
                      options.count >= 2,
                      options.contains(question.correctAnswer)
                else {
                    return false
                }
            }

            return true
        }
    }
}

// MARK: - Supporting Types

struct CourseContext {
    let courseName: String
    let courseCode: String?
    let assignmentTitles: [String]
    let assignmentDescriptions: [String]
    let topics: [String]
}

struct TopicResearch {
    let topics: [String: ResearchedTopic]
}

struct ResearchedTopic {
    let name: String
    let concepts: [String]
    let definitions: [String: String]
    let relatedTerms: [String]
    let sourceUrls: [String]
}

struct WebSearchResult {
    let results: [SearchResult]
}

struct SearchResult {
    let title: String
    let url: String
    let snippet: String
}

enum TestGenerationError: Error, LocalizedError {
    case noInternetConnection(message: String)
    case llmError(message: String)
    case parsingFailed(message: String)
    case validationFailed(message: String)

    var errorDescription: String? {
        switch self {
        case let .noInternetConnection(msg): msg
        case let .llmError(msg): "LLM Error: \(msg)"
        case let .parsingFailed(msg): "Parsing Error: \(msg)"
        case let .validationFailed(msg): "Validation Error: \(msg)"
        }
    }
}

// MARK: - Response DTOs

struct QuestionGenerationResponse: Codable {
    let status: String
    let errorType: String?
    let message: String?
    let questions: [QuestionDTO]?

    enum CodingKeys: String, CodingKey {
        case status
        case errorType = "error_type"
        case message
        case questions
    }
}

struct QuestionDTO: Codable {
    let prompt: String
    let options: [String]
    let correctAnswer: String
    let explanation: String
    let difficulty: String
    let bloomLevel: String

    enum CodingKeys: String, CodingKey {
        case prompt
        case options
        case correctAnswer = "correct_answer"
        case explanation
        case difficulty
        case bloomLevel = "bloom_level"
    }
}
