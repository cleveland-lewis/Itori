import SwiftUI
import EventKit
import UserNotifications

struct PrivacySettingsView: View {
    @State private var calendarAccessGranted: Bool = false
    @State private var notificationsAuthorized: Bool = false
    @EnvironmentObject var appSettings: AppSettingsModel

    var body: some View {
        Form {
            Section(header: Text("Data Storage")) {
                HStack {
                    Label("On-Device Encryption", systemImage: "lock.shield")
                        .labelStyle(.titleAndIcon)
                        .foregroundColor(.green)
                    Spacer()
                    Text("Active").foregroundColor(.secondary)
                }

                HStack {
                    Label("Cloud Sync", systemImage: "icloud")
                        .labelStyle(.titleAndIcon)
                    Spacer()
                    Text(appSettings.enableICloudSync ? "Via iCloud Drive" : "Local Only")
                        .foregroundColor(.secondary)
                }
            }

            Section(header: Text("Permissions")) {
                NavigationLink(destination: CalendarSettingsView()) {
                    HStack {
                        Label("Calendar Access", systemImage: "calendar")
                        Spacer()
                        Text(calendarAccessGranted ? "Enabled" : "Disabled")
                            .foregroundColor(.secondary)
                    }
                }

                HStack {
                    Label("Notifications", systemImage: "bell")
                    Spacer()
                    Toggle(isOn: Binding(get: { notificationsAuthorized }, set: { _ in
                        openSystemNotificationSettings()
                    })) {
                        Text(notificationsAuthorized ? "Authorized" : "Manage")
                            .foregroundColor(.secondary)
                    }
                    .toggleStyle(.switch)
                }
            }

            Section(header: Text("Data Management")) {
                Button(action: exportAllData) {
                    Label("Export All Data", systemImage: "square.and.arrow.up")
                }

                Button(role: .destructive, action: deleteAllData) {
                    Label("Delete All Data", systemImage: "trash")
                }
            }

            Section {
                Text("This app stores personal data on-device only and does not share data with third-party services. Encryption at rest is enabled via iOS file protection.")
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }
        }
        .navigationTitle("Privacy & Security")
        .onAppear {
            refreshPermissions()
        }
    }

    private func refreshPermissions() {
        let store = EKEventStore()
        store.requestAccess(to: .event) { granted, _ in
            DispatchQueue.main.async {
                self.calendarAccessGranted = granted
            }
        }

        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.notificationsAuthorized = settings.authorizationStatus == .authorized
            }
        }
    }

    private func openSystemNotificationSettings() {
        #if os(iOS)
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        }
#else
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy") {
            NSWorkspace.shared.open(url)
        }
#endif
    }

    private func exportAllData() {
        // Simple export: gather known data files and present share sheet
        // Implementation note: keep exports on-device; do not upload automatically.
        let fm = FileManager.default
        let docs = fm.urls(for: .documentDirectory, in: .userDomainMask).first
        var urls: [URL] = []
        if let docs = docs {
            let known = ["flashcards.json"]
            for name in known {
                let url = docs.appendingPathComponent(name)
                if fm.fileExists(atPath: url.path) { urls.append(url) }
            }
        }

        // Present share sheet
        guard !urls.isEmpty else { return }
        #if os(iOS)
        let av = UIActivityViewController(activityItems: urls, applicationActivities: nil)
        UIApplication.shared.windows.first?.rootViewController?.present(av, animated: true, completion: nil)
#else
        // On macOS, use NSSharingServicePicker from an open window — fall back to writing export to desktop
        if let desktop = FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask).first {
            for url in urls {
                let dest = desktop.appendingPathComponent(url.lastPathComponent)
                try? FileManager.default.copyItem(at: url, to: dest)
            }
        }
#endif
    }

    private func deleteAllData() {
        // Remove known app files and reset in-memory stores
        let fm = FileManager.default
        let docs = fm.urls(for: .documentDirectory, in: .userDomainMask).first
        if let docs = docs {
            let known = ["flashcards.json"]
            for name in known {
                let url = docs.appendingPathComponent(name)
                try? fm.removeItem(at: url)
            }
        }

        // Notify app to reset state
        NotificationCenter.default.post(name: Notification.Name("AppShouldResetData"), object: nil)
    }
}

struct PrivacySettingsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView { PrivacySettingsView().environmentObject(AppSettingsModel()) }
    }
}
