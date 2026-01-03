//
//  AccessibilityTestingHelpers.swift
//  Roots
//
//  Created on 2026-01-03.
//

import SwiftUI

#if DEBUG

// MARK: - Accessibility Testing Helpers

/// Helpers for manual and automated accessibility testing
enum AccessibilityTestingHelpers {
    
    // MARK: - VoiceOver Testing
    
    /// Simulate VoiceOver announcement for testing
    static func announceForTesting(_ message: String) {
        #if os(iOS)
        UIAccessibility.post(notification: .announcement, argument: message)
        #elseif os(macOS)
        NSAccessibility.post(element: NSApp, notification: .announcementRequested, userInfo: [
            .announcement: message
        ])
        #endif
        print("[A11Y] Announced: \(message)")
    }
    
    /// Check if VoiceOver is running
    static var isVoiceOverRunning: Bool {
        #if os(iOS)
        return UIAccessibility.isVoiceOverRunning
        #elseif os(macOS)
        return NSWorkspace.shared.isVoiceOverEnabled
        #else
        return false
        #endif
    }
    
    // MARK: - Dynamic Type Testing
    
    /// Get current Dynamic Type size
    static var currentDynamicTypeSize: String {
        #if os(iOS)
        let category = UIApplication.shared.preferredContentSizeCategory
        return category.rawValue
        #else
        return "Not applicable on this platform"
        #endif
    }
    
    /// Check if using accessibility text sizes
    static var isAccessibilityTextSize: Bool {
        #if os(iOS)
        return UIApplication.shared.preferredContentSizeCategory.isAccessibilityCategory
        #else
        return false
        #endif
    }
    
    // MARK: - Contrast Testing
    
    /// Calculate contrast ratio between two colors
    static func contrastRatio(foreground: Color, background: Color) -> Double {
        let fg = UIColor(foreground)
        let bg = UIColor(background)
        
        let fgLuminance = relativeLuminance(of: fg)
        let bgLuminance = relativeLuminance(of: bg)
        
        let lighter = max(fgLuminance, bgLuminance)
        let darker = min(fgLuminance, bgLuminance)
        
        return (lighter + 0.05) / (darker + 0.05)
    }
    
    /// Check if contrast ratio meets WCAG AA standard (4.5:1 for normal text)
    static func meetsWCAGAA(foreground: Color, background: Color) -> Bool {
        contrastRatio(foreground: foreground, background: background) >= 4.5
    }
    
    /// Check if contrast ratio meets WCAG AAA standard (7:1 for normal text)
    static func meetsWCAGAAA(foreground: Color, background: Color) -> Bool {
        contrastRatio(foreground: foreground, background: background) >= 7.0
    }
    
    private static func relativeLuminance(of color: UIColor) -> Double {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        
        color.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        
        let r = linearize(red)
        let g = linearize(green)
        let b = linearize(blue)
        
        return 0.2126 * r + 0.7152 * g + 0.0722 * b
    }
    
    private static func linearize(_ component: CGFloat) -> Double {
        let c = Double(component)
        if c <= 0.03928 {
            return c / 12.92
        } else {
            return pow((c + 0.055) / 1.055, 2.4)
        }
    }
    
    // MARK: - Touch Target Testing
    
    /// Check if size meets minimum touch target (44x44 on iOS, 24x24 on macOS)
    static func meetsTouchTargetSize(_ size: CGSize) -> Bool {
        #if os(iOS)
        return size.width >= 44 && size.height >= 44
        #elseif os(macOS)
        return size.width >= 24 && size.height >= 24
        #else
        return true
        #endif
    }
    
    /// Get recommended minimum touch target size
    static var minimumTouchTarget: CGSize {
        #if os(iOS)
        return CGSize(width: 44, height: 44)
        #elseif os(macOS)
        return CGSize(width: 24, height: 24)
        #else
        return CGSize(width: 44, height: 44)
        #endif
    }
    
    // MARK: - Motion Preferences
    
    /// Check if Reduce Motion is enabled
    static var isReduceMotionEnabled: Bool {
        #if os(iOS)
        return UIAccessibility.isReduceMotionEnabled
        #elseif os(macOS)
        return NSWorkspace.shared.accessibilityDisplayShouldReduceMotion
        #else
        return false
        #endif
    }
    
    /// Check if Reduce Transparency is enabled
    static var isReduceTransparencyEnabled: Bool {
        #if os(iOS)
        return UIAccessibility.isReduceTransparencyEnabled
        #else
        return false
        #endif
    }
    
    // MARK: - Element Inspection
    
    /// Print accessibility information for debugging
    static func inspectAccessibility(
        label: String?,
        value: String?,
        hint: String?,
        traits: AccessibilityTraits
    ) {
        print("""
        [A11Y Inspection]
        Label: \(label ?? "nil")
        Value: \(value ?? "nil")
        Hint: \(hint ?? "nil")
        Traits: \(traits)
        """)
    }
    
    // MARK: - Testing Scenarios
    
    /// Generate test report for a view
    static func generateTestReport(
        viewName: String,
        hasLabel: Bool,
        hasHint: Bool,
        hasValue: Bool,
        hasTraits: Bool,
        contrast: Double?,
        touchTargetSize: CGSize?
    ) -> String {
        var report = "Accessibility Test Report: \(viewName)\n"
        report += String(repeating: "=", count: 50) + "\n\n"
        
        report += "Labels & Traits:\n"
        report += "  ✓ Has Label: \(hasLabel ? "✅" : "❌")\n"
        report += "  ✓ Has Hint: \(hasHint ? "✅" : "⚠️")\n"
        report += "  ✓ Has Value: \(hasValue ? "✅" : "⚠️")\n"
        report += "  ✓ Has Traits: \(hasTraits ? "✅" : "❌")\n\n"
        
        if let contrast = contrast {
            report += "Color Contrast:\n"
            report += "  Ratio: \(String(format: "%.2f", contrast)):1\n"
            report += "  WCAG AA: \(contrast >= 4.5 ? "✅ Pass" : "❌ Fail")\n"
            report += "  WCAG AAA: \(contrast >= 7.0 ? "✅ Pass" : "⚠️ Fail")\n\n"
        }
        
        if let size = touchTargetSize {
            let meets = meetsTouchTargetSize(size)
            report += "Touch Target:\n"
            report += "  Size: \(Int(size.width))×\(Int(size.height))pt\n"
            report += "  Minimum: \(Int(minimumTouchTarget.width))×\(Int(minimumTouchTarget.height))pt\n"
            report += "  Status: \(meets ? "✅ Pass" : "❌ Fail")\n\n"
        }
        
        report += "Accessibility Settings:\n"
        report += "  VoiceOver: \(isVoiceOverRunning ? "Enabled" : "Disabled")\n"
        report += "  Reduce Motion: \(isReduceMotionEnabled ? "Enabled" : "Disabled")\n"
        report += "  Reduce Transparency: \(isReduceTransparencyEnabled ? "Enabled" : "Disabled")\n"
        report += "  Dynamic Type: \(currentDynamicTypeSize)\n"
        
        return report
    }
}

// MARK: - Accessibility Preview Modifiers

extension View {
    /// Preview with VoiceOver simulation
    func previewWithVoiceOver() -> some View {
        self.environment(\.accessibilityEnabled, true)
    }
    
    /// Preview with large text size
    func previewWithLargeText() -> some View {
        self.environment(\.sizeCategory, .accessibilityExtraExtraExtraLarge)
    }
    
    /// Preview with Reduce Motion
    func previewWithReduceMotion() -> some View {
        self.environment(\.accessibilityReduceMotion, true)
    }
    
    /// Preview with high contrast
    func previewWithHighContrast() -> some View {
        self.environment(\.accessibilityDifferentiateWithoutColor, true)
    }
    
    /// Preview with all accessibility features
    func previewAccessibilityMaximum() -> some View {
        self
            .environment(\.sizeCategory, .accessibilityExtraExtraExtraLarge)
            .environment(\.accessibilityReduceMotion, true)
            .environment(\.accessibilityReduceTransparency, true)
            .environment(\.accessibilityDifferentiateWithoutColor, true)
    }
}

// MARK: - Accessibility Overlay for Visual Debugging

struct AccessibilityDebugOverlay: ViewModifier {
    @State private var showLabels = false
    @State private var showTouchTargets = false
    @State private var showContrast = false
    
    func body(content: Content) -> some View {
        content
            .overlay(alignment: .bottomTrailing) {
                debugControls
            }
            .overlay {
                if showTouchTargets {
                    touchTargetGrid
                }
            }
    }
    
    private var debugControls: some View {
        VStack(spacing: 8) {
            Button(action: { showLabels.toggle() }) {
                Image(systemName: showLabels ? "tag.fill" : "tag")
                    .padding(8)
                    .background(Color.blue.opacity(0.8))
                    .foregroundColor(.white)
                    .clipShape(Circle())
            }
            
            Button(action: { showTouchTargets.toggle() }) {
                Image(systemName: showTouchTargets ? "hand.tap.fill" : "hand.tap")
                    .padding(8)
                    .background(Color.green.opacity(0.8))
                    .foregroundColor(.white)
                    .clipShape(Circle())
            }
            
            Button(action: { showContrast.toggle() }) {
                Image(systemName: showContrast ? "circle.lefthalf.filled" : "circle.lefthalf.fill")
                    .padding(8)
                    .background(Color.orange.opacity(0.8))
                    .foregroundColor(.white)
                    .clipShape(Circle())
            }
        }
        .padding()
    }
    
    private var touchTargetGrid: some View {
        GeometryReader { geometry in
            let spacing: CGFloat = AccessibilityTestingHelpers.minimumTouchTarget.width
            let columns = Int(geometry.size.width / spacing) + 1
            let rows = Int(geometry.size.height / spacing) + 1
            
            ZStack {
                ForEach(0..<columns, id: \.self) { col in
                    ForEach(0..<rows, id: \.self) { row in
                        Rectangle()
                            .stroke(Color.green.opacity(0.3), lineWidth: 1)
                            .frame(width: spacing, height: spacing)
                            .position(
                                x: CGFloat(col) * spacing + spacing / 2,
                                y: CGFloat(row) * spacing + spacing / 2
                            )
                    }
                }
            }
        }
        .allowsHitTesting(false)
    }
}

extension View {
    /// Add visual accessibility debugging overlay
    func accessibilityDebugOverlay() -> some View {
        modifier(AccessibilityDebugOverlay())
    }
}

// MARK: - Color Blindness Simulation

enum ColorBlindnessType {
    case protanopia    // Red-blind
    case deuteranopia  // Green-blind
    case tritanopia    // Blue-blind
    case monochromacy  // Total color blindness
}

extension View {
    /// Simulate color blindness for testing
    func simulateColorBlindness(_ type: ColorBlindnessType) -> some View {
        // Note: This is a simplified simulation
        // For accurate testing, use real color blindness simulators
        self.grayscale(type == .monochromacy ? 1.0 : 0.0)
    }
}

// MARK: - Accessibility Test Suite Helpers

struct AccessibilityTestSuite {
    let viewName: String
    var tests: [AccessibilityTest] = []
    
    struct AccessibilityTest {
        let name: String
        let passed: Bool
        let message: String
    }
    
    mutating func addTest(name: String, passed: Bool, message: String = "") {
        tests.append(AccessibilityTest(name: name, passed: passed, message: message))
    }
    
    var passCount: Int {
        tests.filter { $0.passed }.count
    }
    
    var failCount: Int {
        tests.filter { !$0.passed }.count
    }
    
    var passPercentage: Double {
        guard !tests.isEmpty else { return 0 }
        return Double(passCount) / Double(tests.count) * 100
    }
    
    func printReport() {
        print("""
        
        ════════════════════════════════════════════════════════
        Accessibility Test Report: \(viewName)
        ════════════════════════════════════════════════════════
        
        Total Tests: \(tests.count)
        Passed: \(passCount) ✅
        Failed: \(failCount) ❌
        Pass Rate: \(String(format: "%.1f", passPercentage))%
        
        """)
        
        for (index, test) in tests.enumerated() {
            let status = test.passed ? "✅ PASS" : "❌ FAIL"
            print("[\(index + 1)] \(status) - \(test.name)")
            if !test.message.isEmpty {
                print("    \(test.message)")
            }
        }
        
        print("\n════════════════════════════════════════════════════════\n")
    }
}

// MARK: - Platform Extensions

#if os(iOS)
extension UIColor {
    convenience init(_ color: Color) {
        let uiColor = UIColor(color)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        self.init(red: red, green: green, blue: blue, alpha: alpha)
    }
}
#endif

#endif
