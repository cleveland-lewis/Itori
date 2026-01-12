#!/usr/bin/env swift

import Foundation

// Test script for Web-Enhanced Practice Test Generation
// This simulates the full workflow: course setup → test generation → test taking

print("=== Practice Test Generation & Evaluation ===\n")

// MARK: - Test Configuration

struct TestScenario {
    let courseName: String
    let courseCode: String
    let topics: [String]
    let difficulty: String
    let questionCount: Int
}

let testScenarios: [TestScenario] = [
    TestScenario(
        courseName: "Cognitive Psychology",
        courseCode: "PSY301",
        topics: ["Memory Formation", "Cognitive Biases", "Neural Plasticity"],
        difficulty: "medium",
        questionCount: 5
    ),
    TestScenario(
        courseName: "Data Structures and Algorithms",
        courseCode: "CS202",
        topics: ["Binary Trees", "Graph Algorithms", "Dynamic Programming"],
        difficulty: "hard",
        questionCount: 5
    ),
    TestScenario(
        courseName: "World History",
        courseCode: "HIST101",
        topics: ["Industrial Revolution", "Cold War", "Renaissance"],
        difficulty: "easy",
        questionCount: 5
    )
]

// MARK: - Web Search Simulation

func searchWikipedia(query: String) async throws -> [String: Any] {
    let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
    let urlString = "https://en.wikipedia.org/w/api.php?action=opensearch&format=json&search=\(encodedQuery)&limit=3"

    guard let url = URL(string: urlString) else {
        throw NSError(domain: "Invalid URL", code: -1)
    }

    let (data, _) = try await URLSession.shared.data(from: url)
    let json = try JSONSerialization.jsonObject(with: data) as! [Any]

    guard json.count >= 4,
          let titles = json[1] as? [String],
          let descriptions = json[2] as? [String],
          let urls = json[3] as? [String]
    else {
        throw NSError(domain: "Invalid response", code: -1)
    }

    return [
        "titles": titles,
        "descriptions": descriptions,
        "urls": urls
    ]
}

// MARK: - Test Generation

func generatePracticeTest(scenario: TestScenario) async throws -> [String: Any] {
    print("📚 Generating practice test for: \(scenario.courseName)")
    print("   Topics: \(scenario.topics.joined(separator: ", "))")
    print("   Difficulty: \(scenario.difficulty)")
    print("   Questions: \(scenario.questionCount)\n")

    // Phase 1: Research Topics
    print("🔍 Phase 1: Researching topics via Wikipedia...")
    var researchedContent: [[String: Any]] = []

    for topic in scenario.topics {
        let query = "\(topic) \(scenario.courseName)"
        print("   Searching: \"\(query)\"")

        do {
            let results = try await searchWikipedia(query: query)
            if let titles = results["titles"] as? [String],
               let descriptions = results["descriptions"] as? [String],
               !titles.isEmpty
            {
                print("   ✓ Found \(titles.count) results")
                researchedContent.append([
                    "topic": topic,
                    "titles": titles,
                    "descriptions": descriptions
                ])
            } else {
                print("   ⚠️ No results, using topic as-is")
                researchedContent.append(["topic": topic, "titles": [topic], "descriptions": [""]])
            }
        } catch {
            print("   ⚠️ Search failed: \(error.localizedDescription)")
            researchedContent.append(["topic": topic, "titles": [topic], "descriptions": [""]])
        }

        // Rate limiting
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
    }

    print("\n✅ Research complete. Found content for \(researchedContent.count) topics\n")

    // Phase 2: Build prompt and simulate generation
    print("🤖 Phase 2: Generating questions with LLM...")

    let generatedTest: [String: Any] = [
        "courseName": scenario.courseName,
        "courseCode": scenario.courseCode,
        "topics": scenario.topics,
        "difficulty": scenario.difficulty,
        "questionCount": scenario.questionCount,
        "researchedContent": researchedContent,
        "questions": generateMockQuestions(scenario: scenario, research: researchedContent)
    ]

    print("✅ Generated \(scenario.questionCount) questions\n")

    return generatedTest
}

func generateMockQuestions(scenario: TestScenario, research: [[String: Any]]) -> [[String: Any]] {
    var questions: [[String: Any]] = []

    for i in 0 ..< scenario.questionCount {
        let topicIndex = i % scenario.topics.count
        let topic = scenario.topics[topicIndex]
        let researchData = research[topicIndex]

        let question: [String: Any] = [
            "id": i + 1,
            "prompt": "What is a fundamental concept related to \(topic) in the context of \(scenario.courseName)?",
            "options": [
                "Core principle that forms the foundation of \(topic)",
                "A superficial aspect with minimal significance",
                "An unrelated concept from a different field",
                "A deprecated approach no longer used"
            ],
            "correctAnswer": "Core principle that forms the foundation of \(topic)",
            "explanation": "This concept is central to understanding \(topic) as it relates to \(scenario.courseName). Research from Wikipedia shows this is a key area of study.",
            "difficulty": scenario.difficulty,
            "bloomLevel": "Understand",
            "topic": topic,
            "researchSources": researchData["titles"] as? [String] ?? []
        ]

        questions.append(question)
    }

    return questions
}

// MARK: - Test Taking Simulation

func takeTest(test: [String: Any]) -> [String: Any] {
    print("📝 Taking the test...\n")

    guard let questions = test["questions"] as? [[String: Any]] else {
        return ["error": "Invalid test format"]
    }

    var userAnswers: [[String: Any]] = []
    var correctCount = 0

    for (index, question) in questions.enumerated() {
        let questionNum = index + 1
        let prompt = question["prompt"] as? String ?? ""
        let options = question["options"] as? [String] ?? []
        let correctAnswer = question["correctAnswer"] as? String ?? ""
        let explanation = question["explanation"] as? String ?? ""
        let topic = question["topic"] as? String ?? ""

        print("Question \(questionNum): \(prompt)")
        print("Topic: \(topic)\n")

        for (optionIndex, option) in options.enumerated() {
            let letter = ["A", "B", "C", "D"][optionIndex]
            print("   \(letter). \(option)")
        }

        // Simulate choosing answer (for testing, we'll pick correctly 70% of the time)
        let willAnswerCorrectly = Double.random(in: 0 ... 1) < 0.7
        let selectedAnswer = willAnswerCorrectly ? correctAnswer : options.randomElement()!
        let isCorrect = selectedAnswer == correctAnswer

        if isCorrect {
            correctCount += 1
        }

        print("\n   Selected: \(selectedAnswer)")
        print("   \(isCorrect ? "✅ Correct!" : "❌ Incorrect")")

        if !isCorrect {
            print("   Correct answer: \(correctAnswer)")
        }

        print("   Explanation: \(explanation)")
        print("\n" + String(repeating: "-", count: 80) + "\n")

        userAnswers.append([
            "questionId": questionNum,
            "selectedAnswer": selectedAnswer,
            "correctAnswer": correctAnswer,
            "isCorrect": isCorrect,
            "topic": topic
        ])
    }

    return [
        "totalQuestions": questions.count,
        "correctCount": correctCount,
        "score": Double(correctCount) / Double(questions.count) * 100.0,
        "userAnswers": userAnswers
    ]
}

// MARK: - Quality Evaluation

func evaluateTestQuality(test: [String: Any]) -> [String: Any] {
    print("📊 Evaluating Test Quality...\n")

    guard let questions = test["questions"] as? [[String: Any]] else {
        return ["error": "Invalid test"]
    }

    var metrics: [String: Any] = [:]

    // 1. Check if questions are diverse
    let topics = questions.compactMap { $0["topic"] as? String }
    let uniqueTopics = Set(topics).count
    metrics["topicDiversity"] = Double(uniqueTopics) / Double(max(topics.count, 1))

    // 2. Check if research was used
    let withResearch = questions.filter { question in
        if let sources = question["researchSources"] as? [String] {
            return !sources.isEmpty
        }
        return false
    }.count
    metrics["researchCoverage"] = Double(withResearch) / Double(questions.count)

    // 3. Check question complexity
    let avgPromptLength = questions.map { ($0["prompt"] as? String ?? "").count }.reduce(0, +) / questions.count
    metrics["avgPromptLength"] = avgPromptLength

    // 4. Check if explanations are provided
    let withExplanations = questions.filter { !($0["explanation"] as? String ?? "").isEmpty }.count
    metrics["explanationCoverage"] = Double(withExplanations) / Double(questions.count)

    return metrics
}

// MARK: - Main Test Execution

Task {
    print("Starting Practice Test System Evaluation")
    print("Date: \(Date())")
    print("\n" + String(repeating: "=", count: 80) + "\n")

    for (index, scenario) in testScenarios.enumerated() {
        print("\n" + String(repeating: "=", count: 80))
        print("TEST SCENARIO \(index + 1)/\(testScenarios.count)")
        print(String(repeating: "=", count: 80) + "\n")

        do {
            // Generate test
            let test = try await generatePracticeTest(scenario: scenario)

            // Evaluate quality
            let quality = evaluateTestQuality(test: test)
            print("Quality Metrics:")
            print("   Topic Diversity: \(String(format: "%.1f%%", (quality["topicDiversity"] as? Double ?? 0) * 100))")
            print(
                "   Research Coverage: \(String(format: "%.1f%%", (quality["researchCoverage"] as? Double ?? 0) * 100))"
            )
            print("   Avg Prompt Length: \(quality["avgPromptLength"] ?? 0) characters")
            print(
                "   Explanation Coverage: \(String(format: "%.1f%%", (quality["explanationCoverage"] as? Double ?? 0) * 100))"
            )
            print("\n" + String(repeating: "-", count: 80) + "\n")

            // Take test
            let results = takeTest(test: test)

            // Display results
            print("\n📈 Test Results Summary")
            print("   Total Questions: \(results["totalQuestions"] ?? 0)")
            print("   Correct Answers: \(results["correctCount"] ?? 0)")
            print("   Score: \(String(format: "%.1f%%", results["score"] as? Double ?? 0))")

            print("\n✅ Test scenario completed successfully")

        } catch {
            print("❌ Error: \(error.localizedDescription)")
        }

        print("\n")
    }

    print(String(repeating: "=", count: 80))
    print("EVALUATION COMPLETE")
    print(String(repeating: "=", count: 80))

    exit(0)
}

dispatchMain()
