import SwiftUI

#if os(macOS)
    extension Space {
        static let formSectionSpacing: CGFloat = 10
        static let formRowSpacing: CGFloat = 6
    }

    extension View {
        func compactFormSections() -> some View {
            self.environment(\.defaultMinListRowHeight, 24)
        }
    }
#endif
