import SwiftUI

#if os(macOS)
    struct CompactFormSectionsModifier: ViewModifier {
        func body(content: Content) -> some View {
            content
                .environment(\.defaultMinListHeaderHeight, 8)
        }
    }

    extension View {
        func compactFormSections() -> some View {
            self.modifier(CompactFormSectionsModifier())
        }
    }
#endif
