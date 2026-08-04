import Foundation
import SwiftData

/// Widget kind identifiers.
enum WidgetKind: String, Codable, CaseIterable {
    case file = "file"
    case note = "note"
    case todo = "todo"
    case clock = "clock"
    case pomodoro = "pomodoro"
}

/// Appearance configuration shared across all widget types.
struct WidgetAppearance: Codable, Equatable {
    var backgroundColorHex: String? = nil
    var cornerRadius: Double = 16
    var alpha: Double = 0.95
    var spacing: WidgetSpacing = .standard
    var appearanceMode: AppearanceMode = .system
}

enum WidgetSpacing: String, Codable, CaseIterable {
    case compact, standard, relaxed
}

enum AppearanceMode: String, Codable, CaseIterable {
    case light, dark, system
}

/// Main widget instance model — persisted via SwiftData.
@Model
final class WidgetInstance {
    var id: UUID
    var kind: String
    var title: String
    var frameX: Double
    var frameY: Double
    var frameWidth: Double
    var frameHeight: Double
    var screenID: String?
    var isLocked: Bool
    var appearanceData: Data
    var configurationData: Data
    var createdAt: Date
    var updatedAt: Date
    var sortOrder: Int

    var widgetKind: WidgetKind? {
        WidgetKind(rawValue: kind)
    }

    init(
        id: UUID = UUID(),
        kind: WidgetKind,
        title: String,
        frameX: Double = 100,
        frameY: Double = 100,
        frameWidth: Double = 320,
        frameHeight: Double = 400,
        screenID: String? = nil,
        isLocked: Bool = true,
        appearance: WidgetAppearance = WidgetAppearance(),
        configuration: Data = Data(),
        sortOrder: Int = 0
    ) throws {
        self.id = id
        self.kind = kind.rawValue
        self.title = title
        self.frameX = frameX
        self.frameY = frameY
        self.frameWidth = frameWidth
        self.frameHeight = frameHeight
        self.screenID = screenID
        self.isLocked = isLocked
        self.appearanceData = try JSONEncoder().encode(appearance)
        self.configurationData = configuration
        self.createdAt = Date()
        self.updatedAt = Date()
        self.sortOrder = sortOrder
    }

    func decodeAppearance() -> WidgetAppearance {
        (try? JSONDecoder().decode(WidgetAppearance.self, from: appearanceData))
            ?? WidgetAppearance()
    }
}
