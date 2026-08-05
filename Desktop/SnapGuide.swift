import AppKit
import Foundation

// MARK: - Snap Line

struct SnapLine: Equatable {
    enum Orientation: Equatable { case horizontal, vertical }
    let position: CGFloat
    let orientation: Orientation
    let start: CGFloat
    let end: CGFloat
}

// MARK: - Snappable Window

/// NSWindow subclass that snaps movement to an 8pt grid and supports
/// edge-alignment guide lines via a SnapGuideController.
final class SnappableWindow: NSWindow {
    weak var snapController: SnapGuideController?
    var widgetID: UUID?

    private var guideTimer: Timer?

    override func setFrameOrigin(_ point: NSPoint) {
        guard let controller = snapController, let id = widgetID else {
            super.setFrameOrigin(point)
            return
        }

        let proposed = NSRect(origin: point, size: frame.size)
        let result = controller.snapFrame(proposed, for: id)

        if result.lines.isEmpty {
            guideTimer?.invalidate()
            guideTimer = nil
            controller.hideGuideLines()
        } else {
            controller.showGuideLines(result.lines)
            // Debounce: hide guides 0.2s after last movement
            guideTimer?.invalidate()
            guideTimer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: false) { [weak self] _ in
                Task { @MainActor [weak self] in
                    self?.snapController?.hideGuideLines()
                }
            }
        }

        super.setFrameOrigin(result.frame.origin)
    }
}

// MARK: - Snap Guide Controller

/// Manages 8pt grid snapping, edge-alignment detection, and
/// visual guide line overlay during widget drag.
@MainActor
final class SnapGuideController {
    let gridSize: CGFloat = 8
    let alignmentThreshold: CGFloat = 6

    /// All partner widget frames keyed by widget ID.
    private var frames: [UUID: NSRect] = [:]

    private var guideWindow: GuideOverlayWindow?

    // MARK: Frame Tracking

    func setFrame(_ rect: NSRect, for id: UUID) {
        frames[id] = rect
    }

    func removeFrame(for id: UUID) {
        frames[id] = nil
    }

    // MARK: Snap Math

    func snapPoint(_ point: NSPoint) -> NSPoint {
        NSPoint(
            x: round(point.x / gridSize) * gridSize,
            y: round(point.y / gridSize) * gridSize
        )
    }

    /// Snap a proposed frame against the 8pt grid and partner widget edges.
    /// Returns the snapped frame and any alignment lines to draw.
    func snapFrame(_ proposed: NSRect, for movingID: UUID) -> (frame: NSRect, lines: [SnapLine]) {
        var snapped = proposed
        var lines: [SnapLine] = []

        // 1. Snap origin to 8pt grid
        snapped.origin = snapPoint(snapped.origin)

        // 2. Detect edge/center alignment with partner windows
        for (partnerID, partner) in frames {
            guard partnerID != movingID, !partner.isEmpty else { continue }

            // Vertical alignments: left, right, center-X
            if abs(snapped.minX - partner.minX) < alignmentThreshold {
                snapped.origin.x = partner.minX
                lines.append(SnapLine(
                    position: partner.minX, orientation: .vertical,
                    start: min(snapped.minY, partner.minY),
                    end: max(snapped.maxY, partner.maxY)
                ))
            } else if abs(snapped.maxX - partner.maxX) < alignmentThreshold {
                snapped.origin.x = partner.maxX - snapped.width
                lines.append(SnapLine(
                    position: partner.maxX, orientation: .vertical,
                    start: min(snapped.minY, partner.minY),
                    end: max(snapped.maxY, partner.maxY)
                ))
            } else if abs(snapped.midX - partner.midX) < alignmentThreshold {
                snapped.origin.x = partner.midX - snapped.width / 2
                lines.append(SnapLine(
                    position: partner.midX, orientation: .vertical,
                    start: min(snapped.minY, partner.minY),
                    end: max(snapped.maxY, partner.maxY)
                ))
            }

            // Horizontal alignments: bottom, top, center-Y
            if abs(snapped.minY - partner.minY) < alignmentThreshold {
                snapped.origin.y = partner.minY
                lines.append(SnapLine(
                    position: partner.minY, orientation: .horizontal,
                    start: min(snapped.minX, partner.minX),
                    end: max(snapped.maxX, partner.maxX)
                ))
            } else if abs(snapped.maxY - partner.maxY) < alignmentThreshold {
                snapped.origin.y = partner.maxY - snapped.height
                lines.append(SnapLine(
                    position: partner.maxY, orientation: .horizontal,
                    start: min(snapped.minX, partner.minX),
                    end: max(snapped.maxX, partner.maxX)
                ))
            } else if abs(snapped.midY - partner.midY) < alignmentThreshold {
                snapped.origin.y = partner.midY - snapped.height / 2
                lines.append(SnapLine(
                    position: partner.midY, orientation: .horizontal,
                    start: min(snapped.minX, partner.minX),
                    end: max(snapped.maxX, partner.maxX)
                ))
            }
        }

        return (snapped, lines)
    }

    // MARK: Guide Line Overlay

    func showGuideLines(_ lines: [SnapLine]) {
        if guideWindow == nil {
            guard let screen = NSScreen.main else { return }
            guideWindow = GuideOverlayWindow(contentRect: screen.frame)
        }
        guideWindow?.draw(lines: lines)
        guideWindow?.orderFront(nil)
    }

    func hideGuideLines() {
        guideWindow?.orderOut(nil)
    }
}

// MARK: - Guide Overlay Window

/// Transparent, non-interactive overlay for drawing alignment guide lines.
private final class GuideOverlayWindow: NSWindow {
    private let lineLayer = CAShapeLayer()

    init(contentRect: NSRect) {
        super.init(
            contentRect: contentRect,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        isOpaque = false
        backgroundColor = .clear
        level = NSWindow.Level(rawValue: -998) // just above widget level (-999)
        ignoresMouseEvents = true
        hasShadow = false
        isReleasedWhenClosed = false
        collectionBehavior = [.canJoinAllSpaces, .stationary]

        contentView?.wantsLayer = true
        contentView?.layer?.addSublayer(lineLayer)

        lineLayer.fillColor = nil
        lineLayer.strokeColor = NSColor.systemBlue.withAlphaComponent(0.7).cgColor
        lineLayer.lineWidth = 1
    }

    func draw(lines: [SnapLine]) {
        let path = CGMutablePath()
        for line in lines {
            switch line.orientation {
            case .horizontal:
                path.move(to: CGPoint(x: line.start, y: line.position))
                path.addLine(to: CGPoint(x: line.end, y: line.position))
            case .vertical:
                path.move(to: CGPoint(x: line.position, y: line.start))
                path.addLine(to: CGPoint(x: line.position, y: line.end))
            }
        }
        lineLayer.path = path
    }
}
