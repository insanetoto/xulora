import Foundation
import AppKit
import OSLog
import SwiftData

private let logger = Logger(subsystem: "com.nuochong.xulora", category: "WidgetManager")

/// Central manager for widget lifecycle — create, delete, duplicate, and enumerate widgets.
@MainActor
@Observable
final class WidgetManager {
    private(set) var widgets: [WidgetInstance] = []
    private var widgetWindows: [UUID: WidgetWindow] = [:]

    var areAllLocked: Bool {
        widgets.allSatisfy(\.isLocked)
    }

    var areAllVisible: Bool {
        widgetWindows.values.allSatisfy { $0.isVisible }
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
        widgetWindows[id]?.close()
        widgetWindows.removeValue(forKey: id)
        widgets.removeAll { $0.id == id }
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
            widgets.append(widget)
            createWindow(for: widget)
        } catch {
            logger.error("Failed to create widget: \(error.localizedDescription)")
        }
    }

    private func createWindow(for widget: WidgetInstance) {
        let window = WidgetWindow(widgetInstance: widget)
        widgetWindows[widget.id] = window
        window.show()
    }
}
