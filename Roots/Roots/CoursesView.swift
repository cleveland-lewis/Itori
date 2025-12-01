import SwiftUI

struct CoursesView: View {
    // No sample courses — empty only
    private let courses: [Any] = []

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.large) {
                // Header
                HStack(alignment: .center, spacing: DesignSystem.Spacing.medium) {
                    Text("Courses")
                        .font(DesignSystem.Typography.title)

                    Spacer()

                    // Toolbar area: Add Course + filters (stubs)
                    HStack(spacing: DesignSystem.Spacing.small) {
                        Button(action: {}) {
                            Label("Add Course", systemImage: "plus")
                        }
                        .buttonStyle(.borderedProminent)

                        Menu {
                            Button("Sort: Name", action: {})
                            Button("Sort: Instructor", action: {})
                        } label: {
                            Image(systemName: "arrow.up.arrow.down")
                        }
                    }
                }

                // Main area
                if courses.isEmpty {
                    DesignCard(imageName: "Tahoe", material: .constant(DesignSystem.materials.first?.material ?? Material.regularMaterial)) {
                        VStack(spacing: DesignSystem.Spacing.small) {
                            Image(systemName: "book.closed")
                                .imageScale(.large)
                            Text("Courses")
                                .font(DesignSystem.Typography.title)
                            Text(DesignSystem.emptyStateMessage)
                                .font(DesignSystem.Typography.body)
                                .foregroundStyle(.primary)
                        }
                    }
                    .frame(height: DesignSystem.Cards.defaultHeight)
                } else {
                    // TODO: render course cards in a grid
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 300), spacing: DesignSystem.Spacing.medium)], spacing: DesignSystem.Spacing.medium) {
                        // Placeholder for future course cards
                    }
                }
            }
            .padding(DesignSystem.Spacing.large)
        }
        .background(DesignSystem.background(for: .light))
    }
}

struct CoursesView_Previews: PreviewProvider {
    static var previews: some View {
        CoursesView()
    }
}
