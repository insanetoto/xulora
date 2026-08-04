import AppKit
import SwiftUI
import OSLog

private let logger = Logger(subsystem: "com.nuochong.xulora", category: "WidgetWindow")

/// A floating desktop window that hosts a widget's SwiftUI content.
/// Behaves: below normal apps, above desktop icons, not in Dock or Cmd+Tab.
@MainActor
final class WidgetWindow {
    private let nsWindow: NSWindow
    let widgetInstance: WidgetInstance

    var isVisible: Bool { nsWindow.isVisible }

    init(widgetInstance: WidgetInstance) {
        self.widgetInstance = widgetInstance

        let rect = NSRect(
            x: widgetInstance.frameX,
            y: widgetInstance.frameY,
            width: widgetInstance.frameWidth,
            height: widgetInstance.frameHeight
        )

        nsWindow = NSWindow(
            contentRect: rect,
            styleMask: [.borderless, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )

        configureWindow()
        setContent()
    }

    private func configureWindow() {
        nsWindow.titlebarAppearsTransparent = true
        nsWindow.titleVisibility = .hidden
        nsWindow.isMovableByWindowBackground = widgetInstance.isLocked ? false : true
        // Place widget below normal windows (0) but above desktop background
        // kCGDesktopWindowLevel and kCGDesktopIconWindowLevel are unavailable in macOS 26 SDK
        nsWindow.level = NSWindow.Level(rawValue: -1000)
        nsWindow.collectionBehavior = [
            .canJoinAllSpaces,
            .stationary,
            .ignoresCycle
        ]
        nsWindow.isOpaque = false
        nsWindow.backgroundColor = .clear
        nsWindow.hasShadow = true
        nsWindow.isReleasedWhenClosed = false
        nsWindow.setContentSize(
            NSSize(width: widgetInstance.frameWidth, height: widgetInstance.frameHeight)
        )
    }

    private func setContent() {
        let hostView = NSHostingView(
            rootView: WidgetContainerView(widgetInstance: widgetInstance)
        )
        hostView.frame = nsWindow.contentView?.bounds ?? .zero
        hostView.autoresizingMask = [.width, .height]
        nsWindow.contentView?.addSubview(hostView)
    }

    // MARK: Actions

    func show() {
        nsWindow.makeKeyAndOrderFront(nil)
    }

    func hide() {
        nsWindow.orderOut(nil)
    }

    func close() {
        nsWindow.close()
    }

    func setFrame(_ rect: NSRect) {
        nsWindow.setFrame(rect, display: true, animate: false)
    }

    func setMovable(_ movable: Bool) {
        nsWindow.isMovableByWindowBackground = movable
    }
}

/// Root SwiftUI container for a widget window.
struct WidgetContainerView: View {
    let widgetInstance: WidgetInstance

    var body: some View {
        Group {
            switch widgetInstance.widgetKind {
            case .file:
                FileWidgetView(widgetInstance: widgetInstance)
            case .note:
                NoteWidgetView(widgetInstance: widgetInstance)
            case .todo:
                TodoWidgetView(widgetInstance: widgetInstance)
            case .clock:
                ClockWidgetView(widgetInstance: widgetInstance)
            case .pomodoro:
                PomodoroWidgetView(widgetInstance: widgetInstance)
            case .none:
                EmptyView()
            }
        }
    }
}
