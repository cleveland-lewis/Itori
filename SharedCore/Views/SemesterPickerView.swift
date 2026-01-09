//
//  SemesterPickerView.swift
//  Itori
//
//  Multi-select semester picker with checkmarks
//

import SwiftUI

struct SemesterPickerView: View {
    @EnvironmentObject private var coursesStore: CoursesStore

    var body: some View {
        Menu {
            ForEach(coursesStore.nonArchivedSemesters) { semester in
                let isActive = coursesStore.activeSemesterIds.contains(semester.id)
                Button {
                    guard canToggleSemester(isActive: isActive) else { return }
                    coursesStore.toggleActiveSemester(semester)
                } label: {
                    HStack {
                        Text(semester.name)
                        Spacer()
                        if isActive {
                            Image(systemName: "checkmark")
                        }
                    }
                }
                .disabled(!canToggleSemester(isActive: isActive))
            }

            if !coursesStore.nonArchivedSemesters.isEmpty {
                Divider()

                // Quick actions
                Button(NSLocalizedString(
                    "semesterpicker.button.select.all",
                    value: "Select All",
                    comment: "Select All"
                )) {
                    let allIds = Set(coursesStore.nonArchivedSemesters.map(\.id))
                    coursesStore.setActiveSemesters(allIds)
                }

                Button(NSLocalizedString("semesterpicker.button.clear.all", value: "Clear All", comment: "Clear All")) {
                    coursesStore.setActiveSemesters([])
                }
                .disabled(!canClearAll)
            }
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "calendar")
                    .font(.system(size: 14))

                Text(summaryText)

                Image(systemName: "chevron.down")
                    .font(.system(size: 10))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.accentColor.opacity(0.1), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
    }

    private var summaryText: String {
        let count = coursesStore.activeSemesterIds.count
        if count == 0 {
            return "No Active Semester"
        }
        let ordered = coursesStore.activeSemesters.sorted { $0.startDate < $1.startDate }
        if count == 1, let first = ordered.first {
            return first.name
        }
        if count == 2, let first = ordered.first {
            return "\(first.name) + 1"
        }
        return "\(count) Active Semesters"
    }

    private var canClearAll: Bool {
        coursesStore.activeSemesterIds.count > 1
    }

    private func canToggleSemester(isActive: Bool) -> Bool {
        if isActive && coursesStore.activeSemesterIds.count <= 1 {
            return false
        }
        return true
    }
}

// MARK: - Compact Version for Toolbar

struct CompactSemesterPicker: View {
    @EnvironmentObject private var coursesStore: CoursesStore

    var body: some View {
        Menu {
            ForEach(coursesStore.nonArchivedSemesters) { semester in
                let isActive = coursesStore.activeSemesterIds.contains(semester.id)
                Button {
                    guard canToggleSemester(isActive: isActive) else { return }
                    coursesStore.toggleActiveSemester(semester)
                } label: {
                    HStack {
                        Text(semester.name)
                        if isActive {
                            Image(systemName: "checkmark")
                        }
                    }
                }
                .disabled(!canToggleSemester(isActive: isActive))
            }
        } label: {
            Label {
                Text(summaryText)
            } icon: {
                Image(systemName: "calendar")
            }
        }
    }

    private var summaryText: String {
        let count = coursesStore.activeSemesterIds.count
        if count == 0 {
            return "No Active Semester"
        }
        let ordered = coursesStore.activeSemesters.sorted { $0.startDate < $1.startDate }
        if count == 1, let first = ordered.first {
            return first.name
        }
        if count == 2, let first = ordered.first {
            return "\(first.name) + 1"
        }
        return "\(count) Active Semesters"
    }

    private func canToggleSemester(isActive: Bool) -> Bool {
        if isActive && coursesStore.activeSemesterIds.count <= 1 {
            return false
        }
        return true
    }
}

#Preview {
    SemesterPickerView()
        .environmentObject(CoursesStore())
        .padding()
}
