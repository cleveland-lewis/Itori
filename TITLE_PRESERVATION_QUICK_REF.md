# Title Preservation - Developer Quick Reference

## 🚨 Critical Rules

### NEVER modify titles
```swift
// ❌ DON'T DO THIS
module.title = cleanTitle(module.title)  // NO!
file.filename = removePrefix(file.filename)  // NO!

// ✅ DO THIS
module.title = userProvidedTitle  // Keep exactly as provided
file.filename = originalFilename  // No modifications
```

### ALWAYS preserve legacy flags during migration
```swift
// ✅ CORRECT
let file = CourseFile(
    filename: original.filename,      // Exact copy
    isSyllabus: original.isSyllabus,  // Preserve
    isPracticeExam: original.isPracticeExam,  // Preserve
    category: inferredCategory  // Can be set from flags
)
```

## Test Commands

### Run all title preservation tests
```bash
xcodebuild test -scheme Itori \
  -only-testing:ItoriTests/TitlePreservationTests
```

### Run specific test
```bash
xcodebuild test -scheme Itori \
  -only-testing:ItoriTests/TitlePreservationTests/testCreateModulePreservesTitleExactly
```

### Quick validation
```bash
# Before committing changes to persistence code
./Scripts/run-title-preservation-tests.sh
```

## Common Mistakes

### ❌ Title "Cleaning"
```swift
// WRONG: Don't strip prefixes
if title.hasPrefix("[") {
    title = title.removePrefix()
}
```

### ❌ Category-based Title Modification
```swift
// WRONG: Don't modify title based on category
if file.category == .syllabus {
    file.filename = "[Syllabus] " + file.filename
}
```

### ❌ Encoding Assumptions
```swift
// WRONG: Don't assume ASCII
let cleanTitle = title.replacingOccurrences(of: "模块", with: "Module")
```

## Verification Checklist

Before committing persistence changes:
- [ ] Run `TitlePreservationTests`
- [ ] Test with Unicode titles
- [ ] Test with special characters `[]():;-`
- [ ] Test legacy flag preservation
- [ ] Test multiple save/fetch cycles

## Edge Cases Covered

✅ Brackets: `[IMPORTANT] Title`
✅ Colons: `Week 1: Day 2: Intro`
✅ Prefixes that look like types: `Module: Core`
✅ Unicode: `模块 1: 介绍`
✅ Special chars: `Homework #3 - Arrays & Strings`
✅ Legacy migrations
✅ Nested structures

## When Tests Fail

1. **Check**: Did you modify title in save logic?
2. **Check**: Did you add title "cleaning" code?
3. **Check**: Did migration drop fields?
4. **Check**: Is encoding correct for Unicode?
5. **Check**: Are legacy flags preserved?

## Quick Test Examples

### Test a new title format
```swift
func testMyNewFormat() async throws {
    let title = "My [Special] Format: V2"
    let module = try await repository.createModule(
        courseId: courseId,
        type: .module,
        title: title
    )
    XCTAssertEqual(module.title, title)
}
```

### Test migration
```swift
func testMyMigration() async throws {
    let original = createOriginalData()
    let migrated = try await migrateData(original)
    XCTAssertEqual(migrated.title, original.title)
}
```

## Related Files
- `TitlePreservationTests.swift` - Full test suite
- `CourseModuleRepository.swift` - Persistence layer
- `PersistenceMigrationManager.swift` - Migration logic

## Need Help?
See `TITLE_PRESERVATION_TESTS.md` for detailed documentation.
