# Xulora (桌序)

> macOS 桌面工作台 — 以文件整理为核心，包含便签、待办、时钟与番茄钟的私人工具

## Quick Reference

| Key | Value |
|-----|-------|
| Product | 桌序 · Xulora |
| App Name | 桌序 |
| Bundle ID | `com.nuochong.xulora` |
| Platform | macOS 26+ (dev on macOS 27) |
| Language | Swift 6 |
| UI | SwiftUI + AppKit |
| Persistence | SwiftData |
| Min version | macOS 26.0 |
| Xcode | 27 |

## Build & Run

```bash
# Build from CLI
swift build

# Run from CLI
swift run

# Open in Xcode
open Package.swift

# Build in Xcode
xcodebuild -scheme Xulora -configuration Debug build

# Run tests
swift test
```

## Architecture

```
User Command → MenuBarExtra → WidgetManager → WidgetWindow → Widget Views
                                    ↕
                            LayoutController
                            PersistenceService
```

- **Menu bar app**: No main window. All interaction starts from the menu bar.
- **Desktop widgets**: Each widget is a borderless `NSWindow` with SwiftUI content. Windows sit below normal apps, above desktop.
- **WidgetManager**: Central lifecycle controller — create, delete, duplicate widgets. Manages window-to-widget mapping.
- **LayoutController**: Editing mode toggle, offscreen recovery, multi-display coordination.
- **File operations**: Mandatory safety rules — no silent overwrite, no permanent delete, trash only. All ops through `FileManager`, never shell.
- **SwiftData**: Persists widget layout, todo items, notes, pomodoro state. File contents are NOT stored in the database — only folder references and display preferences.

## Project Structure

```
Xulora/
├── Package.swift                # SPM manifest (Swift 6, macOS 26)
├── Resources/Info.plist         # App metadata (LSUIElement=true)
├── App/                         # Entry point & menu bar
│   ├── XuloraApp.swift          # @main app, MenuBarExtra
│   ├── MenuBarView.swift        # Menu bar content
│   └── AppLifecycle.swift       # Sleep/wake/terminate observers
├── Desktop/                     # Widget window management
│   ├── WidgetManager.swift      # Widget lifecycle & factory
│   ├── WidgetWindow.swift       # NSWindow wrapper + SwiftUI host
│   └── LayoutController.swift   # Edit mode, offscreen recovery
├── Models/                      # SwiftData models & config
│   ├── WidgetInstance.swift     # Core widget model
│   ├── TodoItem.swift           # Todo task model
│   ├── PomodoroState.swift      # Pomodoro timer state
│   ├── FileWidgetConfiguration.swift
│   └── NoteRecord.swift         # Note content model
├── FileOrganizer/               # File widget implementation
│   ├── FileWidgetView.swift     # File list/grid view
│   ├── FileOperationService.swift  # Move/copy/trash operations
│   ├── FolderObserver.swift     # FSEvents debounced monitoring
│   ├── FileDropHandler.swift    # Finder drag-and-drop
│   └── FileConflictResolver.swift  # Name collision resolution
├── Widgets/                     # Non-file widget views
│   ├── NoteWidgetView.swift     # Rich text note
│   ├── TodoWidgetView.swift     # Task list
│   ├── ClockWidgetView.swift    # Time and date
│   └── PomodoroWidgetView.swift # Focus timer
├── Services/                    # Cross-cutting services
│   ├── PersistenceService.swift # SwiftData container & CRUD
│   ├── NotificationService.swift   # UserNotifications wrapper
│   └── LoginItemService.swift   # SMAppService launch-at-login
└── Tests/
    └── XuloraTests.swift
```

## Development Phases

| Phase | Focus | Exit Criteria |
|-------|-------|---------------|
| P0 | Window behavior | Desktop window experience stable |
| P1 | File widget prototype | Single file widget safe for real files |
| P2 | Full file capabilities | Multi-widget, cross-drag, conflict handling |
| P3 | Remaining widgets | Notes, todos, clock, pomodoro complete |
| P4 | Self-use validation | 7-day real-world usage, no data loss |

## Key Design Decisions

1. **No App Sandbox** (V0.1): Simplifies arbitrary folder access
2. **No network**: Zero network calls, no cloud, no accounts
3. **No root/shell ops**: FileManager only, no shell commands
4. **Trash only**: Never permanently delete files
5. **No silent overwrite**: Always prompt on name conflicts
6. **Absolute time tracking**: Pomodoro uses target time, not cumulative ticks

## V0.1 Scope

- 5 widget types: File, Note, Todo, Clock, Pomodoro
- Menu bar app with LSUIElement
- Local persistence via SwiftData
- No App Store, no Sandbox, no network, no accounts
