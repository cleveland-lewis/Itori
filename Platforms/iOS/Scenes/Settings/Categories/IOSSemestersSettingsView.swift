import SwiftUI

#if os(iOS)

    struct IOSSemestersSettingsView: View {
        @EnvironmentObject var coursesStore: CoursesStore

        var body: some View {
            List {
                Section {
                    if coursesStore.nonArchivedSemesters.isEmpty {
                        Text(NSLocalizedString(
                            "settings.semesters.empty",
                            value: "No semesters yet. Add one to get started.",
                            comment: "No semesters empty state"
                        ))
                        .foregroundColor(.secondary)
                    } else {
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
                                            .foregroundColor(.accentColor)
                                    }
                                }
                            }
                            .disabled(!canToggleSemester(isActive: isActive))
                        }
                    }
                } header: {
                    Text(NSLocalizedString(
                        "settings.semesters.active.header",
                        value: "Active Semesters",
                        comment: "Active semesters header"
                    ))
                } footer: {
                    Text(NSLocalizedString(
                        "settings.semesters.active.footer",
                        value: "Select one or more semesters. At least one semester must stay active.",
                        comment: "Active semesters footer"
                    ))
                }

                if !coursesStore.nonArchivedSemesters.isEmpty {
                    Section {
                        Button(NSLocalizedString(
                            "settings.semesters.select_all",
                            value: "Select All",
                            comment: "Select all semesters"
                        )) {
                            let allIds = Set(coursesStore.nonArchivedSemesters.map(\.id))
                            coursesStore.setActiveSemesters(allIds)
                        }
                        Button(NSLocalizedString(
                            "settings.semesters.clear_all",
                            value: "Clear All",
                            comment: "Clear all semesters"
                        )) {
                            coursesStore.setActiveSemesters([])
                        }
                        .disabled(!canClearAll)
                    }
                }

                Section {
                    HStack {
                        Text(NSLocalizedString(
                            "settings.semesters.summary.active",
                            value: "Active Summary",
                            comment: "Active summary label"
                        ))
                        Spacer()
                        Text(summaryText)
                            .foregroundColor(.secondary)
                    }
                    HStack {
                        Text(NSLocalizedString(
                            "settings.semesters.summary.current",
                            value: "Current Semester",
                            comment: "Current semester label"
                        ))
                        Spacer()
                        Text(coursesStore.currentSemester?.name ?? "None")
                            .foregroundColor(.secondary)
                    }
                } header: {
                    Text(NSLocalizedString(
                        "settings.semesters.summary.header",
                        value: "Summary",
                        comment: "Summary header"
                    ))
                }
            }
            .listStyle(.insetGrouped)
            .background(Color(UIColor.systemGroupedBackground))
            .navigationTitle(NSLocalizedString(
                "settings.category.active_semesters",
                value: "Active Semesters",
                comment: "Active Semesters"
            ))
            .navigationBarTitleDisplayMode(.inline)
        }

        private var summaryText: String {
            let count = coursesStore.activeSemesterIds.count
            if count == 0 {
                return NSLocalizedString("common.none", value: "None", comment: "None")
            }
            let ordered = coursesStore.activeSemesters.sorted { $0.startDate < $1.startDate }
            if count == 1, let first = ordered.first {
                return first.name
            }
            if count == 2, let first = ordered.first {
                return "\(first.name) + 1"
            }
            return String(
                format: NSLocalizedString(
                    "settings.semesters.summary.count",
                    value: "%d Active",
                    comment: "Active semesters count"
                ),
                count
            )
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

    #if !DISABLE_PREVIEWS
        #Preview {
            NavigationStack {
                IOSSemestersSettingsView()
                    .environmentObject(CoursesStore.shared ?? CoursesStore())
            }
        }
    #endif
#endif
