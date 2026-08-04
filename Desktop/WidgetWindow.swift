import AppKit
import SwiftUI
import OSLog

private let logger = Logger(subsystem: "com.nuochong.xulora", category: "WidgetWindow")

// MARK: - Edit State

/// Observable state bridge between AppKit window and SwiftUI view for edit mode.
@MainActor
final class EditState: ObservableObject {
    @Published var isEditing = false
}

// MARK: - Widget Window

/// A floating desktop window that hosts a widget's SwiftUI content.
/// Behaves: below normal apps, above desktop icons, not in Dock or Cmd+Tab.
@MainActor
final class WidgetWindow {
    /// One point above the desktop icon layer (kCGDesktopIconWindowLevel ≈ -1000).
    /// Ensures widgets sit above desktop icons but below normal application windows.
    static let desktopWidgetLevel = NSWindow.Level(rawValue: -999)

    private let nsWindow: NSWindow
    let widgetInstance: WidgetInstance
    let editState = EditState()

    /// Frame change debounce timer.
    private var frameChangeTimer: Timer?
    private let frameDebounceInterval: TimeInterval = 0.5

    // MARK: Callbacks

    var onDelete: ((UUID) -> Void)?
    var onDuplicate: ((UUID) -> Void)?
    var onFrameChange: ((UUID, NSRect) -> Void)?

    // MARK: Properties

    var isVisible: Bool { nsWindow.isVisible }

    // MARK: Init

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
        observeFrame()
    }

    private func configureWindow() {
        nsWindow.titlebarAppearsTransparent = true
        nsWindow.titleVisibility = .hidden
        nsWindow.isMovableByWindowBackground = !widgetInstance.isLocked
        nsWindow.level = Self.desktopWidgetLevel
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
            rootView: WidgetContainerView(
                widgetInstance: widgetInstance,
                editState: editState,
                onDelete: { [weak self] in
                    self?.onDelete?(self?.widgetInstance.id ?? UUID())
                },
                onDuplicate: { [weak self] in
                    self?.onDuplicate?(self?.widgetInstance.id ?? UUID())
                }
            )
        )
        hostView.frame = nsWindow.contentView?.bounds ?? .zero
        hostView.autoresizingMask = [.width, .height]
        nsWindow.contentView?.addSubview(hostView)
    }

    // MARK: Frame Observation

    /// Listen for window move/resize events with debounce, then persist via callback.
    private func observeFrame() {
        NotificationCenter.default.addObserver(
            forName: NSWindow.didMoveNotification,
            object: nsWindow,
            queue: .main
        ) { [weak self] _ in
            guard let self else { return }
            MainActor.assumeIsolated {
                self.scheduleFrameChange()
            }
        }

        NotificationCenter.default.addObserver(
            forName: NSWindow.didResizeNotification,
            object: nsWindow,
            queue: .main
        ) { [weak self] _ in
            guard let self else { return }
            MainActor.assumeIsolated {
                self.scheduleFrameChange()
            }
        }
    }

    private func scheduleFrameChange() {
        frameChangeTimer?.invalidate()
        frameChangeTimer = Timer.scheduledTimer(
            withTimeInterval: frameDebounceInterval,
            repeats: false
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.onFrameChange?(self.widgetInstance.id, self.nsWindow.frame)
            }
        }
    }

    // MARK: Actions

    func show() {
        nsWindow.orderFront(nil)
    }

    func hide() {
        nsWindow.orderOut(nil)
    }

    func close() {
        frameChangeTimer?.invalidate()
        nsWindow.close()
    }

    func setFrame(_ rect: NSRect) {
        nsWindow.setFrame(rect, display: true, animate: false)
    }

    func setMovable(_ movable: Bool) {
        nsWindow.isMovableByWindowBackground = movable
    }

    func setEditingMode(_ editing: Bool) {
        editState.isEditing = editing
    }
}

// MARK: - Widget Container View

/// Root SwiftUI container for a widget window.
/// Routes to the correct widget view based on `widgetKind`,
/// and renders edit-mode border overlay + context menu.
struct WidgetContainerView: View {
    let widgetInstance: WidgetInstance
    @ObservedObject var editState: EditState

    var onDelete: (() -> Void)?
    var onDuplicate: (() -> Void)?

    var body: some View {
        contentView
            .overlay(editBorder)
            .contextMenu {
                if editState.isEditing {
                    Button("复制") { onDuplicate?() }
                    Divider()
                    Button("删除") { onDelete?() }
                }
            }
    }

    @ViewBuilder
    private var contentView: some View {
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

    @ViewBuilder
    private var editBorder: some View {
        if editState.isEditing {
            RoundedRectangle(cornerRadius: widgetInstance.decodeAppearance().cornerRadius + 2)
                .stroke(Color.accentColor, lineWidth: 2)
                .allowsHitTesting(false)
        }
    }
}
