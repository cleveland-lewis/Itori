#if os(macOS)
    import SwiftUI

    struct CourseOutlineEditorView: View {
        let course: Course
        @EnvironmentObject var coursesStore: CoursesStore
        @State private var showingAddNode = false
        @State private var showingRenameNode: CourseOutlineNode?
        @State private var newNodeTitle = ""
        @State private var newNodeType: CourseOutlineNodeType = .lesson
        @State private var newNodeParent: UUID?

        private var outlineNodes: [CourseOutlineNode] {
            coursesStore.outlineNodes(for: course.id)
        }

        private var rootNodes: [CourseOutlineNode] {
            coursesStore.rootOutlineNodes(for: course.id)
        }

        var body: some View {
            VStack {
                if outlineNodes.isEmpty {
                    emptyState
                } else {
                    outlineList
                }
            }
            .navigationTitle("Course Outline")
            .navigationSubtitle(course.title)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        newNodeTitle = ""
                        newNodeType = .lesson
                        newNodeParent = nil
                        showingAddNode = true
                    } label: {
                        Label(
                            NSLocalizedString("courseoutlineeditor.label.add", value: "Add", comment: "Add"),
                            systemImage: "plus"
                        )
                    }
                }
            }
            .sheet(isPresented: $showingAddNode) {
                AddNodeSheet(
                    title: $newNodeTitle,
                    type: $newNodeType,
                    courseId: course.id,
                    parentId: newNodeParent,
                    coursesStore: coursesStore
                )
            }
            .sheet(item: $showingRenameNode) { node in
                RenameNodeSheet(node: node, coursesStore: coursesStore)
            }
        }

        private var emptyState: some View {
            VStack(spacing: 16) {
                Image(systemName: "list.bullet.indent")
                    .font(.largeTitle)
                    .foregroundStyle(.tertiary)

                Text(NSLocalizedString(
                    "courseoutlineeditor.no.outline.yet",
                    value: "No Outline Yet",
                    comment: "No Outline Yet"
                ))
                .font(DesignSystem.Typography.subHeader)
                .foregroundStyle(.secondary)

                Text(NSLocalizedString(
                    "courseoutlineeditor.create.modules.units.sections.chapters",
                    value: "Create modules, units, sections, chapters, and lessons to organize your course content.",
                    comment: "Create modules, units, sections, chapters, and les..."
                ))
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 300)

                Button {
                    showingAddNode = true
                } label: {
                    Label(
                        NSLocalizedString(
                            "courseoutlineeditor.label.create.first.node",
                            value: "Create First Node",
                            comment: "Create First Node"
                        ),
                        systemImage: "plus.circle.fill"
                    )
                }
                .buttonStyle(.itoriLiquidProminent)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding()
        }

        private var outlineList: some View {
            List {
                ForEach(rootNodes) { node in
                    OutlineNodeRow(node: node, level: 0, coursesStore: coursesStore)
                }
            }
        }
    }

    // MARK: - Outline Node Row

    private struct OutlineNodeRow: View {
        let node: CourseOutlineNode
        let level: Int
        let coursesStore: CoursesStore

        @State private var isExpanded = true

        private var children: [CourseOutlineNode] {
            coursesStore.childOutlineNodes(for: node.id)
        }

        private var hasChildren: Bool {
            !children.isEmpty
        }

        var body: some View {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    // Indentation
                    ForEach(0 ..< level, id: \.self) { _ in
                        Rectangle()
                            .fill(Color.clear)
                            .frame(width: 20)
                    }

                    // Disclosure triangle
                    if hasChildren {
                        Button {
                            withAnimation(DesignSystem.Motion.snappyEase) {
                                isExpanded.toggle()
                            }
                        } label: {
                            Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(.secondary)
                                .frame(width: 16, height: 16)
                        }
                        .buttonStyle(.plain)
                    } else {
                        Rectangle()
                            .fill(Color.clear)
                            .frame(width: 16, height: 16)
                    }

                    // Type icon
                    Image(systemName: iconForType(node.type))
                        .font(.caption2)
                        .foregroundStyle(.secondary)

                    // Title
                    Text(node.title)
                        .font(.caption)

                    Spacer()

                    // Type label
                    Text(node.type.rawValue)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
                .padding(.vertical, 4)
                .contextMenu {
                    Button {
                        // Trigger rename
                    } label: {
                        Label(
                            NSLocalizedString("courseoutlineeditor.label.rename", value: "Rename", comment: "Rename"),
                            systemImage: "pencil"
                        )
                    }

                    Button(role: .destructive) {
                        coursesStore.deleteSubtree(node.id)
                    } label: {
                        Label(
                            NSLocalizedString("courseoutlineeditor.label.delete", value: "Delete", comment: "Delete"),
                            systemImage: "trash"
                        )
                    }
                }

                // Render children if expanded
                if isExpanded && hasChildren {
                    ForEach(children) { child in
                        OutlineNodeRow(node: child, level: level + 1, coursesStore: coursesStore)
                    }
                }
            }
        }

        private func iconForType(_ type: CourseOutlineNodeType) -> String {
            switch type {
            case .module: "square.stack.3d.up"
            case .unit: "square.stack"
            case .section: "square.split.2x1"
            case .chapter: "book"
            case .part: "rectangle.split.3x1"
            case .lesson: "doc.text"
            }
        }
    }

    // MARK: - Add Node Sheet

    private struct AddNodeSheet: View {
        @Binding var title: String
        @Binding var type: CourseOutlineNodeType
        let courseId: UUID
        let parentId: UUID?
        let coursesStore: CoursesStore
        @Environment(\.dismiss) var dismiss

        var body: some View {
            Form {
                TextField("Title", text: $title)
                Picker("Type", selection: $type) {
                    ForEach(CourseOutlineNodeType.allCases) { nodeType in
                        Text(nodeType.rawValue).tag(nodeType)
                    }
                }
            }
            .padding()
            .frame(width: 400, height: 150)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(NSLocalizedString("courseoutlineeditor.button.cancel", value: "Cancel", comment: "Cancel")) {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(NSLocalizedString("courseoutlineeditor.button.add", value: "Add", comment: "Add")) {
                        let sortIndex = coursesStore.nextSortIndex(for: parentId)
                        let node = CourseOutlineNode(
                            courseId: courseId,
                            parentId: parentId,
                            type: type,
                            title: title,
                            sortIndex: sortIndex
                        )
                        coursesStore.addOutlineNode(node)
                        dismiss()
                    }
                    .disabled(title.isEmpty)
                }
            }
        }
    }

    // MARK: - Rename Node Sheet

    private struct RenameNodeSheet: View {
        let node: CourseOutlineNode
        let coursesStore: CoursesStore
        @Environment(\.dismiss) var dismiss
        @State private var newTitle: String

        init(node: CourseOutlineNode, coursesStore: CoursesStore) {
            self.node = node
            self.coursesStore = coursesStore
            _newTitle = State(initialValue: node.title)
        }

        var body: some View {
            Form {
                TextField("Title", text: $newTitle)
            }
            .padding()
            .frame(width: 400, height: 100)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(NSLocalizedString("courseoutlineeditor.button.cancel", value: "Cancel", comment: "Cancel")) {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(NSLocalizedString("courseoutlineeditor.button.save", value: "Save", comment: "Save")) {
                        var updated = node
                        updated.title = newTitle
                        coursesStore.updateOutlineNode(updated)
                        dismiss()
                    }
                    .disabled(newTitle.isEmpty)
                }
            }
        }
    }
#endif
