import SwiftUI
import OSLog

private let logger = Logger(subsystem: "com.nuochong.xulora", category: "Lifecycle")

/// Observes app lifecycle events: launch, sleep, wake, terminate.
@MainActor
enum AppLifecycle {
    /// Called when the app is about to terminate. Set before calling setup().
    nonisolated(unsafe) static var onTerminate: (() -> Void)?

    static func setup() {
        NotificationCenter.default.addObserver(
            forName: NSApplication.willTerminateNotification,
            object: nil,
            queue: .main
        ) { _ in
            logger.info("Application will terminate — saving state")
            onTerminate?()
        }

        NotificationCenter.default.addObserver(
            forName: NSWorkspace.screensDidSleepNotification,
            object: nil,
            queue: .main
        ) { _ in
            logger.info("Displays went to sleep — pausing non-essential work")
        }

        NotificationCenter.default.addObserver(
            forName: NSWorkspace.screensDidWakeNotification,
            object: nil,
            queue: .main
        ) { _ in
            logger.info("Displays woke — resuming")
        }
    }
}
