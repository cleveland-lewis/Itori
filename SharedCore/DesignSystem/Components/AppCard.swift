import SwiftUI

struct AppCard<Content: View>: View {
    @EnvironmentObject private var settings: AppSettingsModel
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.interfacePreferences) private var prefs
    let title: String?
    let icon: Image?
    let iconBounceTrigger: Bool
    let content: Content
    private let isPopup: Bool

    init(
        title: String? = nil,
        icon: Image? = nil,
        iconBounceTrigger: Bool = false,
        isPopup: Bool = true,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.icon = icon
        self.iconBounceTrigger = iconBounceTrigger
        self.isPopup = isPopup
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: prefs.spacing.md) {
            if title != nil || icon != nil {
                header
            }

            content
                .font(settings.font(for: .body))
                .foregroundStyle(.primary)
        }
        .padding(prefs.spacing.cardPadding)
        .frame(minHeight: 180)
        .prefsCardMaterial()
        .prefsBorder()
        .contentTransition(.opacity)
        .modifier(PopupAlignmentModifier(isPopup: isPopup))
    }

    private var header: some View {
        HStack(spacing: prefs.spacing.sm) {
            if let icon {
                icon
                    .font(.title2)
                    .symbolEffect(.bounce, value: iconBounceTrigger)
                    .transition(.cardHeaderTransition)
            }

            if let title {
                Text(title)
                    .font(.title2).fontWeight(.semibold)
                    .foregroundStyle(.primary)
                    .transition(.cardHeaderTransition)
            }

            Spacer()
        }
        .contentTransition(.opacity)
    }

}

private extension AnyTransition {
    static var cardHeaderTransition: AnyTransition {
        let opacity = AnyTransition.opacity
        let scale = AnyTransition.scale(scale: 0.95)
        return .asymmetric(insertion: opacity.combined(with: scale), removal: opacity.combined(with: scale))
    }
}

private struct PopupAlignmentModifier: ViewModifier {
    let isPopup: Bool

    func body(content: Content) -> some View {
        if isPopup {
            content.popupTextAlignedLeft()
        } else {
            content
        }
    }
}
