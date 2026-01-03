# Hybrid AI Architecture - Quick Reference

## Quick Start

### Basic Usage
```swift
// Simple generation
let result = try await AIRouter.shared.route(
    prompt: "Your prompt here",
    task: .textCompletion
)
print(result.text)
```

### Change AI Mode
```swift
AIRouter.shared.mode = .localOnly  // Offline mode
AIRouter.shared.mode = .auto       // Smart routing (default)
AIRouter.shared.mode = .appleOnly  // Apple Intelligence only
AIRouter.shared.mode = .byoOnly    // Your provider only
```

---

## AI Modes

| Mode | Network | Fallback | Use Case |
|------|---------|----------|----------|
| **Auto** | Optional | Yes | Recommended for most users |
| **Apple Only** | No | No | Maximum privacy |
| **Local Only** | No | No | Guaranteed offline |
| **BYO Only** | Yes | No | Advanced users |

---

## Provider Comparison

| Provider | Network | Size | Latency | Context | Tasks |
|----------|---------|------|---------|---------|-------|
| **Apple Intelligence** | No | 0 MB | 500ms | 8192 | Most |
| **Local macOS** | No | 800 MB | 1500ms | 4096 | All |
| **Local iOS** | No | 150 MB | 2000ms | 2048 | Core |
| **BYO (OpenAI)** | Yes | 0 MB | 2000ms | 100K+ | All |

---

## Task Types

```swift
public enum AITaskKind {
    case intentToAction      // Parse intent → JSON
    case summarize          // Summarize text
    case rewrite            // Improve text
    case studyQuestionGen   // Generate questions
    case textCompletion     // General completion
    case chat               // Conversational
}
```

**Recommended Providers by Task**:
- **Intent Parsing**: Apple Intelligence > Local (both platforms)
- **Summarization**: Apple Intelligence > Local macOS > BYO
- **Study Questions**: Apple Intelligence > Local macOS > BYO
- **Chat**: Apple Intelligence > BYO

---

## Error Handling

```swift
do {
    let result = try await AIRouter.shared.route(...)
} catch AIError.providerUnavailable(let name) {
    print("Provider \(name) not available")
} catch AIError.modelNotDownloaded {
    print("Download local model first")
} catch AIError.networkRequired {
    print("This mode requires network")
} catch {
    print("Generation failed: \(error)")
}
```

---

## Local Model Management

### Download Model
```swift
// Check if downloaded
let isDownloaded = LocalModelManager.shared.isModelDownloaded(.macOSStandard)

// Download
if !isDownloaded {
    try await LocalModelManager.shared.downloadModel(.macOSStandard)
}
```

### Monitor Progress
```swift
let progress = LocalModelManager.shared.downloadProgress(.macOSStandard)
// Returns 0.0 to 1.0
```

### Delete Model
```swift
try LocalModelManager.shared.deleteModel(.iOSLite)
```

---

## BYO Provider Setup

```swift
// 1. Create provider
let provider = BYOProvider(
    type: .openai,
    apiKey: "sk-your-key-here",
    endpoint: nil  // Use default
)

// 2. Register
AIRouter.shared.registerBYOProvider(provider)

// 3. Switch mode (optional)
AIRouter.shared.mode = .byoOnly

// 4. Use normally
let result = try await AIRouter.shared.route(...)
```

---

## Offline-Only Requests

```swift
// Force offline processing
let result = try await AIRouter.shared.route(
    prompt: "Your prompt",
    task: .intentToAction,
    requireOffline: true  // ← Enforces no network
)
```

**What happens**:
- `requireOffline: true` → Only Apple Intelligence or Local models
- BYO provider **never used** even if configured
- Throws error if no offline provider available

---

## Structured Output (JSON)

```swift
let schema = [
    "type": "object",
    "properties": [
        "action": ["type": "string"],
        "entity": ["type": "string"],
        "time": ["type": "string"]
    ],
    "required": ["action", "entity"]
]

let result = try await AIRouter.shared.route(
    prompt: "Parse: 'Add homework due Friday'",
    task: .intentToAction,
    schema: schema
)

if let data = result.structuredData {
    let action = data["action"] as? String
    let entity = data["entity"] as? String
}
```

---

## Observability

### View Routing Log
```swift
let events = AIRouter.shared.getRoutingLog()

for event in events {
    print("\(event.provider) - \(event.task) (\(event.latencyMs)ms)")
}
```

### Check Provider Availability
```swift
let availability = await AIRouter.shared.getAvailableProviders()
// Returns: ["apple": Bool, "local-macos": Bool, "byo": Bool]
```

### Clear Logs
```swift
AIRouter.shared.clearRoutingLog()
```

---

## Platform-Specific Code

### Check Current Platform Model
```swift
#if os(macOS)
let modelType = LocalModelType.macOSStandard
let expectedSize = "800 MB"
#else
let modelType = LocalModelType.iOSLite
let expectedSize = "150 MB"
#endif
```

### Platform Capabilities
```swift
#if os(macOS)
// macOS: Full capabilities
// - All task types
// - Deep reasoning
// - Study question generation
#else
// iOS/iPadOS: Core capabilities
// - Intent parsing (primary)
// - Basic summarization
// - Simple rewriting
// - Limited context
#endif
```

---

## Debugging

### Enable Debug Logging
```swift
// In DEBUG builds, routing decisions are automatically logged:
// 🤖 AI Router: Apple Intelligence - Intent Parsing (450ms) - ✅
```

### Check Why Provider Failed
```swift
let availability = AppleIntelligenceProvider.availability()
print(availability.reason)
// "Apple Intelligence not available on this device"
// "Requires iOS 18+ / macOS 15+"
```

---

## Common Patterns

### Retry with Fallback
```swift
do {
    // Try preferred provider
    AIRouter.shared.mode = .appleOnly
    return try await AIRouter.shared.route(...)
} catch {
    // Fall back to local
    AIRouter.shared.mode = .localOnly
    return try await AIRouter.shared.route(...)
}
```

### Check Before Request
```swift
let availability = await AIRouter.shared.getAvailableProviders()

if availability["apple"] == true {
    AIRouter.shared.mode = .appleOnly
} else if availability["local-macos"] == true {
    AIRouter.shared.mode = .localOnly
} else {
    // Show download prompt
}
```

### Batch Requests
```swift
let prompts = ["Prompt 1", "Prompt 2", "Prompt 3"]

let results = try await withThrowingTaskGroup(
    of: AIProviderResult.self
) { group in
    for prompt in prompts {
        group.addTask {
            try await AIRouter.shared.route(
                prompt: prompt,
                task: .summarize
            )
        }
    }
    
    var results: [AIProviderResult] = []
    for try await result in group {
        results.append(result)
    }
    return results
}
```

---

## Performance Tips

### 1. Use Appropriate Task Types
```swift
// ❌ Don't use .chat for structured data
AIRouter.shared.route(prompt: jsonPrompt, task: .chat)

// ✅ Use .intentToAction with schema
AIRouter.shared.route(prompt: jsonPrompt, task: .intentToAction, schema: schema)
```

### 2. Cache Results When Possible
```swift
private var cache: [String: AIProviderResult] = [:]

func getCached(prompt: String) async throws -> AIProviderResult {
    if let cached = cache[prompt] {
        return cached
    }
    
    let result = try await AIRouter.shared.route(prompt: prompt, task: .summarize)
    cache[prompt] = result
    return result
}
```

### 3. Use Lower Temperature for Deterministic Tasks
```swift
// Temperature is automatically set based on task:
// - intentToAction: 0.0 (deterministic)
// - summarize: 0.3 (focused)
// - rewrite: 0.5 (balanced)
// - studyQuestionGen: 0.7 (creative)
```

---

## Troubleshooting

### "Provider not available"
**Solutions**:
1. Check mode matches available providers
2. Download local model if using Local mode
3. Verify Apple Intelligence requirements (iOS 18+/macOS 15+)
4. Test BYO provider connection

### "Model not downloaded"
**Solutions**:
1. Download model: `LocalModelManager.shared.downloadModel()`
2. Check storage space
3. Verify network during download
4. Switch to Auto mode for fallback

### "Network required"
**Solutions**:
1. You're in BYO mode without network
2. Switch to Local-only mode for offline
3. Download local model first

### Slow Performance
**Check**:
1. Which provider is being used (check logs)
2. Is local model loaded in memory?
3. Network latency if using BYO
4. Task complexity vs provider capability

---

## API Reference

### AIRouter
```swift
@MainActor public final class AIRouter {
    public static let shared: AIRouter
    public var mode: AIMode
    
    func route(
        prompt: String,
        task: AITaskKind,
        schema: [String: Any]? = nil,
        requireOffline: Bool = false
    ) async throws -> AIProviderResult
    
    func registerBYOProvider(_ provider: AIProvider)
    func removeBYOProvider()
    func getRoutingLog() -> [RoutingEvent]
    func clearRoutingLog()
    func getAvailableProviders() async -> [String: Bool]
}
```

### LocalModelManager
```swift
@MainActor public final class LocalModelManager {
    public static let shared: LocalModelManager
    
    func isModelDownloaded(_ type: LocalModelType) -> Bool
    func isDownloading(_ type: LocalModelType) -> Bool
    func downloadProgress(_ type: LocalModelType) -> Double
    func downloadModel(_ type: LocalModelType) async throws
    func cancelDownload(_ type: LocalModelType)
    func deleteModel(_ type: LocalModelType) throws
    func getModelURL(_ type: LocalModelType) throws -> URL
    func totalDownloadedSize() -> Int64
}
```

---

## Constants

### Model Sizes
```swift
LocalModelType.macOSStandard.estimatedSizeBytes  // 838,860,800 (800 MB)
LocalModelType.iOSLite.estimatedSizeBytes        // 157,286,400 (150 MB)
```

### Context Lengths
```swift
Apple Intelligence: 8,192 tokens
Local macOS: 4,096 tokens
Local iOS: 2,048 tokens
BYO (OpenAI): 100,000+ tokens
```

---

**Version**: 1.0  
**Last Updated**: 2026-01-03  
**Platforms**: macOS 14.0+, iOS 17.0+, iPadOS 17.0+
