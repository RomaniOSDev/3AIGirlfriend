import Combine
import Foundation
import Intents
import UIKit
import UserNotifications

@MainActor
final class NotificationManager: NSObject, ObservableObject {
    static let shared = NotificationManager()

    private enum IDs {
        static let welcome = "aigf.welcome"
        static let inactivity = "aigf.inactivity"
    }

    static let inactivityInterval: TimeInterval = 12 * 60 * 60

    @Published private(set) var isAuthorized = false

    override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
    }

    func refreshAuthorizationStatus() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        isAuthorized = settings.authorizationStatus == .authorized
            || settings.authorizationStatus == .provisional
    }

    @discardableResult
    func requestPermission() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .badge, .sound])
            isAuthorized = granted
            return granted
        } catch {
            isAuthorized = false
            return false
        }
    }

    /// Greeting soon after companion is chosen.
    func scheduleWelcome(companion: Companion, userName: String) {
        cancel(id: IDs.welcome)

        let name = userName.trimmingCharacters(in: .whitespacesAndNewlines)
        let body: String
        if name.isEmpty {
            body = String(
                format: String(localized: "notification.welcome_body"),
                locale: .current,
                companion.name
            )
        } else {
            body = String(
                format: String(localized: "notification.welcome_body_named"),
                locale: .current,
                name,
                companion.name
            )
        }

        let content = makeMessageContent(
            body: body,
            companion: companion
        )

        // Slight delay so the system dialog / next screen can settle first.
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 3, repeats: false)
        let request = UNNotificationRequest(identifier: IDs.welcome, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    /// Fires every 12 hours until the user chats again (then reschedule from that moment).
    func scheduleInactivityReminder(companion: Companion, enabled: Bool) {
        cancel(id: IDs.inactivity)
        guard enabled else { return }

        let body = String(
            format: String(localized: "notification.inactivity_body"),
            locale: .current,
            companion.name
        )
        let content = makeMessageContent(body: body, companion: companion)

        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: Self.inactivityInterval,
            repeats: true
        )
        let request = UNNotificationRequest(
            identifier: IDs.inactivity,
            content: content,
            trigger: trigger
        )
        UNUserNotificationCenter.current().add(request)
    }

    /// Call when the user sends a chat message — resets the 12h timer.
    func noteChatActivity(companion: Companion, remindersEnabled: Bool) {
        UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: "aigf.lastChatActivity")
        scheduleInactivityReminder(companion: companion, enabled: remindersEnabled)
    }

    func cancelAll() {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: [IDs.welcome, IDs.inactivity])
    }

    private func cancel(id: String) {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: [id])
    }

    /// Communication Notification: shows companion avatar instead of the app icon.
    private func makeMessageContent(body: String, companion: Companion) -> UNNotificationContent {
        let content = UNMutableNotificationContent()
        content.title = companion.name
        content.body = body
        content.sound = .default

        let avatarName = companion.primaryPhotoName
        let avatar = avatarName.flatMap { INImage(named: $0) }

        let handle = INPersonHandle(value: companion.id, type: .unknown)
        let person = INPerson(
            personHandle: handle,
            nameComponents: nil,
            displayName: companion.name,
            image: avatar,
            contactIdentifier: nil,
            customIdentifier: companion.id
        )

        let intent = INSendMessageIntent(
            recipients: nil,
            outgoingMessageType: .outgoingMessageText,
            content: body,
            speakableGroupName: nil,
            conversationIdentifier: "aigf.\(companion.id)",
            serviceName: nil,
            sender: person,
            attachments: nil
        )
        if let avatar {
            intent.setImage(avatar, forParameterNamed: \.sender)
        }

        let interaction = INInteraction(intent: intent, response: nil)
        interaction.direction = .incoming
        interaction.donate(completion: nil)

        do {
            return try content.updating(from: intent)
        } catch {
            #if DEBUG
            print("Communication notification update failed: \(error)")
            #endif
            // Fallback: attach photo as notification thumbnail
            if let avatarName, let attachment = Self.attachment(fromAssetNamed: avatarName) {
                content.attachments = [attachment]
            }
            return content
        }
    }

    private static func attachment(fromAssetNamed name: String) -> UNNotificationAttachment? {
        guard let image = UIImage(named: name),
              let data = image.jpegData(compressionQuality: 0.85) else { return nil }
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("aigf-\(name)-\(UUID().uuidString).jpg")
        do {
            try data.write(to: url)
            return try UNNotificationAttachment(identifier: name, url: url)
        } catch {
            return nil
        }
    }
}

extension NotificationManager: UNUserNotificationCenterDelegate {
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .sound, .badge]
    }
}
