#if os(macOS)
import SwiftUI

struct PrivacySettingsView: View {
    @EnvironmentObject var settings: AppSettingsModel
    @State private var showingAIDisabledAlert = false
    
    var body: some View {
        Form {
            Section {
                Text("Privacy & Security")
                    .font(.title2)
                    .bold()
                    .padding(.bottom, 4)
                
                Text("Control how Roots uses your data and manages privacy-sensitive features.")
                    .foregroundStyle(.secondary)
            }
            .listRowBackground(Color.clear)
            
            Section("AI Features") {
                Toggle("Enable AI Features", isOn: Binding(
                    get: { settings.aiEnabled },
                    set: { newValue in
                        if !newValue {
                            showingAIDisabledAlert = true
                        } else {
                            settings.aiEnabled = newValue
                            settings.save()
                            LOG_SETTINGS(.info, "AIPrivacy", "AI features enabled")
                        }
                    }
                ))
                
                if settings.aiEnabled {
                    Text("AI features are enabled. Roots can use Apple Intelligence, local models, or custom providers based on your AI settings.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    Label {
                        Text("All AI features are disabled. No AI providers will be used.")
                    } icon: {
                        Image(systemName: "lock.shield.fill")
                            .foregroundStyle(.green)
                    }
                    .font(.caption)
                }
            }
            
            Section("What This Controls") {
                VStack(alignment: .leading, spacing: 12) {
                    PrivacyFeatureRow(
                        icon: "brain.head.profile",
                        title: "AI Providers",
                        description: "Apple Intelligence, local models, and custom providers",
                        isEnabled: settings.aiEnabled
                    )
                    
                    PrivacyFeatureRow(
                        icon: "wand.and.stars",
                        title: "Smart Suggestions",
                        description: "AI-powered scheduling, summaries, and recommendations",
                        isEnabled: settings.aiEnabled
                    )
                    
                    PrivacyFeatureRow(
                        icon: "doc.text.magnifyingglass",
                        title: "Content Analysis",
                        description: "Syllabus parsing, question generation, and text analysis",
                        isEnabled: settings.aiEnabled
                    )
                    
                    PrivacyFeatureRow(
                        icon: "calendar.badge.clock",
                        title: "AI Scheduling",
                        description: "Intelligent task scheduling and time optimization",
                        isEnabled: settings.aiEnabled
                    )
                }
            }
            
            Section("Privacy Guarantees") {
                VStack(alignment: .leading, spacing: 8) {
                    Label("No AI processing when disabled", systemImage: "checkmark.shield")
                        .font(.caption)
                    Label("No network calls to AI providers", systemImage: "checkmark.shield")
                        .font(.caption)
                    Label("No local model inference", systemImage: "checkmark.shield")
                        .font(.caption)
                    Label("All AI features gracefully disabled", systemImage: "checkmark.shield")
                        .font(.caption)
                }
                .foregroundStyle(.secondary)
            }
            
            Section("Data Storage") {
                Toggle("Enable iCloud Sync", isOn: $settings.enableICloudSync)
                    .onChange(of: settings.enableICloudSync) { _, _ in
                        settings.save()
                    }
                
                Text("When enabled, your courses, assignments, and settings sync across your devices via iCloud.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Privacy")
        .frame(minWidth: 500, maxWidth: 700)
        .alert("Disable AI Features?", isPresented: $showingAIDisabledAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Disable", role: .destructive) {
                settings.aiEnabled = false
                settings.save()
                LOG_SETTINGS(.warn, "AIPrivacy", "AI features disabled by user")
            }
        } message: {
            Text("This will disable all AI-powered features including Apple Intelligence, local models, and custom providers. Smart suggestions, content analysis, and AI scheduling will not be available.\n\nYou can re-enable AI features at any time.")
        }
    }
}

// MARK: - Privacy Feature Row

private struct PrivacyFeatureRow: View {
    let icon: String
    let title: String
    let description: String
    let isEnabled: Bool
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(isEnabled ? .blue : .secondary)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(title)
                        .font(.body)
                    Spacer()
                    Image(systemName: isEnabled ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundStyle(isEnabled ? .green : .red)
                        .font(.caption)
                }
                
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(nsColor: .controlBackgroundColor))
        )
    }
}

#endif
