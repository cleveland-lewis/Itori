import SwiftUI
import Charts

/// Grades Analytics page showing charts, trends, and grade insights
struct GradesAnalyticsView: View {
    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var assignmentsStore: AssignmentsStore
    @EnvironmentObject private var coursesStore: CoursesStore
    
    @Environment(\.dismiss) private var dismiss
    
    // MARK: - Filter State
    @State private var selectedCourseId: UUID?
    @State private var showWeightedGPA: Bool = true
    @State private var selectedDateRange: DateRangeFilter = .allTime
    
    // MARK: - What-If Simulator State
    @State private var whatIfMode: Bool = false
    @State private var whatIfAssignments: [UUID: Double] = [:] // taskId -> hypothetical grade
    
    // MARK: - Interaction State
    @State private var selectedChartElement: String?
    @State private var showRiskBreakdown: Bool = false
    @State private var selectedForecastScenario: ForecastScenario = .realistic
    
    var body: some View {
        ZStack(alignment: .top) {
            ScrollView {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.large) {
                    header
                    
                    // What-If Banner
                    if whatIfMode {
                        whatIfBanner
                    }
                    
                    filterControls
                    
                    chartsSection
                    
                    if showRiskBreakdown {
                        riskBreakdownSection
                    }
                }
                .padding(DesignSystem.Spacing.large)
            }
            .frame(minWidth: 900, minHeight: 700)
            .rootsSystemBackground()
        }
    }
    
    // MARK: - Header
    
    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Grade Analytics")
                    .font(.title.bold())
                
                Text("Visualize your academic performance")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.secondary)
                    .symbolRenderingMode(.hierarchical)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Close")
        }
    }
    
    // MARK: - What-If Banner
    
    private var whatIfBanner: some View {
        HStack(spacing: 12) {
            Image(systemName: "wand.and.stars")
                .foregroundStyle(settings.activeAccentColor)
                .symbolRenderingMode(.hierarchical)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("What-If Mode Active")
                    .font(.subheadline.weight(.semibold))
                
                Text("Hypothetical grades won't be saved")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Button("Reset") {
                resetWhatIfMode()
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
            
            Button {
                whatIfMode = false
            } label: {
                Image(systemName: "xmark")
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
        }
        .padding()
        .background(settings.activeAccentColor.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(settings.activeAccentColor.opacity(0.3), lineWidth: 1)
        )
    }
    
    // MARK: - Filter Controls
    
    private var filterControls: some View {
        GroupBox("Filters") {
            HStack(spacing: 12) {
                Picker("Course", selection: $selectedCourseId) {
                    Text("All Courses").tag(Optional<UUID>.none)
                    ForEach(coursesStore.courses) { course in
                        Text(course.code).tag(Optional(course.id))
                    }
                }
                .pickerStyle(.menu)

                Picker("Date Range", selection: $selectedDateRange) {
                    ForEach(DateRangeFilter.allCases, id: \.self) { range in
                        Text(range.label).tag(range)
                    }
                }
                .pickerStyle(.menu)

                Toggle("Weighted", isOn: $showWeightedGPA)
                    .toggleStyle(.switch)

                Spacer()

                Button {
                    whatIfMode.toggle()
                    if whatIfMode {
                        whatIfAssignments = [:]
                    }
                } label: {
                    Label("What-If Mode", systemImage: "wand.and.stars")
                }
                .buttonStyle(.borderedProminent)
                .tint(whatIfMode ? settings.activeAccentColor : .secondary)

                Button {
                    showRiskBreakdown.toggle()
                } label: {
                    Label("Risk Analysis", systemImage: "exclamationmark.triangle")
                }
                .buttonStyle(.bordered)
            }
            .controlSize(.regular)
            .padding(.vertical, 4)
        }
    }
    
    // MARK: - Charts Section
    
    private var chartsSection: some View {
        VStack(spacing: DesignSystem.Spacing.medium) {
            // Row 1: GPA Trend + Grade Distribution
            HStack(spacing: DesignSystem.Spacing.medium) {
                gpaTrendChart
                    .frame(maxWidth: .infinity)
                
                gradeDistributionChart
                    .frame(maxWidth: .infinity)
            }
            
            // Row 2: Course Performance + Assignment Completion
            HStack(spacing: DesignSystem.Spacing.medium) {
                coursePerformanceChart
                    .frame(maxWidth: .infinity)
                
                assignmentCompletionChart
                    .frame(maxWidth: .infinity)
            }
        }
    }
    
    // MARK: - Individual Charts
    
    private var gpaTrendChart: some View {
        RootsChartContainer(
            title: "GPA Trend",
            summary: "Your GPA over time"
        ) {
            let data = generateGPATrendData()
            
            Chart(data) { item in
                LineMark(
                    x: .value("Week", item.week),
                    y: .value("GPA", item.gpa)
                )
                .foregroundStyle(settings.activeAccentColor)
                .interpolationMethod(.catmullRom)
                
                AreaMark(
                    x: .value("Week", item.week),
                    y: .value("GPA", item.gpa)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            settings.activeAccentColor.opacity(0.3),
                            settings.activeAccentColor.opacity(0.0)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .interpolationMethod(.catmullRom)
            }
            .chartYScale(domain: 0...4.0)
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisGridLine()
                    AxisValueLabel()
                }
            }
            .frame(height: 200)
        }
        .accessibilityLabel("GPA Trend Chart")
        .accessibilityValue("Shows GPA progression over recent weeks")
    }
    
    private var gradeDistributionChart: some View {
        RootsChartContainer(
            title: "Grade Distribution",
            summary: "Breakdown by letter grade"
        ) {
            let data = generateGradeDistributionData()
            
            Chart(data) { item in
                BarMark(
                    x: .value("Grade", item.grade),
                    y: .value("Count", item.count)
                )
                .foregroundStyle(colorForGrade(item.grade))
                .cornerRadius(8)
            }
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisGridLine()
                    AxisValueLabel()
                }
            }
            .frame(height: 200)
        }
        .accessibilityLabel("Grade Distribution Chart")
        .accessibilityValue("Shows count of assignments by letter grade")
    }
    
    private var coursePerformanceChart: some View {
        RootsChartContainer(
            title: "Course Performance",
            summary: "Current grade by course"
        ) {
            let data = generateCoursePerformanceData()
            
            Chart(data) { item in
                BarMark(
                    x: .value("Course", item.courseCode),
                    y: .value("Grade", item.percentage)
                )
                .foregroundStyle(settings.activeAccentColor)
                .cornerRadius(8)
            }
            .chartYScale(domain: 0...100)
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisGridLine()
                    AxisValueLabel()
                }
            }
            .frame(height: 200)
        }
        .accessibilityLabel("Course Performance Chart")
        .accessibilityValue("Shows current grade percentage for each course")
    }
    
    private var assignmentCompletionChart: some View {
        RootsChartContainer(
            title: "Assignment Completion",
            summary: "Completed vs. pending"
        ) {
            let data = generateAssignmentCompletionData()
            
            Chart(data) { item in
                SectorMark(
                    angle: .value("Count", item.count),
                    innerRadius: .ratio(0.5),
                    angularInset: 2
                )
                .foregroundStyle(item.color)
                .cornerRadius(4)
            }
            .frame(height: 200)
            .overlay {
                VStack(spacing: 4) {
                    Text("\(data.first(where: { $0.status == "Completed" })?.count ?? 0)")
                        .font(.title.bold())
                    Text("Completed")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .accessibilityLabel("Assignment Completion Chart")
        .accessibilityValue("Shows ratio of completed to pending assignments")
    }
    
    // MARK: - Data Generation
    
    private struct GPATrendItem: Identifiable {
        let id = UUID()
        let week: String
        let gpa: Double
    }
    
    private func generateGPATrendData() -> [GPATrendItem] {
        let calendar = Calendar.current
        let endDate = Date()
        let endWeekStart = calendar.dateInterval(of: .weekOfYear, for: endDate)?.start ?? endDate
        let defaultStart = calendar.date(byAdding: .weekOfYear, value: -7, to: endWeekStart) ?? endWeekStart
        let rangeStart = dateRangeBounds()?.start ?? defaultStart
        let startDate = max(rangeStart, defaultStart)

        var items: [GPATrendItem] = []
        for index in 0..<8 {
            guard let weekStart = calendar.date(byAdding: .weekOfYear, value: index, to: startDate) else { continue }
            if weekStart > endDate { break }
            let weekEnd = calendar.date(byAdding: .day, value: 6, to: weekStart) ?? weekStart
            let tasks = tasksForTrend(upTo: min(weekEnd, endDate))
            let courses = filteredCourses()
            let gpa = gpaValue(courses: courses, tasks: tasks, weighted: showWeightedGPA)
            items.append(GPATrendItem(week: "Week \(index + 1)", gpa: gpa))
        }

        return items
    }
    
    private struct GradeDistributionItem: Identifiable {
        let id = UUID()
        let grade: String
        let count: Int
    }
    
    private func generateGradeDistributionData() -> [GradeDistributionItem] {
        let tasks = filteredTasks().filter { $0.isCompleted && $0.gradeEarnedPoints != nil }
        var gradeCounts: [String: Int] = ["A": 0, "B": 0, "C": 0, "D": 0, "F": 0]
        
        for task in tasks {
            if let earned = task.gradeEarnedPoints, let possible = task.gradePossiblePoints, possible > 0 {
                let percentage = (earned / possible) * 100
                let grade: String
                if percentage >= 90 { grade = "A" }
                else if percentage >= 80 { grade = "B" }
                else if percentage >= 70 { grade = "C" }
                else if percentage >= 60 { grade = "D" }
                else { grade = "F" }
                gradeCounts[grade, default: 0] += 1
            }
        }
        
        return ["A", "B", "C", "D", "F"].map { grade in
            GradeDistributionItem(grade: grade, count: gradeCounts[grade] ?? 0)
        }
    }
    
    private struct CoursePerformanceItem: Identifiable {
        let id = UUID()
        let courseCode: String
        let percentage: Double
    }
    
    private func generateCoursePerformanceData() -> [CoursePerformanceItem] {
        let tasks = filteredTasks()
        return filteredCourses().compactMap { course in
            guard let percentage = coursePercent(for: course.id, tasks: tasks, weighted: showWeightedGPA) else { return nil }
            return CoursePerformanceItem(courseCode: course.code, percentage: percentage)
        }
    }
    
    private struct AssignmentCompletionItem: Identifiable {
        let id = UUID()
        let status: String
        let count: Int
        let color: Color
    }
    
    private func generateAssignmentCompletionData() -> [AssignmentCompletionItem] {
        let tasks = filteredTasks()
        let completed = tasks.filter { $0.isCompleted }.count
        let pending = tasks.filter { !$0.isCompleted }.count
        
        return [
            AssignmentCompletionItem(status: "Completed", count: completed, color: .green),
            AssignmentCompletionItem(status: "Pending", count: pending, color: .orange)
        ]
    }
    
    // MARK: - Risk Breakdown Section
    
    private var riskBreakdownSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Risk Analysis")
                    .font(.title3.bold())
                
                Spacer()
                
                Button {
                    showRiskBreakdown = false
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
            
            VStack(spacing: 12) {
                riskCard(
                    level: "High Risk",
                    courses: getCoursesAtRisk(threshold: 70),
                    color: .red,
                    icon: "exclamationmark.triangle.fill",
                    description: "Courses below 70% need immediate attention"
                )
                
                riskCard(
                    level: "Moderate Risk",
                    courses: getCoursesAtRisk(threshold: 80, max: 70),
                    color: .orange,
                    icon: "exclamationmark.circle.fill",
                    description: "Courses between 70-80% require monitoring"
                )
                
                riskCard(
                    level: "On Track",
                    courses: getCoursesAtRisk(threshold: 100, max: 80),
                    color: .green,
                    icon: "checkmark.circle.fill",
                    description: "Courses above 80% are performing well"
                )
            }
        }
        .padding()
        .background(DesignSystem.Materials.card)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.05), lineWidth: 1)
        )
    }
    
    private func riskCard(level: String, courses: [Course], color: Color, icon: String, description: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
                .symbolRenderingMode(.hierarchical)
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(level)
                        .font(.headline)
                    
                    Text("(\(courses.count))")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                if !courses.isEmpty {
                    Text(courses.map { $0.code }.joined(separator: ", "))
                        .font(.caption.bold())
                        .foregroundStyle(color)
                }
            }
            
            Spacer()
        }
        .padding()
        .background(color.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
    
    private func getCoursesAtRisk(threshold: Double, max: Double? = nil) -> [Course] {
        let tasks = filteredTasks()
        return filteredCourses().filter { course in
            if let grade = coursePercent(for: course.id, tasks: tasks, weighted: showWeightedGPA) {
                if let max = max {
                    return grade < threshold && grade >= max
                } else {
                    return grade < threshold
                }
            }
            return false
        }
    }
    
    // MARK: - What-If Functions
    
    private func resetWhatIfMode() {
        whatIfAssignments = [:]
    }
    
    // MARK: - Helpers
    
    private func colorForGrade(_ grade: String) -> Color {
        switch grade {
        case "A": return .green
        case "B": return .blue
        case "C": return .yellow
        case "D": return .orange
        case "F": return .red
        default: return .gray
        }
    }

    private func filteredCourses() -> [Course] {
        if let selectedCourseId = selectedCourseId {
            return coursesStore.courses.filter { $0.id == selectedCourseId }
        }
        return coursesStore.courses
    }

    private func filteredTasks() -> [AppTask] {
        let tasks = assignmentsStore.tasks
        let courseFiltered = selectedCourseId == nil ? tasks : tasks.filter { $0.courseId == selectedCourseId }
        guard let bounds = dateRangeBounds() else {
            return courseFiltered
        }
        return courseFiltered.filter { task in
            guard let due = task.due else { return false }
            return due >= bounds.start && due <= bounds.end
        }
    }

    private func tasksForTrend(upTo endDate: Date) -> [AppTask] {
        let tasks = assignmentsStore.tasks
        let courseFiltered = selectedCourseId == nil ? tasks : tasks.filter { $0.courseId == selectedCourseId }
        let startDate = dateRangeBounds()?.start
        return courseFiltered.filter { task in
            guard let due = task.due else { return false }
            if let startDate = startDate, due < startDate { return false }
            return due <= endDate
        }
    }

    private func dateRangeBounds() -> (start: Date, end: Date)? {
        let calendar = Calendar.current
        let now = Date()
        switch selectedDateRange {
        case .allTime:
            return nil
        case .thisMonth:
            let start = calendar.dateInterval(of: .month, for: now)?.start ?? now
            return (start: start, end: now)
        case .thisQuarter:
            let month = calendar.component(.month, from: now)
            let quarterStartMonth = ((month - 1) / 3) * 3 + 1
            var components = calendar.dateComponents([.year, .month], from: now)
            components.month = quarterStartMonth
            let start = calendar.date(from: components) ?? now
            return (start: start, end: now)
        case .thisSemester:
            let month = calendar.component(.month, from: now)
            let semesterStartMonth = month <= 6 ? 1 : 7
            var components = calendar.dateComponents([.year, .month], from: now)
            components.month = semesterStartMonth
            let start = calendar.date(from: components) ?? now
            return (start: start, end: now)
        }
    }

    private func coursePercent(for courseId: UUID, tasks: [AppTask], weighted: Bool) -> Double? {
        if weighted {
            return GradeCalculator.calculateCourseGrade(courseID: courseId, tasks: tasks)
        }
        let graded = tasks.filter { task in
            task.courseId == courseId &&
            task.isCompleted &&
            task.gradeEarnedPoints != nil &&
            task.gradePossiblePoints ?? 0 > 0
        }
        guard !graded.isEmpty else { return nil }
        let total = graded.reduce(0.0) { partial, task in
            let earned = task.gradeEarnedPoints ?? 0
            let possible = task.gradePossiblePoints ?? 0
            guard possible > 0 else { return partial }
            return partial + (earned / possible) * 100
        }
        return total / Double(graded.count)
    }

    private func gpaValue(courses: [Course], tasks: [AppTask], weighted: Bool) -> Double {
        if weighted {
            return GradeCalculator.calculateGPA(courses: courses, tasks: tasks)
        }

        var total: Double = 0
        var creditSum: Double = 0

        for course in courses {
            guard let percent = coursePercent(for: course.id, tasks: tasks, weighted: false) else { continue }
            let gpaValue = mapPercentToGPA(percent)
            let credits = course.credits ?? 1
            total += gpaValue * credits
            creditSum += credits
        }

        guard creditSum > 0 else { return 0 }
        return total / creditSum
    }

    private func mapPercentToGPA(_ percent: Double) -> Double {
        switch percent {
        case 93...: return 4.0
        case 90..<93: return 3.7
        case 87..<90: return 3.3
        case 83..<87: return 3.0
        case 80..<83: return 2.7
        case 77..<80: return 2.3
        case 73..<77: return 2.0
        case 70..<73: return 1.7
        case 67..<70: return 1.3
        case 63..<67: return 1.0
        case 60..<63: return 0.7
        default: return 0.0
        }
    }
}

// MARK: - Supporting Types

enum DateRangeFilter: CaseIterable {
    case allTime
    case thisMonth
    case thisQuarter
    case thisSemester
    
    var label: String {
        switch self {
        case .allTime: return "All Time"
        case .thisMonth: return "This Month"
        case .thisQuarter: return "This Quarter"
        case .thisSemester: return "This Semester"
        }
    }
}

enum ForecastScenario: CaseIterable {
    case optimistic
    case realistic
    case pessimistic
    
    var label: String {
        switch self {
        case .optimistic: return "Optimistic"
        case .realistic: return "Realistic"
        case .pessimistic: return "Pessimistic"
        }
    }
}

// MARK: - Preview

#if !DISABLE_PREVIEWS
#Preview {
    let settings = AppSettings()
    let assignmentsStore = AssignmentsStore.shared
    let coursesStore = CoursesStore(storageURL: nil)
    
    return GradesAnalyticsView()
        .environmentObject(settings)
        .environmentObject(assignmentsStore)
        .environmentObject(coursesStore)
}
#endif
