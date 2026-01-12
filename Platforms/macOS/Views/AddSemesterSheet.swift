#if os(macOS)
    import SwiftUI

    struct AddSemesterSheet: View {
        @Environment(\.dismiss) private var dismiss
        @EnvironmentObject private var coursesStore: CoursesStore

        @State private var term: SemesterType = .fall
        @State private var year: Int = Calendar.current.component(.year, from: Date())
        @State private var startDate = Date()
        @State private var endDate = Calendar.current.date(byAdding: .month, value: 4, to: Date()) ?? Date()
        @State private var markAsCurrent: Bool = true

        private var computedName: String { "\(term.rawValue) \(year)" }

        private var isSaveDisabled: Bool {
            endDate < startDate
        }

        var body: some View {
            StandardSheetContainer(
                title: "New Semester",
                primaryActionTitle: "Save",
                primaryAction: saveSemester,
                primaryActionDisabled: isSaveDisabled,
                onDismiss: { dismiss() }
            ) {
                VStack(alignment: .leading, spacing: 20) {
                    // Semester Name Preview
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Semester Name")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.secondary)
                            .textCase(.uppercase)
                            .tracking(0.5)

                        Text(computedName)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(.primary)
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.accentColor.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                    Divider()

                    // Term and Year
                    VStack(alignment: .leading, spacing: 12) {
                        Picker("Term", selection: $term) {
                            ForEach(SemesterType.allCases) { t in
                                Text(t.rawValue).tag(t)
                            }
                        }
                        .pickerStyle(.segmented)
                        .onChange(of: term) { _, _ in
                            updateDatesForTerm()
                        }

                        Stepper("Year: \(year)", value: $year, in: 2000 ... 2100)
                            .font(.system(size: 15))
                            .onChange(of: year) { _, _ in
                                updateDatesForTerm()
                            }
                    }

                    Divider()

                    // Dates
                    VStack(alignment: .leading, spacing: 12) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Start Date")
                                .font(.system(size: 13))
                                .foregroundStyle(.secondary)
                            DatePicker("", selection: $startDate, displayedComponents: .date)
                                .datePickerStyle(.field)
                                .labelsHidden()
                        }

                        VStack(alignment: .leading, spacing: 6) {
                            Text("End Date")
                                .font(.system(size: 13))
                                .foregroundStyle(.secondary)
                            DatePicker("", selection: $endDate, displayedComponents: .date)
                                .datePickerStyle(.field)
                                .labelsHidden()
                        }

                        if endDate < startDate {
                            Text("End date must be after start date")
                                .font(.system(size: 12))
                                .foregroundStyle(.red)
                        }
                    }

                    Divider()

                    // Options
                    Toggle("Set as current semester", isOn: $markAsCurrent)
                        .font(.system(size: 15))
                }
            }
        }

        private func updateDatesForTerm() {
            var comps = Calendar.current.dateComponents([.year, .month, .day], from: startDate)
            comps.year = year
            switch term {
            case .fall:
                comps.month = 9
                comps.day = 1
            case .winter:
                comps.month = 1
                comps.day = 6
            case .spring:
                comps.month = 1
                comps.day = 15
            case .summerI:
                comps.month = 6
                comps.day = 1
            case .summerII:
                comps.month = 7
                comps.day = 1
            }
            if let newStart = Calendar.current.date(from: comps) {
                startDate = newStart
                endDate = Calendar.current.date(byAdding: .month, value: 4, to: newStart) ?? newStart
            }
        }

        private func saveSemester() {
            guard endDate >= startDate else { return }
            let sem = Semester(
                startDate: startDate,
                endDate: endDate,
                isCurrent: markAsCurrent,
                educationLevel: .college,
                semesterTerm: term,
                academicYear: "\(year)-\(year + 1)"
            )
            coursesStore.addSemester(sem)
            if markAsCurrent { coursesStore.setCurrentSemester(sem) }
            dismiss()
        }
    }
#endif
