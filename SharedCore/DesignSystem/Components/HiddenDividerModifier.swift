import SwiftUI

#if os(macOS)
import AppKit

extension View {
    /// Hides the divider in a NavigationSplitView while maintaining resize functionality
    /// Uses safe AppKit APIs only - no KVC on undefined keys
    func hideSplitViewDivider() -> some View {
        self.onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                if let window = NSApp.keyWindow ?? NSApp.windows.first {
                    self.hideDivider(in: window.contentView)
                }
            }
        }
    }
    
    private func hideDivider(in view: NSView?) {
        guard let view = view else { return }
        
        if let splitView = view as? NSSplitView {
            // Use .thin for minimal visual weight
            // Note: dividerThickness and dividerColor are read-only properties
            // The .thin style provides the thinnest standard divider (1pt)
            // This is the only safe, supported API for controlling divider appearance
            splitView.dividerStyle = .thin
        }
        
        for subview in view.subviews {
            hideDivider(in: subview)
        }
    }
}

#else
extension View {
    func hideSplitViewDivider() -> some View {
        self
    }
}
#endif

