#if os(macOS)
    import AppKit
    import SwiftUI
    import UniformTypeIdentifiers

    /// Modules & Files section for Course Information panel
    struct CourseModulesFilesSection: View {
        let course: CoursePageCourse
        let modules: [CourseOutlineNode]
        let files: [CourseFile]
        let onCreateModule: () -> Void
        let onAddFiles: () -> Void
        let onSelectModule: (CourseOutlineNode) -> Void

        private let cardCorner: CGFloat = 24

        var body: some View {
            VStack(alignment: .leading, spacing: 16) {
                // Action Buttons
                HStack(spacing: 12) {
                    Button(action: onCreateModule) {
                        Label(
                            NSLocalizedString(
                                "ui.label.create.module",
                                value: "Create Module",
                                comment: "Create Module"
                            ),
                            systemImage: "folder.badge.plus"
                        )
                        .font(.body.weight(.medium))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                    }
                    .buttonStyle(.bordered)

                    Button(action: onAddFiles) {
                        Label(
                            NSLocalizedString("ui.label.add.files", value: "Add Files", comment: "Add Files"),
                            systemImage: "doc.badge.plus"
                        )
                        .font(.body.weight(.medium))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                    }
                    .buttonStyle(.bordered)
                }

                // Modules List
                VStack(alignment: .leading, spacing: 12) {
                    Text(NSLocalizedString("ui.modules", value: "Modules", comment: "Modules"))
                        .font(.headline.weight(.semibold))
                        .padding(.horizontal, 18)
                        .padding(.top, 18)

                    if modules.isEmpty {
                        VStack(spacing: 8) {
                            Image(systemName: "folder.badge.questionmark")
                                .font(.title2)
                                .foregroundStyle(.tertiary)
                            Text(NSLocalizedString(
                                "ui.no.modules.yet",
                                value: "No modules yet",
                                comment: "No modules yet"
                            ))
                            .font(.subheadline.weight(.medium))
                            Text(NSLocalizedString(
                                "ui.create.a.module.to.organize.content",
                                value: "Create a module to organize content",
                                comment: "Create a module to organize content"
                            ))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 32)
                    } else {
                        ScrollView {
                            VStack(spacing: 8) {
                                ForEach(modules.sorted(by: { $0.sortIndex < $1.sortIndex })) { module in
                                    ModuleRow(module: module) {
                                        onSelectModule(module)
                                    }
                                }
                            }
                            .padding(.horizontal, 12)
                            .padding(.bottom, 12)
                        }
                        .frame(maxHeight: 280)
                    }
                }
                .padding(.bottom, 18)
                .rootsCardBackground(radius: cardCorner)

                // Files List (Course-level files)
                if !files.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(NSLocalizedString("ui.course.files", value: "Course Files", comment: "Course Files"))
                            .font(.headline.weight(.semibold))
                            .padding(.horizontal, 18)
                            .padding(.top, 18)

                        ScrollView {
                            VStack(spacing: 8) {
                                ForEach(files) { file in
                                    FileRow(file: file)
                                }
                            }
                            .padding(.horizontal, 12)
                            .padding(.bottom, 12)
                        }
                        .frame(maxHeight: 200)
                    }
                    .padding(.bottom, 18)
                    .rootsCardBackground(radius: cardCorner)
                }
            }
        }
    }

    /// Individual module row
    private struct ModuleRow: View {
        let module: CourseOutlineNode
        let onTap: () -> Void
        @State private var isHovered = false

        var body: some View {
            Button(action: onTap) {
                HStack(spacing: 12) {
                    Image(systemName: moduleIcon)
                        .font(.title3)
                        .foregroundStyle(isHovered ? Color.accentColor : .secondary)
                        .frame(width: 32)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(module.title)
                            .font(.body.weight(.medium))
                            .foregroundStyle(.primary)
                            .lineLimit(2)

                        Text(module.type.rawValue)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(isHovered ? Color.accentColor.opacity(0.08) : .secondaryBackground.opacity(0.5))
                )
            }
            .buttonStyle(.plain)
            .onHover { hovering in
                isHovered = hovering
            }
        }

        private var moduleIcon: String {
            switch module.type {
            case .module: "folder"
            case .unit: "square.stack.3d.up"
            case .section: "doc.text"
            case .chapter: "book"
            case .part: "square.split.2x1"
            case .lesson: "lightbulb"
            }
        }
    }

    /// Individual file row
    private struct FileRow: View {
        @State var file: CourseFile
        @State private var isHovered = false
        @State private var showErrorAlert = false
        @StateObject private var parsingService = FileParsingService.shared

        var body: some View {
            HStack(spacing: 12) {
                // File icon
                Image(systemName: fileIcon)
                    .font(.title3)
                    .foregroundStyle(isHovered ? Color.accentColor : .secondary)
                    .frame(width: 32)

                // File info
                VStack(alignment: .leading, spacing: 2) {
                    Text(file.filename)
                        .font(.body)
                        .foregroundStyle(.primary)
                        .lineLimit(1)

                    HStack(spacing: 6) {
                        Text(file.fileType.uppercased())
                            .font(.caption2.weight(.medium))
                            .foregroundStyle(.secondary)

                        // Parse status indicator
                        if file.parseStatus != .notParsed {
                            Text(NSLocalizedString("ui.", value: "•", comment: "•"))
                                .font(.caption2)
                                .foregroundStyle(.secondary)

                            HStack(spacing: 4) {
                                // Show progress bar if parsing
                                if file.parseStatus == .parsing,
                                   let progress = parsingService.parsingProgress[file.id]
                                {
                                    ProgressView(value: progress)
                                        .controlSize(.mini)
                                        .frame(width: 40)
                                } else {
                                    Image(systemName: file.parseStatus.icon)
                                        .font(.caption2)
                                }
                                Text(file.parseStatus.displayName)
                                    .font(.caption2.weight(.medium))
                            }
                            .foregroundStyle(parseStatusColor)
                        }

                        // Legacy indicators (if set)
                        if file.isSyllabus && file.category != .syllabus {
                            Text(NSLocalizedString("ui.", value: "•", comment: "•"))
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                            Text(NSLocalizedString("ui.syllabus", value: "Syllabus", comment: "Syllabus"))
                                .font(.caption2.weight(.medium))
                                .foregroundStyle(.blue)
                        }

                        if file.isPracticeExam && file.category != .practiceTest {
                            Text(NSLocalizedString("ui.", value: "•", comment: "•"))
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                            Text(NSLocalizedString(
                                "ui.practice.exam",
                                value: "Practice Exam",
                                comment: "Practice Exam"
                            ))
                            .font(.caption2.weight(.medium))
                            .foregroundStyle(.purple)
                        }
                    }
                }

                Spacer()

                // Category dropdown (replaces button)
                Menu {
                    ForEach(FileCategory.allCases) { category in
                        Button(action: {
                            Task {
                                await updateCategory(category)
                            }
                        }) {
                            HStack {
                                Image(systemName: category.icon)
                                Text(category.displayName)
                                if file.category == category {
                                    Spacer()
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }

                    Divider()

                    if file.parseStatus == .failed, let _ = file.parseError {
                        Button(action: {
                            showErrorAlert = true
                        }) {
                            Label(
                                NSLocalizedString("ui.label.view.error", value: "View Error", comment: "View Error"),
                                systemImage: "exclamationmark.triangle"
                            )
                        }
                    }

                    Button(action: openFile) {
                        Label(
                            NSLocalizedString("ui.label.open.file", value: "Open File", comment: "Open File"),
                            systemImage: "arrow.up.right.square"
                        )
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: file.category.icon)
                            .font(.caption)
                        Text(file.category.displayName)
                            .font(.caption.weight(.medium))
                        Image(systemName: "chevron.down")
                            .font(.caption2)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(.secondaryBackground)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .strokeBorder(.quaternary, lineWidth: 0.5)
                    )
                }
                .menuStyle(.borderlessButton)
                .fixedSize()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(isHovered ? Color.accentColor.opacity(0.08) : .secondaryBackground.opacity(0.3))
            )
            .onHover { hovering in
                isHovered = hovering
            }
            .alert("Parse Error", isPresented: $showErrorAlert) {
                Button(NSLocalizedString("OK", value: "OK", comment: ""), role: .cancel) {}
            } message: {
                Text(file.parseError ?? "Unknown error")
            }
        }

        private var parseStatusColor: Color {
            switch file.parseStatus {
            case .notParsed: .gray
            case .queued: .orange
            case .parsing: .blue
            case .parsed: .green
            case .failed: .red
            }
        }

        private func updateCategory(_ newCategory: FileCategory) async {
            var updatedFile = file
            updatedFile.category = newCategory
            updatedFile.updatedAt = Date()
            file = updatedFile

            await parsingService.updateFileCategory(file, newCategory: newCategory)
        }

        private func openFile() {
            guard let urlString = file.localURL,
                  let url = URL(string: urlString)
            else {
                DebugLogger.log("⚠️ No valid file URL for: \(file.filename)")
                return
            }

            NSWorkspace.shared.open(url)
        }

        private var fileIcon: String {
            let ext = file.fileType.lowercased()
            switch ext {
            case "pdf": return "doc.richtext"
            case "doc", "docx": return "doc.text"
            case "xls", "xlsx", "csv": return "tablecells"
            case "ppt", "pptx": return "rectangle.3.offgrid"
            case "zip", "rar": return "doc.zipper"
            case "png", "jpg", "jpeg": return "photo"
            default: return "doc"
            }
        }
    }

#endif
