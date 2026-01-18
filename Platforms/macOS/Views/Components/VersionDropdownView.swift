#if os(macOS)
    import SwiftUI

    /// Version information dropdown shown in Dashboard footer
    struct VersionDropdownView: View {
        @State private var isExpanded = false
        @State private var isCheckingForUpdates = false
        @State private var updateCheckResult: UpdateCheckResult?

        private let appVersion: String = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"

        private let buildNumber: String = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"

        var body: some View {
            VStack(spacing: 0) {
                // Collapsed version button
                Button(action: { withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { isExpanded.toggle() }
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "info.circle")
                            .font(.caption)
                        Text(verbatim: "Itori v\(appVersion)")
                            .font(.caption)
                            .monospacedDigit()
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.caption2)
                    }
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(Color(nsColor: .controlBackgroundColor).opacity(0.5))
                    )
                }
                .buttonStyle(.plain)

                // Expanded details
                if isExpanded {
                    VStack(alignment: .leading, spacing: 12) {
                        Divider()
                            .padding(.vertical, 8)

                        // Version info
                        VStack(alignment: .leading, spacing: 6) {
                            InfoRow(label: "Version", value: appVersion)
                            InfoRow(label: "Build", value: buildNumber)

                            if let result = updateCheckResult {
                                switch result {
                                case .upToDate:
                                    HStack(spacing: 6) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundStyle(.green)
                                        Text(NSLocalizedString(
                                            "versiondropdown.up.to.date",
                                            value: "Up to date",
                                            comment: "Up to date"
                                        ))
                                        .font(.caption)
                                    }
                                case let .updateAvailable(version):
                                    HStack(spacing: 6) {
                                        Image(systemName: "arrow.down.circle.fill")
                                            .foregroundStyle(.blue)
                                        Text(verbatim: "Update available: v\(version)")
                                            .font(.caption)
                                    }
                                case let .error(message):
                                    HStack(spacing: 6) {
                                        Image(systemName: "exclamationmark.triangle.fill")
                                            .foregroundStyle(.orange)
                                        Text(message)
                                            .font(.caption)
                                    }
                                }
                            }
                        }

                        // Action buttons
                        HStack(spacing: 8) {
                            Button(action: checkForUpdates) {
                                HStack(spacing: 4) {
                                    if isCheckingForUpdates {
                                        ProgressView()
                                            .scaleEffect(0.6)
                                            .frame(width: 12, height: 12)
                                    } else {
                                        Image(systemName: "arrow.clockwise")
                                            .font(.caption)
                                    }
                                    Text(NSLocalizedString(
                                        "versiondropdown.check.for.updates",
                                        value: "Check for Updates",
                                        comment: "Check for Updates"
                                    ))
                                    .font(.caption)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 6)
                            }
                            .buttonStyle(.itoriLiquidProminent)
                            .disabled(isCheckingForUpdates)

                            Button(action: openReleaseNotes) {
                                HStack(spacing: 4) {
                                    Image(systemName: "doc.text")
                                        .font(.caption)
                                    Text(NSLocalizedString(
                                        "versiondropdown.release.notes",
                                        value: "Release Notes",
                                        comment: "Release Notes"
                                    ))
                                    .font(.caption)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 6)
                            }
                            .buttonStyle(.itariLiquid)
                        }

                        // Additional info
                        Text(NSLocalizedString(
                            "versiondropdown.2026.itori.all.rights.reserved",
                            value: "© 2026 Itori. All rights reserved.",
                            comment: "© 2026 Itori. All rights reserved."
                        ))
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                        .frame(maxWidth: .infinity, alignment: .center)
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(DesignSystem.Materials.card)
                            .shadow(color: .black.opacity(0.1), radius: 8, y: 4)
                    )
                    .padding(.top, 8)
                    .transition(.opacity.combined(with: .move(edge: .top).combined(with: .scale(
                        scale: 0.95,
                        anchor: .top
                    ))))
                }
            }
            .frame(maxWidth: 300)
            .padding(.bottom, 16)
        }

        private func checkForUpdates() {
            isCheckingForUpdates = true
            updateCheckResult = nil

            // Simulate update check (replace with actual implementation)
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                isCheckingForUpdates = false
                // For now, always say up to date. Real implementation would check GitHub releases or update server
                updateCheckResult = .upToDate
            }
        }

        private func openReleaseNotes() {
            if let url = URL(string: "https://github.com/yourusername/Itori/releases") {
                NSWorkspace.shared.open(url)
            }
        }
    }

    private struct InfoRow: View {
        let label: String
        let value: String

        var body: some View {
            HStack {
                Text(label)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(value)
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.primary)
            }
        }
    }

    private enum UpdateCheckResult {
        case upToDate
        case updateAvailable(version: String)
        case error(message: String)
    }

#endif
