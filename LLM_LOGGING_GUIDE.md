# LLM Feature Usage - Developer Console Logging Guide

## Overview
Comprehensive logging for all LLM/AI feature usage in the app when Developer Mode is enabled.

## How to Enable

**Settings → Developer → Enable Developer Mode + Data Logging**

All LLM logs use the category **"LLM"** for easy filtering.

## Log Events

### 1️⃣ LLM Request Started (Normal Flow)

```
LOG: 🤖 Starting LLM request
  provider: OpenAI | Anthropic | LocalLLM | etc
  port: assignmentParser | questionGenerator | etc
  trigger: <UUID> (request ID)
  privacy: normal | redacted | anonymous
  inputSize: 1234 bytes
  timestamp: 2026-01-04 00:05:23
```

**What this means:**
- User triggered an AI feature
- LLM provider is about to be called
- Network request will be made (unless local)

### 2️⃣ LLM Request Completed Successfully

```
LOG: ✅ LLM request completed
  provider: OpenAI
  port: assignmentParser
  duration: 2.347s
  outputSize: 892 bytes
  modelUsed: gpt-4
  tokensUsed: 245
  success: true
```

**What this means:**
- LLM call succeeded
- Shows actual model used (may differ from requested)
- Token usage for billing/quota tracking
- Response time for performance monitoring

### 3️⃣ Output Preview (Debug Level)

```
LOG: Output preview
  provider: OpenAI
  preview: {"assignments":[{"title":"Math Homework","dueDate":"2026-01-10","category":"homework"}],"confidence":0.95}...
```

**What this means:**
- First 200 characters of LLM output
- Useful for debugging parsing issues
- Only shown at DEBUG log level

### 4️⃣ LLM Request Failed

```
LOG: ❌ LLM request failed
  provider: OpenAI
  port: assignmentParser
  duration: 5.023s
  error: Network timeout
  willRetry: false
```

**What this means:**
- LLM call failed (network, API error, timeout)
- Provider marked as unreliable
- Will fallback to deterministic algorithm

### 5️⃣ LLM Disabled - Using Fallback

```
LOG: 🚫 LLM assistance disabled - using fallback only
  port: assignmentParser
  trigger: <UUID>
  reason: user_setting_disabled
  
LOG: Fallback completed (LLM disabled)
  port: assignmentParser
  duration: 0.023s
```

**What this means:**
- User has LLM assistance turned OFF in settings
- Using deterministic algorithm instead
- No network calls made
- Much faster (no API latency)

### 6️⃣ Fallback Strategy (Realtime Ports)

```
LOG: 🔄 Using deterministic fallback (no LLM)
  port: realtimeParser
  reason: fallback-first strategy
  trigger: <UUID>

LOG: Fallback completed
  port: realtimeParser
  duration: 0.015s
  deterministic: true
```

**What this means:**
- Port is configured for fallback-first
- Prioritizes speed over AI enhancement
- Used for realtime features (autocomplete, etc)

### 7️⃣ No Fallback Available (Error)

```
LOG: ❌ No fallback available for port
  port: imageAnalysis
  supportsFallback: false
```

**What this means:**
- LLM is disabled but port requires AI
- Feature will not work without LLM
- User needs to enable LLM assistance

## Complete Flow Examples

### Example 1: Parse Syllabus with LLM Enabled

```
1. 🤖 Starting LLM request
   provider: OpenAI
   port: syllabusParser
   inputSize: 15234 bytes (PDF text)
   
2. ✅ LLM request completed
   duration: 3.452s
   outputSize: 2341 bytes
   modelUsed: gpt-4-turbo
   tokensUsed: 3421
   
3. Output preview
   preview: {"course":"MATH 101","assignments":[...],"schedule":[...]}
```

### Example 2: Parse Syllabus with LLM Disabled

```
1. 🚫 LLM assistance disabled - using fallback only
   port: syllabusParser
   reason: user_setting_disabled
   
2. Fallback completed (LLM disabled)
   duration: 0.234s
   
Result: Deterministic parser used (regex-based)
```

### Example 3: LLM Request Fails, Falls Back

```
1. �� Starting LLM request
   provider: Anthropic
   port: questionGenerator
   
2. ❌ LLM request failed
   error: API rate limit exceeded
   duration: 0.523s
   
3. 🔄 Using deterministic fallback (no LLM)
   reason: provider failed
   
4. Fallback completed
   duration: 0.089s
```

## What Each Port Does

| Port ID | Feature | What it does |
|---------|---------|--------------|
| `assignmentParser` | Parse syllabus text | Extracts assignments from PDFs/text |
| `questionGenerator` | Generate test questions | Creates practice questions from content |
| `flashcardGenerator` | Generate flashcards | Creates study flashcards |
| `summaryGenerator` | Summarize text | Creates summaries of readings |
| `scheduleOptimizer` | Optimize study schedule | AI-enhanced scheduling |

## Privacy Levels

| Level | Description | What's sent to LLM |
|-------|-------------|-------------------|
| `normal` | Default | Full content with redaction policy |
| `redacted` | Sensitive content removed | PII stripped before sending |
| `anonymous` | Maximum privacy | Fully anonymized data only |

## Provider Types

| Provider | Description | Notes |
|----------|-------------|-------|
| `OpenAI` | ChatGPT/GPT-4 | Cloud-based, requires API key |
| `Anthropic` | Claude | Cloud-based, requires API key |
| `LocalLLM` | On-device | MLX models, no network |
| `Ollama` | Local server | Self-hosted, localhost |

## Performance Benchmarks

**Expected durations:**
- LLM requests: 1-5 seconds (network + inference)
- Fallback: 0.01-0.5 seconds (local computation)
- Local LLM: 2-10 seconds (on-device inference)

**If you see:**
- `duration > 10s` → Check network/API status
- `duration > 30s` → Timeout likely, check logs for error

## Debugging Scenarios

### Scenario 1: Feature Not Working

**Check logs for:**
```
🚫 LLM assistance disabled → User needs to enable in Settings
❌ No fallback available → Feature requires LLM
❌ LLM request failed → Provider issue
```

### Scenario 2: Slow Performance

**Check logs for:**
```
duration: 15.234s → API slow, consider timeout adjustment
provider: OpenAI, modelUsed: gpt-4 → Try faster model
tokensUsed: 50000 → Input too large, needs chunking
```

### Scenario 3: Unexpected Results

**Check logs for:**
```
Output preview → See actual LLM output
privacy: redacted → Some content was stripped
modelUsed: gpt-3.5-turbo → Different from requested gpt-4
```

## Filtering Console Logs

**Xcode Console:**
```
Search: "LLM"
```

**Console.app:**
```
category:LLM
subsystem:Itori category:LLM
```

**Only LLM requests:**
```
"Starting LLM request"
```

**Only failures:**
```
"LLM request failed"
```

**Only completions:**
```
"LLM request completed"
```

## Token Usage Tracking

Every successful LLM request logs `tokensUsed` for:
- Cost estimation (tokens → API costs)
- Quota monitoring (rate limits)
- Performance analysis (more tokens = slower)

**Typical token usage:**
- Syllabus parsing: 1000-5000 tokens
- Question generation: 500-2000 tokens
- Flashcard generation: 300-1500 tokens
- Summary generation: 200-1000 tokens

## Privacy & Security

**What's logged:**
- Provider name
- Port ID (feature type)
- Duration, token count, model used
- Request ID (for tracing)
- **NOT logged:** Actual user content, API keys

**Output preview:**
- Only first 200 chars
- Only at DEBUG level
- Can contain user data - careful when sharing logs

## Pro Tips

1. **Filter by port** to track specific features
2. **Watch duration** to identify performance issues
3. **Check tokensUsed** to optimize API costs
4. **Compare provider** performance
5. **Monitor fallback usage** to see reliability
6. **Track trigger IDs** across multiple operations

## Testing Checklist

- [ ] Enable LLM → see "Starting LLM request"
- [ ] Disable LLM → see "LLM assistance disabled"
- [ ] Successful request → see duration + tokens
- [ ] Failed request → see error message
- [ ] Fallback → see "Using deterministic fallback"
- [ ] Output preview → see JSON snippet
- [ ] Multiple providers → see different provider names
- [ ] Privacy levels → verify redaction applied

