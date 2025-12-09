import SwiftUI

struct RootsTooltipModifier: ViewModifier {
    let text: String
    @State private var isVisible = false
    @State private var workItem: DispatchWorkItem?

    func body(content: Content) -> some View {
        content
            .onHover { hovering in
                handleHover(hovering)
            }
            .overlay(alignment: .top) {
                if isVisible {
                    Text(text)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(DesignSystem.Materials.hud, in: Capsule())
                        .shadow(radius: 4, y: 2)
                        .offset(y: -40)
                        .transition(.scale.combined(with: .opacity))
                }
            }
    }

    private func handleHover(_ hovering: Bool) {
        if hovering {
            let item = DispatchWorkItem { withAnimation(.easeInOut(duration: 0.2)) { isVisible = true } }
            workItem?.cancel()
            workItem = item
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.7, execute: item)
        } else {
            workItem?.cancel()
            workItem = nil
            withAnimation(.easeInOut(duration: 0.2)) {
                isVisible = false
            }
        }
    }
}

extension View {
    func rootsTooltip(_ text: String) -> some View {
        modifier(RootsTooltipModifier(text: text))
    }
}
