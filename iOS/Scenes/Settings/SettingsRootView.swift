#if os(iOS)
import SwiftUI

struct SettingsRootView: View {
    @EnvironmentObject var settings: AppSettingsModel
    @Environment(\.dismiss) private var dismiss
    
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

#Preview {
    SettingsRootView()
        .environmentObject(AppSettingsModel.shared)
}
#endif
