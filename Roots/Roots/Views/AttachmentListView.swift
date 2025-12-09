import SwiftUI
import UniformTypeIdentifiers

/// A reusable view for displaying and managing file attachments
struct AttachmentListView: View {
    @Binding public var attachments: [Attachment]

    /// Whether to show module number field (for course materials)
    public var allowModuleNumber: Bool = true

    /// Filter which tags are available based on context
    public var availableTags: [AttachmentTag]

    @State private var showingFilePicker = false
    @State private var showingConfigSheet = false
    @State private var pendingFileURL: URL?
    @State private var pendingFileName: String = ""
    @State private var selectedTag: AttachmentTag = .other
    @State private var moduleNumber: String = ""

    // Use AttachmentManager when present; guard for compilation in modular builds
    private var attachmentManager: AttachmentManager? { AttachmentManager.shared }

    public var body: some View {
        VStack(alignment: .leading, spacing: RootsSpacing.m) {
            // Header with Add button
            HStack {
                Text("Attachments")
                    .rootsBodySecondary()
                Spacer()
                Button {
                    showingFilePicker = true
                } label: {
                    Label("Add File", systemImage: "plus.circle.fill")
                        .font(DesignSystem.Typography.caption).foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }

            // Attachments List
            if attachments.isEmpty {
                Text("No attachments yet")
                    .rootsCaption()
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, RootsSpacing.l)
            } else {
                VStack(spacing: RootsSpacing.s) {
                    ForEach(attachments) { attachment in
                        AttachmentRow(
                            attachment: attachment,
                            onDelete: { deleteAttachment(attachment) },
                            onOpen: { openAttachment(attachment) },
                            onParse: attachment.tag == .syllabus ? { parseAttachment(attachment) } : nil
                        )
                    }
                }
            }
        }
        .fileImporter(
            isPresented: $showingFilePicker,
            allowedContentTypes: [.pdf, .plainText, .rtf, .data],
            allowsMultipleSelection: false
        ) { result in
            handleFileSelection(result)
        }
        .sheet(isPresented: $showingConfigSheet) {
            AttachmentConfigSheet(
                fileName: pendingFileName,
                selectedTag: $selectedTag,
                moduleNumber: $moduleNumber,
                availableTags: availableTags,
                allowModuleNumber: allowModuleNumber,
                onSave: saveAttachment,
                onCancel: cancelAttachment
            )
        }
    }

    // MARK: - Actions

    private func handleFileSelection(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            pendingFileURL = url
            pendingFileName = url.lastPathComponent
            selectedTag = availableTags.first ?? .other
            moduleNumber = ""
            showingConfigSheet = true

        case .failure(let error):
            print("File selection error: \(error)")
        }
    }

    private func saveAttachment() {
        guard let sourceURL = pendingFileURL else { return }

        do {
            let savedURL = (try? attachmentManager?.saveFile(from: sourceURL)) ?? sourceURL

            let attachment = Attachment(
                name: pendingFileName,
                localURL: savedURL,
                tag: selectedTag,
                moduleNumber: moduleNumber.isEmpty ? nil : Int(moduleNumber)
            )

            attachments.append(attachment)
            showingConfigSheet = false
            pendingFileURL = nil

        } catch {
            print("Error saving attachment: \(error)")
        }
    }

    private func cancelAttachment() {
        showingConfigSheet = false
        pendingFileURL = nil
    }

    private func deleteAttachment(_ attachment: Attachment) {
        attachmentManager?.deleteFile(for: attachment)
        attachments.removeAll { $0.id == attachment.id }
    }

    private func openAttachment(_ attachment: Attachment) {
        attachmentManager?.openFile(attachment)
    }

    private func parseAttachment(_ attachment: Attachment) {
        // Stub for future AI parsing functionality
        print("Parsing attachment: \(attachment.name)")
        // TODO: Implement AI parsing service call
    }
}

// MARK: - Attachment Row

struct AttachmentRow: View {
    let attachment: Attachment
    let onDelete: () -> Void
    let onOpen: () -> Void
    let onParse: (() -> Void)?

    @State private var isHovering = false

    var body: some View {
        HStack(spacing: RootsSpacing.m) {
            // Icon
            Image(systemName: attachment.tag.icon)
                .foregroundStyle(.secondary)
                .frame(width: 20)

            // File info
            VStack(alignment: .leading, spacing: 2) {
                Text(attachment.name)
                    .rootsBody()
                    .lineLimit(1)

                HStack(spacing: RootsSpacing.s) {
                    Text(attachment.tag.rawValue)
                        .font(DesignSystem.Typography.caption).foregroundStyle(.secondary)

                    if let moduleNum = attachment.moduleNumber {
                        Text("•")
                            .font(DesignSystem.Typography.caption).foregroundStyle(.secondary)
                        Text("Module \(moduleNum)")
                            .font(DesignSystem.Typography.caption).foregroundStyle(.secondary)
                    }

                    if let size = attachment.formattedFileSize {
                        Text("•")
                            .font(DesignSystem.Typography.caption).foregroundStyle(.secondary)
                        Text(size)
                            .font(DesignSystem.Typography.caption).foregroundStyle(.secondary)
                    }
                }
            }

            Spacer()

            // Actions
            HStack(spacing: RootsSpacing.s) {
                if let onParse = onParse {
                    Button {
                        onParse()
                    } label: {
                        Text("Parse Outline")
                            .rootsCaption()
                    }
                    .buttonStyle(.plain)
                }

                Button {
                    onOpen()
                } label: {
                    Image(systemName: "arrow.up.forward.square")
                }
                .buttonStyle(.plain)
                .help("Open file")

                Button {
                    onDelete()
                } label: {
                    Image(systemName: "trash")
                        .foregroundStyle(.red)
                }
                .buttonStyle(.plain)
                .help("Delete attachment")
            }
            .opacity(isHovering ? 1 : 0.5)
        }
        .padding(.horizontal, RootsSpacing.m)
        .padding(.vertical, RootsSpacing.s)
        .background(
            RoundedRectangle(cornerRadius: RootsRadius.chip, style: .continuous)
                .fill(isHovering ? DesignSystem.Materials.surfaceHover : DesignSystem.Materials.surface)
        )
        .onHover { hovering in
            isHovering = hovering
        }
    }
}

// MARK: - Configuration Sheet

struct AttachmentConfigSheet: View {
    let fileName: String
    @Binding var selectedTag: AttachmentTag
    @Binding var moduleNumber: String
    let availableTags: [AttachmentTag]
    let allowModuleNumber: Bool
    let onSave: () -> Void
    let onCancel: () -> Void

    var body: some View {
        RootsPopupContainer(
            title: "Configure Attachment",
            subtitle: fileName
        ) {
            VStack(alignment: .leading, spacing: RootsSpacing.m) {
                // Tag Picker
                RootsFormRow(label: "Type") {
                    Picker("Type", selection: $selectedTag) {
                        ForEach(availableTags) { tag in
                            HStack {
                                Image(systemName: tag.icon)
                                Text(tag.rawValue)
                            }
                            .tag(tag)
                        }
                    }
                    .labelsHidden()
                }

                // Module Number (optional)
                if allowModuleNumber {
                    RootsFormRow(label: "Module") {
                        TextField("Optional", text: $moduleNumber)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 100)
                    } helper: {
                        Text("Leave blank if not associated with a module")
                            .rootsCaption()
                            .foregroundStyle(.secondary)
                            .padding(.leading, 110 + RootsSpacing.m)
                    }
                }
            }
        } footer: {
            HStack {
                Button("Cancel") {
                    onCancel()
                }
                .buttonStyle(.plain)

                Spacer()

                Button("Save") {
                    onSave()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
    }
}

// MARK: - Preview

#Preview {
    struct PreviewWrapper: View {
        @State private var attachments: [Attachment] = [
            Attachment(
                name: "CS101_Syllabus.pdf",
                localURL: URL(fileURLWithPath: "/tmp/syllabus.pdf"),
                tag: .syllabus,
                moduleNumber: nil
            ),
            Attachment(
                name: "Assignment_Rubric.pdf",
                localURL: URL(fileURLWithPath: "/tmp/rubric.pdf"),
                tag: .rubric,
                moduleNumber: 3
            )
        ]

        var body: some View {
            AttachmentListView(
                attachments: $attachments,
                allowModuleNumber: true,
                availableTags: AttachmentTag.allCases
            )
            .padding()
            .frame(width: 600)
        }
    }

    return PreviewWrapper()
}
