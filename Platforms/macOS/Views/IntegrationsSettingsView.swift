#if os(macOS)
    import SwiftUI
    import UserNotifications

    struct IntegrationsSettingsView: View {
        @EnvironmentObject var settings: AppSettingsModel
        @State private var notificationStatus: PermissionStatus = .notRequested
        @State private var iCloudStatus: Bool = false

        var body: some View {
            Form {
                Section {
                    Text(NSLocalizedString("settings.integrations", value: "Integrations", comment: "Integrations"))
                        .font(.title2)
                        .bold()
                        .padding(.bottom, 4)

                    Text(NSLocalizedString(
                        "settings.manage.app.capabilities.that.require",
                        value: "Manage app capabilities that require permissions or connect to external services.",
                        comment: "Manage app capabilities that require permissions o..."
                    ))
                    .foregroundStyle(.secondary)
                }
                .listRowBackground(Color.clear)

                // Notifications Integration
                Section {
                    IntegrationCard(
                        title: "Notifications",
                        icon: "bell.badge",
                        description: "Get alerts for timers, assignments, and important reminders",
                        status: notificationStatus,
                        isEnabled: Binding(
                            get: { settings.notificationsEnabled },
                            set: { settings.notificationsEnabled = $0
                                settings.save()
                            }
                        ),
                        onOpenSettings: {
                            openNotificationSettings()
                        }
                    )
                }

                // Developer Mode Integration
                Section {
                    IntegrationCard(
                        title: "Developer Mode",
                        icon: "hammer.fill",
                        description: "Enable detailed logging and diagnostics for troubleshooting",
                        status: settings.devModeEnabled ? .granted : .notRequested,
                        isEnabled: Binding(
                            get: { settings.devModeEnabled },
                            set: { settings.devModeEnabled = $0
                                settings.save()
                            }
                        ),
                        showOpenSettings: false
                    )
                }
            }
            .formStyle(.grouped)
            .navigationTitle("Integrations")
            .frame(minWidth: 500, maxWidth: 700)
            .onAppear {
                checkNotificationPermissions()
            }
        }

        private func checkNotificationPermissions() {
            UNUserNotificationCenter.current().getNotificationSettings { settings in
                DispatchQueue.main.async {
                    switch settings.authorizationStatus {
                    case .authorized, .provisional, .ephemeral:
                        notificationStatus = .granted
                    case .denied:
                        notificationStatus = .denied
                    case .notDetermined:
                        notificationStatus = .notRequested
                    @unknown default:
                        notificationStatus = .notRequested
                    }
                }
            }
        }

        private func openNotificationSettings() {
            if let url = URL(string: "x-apple.systempreferences:com.apple.preference.notifications") {
                NSWorkspace.shared.open(url)
            }
        }
    }

    // MARK: - Permission Status

    enum PermissionStatus {
        case notRequested
        case granted
        case denied
        case error

        var label: String {
            switch self {
            case .notRequested: "Not Requested"
            case .granted: "Granted"
            case .denied: "Denied"
            case .error: "Error"
            }
        }

        var color: Color {
            switch self {
            case .notRequested: .gray
            case .granted: .green
            case .denied: .red
            case .error: .orange
            }
        }

        var icon: String {
            switch self {
            case .notRequested: "circle"
            case .granted: "checkmark.circle.fill"
            case .denied: "xmark.circle.fill"
            case .error: "exclamationmark.triangle.fill"
            }
        }
    }

    // MARK: - Integration Card

    struct IntegrationCard: View {
        let title: String
        let icon: String
        let description: String
        let status: PermissionStatus
        @Binding var isEnabled: Bool
        var onOpenSettings: (() -> Void)?
        var showOpenSettings: Bool = true

        @EnvironmentObject var settings: AppSettingsModel

        var body: some View {
            VStack(alignment: .leading, spacing: 16) {
                // Header
                HStack(spacing: 12) {
                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundStyle(Color.accentColor)
                        .frame(width: 32, height: 32)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(title)
                            .font(.headline)

                        Text(description)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    // Status indicator
                    HStack(spacing: 6) {
                        Image(systemName: status.icon)
                            .foregroundStyle(status.color)
                            .font(.caption)

                        Text(status.label)
                            .font(.caption)
                            .foregroundStyle(status.color)
                    }
                }

                // Controls
                HStack(spacing: 12) {
                    // Toggle (if applicable)
                    if showOpenSettings || status != .denied {
                        Toggle(
                            NSLocalizedString("settings.toggle.enabled", value: "Enabled", comment: "Enabled"),
                            isOn: $isEnabled
                        )
                        .toggleStyle(.switch)
                        .disabled(status == .denied)
                    }

                    Spacer()

                    // Open Settings button (if denied and applicable)
                    if status == .denied && showOpenSettings, let openSettings = onOpenSettings {
                        Button {
                            openSettings()
                        } label: {
                            Label(
                                NSLocalizedString(
                                    "settings.label.open.system.settings",
                                    value: "Open System Settings",
                                    comment: "Open System Settings"
                                ),
                                systemImage: "gear"
                            )
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.accentColor)
                    }
                }

                // Guidance message for denied state
                if status == .denied && showOpenSettings {
                    HStack(spacing: 8) {
                        Image(systemName: "info.circle")
                            .foregroundStyle(.orange)

                        Text(NSLocalizedString(
                            "settings.permission.denied.please.enable.in",
                            value: "Permission denied. Please enable in System Settings to use this feature.",
                            comment: "Permission denied. Please enable in System Setting..."
                        ))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }
                    .padding(8)
                    .background(Color.orange.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(.regularMaterial)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(.separatorColor.opacity(0.2), lineWidth: 0.5)
            )
        }
    }

#endif
