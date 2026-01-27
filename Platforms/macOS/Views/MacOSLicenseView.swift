#if os(macOS)
    import AppKit
    import StoreKit
    import SwiftUI

    struct MacOSLicenseView: View {
        @ScaledMetric private var emptyIconSize: CGFloat = 48
        @ScaledMetric private var mediumTextSize: CGFloat = 16
        @ScaledMetric private var heroIconSize: CGFloat = 60
        @ScaledMetric private var heroTitleSize: CGFloat = 32
        @ScaledMetric private var pricingSize: CGFloat = 36

        @StateObject private var subscriptionManager = SubscriptionManager.shared
        @Environment(\.dismiss) private var dismiss

        @State private var isPurchasing = false
        @State private var showError = false
        @State private var errorMessage = ""
        @State private var showRestoreSuccess = false
        @State private var isTrialActive = false
        @State private var trialEndDate: Date?

        var body: some View {
            VStack(spacing: 32) {
                headerSection

                statusBanner

                if !subscriptionManager.hasLifetimeLicense {
                    trialInfoSection
                    
                    lifetimePurchaseCard
                }

                featuresSection

                restoreButton
            }
            .frame(maxWidth: 600)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(nsColor: .windowBackgroundColor))
            .task {
                await subscriptionManager.loadProducts()
                await subscriptionManager.updateSubscriptionStatus()
                checkTrialStatus()
            }
            .alert("Error", isPresented: $showError) {
                Button(NSLocalizedString("OK", value: "OK", comment: ""), role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
            .alert("Restored", isPresented: $showRestoreSuccess) {
                Button(NSLocalizedString("OK", value: "OK", comment: ""), role: .cancel) {}
            } message: {
                Text(NSLocalizedString(
                    "macoslicense.purchases.restored",
                    value: "Your purchase has been restored.",
                    comment: "Your purchase has been restored."
                ))
            }
        }

        private var headerSection: some View {
            VStack(spacing: 16) {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: heroIconSize))
                    .foregroundStyle(.green)
                
                Text(NSLocalizedString(
                    "macoslicense.unlock.full.access",
                    value: "Unlock Full Access",
                    comment: "Unlock Full Access"
                ))
                .font(.system(size: heroTitleSize, weight: .bold))

                Text(NSLocalizedString(
                    "macoslicense.one.time.purchase",
                    value: "One-time purchase • Lifetime access • Free 7-day trial",
                    comment: "One-time purchase • Lifetime access • Free 7-day trial"
                ))
                .font(.title3)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            }
        }

        @ViewBuilder
        private var statusBanner: some View {
            if subscriptionManager.hasLifetimeLicense {
                VStack(spacing: 8) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                        Text(NSLocalizedString(
                            "macoslicense.active.license",
                            value: "Active License",
                            comment: "Active License"
                        ))
                        .font(.headline)
                        Spacer()
                    }

                    Text(NSLocalizedString(
                        "macoslicense.lifetime.access",
                        value: "You have lifetime access to all features",
                        comment: "You have lifetime access to all features"
                    ))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.green.opacity(0.1))
                )
            } else if isTrialActive, let endDate = trialEndDate {
                VStack(spacing: 8) {
                    HStack {
                        Image(systemName: "clock.badge.checkmark.fill")
                            .foregroundStyle(.blue)
                        Text(NSLocalizedString(
                            "macoslicense.trial.active",
                            value: "Free Trial Active",
                            comment: "Free Trial Active"
                        ))
                        .font(.headline)
                        Spacer()
                    }

                    Text(String(
                        format: NSLocalizedString(
                            "macoslicense.trial.ends",
                            value: "Trial ends %@",
                            comment: "Trial ends date"
                        ),
                        endDate.formatted(date: .abbreviated, time: .omitted)
                    ))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.blue.opacity(0.1))
                )
            } else {
                HStack {
                    Image(systemName: "lock.fill")
                        .foregroundStyle(.secondary)
                    Text(NSLocalizedString(
                        "macoslicense.no.active.license",
                        value: "No active license",
                        comment: "No active license"
                    ))
                    .font(.headline)
                    Spacer()
                }
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color(nsColor: .controlBackgroundColor))
                )
            }
        }

        private var trialInfoSection: some View {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "gift.fill")
                        .foregroundStyle(.purple)
                    Text(NSLocalizedString(
                        "macoslicense.free.trial",
                        value: "Free 7-Day Trial",
                        comment: "Free 7-Day Trial"
                    ))
                    .font(.headline)
                }
                
                Text(NSLocalizedString(
                    "macoslicense.trial.description",
                    value: "Try all features free for 7 days. No payment required until trial ends. Cancel anytime.",
                    comment: "Trial description"
                ))
                .font(.subheadline)
                .foregroundStyle(.secondary)
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.purple.opacity(0.1))
            )
        }

        private var lifetimePurchaseCard: some View {
            VStack(spacing: 24) {
                VStack(spacing: 12) {
                    Text(NSLocalizedString(
                        "macoslicense.lifetime.license",
                        value: "Lifetime License",
                        comment: "Lifetime License"
                    ))
                    .font(.title2.bold())

                    Text("$9.99")
                        .font(.system(size: 56, weight: .bold))
                        .foregroundStyle(.green)

                    Text(NSLocalizedString(
                        "macoslicense.one.time.payment",
                        value: "one-time payment",
                        comment: "one-time payment"
                    ))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                }

                Divider()

                Button {
                    Task {
                        await purchaseLifetimeLicense()
                    }
                } label: {
                    Group {
                        if isPurchasing {
                            ProgressView()
                                .controlSize(.small)
                                .tint(.white)
                        } else {
                            HStack(spacing: 8) {
                                Image(systemName: "cart.fill")
                                Text(isTrialActive ? 
                                    NSLocalizedString(
                                        "macoslicense.continue.trial",
                                        value: "Continue with Trial",
                                        comment: "Continue with Trial"
                                    ) :
                                    NSLocalizedString(
                                        "macoslicense.start.trial",
                                        value: "Start Free Trial",
                                        comment: "Start Free Trial"
                                    )
                                )
                                .font(.headline)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                }
                .buttonStyle(.itoriLiquidProminent)
                .controlSize(.large)
                .disabled(isPurchasing)
                
                Text(NSLocalizedString(
                    "macoslicense.no.subscription",
                    value: "No subscription. Pay once, yours forever.",
                    comment: "No subscription disclaimer"
                ))
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            .padding(32)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color(nsColor: .controlBackgroundColor))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(Color.green, lineWidth: 2)
                    )
            )
        }

        private var featuresSection: some View {
            VStack(alignment: .leading, spacing: 20) {
                Text(NSLocalizedString(
                    "macoslicense.whats.included",
                    value: "What's Included",
                    comment: "What's Included"
                ))
                .font(.title2.bold())

                VStack(spacing: 16) {
                    MacLicenseFeatureRow(
                        icon: "calendar.badge.plus",
                        title: "Smart Course Management",
                        description: "Organize courses, semesters, and track your academic progress"
                    )
                    MacLicenseFeatureRow(
                        icon: "doc.text.fill",
                        title: "Assignment Tracking",
                        description: "Never miss a deadline with intelligent reminders and scheduling"
                    )
                    MacLicenseFeatureRow(
                        icon: "brain.head.profile",
                        title: "Automatic Planning",
                        description: "Auto-schedule study sessions based on your energy levels"
                    )
                    MacLicenseFeatureRow(
                        icon: "chart.line.uptrend.xyaxis",
                        title: "Grade Analytics",
                        description: "Track grades, calculate GPA, and monitor academic performance"
                    )
                    MacLicenseFeatureRow(
                        icon: "timer",
                        title: "Focus Timer",
                        description: "Pomodoro timer with break scheduling for optimal productivity"
                    )
                    MacLicenseFeatureRow(
                        icon: "icloud.fill",
                        title: "Cross-Platform Sync",
                        description: "Seamlessly sync across macOS, iOS, and Apple Watch"
                    )
                    MacLicenseFeatureRow(
                        icon: "calendar",
                        title: "Calendar Integration",
                        description: "Sync with Apple Calendar for a unified schedule"
                    )
                    MacLicenseFeatureRow(
                        icon: "arrow.clockwise",
                        title: "Recurring Tasks",
                        description: "Handle repeating assignments with smart recurrence rules"
                    )
                }
            }
        }

        private var restoreButton: some View {
            Button(NSLocalizedString(
                "macoslicense.restore.purchase",
                value: "Restore Purchase",
                comment: "Restore Purchase"
            )) {
                Task {
                    await restorePurchases()
                }
            }
            .buttonStyle(.link)
        }

        // MARK: - Actions

        private func purchaseLifetimeLicense() async {
            isPurchasing = true

            // TODO: Implement actual purchase flow with StoreKit
            // For now, simulate purchase
            do {
                // Find lifetime product
                guard let lifetimeProduct = subscriptionManager.availableSubscriptions
                    .first(where: { $0.subscription == nil }) else {
                    errorMessage = "Lifetime license not available. Please try again."
                    showError = true
                    isPurchasing = false
                    return
                }
                
                let transaction = try await subscriptionManager.purchase(lifetimeProduct)

                if transaction != nil {
                    showRestoreSuccess = true
                }
            } catch {
                errorMessage = "Failed to complete purchase. Please try again."
                showError = true
            }

            isPurchasing = false
        }

        private func restorePurchases() async {
            do {
                try await subscriptionManager.restorePurchases()
                showRestoreSuccess = true
            } catch {
                errorMessage = "Failed to restore purchases. Please try again."
                showError = true
            }
        }
        
        private func checkTrialStatus() {
            // Check if trial is active
            let trialKey = "itori.trial.startDate"
            if let trialStart = UserDefaults.standard.object(forKey: trialKey) as? Date {
                let trialEnd = Calendar.current.date(byAdding: .day, value: 7, to: trialStart) ?? trialStart
                isTrialActive = Date() < trialEnd
                trialEndDate = trialEnd
            } else {
                // Start trial on first launch
                let now = Date()
                UserDefaults.standard.set(now, forKey: trialKey)
                trialEndDate = Calendar.current.date(byAdding: .day, value: 7, to: now)
                isTrialActive = true
            }
        }
    }

    // MARK: - Mac License Feature Row

    private struct MacLicenseFeatureRow: View {
        let icon: String
        let title: String
        let description: String

        var body: some View {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(Color.accentColor)
                    .frame(width: 40, height: 40)

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                    Text(description)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }
        }
    }

    #Preview {
        MacOSLicenseView()
    }
#endif
