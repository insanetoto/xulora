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
                "Scripts",
                "CLAUDE.md",
                "README.md",
                "Xulora-产品说明.md",
                "Xulora-视觉设计规范.md",
                "Models/TodoItem.swift",
                "Models/NoteRecord.swift",
            ],
            sources: [
                "App/XuloraApp.swift",
                "App/MenuBarView.swift",
                "App/AppLifecycle.swift",
                "Desktop/WidgetManager.swift",
                "Desktop/WidgetWindow.swift",
                "Desktop/LayoutController.swift",
                "Models/WidgetInstance.swift",
                "Models/FileWidgetConfiguration.swift",
                "FileOrganizer/FileWidgetView.swift",
                "FileOrganizer/FileOperationService.swift",
                "FileOrganizer/FolderObserver.swift",
                "FileOrganizer/FileDropHandler.swift",
                "FileOrganizer/FileConflictResolver.swift",
                "Widgets/NoteWidgetView.swift",
                "Widgets/TodoWidgetView.swift",
                "Widgets/CalculatorWidgetView.swift",
                "Services/PersistenceService.swift",
                "Services/NotificationService.swift",
                "Services/LoginItemService.swift",
                "Services/DesignTokens.swift",
                "Services/VisualEffectView.swift",
                "Services/Color+Hex.swift",
                "Widgets/SharedWidgetViews.swift",
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
