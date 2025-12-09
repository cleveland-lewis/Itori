import SwiftUI

struct RootsDashboardGrid<Content: View>: View {
    private let content: () -> Content

    private var columns: [GridItem] {
        [
            GridItem(.adaptive(minimum: 340, maximum: 600), spacing: DesignSystem.Layout.spacing.large)
        ]
    }

    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }

    var body: some View {
        LazyVGrid(columns: columns, spacing: DesignSystem.Layout.spacing.large) {
            content()
        }
        .padding(DesignSystem.Layout.padding.window)
    }
}
