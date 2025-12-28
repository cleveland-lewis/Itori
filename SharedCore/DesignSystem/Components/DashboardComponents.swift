import SwiftUI

/// Native macOS dashboard card following Apple's Human Interface Guidelines
/// - Uses system materials and semantic colors
/// - Adaptive layout with proper spacing
/// - Built-in empty and loading states
struct DashboardCard<Content: View, HeaderContent: View, FooterContent: View>: View {
    let title: String
    let systemImage: String
    @ViewBuilder let content: () -> Content
    @ViewBuilder let header: () -> HeaderContent
    @ViewBuilder let footer: () -> FooterContent
    
    var isLoading: Bool = false
    
    init(
        title: String,
        systemImage: String,
        isLoading: Bool = false,
        @ViewBuilder content: @escaping () -> Content,
        @ViewBuilder header: @escaping () -> HeaderContent = { EmptyView() },
        @ViewBuilder footer: @escaping () -> FooterContent = { EmptyView() }
    ) {
        self.title = title
        self.systemImage = systemImage
        self.isLoading = isLoading
        self.content = content
        self.header = header
        self.footer = footer
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with optional custom content
            HStack {
                Label(title, systemImage: systemImage)
                    .font(.headline)
                    .foregroundStyle(.primary)
                
                Spacer()
                
                header()
            }
            
            // Main content
            if isLoading {
                loadingState
            } else {
                content()
            }
            
            // Footer with optional actions
            if !(footer() is EmptyView) {
                Divider()
                    .padding(.top, 4)
                footer()
            }
        }
        .padding(16)
        .background(.regularMaterial)
        .clipShape(.rect(cornerRadius: 10))
        .overlay {
            RoundedRectangle(cornerRadius: 10)
                .strokeBorder(.separator.opacity(0.5), lineWidth: 0.5)
        }
    }
    
    private var loadingState: some View {
        VStack(spacing: 8) {
            ForEach(0..<3, id: \.self) { _ in
                RoundedRectangle(cornerRadius: 4)
                    .fill(.tertiary)
                    .frame(height: 20)
            }
        }
        .redacted(reason: .placeholder)
    }
}

// Convenience initializer without header/footer
extension DashboardCard where HeaderContent == EmptyView, FooterContent == EmptyView {
    init(
        title: String,
        systemImage: String,
        isLoading: Bool = false,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.title = title
        self.systemImage = systemImage
        self.isLoading = isLoading
        self.content = content
        self.header = { EmptyView() }
        self.footer = { EmptyView() }
    }
}

// MARK: - Dashboard Grid

struct AdaptiveDashboardGrid<Content: View>: View {
    @ViewBuilder let content: () -> Content
    
    var body: some View {
        ScrollView {
            LazyVGrid(
                columns: [
                    GridItem(.adaptive(minimum: 300, maximum: 600), spacing: 20)
                ],
                spacing: 20
            ) {
                content()
            }
            .padding(20)
            .padding(.bottom, 100) // Dock clearance
        }
        .background(Color(nsColor: .windowBackgroundColor))
    }
}

// MARK: - Empty State View

struct DashboardEmptyState: View {
    let title: String
    let systemImage: String
    let description: String
    var action: (() -> Void)? = nil
    var actionTitle: String? = nil
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.system(size: 40))
                .foregroundStyle(.tertiary)
            
            Text(title)
                .font(.headline)
                .foregroundStyle(.secondary)
            
            if !description.isEmpty {
                Text(description)
                    .font(.subheadline)
                    .foregroundStyle(.tertiary)
                    .multilineTextAlignment(.center)
            }
            
            if let action, let actionTitle {
                Button(actionTitle, action: action)
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                    .padding(.top, 4)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
    }
}

// MARK: - Stat Row

struct DashboardStatRow: View {
    let label: String
    let value: String
    let icon: String
    var valueColor: Color = .primary
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(.secondary)
                .frame(width: 20)
            
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(valueColor)
                .monospacedDigit()
        }
    }
}

// MARK: - Quick Action Button

struct DashboardQuickAction: View {
    let title: String
    let icon: String
    let action: () -> Void
    var style: ButtonStyle = .borderedProminent
    
    enum ButtonStyle {
        case borderedProminent
        case bordered
        case plain
    }
    
    var body: some View {
        Button(action: action) {
            Label(title, systemImage: icon)
                .frame(maxWidth: .infinity)
        }
        .buttonStyleForType(style)
        .controlSize(.small)
    }
}

extension View {
    func buttonStyleForType(_ type: DashboardQuickAction.ButtonStyle) -> some View {
        Group {
            switch type {
            case .borderedProminent:
                self.buttonStyle(.borderedProminent)
            case .bordered:
                self.buttonStyle(.bordered)
            case .plain:
                self.buttonStyle(.plain)
            }
        }
    }
}

// MARK: - Preview

#Preview("Dashboard Components") {
    ScrollView {
        VStack(spacing: 20) {
            // Basic card
            DashboardCard(title: "Overview", systemImage: "chart.bar") {
                VStack(alignment: .leading, spacing: 8) {
                    DashboardStatRow(label: "Events", value: "5", icon: "calendar")
                    DashboardStatRow(label: "Tasks", value: "12", icon: "checkmark.circle")
                }
            }
            
            // Card with footer actions
            DashboardCard(
                title: "Assignments",
                systemImage: "doc.text"
            ) {
                Text("3 assignments due today")
                    .font(.body)
                    .foregroundStyle(.secondary)
            } header: {
                Button {
                    print("Add tapped")
                } label: {
                    Image(systemName: "plus")
                }
                .buttonStyle(.plain)
                .font(.headline)
            } footer: {
                DashboardQuickAction(
                    title: "View All",
                    icon: "arrow.right",
                    action: {},
                    style: .bordered
                )
            }
            
            // Loading state
            DashboardCard(title: "Loading", systemImage: "clock", isLoading: true) {
                EmptyView()
            }
            
            // Empty state
            DashboardCard(title: "Events", systemImage: "calendar") {
                DashboardEmptyState(
                    title: "No Events",
                    systemImage: "calendar.badge.exclamationmark",
                    description: "Add your first event to get started",
                    action: { print("Add event") },
                    actionTitle: "Add Event"
                )
            }
        }
        .padding(20)
    }
    .frame(width: 400, height: 800)
}
