import SwiftUI

enum ItoriIconButtonRole { case primaryAccent, secondary, destructive }

struct ItoriIconButton: View {
    var systemName: String
    var role: ItoriIconButtonRole = .primaryAccent
    var size: CGFloat = 44
    var accessibilityLabel: String?
    var action: () -> Void

    var body: some View {
        ItoriHeaderButton(icon: systemName, size: size) {
            action()
        }
        .accessibilityLabelWithTooltip(accessibilityLabel ?? systemName)
    }
}

struct ItoriIconButtonLabel: View {
    var role: ItoriIconButtonRole = .primaryAccent
    var systemName: String
    var size: CGFloat = 44

    var body: some View {
        ItoriHeaderButton(icon: systemName, size: size) {}
    }
}
