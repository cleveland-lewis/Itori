import SwiftUI

struct TaskDashboardCard: View {
    @Binding var tasks: [Task]
    @State private var expandedCompleted: Bool = false
    
    // Computed Groups
    var overdueTasks: [Task] {
        tasks.filter { $0.isOverdue }.sorted(by: sortTasks)
    }
    
    var todayTasks: [Task] {
        tasks.filter { $0.isDueToday }.sorted(by: sortTasks)
    }
    
    var tomorrowTasks: [Task] {
        tasks.filter { $0.isDueTomorrow }.sorted(by: sortTasks)
    }
    
    var upcomingTasks: [Task] {
        let startOfDayAfterTomorrow = Calendar.current.date(byAdding: .day, value: 2, to: Calendar.current.startOfDay(for: Date()))!
        return tasks
            .filter { !$0.isCompleted && $0.dueDate >= startOfDayAfterTomorrow }
            .sorted(by: sortTasks)
    }
    
    var completedTasks: [Task] {
        tasks.filter { $0.isCompleted }
            .sorted { $0.completedDate ?? Date() > $1.completedDate ?? Date() }
    }
    
    func sortTasks(_ t1: Task, _ t2: Task) -> Bool {
        if t1.priority != t2.priority {
            return t1.priority > t2.priority
        }
        return t1.dueDate < t2.dueDate
    }

    var body: some View {
        RootsCard {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.medium) {
                
                // Header
                HStack {
                    Text("Tasks")
                        .font(DesignSystem.Typography.subHeader)
                    Spacer()
                    Text("View All")
                        .font(DesignSystem.Typography.caption)
                        .foregroundStyle(.secondary)
                }
                
                // Content
                if tasks.filter({ !$0.isCompleted }).isEmpty {
                    VStack(spacing: DesignSystem.Layout.spacing.small) {
                        Image(systemName: "checkmark.circle")
                            .font(DesignSystem.Typography.display)
                            .foregroundStyle(.secondary)
                        Text("All caught up!")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, minHeight: 100)
                } else {
                    VStack(alignment: .leading, spacing: 12) {
                        if !overdueTasks.isEmpty {
                            DashboardTaskGroup(tasks: $tasks, title: "Overdue", filteredTasks: overdueTasks, isUrgent: true)
                        }
                        
                        if !todayTasks.isEmpty {
                            DashboardTaskGroup(tasks: $tasks, title: "Today", filteredTasks: todayTasks)
                        }
                        
                        if !tomorrowTasks.isEmpty {
                            DashboardTaskGroup(tasks: $tasks, title: "Tomorrow", filteredTasks: tomorrowTasks)
                        }
                        
                        if !upcomingTasks.isEmpty {
                            DashboardTaskGroup(tasks: $tasks, title: "Upcoming", filteredTasks: upcomingTasks)
                        }
                    }
                }
                
                Divider()
                
                // Completed Section
                DisclosureGroup(
                    isExpanded: $expandedCompleted,
                    content: {
                        VStack(spacing: 0) {
                            ForEach(completedTasks.prefix(5)) { task in
                                DashboardCompletedTaskRow(task: task)
                            }
                        }
                        .padding(.top, 8)
                    },
                    label: {
                        Text("Completed (\(completedTasks.count))")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                )
                .tint(.secondary)
            }
            .padding(DesignSystem.Spacing.medium)
            .animation(DesignSystem.Motion.layoutSpring, value: tasks)
        }
    }
}

// MARK: - Renamed Subviews (To avoid collisions)

struct DashboardTaskGroup: View {
    @Binding var tasks: [Task]
    let title: String
    let filteredTasks: [Task]
    var isUrgent: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Layout.spacing.small) {
            Text(title.uppercased())
                .font(.caption.weight(.bold))
                .foregroundStyle(isUrgent ? .red : .secondary)
            
            ForEach(filteredTasks) { task in
                DashboardTaskRow(tasks: $tasks, task: task)
            }
        }
    }
}

struct DashboardTaskRow: View {
    @Binding var tasks: [Task]
    let task: Task
    
    var priorityColor: Color {
        switch task.priority {
        case .high: return .red
        case .medium: return .orange
        case .low: return .blue
        }
    }
    
    var body: some View {
        HStack(spacing: 12) {
            Button(action: {
                withAnimation(DesignSystem.Motion.interactiveSpring) {
                    if let index = tasks.firstIndex(where: { $0.id == task.id }) {
                        tasks[index].isCompleted = true
                        tasks[index].completedDate = Date()
                    }
                }
            }) {
                Circle()
                    .strokeBorder(Color.secondary.opacity(0.3), lineWidth: 1.5)
                    .frame(width: 20, height: 20)
            }
            .accessibilityIdentifier("TaskCheckbox")
            .buttonStyle(.plain)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(task.title)
                    .font(.body)
                    .foregroundStyle(.primary)
                
                Text(task.dueDate.formatted(date: .omitted, time: .shortened))
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Circle()
                .fill(priorityColor)
                .frame(width: 6, height: 6)
        }
        .padding(DesignSystem.Layout.spacing.small)
        .background(Color(nsColor: .controlBackgroundColor).opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

struct DashboardCompletedTaskRow: View {
    let task: Task
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.secondary)
            
            Text(task.title)
                .strikethrough()
                .foregroundStyle(.secondary)
            
            Spacer()
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
    }
}
