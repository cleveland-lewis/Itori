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
                Button {
                    coursesStore.toggleActiveSemester(semester)
                } label: {
                    HStack {
                        Text(semester.name)
                        Spacer()
                        if coursesStore.activeSemesterIds.contains(semester.id) {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
            
            if !coursesStore.nonArchivedSemesters.isEmpty {
                Divider()
                
                // Quick actions
                Button("Select All") {
                    let allIds = Set(coursesStore.nonArchivedSemesters.map { $0.id })
                    coursesStore.setActiveSemesters(allIds)
                }
                
                Button("Clear All") {
                    coursesStore.setActiveSemesters([])
                }
            }
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "calendar")
                    .font(.system(size: 14))
                
                if coursesStore.activeSemesterIds.isEmpty {
                    Text("No Active Semester")
                } else if coursesStore.activeSemesterIds.count == 1,
                          let semester = coursesStore.activeSemesters.first {
                    Text(semester.name)
                } else {
                    Text("\(coursesStore.activeSemesterIds.count) Semesters")
                }
                
                Image(systemName: "chevron.down")
                    .font(.system(size: 10))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.accentColor.opacity(0.1), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
    }
}

// MARK: - Compact Version for Toolbar

struct CompactSemesterPicker: View {
    @EnvironmentObject private var coursesStore: CoursesStore
    
    var body: some View {
        Menu {
            ForEach(coursesStore.nonArchivedSemesters) { semester in
                Button {
                    coursesStore.toggleActiveSemester(semester)
                } label: {
                    HStack {
                        Text(semester.name)
                        if coursesStore.activeSemesterIds.contains(semester.id) {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            Label {
                if coursesStore.activeSemesterIds.count == 1,
                   let semester = coursesStore.activeSemesters.first {
                    Text(semester.name)
                } else if coursesStore.activeSemesterIds.count > 1 {
                    Text("\(coursesStore.activeSemesterIds.count) Active")
                } else {
                    Text("Select Semester")
                }
            } icon: {
                Image(systemName: "calendar")
            }
        }
    }
}

#Preview {
    SemesterPickerView()
        .environmentObject(CoursesStore())
        .padding()
}
