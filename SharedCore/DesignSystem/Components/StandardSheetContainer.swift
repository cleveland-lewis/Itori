import SwiftUI

/// Standard container for all sheet/popup views in the app
/// Provides consistent styling, sizing, and behavior
struct StandardSheetContainer<Content: View>: View {
    let title: String
    let content: Content
    let onDismiss: () -> Void
    let primaryAction: (() -> Void)?
    let primaryActionTitle: String
    let primaryActionDisabled: Bool
    let hasUnsavedChanges: Bool

    @State private var showDiscardDialog = false

    init(
        title: String,
        primaryActionTitle: String = "Save",
        primaryAction: (() -> Void)? = nil,
        primaryActionDisabled: Bool = false,
        hasUnsavedChanges: Bool = false,
        onDismiss: @escaping () -> Void,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.primaryActionTitle = primaryActionTitle
        self.primaryAction = primaryAction
        self.primaryActionDisabled = primaryActionDisabled
        self.hasUnsavedChanges = hasUnsavedChanges
        self.onDismiss = onDismiss
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Text(title)
                    .font(.system(size: 20, weight: .semibold))

                Spacer()

                Button {
                    handleDismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(.secondary)
                        .symbolRenderingMode(.hierarchical)
                }
                .buttonStyle(.itariLiquid)
                .keyboardShortcut(.cancelAction)
                .help("Close")
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)
            .padding(.bottom, 16)

            Divider()

            // Content
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    content
                }
                .padding(24)
            }
            .frame(maxHeight: .infinity)

            Divider()

            // Footer with actions
            HStack {
                Button("Cancel") {
                    handleDismiss()
                }
                .buttonStyle(.itariLiquid)
                .keyboardShortcut(.escape)

                Spacer()

                if let primaryAction {
                    Button(primaryActionTitle) {
                        primaryAction()
                    }
                    .buttonStyle(.itoriLiquidProminent)
                    .keyboardShortcut(.defaultAction)
                    .disabled(primaryActionDisabled)
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
        }
        .frame(minWidth: 480, idealWidth: 560, maxWidth: 720)
        .frame(minHeight: 400, idealHeight: 600, maxHeight: .infinity)
        .background(.regularMaterial)
        .interactiveDismissDisabled(hasUnsavedChanges)
        .confirmationDialog(
            "Discard unsaved changes?",
            isPresented: $showDiscardDialog,
            titleVisibility: .visible
        ) {
            Button("Discard", role: .destructive) {
                onDismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("You have unsaved changes that will be lost.")
        }
    }

    private func handleDismiss() {
        if hasUnsavedChanges {
            showDiscardDialog = true
        } else {
            onDismiss()
        }
    }
}

/// Compact variant for smaller popups
struct CompactSheetContainer<Content: View>: View {
    let title: String
    let content: Content
    let onDismiss: () -> Void
    let primaryAction: (() -> Void)?
    let primaryActionTitle: String
    let primaryActionDisabled: Bool

    init(
        title: String,
        primaryActionTitle: String = "Done",
        primaryAction: (() -> Void)? = nil,
        primaryActionDisabled: Bool = false,
        onDismiss: @escaping () -> Void,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.primaryActionTitle = primaryActionTitle
        self.primaryAction = primaryAction
        self.primaryActionDisabled = primaryActionDisabled
        self.onDismiss = onDismiss
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Text(title)
                    .font(.system(size: 17, weight: .semibold))

                Spacer()

                Button {
                    onDismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(.secondary)
                        .symbolRenderingMode(.hierarchical)
                }
                .buttonStyle(.itariLiquid)
                .keyboardShortcut(.cancelAction)
            }
            .padding(16)

            Divider()

            // Content
            VStack(alignment: .leading, spacing: 12) {
                content
            }
            .padding(16)

            if primaryAction != nil {
                Divider()

                // Footer
                HStack {
                    Spacer()

                    Button(primaryActionTitle) {
                        primaryAction?()
                    }
                    .buttonStyle(.itoriLiquidProminent)
                    .controlSize(.small)
                    .keyboardShortcut(.defaultAction)
                    .disabled(primaryActionDisabled)
                }
                .padding(16)
            }
        }
        .frame(width: 320)
        .background(.regularMaterial)
    }
}

#Preview("Standard Sheet") {
    StandardSheetContainer(
        title: "Add Assignment",
        primaryActionTitle: "Save",
        primaryAction: {},
        onDismiss: {}
    ) {
        VStack(spacing: 16) {
            TextField("Title", text: .constant(""))
            TextField("Description", text: .constant(""), axis: .vertical)
                .lineLimit(4 ... 6)
        }
    }
}

#Preview("Compact Sheet") {
    CompactSheetContainer(
        title: "Quick Action",
        primaryActionTitle: "Done",
        primaryAction: {},
        onDismiss: {}
    ) {
        VStack(spacing: 12) {
            Text("This is a compact popup for quick actions")
                .font(.system(size: 13))
            Toggle("Enable feature", isOn: .constant(true))
        }
    }
}
