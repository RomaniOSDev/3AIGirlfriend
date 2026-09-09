import Foundation
import SwiftUI
import Combine

@MainActor
final class AppState: ObservableObject {
    static let freeMessageLimit = 3

    let store: StoreManager

    @Published var hasCompletedOnboarding: Bool {
        didSet { UserDefaults.standard.set(hasCompletedOnboarding, forKey: Keys.onboarding) }
    }

    @Published var userName: String {
        didSet { UserDefaults.standard.set(userName, forKey: Keys.userName) }
    }

    @Published var selectedCompanionID: String {
        didSet { UserDefaults.standard.set(selectedCompanionID, forKey: Keys.companion) }
    }

    @Published var messagesUsed: Int {
        didSet { UserDefaults.standard.set(messagesUsed, forKey: Keys.messagesUsed) }
    }

    @Published var isSubscribed: Bool {
        didSet { UserDefaults.standard.set(isSubscribed, forKey: Keys.subscribed) }
    }

    private var storeCancellable: AnyCancellable?

    @Published var messages: [ChatMessage] = []
    @Published var isTyping = false
    @Published var relationshipStage: RelationshipStage = .gettingToKnow

    @Published var showPaywall = false
    @Published var paywallContext: PaywallContext = .general
    @Published var preferAnnualSelection = false
    @Published var showExitIntent = false
    @Published var showFeatureSheet: FeatureSheetKind?
    @Published var showPostCloseBanner = false
    @Published var postCloseOfferActive = false

    @Published var chatRemindersEnabled: Bool {
        didSet {
            UserDefaults.standard.set(chatRemindersEnabled, forKey: Keys.chatReminders)
            NotificationManager.shared.scheduleInactivityReminder(
                companion: selectedCompanion,
                enabled: chatRemindersEnabled && hasCompletedOnboarding
            )
        }
    }

    private var postCloseWorkItem: DispatchWorkItem?
    private let chatService = WaveSpeedChatService()
    private var replyTask: Task<Void, Never>?

    var selectedCompanion: Companion {
        CompanionCatalog.companion(id: selectedCompanionID)
    }

    var messagesLeft: Int {
        max(0, Self.freeMessageLimit - messagesUsed)
    }

    var canSendMessage: Bool {
        isSubscribed || messagesUsed < Self.freeMessageLimit
    }

    init(store injectedStore: StoreManager? = nil) {
        let store = injectedStore ?? StoreManager()
        self.store = store
        let defaults = UserDefaults.standard
        hasCompletedOnboarding = defaults.bool(forKey: Keys.onboarding)
        userName = defaults.string(forKey: Keys.userName) ?? ""
        let savedCompanion = defaults.string(forKey: Keys.companion) ?? CompanionCatalog.all[0].id
        // Migrate removed placeholder ids
        switch savedCompanion {
        case "mia": selectedCompanionID = "emma"
        case "luna": selectedCompanionID = "elena"
        case "ava": selectedCompanionID = "maya"
        case "nova": selectedCompanionID = "chloe"
        case "ruby": selectedCompanionID = "stella"
        case "zoe": selectedCompanionID = "yuki"
        default: selectedCompanionID = savedCompanion
        }
        messagesUsed = defaults.integer(forKey: Keys.messagesUsed)
        // Cache until StoreKit entitlements refresh
        isSubscribed = defaults.bool(forKey: Keys.subscribed) || store.isSubscribed
        postCloseOfferActive = defaults.bool(forKey: Keys.postCloseOffer)
        // Avoid didSet side-effects during init before flags are ready
        let remindersDefault = defaults.object(forKey: Keys.chatReminders) == nil
            ? true
            : defaults.bool(forKey: Keys.chatReminders)
        _chatRemindersEnabled = Published(initialValue: remindersDefault)

        storeCancellable = store.$isSubscribed
            .receive(on: RunLoop.main)
            .sink { [weak self] active in
                guard let self else { return }
                if self.isSubscribed != active {
                    self.isSubscribed = active
                }
                if active {
                    self.applyPremiumUnlock()
                }
            }

        seedWelcomeIfNeeded()
        Task {
            await store.refresh()
            await NotificationManager.shared.refreshAuthorizationStatus()
            if hasCompletedOnboarding {
                NotificationManager.shared.scheduleInactivityReminder(
                    companion: selectedCompanion,
                    enabled: chatRemindersEnabled
                )
            }
        }
    }

    func completeOnboarding(companionID: String, name: String) {
        selectedCompanionID = companionID
        userName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        hasCompletedOnboarding = true
        seedWelcomeIfNeeded(force: true)
        presentPaywall(context: .onboardingSoft)

        Task {
            let granted = await NotificationManager.shared.requestPermission()
            guard granted else { return }
            NotificationManager.shared.scheduleWelcome(
                companion: selectedCompanion,
                userName: userName
            )
            NotificationManager.shared.scheduleInactivityReminder(
                companion: selectedCompanion,
                enabled: chatRemindersEnabled
            )
        }
    }

    /// Ask for notification permission when the free companion is confirmed on step 1.
    func prepareNotificationsAfterCompanionSelection() {
        Task {
            _ = await NotificationManager.shared.requestPermission()
        }
    }

    func presentPaywall(context: PaywallContext) {
        paywallContext = context
        preferAnnualSelection = context == .messageLimit || context == .postCloseOffer || postCloseOfferActive
        showPaywall = true
    }

    func dismissPaywall(allowExitIntent: Bool) {
        if allowExitIntent && !isSubscribed {
            showExitIntent = true
            return
        }
        showPaywall = false
        showExitIntent = false
        schedulePostCloseOfferIfNeeded()
    }

    func continueWithFreeMessages() {
        showExitIntent = false
        showPaywall = false
        schedulePostCloseOfferIfNeeded()
    }

    func purchase(plan: SubscriptionPlan) async {
        let success = await store.purchase(plan)
        if success {
            applyPremiumUnlock()
        }
    }

    func restorePurchases() async {
        let success = await store.restore()
        if success {
            applyPremiumUnlock()
        }
    }

    /// Called after verified StoreKit entitlement (or DEBUG mock).
    func activateSubscription() {
        isSubscribed = true
        applyPremiumUnlock()
    }

    private func applyPremiumUnlock() {
        showPaywall = false
        showExitIntent = false
        showFeatureSheet = nil
        showPostCloseBanner = false
        postCloseOfferActive = false
        UserDefaults.standard.set(false, forKey: Keys.postCloseOffer)
        postCloseWorkItem?.cancel()
    }

    func sendUserMessage(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        guard canSendMessage else {
            preferAnnualSelection = true
            presentPaywall(context: .messageLimit)
            return
        }

        messages.append(ChatMessage(sender: .user, text: trimmed))
        if !isSubscribed {
            messagesUsed += 1
        }

        NotificationManager.shared.noteChatActivity(
            companion: selectedCompanion,
            remindersEnabled: chatRemindersEnabled
        )

        if !isSubscribed && messagesUsed >= Self.freeMessageLimit {
            triggerHardPaywallAfterTyping()
        } else {
            requestAIReply(to: trimmed)
        }

        updateRelationshipProgress()
    }

    func applySuggestion(_ text: String) {
        sendUserMessage(text)
    }

    func requestLockedFeature(_ kind: FeatureSheetKind) {
        guard !isSubscribed else { return }
        showFeatureSheet = kind
    }

    func selectCompanion(_ id: String) {
        guard isSubscribed else {
            showFeatureSheet = .characters
            return
        }
        replyTask?.cancel()
        isTyping = false
        selectedCompanionID = id
        seedWelcomeIfNeeded(force: true)
        NotificationManager.shared.scheduleInactivityReminder(
            companion: selectedCompanion,
            enabled: chatRemindersEnabled
        )
    }

    func dismissPostCloseBanner() {
        showPostCloseBanner = false
    }

    func openPostCloseOffer() {
        showPostCloseBanner = false
        postCloseOfferActive = true
        UserDefaults.standard.set(true, forKey: Keys.postCloseOffer)
        presentPaywall(context: .postCloseOffer)
    }

    func resetForDebug() {
        hasCompletedOnboarding = false
        userName = ""
        messagesUsed = 0
        isSubscribed = false
        messages = []
        showPaywall = false
        showExitIntent = false
        showFeatureSheet = nil
        showPostCloseBanner = false
        postCloseOfferActive = false
        NotificationManager.shared.cancelAll()
    }

    // MARK: - Private

    private func seedWelcomeIfNeeded(force: Bool = false) {
        guard force || messages.isEmpty else { return }
        let name = userName.isEmpty ? String(localized: "chat.fallback_name") : userName
        let companion = selectedCompanion
        let text = String(
            format: String(localized: "chat.welcome"),
            locale: .current,
            name,
            companion.name,
            companion.accentEmoji
        )
        messages = [ChatMessage(sender: .ai, text: text)]
    }

    private func requestAIReply(to userText: String) {
        replyTask?.cancel()
        isTyping = true

        let companion = selectedCompanion
        let name = userName
        let history = messages
        let systemPrompt = CompanionSystemPrompt.build(for: companion, userName: name)

        replyTask = Task { @MainActor in
            do {
                let reply = try await chatService.complete(
                    systemPrompt: systemPrompt,
                    history: history,
                    userText: userText
                )
                guard !Task.isCancelled else { return }
                isTyping = false
                messages.append(ChatMessage(sender: .ai, text: reply))
            } catch {
                guard !Task.isCancelled else { return }
                // Fallback keeps the chat usable if key/network/model fails
                let fallback = MockReplyGenerator.reply(
                    for: userText,
                    companion: companion,
                    userName: name
                )
                isTyping = false
                messages.append(ChatMessage(sender: .ai, text: fallback))
                #if DEBUG
                print("WaveSpeed error: \(error.localizedDescription)")
                #endif
            }
        }
    }

    private func triggerHardPaywallAfterTyping() {
        isTyping = true
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 1_500_000_000)
            isTyping = false
            preferAnnualSelection = true
            presentPaywall(context: .messageLimit)
        }
    }

    private func updateRelationshipProgress() {
        let total = messages.filter { $0.sender == .user }.count
        if total >= 12 {
            relationshipStage = .deeplyConnected
        } else if total >= 5 {
            relationshipStage = .closeFriends
        } else {
            relationshipStage = .gettingToKnow
        }
    }

    private func schedulePostCloseOfferIfNeeded() {
        guard !isSubscribed, !postCloseOfferActive else { return }
        guard !UserDefaults.standard.bool(forKey: Keys.postCloseShownOnce) else { return }

        postCloseWorkItem?.cancel()
        let work = DispatchWorkItem { [weak self] in
            guard let self, !self.isSubscribed else { return }
            self.showPostCloseBanner = true
            UserDefaults.standard.set(true, forKey: Keys.postCloseShownOnce)
        }
        postCloseWorkItem = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 30, execute: work)
    }

    private enum Keys {
        static let onboarding = "aigf.onboarding"
        static let userName = "aigf.userName"
        static let companion = "aigf.companion"
        static let messagesUsed = "aigf.messagesUsed"
        static let subscribed = "aigf.subscribed"
        static let postCloseOffer = "aigf.postCloseOffer"
        static let postCloseShownOnce = "aigf.postCloseShownOnce"
        static let chatReminders = "aigf.chatReminders"
    }
}

enum FeatureSheetKind: Identifiable, Equatable {
    case photos
    case characters
    case edit

    var id: String {
        switch self {
        case .photos: return "photos"
        case .characters: return "characters"
        case .edit: return "edit"
        }
    }
}

enum MockReplyGenerator {
    static func reply(for text: String, companion: Companion, userName: String) -> String {
        let name = userName.isEmpty ? String(localized: "chat.reply_you") : userName
        let lower = text.lowercased()

        if lower.contains("hello") || lower.contains("hi") || lower.contains("hey")
            || lower.contains("привет") || lower.contains("здравств") {
            return String(format: String(localized: "chat.reply_hello"), locale: .current, name)
        }
        if lower.contains("how are you") || lower.contains("как дела") || lower.contains("как ты") {
            return String(localized: "chat.reply_how_are_you")
        }
        if lower.contains("miss") || lower.contains("скучаю") {
            return String(
                format: String(localized: "chat.reply_miss"),
                locale: .current,
                companion.accentEmoji
            )
        }

        let templates = [
            String(format: String(localized: "chat.reply_1"), locale: .current, name),
            String(localized: "chat.reply_2"),
            String(localized: "chat.reply_3"),
            String(localized: "chat.reply_4"),
            String(localized: "chat.reply_5"),
            String(localized: "chat.reply_6"),
            String(localized: "chat.reply_7"),
            String(localized: "chat.reply_8")
        ]
        return templates.randomElement() ?? templates[0]
    }

    static var suggestions: [String] {
        [
            String(localized: "chat.suggestion_1"),
            String(localized: "chat.suggestion_2"),
            String(localized: "chat.suggestion_3")
        ]
    }
}
