import Foundation
import SwiftData
import OSLog

private let logger = Logger(subsystem: "com.nuochong.xulora", category: "Persistence")

/// Central persistence service using SwiftData.
/// Stores widget layout, todo items, note records, and pomodoro state.
@MainActor
final class PersistenceService {
    static let shared = PersistenceService()

    let container: ModelContainer

    private init() {
        // Explicit schema definition ensures clean migration paths
        let schema = Schema([
            WidgetInstance.self,
        ])

        let config = ModelConfiguration(
            "Xulora",
            schema: schema,
            isStoredInMemoryOnly: false
        )

        do {
            container = try ModelContainer(for: schema, configurations: [config])
            logger.info("Persistence container initialized")
        } catch {
            logger.fault("Failed to create ModelContainer: \(error.localizedDescription)")
            fatalError("Cannot initialize persistence: \(error.localizedDescription)")
        }
    }

    // MARK: Context

    var mainContext: ModelContext {
        container.mainContext
    }

    // MARK: Save

    func save() {
        do {
            try mainContext.save()
        } catch {
            logger.error("Save failed: \(error.localizedDescription)")
        }
    }

    // MARK: Widget CRUD

    func fetchAllWidgets() -> [WidgetInstance] {
        let descriptor = FetchDescriptor<WidgetInstance>(
            sortBy: [SortDescriptor(\.sortOrder)]
        )
        return (try? mainContext.fetch(descriptor)) ?? []
    }

    func insertWidget(_ widget: WidgetInstance) {
        mainContext.insert(widget)
        save()
    }

    func deleteWidget(_ widget: WidgetInstance) {
        mainContext.delete(widget)
        save()
    }
}
