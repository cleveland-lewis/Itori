#if os(iOS)
import SwiftUI

struct SettingsRootView: View {
    @EnvironmentObject var settings: AppSettingsModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.layoutMetrics) private var layoutMetrics
    
    var body: some View {
        NavigationStack {
            List {
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
            .listStyle(.insetGrouped)
            .navigationTitle(NSLocalizedString("ios.settings.title", comment: "Settings"))
            .navigationBarTitleDisplayMode(.large)
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
