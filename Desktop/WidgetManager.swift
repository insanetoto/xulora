import Foundation
import AppKit
import OSLog
import SwiftData

private let logger = Logger(subsystem: "com.nuochong.xulora", category: "WidgetManager")

/// Central manager for widget lifecycle — create, delete, duplicate, and enumerate widgets.
@MainActor
@Observable
final class WidgetManager {
    private let persistence = PersistenceService.shared

    private(set) var widgets: [WidgetInstance] = []
    private var widgetWindows: [UUID: WidgetWindow] = [:]

    var areAllLocked: Bool {
        widgets.allSatisfy(\.isLocked)
    }

    var areAllVisible: Bool {
        widgetWindows.values.allSatisfy { $0.isVisible }
    }

    // MARK: Init — restore persisted widgets

    init() {
        let restored = persistence.fetchAllWidgets()
        widgets = restored
        for widget in restored {
            createWindow(for: widget)
        }
        if !restored.isEmpty {
            logger.info("Restored \(restored.count) widget(s) from persistence")
        }
    }

    // MARK: Factory methods

    func addFileWidget(title: String = "文件整理") {
        addWidget(kind: .file, title: title, defaultSize: (360, 400))
    }

    func addNoteWidget(title: String = "便签") {
        addWidget(kind: .note, title: title, defaultSize: (300, 300))
    }

    func addTodoWidget(title: String = "待办") {
        addWidget(kind: .todo, title: title, defaultSize: (280, 350))
    }

    func addClockWidget(title: String = "时钟") {
        addWidget(kind: .clock, title: title, defaultSize: (220, 160))
    }

    func addPomodoroWidget(title: String = "番茄钟") {
        addWidget(kind: .pomodoro, title: title, defaultSize: (220, 220))
    }

    // MARK: Management

    func deleteWidget(_ id: UUID) {
        guard let widget = widgets.first(where: { $0.id == id }) else { return }
        widgetWindows[id]?.close()
        widgetWindows.removeValue(forKey: id)
        widgets.removeAll { $0.id == id }
        persistence.deleteWidget(widget)
    }

    func duplicateWidget(_ id: UUID) {
        guard let original = widgets.first(where: { $0.id == id }) else { return }

        let newID = UUID()
        let offset: Double = 30

        do {
            let copy = try WidgetInstance(
                id: newID,
                kind: original.widgetKind ?? .file,
                title: original.title + " 拷贝",
                frameX: original.frameX + offset,
                frameY: original.frameY + offset,
                frameWidth: original.frameWidth,
                frameHeight: original.frameHeight,
                screenID: original.screenID,
                isLocked: false,
                appearance: original.decodeAppearance(),
                configuration: original.configurationData,
                sortOrder: widgets.count
            )
            persistence.insertWidget(copy)
            widgets.append(copy)
            createWindow(for: copy)
        } catch {
            logger.error("Failed to duplicate widget: \(error.localizedDescription)")
        }
    }

    func setAllLocked(_ locked: Bool) {
        for widget in widgets {
            widget.isLocked = locked
        }
        persistence.save()
    }

    func setAllVisible(_ visible: Bool) {
        for (_, window) in widgetWindows {
            if visible {
                window.show()
            } else {
                window.hide()
            }
        }
    }

    /// Update persisted frame for a widget and save.
    func updateWidgetFrame(id: UUID, x: Double, y: Double, width: Double, height: Double) {
        guard let widget = widgets.first(where: { $0.id == id }) else { return }
        widget.frameX = x
        widget.frameY = y
        widget.frameWidth = width
        widget.frameHeight = height
        widget.updatedAt = Date()
        persistence.save()
    }

    /// Toggle edit mode for all widget windows.
    func setEditingMode(_ editing: Bool) {
        for (_, window) in widgetWindows {
            window.setMovable(editing)
            window.setEditingMode(editing)
        }
    }

    // MARK: Internal

    private func addWidget(kind: WidgetKind, title: String, defaultSize: (CGFloat, CGFloat)) {
        do {
            let widget = try WidgetInstance(
                kind: kind,
                title: title,
                frameX: 200 + Double(widgets.count) * 40,
                frameY: 200 + Double(widgets.count) * 40,
                frameWidth: Double(defaultSize.0),
                frameHeight: Double(defaultSize.1),
                sortOrder: widgets.count
            )
            persistence.insertWidget(widget)
            widgets.append(widget)
            createWindow(for: widget)
        } catch {
            logger.error("Failed to create widget: \(error.localizedDescription)")
        }
    }

    private func createWindow(for widget: WidgetInstance) {
        let window = WidgetWindow(widgetInstance: widget)
        widgetWindows[widget.id] = window

        // Sync frame changes back to persistence
        window.onFrameChange = { [weak self] id, frame in
            self?.updateWidgetFrame(
                id: id,
                x: frame.origin.x,
                y: frame.origin.y,
                width: frame.size.width,
                height: frame.size.height
            )
        }

        window.onDelete = { [weak self] id in
            self?.deleteWidget(id)
        }

        window.onDuplicate = { [weak self] id in
            self?.duplicateWidget(id)
        }

        window.show()
    }
}
