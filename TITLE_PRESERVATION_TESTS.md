# Title Preservation & Migration Tests

## Overview
This document describes the comprehensive test suite that prevents regression in title handling and data migration for the Itori app.

## Purpose
**Critical Requirements:**
1. Titles must NEVER change on save
2. Migration must NOT lose data
3. Legacy flags must be preserved during migration
4. Edge cases (brackets, colons, special characters) must be handled correctly

## Test File
`Tests/Unit/SharedCore/TitlePreservationTests.swift`

## Test Coverage

### 1. Module Title Preservation Tests

#### `testCreateModulePreservesTitleExactly`
- **Purpose**: Verify that creating a module preserves the title exactly as provided
- **Test Case**: Create module with title "Week 1: Introduction to Swift"
- **Expected**: Title remains unchanged after creation

#### `testEditModulePreservesTitleExactly`
- **Purpose**: Verify that updating a module preserves the new title exactly
- **Test Case**: Create module, then update with new title
- **Expected**: New title is saved exactly as provided

#### `testSaveModuleMultipleTimesPreservesTitle`
- **Purpose**: Verify that saving a module multiple times does not alter its title
- **Test Case**: Create module and save 5 times with different sort indices
- **Expected**: Title remains unchanged after multiple saves

### 2. File Title Preservation Tests

#### `testCreateFilePreservesTitleExactly`
- **Purpose**: Verify that creating a file preserves the filename exactly
- **Test Case**: Create file with filename "Syllabus - Fall 2024.pdf"
- **Expected**: Filename remains unchanged after creation

#### `testFilenameSavePreservesTitle`
- **Purpose**: Verify that updating file metadata does not alter filename
- **Test Case**: Create file, then update parse status multiple times
- **Expected**: Filename remains unchanged after metadata updates

### 3. Edge Case Titles

#### `testTitleWithBrackets`
- **Purpose**: Verify titles containing brackets are preserved
- **Test Case**: "[IMPORTANT] Module 1: Introduction"
- **Expected**: Title with brackets persists exactly, including brackets

#### `testTitleWithColons`
- **Purpose**: Verify titles containing multiple colons are preserved
- **Test Case**: "Week 3: Review: Midterm Prep"
- **Expected**: All colons preserved in exact positions

#### `testTitleWithLegacyLikePrefixes`
- **Purpose**: Verify titles that look like legacy markers are not stripped
- **Test Cases**:
  - "Module: Core Concepts"
  - "Section: Advanced Topics"
  - "Chapter: Final Review"
  - "Part 1: Getting Started"
  - "Lesson 5: Summary"
- **Expected**: All prefixes preserved exactly, no automatic stripping

#### `testFilenameWithSpecialCharacters`
- **Purpose**: Verify filenames with special characters are preserved
- **Test Cases**:
  - "[Syllabus] CS 101.pdf"
  - "Practice Test: Midterm (v2).pdf"
  - "Homework #3 - Arrays & Strings.pdf"
  - "Lab Report [Group A]: Results.pdf"
- **Expected**: All special characters preserved exactly

### 4. Migration Tests

#### `testLegacyRecordMigratesCategoryCorrectly`
- **Purpose**: Verify legacy flags (isSyllabus, isPracticeExam) are preserved during migration
- **Test Case**: Create files with legacy flags set
- **Expected**: 
  - Legacy flags remain unchanged
  - Category field is populated (not nil)
  - No data loss during migration

#### `testTitleRemainsIdenticalPrePostMigration`
- **Purpose**: Verify titles are not modified during migration operations
- **Test Case**: Create file with legacy flags, then trigger migration-like operations
- **Expected**: Filename remains absolutely identical before and after

#### `testMigrationPreservesAllFileData`
- **Purpose**: Verify all file data fields are preserved during migration
- **Test Case**: Create file with comprehensive data
- **Fields Verified**:
  - filename
  - fileType
  - localURL
  - isSyllabus
  - isPracticeExam
  - courseId
- **Expected**: All fields persist exactly, no data loss

#### `testModuleMigrationPreservesAllData`
- **Purpose**: Verify all module data fields are preserved during migration
- **Test Case**: Create module with comprehensive data
- **Fields Verified**:
  - title
  - type
  - sortIndex
  - courseId
  - parentId
- **Expected**: All fields persist exactly

#### `testNestedModuleTitlePreservation`
- **Purpose**: Verify parent-child relationships don't affect title preservation
- **Test Case**: Create parent module with child module, both with special titles
- **Expected**: Both titles persist independently and exactly

### 5. Stress Tests

#### `testMassiveTitleVariations`
- **Purpose**: Test multiple title format variations simultaneously
- **Test Cases**: 10 different title patterns including:
  - Simple titles
  - Prefixed titles
  - Suffixed titles
  - Multiple delimiters
  - Nested brackets
  - Multiple markers
- **Expected**: All variations persist exactly

#### `testUnicodeTitles`
- **Purpose**: Verify Unicode characters in titles are preserved
- **Test Cases**: Titles in 6 different languages:
  - Chinese (Simplified)
  - Japanese
  - Korean
  - Russian
  - Arabic
  - Greek
- **Expected**: All Unicode characters persist exactly without corruption

## Running the Tests

### Command Line
```bash
xcodebuild test \
  -scheme Itori \
  -destination 'platform=macOS' \
  -only-testing:ItoriTests/TitlePreservationTests
```

### Xcode IDE
1. Open `ItoriApp.xcodeproj`
2. Navigate to Test Navigator (⌘6)
3. Find `TitlePreservationTests`
4. Click the diamond icon to run all tests in the suite
5. Or right-click individual tests to run them

### CI/CD Integration
Add to your test pipeline:
```bash
# Run title preservation tests as part of regression suite
xcodebuild test -scheme Itori \
  -only-testing:ItoriTests/TitlePreservationTests \
  -resultBundlePath ./test-results/title-preservation
```

## Test Data Patterns

### Title Patterns Tested
- Simple: "Module 1"
- With prefixes: "[DRAFT] Module 1"
- With suffixes: "Module 1 (Notes)"
- With colons: "Week 1: Day 2: Introduction"
- With brackets: "[Important] [Urgent]"
- With special chars: "Homework #3 - Arrays & Strings"
- Unicode: "模块 1: 介绍"

### File Patterns Tested
- Simple PDFs: "syllabus.pdf"
- Dated: "Syllabus - Fall 2024.pdf"
- Versioned: "Practice Test (v2).pdf"
- Special chars: "Lab Report [Group A]: Results.pdf"
- Hyphenated: "Homework #3 - Arrays & Strings.pdf"

## Assertions Made

### Title Equality
```swift
XCTAssertEqual(module.title, expectedTitle, 
    "Title must be preserved exactly")
```

### Data Integrity
```swift
XCTAssertEqual(persisted?.filename, original.filename,
    "Filename must persist exactly")
XCTAssertEqual(persisted?.isSyllabus, original.isSyllabus,
    "Legacy flags must persist")
```

### Non-Null Guarantees
```swift
XCTAssertNotNil(file.category,
    "Category should be populated after migration")
```

## Failure Scenarios

If these tests fail, it indicates:

1. **Title modification bug**: Code is altering titles during save/fetch
2. **Migration data loss**: Migration process is losing or corrupting data
3. **Encoding issue**: Unicode or special characters being corrupted
4. **Legacy flag loss**: Old data format is not being preserved
5. **Category inference bug**: Category system is overwriting titles

## Integration with CI/CD

### Pre-commit Hook
```bash
#!/bin/bash
# Run title preservation tests before commit
xcodebuild test -scheme Itori \
  -only-testing:ItoriTests/TitlePreservationTests \
  -quiet || exit 1
```

### Pull Request Checks
Add as required check:
- Test suite must pass before merge
- No title preservation test can be skipped
- Code coverage must include new title-handling code

## Maintenance

### When to Add New Tests
1. Adding new data models with titles/names
2. Adding new migration paths
3. Adding new special character support
4. Adding new languages/Unicode support
5. Modifying save/fetch logic

### Test Maintenance Checklist
- [ ] Tests pass on all supported platforms (macOS, iOS, watchOS)
- [ ] Tests cover all edge cases documented in issues
- [ ] Tests fail when intentionally breaking title preservation
- [ ] Tests pass after migration code changes
- [ ] Tests are documented in this file

## Related Documentation
- `COURSE_MODULE_PERSISTENCE.md` - Persistence architecture
- `FILE_CLASSIFICATION_IMPLEMENTATION.md` - Category system
- `MIGRATION_GUIDE.md` - Data migration patterns

## Issue Tracking
Tests address requirements from:
- Issue: Title preservation requirements
- Issue: Migration data integrity requirements
- Epic: Persistence system implementation

## Success Criteria
✅ All 17+ test cases pass
✅ Tests run in < 10 seconds
✅ Zero false positives
✅ Coverage of all edge cases
✅ Tests fail when regression is introduced
