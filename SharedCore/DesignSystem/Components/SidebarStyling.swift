import SwiftUI

func makeSidebarBackground(colorScheme: ColorScheme) -> AnyView {
    #if os(macOS)
    let bg = Color.clear
        .background(.ultraThinMaterial)
        .overlay(
            Rectangle()
                .stroke(DesignSystem.Colors.neutralLine(for: colorScheme).opacity(colorScheme == .dark ? 0.16 : 0.12), lineWidth: 0.4)
        )
    #else
    let bg = Color.clear
        .background(.ultraThinMaterial)
        .overlay(
            Rectangle()
                .stroke(DesignSystem.Colors.neutralLine(for: colorScheme).opacity(colorScheme == .dark ? 0.16 : 0.12), lineWidth: 0.4)
        )
    #endif
    return AnyView(bg)
}

func makeSidebarRowBackground(isSelected: Bool, colorScheme: ColorScheme) -> AnyView {
    if isSelected {
        let fill = Color.accentColor.opacity(colorScheme == .dark ? 0.22 : 0.12)
        let background = RoundedRectangle(cornerRadius: 8, style: .continuous)
            .fill(fill)
            .padding(.vertical, 4)
            .padding(.horizontal, 4)
        return AnyView(background)
    } else {
        return AnyView(Color.clear)
    }
}
