#if os(iOS)
import SwiftUI
import StoreKit

struct IOSSubscriptionView: View {
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    @Environment(\.dismiss) private var dismiss
    
    @State private var isPurchasing = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showRestoreSuccess = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
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
                .padding(20)
            }
            .background(DesignSystem.Colors.appBackground)
            .navigationTitle("Itori Premium")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(NSLocalizedString("iossubscription.button.done", value: "Done", comment: "Done")) {
                        dismiss()
                    }
                }
            }
            .alert("Error", isPresented: $showError) {
                Button(NSLocalizedString("OK", value: "OK", comment: ""), role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
            .alert("Restored", isPresented: $showRestoreSuccess) {
                Button(NSLocalizedString("OK", value: "OK", comment: ""), role: .cancel) { }
            } message: {
                Text(NSLocalizedString("iossubscription.your.purchases.have.been.restored", value: "Your purchases have been restored.", comment: "Your purchases have been restored."))
            }
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
            
            Text(NSLocalizedString("iossubscription.unlock.premium", value: "Unlock Premium", comment: "Unlock Premium"))
                .font(.title.bold())
            
            Text(NSLocalizedString("iossubscription.get.unlimited.access.to.all.features", value: "Get unlimited access to all features", comment: "Get unlimited access to all features"))
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 20)
    }
    
    @ViewBuilder
    private var statusBanner: some View {
        switch subscriptionManager.subscriptionStatus {
        case .subscribed(let expirationDate):
            VStack(spacing: 8) {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                    Text(NSLocalizedString("iossubscription.active.subscription", value: "Active Subscription", comment: "Active Subscription"))
                        .font(.subheadline.weight(.semibold))
                    Spacer()
                }
                
                if let expiration = expirationDate {
                Text(String(format: NSLocalizedString("subscription.renews", value: "Renews %@", comment: "Subscription renewal date"), expiration.formatted(date: .abbreviated, time: .omitted)))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.green.opacity(0.1))
            )
            
        case .expired:
            HStack {
                Image(systemName: "exclamationmark.circle.fill")
                    .foregroundStyle(.orange)
                Text(NSLocalizedString("iossubscription.subscription.expired", value: "Subscription Expired", comment: "Subscription Expired"))
                    .font(.subheadline.weight(.semibold))
                Spacer()
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.orange.opacity(0.1))
            )
            
        default:
            EmptyView()
        }
    }
    
    private var subscriptionPlans: some View {
        VStack(spacing: 12) {
            ForEach(subscriptionManager.availableSubscriptions, id: \.id) { product in
                SubscriptionPlanCard(
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
        VStack(spacing: 12) {
            ProgressView()
            Text(NSLocalizedString("iossubscription.loading.subscription.options", value: "Loading subscription options...", comment: "Loading subscription options..."))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
    
    private var featuresSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(NSLocalizedString("iossubscription.premium.features", value: "Premium Features", comment: "Premium Features"))
                .font(.headline)
            
            FeatureRow(icon: "brain.head.profile", title: "AI-Powered Study Plans", description: "Intelligent scheduling optimized for your learning")
            FeatureRow(icon: "calendar.badge.clock", title: "Advanced Planning", description: "Auto-schedule assignments with smart conflict resolution")
            FeatureRow(icon: "chart.bar.fill", title: "Analytics & Insights", description: "Track your progress with detailed statistics")
            FeatureRow(icon: "square.stack.3d.up", title: "Unlimited Storage", description: "Store all your assignments and study materials")
            FeatureRow(icon: "person.badge.shield.checkmark", title: "Priority Support", description: "Get help faster with premium support")
        }
        .padding(.vertical)
    }
    
    private var restoreButton: some View {
        Button {
            Task {
                await restorePurchases()
            }
        } label: {
            Text(NSLocalizedString("iossubscription.restore.purchases", value: "Restore Purchases", comment: "Restore Purchases"))
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.bottom, 20)
    }
    
    // MARK: - Actions
    
    private func purchaseSubscription(_ product: Product) async {
        isPurchasing = true
        
        do {
            let transaction = try await subscriptionManager.purchase(product)
            
            if transaction != nil {
                // Purchase successful
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

// MARK: - Subscription Plan Card

private struct SubscriptionPlanCard: View {
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
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(product.displayName)
                        .font(.headline)
                    
                    if let savings = savingsText {
                        Text(savings)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.green)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text(product.displayPrice)
                        .font(.title2.bold())
                    
                    Text(subscriptionPeriod)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            if isCurrentPlan {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                    Text(NSLocalizedString("iossubscription.current.plan", value: "Current Plan", comment: "Current Plan"))
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.green)
                    Spacer()
                }
            } else {
                Button {
                    onPurchase()
                } label: {
                    Group {
                        if isPurchasing {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Text(NSLocalizedString("iossubscription.subscribe", value: "Subscribe", comment: "Subscribe"))
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
                .disabled(isPurchasing)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(uiColor: .secondarySystemBackground))
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

// MARK: - Feature Row

private struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(Color.accentColor)
                .frame(width: 32, height: 32)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
        }
    }
}

#Preview {
    IOSSubscriptionView()
}
#endif
