import Foundation
import Combine
import StoreKit
import SwiftUI

@MainActor
class StoreManager: ObservableObject {
    @Published var isPro: Bool = false
    @Published var products: [Product] = []
    @Published var subscriptionExpirationDate: Date? = nil
    @Published var subscriptionWillAutoRenew: Bool = false
    @Published var subscriptionIsExpired: Bool = false
    @Published var subscriptionIsRevoked: Bool = false
    private var transactionListener: Task<Void, Error>? = nil
    
    let productIds = ["com_assistants_technologies_pdfscanner_pro"]

    init() {
        transactionListener = listenForTransactions()
        
        Task {
            await requestProducts()
            await updateProStatus()
        }
    }
    
    deinit {
        transactionListener?.cancel()
    }

    func requestProducts() async {
        do {
            products = try await Product.products(for: productIds)
        } catch {
            print("Failed to fetch products: \(error)")
        }
    }

    func purchasePro() {
        Task {
            guard let proProduct = products.first else { return }
            
            do {
                let result = try await proProduct.purchase()
                
                switch result {
                case .success(let verification):
                    let transaction = try checkVerified(verification)
                    await transaction.finish()
                    await updateProStatus()
                case .pending:
                    break
                case .userCancelled:
                    break
                @unknown default:
                    break
                }
            } catch {
                print("Purchase failed: \(error)")
            }
        }
    }

    func restorePurchases() {
        Task {
            do {
                try await AppStore.sync()
                await updateProStatus()
            } catch {
                print("Failed to restore purchases: \(error)")
            }
        }
    }
    
    func listenForTransactions() -> Task<Void, Error> {
        return Task.detached {
            for await result in Transaction.updates {
                do {
                    let transaction = try self.checkVerified(result)
                    await self.updateProStatus()
                    await transaction.finish()
                } catch {
                    print("Transaction failed verification")
                }
            }
        }
    }
    
    nonisolated func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreKitError.unknown
        case .verified(let safe):
            return safe
        }
    }
    
    func updateProStatus() async {
        var isPro = false
        var expirationDate: Date? = nil
        var willAutoRenew = false
        var isExpired = false
        var isRevoked = false

        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else { continue }

            if self.productIds.contains(transaction.productID) {
                expirationDate = transaction.expirationDate
                isRevoked = transaction.revocationDate != nil
                if let exp = expirationDate {
                    isExpired = exp < Date()
                }
                // Only allow PRO if not expired and not revoked
                if !isExpired && !isRevoked {
                    isPro = true
                }
                if let product = products.first(where: { $0.id == transaction.productID }) {
                    do {
                        if let subscription = product.subscription {
                            let statuses = try await subscription.status
                            if let status = statuses.first {
                                switch status.renewalInfo {
                                case .verified(let verifiedRenewalInfo):
                                    willAutoRenew = verifiedRenewalInfo.willAutoRenew
                                default:
                                    break
                                }
                            }
                        }
                    } catch {
                        print("Failed to get subscription status: \(error)")
                    }
                }
                break
            }
        }

        self.isPro = isPro
        self.subscriptionExpirationDate = expirationDate
        self.subscriptionWillAutoRenew = willAutoRenew
        self.subscriptionIsExpired = isExpired
        self.subscriptionIsRevoked = isRevoked
    }
}
