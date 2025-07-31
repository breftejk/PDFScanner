import SwiftUI
import StoreKit

struct SubscriptionView: View {
    @EnvironmentObject var storeManager: StoreManager
    
    var body: some View {
        ZStack {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()
            VStack(spacing: 32) {
                VStack(spacing: 16) {
                    Image(systemName: storeManager.isPro ? "crown.fill" : "creditcard.fill")
                        .font(.system(size: 56, weight: .semibold))
                        .foregroundColor(storeManager.isPro ? .yellow : .accentColor)
                        .padding(.bottom, 2)
                    Text(storeManager.isPro ? "Pro Access" : "Free Access")
                        .font(.title.bold())
                        .foregroundColor(storeManager.isPro ? .accentColor : .secondary)
                    if storeManager.subscriptionIsRevoked {
                        Text("Subscription revoked")
                            .font(.subheadline)
                            .foregroundColor(.red)
                    } else if storeManager.subscriptionIsExpired {
                        Text("Subscription expired")
                            .font(.subheadline)
                            .foregroundColor(.orange)
                    } else if storeManager.isPro {
                        if let exp = storeManager.subscriptionExpirationDate {
                            Text("Active until \(exp, style: .date)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        if storeManager.subscriptionWillAutoRenew {
                            Text("Auto-renewal enabled")
                                .font(.subheadline)
                                .foregroundColor(.green)
                        } else {
                            Text("Auto-renewal off")
                                .font(.subheadline)
                                .foregroundColor(.yellow)
                        }
                    }
                }
                .padding(.vertical, 32)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(Color(.secondarySystemGroupedBackground))
                )
                .padding(.horizontal)

                if let product = storeManager.products.first, let subscription = product.subscription {
                    VStack(spacing: 8) {
                        if let intro = subscription.introductoryOffer {
                            Text("Trial: \(intro.periodCount) \(intro.period.localizedDescription) \(intro.paymentMode.localizedDescription)")
                                .font(.footnote)
                                .foregroundColor(.secondary)
                        }
                        Text("\(product.displayPrice) / \(subscription.subscriptionPeriod.localizedDescription)")
                            .font(.title3.bold())
                            .foregroundColor(.primary)
                    }
                }

                Button(action: {
                    Task {
                        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                            try? await AppStore.showManageSubscriptions(in: windowScene)
                        }
                    }
                }) {
                    Text("Manage Subscription")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .cornerRadius(14)
                }
                .padding(.horizontal)
            }
            .padding(.vertical, 40)
            .navigationTitle("Subscription")
        }
    }
}

extension Product.SubscriptionOffer.PaymentMode {
    var localizedDescription: String {
        switch self {
        case .payAsYouGo:
            return "Pay as you go"
        case .payUpFront:
            return "Pay up front"
        case .freeTrial:
            return "Free trial"
        default:
            return "Unknown"
        }
    }
}

extension Product.SubscriptionPeriod {
    var localizedDescription: String {
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .full
        formatter.allowedUnits = [.day, .weekOfMonth, .month, .year]
        var components = DateComponents()
        switch self.unit {
        case .day:
            components.day = self.value
        case .week:
            components.weekOfMonth = self.value
        case .month:
            components.month = self.value
        case .year:
            components.year = self.value
        @unknown default:
            return "Unknown"
        }
        return formatter.string(from: components) ?? ""
    }
}

extension TimeInterval {
    var localizedDescription: String {
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .full
        formatter.allowedUnits = [.day, .weekOfMonth, .month, .year]
        return formatter.string(from: self) ?? ""
    }
}

struct SubscriptionView_Previews: PreviewProvider {
    static var previews: some View {
        SubscriptionView()
            .environmentObject(StoreManager())
    }
}
