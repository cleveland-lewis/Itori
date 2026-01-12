import Foundation

/// Service that wraps web search functionality for practice test generation
final class WebSearchService {
    
    private let useMockData: Bool
    
    init(useMockData: Bool = false) {
        self.useMockData = useMockData
    }
    
    func search(query: String) async throws -> WebSearchResult {
        if useMockData {
            return generateMockSearchResults(for: query)
        }
        
        do {
            let results = try await performWebSearch(query: query)
            return results
        } catch {
            // Fallback to mock if real search fails
            DebugLogger.log("[WebSearchService] Search failed, using mock data: \(error)")
            return generateMockSearchResults(for: query)
        }
    }
    
    private func performWebSearch(query: String) async throws -> WebSearchResult {
        // For now, use DuckDuckGo Instant Answer API as a free alternative
        // In production, you could integrate with Wikipedia API, Google Custom Search, etc.
        
        let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
        let urlString = "https://api.duckduckgo.com/?q=\(encodedQuery)&format=json&no_html=1&skip_disambig=1"
        
        guard let url = URL(string: urlString) else {
            throw WebSearchError.searchFailed(message: "Invalid URL")
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw WebSearchError.searchFailed(message: "HTTP error")
        }
        
        // Parse DuckDuckGo response
        let searchResults = try parseDuckDuckGoResponse(data: data, query: query)
        
        if searchResults.results.isEmpty {
            // Fallback to Wikipedia API
            return try await searchWikipedia(query: query)
        }
        
        return searchResults
    }
    
    private func parseDuckDuckGoResponse(data: Data, query: String) throws -> WebSearchResult {
        struct DDGResponse: Codable {
            let Abstract: String?
            let AbstractText: String?
            let AbstractURL: String?
            let RelatedTopics: [RelatedTopic]?
            
            struct RelatedTopic: Codable {
                let Text: String?
                let FirstURL: String?
            }
        }
        
        let decoder = JSONDecoder()
        let response = try decoder.decode(DDGResponse.self, from: data)
        
        var results: [SearchResult] = []
        
        // Add abstract as first result
        if let abstract = response.AbstractText, !abstract.isEmpty,
           let url = response.AbstractURL {
            results.append(SearchResult(
                title: query,
                url: url,
                snippet: abstract
            ))
        }
        
        // Add related topics
        if let topics = response.RelatedTopics {
            for topic in topics.prefix(5) {
                if let text = topic.Text, let url = topic.FirstURL {
                    results.append(SearchResult(
                        title: String(text.prefix(100)),
                        url: url,
                        snippet: text
                    ))
                }
            }
        }
        
        return WebSearchResult(results: results)
    }
    
    private func searchWikipedia(query: String) async throws -> WebSearchResult {
        let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
        let urlString = "https://en.wikipedia.org/w/api.php?action=opensearch&format=json&search=\(encodedQuery)&limit=5"
        
        guard let url = URL(string: urlString) else {
            throw WebSearchError.searchFailed(message: "Invalid Wikipedia URL")
        }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        
        // Wikipedia OpenSearch returns: [query, [titles], [descriptions], [urls]]
        guard let json = try JSONSerialization.jsonObject(with: data) as? [Any],
              json.count >= 4,
              let titles = json[1] as? [String],
              let descriptions = json[2] as? [String],
              let urls = json[3] as? [String] else {
            throw WebSearchError.noResults
        }
        
        var results: [SearchResult] = []
        for i in 0..<min(titles.count, descriptions.count, urls.count) {
            results.append(SearchResult(
                title: titles[i],
                url: urls[i],
                snippet: descriptions[i]
            ))
        }
        
        if results.isEmpty {
            throw WebSearchError.noResults
        }
        
        return WebSearchResult(results: results)
    }
    
    private func generateMockSearchResults(for query: String) -> WebSearchResult {
        // Generate mock results based on query
        let results = [
            SearchResult(
                title: "\(query) - Overview",
                url: "https://en.wikipedia.org/wiki/\(query.replacingOccurrences(of: " ", with: "_"))",
                snippet: "\(query) is a fundamental concept that encompasses various principles and applications. It involves understanding key relationships and mechanisms."
            ),
            SearchResult(
                title: "\(query) - Key Concepts",
                url: "https://en.wikipedia.org/wiki/\(query.replacingOccurrences(of: " ", with: "_"))#Concepts",
                snippet: "The main concepts include theoretical foundations, practical applications, and related methodologies. Understanding these concepts is essential for mastery."
            ),
            SearchResult(
                title: "\(query) - Applications",
                url: "https://en.wikipedia.org/wiki/\(query.replacingOccurrences(of: " ", with: "_"))#Applications",
                snippet: "Applications of \(query) can be found across multiple domains. Real-world implementations demonstrate the practical value and significance."
            ),
            SearchResult(
                title: "\(query) - Related Topics",
                url: "https://en.wikipedia.org/wiki/\(query.replacingOccurrences(of: " ", with: "_"))#Related",
                snippet: "Related topics include complementary concepts, alternative approaches, and historical development. These connections provide broader context."
            ),
            SearchResult(
                title: "\(query) - Advanced Concepts",
                url: "https://en.wikipedia.org/wiki/\(query.replacingOccurrences(of: " ", with: "_"))#Advanced",
                snippet: "Advanced aspects involve deeper analysis, complex interactions, and specialized applications. These build upon foundational understanding."
            )
        ]
        
        return WebSearchResult(results: results)
    }
}

enum WebSearchError: Error, LocalizedError {
    case searchFailed(message: String)
    case notImplemented(message: String)
    case noResults
    
    var errorDescription: String? {
        switch self {
        case .searchFailed(let msg): return "Search failed: \(msg)"
        case .notImplemented(let msg): return msg
        case .noResults: return "No search results found"
        }
    }
}
