import SwiftUI

struct FanOutMenuItem: Identifiable {
    let id = UUID()
    let icon: String
    let label: String
    let action: () -> Void
}

struct RootsFanOutMenu: View {
    let items: [FanOutMenuItem]
    @State private var isOpen = false

    var body: some View {
        ZStack(alignment: .leading) {
            // Overlay to capture taps outside the menu
            if isOpen {
                Color.black.opacity(0.01)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(DesignSystem.Motion.interactiveSpring) {
                            isOpen = false
                        }
                    }
            }

            HStack(spacing: DesignSystem.Layout.spacing.small) {
                // Trigger button
                Button {
                    withAnimation(DesignSystem.Motion.interactiveSpring) {
                        isOpen.toggle()
                    }
                } label: {
                    Image(systemName: "plus")
                        .rotationEffect(.degrees(isOpen ? 45 : 0))
                        .font(DesignSystem.Typography.body)
                        .foregroundStyle(.primary)
                        .frame(width: 36, height: 36)
                        .background(
                            Circle()
                                .fill(DesignSystem.Materials.hud.opacity(isOpen ? 1.0 : 0.9))
                                .overlay(
                                    Circle()
                                        .stroke(isOpen ? Color.accentColor.opacity(0.4) : Color.clear, lineWidth: 1)
                                )
                        )
                }
                .buttonStyle(.plain)
                .contentShape(Circle())

                // Menu items fanning to the right
                if isOpen {
                    HStack(spacing: DesignSystem.Layout.spacing.small) {
                        ForEach(Array(items.enumerated()), id: \.1.id) { index, item in
                            Button {
                                withAnimation(DesignSystem.Motion.interactiveSpring) {
                                    isOpen = false
                                }
                                item.action()
                            } label: {
                                HStack(spacing: DesignSystem.Layout.spacing.small) {
                                    Image(systemName: item.icon)
                                        .font(DesignSystem.Typography.body)
                                        .foregroundStyle(.primary)
                                    Text(item.label)
                                        .font(DesignSystem.Typography.body)
                                        .foregroundStyle(.primary)
                                }
                                .padding(.horizontal, DesignSystem.Layout.spacing.medium)
                                .padding(.vertical, DesignSystem.Layout.spacing.small)
                                .background(DesignSystem.Materials.card, in: Capsule())
                            }
                            .buttonStyle(.plain)
                            .transition(.move(edge: .leading).combined(with: .opacity))
                            .animation(
                                DesignSystem.Motion.interactiveSpring.delay(Double(index) * 0.05),
                                value: isOpen
                            )
                        }
                    }
                }
            }
        }
    }
}

#if !DISABLE_PREVIEWS
#Preview {
    RootsFanOutMenu(items: [
        FanOutMenuItem(icon: "doc.badge.plus", label: "Add Assignment", action: {}),
        FanOutMenuItem(icon: "calendar.badge.plus", label: "Add Event", action: {}),
        FanOutMenuItem(icon: "graduationcap", label: "Add Course", action: {})
    ])
    .padding()
}
#endif
