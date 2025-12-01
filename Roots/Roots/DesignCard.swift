import SwiftUI

struct AppCard {
        self.imageName = imageName
        self._material = material
        self.content = content
    }

    var body: some View {
        // Use the new AppCard for consistent visuals; keep image overlay for backwards compatibility
        AppCard {
            ZStack(alignment: .topLeading) {
                Image(imageName)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .clipped()

                VStack(spacing: DesignSystem.Spacing.medium) {
                    content()
                }
                .padding(DesignSystem.Spacing.medium)
            }
        }
        .frame(minHeight: DesignSystem.Cards.defaultHeight)
    }
}

struct AppCard { binding in
            AppCard {
                Image(systemName: "cube.fill")
                    .imageScale(.large)
                Text("Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.")
                    .foregroundStyle(.primary)
            }
            .frame(height: 260)
            .padding()
        }
    }
}

// Helper to provide Binding in previews
struct StatefulPreviewWrapper<Value, Content: View>: View {
    @State var value: Value
    var content: (Binding<Value>) -> Content

    init(_ value: Value, content: @escaping (Binding<Value>) -> Content) {
        _value = State(wrappedValue: value)
        self.content = content
    }

    var body: some View { content($value) }
}
