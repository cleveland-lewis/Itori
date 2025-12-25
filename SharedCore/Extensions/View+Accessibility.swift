import SwiftUI

// MARK: - Accessibility View Modifiers

extension View {
    /// Apply help/tooltip text only if tooltips are enabled in settings
    /// Note: On iOS, .help() is primarily for VoiceOver. On macOS, it shows hover tooltips.
    func conditionalHelp(_ text: String, settings: AppSettingsModel = .shared) -> some View {
        Group {
            if settings.showTooltips {
                self.help(text)
            } else {
                self
            }
        }
    }
}
