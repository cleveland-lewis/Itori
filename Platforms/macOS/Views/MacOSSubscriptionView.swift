#if os(macOS)
import SwiftUI
import StoreKit

struct MacOSSubscriptionView: View {
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    @Environment(\.dismiss) private var dismiss
    
    @State private var isPurchasing = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showRestoreSuccess = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                headerSection
                
                statusBanner
                
                if !subscriptionManager.availableSubscriptions.isEmpty {
                    subscriptionPlans
                } else {
                    loadingPlaceholder
                }
                
                featuresSection
                
                restoreButton
            }
            .frame(maxWidth: 600)
            .padding(40)
        }
        .frame(minWidth: 700, minHeight: 600)
        .alert("Error", isPresented: $showError) {
            Button(NSLocalizedString("OK", value: "OK", comment: ""), role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
        .alert("Restored", isPresented: $showRestoreSuccess) {
            Button(NSLocalizedString("OK", value: "OK", comment: ""), role: .cancel) { }
        } message: {
            Text(NSLocalizedString("macossubscription.your.purchases.have.been.restored", value: "Your purchases have been restored.", comment: "Your purchases have been restored."))
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            Image(systemName: "sparkles")
                .font(.system(size: 60))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.blue, .purple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            Text(NSLocalizedString("macossubscription.unlock.premium", value: "Unlock Premium", comment: "Unlock Premium"))
                .font(.system(size: 32, weight: .bold))
            
            Text(NSLocalizedString("macossubscription.get.unlimited.access.to.all", value: "Get unlimited access to all features and priority support", comment: "Get unlimited access to all features and priority ..."))
                .font(.title3)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }
    
    @ViewBuilder
    private var statusBanner: some View {
        switch subscriptionManager.subscriptionStatus {
        case .subscribed(let expirationDate):
            VStack(spacing: 8) {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                    Text(NSLocalizedString("macossubscription.active.subscription", value: "Active Subscription", comment: "Active Subscription"))
                        .font(.headline)
                    Spacer()
                }
                
                if let expiration = expirationDate {
                    Text(String(format: NSLocalizedString("macos.subscription.renews_date", value: "Renews %@", comment: "Subscription renewal date"), expiration.formatted(date: .abbreviated, time: .omitted)))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.green.opacity(0.1))
            )
            
        case .expired:
            HStack {
                Image(systemName: "exclamationmark.circle.fill")
                    .foregroundStyle(.orange)
                Text(NSLocalizedString("macossubscription.subscription.expired", value: "Subscription Expired", comment: "Subscription Expired"))
                    .font(.headline)
                Spacer()
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.orange.opacity(0.1))
            )
            
        default:
            EmptyView()
        }
    }
    
    private var subscriptionPlans: some View {
        HStack(spacing: 16) {
            ForEach(subscriptionManager.availableSubscriptions, id: \.id) { product in
                MacSubscriptionPlanCard(
                    product: product,
                    isPurchasing: isPurchasing,
                    isCurrentPlan: subscriptionManager.purchasedSubscriptions.contains(where: { $0.id == product.id }),
                    onPurchase: {
                        Task {
                            await purchaseSubscription(product)
                        }
                    }
                )
            }
        }
    }
    
    private var loadingPlaceholder: some View {
        VStack(spacing: 16) {
            ProgressView()
                .controlSize(.large)
            Text(NSLocalizedString("macossubscription.loading.subscription.options", value: "Loading subscription options...", comment: "Loading subscription options..."))
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }
    
    private var featuresSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text(NSLocalizedString("macossubscription.premium.features", value: "Premium Features", comment: "Premium Features"))
                .font(.title2.bold())
            
            VStack(spacing: 16) {
                MacFeatureRow(icon: "brain.head.profile", title: "AI-Powered Study Plans", description: "Intelligent scheduling optimized for your learning patterns")
                MacFeatureRow(icon: "calendar.badge.clock", title: "Advanced Planning", description: "Auto-schedule assignments with smart conflict resolution")
                MacFeatureRow(icon: "chart.bar.fill", title: "Analytics & Insights", description: "Track your progress with detailed statistics and reports")
                MacFeatureRow(icon: "square.stack.3d.up", title: "Unlimited Storage", description: "Store all your assignments and study materials without limits")
                MacFeatureRow(icon: "person.badge.shield.checkmark", title: "Priority Support", description: "Get help faster with priority email and chat support")
            }
        }
    }
    
    private var restoreButton: some View {
        Button(NSLocalizedString("macossubscription.button.restore.purchases", value: "Restore Purchases", comment: "Restore Purchases")) {
            Task {
                await restorePurchases()
            }
        }
        .buttonStyle(.link)
    }
    
    // MARK: - Actions
    
    private func purchaseSubscription(_ product: Product) async {
        isPurchasing = true
        
        do {
            let transaction = try await subscriptionManager.purchase(product)
            
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
}

// MARK: - Mac Subscription Plan Card

private struct MacSubscriptionPlanCard: View {
    let product: Product
    let isPurchasing: Bool
    let isCurrentPlan: Bool
    let onPurchase: () -> Void
    
    private var isYearly: Bool {
        product.id.contains("yearly")
    }
    
    private var savingsText: String? {
        guard isYearly else { return nil }
        return "Save 20%"
    }
    
    var body: some View {
        VStack(spacing: 20) {
            VStack(spacing: 8) {
                if let savings = savingsText {
                    Text(savings)
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(Color.green)
                        .clipShape(Capsule())
                }
                
                Text(product.displayName)
                    .font(.title2.bold())
                
                Text(product.displayPrice)
                    .font(.system(size: 36, weight: .bold))
                
                Text(subscriptionPeriod)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            Divider()
            
            if isCurrentPlan {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                    Text(NSLocalizedString("macossubscription.current.plan", value: "Current Plan", comment: "Current Plan"))
                        .font(.headline)
                        .foregroundStyle(.green)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            } else {
                Button {
                    onPurchase()
                } label: {
                    Group {
                        if isPurchasing {
                            ProgressView()
                                .controlSize(.small)
                                .tint(.white)
                        } else {
                            Text(NSLocalizedString("macossubscription.subscribe", value: "Subscribe", comment: "Subscribe"))
                                .font(.headline)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(isPurchasing)
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(nsColor: .controlBackgroundColor))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(isYearly ? Color.accentColor : Color.clear, lineWidth: 2)
                )
        )
    }
    
    private var subscriptionPeriod: String {
        if let subscription = product.subscription {
            switch subscription.subscriptionPeriod.unit {
            case .month:
                return "per month"
            case .year:
                return "per year"
            default:
                return ""
            }
        }
        return ""
    }
}

// MARK: - Mac Feature Row

private struct MacFeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title)
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
    MacOSSubscriptionView()
}
#endif
