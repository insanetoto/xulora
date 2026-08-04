import Foundation
import SwiftData

@Model
final class NoteRecord {
    var id: UUID
    var widgetID: UUID
    var title: String
    var bodyText: String
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        widgetID: UUID,
        title: String = "",
        bodyText: String = ""
    ) {
        self.id = id
        self.widgetID = widgetID
        self.title = title
        self.bodyText = bodyText
        self.updatedAt = Date()
    }
}
