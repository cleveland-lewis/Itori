import SwiftUI

enum RootsIconButtonRole { case primaryAccent, secondary, destructive }

struct RootsIconButton: View {
    var systemName: String
    var role: RootsIconButtonRole = .primaryAccent
    var size: CGFloat = 44
    var accessibilityLabel: String? = nil
    var action: () -> Void

    var body: some View {
        RootsHeaderButton(icon: systemName, size: size) {
            action()
        }
        .accessibilityLabel(accessibilityLabel ?? systemName)
    }
}

struct RootsIconButtonLabel: View {
    var role: RootsIconButtonRole = .primaryAccent
    var systemName: String
    var size: CGFloat = 44

    var body: some View {
        Image(systemName: systemName)
            .font(.system(size: 16, weight: .semibold))
            .foregroundColor(role == .secondary ? .primary : .white)
            .frame(width: size, height: size)
            .background(
                Circle()
                    .fill((role == .secondary ? Color.primary.opacity(0.1) : RootsColor.accent.opacity(0.8)))
                    .background(Circle().fill(DesignSystem.Materials.hud))
            )
            .overlay(
                Circle().stroke(.white.opacity(0.12), lineWidth: 0.75)
            )
            .shadow(color: (role == .secondary ? Color.primary.opacity(0.1) : RootsColor.accent.opacity(0.25)), radius: 14, y: 8)
    }
}

struct RootsIconButtonLabel: View {
    var role: RootsIconButtonRole = .primaryAccent
    var systemName: String
    var size: CGFloat = 44

    private var background: Color {
        switch role {
        case .primaryAccent: return RootsColor.accent
        case .secondary: return RootsColor.subtleFill
        case .destructive: return Color.red.opacity(0.85)
        }
    }

    var body: some View {
        Image(systemName: systemName)
            .font(.system(size: 16, weight: .semibold))
            .foregroundColor(role == .secondary ? .primary : .white)
            .frame(width: size, height: size)
            .background(
                Circle()
                    .fill(background.opacity(role == .secondary ? 0.1 : 0.8))
                    .background(Circle().fill(DesignSystem.Materials.hud))
            )
            .overlay(
                Circle().stroke(.white.opacity(0.12), lineWidth: 0.75)
            )
            .shadow(color: background.opacity(0.25), radius: 14, y: 8)
    }
}
