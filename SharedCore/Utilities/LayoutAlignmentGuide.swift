import SwiftUI

#if DEBUG
/// Visual debugging aid to verify canonical top content spacing across pages.
/// Shows a horizontal line at the position where content should begin.
struct LayoutAlignmentGuide: View {
    @Environment(\.appLayout) private var appLayout
    @State private var isVisible = false
    
    var body: some View {
        ZStack(alignment: .top) {
            if isVisible {
                guideLine
                    .zIndex(9999)
                    .allowsHitTesting(false)
            }
        }
        .onAppear {
            isVisible = UserDefaults.standard.bool(forKey: "debug.showLayoutGuide")
        }
    }
    
    private var guideLine: some View {
        VStack(spacing: 0) {
            Color.clear
                .frame(height: appLayout.topContentInset)
            
            ZStack {
                // Red line
                Rectangle()
                    .fill(Color.red.opacity(0.8))
                    .frame(height: 2)
                
                // Label
                HStack {
                    Text(verbatim: "Content Start Line: \(Int(appLayout.topContentInset))pt")
                        .font(.caption2.monospaced())
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(Color.red)
                        )
                        .shadow(radius: 4)
                    Spacer()
                }
                .padding(.leading, 16)
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

extension View {
    /// Adds a visual debug overlay showing the canonical content start line.
    /// Enable/disable by setting UserDefaults key "debug.showLayoutGuide" to true/false.
    ///
    /// Usage:
    /// ```
    /// .overlay {
    ///     LayoutAlignmentGuide()
    /// }
    /// ```
    ///
    /// Toggle in Xcode console:
    /// ```
    /// // Enable
    /// po UserDefaults.standard.set(true, forKey: "debug.showLayoutGuide")
    ///
    /// // Disable
    /// po UserDefaults.standard.set(false, forKey: "debug.showLayoutGuide")
    /// ```
    func debugLayoutAlignment() -> some View {
        overlay {
            LayoutAlignmentGuide()
        }
    }
}
#endif
