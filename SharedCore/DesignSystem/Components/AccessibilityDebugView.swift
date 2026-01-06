import SwiftUI
#if canImport(AppKit)
import AppKit
#endif
#if canImport(UIKit)
import UIKit
#endif

#if DEBUG

#if os(macOS)
private let _panelBackground = Color(nsColor: .textBackgroundColor)
private let _controlBackground = Color(nsColor: .controlBackgroundColor)
#else
private let _panelBackground = Color(uiColor: .systemBackground)
private let _controlBackground = Color(uiColor: .secondarySystemBackground)
#endif

/// Debug-only view for testing accessibility features and simulating system settings
/// Allows developers to preview accessibility states without changing system settings
struct AccessibilityDebugView: View {
    @ObservedObject private var coordinator = AccessibilityCoordinator.shared
    @ObservedObject private var animationPolicy = AnimationPolicy.shared
    
    @State private var simulateReduceMotion = false
    @State private var simulateReduceTransparency = false
    @State private var simulateIncreaseContrast = false
    @State private var simulateDifferentiateWithoutColor = false
    @State private var simulateVoiceOver = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                headerSection
                currentStatusSection
                simulationSection
                previewSection
            }
            .padding(24)
        }
        .frame(minWidth: 600, minHeight: 500)
        .background(_panelBackground)
    }
    
    // MARK: - Header
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(NSLocalizedString("accessibilitydebug.accessibility.debug.tools", value: "Accessibility Debug Tools", comment: "Accessibility Debug Tools"))
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text(NSLocalizedString("accessibilitydebug.test.and.preview.accessibility.features", value: "Test and preview accessibility features without changing system settings", comment: "Test and preview accessibility features without ch..."))
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            Divider()
        }
    }
    
    // MARK: - Current System Status
    
    private var currentStatusSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(NSLocalizedString("accessibilitydebug.current.system.settings", value: "Current System Settings", comment: "Current System Settings"))
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 8) {
                statusRow(
                    title: "Reduce Motion",
                    isEnabled: coordinator.isReduceMotionEnabled
                )
                statusRow(
                    title: "Reduce Transparency",
                    isEnabled: coordinator.isReduceTransparencyEnabled
                )
                statusRow(
                    title: "Increase Contrast",
                    isEnabled: coordinator.isIncreaseContrastEnabled
                )
                statusRow(
                    title: "Differentiate Without Color",
                    isEnabled: coordinator.isDifferentiateWithoutColorEnabled
                )
                statusRow(
                    title: "VoiceOver",
                    isEnabled: coordinator.isVoiceOverEnabled
                )
                statusRow(
                    title: "Switch Control",
                    isEnabled: coordinator.isSwitchControlEnabled
                )
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(_controlBackground)
            )
            
            Divider()
        }
    }
    
    // MARK: - Simulation Controls
    
    private var simulationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(NSLocalizedString("accessibilitydebug.simulate.accessibility.features", value: "Simulate Accessibility Features", comment: "Simulate Accessibility Features"))
                .font(.headline)
            
            Text(NSLocalizedString("accessibilitydebug.note.these.simulations.are.for", value: "Note: These simulations are for preview only and don't affect actual system behavior", comment: "Note: These simulations are for preview only and d..."))
                .font(.caption)
                .foregroundStyle(.secondary)
            
            VStack(alignment: .leading, spacing: 12) {
                Toggle(NSLocalizedString("accessibilitydebug.toggle.reduce.motion", value: "Reduce Motion", comment: "Reduce Motion"), isOn: $simulateReduceMotion)
                Toggle(NSLocalizedString("accessibilitydebug.toggle.reduce.transparency", value: "Reduce Transparency", comment: "Reduce Transparency"), isOn: $simulateReduceTransparency)
                Toggle(NSLocalizedString("accessibilitydebug.toggle.increase.contrast", value: "Increase Contrast", comment: "Increase Contrast"), isOn: $simulateIncreaseContrast)
                Toggle(NSLocalizedString("accessibilitydebug.toggle.differentiate.without.color", value: "Differentiate Without Color", comment: "Differentiate Without Color"), isOn: $simulateDifferentiateWithoutColor)
                Toggle(NSLocalizedString("accessibilitydebug.toggle.voiceover.active", value: "VoiceOver Active", comment: "VoiceOver Active"), isOn: $simulateVoiceOver)
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(_controlBackground)
            )
            
            Divider()
        }
    }
    
    // MARK: - Live Preview
    
    private var previewSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(NSLocalizedString("accessibilitydebug.live.preview", value: "Live Preview", comment: "Live Preview"))
                .font(.headline)
            
            VStack(spacing: 16) {
                // Button preview
                HStack(spacing: 12) {
                    Button(NSLocalizedString("accessibilitydebug.button.standard.button", value: "Standard Button", comment: "Standard Button")) { }
                        .buttonStyle(.borderedProminent)
                    
                    Button(NSLocalizedString("accessibilitydebug.button.secondary.button", value: "Secondary Button", comment: "Secondary Button")) { }
                        .buttonStyle(.bordered)
                }
                
                // Card preview with glass effect
                VStack(alignment: .leading, spacing: 8) {
                    Text(NSLocalizedString("accessibilitydebug.sample.card", value: "Sample Card", comment: "Sample Card"))
                        .font(.headline)
                    Text(NSLocalizedString("accessibilitydebug.this.card.demonstrates.material.effects", value: "This card demonstrates material effects", comment: "This card demonstrates material effects"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(simulateReduceTransparency ? 
                              AnyShapeStyle(_panelBackground) :
                              AnyShapeStyle(.regularMaterial))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(
                            Color.primary.opacity(simulateIncreaseContrast ? 0.3 : 0.12),
                            lineWidth: simulateIncreaseContrast ? 1.5 : 1.0
                        )
                )
                
                // Animation preview
                HStack {
                    Text(NSLocalizedString("accessibilitydebug.animation", value: "Animation:", comment: "Animation:"))
                        .font(.subheadline)
                    
                    Text(simulateReduceMotion ? "Reduced/Disabled" : "Full animations")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(simulateReduceMotion ? .orange : .green)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(_controlBackground.opacity(0.5))
            )
        }
    }
    
    // MARK: - Helper Views
    
    private func statusRow(title: String, isEnabled: Bool) -> some View {
        HStack {
            Text(title)
                .font(.body)
            Spacer()
            Image(systemName: isEnabled ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(isEnabled ? .green : .secondary)
                .font(.body)
        }
    }
}

// MARK: - Preview

struct AccessibilityDebugView_Previews: PreviewProvider {
    static var previews: some View {
        AccessibilityDebugView()
    }
}

#endif

