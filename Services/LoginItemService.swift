import Foundation
import ServiceManagement
import OSLog

private let logger = Logger(subsystem: "com.nuochong.xulora", category: "LoginItem")

/// Manages the "Launch at Login" system preference via SMAppService.
@MainActor
final class LoginItemService {
    static let shared = LoginItemService()

    var isEnabled: Bool {
        SMAppService.mainApp.status == .enabled
    }

    private init() {}

    func setEnabled(_ enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
                logger.info("Login item registered")
            } else {
                try SMAppService.mainApp.unregister()
                logger.info("Login item unregistered")
            }
        } catch {
            logger.error("Failed to toggle login item: \(error.localizedDescription)")
        }
    }
}
