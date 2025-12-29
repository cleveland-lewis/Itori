#if os(macOS)
import SwiftUI
import UniformTypeIdentifiers

struct CourseEditView: View {
    @Environment(\.dismiss) var dismiss
    let coursesStore: CoursesStore
    let semester: Semester?

    @State private var course: Course
    @State private var isNewCourse: Bool

    @State private var selectedColor: Color = .accentColor

    init(course: Course?, semester: Semester? = nil, coursesStore: CoursesStore) {
        self.coursesStore = coursesStore
        self.semester = semester

        if let course = course {
            _course = State(initialValue: course)
            _isNewCourse = State(initialValue: false)
            if let colorHex = course.colorHex, let color = Color(hex: colorHex) {
                _selectedColor = State(initialValue: color)
            }
        } else if let semester = semester {
            _course = State(initialValue: Course(
                title: "",
                code: "",
                semesterId: semester.id
            ))
            _isNewCourse = State(initialValue: true)
        } else {
            // Fallback - should not happen
            _course = State(initialValue: Course(
                title: "",
                code: "",
                semesterId: UUID()
            ))
            _isNewCourse = State(initialValue: true)
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Basic Information") {
                    TextField("Course Title", text: $course.title)
                    TextField("Course Code", text: $course.code)

                    Picker("Course Type", selection: $course.courseType) {
                        ForEach(CourseType.allCases) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                }

                Section("Credits & Schedule") {
                    HStack {
                        TextField("Credits", value: $course.credits, format: .number)
                            .frame(width: 100)

                        Picker("Type", selection: $course.creditType) {
                            ForEach(CreditType.allCases) { type in
                                Text(type.rawValue).tag(type)
                            }
                        }
                        .labelsHidden()
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Meeting Times")
                            .font(.headline)
                        
                        MeetingTimesSelector(meetingTimes: Binding(
                            get: { course.meetingTimes ?? "" },
                            set: { course.meetingTimes = $0.isEmpty ? nil : $0 }
                        ))
                    }
                }

                Section("Details") {
                    TextField("Instructor", text: Binding(
                        get: { course.instructor ?? "" },
                        set: { course.instructor = $0.isEmpty ? nil : $0 }
                    ))

                    TextField("Location", text: Binding(
                        get: { course.location ?? "" },
                        set: { course.location = $0.isEmpty ? nil : $0 }
                    ))

                    ColorPicker("Course Color", selection: $selectedColor)
                }

                Section("Additional Information") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Syllabus")
                            .font(.headline)
                        
                        Button {
                            selectSyllabusFile()
                        } label: {
                            Label("Add Files", systemImage: "doc.badge.plus")
                        }
                        .buttonStyle(.bordered)
                        
                        if let syllabus = course.syllabus, !syllabus.isEmpty {
                            Text(syllabus)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(2)
                        }
                    }
                    
                    TextField("Notes", text: Binding(
                        get: { course.notes ?? "" },
                        set: { course.notes = $0.isEmpty ? nil : $0 }
                    ), axis: .vertical)
                    .lineLimit(3...6)
                }
            }
            .formStyle(.grouped)
            .navigationTitle(isNewCourse ? "New Course" : "Edit Course")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button(isNewCourse ? "Add" : "Save") {
                        saveCourse()
                    }
                    .disabled(course.title.isEmpty || course.code.isEmpty)
                }
            }
        }
        .frame(minWidth: 500, minHeight: 600)
    }

    private func saveCourse() {
        course.colorHex = selectedColor.toHex()

        if isNewCourse {
            coursesStore.addCourse(course)
        } else {
            coursesStore.updateCourse(course)
        }

        dismiss()
    }
    
    private func selectSyllabusFile() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowedContentTypes = [.pdf, .text, .plainText, .rtf, .html, .url]
        panel.message = "Select syllabus file"
        
        panel.begin { response in
            if response == .OK, let url = panel.url {
                // Store the file path or bookmark
                course.syllabus = url.path
            }
        }
    }
}
struct MeetingTimesSelector: View {
    @Binding var meetingTimes: String
    
    @State private var selectedDays: Set<String> = []
    @State private var startTime = Date()
    @State private var endTime = Date()
    
    private let days = ["M", "T", "W", "Th", "F"]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Days checkboxes
            HStack(spacing: 12) {
                ForEach(days, id: \.self) { day in
                    Toggle(day, isOn: Binding(
                        get: { selectedDays.contains(day) },
                        set: { isSelected in
                            if isSelected {
                                selectedDays.insert(day)
                            } else {
                                selectedDays.remove(day)
                            }
                            updateMeetingTimesString()
                        }
                    ))
                    .toggleStyle(.checkbox)
                }
            }
            
            // Time pickers
            HStack(spacing: 12) {
                DatePicker("Start", selection: $startTime, displayedComponents: .hourAndMinute)
                    .labelsHidden()
                    .onChange(of: startTime) { _, _ in updateMeetingTimesString() }
                
                Text("to")
                    .foregroundStyle(.secondary)
                
                DatePicker("End", selection: $endTime, displayedComponents: .hourAndMinute)
                    .labelsHidden()
                    .onChange(of: endTime) { _, _ in updateMeetingTimesString() }
            }
        }
        .onAppear {
            parseMeetingTimes()
        }
    }
    
    private func parseMeetingTimes() {
        // Parse existing meeting times string like "MWF 9:00-10:00"
        let components = meetingTimes.split(separator: " ")
        if components.count >= 2 {
            let daysString = String(components[0])
            selectedDays = Set(daysString.map { String($0) }.filter { days.contains($0) })
            
            let timeRange = String(components[1])
            let times = timeRange.split(separator: "-")
            if times.count == 2 {
                startTime = parseTime(String(times[0])) ?? Date()
                endTime = parseTime(String(times[1])) ?? Date()
            }
        }
    }
    
    private func parseTime(_ timeString: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "H:mm"
        return formatter.date(from: timeString)
    }
    
    private func updateMeetingTimesString() {
        guard !selectedDays.isEmpty else {
            meetingTimes = ""
            return
        }
        
        let sortedDays = days.filter { selectedDays.contains($0) }.joined()
        let formatter = DateFormatter()
        formatter.dateFormat = "H:mm"
        let startStr = formatter.string(from: startTime)
        let endStr = formatter.string(from: endTime)
        
        meetingTimes = "\(sortedDays) \(startStr)-\(endStr)"
    }
}
#endif
