#if os(macOS)
    import SwiftUI

    /// Detail view for a single course module
    struct ModuleDetailView: View {
        let module: CourseOutlineNode
        let files: [CourseFile]
        let onBack: () -> Void
        let onAddFiles: () -> Void

        private let cardCorner: CGFloat = 24

        var body: some View {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header with back button
                    HStack {
                        Button(action: onBack) {
                            Label(
                                NSLocalizedString("moduledetail.label.back", value: "Back", comment: "Back"),
                                systemImage: "chevron.left"
                            )
                            .font(.body)
                        }
                        .buttonStyle(.plain)

                        Spacer()
                    }

                    // Module info card
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 12) {
                            Image(systemName: moduleIcon)
                                .font(.title)
                                .foregroundStyle(.secondary)
                                .frame(width: 40, height: 40)
                                .background(
                                    Circle()
                                        .fill(.accentQuaternary)
                                )

                            VStack(alignment: .leading, spacing: 4) {
                                Text(module.type.rawValue)
                                    .font(.caption.weight(.medium))
                                    .foregroundStyle(.secondary)
                                    .textCase(.uppercase)

                                Text(module.title)
                                    .font(.title2.weight(.semibold))
                            }

                            Spacer()
                        }

                        Divider()
                            .padding(.vertical, 4)

                        HStack(spacing: 16) {
                            Label(
                                NSLocalizedString("moduledetail.label.created", value: "Created", comment: "Created"),
                                systemImage: "calendar"
                            )
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            Text(module.createdAt, style: .date)
                                .font(.caption)

                            Spacer()

                            Label(
                                NSLocalizedString(
                                    "moduledetail.label.filescount.files",
                                    value: "\(files.count) files",
                                    comment: "\(files.count) files"
                                ),
                                systemImage: "doc"
                            )
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        }
                    }
                    .padding(18)
                    .rootsCardBackground(radius: cardCorner)

                    // Files section
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text(NSLocalizedString(
                                "moduledetail.module.files",
                                value: "Module Files",
                                comment: "Module Files"
                            ))
                            .font(.headline.weight(.semibold))

                            Spacer()

                            Button(action: onAddFiles) {
                                Label(
                                    NSLocalizedString(
                                        "moduledetail.label.add.files",
                                        value: "Add Files",
                                        comment: "Add Files"
                                    ),
                                    systemImage: "plus"
                                )
                                .font(.caption.weight(.medium))
                            }
                            .buttonStyle(.bordered)
                        }
                        .padding(.horizontal, 18)
                        .padding(.top, 18)

                        if files.isEmpty {
                            VStack(spacing: 12) {
                                Image(systemName: "doc.badge.plus")
                                    .font(.system(size: largeIconSize, weight: .bold, design: .rounded))
                                    .foregroundStyle(.tertiary)

                                Text(NSLocalizedString(
                                    "moduledetail.no.files.attached",
                                    value: "No files attached",
                                    comment: "No files attached"
                                ))
                                .font(.subheadline.weight(.medium))

                                Text(NSLocalizedString(
                                    "moduledetail.add.files.to.this.module.to.keep.them.organized",
                                    value: "Add files to this module to keep them organized",
                                    comment: "Add files to this module to keep them organized"
                                ))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 48)
                        } else {
                            VStack(spacing: 8) {
                                ForEach(files) { file in
                                    ModuleFileRow(file: file)
                                }
                            }
                            .padding(.horizontal, 12)
                            .padding(.bottom, 18)
                        }
                    }
                    .rootsCardBackground(radius: cardCorner)
                }
                .padding(.trailing, 6)
                .padding(.vertical, 12)
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

    /// File row in module detail
    private struct ModuleFileRow: View {
        let file: CourseFile
        @ScaledMetric private var largeIconSize: CGFloat = 48

        @State private var isHovered = false

        var body: some View {
            Button(action: openFile) {
                HStack(spacing: 12) {
                    Image(systemName: fileIcon)
                        .font(.title3)
                        .foregroundStyle(isHovered ? Color.accentColor : .secondary)
                        .frame(width: 40, height: 40)
                        .background(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(.secondaryBackground.opacity(0.5))
                        )

                    VStack(alignment: .leading, spacing: 4) {
                        Text(file.filename)
                            .font(.body.weight(.medium))
                            .foregroundStyle(.primary)
                            .lineLimit(1)

                        HStack(spacing: 8) {
                            Text(file.fileType.uppercased())
                                .font(.caption2.weight(.medium))
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(
                                    Capsule()
                                        .fill(.secondaryBackground.opacity(0.5))
                                )

                            Text(file.createdAt, style: .date)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }

                    Spacer()

                    Image(systemName: "arrow.up.right.square")
                        .font(.body)
                        .foregroundStyle(isHovered ? Color.accentColor : .secondary)
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(isHovered ? Color.accentColor.opacity(0.06) : Color.clear)
                )
            }
            .buttonStyle(.plain)
            .onHover { hovering in
                isHovered = hovering
            }
        }

        private func openFile() {
            guard let urlString = file.localURL,
                  let url = URL(string: urlString)
            else {
                DebugLogger.log("⚠️ No valid file URL for: \(file.filename)")
                return
            }

            // Open the file with the system's default application
            NSWorkspace.shared.open(url)
        }

        private var fileIcon: String {
            let ext = file.fileType.lowercased()
            switch ext {
            case "pdf": return "doc.richtext"
            case "doc", "docx": return "doc.text"
            case "xls", "xlsx": return "tablecells"
            case "ppt", "pptx": return "rectangle.3.offgrid"
            case "zip", "rar": return "doc.zipper"
            case "png", "jpg", "jpeg": return "photo"
            default: return "doc"
            }
        }
    }

#endif
