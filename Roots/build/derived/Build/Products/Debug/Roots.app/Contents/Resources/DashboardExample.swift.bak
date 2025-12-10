import SwiftUI

struct DashboardExample: View {
    var body: some View {
        ScrollView {
            RootsDashboardGrid {
                ForEach(0..<6) { idx in
                    RootsCard(title: "Card \(idx)") {
                        VStack(alignment: .leading, spacing: DesignSystem.Layout.spacing.medium) {
                            Text("Card Title")
                                .font(DesignSystem.Typography.header)
                            Text("Summary or content goes here.")
                                .font(DesignSystem.Typography.body)
                                .foregroundStyle(.secondary)
                        }
                        .padding(DesignSystem.Layout.padding.card)
                    }
                }
            }
            .padding(.top, DesignSystem.Layout.spacing.medium)
        }
        .background(DesignSystem.background(for: .light))
    }
}

struct DashboardExample_Previews: PreviewProvider {
    static var previews: some View {
        DashboardExample()
    }
}
