import Foundation

enum PlatformCapabilities {
    static var supportsHiddenNavigationBar: Bool {
#if os(iOS)
        if #available(iOS 16.0, *) {
            return true
        }
        return false
#else
        return false
#endif
    }
}
