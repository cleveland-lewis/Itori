#if os(macOS)
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
                    Label("Create Module", systemImage: "folder.badge.plus")
                        .font(.body.weight(.medium))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                }
                .buttonStyle(.borderedProminent)
                .tint(.accentColor)
                
                Button(action: onAddFiles) {
                    Label("Add Files", systemImage: "doc.badge.plus")
                        .font(.body.weight(.medium))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                }
                .buttonStyle(.bordered)
            }
            
            // Modules List
            VStack(alignment: .leading, spacing: 12) {
                Text("Modules")
                    .font(.headline.weight(.semibold))
                    .padding(.horizontal, 18)
                    .padding(.top, 18)
                
                if modules.isEmpty {
                    VStack(spacing: 8) {
                        Image(systemName: "folder.badge.questionmark")
                            .font(.title2)
                            .foregroundStyle(.tertiary)
                        Text("No modules yet")
                            .font(.subheadline.weight(.medium))
                        Text("Create a module to organize content")
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
                    Text("Course Files")
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
                    .fill(isHovered ? Color.accentColor.opacity(0.08) : Color(nsColor: .controlBackgroundColor).opacity(0.5))
            )
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovered = hovering
        }
    }
    
    private var moduleIcon: String {
        switch module.type {
        case .module: return "folder"
        case .unit: return "square.stack.3d.up"
        case .section: return "doc.text"
        case .chapter: return "book"
        case .part: return "square.split.2x1"
        case .lesson: return "lightbulb"
        }
    }
}

/// Individual file row
private struct FileRow: View {
    let file: CourseFile
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: fileIcon)
                .font(.title3)
                .foregroundStyle(.secondary)
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(file.filename)
                    .font(.body)
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                
                HStack(spacing: 6) {
                    Text(file.fileType.uppercased())
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(.secondary)
                    
                    if file.isSyllabus {
                        Text("•")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Text("Syllabus")
                            .font(.caption2.weight(.medium))
                            .foregroundStyle(.blue)
                    }
                    
                    if file.isPracticeExam {
                        Text("•")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Text("Practice Exam")
                            .font(.caption2.weight(.medium))
                            .foregroundStyle(.purple)
                    }
                }
            }
            
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color(nsColor: .controlBackgroundColor).opacity(0.3))
        )
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
