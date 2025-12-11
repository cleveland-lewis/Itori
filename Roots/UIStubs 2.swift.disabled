import SwiftUI

// Lightweight stubs for missing design components used throughout the app.
// These are minimal implementations to allow the project to compile; substitute
// the real design-system components in the main app.

struct EmptyStateView: View {
    let icon: String
    var body: some View {
        VStack(spacing: DesignSystem.Layout.spacing.small) {
            Image(systemName: icon)
                .font(DesignSystem.Typography.display)
            Text(DesignSystem.emptyStateMessage)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, minHeight: DesignSystem.Cards.cardMinHeight)
    }
}

struct GlassLoadingCard: View {
    let title: String
    let message: String?

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: DesignSystem.Cards.cardCornerRadius, style: .continuous)
                .fill(.thinMaterial)
            VStack(alignment: .leading) {
                Text(title).font(DesignSystem.Typography.subHeader)
                if let m = message { Text(m).font(DesignSystem.Typography.caption).foregroundStyle(.secondary) }
            }
            .padding(DesignSystem.Layout.padding.card)
        }
        .frame(minHeight: DesignSystem.Cards.cardMinHeight)
    }
}

extension View {
    func loadingHUD(isVisible: Binding<Bool>, title: String = "", message: String? = nil) -> some View {
        // No-op wrapper for now — production app will overlay a HUD.
        self
    }
}
