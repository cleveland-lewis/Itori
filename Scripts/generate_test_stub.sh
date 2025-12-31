#!/bin/bash
#
# generate_test_stub.sh
# Generates test file stubs for Swift source files that don't have tests
#
# Usage: ./generate_test_stub.sh <SourceFile.swift>
#

set -e

SOURCE_FILE="$1"

if [ -z "$SOURCE_FILE" ]; then
    echo "Usage: $0 <SourceFile.swift>"
    exit 1
fi

if [ ! -f "$SOURCE_FILE" ]; then
    echo "Error: File $SOURCE_FILE not found"
    exit 1
fi

# Extract filename without path and extension
BASENAME=$(basename "$SOURCE_FILE" .swift)
TEST_FILE="Tests/Unit/RootsTests/${BASENAME}Tests.swift"

# Check if test already exists
if [ -f "$TEST_FILE" ]; then
    echo "Test file already exists: $TEST_FILE"
    exit 0
fi

# Extract class/struct names from source file
TYPES=$(grep -E "^(class|struct|enum|actor) " "$SOURCE_FILE" | awk '{print $2}' | cut -d: -f1 | cut -d'<' -f1)

if [ -z "$TYPES" ]; then
    echo "No types found in $SOURCE_FILE"
    exit 1
fi

# Generate test file
cat > "$TEST_FILE" << EOF
//
//  ${BASENAME}Tests.swift
//  RootsTests
//
//  Auto-generated test stub for ${BASENAME}.swift
//  TODO: Implement actual tests
//

import XCTest
@testable import Roots

@MainActor
final class ${BASENAME}Tests: BaseTestCase {
    
    // MARK: - Properties
    
    // Add test subjects here
    
    // MARK: - Setup
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        // Additional setup
    }
    
    override func tearDownWithError() throws {
        // Cleanup
        try super.tearDownWithError()
    }
    
    // MARK: - Tests
    
EOF

# Generate test method stubs for each type
for TYPE in $TYPES; do
    cat >> "$TEST_FILE" << EOF
    // MARK: - $TYPE Tests
    
    func testInit${TYPE}() {
        // TODO: Test initialization
        XCTFail("Test not implemented")
    }
    
    func test${TYPE}BasicOperations() {
        // TODO: Test basic operations
        XCTFail("Test not implemented")
    }
    
    func test${TYPE}EdgeCases() {
        // TODO: Test edge cases
        XCTFail("Test not implemented")
    }
    
EOF
done

cat >> "$TEST_FILE" << EOF
}
EOF

echo "✅ Generated test stub: $TEST_FILE"
echo ""
echo "Next steps:"
echo "1. Open $TEST_FILE"
echo "2. Replace XCTFail with actual test implementations"
echo "3. Add necessary setup and mocks"
echo "4. Run tests: xcodebuild test -scheme Roots -only-testing:RootsTests/${BASENAME}Tests"
