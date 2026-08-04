import SwiftUI
import OSLog

private let logger = Logger(subsystem: "com.nuochong.xulora", category: "App")

@main
struct XuloraApp: App {
    @State private var widgetManager = WidgetManager()
    @State private var layoutController = LayoutController()

    init() {
        AppLifecycle.setup()
        AppLifecycle.onTerminate = {
            PersistenceService.shared.save()
        }
    }

    var body: some Scene {
        MenuBarExtra("桌序", systemImage: "square.grid.3x3.topleft.filled") {
            MenuBarView(
                widgetManager: widgetManager,
                layoutController: layoutController
            )
        }
    }
}
