#if os(iOS)
    import SwiftUI

    struct SettingsRootView: View {
        @EnvironmentObject var settings: AppSettingsModel
        @Environment(\.dismiss) private var dismiss
        @Environment(\.layoutMetrics) private var layoutMetrics

        var body: some View {
            NavigationStack {
                List {
                    Section {
                        NavigationLink {
                            IOSSubscriptionView()
                        } label: {
                            Label {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(NSLocalizedString(
                                        "settings.itori.premium",
                                        value: "Subscriptions",
                                        comment: "Subscriptions"
                                    ))
                                    .font(.body.weight(.semibold))
                                    Text(NSLocalizedString(
                                        "settings.unlock.all.features",
                                        value: "Unlock all features",
                                        comment: "Unlock all features"
                                    ))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                }
                            } icon: {
                                Image(systemName: "creditcard")
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [.blue, .purple],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 28, height: 28)
                            }
                        }
                        .listRowInsets(EdgeInsets(
                            top: layoutMetrics.listRowVerticalPadding,
                            leading: 16,
                            bottom: layoutMetrics.listRowVerticalPadding,
                            trailing: 16
                        ))

                        ForEach(SettingsCategory.allCases) { category in
                            NavigationLink(destination: category.destinationView()) {
                                Label {
                                    Text(category.title)
                                } icon: {
                                    Image(systemName: category.systemImage)
                                        .foregroundColor(.accentColor)
                                        .frame(width: 28, height: 28)
                                }
                            }
                            .listRowInsets(EdgeInsets(
                                top: layoutMetrics.listRowVerticalPadding,
                                leading: 16,
                                bottom: layoutMetrics.listRowVerticalPadding,
                                trailing: 16
                            ))
                        }
                    }
                }
                .listStyle(.insetGrouped)
                .navigationTitle(NSLocalizedString("ios.settings.title", comment: "Settings"))
                .navigationBarTitleDisplayMode(.large)
                .background(Color(UIColor.systemGroupedBackground))
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            dismiss()
                        } label: {
                            Text(NSLocalizedString("common.done", comment: "Done"))
                                .fontWeight(.semibold)
                        }
                    }
                }
            }
        }
    }

    #if !DISABLE_PREVIEWS
        #Preview {
            SettingsRootView()
                .environmentObject(AppSettingsModel.shared)
        }
    #endif
#endif
