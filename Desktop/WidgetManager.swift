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

    /// Snap guide controller for grid snapping and alignment guides.
    private let snapGuide = SnapGuideController()

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
        if restored.isEmpty {
            firstLaunchLayout()
            logger.info("First launch: created \(self.widgets.count) default widget(s)")
        } else {
            logger.info("Restored \(restored.count) widget(s) from persistence")
        }
        // Populate snap guide with initial widget frames
        refreshSnapGuide()
    }

    // MARK: Factory methods

    func addFileWidget(title: String = "文件整理") {
        addWidget(kind: .file, title: title, defaultSize: (480, 360))
    }

    func addNoteWidget(title: String = "便签") {
        addWidget(kind: .note, title: title, defaultSize: (320, 192))
    }

    func addTodoWidget(title: String = "待办") {
        addWidget(kind: .todo, title: title, defaultSize: (350, 236))
    }

    func addCalculatorWidget(title: String = "计算器") {
        addWidget(kind: .calculator, title: title, defaultSize: (260, 320))
    }

    // MARK: Management

    func deleteWidget(_ id: UUID) {
        guard let widget = widgets.first(where: { $0.id == id }) else { return }
        widgetWindows[id]?.close()
        widgetWindows.removeValue(forKey: id)
        widgets.removeAll { $0.id == id }
        persistence.deleteWidget(widget)
        snapGuide.removeFrame(for: id)
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

        // Keep snap guide aligned with reality
        snapGuide.setFrame(
            NSRect(x: x, y: y, width: width, height: height),
            for: id
        )
    }

    /// Toggle edit mode for all widget windows.
    func setEditingMode(_ editing: Bool) {
        for (_, window) in widgetWindows {
            window.setMovable(editing)
            window.setEditingMode(editing)
        }
    }

    // MARK: First Launch Layout

    /// Create default widgets arranged in a 3-column grid filling the primary screen.
    private func firstLaunchLayout() {
        guard let screen = NSScreen.main else { return }
        let frame = screen.visibleFrame
        let margin: CGFloat = 64
        let gap: CGFloat = 24

        // 3-column grid: evenly divide available width
        let columnCount: CGFloat = 3
        let availableWidth = frame.width - 2 * margin - (columnCount - 1) * gap
        let colWidth = availableWidth / columnCount
        let colOrigins: [CGFloat] = (0..<Int(columnCount)).map { i in
            frame.minX + margin + CGFloat(i) * (colWidth + gap)
        }

        // Row 0 tallest height (File widget = 360)
        let row0Height: CGFloat = 360
        let row0Top = margin
        let row1Top = row0Top + row0Height + gap

        // (kind, title, width, height, col, row)
        let placements: [(WidgetKind, String, CGFloat, CGFloat, Int, Int)] = [
            (.file,       "文件整理", 480, 360, 0, 0),
            (.note,       "便签",     320, 192, 1, 0),
            (.todo,       "待办",     350, 236, 2, 0),
            (.calculator, "计算器",   260, 320, 1, 1),
        ]

        for (index, (kind, title, width, height, col, row)) in placements.enumerated() {
            let x = colOrigins[col] + (colWidth - width) / 2
            let topY = row == 0 ? row0Top : row1Top
            let y = frame.maxY - topY - height

            do {
                let widget = try WidgetInstance(
                    kind: kind,
                    title: title,
                    frameX: x,
                    frameY: y,
                    frameWidth: width,
                    frameHeight: height,
                    isLocked: false,
                    sortOrder: index
                )
                persistence.insertWidget(widget)
                widgets.append(widget)
                createWindow(for: widget)
            } catch {
                logger.error("Failed to create default widget '\(title)': \(error.localizedDescription)")
            }
        }

        persistence.save()
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
        let window = WidgetWindow(widgetInstance: widget, snapController: snapGuide)
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

    /// Rebuild all partner frames in the snap guide controller.
    private func refreshSnapGuide() {
        for widget in widgets {
            snapGuide.setFrame(
                NSRect(
                    x: widget.frameX,
                    y: widget.frameY,
                    width: widget.frameWidth,
                    height: widget.frameHeight
                ),
                for: widget.id
            )
        }
    }
}
