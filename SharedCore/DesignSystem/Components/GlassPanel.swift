import SwiftUI

#if os(macOS)
import AppKit

/// Native NSVisualEffectView wrapper for true glass/vibrancy effect
struct VisualEffectView: NSViewRepresentable {
    var material: NSVisualEffectView.Material = .hudWindow
    var blendingMode: NSVisualEffectView.BlendingMode = .behindWindow
    var state: NSVisualEffectView.State = .active

    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = state
        return view
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
        nsView.state = state
    }
}

/// Glass panel container with vibrancy and subtle border
struct GlassPanel<Content: View>: View {
    var material: NSVisualEffectView.Material
    var cornerRadius: CGFloat
    var showBorder: Bool
    let content: Content

    init(
        material: NSVisualEffectView.Material = .hudWindow,
        cornerRadius: CGFloat = 14,
        showBorder: Bool = true,
        @ViewBuilder content: () -> Content
    ) {
        self.material = material
        self.cornerRadius = cornerRadius
        self.showBorder = showBorder
        self.content = content()
    }

    var body: some View {
        ZStack {
            VisualEffectView(material: material, blendingMode: .behindWindow, state: .active)
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))

            content
                .padding(12)
        }
        .overlay(
            Group {
                if showBorder {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .strokeBorder(.white.opacity(0.12), lineWidth: 1)
                }
            }
        )
        .shadow(color: .black.opacity(0.15), radius: 10, y: 6)
    }
}

#else
// iOS/iPadOS fallback
struct GlassPanel<Content: View>: View {
    var cornerRadius: CGFloat
    var showBorder: Bool
    let content: Content

    init(
        cornerRadius: CGFloat = 14,
        showBorder: Bool = true,
        @ViewBuilder content: () -> Content
    ) {
        self.cornerRadius = cornerRadius
        self.showBorder = showBorder
        self.content = content()
    }

    var body: some View {
        content
            .padding(12)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(
                Group {
                    if showBorder {
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .strokeBorder(.white.opacity(0.12), lineWidth: 1)
                    }
                }
            )
            .shadow(color: .black.opacity(0.15), radius: 10, y: 6)
    }
}
#endif
