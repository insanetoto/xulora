// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Xulora",
    platforms: [
        .macOS("26.0")
    ],
    targets: [
        .executableTarget(
            name: "Xulora",
            path: ".",
            exclude: [
                "Resources",
                "Tests",
                "CLAUDE.md",
                "README.md",
                "Xulora-产品说明.md",
            ],
            sources: [
                "App/XuloraApp.swift",
                "App/MenuBarView.swift",
                "App/AppLifecycle.swift",
                "Desktop/WidgetManager.swift",
                "Desktop/WidgetWindow.swift",
                "Desktop/LayoutController.swift",
                "Models/WidgetInstance.swift",
                "Models/TodoItem.swift",
                "Models/PomodoroState.swift",
                "Models/FileWidgetConfiguration.swift",
                "Models/NoteRecord.swift",
                "FileOrganizer/FileWidgetView.swift",
                "FileOrganizer/FileOperationService.swift",
                "FileOrganizer/FolderObserver.swift",
                "FileOrganizer/FileDropHandler.swift",
                "FileOrganizer/FileConflictResolver.swift",
                "Widgets/NoteWidgetView.swift",
                "Widgets/TodoWidgetView.swift",
                "Widgets/ClockWidgetView.swift",
                "Widgets/PomodoroWidgetView.swift",
                "Services/PersistenceService.swift",
                "Services/NotificationService.swift",
                "Services/LoginItemService.swift",
            ],
            swiftSettings: [
                .enableUpcomingFeature("ExistentialAny"),
                .swiftLanguageMode(.v6)
            ]
        ),
        .testTarget(
            name: "XuloraTests",
            dependencies: ["Xulora"],
            path: "Tests"
        ),
    ]
)
