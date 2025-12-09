import SwiftUI

struct RootsFanOutMenu: View {
    let items: [(icon: String, label: String, action: () -> Void)]
    @State private var isOpen = false

    var body: some View {
        ZStack(alignment: .topLeading) {
            if isOpen {
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                        Button {
                            item.action()
                            closeMenuWithSpring()
                        } label: {
                            HStack(spacing: DesignSystem.Layout.spacing.small) {
                                Image(systemName: item.icon)
                                    .font(DesignSystem.Typography.body)
                                Text(item.label)
                                    .font(DesignSystem.Typography.body)
                            }
                            .padding(.vertical, 8)
                            .padding(.horizontal, 12)
                            .background(DesignSystem.Materials.hud, in: Capsule())
                            .shadow(color: Color.black.opacity(0.15), radius: 5, y: 2)
                        }
                        .buttonStyle(.plain)
                        .transition(.asymmetric(insertion: .scale.combined(with: .move(edge: .top)), removal: .opacity))
                        .animation(
                            .spring(response: 0.4, dampingFraction: 0.75)
                                .delay(isOpen ? Double(index) * 0.05 : 0),
                            value: isOpen
                        )
                    }
                }
                .offset(y: 50)
            }

            Button {
                withAnimation(DesignSystem.Motion.interactiveSpring) {
                    isOpen.toggle()
                }
            } label: {
                Image(systemName: "plus")
                    .font(DesignSystem.Typography.body)
                    .rotationEffect(.degrees(isOpen ? 45 : 0))
                    .frame(width: 36, height: 36)
            }
            .buttonStyle(.plain)
            .background(
                Circle()
                    .fill(DesignSystem.Materials.hud)
                    .overlay(
                        Circle()
                            .fill(Color.accentColor.opacity(isOpen ? 0.18 : 0))
                    )
                    .shadow(color: Color.black.opacity(isOpen ? 0.16 : 0.08), radius: isOpen ? 8 : 4, y: 3)
            )
            .contentShape(Circle())
        }
    }

    private func closeMenuWithSpring() {
        withAnimation(DesignSystem.Motion.interactiveSpring) {
            isOpen = false
        }
    }
}
