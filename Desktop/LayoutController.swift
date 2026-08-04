import Foundation
import AppKit
import OSLog

private let logger = Logger(subsystem: "com.nuochong.xulora", category: "Layout")

/// Manages widget layout editing mode, offscreen recovery, and multi-display handling.
@MainActor
@Observable
final class LayoutController {
    private(set) var isEditing = false

    /// Toggle layout editing mode for all widget windows via the WidgetManager.
    func setEditingMode(_ editing: Bool, widgetManager: WidgetManager) {
        isEditing = editing
        widgetManager.setEditingMode(editing)
        logger.info("Layout editing mode: \(editing)")
    }

    /// Recover widgets that may have ended up offscreen (e.g., after display disconnect).
    func recoverOffscreenWidgets() {
        guard let screen = NSScreen.main else { return }
        let visibleFrame = screen.visibleFrame

        for window in NSApp.windows {
            let frame = window.frame
            let intersects = visibleFrame.intersection(frame)

            // Ensure at least 48pt of the widget is on screen
            if intersects.width < 48 || intersects.height < 48 {
                let newOrigin = NSPoint(
                    x: max(visibleFrame.minX + 50, min(frame.origin.x, visibleFrame.maxX - 100)),
                    y: max(visibleFrame.minY + 50, min(frame.origin.y, visibleFrame.maxY - 100))
                )
                window.setFrameOrigin(newOrigin)
                logger.info("Recovered offscreen widget to: (\(newOrigin.x), \(newOrigin.y))")
            }
        }
    }
}
