#if os(iOS)
    import SwiftUI

    struct SafeAreaInsetsKey: PreferenceKey {
        static var defaultValue: EdgeInsets = .init()

        static func reduce(value: inout EdgeInsets, nextValue: () -> EdgeInsets) {
            value = nextValue()
        }
    }

    extension View {
        func readSafeAreaInsets(_ onChange: @escaping (EdgeInsets) -> Void) -> some View {
            background(
                GeometryReader { proxy in
                    Color.clear.preference(key: SafeAreaInsetsKey.self, value: proxy.safeAreaInsets)
                }
            )
            .onPreferenceChange(SafeAreaInsetsKey.self, perform: onChange)
        }
    }
#endif
