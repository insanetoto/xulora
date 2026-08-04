import Foundation
import UserNotifications
import OSLog

private let logger = Logger(subsystem: "com.nuochong.xulora", category: "Notifications")

/// Manages system notification permissions and delivery.
@MainActor
final class NotificationService {
    static let shared = NotificationService()

    private let center = UNUserNotificationCenter.current()

    private init() {}

    /// Request notification authorization.
    func requestAuthorization() async -> Bool {
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            logger.info("Notification authorization: \(granted ? "granted" : "denied")")
            return granted
        } catch {
            logger.error("Notification auth failed: \(error.localizedDescription)")
            return false
        }
    }

    /// Send an immediate local notification.
    func send(title: String, body: String, sound: UNNotificationSound = .default) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = sound

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil // immediate
        )

        center.add(request) { error in
            if let error {
                logger.error("Failed to deliver notification: \(error.localizedDescription)")
            }
        }
    }

    /// Cancel all pending notifications for pomodoro or other timed purposes.
    func cancelAll() {
        center.removeAllPendingNotificationRequests()
    }
}
