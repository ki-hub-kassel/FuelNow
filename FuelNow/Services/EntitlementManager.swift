import Foundation
import Observation
import StoreKit

// Lives under Services so a future CarPlay extension target can add this file to compile membership.

private final class TransactionUpdatesSubscription {
    private var task: Task<Void, Never>?

    func replace(with newTask: Task<Void, Never>) {
        task?.cancel()
        task = newTask
    }

    deinit {
        task?.cancel()
    }
}

/// StoreKit-2 subscription state for FuelNow Plus. Same entitlement gates CarPlay (Phase 7).
@Observable @MainActor
final class EntitlementManager {
    /// Loaded subscription products (ASC / `.storekit` Local Testing).
    private(set) var products: [Product] = []

    /// True when an active FuelNow Plus subscription is in `Transaction.currentEntitlements`.
    private(set) var isPlusSubscriber = false

    /// Alias for product roadmap — today identical to Plus.
    var isCarPlayUnlocked: Bool { isPlusSubscriber }

    @ObservationIgnored private let transactionUpdates = TransactionUpdatesSubscription()

    init() {}

    /// Loads products, refreshes entitlements, then observes `Transaction.updates` for the app lifetime.
    func start() async {
        await loadProducts()
        await refreshEntitlements()
        guard ProcessInfo.processInfo.environment["UITESTING"] != "1" else { return }
        observeTransactionUpdates()
    }

    func loadProducts() async {
        do {
            products = try await Product.products(for: SubscriptionConstants.productIDs)
            Self.sortPlusProducts(&products)
        } catch {
            products = []
        }
    }

    func purchase(_ product: Product) async throws {
        let result = try await product.purchase()
        switch result {
        case let .success(verification):
            let transaction = try Self.unwrapVerification(verification)
            await transaction.finish()
            await refreshEntitlements()
        case .userCancelled:
            throw EntitlementManagerError.userCancelled
        case .pending:
            throw EntitlementManagerError.pending
        @unknown default:
            throw EntitlementManagerError.unknownPurchaseResult
        }
    }

    /// Restore via Apple account sync, then re-read current entitlements.
    func restorePurchases() async throws {
        try await AppStore.sync()
        await refreshEntitlements()
    }

    func refreshEntitlements() async {
        var plus = false
        for await entitlement in Transaction.currentEntitlements {
            guard case let .verified(transaction) = entitlement else { continue }
            guard transaction.revocationDate == nil else { continue }
            if SubscriptionConstants.productIDs.contains(transaction.productID) {
                plus = true
                break
            }
        }
        #if DEBUG
        let debugOverride = UserDefaults.standard.bool(forKey: AppSettings.UserDefaultsKey.temporaryDebugPlusOverrideEnabled)
        isPlusSubscriber = plus || debugOverride
        #else
        isPlusSubscriber = plus
        #endif
    }

    private static func sortPlusProducts(_ products: inout [Product]) {
        let order = SubscriptionConstants.productIDs
        products.sort { lhs, rhs in
            let li = order.firstIndex(of: lhs.id) ?? Int.max
            let ri = order.firstIndex(of: rhs.id) ?? Int.max
            if li != ri { return li < ri }
            return lhs.id < rhs.id
        }
    }

    private func observeTransactionUpdates() {
        transactionUpdates.replace(with: Task { [weak self] in
            for await update in Transaction.updates {
                await self?.handle(transactionUpdate: update)
            }
        })
    }

    private func handle(transactionUpdate: VerificationResult<Transaction>) async {
        guard case let .verified(transaction) = transactionUpdate else { return }
        await transaction.finish()
        await refreshEntitlements()
    }

    private static func unwrapVerification(_ result: VerificationResult<Transaction>) throws -> Transaction {
        switch result {
        case let .verified(transaction):
            transaction
        case let .unverified(_, error):
            throw error
        }
    }
}

enum EntitlementManagerError: Error, Equatable {
    case userCancelled
    case pending
    case unknownPurchaseResult
}
