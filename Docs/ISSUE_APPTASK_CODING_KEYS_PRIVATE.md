# [BUG] AppTask CodingKeys Privacy Breaks Protocol Conformance

## Priority
🔴 **Critical** - Blocks all unit tests

## Description
`AppTask` struct declares conformance to `Equatable` and `Hashable` but has `private` CodingKeys, preventing the Swift compiler from synthesizing the required implementations.

## Error Messages
```
Type 'AppTask' does not conform to protocol 'Hashable'
Type 'AppTask' does not conform to protocol 'Equatable'
'CodingKeys' is inaccessible due to 'private' protection level
```

## Affected Files
- `SharedCore/Features/Scheduler/AIScheduler.swift` (lines 48, 95-117)

## Root Cause
```swift
struct AppTask: Codable, Equatable, Hashable {  // ✅ Declares conformance
    // ... properties ...
    
    private enum CodingKeys: String, CodingKey {  // ❌ Private prevents synthesis
        case id
        case title
        // ... other keys ...
    }
}
```

When `CodingKeys` is private, the compiler cannot:
1. Synthesize `Equatable` conformance (needs to compare all properties)
2. Synthesize `Hashable` conformance (needs to hash all properties)
3. Even though `Codable` conformance is manually implemented

## Fix
Change CodingKeys visibility:

```swift
struct AppTask: Codable, Equatable, Hashable {
    // ... properties ...
    
    enum CodingKeys: String, CodingKey {  // ✅ Remove 'private'
        case id
        case title
        // ... other keys ...
    }
}
```

Or if CodingKeys must stay private, manually implement Equatable and Hashable:

```swift
extension AppTask {
    static func == (lhs: AppTask, rhs: AppTask) -> Bool {
        lhs.id == rhs.id &&
        lhs.title == rhs.title &&
        // ... compare all properties ...
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(title)
        // ... hash all properties ...
    }
}
```

## Steps to Reproduce
1. Run unit tests: `xcodebuild test -scheme ItoriTests -destination 'platform=macOS'`
2. Build fails with protocol conformance errors

## Impact
- ❌ Unit tests cannot run
- ❌ Any code comparing or hashing AppTask instances fails
- ❌ Collections using AppTask (Set, Dictionary) may not work correctly

## Recommended Solution
**Remove `private` from CodingKeys** - This is the simplest fix and follows Swift best practices. CodingKeys visibility doesn't affect API surface since it's only used during encoding/decoding.

## Environment
- macOS
- Xcode (current version)
- Test suite: ItoriTests

---

**Labels:** `bug`, `critical`, `build-failure`, `testing`, `swift`, `models`
