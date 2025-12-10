import SwiftUI
import UniformTypeIdentifiers

struct AttachmentListView: View {
    @Binding var attachments: [Attachment]
    var courseId: UUID?

    @EnvironmentObject private var assignmentsStore: AssignmentsStore
    @State private var showingImporter = false
    @State private var pendingURL: URL?
    @State private var pendingTag: AttachmentTag = .other
    @State private var showTagChooser = false
    @State private var isParsing = false
    @State private var parseMessage: String?
    @State private var editingAttachment: Attachment?
    @State private var showMetadata = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(attachments) { attachment in
                HStack(spacing: 12) {
                    Image(systemName: attachment.tag.icon)
                        .font(.title3)
                        .foregroundStyle(.secondary)
                        .frame(width: 32, height: 32)
                        .background(DesignSystem.Materials.card, in: RoundedRectangle(cornerRadius: 8, style: .continuous))

                    VStack(alignment: .leading, spacing: 2) {
                        Text(attachment.name)
                            .font(DesignSystem.Typography.body)
                        HStack(spacing: 6) {
                            Text(attachment.tag.rawValue)
                            if let size = attachment.formattedFileSize {
                                Text("· \(size)")
                            }
                        }
                        .font(DesignSystem.Typography.caption)
                        .foregroundStyle(.secondary)
                    }

                    Spacer()

                    if attachment.tag == .syllabus {
                        Button {
                            parseSyllabus(attachment)
                        } label: {
                            HStack(spacing: 6) {
                                if isParsing { ProgressView().scaleEffect(0.75) }
                                Text("Parse Dates")
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(isParsing)
                    }
                }
                .padding(12)
                .background(DesignSystem.Materials.hud.opacity(0.4), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            }

            Button {
                pendingTag = .other
                showingImporter = true
            } label: {
                Label("Add File", systemImage: "plus")
                    .font(DesignSystem.Typography.body)
            }
            .buttonStyle(.borderedProminent)
        }
        .fileImporter(
            isPresented: $showingImporter,
            allowedContentTypes: [.pdf, .image, .plainText, .content, .item],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                guard let url = urls.first else { return }
                pendingURL = url
                showTagChooser = true
            case .failure:
                break
            }
        }
        .confirmationDialog("What type of file is this?", isPresented: $showTagChooser, titleVisibility: .visible) {
            ForEach(AttachmentTag.allCases) { tag in
                Button(tag.rawValue) {
                    finalizeImport(tag: tag)
                }
            }
            Button("Cancel", role: .cancel) { pendingURL = nil }
        }
        .alert("Parse Complete", isPresented: Binding(get: { parseMessage != nil }, set: { _ in parseMessage = nil })) {
            Button("OK", role: .cancel) { parseMessage = nil }
        } message: {
            if let message = parseMessage {
                Text(message)
            }
        }
        .sheet(isPresented: $showMetadata, onDismiss: { editingAttachment = nil }) {
            if let binding = bindingForEditingAttachment() {
                FileMetadataSheet(attachment: binding, courses: nil) {
                    showMetadata = false
                }
            } else {
                EmptyView()
            }
        }
    }

    private func finalizeImport(tag: AttachmentTag) {
        guard let sourceURL = pendingURL else { return }
        let fm = FileManager.default
        let docs = fm.urls(for: .documentDirectory, in: .userDomainMask).first!
        let destURL = docs.appendingPathComponent("\(UUID().uuidString)-\(sourceURL.lastPathComponent)")
        do {
            if fm.fileExists(atPath: destURL.path) {
                try fm.removeItem(at: destURL)
            }
            try fm.copyItem(at: sourceURL, to: destURL)
            let newAttachment = Attachment(name: sourceURL.lastPathComponent, localURL: destURL, tag: tag, moduleNumber: 1, taskType: .other, associatedCourseID: courseId)
            attachments.append(newAttachment)
            editingAttachment = newAttachment
            showMetadata = true
        } catch {
            print("Failed to import file: \(error)")
        }
        pendingURL = nil
    }

    private func parseSyllabus(_ attachment: Attachment) {
        guard attachment.tag == .syllabus else { return }
        isParsing = true
        _Concurrency.Task {
            let tasks = await SyllabusParser.parseDates(from: attachment.localURL, courseId: courseId)
            for task in tasks {
                assignmentsStore.addTask(task)
            }
            await MainActor.run {
                isParsing = false
                parseMessage = "Parsed \(tasks.count) items from syllabus."
            }
        }
    }

    private func bindingForEditingAttachment() -> Binding<Attachment>? {
        guard let editingAttachment else { return nil }
        guard let idx = attachments.firstIndex(of: editingAttachment) else { return nil }
        return $attachments[idx]
    }
}
