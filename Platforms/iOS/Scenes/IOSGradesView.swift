#if os(iOS)
import SwiftUI

struct IOSGradesView: View {
    @EnvironmentObject private var coursesStore: CoursesStore
    @EnvironmentObject private var assignmentsStore: AssignmentsStore
    @EnvironmentObject private var gradesStore: GradesStore
    @EnvironmentObject private var sheetRouter: IOSSheetRouter
    @EnvironmentObject private var toastRouter: IOSToastRouter
    @State private var selectedCourse: Course? = nil
    @State private var showingGradeEditor = false
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.layoutMetrics) private var metrics
    
    private var isPad: Bool {
        horizontalSizeClass == .regular
    }
    
    var body: some View {
        List {
            if coursesStore.activeCourses.isEmpty {
                IOSInlineEmptyState(
                    title: NSLocalizedString("ios.grades.empty.title", value: "No courses yet", comment: "No courses"),
                    subtitle: NSLocalizedString("ios.grades.empty.subtitle", value: "Add courses to track grades", comment: "Add courses to track grades")
                )
            } else {
                Section {
                    overallGPACard
                }
                
                Section(NSLocalizedString("ios.grades.courses.section", value: "Courses", comment: "Courses")) {
                    ForEach(coursesStore.activeCourses) { course in
                        courseRow(for: course)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                selectedCourse = course
                            }
                            .accessibilityAddTraits(.isButton)
                            .accessibilityHint("View course grade details")
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(DesignSystem.Colors.appBackground)
        .navigationTitle(NSLocalizedString("ios.grades.title", value: "Grades", comment: "Grades"))
        .refreshable {
            await refreshGradesData()
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    sheetRouter.activeSheet = .addGrade(UUID())
                } label: {
                    Image(systemName: "plus")
                        .accessibilityLabel("Add grade")
                }
            }
        }
        .sheet(item: $selectedCourse) { course in
            IOSCourseGradeDetailView(course: course)
                .environmentObject(coursesStore)
                .environmentObject(assignmentsStore)
                .environmentObject(gradesStore)
                .environmentObject(toastRouter)
        }
    }
    
    private var overallGPACard: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(NSLocalizedString("ios.grades.overall_gpa", value: "Overall GPA", comment: "Overall GPA"))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text(String(format: "%.2f", calculateOverallGPA()))
                        .font(.system(.largeTitle, weight: .bold))
                        .foregroundStyle(.primary)
                }
                Spacer()
                Image(systemName: "chart.bar.doc.horizontal.fill")
                    .font(.system(.largeTitle))
                    .foregroundStyle(gpaColor(calculateOverallGPA()))
                    .opacity(0.3)
                    .accessibilityHidden(true)
            }
            
            if !coursesStore.activeCourses.isEmpty {
                Divider()
                HStack {
                    statItem(label: NSLocalizedString("ios.grades.courses", value: "Courses", comment: "Courses"), value: "\(coursesStore.activeCourses.count)")
                    Spacer()
                    statItem(label: NSLocalizedString("ios.grades.graded", value: "Graded", comment: "Graded"), value: "\(gradedCoursesCount)")
                }
            }
        }
        .padding(metrics.cardPadding)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(uiColor: .secondarySystemGroupedBackground))
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Overall GPA: \(String(format: "%.2f", calculateOverallGPA())), \(coursesStore.activeCourses.count) courses, \(gradedCoursesCount) graded")
    }
    
    private func courseRow(for course: Course) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(course.code.isEmpty ? course.title : course.code)
                    .font(.body.weight(.medium))
                if !course.code.isEmpty {
                    Text(course.title)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
            
            if let gradeEntry = gradesStore.grade(for: course.id) {
                if let percent = gradeEntry.percent {
                    GradeIndicator(percent: percent, letter: gradeEntry.letter)
                } else if let letter = gradeEntry.letter {
                    Text(letter)
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.primary)
                }
            } else {
                Text(NSLocalizedString("ios.grades.not_graded", value: "Not graded", comment: "Not graded"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabelFor(course: course))
        .accessibilityHint("Tap to view course details")
    }
    
    private func accessibilityLabelFor(course: Course) -> String {
        let courseName = course.code.isEmpty ? course.title : "\(course.code), \(course.title)"
        if let gradeEntry = gradesStore.grade(for: course.id) {
            if let percent = gradeEntry.percent {
                if let letter = gradeEntry.letter {
                    return "\(courseName), grade: \(String(format: "%.1f", percent)) percent, \(letter)"
                } else {
                    return "\(courseName), grade: \(String(format: "%.1f", percent)) percent"
                }
            } else if let letter = gradeEntry.letter {
                return "\(courseName), grade: \(letter)"
            }
        }
        return "\(courseName), not graded"
    }
    
    private func statItem(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.title3.weight(.semibold))
        }
    }
    
    private func calculateOverallGPA() -> Double {
        let gradedCourses = coursesStore.activeCourses.compactMap { course -> (course: Course, percent: Double)? in
            guard let gradeEntry = gradesStore.grade(for: course.id),
                  let percent = gradeEntry.percent else {
                return nil
            }
            return (course, percent)
        }
        
        guard !gradedCourses.isEmpty else { return 0.0 }
        
        let totalPoints = gradedCourses.reduce(0.0) { total, item in
            let gpa = percentToGPA(item.percent)
            let credits = item.course.credits ?? 3.0
            return total + (gpa * credits)
        }
        
        let totalCredits = gradedCourses.reduce(0.0) { total, item in
            total + (item.course.credits ?? 3.0)
        }
        
        return totalCredits > 0 ? totalPoints / totalCredits : 0.0
    }
    
    private var gradedCoursesCount: Int {
        coursesStore.activeCourses.filter { course in
            gradesStore.grade(for: course.id) != nil
        }.count
    }
    
    private func percentToGPA(_ percent: Double) -> Double {
        switch percent {
        case 93...100: return 4.0
        case 90..<93: return 3.7
        case 87..<90: return 3.3
        case 83..<87: return 3.0
        case 80..<83: return 2.7
        case 77..<80: return 2.3
        case 73..<77: return 2.0
        case 70..<73: return 1.7
        case 67..<70: return 1.3
        case 60..<67: return 1.0
        default: return 0.0
        }
    }
    
    private func gradeColor(_ percent: Double) -> Color {
        switch percent {
        case 90...100: return .green
        case 80..<90: return .blue
        case 70..<80: return .orange
        default: return .red
        }
    }
    
    private func gradeIcon(_ percent: Double) -> String {
        switch percent {
        case 90...100: return "star.fill"
        case 80..<90: return "hand.thumbsup.fill"
        case 70..<80: return "minus.circle.fill"
        default: return "exclamationmark.triangle.fill"
        }
    }
    
    private func gpaColor(_ gpa: Double) -> Color {
        switch gpa {
        case 3.5...4.0: return .green
        case 3.0..<3.5: return .blue
        case 2.0..<3.0: return .orange
        default: return .red
        }
    }
    
    private func gpaIcon(_ gpa: Double) -> String {
        switch gpa {
        case 3.5...4.0: return "star.fill"
        case 3.0..<3.5: return "hand.thumbsup.fill"
        case 2.0..<3.0: return "minus.circle.fill"
        default: return "exclamationmark.triangle.fill"
        }
    }
    
    private func refreshGradesData() async {
        // GradesStore automatically syncs with iCloud
        // Just trigger haptic feedback to confirm refresh
        FeedbackManager.shared.trigger(event: .dataRefreshed)
    }
}

struct IOSCourseGradeDetailView: View {
    let course: Course
    @EnvironmentObject private var coursesStore: CoursesStore
    @EnvironmentObject private var assignmentsStore: AssignmentsStore
    @EnvironmentObject private var gradesStore: GradesStore
    @EnvironmentObject private var toastRouter: IOSToastRouter
    @Environment(\.dismiss) private var dismiss
    @State private var editingPercent: String = ""
    @State private var editingLetter: String = ""
    @State private var isEditing = false
    
    var body: some View {
        NavigationStack {
            List {
                Section(NSLocalizedString("ios.grades.overall_grade", value: "Overall Grade", comment: "Overall Grade")) {
                    if isEditing {
                        HStack {
                            TextField(NSLocalizedString("ios.grades.percent", value: "Percent", comment: "Percent"), text: $editingPercent)
                                .keyboardType(.decimalPad)
                            Text(NSLocalizedString("%", value: "%", comment: ""))
                                .foregroundStyle(.secondary)
                        }
                        TextField(NSLocalizedString("ios.grades.letter", value: "Letter Grade", comment: "Letter Grade"), text: $editingLetter)
                    } else {
                        if let gradeEntry = gradesStore.grade(for: course.id) {
                            if let percent = gradeEntry.percent {
                                HStack {
                                    Text(NSLocalizedString("ios.grades.percentage", value: "Percentage", comment: "Percentage"))
                                    Spacer()
                                    Text(String(format: "%.1f%%", percent))
                                        .foregroundStyle(gradeColor(percent))
                                        .font(.body.weight(.semibold))
                                }
                            }
                            if let letter = gradeEntry.letter {
                                HStack {
                                    Text(NSLocalizedString("ios.grades.letter_grade", value: "Letter Grade", comment: "Letter Grade"))
                                    Spacer()
                                    Text(letter)
                                        .font(.body.weight(.semibold))
                                }
                            }
                        } else {
                            Text(NSLocalizedString("ios.grades.no_grade_entered", value: "No grade entered", comment: "No grade entered"))
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                
                Section(NSLocalizedString("ios.grades.assignments", value: "Assignments", comment: "Assignments")) {
                    let courseAssignments = assignmentsStore.tasks.filter { $0.courseId == course.id }
                    if courseAssignments.isEmpty {
                        Text(NSLocalizedString("ios.grades.no_assignments", value: "No assignments", comment: "No assignments"))
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(courseAssignments) { task in
                            assignmentRow(for: task)
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle(course.code.isEmpty ? course.title : course.code)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(NSLocalizedString("ios.grades.close", value: "Close", comment: "Close")) {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(isEditing ? NSLocalizedString("ios.grades.save", value: "Save", comment: "Save") : NSLocalizedString("ios.grades.edit", value: "Edit", comment: "Edit")) {
                        if isEditing {
                            saveGrade()
                        } else {
                            startEditing()
                        }
                    }
                }
            }
        }
    }
    
    private func assignmentRow(for task: AppTask) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(task.title)
                    .font(.body)
                if let earnedPoints = task.gradeEarnedPoints,
                   let possiblePoints = task.gradePossiblePoints,
                   possiblePoints > 0 {
                    Text(String(format: "%.1f / %.1f", earnedPoints, possiblePoints))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
            
            if let earnedPoints = task.gradeEarnedPoints,
               let possiblePoints = task.gradePossiblePoints,
               possiblePoints > 0 {
                let percent = (earnedPoints / possiblePoints) * 100
                Text(String(format: "%.1f%%", percent))
                    .font(.body.weight(.semibold))
                    .foregroundStyle(gradeColor(percent))
            } else {
                Text(NSLocalizedString("ios.grades.not_graded", value: "Not graded", comment: "Not graded"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 2)
    }
    
    private func startEditing() {
        if let gradeEntry = gradesStore.grade(for: course.id) {
            editingPercent = gradeEntry.percent.map { String(format: "%.1f", $0) } ?? ""
            editingLetter = gradeEntry.letter ?? ""
        } else {
            editingPercent = ""
            editingLetter = ""
        }
        isEditing = true
    }
    
    private func saveGrade() {
        let percent = Double(editingPercent)
        let letter = editingLetter.isEmpty ? nil : editingLetter
        
        gradesStore.upsert(courseId: course.id, percent: percent, letter: letter)
        toastRouter.show(NSLocalizedString("ios.grades.grade_updated", value: "Grade updated", comment: "Grade updated"))
        isEditing = false
    }
    
    private func gradeColor(_ percent: Double) -> Color {
        switch percent {
        case 90...100: return .green
        case 80..<90: return .blue
        case 70..<80: return .orange
        default: return .red
        }
    }
}

private struct GradeIndicator: View {
    let percent: Double
    let letter: String?
    
    @Environment(\.accessibilityDifferentiateWithoutColor) private var differentiateWithoutColor
    
    var body: some View {
        HStack(spacing: 6) {
            if differentiateWithoutColor {
                Image(systemName: gradeIcon(percent))
                    .font(.caption)
                    .foregroundStyle(gradeColor(percent))
                    .accessibilityHidden(true)
            }
            
            VStack(alignment: .trailing, spacing: 2) {
                Text(String(format: "%.1f%%", percent))
                    .font(.body.weight(.semibold))
                    .foregroundStyle(gradeColor(percent))
                if let letter {
                    Text(letter)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(String(format: "%.1f", percent)) percent\(letter.map { ", \($0)" } ?? "")")
    }
    
    private func gradeColor(_ percent: Double) -> Color {
        switch percent {
        case 90...100: return .green
        case 80..<90: return .blue
        case 70..<80: return .orange
        default: return .red
        }
    }
    
    private func gradeIcon(_ percent: Double) -> String {
        switch percent {
        case 90...100: return "star.fill"
        case 80..<90: return "hand.thumbsup.fill"
        case 70..<80: return "minus.circle.fill"
        default: return "exclamationmark.triangle.fill"
        }
    }
}

private struct IOSInlineEmptyState: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.body.weight(.semibold))
            Text(subtitle)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 8)
    }
}

#endif
