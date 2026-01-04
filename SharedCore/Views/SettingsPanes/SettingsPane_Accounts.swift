import SwiftUI
#if os(macOS)
import AppKit
#endif

struct SettingsPane_Accounts: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Account management will arrive in a future update.")
                .rootsSectionHeader()

            Text("Keep your profile, backups, and school-wide settings in their respective sections. Itori will link here when account syncing is available.")
                .rootsBodySecondary()

            Button("Open System Settings…", action: openSystemSettings)
                .controlSize(.regular)
        }
        .padding(.top, 4)
        .frame(maxWidth: 640, alignment: .leading)
    }

    private func openSystemSettings() {
        guard let url = URL(string: "x-apple.systempreferences:") else { return }
        #if os(macOS)
        NSWorkspace.shared.open(url)
        #else
        UIApplication.shared.open(url)
        #endif
    }
}
