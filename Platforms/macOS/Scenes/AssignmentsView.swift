#if os(macOS)
import SwiftUI

struct AssignmentsView: View {
    enum Filter: String, CaseIterable, Identifiable {
        case all
        case dueSoon
        case overdue
        case personal  // NEW: Personal tasks filter
        
        var id: String { rawValue }
        
        var displayName: String {
            switch self {
            case .all: return NSLocalizedString("assignments.filter.all", comment: "")
            case .dueSoon: return NSLocalizedString("assignments.filter.due_soon", comment: "")
            case .overdue: return NSLocalizedString("assignments.filter.overdue", comment: "")
            case .personal: return "Personal"  // NEW
            }
        }
    }

    @State private var filter: Filter = .all

    @EnvironmentObject var assignmentsStore: AssignmentsStore
    @EnvironmentObject var coursesStore: CoursesStore  // NEW: For course lookups

    @State private var showingAddSheet: Bool = false
    @State private var editingTask: AppTask? = nil
    
    // NEW: Computed property for filtered tasks
    private var filteredTasks: [AppTask] {
        let tasks = assignmentsStore.tasks
        switch filter {
        case .all:
            return tasks
        case .dueSoon:
            let soon = Calendar.current.date(byAdding: .day, value: 3, to: Date()) ?? Date()
            return tasks.filter { task in
                guard let due = task.due else { return false }
                return due <= soon && due >= Date()
            }
        case .overdue:
            return tasks.filter { task in
                guard let due = task.due else { return false }
                return due < Date() && !task.isCompleted
            }
        case .personal:
            return tasks.filter { $0.isPersonal }  // NEW: Filter personal tasks
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.large) {
                // Toolbar (title removed)
                HStack(spacing: DesignSystem.Spacing.medium) {
                    Spacer()

                    HStack(spacing: DesignSystem.Spacing.small) {
                        Button(action: { showingAddSheet = true }) {
                            Label(NSLocalizedString("assignments.action.add", comment: ""), systemImage: "plus")
                        }
                        .buttonStyle(.glassBlueProminent)

                        Picker(NSLocalizedString("assignments.action.filter", comment: ""), selection: $filter) {
                            ForEach(Filter.allCases) { f in
                                Text(f.displayName).tag(f)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                }

                LazyVStack(alignment: .leading, spacing: DesignSystem.Spacing.large) {
                    // Due Today
                    Section(header: Text(NSLocalizedString("assignments.section.due_today", comment: "")).font(DesignSystem.Typography.body)) {
                        let tasks = assignmentsStore.tasks.filter { $0.due != nil && Calendar.current.isDateInToday($0.due!) }
                        if tasks.isEmpty {
                            AppCard {
                                VStack(spacing: DesignSystem.Spacing.small) {
                                    Image(systemName: "doc.text")
                                        .imageScale(.large)
                                    Text(NSLocalizedString("assignments.section.due_today", comment: ""))
                                        .font(DesignSystem.Typography.title)
                                    Text(DesignSystem.emptyStateMessage)
                                        .font(DesignSystem.Typography.body)
                                }
                            }
                            .frame(minHeight: DesignSystem.Cards.defaultHeight)
                        } else {
                            ForEach(tasks, id: \.id) { t in
                                AssignmentRow(task: t)
                            }
                        }
                    }

                    // Due This Week
                    Section(header: Text(NSLocalizedString("assignments.section.due_this_week", comment: "")).font(DesignSystem.Typography.body)) {
                        let tasks = assignmentsStore.tasks.filter { t in
                            if let d = t.due { return Calendar.current.isDate(d, equalTo: Date(), toGranularity: .weekOfYear) }
                            return false
                        }
                        if tasks.isEmpty {
                            AppCard {
                                VStack(spacing: DesignSystem.Spacing.small) {
                                    Image(systemName: "calendar")
                                        .imageScale(.large)
                                    Text(NSLocalizedString("assignments.section.due_this_week", comment: ""))
                                        .font(DesignSystem.Typography.title)
                                    Text(DesignSystem.emptyStateMessage)
                                        .font(DesignSystem.Typography.body)
                                }
                            }
                            .frame(minHeight: DesignSystem.Cards.defaultHeight)
                        } else {
                            ForEach(tasks, id: \.id) { t in
                                AssignmentRow(task: t)
                            }
                        }
                    }

                    // NEW: Personal Tasks Section
                    if filter == .all || filter == .personal {
                        Section(header: HStack {
                            Text(NSLocalizedString("assignments.personal.tasks", value: "Personal Tasks", comment: "Personal Tasks"))
                                .font(DesignSystem.Typography.body)
                            Image(systemName: "person.fill")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }) {
                            let personalTasks = assignmentsStore.tasks.filter { $0.isPersonal && !$0.isCompleted }
                            if personalTasks.isEmpty {
                                AppCard {
                                    VStack(spacing: DesignSystem.Spacing.small) {
                                        Image(systemName: "person.crop.circle")
                                            .imageScale(.large)
                                        Text(NSLocalizedString("assignments.personal.tasks", value: "Personal Tasks", comment: "Personal Tasks"))
                                            .font(DesignSystem.Typography.title)
                                        Text(NSLocalizedString("assignments.create.personal.tasks.not.tied.to.any.course", value: "Create personal tasks not tied to any course", comment: "Create personal tasks not tied to any course"))
                                            .font(DesignSystem.Typography.body)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                .frame(minHeight: DesignSystem.Cards.defaultHeight)
                            } else {
                                ForEach(personalTasks, id: \.id) { t in
                                    AssignmentRow(task: t)
                                }
                            }
                        }
                    }

                    // Upcoming
                    Section(header: Text(NSLocalizedString("assignments.section.upcoming", comment: "")).font(DesignSystem.Typography.body)) {
                        let tasks = assignmentsStore.tasks.filter { $0.due == nil }
                        if tasks.isEmpty {
                            AppCard {
                                VStack(spacing: DesignSystem.Spacing.small) {
                                    Image(systemName: "clock")
                                        .imageScale(.large)
                                    Text(NSLocalizedString("assignments.section.upcoming", comment: ""))
                                        .font(DesignSystem.Typography.title)
                                    Text(DesignSystem.emptyStateMessage)
                                        .font(DesignSystem.Typography.body)
                                }
                            }
                            .frame(minHeight: DesignSystem.Cards.defaultHeight)
                        } else {
                            ForEach(tasks, id: \.id) { t in
                                AssignmentRow(task: t)
                            }
                        }
                    }

                    // Overdue
                    Section(header: Text(NSLocalizedString("assignments.filter.overdue", comment: "")).font(DesignSystem.Typography.body)) {
                        let tasks = assignmentsStore.tasks.filter { t in
                            if let d = t.due { return d < Date() }
                            return false
                        }
                        if tasks.isEmpty {
                            AppCard {
                                VStack(spacing: DesignSystem.Spacing.small) {
                                    Image(systemName: "clock.badge.exclamationmark")
                                        .imageScale(.large)
                                    Text(NSLocalizedString("assignments.filter.overdue", comment: ""))
                                        .font(DesignSystem.Typography.title)
                                    Text(DesignSystem.emptyStateMessage)
                                        .font(DesignSystem.Typography.body)
                                }
                            }
                            .frame(minHeight: DesignSystem.Cards.defaultHeight)
                        } else {
                            ForEach(tasks, id: \.id) { t in
                                AssignmentRow(task: t)
                            }
                        }
                    }
                }
            }
            .padding(DesignSystem.Spacing.large)
        }
        .rootsSystemBackground()
        .sheet(isPresented: $showingAddSheet) {
            // wrap to avoid ambiguity with trailing closure initializers
            AddAssignmentView(initialType: .reading, onSave: { task in
                AssignmentsStore.shared.addTask(task)
            })
        }
    }
}

struct AssignmentsView_Previews: PreviewProvider {
    static var previews: some View {
        AssignmentsView().environmentObject(AssignmentsStore.shared)
    }
}
#endif
