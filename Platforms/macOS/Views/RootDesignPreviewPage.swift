#if os(macOS)
import SwiftUI

struct RootDesignPreviewPage: View {
    @Environment(\.colorScheme) var colorScheme
    @State private var selectedMaterial: DesignMaterial = .regular

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.large) {
                Text(NSLocalizedString("ui.design.tokens", value: "Design Tokens", comment: "Design Tokens"))
                    .font(DesignSystem.Typography.title)

                // Colors
                VStack(alignment: .leading) {
                    Text(NSLocalizedString("ui.colors", value: "Colors", comment: "Colors")).font(DesignSystem.Typography.subHeader)
                    HStack {
                        ColorSwatch(name: "Primary", color: DesignSystem.Colors.primary)
                        ColorSwatch(name: "Secondary", color: DesignSystem.Colors.secondary)
                        ColorSwatch(name: "Destructive", color: DesignSystem.Colors.destructive)
                        ColorSwatch(name: "Subtle", color: DesignSystem.Colors.subtle)
                        ColorSwatch(name: "Neutral", color: DesignSystem.Colors.neutral)
                    }
                }

                // Typography
                VStack(alignment: .leading) {
                    Text(NSLocalizedString("ui.typography", value: "Typography", comment: "Typography")).font(DesignSystem.Typography.subHeader)
                    Text(NSLocalizedString("ui.title.body.caption", value: "Title / body / caption", comment: "Title / body / caption"))
                        .font(DesignSystem.Typography.title)
                    Text(NSLocalizedString("ui.body.example", value: "Body example", comment: "Body example"))
                        .font(DesignSystem.Typography.body)
                    Text(NSLocalizedString("ui.caption.example", value: "Caption example", comment: "Caption example"))
                        .font(DesignSystem.Typography.caption)
                }

                // Materials
                VStack(alignment: .leading) {
                    Text(NSLocalizedString("ui.materials", value: "Materials", comment: "Materials")).font(DesignSystem.Typography.subHeader)
                    Picker("Material", selection: $selectedMaterial) {
                        ForEach(DesignSystem.materials, id: \.name) { token in
                            Text(token.name).tag(token)
                        }
                    }
                    .pickerStyle(.segmented)

                    AppCard {
                        Image(systemName: "cube.fill")
                            .imageScale(.large)
                        Text(NSLocalizedString("ui.material.preview", value: "Material preview", comment: "Material preview"))
                    }
                    .frame(minHeight: DesignSystem.Cards.defaultHeight)
                }

                // Corners & spacing
                VStack(alignment: .leading) {
                    Text(NSLocalizedString("ui.corners.spacing", value: "Corners & Spacing", comment: "Corners & Spacing")).font(DesignSystem.Typography.subHeader)
                    HStack {
                        RoundedRectangle(cornerRadius: DesignSystem.Corners.small)
                            .fill(Color.secondary)
                            .frame(width: 60, height: 60)
                        RoundedRectangle(cornerRadius: DesignSystem.Corners.medium)
                            .fill(Color.secondary)
                            .frame(width: 60, height: 60)
                        RoundedRectangle(cornerRadius: DesignSystem.Corners.large)
                            .fill(Color.secondary)
                            .frame(width: 60, height: 60)
                    }
                }

                Spacer()
            }
            .padding(DesignSystem.Layout.padding.card)
        }
        .navigationTitle("Design System Preview")
        .background(DesignSystem.background(for: colorScheme))
    }
}

private struct ColorSwatch: View {
    var name: String
    var color: Color

    var body: some View {
        VStack {
            Rectangle()
                .fill(color)
                .frame(width: 60, height: 60)
                .cornerRadius(8)
            Text(name).font(DesignSystem.Typography.caption)
        }
    }
}

#if !DISABLE_PREVIEWS
#if !DISABLE_PREVIEWS
#Preview {
    RootDesignPreviewPage()
}
#endif
#endif
#endif
