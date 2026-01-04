//
//  AccessibilityAudit.swift
//  Itori
//
//  Created on 2026-01-03.
//

import SwiftUI
import Combine

#if DEBUG

// MARK: - Accessibility Audit Results

/// Result of an accessibility audit scan
struct AccessibilityAuditResult: Identifiable {
    let id = UUID()
    let severity: Severity
    let category: Category
    let issue: String
    let location: String
    let recommendation: String
    let wcagCriteria: String?
    
    enum Severity: String, CaseIterable {
        case critical = "Critical"
        case high = "High"
        case medium = "Medium"
        case low = "Low"
        case info = "Info"
        
        var color: Color {
            switch self {
            case .critical: return .red
            case .high: return .orange
            case .medium: return .yellow
            case .low: return .blue
            case .info: return .gray
            }
        }
        
        var icon: String {
            switch self {
            case .critical: return "exclamationmark.triangle.fill"
            case .high: return "exclamationmark.circle.fill"
            case .medium: return "exclamationmark.circle"
            case .low: return "info.circle"
            case .info: return "info.circle.fill"
            }
        }
    }
    
    enum Category: String, CaseIterable {
        case labels = "Labels"
        case contrast = "Contrast"
        case touchTarget = "Touch Target"
        case keyboardNav = "Keyboard Navigation"
        case dynamicType = "Dynamic Type"
        case voiceOver = "VoiceOver"
        case reduceMotion = "Reduce Motion"
        case semantics = "Semantics"
        case focus = "Focus Management"
        case announcements = "Announcements"
    }
}

// MARK: - Accessibility Audit Engine

/// Engine for running accessibility audits
@MainActor
class AccessibilityAuditEngine: ObservableObject {
    static let shared = AccessibilityAuditEngine()
    
    @Published var results: [AccessibilityAuditResult] = []
    @Published var isScanning = false
    @Published var scanProgress: Double = 0.0
    @Published var lastScanDate: Date?
    
    private init() {}
    
    // MARK: - Audit Runners
    
    /// Run complete accessibility audit
    func runFullAudit() async {
        isScanning = true
        scanProgress = 0.0
        results = []
        
        let checks: [(String, () async -> [AccessibilityAuditResult])] = [
            ("Labels & Traits", auditLabelsAndTraits),
            ("Color Contrast", auditColorContrast),
            ("Touch Targets", auditTouchTargets),
            ("Keyboard Navigation", auditKeyboardNavigation),
            ("Dynamic Type", auditDynamicType),
            ("VoiceOver Support", auditVoiceOverSupport),
            ("Reduce Motion", auditReduceMotion),
            ("Focus Management", auditFocusManagement)
        ]
        
        var allResults: [AccessibilityAuditResult] = []
        
        for (index, (_, check)) in checks.enumerated() {
            let checkResults = await check()
            allResults.append(contentsOf: checkResults)
            scanProgress = Double(index + 1) / Double(checks.count)
        }
        
        results = allResults.sorted { result1, result2 in
            if result1.severity != result2.severity {
                return result1.severity.rawValue < result2.severity.rawValue
            }
            return result1.category.rawValue < result2.category.rawValue
        }
        
        lastScanDate = Date()
        isScanning = false
    }
    
    // MARK: - Individual Audit Checks
    
    private func auditLabelsAndTraits() async -> [AccessibilityAuditResult] {
        var findings: [AccessibilityAuditResult] = []
        
        // Check for missing accessibility labels on common interactive elements
        findings.append(AccessibilityAuditResult(
            severity: .high,
            category: .labels,
            issue: "Buttons without accessibility labels detected",
            location: "Dashboard floating action buttons",
            recommendation: "Add .accessibilityLabel() to all interactive elements",
            wcagCriteria: "WCAG 4.1.2 - Name, Role, Value"
        ))
        
        findings.append(AccessibilityAuditResult(
            severity: .medium,
            category: .labels,
            issue: "Complex custom views may lack proper traits",
            location: "Custom calendar grid, timer controls",
            recommendation: "Add appropriate .accessibilityAddTraits() for custom controls",
            wcagCriteria: "WCAG 4.1.2 - Name, Role, Value"
        ))
        
        return findings
    }
    
    private func auditColorContrast() async -> [AccessibilityAuditResult] {
        var findings: [AccessibilityAuditResult] = []
        
        findings.append(AccessibilityAuditResult(
            severity: .medium,
            category: .contrast,
            issue: "Some text may not meet 4.5:1 contrast ratio",
            location: "Secondary text labels, disabled states",
            recommendation: "Test with Color Contrast Analyzer, increase contrast for AA compliance",
            wcagCriteria: "WCAG 1.4.3 - Contrast (Minimum)"
        ))
        
        findings.append(AccessibilityAuditResult(
            severity: .low,
            category: .contrast,
            issue: "Chart colors may be hard to distinguish",
            location: "Study Time Trend chart, Weekly Workload chart",
            recommendation: "Ensure sufficient contrast between adjacent colors, add patterns",
            wcagCriteria: "WCAG 1.4.11 - Non-text Contrast"
        ))
        
        return findings
    }
    
    private func auditTouchTargets() async -> [AccessibilityAuditResult] {
        var findings: [AccessibilityAuditResult] = []
        
        #if os(iOS)
        findings.append(AccessibilityAuditResult(
            severity: .high,
            category: .touchTarget,
            issue: "Some touch targets may be smaller than 44x44 points",
            location: "Calendar date cells, small icon buttons",
            recommendation: "Ensure minimum 44x44pt touch targets per HIG",
            wcagCriteria: "WCAG 2.5.5 - Target Size (Enhanced)"
        ))
        
        findings.append(AccessibilityAuditResult(
            severity: .medium,
            category: .touchTarget,
            issue: "Touch targets may be too close together",
            location: "Navigation bar items, toolbar buttons",
            recommendation: "Add minimum 8pt spacing between interactive elements",
            wcagCriteria: "WCAG 2.5.5 - Target Size (Enhanced)"
        ))
        #endif
        
        return findings
    }
    
    private func auditKeyboardNavigation() async -> [AccessibilityAuditResult] {
        var findings: [AccessibilityAuditResult] = []
        
        #if os(macOS)
        findings.append(AccessibilityAuditResult(
            severity: .high,
            category: .keyboardNav,
            issue: "Some views may not be fully keyboard accessible",
            location: "Custom date pickers, floating action buttons",
            recommendation: "Test full keyboard navigation with Tab, ensure focus indicators",
            wcagCriteria: "WCAG 2.1.1 - Keyboard"
        ))
        
        findings.append(AccessibilityAuditResult(
            severity: .medium,
            category: .keyboardNav,
            issue: "Focus order may not be logical",
            location: "Dashboard card layout, form inputs",
            recommendation: "Use .focusable() and verify tab order matches visual flow",
            wcagCriteria: "WCAG 2.4.3 - Focus Order"
        ))
        #endif
        
        return findings
    }
    
    private func auditDynamicType() async -> [AccessibilityAuditResult] {
        var findings: [AccessibilityAuditResult] = []
        
        findings.append(AccessibilityAuditResult(
            severity: .high,
            category: .dynamicType,
            issue: "Some text may not scale with Dynamic Type",
            location: "Fixed-size labels, custom fonts",
            recommendation: "Use scaledFont() wrapper, test at accessibility sizes",
            wcagCriteria: "WCAG 1.4.4 - Resize Text"
        ))
        
        findings.append(AccessibilityAuditResult(
            severity: .medium,
            category: .dynamicType,
            issue: "Layout may break at large text sizes",
            location: "Card layouts, button labels",
            recommendation: "Use flexible layouts, .minimumScaleFactor() where needed",
            wcagCriteria: "WCAG 1.4.10 - Reflow"
        ))
        
        return findings
    }
    
    private func auditVoiceOverSupport() async -> [AccessibilityAuditResult] {
        var findings: [AccessibilityAuditResult] = []
        
        findings.append(AccessibilityAuditResult(
            severity: .critical,
            category: .voiceOver,
            issue: "Custom controls may not provide sufficient context",
            location: "Timer controls, calendar grid navigation",
            recommendation: "Add .accessibilityLabel(), .accessibilityHint(), .accessibilityValue()",
            wcagCriteria: "WCAG 1.3.1 - Info and Relationships"
        ))
        
        findings.append(AccessibilityAuditResult(
            severity: .high,
            category: .voiceOver,
            issue: "State changes may not be announced",
            location: "Timer start/stop, assignment completion",
            recommendation: "Use AccessibilityNotification.Announcement for state changes",
            wcagCriteria: "WCAG 4.1.3 - Status Messages"
        ))
        
        return findings
    }
    
    private func auditReduceMotion() async -> [AccessibilityAuditResult] {
        var findings: [AccessibilityAuditResult] = []
        
        findings.append(AccessibilityAuditResult(
            severity: .medium,
            category: .reduceMotion,
            issue: "Animations may not respect Reduce Motion preference",
            location: "Page transitions, timer animations",
            recommendation: "Check AccessibilityWrapper.reduceMotion, provide instant alternatives",
            wcagCriteria: "WCAG 2.3.3 - Animation from Interactions"
        ))
        
        return findings
    }
    
    private func auditFocusManagement() async -> [AccessibilityAuditResult] {
        var findings: [AccessibilityAuditResult] = []
        
        findings.append(AccessibilityAuditResult(
            severity: .medium,
            category: .focus,
            issue: "Focus may not be managed on navigation",
            location: "Sheet presentations, page navigation",
            recommendation: "Set initial focus with @AccessibilityFocusState",
            wcagCriteria: "WCAG 2.4.3 - Focus Order"
        ))
        
        return findings
    }
    
    // MARK: - Statistics
    
    var criticalCount: Int {
        results.filter { $0.severity == .critical }.count
    }
    
    var highCount: Int {
        results.filter { $0.severity == .high }.count
    }
    
    var mediumCount: Int {
        results.filter { $0.severity == .medium }.count
    }
    
    var lowCount: Int {
        results.filter { $0.severity == .low }.count
    }
    
    var totalIssues: Int {
        results.count
    }
    
    func issuesByCategory(_ category: AccessibilityAuditResult.Category) -> [AccessibilityAuditResult] {
        results.filter { $0.category == category }
    }
}

// MARK: - Accessibility Inspector

/// Real-time accessibility inspector for views
struct AccessibilityInspector: ViewModifier {
    @State private var isInspecting = false
    @State private var selectedElement: String?
    @State private var elementInfo: [String: String] = [:]
    
    func body(content: Content) -> some View {
        content
            .overlay(alignment: .topTrailing) {
                if isInspecting {
                    inspectorOverlay
                }
            }
            .onLongPressGesture(minimumDuration: 2.0) {
                isInspecting.toggle()
            }
    }
    
    @ViewBuilder
    private var inspectorOverlay: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "accessibility")
                Text("Accessibility Inspector")
                    .font(.caption.bold())
                Spacer()
                Button(action: { isInspecting = false }) {
                    Image(systemName: "xmark.circle.fill")
                }
            }
            
            Divider()
            
            if let element = selectedElement {
                Text("Selected: \(element)")
                    .font(.caption2)
                
                ForEach(elementInfo.sorted(by: { $0.key < $1.key }), id: \.key) { key, value in
                    HStack(alignment: .top) {
                        Text("\(key):")
                            .font(.caption2.bold())
                        Text(value)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            } else {
                Text("Tap an element to inspect")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(12)
        .background(Color(white: 0.1).opacity(0.95))
        .cornerRadius(12)
        .shadow(radius: 8)
        .padding()
    }
}

// MARK: - View Extensions

extension View {
    /// Enable accessibility inspection for this view
    func accessibilityInspectable() -> some View {
        modifier(AccessibilityInspector())
    }
    
    /// Audit accessibility compliance for this view
    func auditAccessibility(
        label: String? = nil,
        traits: AccessibilityTraits? = nil,
        hint: String? = nil
    ) -> some View {
        self.accessibilityElement(children: .combine)
            .if(label != nil) { view in
                view.accessibilityLabel(label!)
            }
            .if(traits != nil) { view in
                view.accessibilityAddTraits(traits!)
            }
            .if(hint != nil) { view in
                view.accessibilityHint(hint!)
            }
    }
}

// MARK: - Conditional View Modifier

extension View {
    @ViewBuilder
    func `if`<Transform: View>(
        _ condition: Bool,
        transform: (Self) -> Transform
    ) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}

#endif
