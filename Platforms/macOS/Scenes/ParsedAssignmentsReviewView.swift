#if os(macOS)
    import SwiftUI

    // MARK: - Parsed Assignment Review View

    struct ParsedAssignmentsReviewView: View {
        @EnvironmentObject private var parsingStore: SyllabusParsingStore
        @EnvironmentObject private var assignmentsStore: AssignmentsStore
        @EnvironmentObject private var coursesStore: CoursesStore

        let courseId: UUID
        @Environment(\.dismiss) private var dismiss

        @State private var parsedItems: [ParsedAssignment] = []
        @State private var approvedIds: Set<UUID> = []
        @State private var editingItem: ParsedAssignment? = nil
        @State private var showingImportConfirmation = false
        @State private var importSuccessCount = 0

        var body: some View {
            VStack(spacing: 0) {
                headerView

                if parsedItems.isEmpty {
                    emptyStateView
                } else {
                    listView
                }

                footerView
            }
            .frame(width: 800, height: 600)
            .onAppear {
                loadParsedAssignments()
            }
            .sheet(item: $editingItem) { item in
                ParsedAssignmentEditSheet(
                    assignment: item,
                    onSave: { updated in
                        updateParsedAssignment(updated)
                    },
                    onCancel: {
                        editingItem = nil
                    }
                )
            }
            .alert(
                NSLocalizedString("assignments.parse.import_success", comment: ""),
                isPresented: $showingImportConfirmation
            ) {
                Button(NSLocalizedString("assignments.action.ok", comment: "")) {
                    showingImportConfirmation = false
                    dismiss()
                }
            } message: {
                Text(String(
                    format: NSLocalizedString("assignments.parse.import_count", comment: ""),
                    importSuccessCount
                ))
            }
        }

        private var headerView: some View {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(NSLocalizedString("assignments.parse.review_title", comment: ""))
                            .font(.title2.weight(.semibold))
                        Text(NSLocalizedString("assignments.parse.review_subtitle", comment: ""))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Button(NSLocalizedString("assignments.action.cancel", comment: "")) {
                        dismiss()
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.secondary)
                }

                Divider()
            }
            .padding()
        }

        private var emptyStateView: some View {
            VStack(spacing: 12) {
                Image(systemName: "doc.text.magnifyingglass")
                    .font(.largeTitle)
                    .imageScale(.large)
                    .foregroundStyle(.secondary)
                Text(NSLocalizedString("assignments.empty.no_parsed", comment: ""))
                    .font(.title3.weight(.semibold))
                Text(NSLocalizedString("assignments.empty.parse_syllabus", comment: ""))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }

        private var listView: some View {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(parsedItems) { item in
                        ParsedAssignmentRow(
                            assignment: item,
                            isApproved: approvedIds.contains(item.id),
                            onToggleApproval: {
                                toggleApproval(item.id)
                            },
                            onEdit: {
                                editingItem = item
                            },
                            provenance: provenanceForItem(item)
                        )
                    }
                }
                .padding()
            }
        }

        private var footerView: some View {
            VStack(spacing: 0) {
                Divider()

                HStack {
                    Text(verbatim: "\(approvedIds.count) of \(parsedItems.count) approved")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Spacer()

                    Button(NSLocalizedString("assignments.parse.select_all", comment: "")) {
                        approvedIds = Set(parsedItems.map(\.id))
                    }
                    .buttonStyle(.plain)

                    Button(NSLocalizedString("assignments.parse.deselect_all", comment: "")) {
                        approvedIds.removeAll()
                    }
                    .buttonStyle(.plain)
                    .padding(.leading, 8)

                    Button(NSLocalizedString("assignments.parse.add_parsed", comment: "")) {
                        importApprovedAssignments()
                    }
                    .buttonStyle(.itoriLiquidProminent)
                    .disabled(approvedIds.isEmpty)
                    .padding(.leading, 16)
                }
                .padding()
            }
        }

        private func loadParsedAssignments() {
            parsedItems = parsingStore.parsedAssignmentsByCourse(courseId)
        }

        private func toggleApproval(_ id: UUID) {
            if approvedIds.contains(id) {
                approvedIds.remove(id)
            } else {
                approvedIds.insert(id)
            }
        }

        private func updateParsedAssignment(_ updated: ParsedAssignment) {
            parsingStore.updateParsedAssignment(updated)
            if let index = parsedItems.firstIndex(where: { $0.id == updated.id }) {
                parsedItems[index] = updated
            }
            editingItem = nil
        }

        private func provenanceForItem(_ item: ParsedAssignment) -> String {
            guard let job = parsingStore.parsingJobs.first(where: { $0.id == item.jobId }),
                  let file = coursesStore.courseFiles.first(where: { $0.id == job.fileId })
            else {
                return NSLocalizedString("assignments.parse.unknown_source", comment: "")
            }
            return file.filename
        }

        private func importApprovedAssignments() {
            let approved = parsedItems.filter { approvedIds.contains($0.id) }
            var importedCount = 0

            for item in approved {
                // Check for duplicates by comparing title and date
                let isDuplicate = assignmentsStore.tasks.contains { task in
                    task.courseId == item.courseId &&
                        task.title == item.title &&
                        task.due == item.dueDate
                }

                if !isDuplicate {
                    let task = AppTask(
                        id: UUID(),
                        title: item.title,
                        courseId: item.courseId,
                        due: item.dueDate,
                        estimatedMinutes: 120,
                        minBlockMinutes: 30,
                        maxBlockMinutes: 90,
                        difficulty: 0.5,
                        importance: 0.7,
                        type: taskTypeFromInferred(item.inferredType),
                        locked: false,
                        attachments: [],
                        isCompleted: false,
                        category: taskTypeFromInferred(item.inferredType)
                    )

                    assignmentsStore.addTask(task)
                    parsingStore.markAsImported(item.id, taskId: task.id)
                    importedCount += 1
                }
            }

            importSuccessCount = importedCount
            showingImportConfirmation = true
            loadParsedAssignments()
        }

        private func taskTypeFromInferred(_ inferredType: String?) -> TaskType {
            guard let type = inferredType?.lowercased() else { return .homework }

            if type.contains("exam") || type.contains("test") {
                return .exam
            } else if type.contains("quiz") {
                return .quiz
            } else if type.contains("project") {
                return .project
            } else if type.contains("reading") {
                return .reading
            } else if type.contains("review") {
                return .review
            }

            return .homework
        }
    }

    // MARK: - Parsed Assignment Row

    struct ParsedAssignmentRow: View {
        let assignment: ParsedAssignment
        let isApproved: Bool
        let onToggleApproval: () -> Void
        let onEdit: () -> Void
        let provenance: String

        var body: some View {
            HStack(alignment: .top, spacing: 12) {
                Toggle(NSLocalizedString("parsedassignmentsreview.toggle.", value: "", comment: ""), isOn: .init(
                    get: { isApproved },
                    set: { _ in onToggleApproval() }
                ))
                .toggleStyle(.checkbox)
                .labelsHidden()

                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(assignment.title)
                            .font(.body.weight(.semibold))

                        if let type = assignment.inferredType {
                            Text(type)
                                .font(.caption)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(.accentTertiary)
                                .clipShape(RoundedRectangle(cornerRadius: 4))
                        }

                        Spacer()
                    }

                    HStack(spacing: 16) {
                        if let dueDate = assignment.dueDate {
                            Label(formatDate(dueDate), systemImage: "calendar")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        if let time = assignment.dueTime {
                            Label(time, systemImage: "clock")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    if let anchor = assignment.provenanceAnchor {
                        Text(verbatim: "Source: \(anchor)")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                            .lineLimit(1)
                    }

                    Text(verbatim: "From: \(provenance)")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }

                Spacer()

                Button(NSLocalizedString("assignments.action.edit", comment: "")) {
                    onEdit()
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(isApproved ? .accentQuaternary : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .strokeBorder(.quaternary, lineWidth: 1)
            )
        }

        private func formatDate(_ date: Date) -> String {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .none
            return formatter.string(from: date)
        }
    }

    // MARK: - Edit Sheet

    struct ParsedAssignmentEditSheet: View {
        let assignment: ParsedAssignment
        let onSave: (ParsedAssignment) -> Void
        let onCancel: () -> Void

        @State private var title: String
        @State private var dueDate: Date
        @State private var dueTime: String
        @State private var inferredType: String

        init(
            assignment: ParsedAssignment,
            onSave: @escaping (ParsedAssignment) -> Void,
            onCancel: @escaping () -> Void
        ) {
            self.assignment = assignment
            self.onSave = onSave
            self.onCancel = onCancel

            _title = State(initialValue: assignment.title)
            _dueDate = State(initialValue: assignment.dueDate ?? Date())
            _dueTime = State(initialValue: assignment.dueTime ?? "")
            _inferredType = State(initialValue: assignment.inferredType ?? "")
        }

        var body: some View {
            VStack(alignment: .leading, spacing: 16) {
                Text(NSLocalizedString("assignments.parse.edit_title", comment: ""))
                    .font(.title2.weight(.semibold))

                Form {
                    TextField(NSLocalizedString("assignments.form.title", comment: ""), text: $title)

                    DatePicker(
                        NSLocalizedString("assignments.form.due_date", comment: ""),
                        selection: $dueDate,
                        displayedComponents: .date
                    )

                    TextField("Due Time (optional)", text: $dueTime)

                    TextField(NSLocalizedString("assignments.form.type", comment: ""), text: $inferredType)
                }
                .formStyle(.grouped)
                .listSectionSpacing(10)
                .scrollContentBackground(.hidden)
                .background(Color(nsColor: .controlBackgroundColor))

                HStack {
                    Button(NSLocalizedString("assignments.action.cancel", comment: "")) {
                        onCancel()
                    }
                    .buttonStyle(.plain)

                    Spacer()

                    Button(NSLocalizedString("assignments.action.save", comment: "")) {
                        var updated = assignment
                        updated.title = title
                        updated.dueDate = dueDate
                        updated.dueTime = dueTime.isEmpty ? nil : dueTime
                        updated.inferredType = inferredType.isEmpty ? nil : inferredType
                        onSave(updated)
                    }
                    .buttonStyle(.itoriLiquidProminent)
                }
            }
            .padding()
            .frame(width: 400)
        }
    }

#endif
