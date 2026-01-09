#if os(macOS)
    import SwiftUI

    struct RecentlyDeletedSemestersView: View {
        @EnvironmentObject var coursesStore: CoursesStore

        var body: some View {
            List {
                if coursesStore.recentlyDeletedSemesters.isEmpty {
                    HStack {
                        Spacer()
                        VStack(spacing: DesignSystem.Layout.spacing.small) {
                            Image(systemName: "tray.full")
                                .font(DesignSystem.Typography.body)
                                .foregroundStyle(.tertiary)
                            Text(NSLocalizedString(
                                "recentlydeletedsemesters.no.recently.deleted.semesters",
                                value: "No recently deleted semesters.",
                                comment: "No recently deleted semesters."
                            ))
                            .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 24)
                        Spacer()
                    }
                } else {
                    ForEach(coursesStore.recentlyDeletedSemesters) { semester in
                        VStack(alignment: .leading, spacing: 6) {
                            Text(semester.name)
                                .font(DesignSystem.Typography.subHeader)
                            Text(
                                verbatim: "\(semester.startDate.formatted(date: .abbreviated, time: .omitted)) – \(semester.endDate.formatted(date: .abbreviated, time: .omitted))"
                            )
                            .font(DesignSystem.Typography.caption)
                            .foregroundStyle(.secondary)

                            HStack(spacing: 12) {
                                Button(NSLocalizedString(
                                    "recentlydeletedsemesters.button.recover",
                                    value: "Recover",
                                    comment: "Recover"
                                )) {
                                    coursesStore.recoverSemester(semester.id)
                                }
                                .buttonStyle(.borderedProminent)

                                Button(
                                    NSLocalizedString("Delete Immediately", value: "Delete Immediately", comment: ""),
                                    role: .destructive
                                ) {
                                    coursesStore.permanentlyDeleteSemester(semester.id)
                                }
                                .buttonStyle(.bordered)
                            }
                        }
                        .padding(.vertical, 6)
                    }
                }
            }
            .navigationTitle("Recently Deleted")
        }
    }

    #if !DISABLE_PREVIEWS
        #if !DISABLE_PREVIEWS
            #Preview {
                RecentlyDeletedSemestersView()
                    .environmentObject(CoursesStore())
            }
        #endif
    #endif
#endif
