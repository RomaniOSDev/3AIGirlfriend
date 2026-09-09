import Foundation

enum MessageSender: String, Codable {
    case user
    case ai
    case system
}

struct ChatMessage: Identifiable, Equatable {
    let id: UUID
    let sender: MessageSender
    let text: String
    let date: Date

    init(id: UUID = UUID(), sender: MessageSender, text: String, date: Date = Date()) {
        self.id = id
        self.sender = sender
        self.text = text
        self.date = date
    }
}

enum RelationshipStage: Int, CaseIterable {
    case gettingToKnow = 0
    case closeFriends = 1
    case deeplyConnected = 2

    var title: String {
        switch self {
        case .gettingToKnow: return String(localized: "relationship.getting_to_know")
        case .closeFriends: return String(localized: "relationship.close_friends")
        case .deeplyConnected: return String(localized: "relationship.deeply_connected")
        }
    }

    var shortLabel: String {
        switch self {
        case .gettingToKnow: return String(localized: "relationship.strangers")
        case .closeFriends: return String(localized: "relationship.close_friends")
        case .deeplyConnected: return String(localized: "relationship.soulmates")
        }
    }

    var progress: Double {
        switch self {
        case .gettingToKnow: return 0.18
        case .closeFriends: return 0.55
        case .deeplyConnected: return 1.0
        }
    }
}

enum SubscriptionPlan: String, CaseIterable, Identifiable {
    case weekly
    case annual
    case monthly

    var id: String { rawValue }

    var title: String {
        switch self {
        case .weekly: return String(localized: "plan.weekly")
        case .monthly: return String(localized: "plan.monthly")
        case .annual: return String(localized: "plan.annual")
        }
    }

    /// Primary price line, e.g. $6.99/wk
    var priceLabel: String {
        switch self {
        case .weekly: return String(localized: "plan.price_weekly")
        case .monthly: return String(localized: "plan.price_monthly")
        case .annual: return String(localized: "plan.price_annual")
        }
    }

    /// Secondary line under price
    var secondaryPrice: String {
        switch self {
        case .weekly: return String(localized: "plan.secondary_weekly")
        case .monthly: return String(localized: "plan.secondary_monthly")
        case .annual: return String(localized: "plan.secondary_annual")
        }
    }

    var strikethroughPrice: String? {
        switch self {
        case .annual: return "$83.88"
        default: return nil
        }
    }

    var badge: String? {
        switch self {
        case .annual: return String(localized: "plan.badge_value")
        default: return nil
        }
    }
}

enum PaywallContext: Equatable {
    case onboardingSoft
    case messageLimit
    case featurePhotos
    case featureCharacters
    case editProfile
    case postCloseOffer
    case general
}
