import Foundation
import XCTest

/// Comprehensive accessibility audit that scans the entire codebase
/// This test ensures all UI elements meet accessibility standards
final class AccessibilityAuditTests: XCTestCase {
    
    private var violations: [AccessibilityViolation] = []
    private let projectRoot = URL(fileURLWithPath: #file)
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .deletingLastPathComponent()
    
    struct AccessibilityViolation {
        let file: String
        let line: Int
        let type: ViolationType
        let code: String
        let suggestion: String
        
        enum ViolationType: String {
            case missingLabel = "Missing Accessibility Label"
            case missingHint = "Missing Accessibility Hint"
            case missingTraits = "Missing Accessibility Traits"
            case colorOnly = "Color-Only Information"
            case smallFont = "Font Too Small"
            case smallTouchTarget = "Touch Target Too Small"
            case noReducedMotion = "Animation Without Reduced Motion"
            case missingIdentifier = "Missing Accessibility Identifier"
            case combinedElements = "Combined Elements Need Grouping"
        }
        
        var description: String {
            """
            
            \(file):\(line)
            Type: \(type.rawValue)
            Code: \(code)
            Fix: \(suggestion)
            """
        }
    }
    
    // MARK: - Main Audit Test
    
    func testFullAccessibilityAudit() throws {
        violations.removeAll()
        
        // Scan all Swift files in the project
        let swiftFiles = try findSwiftFiles()
        
        print("🔍 Scanning \(swiftFiles.count) Swift files for accessibility violations...")
        
        for file in swiftFiles {
            auditFile(file)
        }
        
        // Report results
        if violations.isEmpty {
            print("✅ No accessibility violations found!")
        } else {
            print("\n⚠️  Found \(violations.count) accessibility violations:\n")
            for violation in violations {
                print(violation.description)
            }
            
            // Group by type
            let grouped = Dictionary(grouping: violations, by: { $0.type })
            print("\n📊 Violations by Type:")
            for (type, items) in grouped.sorted(by: { $0.value.count > $1.value.count }) {
                print("  \(type.rawValue): \(items.count)")
            }
            
            XCTFail("\n\n❌ Accessibility audit failed with \(violations.count) violations. See details above.")
        }
    }
    
    // MARK: - File Discovery
    
    private func findSwiftFiles() throws -> [URL] {
        var swiftFiles: [URL] = []
        let fileManager = FileManager.default
        
        // Directories to scan
        let scanDirs = [
            "Platforms/macOS",
            "Platforms/iOS",
            "SharedCore",
            "Shared"
        ]
        
        for dir in scanDirs {
            let dirURL = projectRoot.appendingPathComponent(dir)
            guard fileManager.fileExists(atPath: dirURL.path) else { continue }
            
            if let enumerator = fileManager.enumerator(
                at: dirURL,
                includingPropertiesForKeys: [.isRegularFileKey],
                options: [.skipsHiddenFiles]
            ) {
                for case let fileURL as URL in enumerator {
                    if fileURL.pathExtension == "swift" {
                        swiftFiles.append(fileURL)
                    }
                }
            }
        }
        
        return swiftFiles
    }
    
    // MARK: - File Auditing
    
    private func auditFile(_ fileURL: URL) {
        guard let content = try? String(contentsOf: fileURL, encoding: .utf8) else {
            return
        }
        
        let lines = content.components(separatedBy: .newlines)
        let relativePath = fileURL.path.replacingOccurrences(of: projectRoot.path + "/", with: "")
        
        for (index, line) in lines.enumerated() {
            let lineNumber = index + 1
            auditLine(line, lineNumber: lineNumber, file: relativePath, allLines: lines, currentIndex: index)
        }
    }
    
    private func auditLine(_ line: String, lineNumber: Int, file: String, allLines: [String], currentIndex: Int) {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        
        // Skip comments
        if trimmed.hasPrefix("//") || trimmed.isEmpty {
            return
        }
        
        // Check 1: Interactive elements without accessibility labels
        checkInteractiveElements(line, lineNumber: lineNumber, file: file, allLines: allLines, currentIndex: currentIndex)
        
        // Check 2: Custom gestures without traits
        checkCustomGestures(line, lineNumber: lineNumber, file: file)
        
        // Check 3: Color-only information
        checkColorOnlyInformation(line, lineNumber: lineNumber, file: file)
        
        // Check 4: Small fonts
        checkSmallFonts(line, lineNumber: lineNumber, file: file)
        
        // Check 5: Small touch targets
        checkSmallTouchTargets(line, lineNumber: lineNumber, file: file, allLines: allLines, currentIndex: currentIndex)
        
        // Check 6: Animations without reduced motion
        checkAnimations(line, lineNumber: lineNumber, file: file, allLines: allLines, currentIndex: currentIndex)
        
        // Check 7: Combined elements
        checkCombinedElements(line, lineNumber: lineNumber, file: file, allLines: allLines, currentIndex: currentIndex)
        
        // Check 8: Dynamic lists without identifiers
        checkDynamicLists(line, lineNumber: lineNumber, file: file, allLines: allLines, currentIndex: currentIndex)
    }
    
    // MARK: - Individual Checks
    
    private func checkInteractiveElements(_ line: String, lineNumber: Int, file: String, allLines: [String], currentIndex: Int) {
        let interactivePatterns = [
            "Button\\(",
            "Image\\(",
            "Toggle\\(",
            "Picker\\(",
            "Slider\\(",
            "Stepper\\("
        ]
        
        for pattern in interactivePatterns {
            if line.range(of: pattern, options: .regularExpression) != nil {
                // Check next 10 lines for accessibility modifiers
                let hasAccessibility = checkNextLines(
                    allLines,
                    startIndex: currentIndex,
                    count: 10,
                    patterns: [
                        "\\.accessibilityLabel",
                        "\\.accessibilityHint",
                        "\\.accessibilityHidden"
                    ]
                )
                
                if !hasAccessibility {
                    violations.append(AccessibilityViolation(
                        file: file,
                        line: lineNumber,
                        type: .missingLabel,
                        code: line.trimmingCharacters(in: .whitespaces),
                        suggestion: "Add .accessibilityLabel(\"description\") or .accessibilityHidden(true) for decorative elements"
                    ))
                }
            }
        }
    }
    
    private func checkCustomGestures(_ line: String, lineNumber: Int, file: String) {
        if line.range(of: "\\.onTapGesture|\\gesture\\(", options: .regularExpression) != nil {
            if !line.contains("accessibilityAddTraits") {
                violations.append(AccessibilityViolation(
                    file: file,
                    line: lineNumber,
                    type: .missingTraits,
                    code: line.trimmingCharacters(in: .whitespaces),
                    suggestion: "Add .accessibilityAddTraits(.isButton) or appropriate trait"
                ))
            }
        }
    }
    
    private func checkColorOnlyInformation(_ line: String, lineNumber: Int, file: String) {
        let colorPatterns = [
            "\\.foregroundColor\\(\\.red\\)",
            "\\.foregroundColor\\(\\.green\\)",
            "\\.background\\(\\.red\\)",
            "\\.background\\(\\.green\\)"
        ]
        
        for pattern in colorPatterns {
            if line.range(of: pattern, options: .regularExpression) != nil {
                // Allow if accompanied by Text or Image
                if !line.contains("Text") && !line.contains("Image(systemName:") {
                    violations.append(AccessibilityViolation(
                        file: file,
                        line: lineNumber,
                        type: .colorOnly,
                        code: line.trimmingCharacters(in: .whitespaces),
                        suggestion: "Add text label or icon to convey information beyond color alone"
                    ))
                }
            }
        }
    }
    
    private func checkSmallFonts(_ line: String, lineNumber: Int, file: String) {
        if let match = line.range(of: "\\.font\\(\\.system\\(size:\\s*([0-9])\\)", options: .regularExpression) {
            let sizeString = String(line[match])
            if !line.contains("caption") && !line.contains("footnote") {
                violations.append(AccessibilityViolation(
                    file: file,
                    line: lineNumber,
                    type: .smallFont,
                    code: line.trimmingCharacters(in: .whitespaces),
                    suggestion: "Use Dynamic Type: .font(.caption) or .font(.footnote) instead of hardcoded size"
                ))
            }
        }
    }
    
    private func checkSmallTouchTargets(_ line: String, lineNumber: Int, file: String, allLines: [String], currentIndex: Int) {
        // Match .frame(width: X, height: Y) where X or Y < 44
        if let match = line.range(of: "\\.frame\\(width:\\s*([1-3][0-9]),\\s*height:\\s*([1-3][0-9])\\)", options: .regularExpression) {
            // Check if this is on a Button or tappable element
            let hasTappable = checkPreviousLines(
                allLines,
                startIndex: currentIndex,
                count: 5,
                patterns: ["Button", "onTapGesture"]
            )
            
            if hasTappable {
                violations.append(AccessibilityViolation(
                    file: file,
                    line: lineNumber,
                    type: .smallTouchTarget,
                    code: line.trimmingCharacters(in: .whitespaces),
                    suggestion: "Increase to minimum 44x44 points for touch targets"
                ))
            }
        }
    }
    
    private func checkAnimations(_ line: String, lineNumber: Int, file: String, allLines: [String], currentIndex: Int) {
        if line.range(of: "withAnimation\\(|\\.animation\\(|\\.transition\\(", options: .regularExpression) != nil {
            let hasReducedMotion = checkPreviousLines(
                allLines,
                startIndex: currentIndex,
                count: 20,
                patterns: ["accessibilityReduceMotion"]
            )
            
            if !hasReducedMotion {
                violations.append(AccessibilityViolation(
                    file: file,
                    line: lineNumber,
                    type: .noReducedMotion,
                    code: line.trimmingCharacters(in: .whitespaces),
                    suggestion: "Add @Environment(\\.accessibilityReduceMotion) var reduceMotion and check before animating"
                ))
            }
        }
    }
    
    private func checkCombinedElements(_ line: String, lineNumber: Int, file: String, allLines: [String], currentIndex: Int) {
        // Look for HStack/VStack with both Text and Image
        if line.contains("HStack") || line.contains("VStack") {
            let hasTextAndImage = checkNextLines(
                allLines,
                startIndex: currentIndex,
                count: 10,
                patterns: ["Text\\(", "Image\\("]
            )
            
            if hasTextAndImage {
                let hasAccessibility = checkNextLines(
                    allLines,
                    startIndex: currentIndex,
                    count: 15,
                    patterns: ["\\.accessibilityElement\\(children: \\.combine\\)"]
                )
                
                if !hasAccessibility {
                    violations.append(AccessibilityViolation(
                        file: file,
                        line: lineNumber,
                        type: .combinedElements,
                        code: line.trimmingCharacters(in: .whitespaces),
                        suggestion: "Add .accessibilityElement(children: .combine) to group for VoiceOver"
                    ))
                }
            }
        }
    }
    
    private func checkDynamicLists(_ line: String, lineNumber: Int, file: String, allLines: [String], currentIndex: Int) {
        if line.range(of: "ForEach\\(.*id:", options: .regularExpression) != nil {
            let hasIdentifier = checkNextLines(
                allLines,
                startIndex: currentIndex,
                count: 5,
                patterns: ["\\.accessibilityIdentifier"]
            )
            
            if !hasIdentifier {
                violations.append(AccessibilityViolation(
                    file: file,
                    line: lineNumber,
                    type: .missingIdentifier,
                    code: line.trimmingCharacters(in: .whitespaces),
                    suggestion: "Add .accessibilityIdentifier() to list items for UI testing"
                ))
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func checkNextLines(_ lines: [String], startIndex: Int, count: Int, patterns: [String]) -> Bool {
        let endIndex = min(startIndex + count, lines.count)
        let searchLines = lines[startIndex..<endIndex]
        
        for pattern in patterns {
            if searchLines.contains(where: { $0.range(of: pattern, options: .regularExpression) != nil }) {
                return true
            }
        }
        
        return false
    }
    
    private func checkPreviousLines(_ lines: [String], startIndex: Int, count: Int, patterns: [String]) -> Bool {
        let startSearchIndex = max(0, startIndex - count)
        let searchLines = lines[startSearchIndex..<startIndex]
        
        for pattern in patterns {
            if searchLines.contains(where: { $0.range(of: pattern, options: .regularExpression) != nil }) {
                return true
            }
        }
        
        return false
    }
}
