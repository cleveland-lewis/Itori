import Foundation
import Combine
import StoreKit

@MainActor
final class SubscriptionManager: ObservableObject {
    static let shared = SubscriptionManager()
    
    @Published private(set) var subscriptionStatus: SubscriptionStatus = .unknown
    @Published private(set) var availableSubscriptions: [Product] = []
    @Published private(set) var purchasedSubscriptions: [Product] = []
    
    private var updateListenerTask: Task<Void, Error>? = nil
    
    // Product identifiers - these should match your App Store Connect configuration
    private let productIdentifiers = [
        "6757490466",
        "6757490562",
        "6757490611",
        "6757490125"
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
        case .success(let verification):
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
            guard case .verified(let transaction) = result else { continue }
            
            if let product = availableSubscriptions.first(where: { $0.id == transaction.productID }) {
                activeSubscription = product
                expirationDate = transaction.expirationDate
            }
            
            // Update purchased subscriptions list
            if let product = availableSubscriptions.first(where: { $0.id == transaction.productID }),
               !purchasedSubscriptions.contains(where: { $0.id == product.id }) {
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
        return Task.detached {
            for await result in Transaction.updates {
                guard case .verified(let transaction) = result else { continue }
                await self.updateSubscriptionStatus()
                await transaction.finish()
            }
        }
    }
    
    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw SubscriptionError.failedVerification
        case .verified(let safe):
            return safe
        }
    }
}

enum SubscriptionError: Error {
    case failedVerification
    case purchaseFailed
    case restoreFailed
}
