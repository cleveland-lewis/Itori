import SwiftUI

enum RootsIconButtonRole { case primaryAccent, secondary, destructive }

struct RootsIconButton: View {
    var systemName: String
    var role: RootsIconButtonRole = .primaryAccent
    var size: CGFloat = 44
    var accessibilityLabel: String?
    var action: () -> Void

    var body: some View {
        RootsHeaderButton(icon: systemName, size: size) {
            action()
        }
        .accessibilityLabelWithTooltip(accessibilityLabel ?? systemName)
    }
}

struct RootsIconButtonLabel: View {
    var role: RootsIconButtonRole = .primaryAccent
    var systemName: String
    var size: CGFloat = 44

    var body: some View {
        RootsHeaderButton(icon: systemName, size: size) {}
    }
}
