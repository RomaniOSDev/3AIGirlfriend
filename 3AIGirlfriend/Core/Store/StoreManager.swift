import Combine
import Foundation
import StoreKit

@MainActor
final class StoreManager: ObservableObject {
    @Published private(set) var products: [Product] = []
    @Published private(set) var isSubscribed = false
    @Published private(set) var isLoadingProducts = false
    @Published private(set) var isPurchasing = false
    @Published var lastErrorMessage: String?

    private var updatesTask: Task<Void, Never>?

    init() {
        updatesTask = listenForTransactions()
        Task { await refresh() }
    }

    deinit {
        updatesTask?.cancel()
    }

    func product(for plan: SubscriptionPlan) -> Product? {
        products.first(where: { $0.id == plan.productID })
    }

    func displayPrice(for plan: SubscriptionPlan) -> String? {
        product(for: plan)?.displayPrice
    }

    /// Primary line: "$6.99/wk" from App Store product
    func primaryPriceLabel(for plan: SubscriptionPlan) -> String? {
        guard let product = product(for: plan) else { return nil }
        return "\(product.displayPrice)\(periodSuffix(for: product))"
    }

    /// Secondary marketing line derived from StoreKit price (per day / per week)
    func secondaryPriceLabel(for plan: SubscriptionPlan) -> String? {
        guard let product = product(for: plan) else { return nil }
        switch plan {
        case .weekly:
            let daily = product.price / 7
            return String(
                format: String(localized: "plan.secondary_fmt_day"),
                locale: .current,
                formatMoney(daily, product: product)
            )
        case .monthly:
            let weekly = product.price * 12 / 52
            return String(
                format: String(localized: "plan.secondary_fmt_week"),
                locale: .current,
                formatMoney(weekly, product: product)
            )
        case .annual:
            let weekly = product.price / 52
            return String(
                format: String(localized: "plan.secondary_fmt_week"),
                locale: .current,
                formatMoney(weekly, product: product)
            )
        }
    }

    /// Compare-at for annual = weekly × 52 (from live weekly product)
    func strikethroughPrice(for plan: SubscriptionPlan) -> String? {
        guard plan == .annual,
              let weekly = product(for: .weekly) else { return nil }
        return formatMoney(weekly.price * 52, product: weekly)
    }

    func ctaSubtitle(for plan: SubscriptionPlan, isOffer: Bool) -> String {
        switch plan {
        case .weekly:
            if let price = primaryPriceLabel(for: .weekly) {
                return String(
                    format: String(localized: "paywall.cta_sub_weekly_fmt"),
                    locale: .current,
                    price
                )
            }
            return String(localized: "paywall.cta_sub_weekly")
        case .monthly:
            return String(localized: "paywall.cta_sub_monthly")
        case .annual:
            return isOffer
                ? String(localized: "paywall.cta_sub_annual_offer")
                : String(localized: "paywall.cta_sub_annual")
        }
    }

    func exitMonthlyTitle() -> String {
        if let price = displayPrice(for: .monthly) {
            return String(
                format: String(localized: "exit.monthly_fmt"),
                locale: .current,
                price
            )
        }
        return String(localized: "exit.monthly")
    }

    func exitAnnualTitle() -> String {
        if let perWeek = secondaryPriceLabel(for: .annual) {
            return String(
                format: String(localized: "exit.annual_fmt"),
                locale: .current,
                perWeek
            )
        }
        return String(localized: "exit.annual")
    }

    func refresh() async {
        await loadProducts()
        await updateEntitlements()
    }

    func loadProducts() async {
        isLoadingProducts = true
        defer { isLoadingProducts = false }
        do {
            let ids = StoreProductIDs.all
            let loaded = try await Product.products(for: ids)
            products = loaded.sorted { lhs, rhs in
                orderIndex(lhs.id) < orderIndex(rhs.id)
            }
            if loaded.isEmpty {
                lastErrorMessage = String(localized: "store.error_no_products")
                #if DEBUG
                print("""
                StoreKit: Product.products returned [].
                Requested IDs: \(ids.sorted())
                → Edit Scheme → Run → Options → StoreKit Configuration = Products.storekit
                → Open 3AIGirlfriend.xcworkspace (not .xcodeproj) and Clean Build Folder, then Run.
                """)
                #endif
            } else {
                // Clear stale error after a successful load
                if lastErrorMessage == String(localized: "store.error_no_products") {
                    lastErrorMessage = nil
                }
                #if DEBUG
                print("StoreKit: loaded \(loaded.map(\.id))")
                #endif
            }
        } catch {
            lastErrorMessage = error.localizedDescription
            #if DEBUG
            print("StoreKit loadProducts error: \(error)")
            #endif
        }
    }

    @discardableResult
    func purchase(_ plan: SubscriptionPlan) async -> Bool {
        lastErrorMessage = nil
        guard let product = product(for: plan) else {
            await loadProducts()
            guard product(for: plan) != nil else {
                lastErrorMessage = String(localized: "store.error_no_products")
                return false
            }
            return await purchase(plan)
        }

        isPurchasing = true
        defer { isPurchasing = false }

        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                if StoreProductIDs.all.contains(transaction.productID) {
                    isSubscribed = true
                    UserDefaults.standard.set(true, forKey: "aigf.subscribed")
                }
                await transaction.finish()
                await updateEntitlements()
                return isSubscribed || StoreProductIDs.all.contains(transaction.productID)
            case .userCancelled:
                return false
            case .pending:
                lastErrorMessage = String(localized: "store.error_pending")
                return false
            @unknown default:
                return false
            }
        } catch {
            lastErrorMessage = error.localizedDescription
            #if DEBUG
            print("StoreKit purchase error: \(error)")
            #endif
            return false
        }
    }

    func restore() async -> Bool {
        lastErrorMessage = nil
        isPurchasing = true
        defer { isPurchasing = false }
        do {
            try await AppStore.sync()
            await updateEntitlements()
            if !isSubscribed {
                lastErrorMessage = String(localized: "store.error_nothing_to_restore")
            }
            return isSubscribed
        } catch {
            lastErrorMessage = error.localizedDescription
            return false
        }
    }

    func updateEntitlements() async {
        var active = false
        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else { continue }
            guard StoreProductIDs.all.contains(transaction.productID) else { continue }
            if transaction.revocationDate == nil {
                active = true
                break
            }
        }
        isSubscribed = active
        UserDefaults.standard.set(active, forKey: "aigf.subscribed")
    }

    // MARK: - Private

    private func listenForTransactions() -> Task<Void, Never> {
        Task { [weak self] in
            for await result in Transaction.updates {
                guard let self else { return }
                do {
                    let transaction = try self.checkVerified(result)
                    await transaction.finish()
                    await self.updateEntitlements()
                } catch {
                    #if DEBUG
                    print("StoreKit transaction update error: \(error)")
                    #endif
                }
            }
        }
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified(_, let error):
            throw error
        case .verified(let value):
            return value
        }
    }

    private func orderIndex(_ id: String) -> Int {
        switch id {
        case StoreProductIDs.weekly: return 0
        case StoreProductIDs.annual: return 1
        case StoreProductIDs.monthly: return 2
        default: return 99
        }
    }

    private func periodSuffix(for product: Product) -> String {
        guard let period = product.subscription?.subscriptionPeriod else { return "" }
        switch period.unit {
        case .day:
            return period.value == 1
                ? String(localized: "plan.suffix_day")
                : String(format: String(localized: "plan.suffix_days_fmt"), locale: .current, period.value)
        case .week:
            return String(localized: "plan.suffix_week")
        case .month:
            return String(localized: "plan.suffix_month")
        case .year:
            return String(localized: "plan.suffix_year")
        @unknown default:
            return ""
        }
    }

    private func formatMoney(_ value: Decimal, product: Product) -> String {
        var copy = value
        var rounded = Decimal()
        NSDecimalRound(&rounded, &copy, 2, .plain)
        return product.priceFormatStyle.format(rounded)
    }
}
