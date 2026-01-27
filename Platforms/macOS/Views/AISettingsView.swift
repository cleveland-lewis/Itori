#if os(macOS)
    import SwiftUI

    struct AISettingsView: View {
        var body: some View {
            VStack(spacing: 32) {
                // Coming Soon Icon
                VStack(spacing: 16) {
                    Image(systemName: "sparkles.rectangle.stack.fill")
                        .font(.system(size: 64))
                        .foregroundStyle(.blue.gradient)

                    Text(NSLocalizedString(
                        "settings.ai.coming.soon.title",
                        value: "AI Features Coming Soon",
                        comment: "AI features coming soon title"
                    ))
                    .font(.title.weight(.semibold))

                    Text(NSLocalizedString(
                        "settings.ai.coming.soon.subtitle",
                        value: "Advanced AI capabilities will be available in a future update",
                        comment: "AI features coming soon subtitle"
                    ))
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                }
                .padding(.top, 60)

                Spacer()

                // Future Features List
                VStack(alignment: .leading, spacing: 20) {
                    Text(NSLocalizedString(
                        "settings.ai.planned.features",
                        value: "Planned Features",
                        comment: "Planned AI features title"
                    ))
                    .font(.headline)

                    VStack(alignment: .leading, spacing: 16) {
                        FeatureRow(
                            icon: "doc.text.magnifyingglass",
                            title: "AI Practice Test Generation",
                            description: "Generate custom practice tests from your study materials"
                        )

                        FeatureRow(
                            icon: "brain.head.profile",
                            title: "Smart Study Recommendations",
                            description: "Get personalized study suggestions based on your progress"
                        )

                        FeatureRow(
                            icon: "text.badge.checkmark",
                            title: "Automated Grading & Feedback",
                            description: "Instant feedback on practice tests with detailed explanations"
                        )

                        FeatureRow(
                            icon: "chart.line.uptrend.xyaxis",
                            title: "Performance Analytics",
                            description: "AI-powered insights into your learning patterns"
                        )
                    }
                }
                .padding(24)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(nsColor: .controlBackgroundColor))
                )

                Spacer()

                // Info note
                Text(NSLocalizedString(
                    "settings.ai.subscription.note",
                    value: "AI features will be available as an optional subscription when released",
                    comment: "AI subscription note"
                ))
                .font(.caption)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
            }
            .frame(maxWidth: 600)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(40)
        }
    }

    private struct FeatureRow: View {
        let icon: String
        let title: String
        let description: String

        var body: some View {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(.blue)
                    .frame(width: 32)

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.body.weight(.medium))

                    Text(description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }
        }
    }

    #if !DISABLE_PREVIEWS
        #Preview {
            AISettingsView()
                .frame(width: 700, height: 800)
        }
    #endif

#endif
