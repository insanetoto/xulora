import Foundation
import SwiftData

@Model
final class TodoItem {
    var id: UUID
    var widgetID: UUID
    var title: String
    var isCompleted: Bool
    var sortOrder: Int
    var createdAt: Date
    var completedAt: Date?

    init(
        id: UUID = UUID(),
        widgetID: UUID,
        title: String,
        isCompleted: Bool = false,
        sortOrder: Int = 0
    ) {
        self.id = id
        self.widgetID = widgetID
        self.title = title
        self.isCompleted = isCompleted
        self.sortOrder = sortOrder
        self.createdAt = Date()
        self.completedAt = nil
    }

    func toggle() {
        isCompleted.toggle()
        completedAt = isCompleted ? Date() : nil
    }
}
