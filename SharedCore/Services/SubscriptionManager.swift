import Combine
import Foundation
import StoreKit

@MainActor
final class SubscriptionManager: ObservableObject {
    static let shared = SubscriptionManager()

    @Published private(set) var subscriptionStatus: SubscriptionStatus = .unknown
    @Published private(set) var availableSubscriptions: [Product] = []
    @Published private(set) var purchasedSubscriptions: [Product] = []
    
    private var updateListenerTask: Task<Void, Error>? = nil
    
    // Product identifiers - must match App Store Connect configuration exactly
    // These IDs correspond to the StoreKit configuration in Config/ItoriSubscriptions.storekit
    private let productIdentifiers = [
        "com.itori.subscription.monthly",  // Monthly subscription: $4.99/month
        "com.itori.subscription.yearly"    // Yearly subscription: $49.99/year (17% savings)
        "6757490466",
        "6757490562",
        "6757490611",
        "6757490125"

    private var updateListenerTask: Task<Void, Error>?

    // Product identifiers - must match App Store Connect configuration exactly
    // These IDs correspond to the StoreKit configuration in Config/ItoriSubscriptions.storekit
    private let productIdentifiers = [
        "com.itori.subscription.monthly", // Monthly subscription: $4.99/month
        "com.itori.subscription.yearly" // Yearly subscription: $49.99/year (17% savings)

    private var updateListenerTask: Task<Void, Error>?

    // Product identifiers - must match App Store Connect configuration exactly
    // These IDs correspond to the StoreKit configuration in Config/ItoriSubscriptions.storekit
    private let productIdentifiers = [
        "com.itori.subscription.monthly", // Monthly subscription: $4.99/month
        "com.itori.subscription.yearly" // Yearly subscription: $49.99/year (17% savings)
    ]

    enum SubscriptionStatus {
        case unknown
        case notSubscribed
        case subscribed(expirationDate: Date?)
        case expired
        case inGracePeriod
        case inBillingRetry
    }

    private init() {
        // Start listening for transaction updates
        updateListenerTask = listenForTransactions()

        Task {
            await loadProducts()
            await updateSubscriptionStatus()
        }
    }

    deinit {
        updateListenerTask?.cancel()
    }

    // MARK: - Public Methods

    func loadProducts() async {
        do {
            let products = try await Product.products(for: productIdentifiers)
            availableSubscriptions = products.sorted { $0.price < $1.price }
        } catch {
            print("Failed to load products: \(error)")
        }
    }

    func purchase(_ product: Product) async throws -> Transaction? {
        let result = try await product.purchase()

        switch result {
        case let .success(verification):
            let transaction = try checkVerified(verification)
            await updateSubscriptionStatus()
            await transaction.finish()
            return transaction

        case .userCancelled:
            return nil

        case .pending:
            return nil

        @unknown default:
            return nil
        }
    }

    func restorePurchases() async throws {
        try await AppStore.sync()
        await updateSubscriptionStatus()
    }

    func updateSubscriptionStatus() async {
        var activeSubscription: Product?
        var expirationDate: Date?

        for await result in Transaction.currentEntitlements {
            guard case let .verified(transaction) = result else { continue }

            if let product = availableSubscriptions.first(where: { $0.id == transaction.productID }) {
                activeSubscription = product
                expirationDate = transaction.expirationDate
            }

            // Update purchased subscriptions list
            if let product = availableSubscriptions.first(where: { $0.id == transaction.productID }),
               !purchasedSubscriptions.contains(where: { $0.id == product.id })
            {
                purchasedSubscriptions.append(product)
            }
        }

        if let _ = activeSubscription {
            if let expiration = expirationDate, expiration < Date() {
                subscriptionStatus = .expired
            } else {
                subscriptionStatus = .subscribed(expirationDate: expirationDate)
            }
        } else {
            subscriptionStatus = .notSubscribed
        }
    }

    var isSubscribed: Bool {
        if case .subscribed = subscriptionStatus {
            return true
        }
        return false
    }

    // MARK: - Private Methods

    private func listenForTransactions() -> Task<Void, Error> {
        Task.detached {
            for await result in Transaction.updates {
                guard case let .verified(transaction) = result else { continue }
                await self.updateSubscriptionStatus()
                await transaction.finish()
            }
        }
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw SubscriptionError.failedVerification
        case let .verified(safe):
            return safe
        }
    }
}

enum SubscriptionError: Error {
    case failedVerification
    case purchaseFailed
    case restoreFailed
}
