import Foundation

enum StoreProductIDs {
    /// Must match App Store Connect + Products.storekit
    static let weekly = "home.AIGirlfriend.weekly"
    static let monthly = "home.AIGirlfriend.monthly"
    static let annual = "home.AIGirlfriend.annual"

    static let all: Set<String> = [weekly, monthly, annual]
}

extension SubscriptionPlan {
    var productID: String {
        switch self {
        case .weekly: return StoreProductIDs.weekly
        case .monthly: return StoreProductIDs.monthly
        case .annual: return StoreProductIDs.annual
        }
    }

    static func from(productID: String) -> SubscriptionPlan? {
        switch productID {
        case StoreProductIDs.weekly: return .weekly
        case StoreProductIDs.monthly: return .monthly
        case StoreProductIDs.annual: return .annual
        default: return nil
        }
    }
}
