import SwiftUI
import AppKit
import UniformTypeIdentifiers
import QuickLookThumbnailing
import OSLog

private let logger = Logger(subsystem: "com.nuochong.xulora", category: "FileWidget")

/// Displays the contents of a bound real folder as a desktop widget.
/// Supports drag-and-drop from Finder with real-time folder monitoring.
struct FileWidgetView: View {
    let widgetInstance: WidgetInstance

    @State private var config: FileWidgetConfiguration = FileWidgetConfiguration()
    @State private var fileURLs: [URL] = []
    @State private var isLoading = false
    @State private var isDropTarget = false
    @State private var dropModifier: DragModifier = .move
    @State private var displayMode: FileDisplayMode = .grid
    @State private var sortMode: FileSortMode = .modificationDateDescending

    private var appearance: WidgetAppearance {
        widgetInstance.decodeAppearance()
    }

    /// Resolved folder URL from the security-scoped bookmark.
    private var boundFolderURL: URL? {
        guard let bookmark = config.bookmarkData else { return nil }
        var isStale = false
        return try? URL(
            resolvingBookmarkData: bookmark,
            options: .withSecurityScope,
            bookmarkDataIsStale: &isStale
        )
    }

    /// Sorted file URLs based on current sort mode.
    private var sortedFileURLs: [URL] {
        switch sortMode {
        case .nameAscending:
            return fileURLs.sorted {
                $0.lastPathComponent.localizedStandardCompare($1.lastPathComponent) == .orderedAscending
            }
        case .modificationDateDescending:
            return fileURLs.sorted {
                let a = (try? $0.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? Date.distantPast
                let b = (try? $1.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? Date.distantPast
                return a > b
            }
        case .kind:
            return fileURLs.sorted {
                let extA = $0.pathExtension
                let extB = $1.pathExtension
                if extA == extB {
                    return $0.lastPathComponent.localizedStandardCompare($1.lastPathComponent) == .orderedAscending
                }
                return extA.localizedStandardCompare(extB) == .orderedAscending
            }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            WidgetTitleBar(title: widgetInstance.title) {
                HStack(spacing: XuloraSpacing.sm) {
                    Button {
                        toggleDisplayMode()
                    } label: {
                        Image(systemName: displayMode == .grid ? "list.bullet" : "square.grid.2x2")
                    }
                    .buttonStyle(.plain)
                    .help(displayMode == .grid ? "切换为列表视图" : "切换为网格视图")

                    Menu {
                        sortModeMenu
                    } label: {
                        Image(systemName: "arrow.up.arrow.down")
                    }
                    .buttonStyle(.plain)
                    .help("排序方式")

                    Button {
                        openBoundFolder()
                    } label: {
                        Image(systemName: "folder")
                    }
                    .buttonStyle(.plain)
                    .help("在 Finder 中打开文件夹")
                }
            }

            Divider()

            // Content
            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if fileURLs.isEmpty {
                emptyStateView
            } else if displayMode == .grid {
                fileGridView
            } else {
                fileListView
            }

            // Footer status
            HStack {
                Text("\(fileURLs.count) 个项目")
                    .font(XuloraTypography.secondary)
                    .foregroundStyle(.secondary)
                Spacer()
                if isDropTarget {
                    Text(dropModifier == .copy ? "松开以复制" : "松开以移动")
                        .font(XuloraTypography.secondary)
                        .foregroundStyle(Color.accentColor)
                }
            }
            .padding(.horizontal, XuloraSpacing.xxl)
            .padding(.vertical, XuloraSpacing.sm)
        }
        .background(WidgetBackground(appearance: appearance))
        .overlay(dropBorder)
        .onDrop(of: [.fileURL], delegate: FileWidgetDropDelegate(
            view: self,
            isTarget: $isDropTarget,
            modifier: $dropModifier
        ))
        .onAppear {
            loadConfiguration()
        }
        .onDisappear {
            stopObserving()
        }
    }

    // MARK: Sort Mode Menu

    @ViewBuilder
    private var sortModeMenu: some View {
        Button {
            setSortMode(.nameAscending)
        } label: {
            HStack {
                Text("按名称排序")
                if sortMode == .nameAscending {
                    Image(systemName: "checkmark")
                }
            }
        }
        Button {
            setSortMode(.modificationDateDescending)
        } label: {
            HStack {
                Text("按修改时间排序")
                if sortMode == .modificationDateDescending {
                    Image(systemName: "checkmark")
                }
            }
        }
        Button {
            setSortMode(.kind)
        } label: {
            HStack {
                Text("按类型排序")
                if sortMode == .kind {
                    Image(systemName: "checkmark")
                }
            }
        }
    }

    // MARK: Drop Visual Feedback

    @ViewBuilder
    private var dropBorder: some View {
        if isDropTarget {
            RoundedRectangle(cornerRadius: appearance.cornerRadius)
                .stroke(Color.accentColor, lineWidth: XuloraBorder.dragTargetWidth)
                .allowsHitTesting(false)
        }
    }

    // MARK: Subviews

    private var emptyStateView: some View {
        VStack(spacing: XuloraSpacing.md) {
            Image(systemName: "tray")
                .font(.system(size: 32))
                .foregroundStyle(.secondary)
            if config.bookmarkData == nil {
                Text("将文件拖到这里，或绑定一个文件夹")
                    .font(XuloraTypography.body)
                    .foregroundStyle(.secondary)
                Text("请先绑定文件夹")
                    .font(XuloraTypography.secondary)
                    .foregroundStyle(.tertiary)
                Button("选择文件夹") {
                    selectFolder()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            } else {
                Text("拖入文件以整理")
                    .font(XuloraTypography.body)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .widgetContentPadding()
    }

    // MARK: Grid View

    private var fileGridView: some View {
        ScrollView {
            LazyVGrid(
                columns: [GridItem(.adaptive(minimum: 100), spacing: XuloraSpacing.md)],
                spacing: XuloraSpacing.md
            ) {
                ForEach(sortedFileURLs, id: \.self) { url in
                    FileGridItem(url: url)
                }
            }
            .padding(XuloraSpacing.md)
        }
    }

    // MARK: List View

    private var fileListView: some View {
        List(sortedFileURLs, id: \.self) { url in
            FileListRow(url: url)
        }
        .listStyle(.plain)
    }

    // MARK: Actions

    private func loadConfiguration() {
        guard let data = try? JSONDecoder().decode(
            FileWidgetConfiguration.self,
            from: widgetInstance.configurationData
        ) else { return }
        config = data
        displayMode = data.displayMode
        sortMode = data.sortMode
        loadFiles()
        startObserving()
    }

    private func loadFiles() {
        guard let url = boundFolderURL else { return }

        guard url.startAccessingSecurityScopedResource() else { return }
        defer { url.stopAccessingSecurityScopedResource() }

        fileURLs = (try? FileManager.default.contentsOfDirectory(
            at: url,
            includingPropertiesForKeys: [.contentModificationDateKey],
            options: .skipsHiddenFiles
        )) ?? []
    }

    private func toggleDisplayMode() {
        displayMode = displayMode == .grid ? .list : .grid
        saveConfiguration()
    }

    private func setSortMode(_ mode: FileSortMode) {
        sortMode = mode
        saveConfiguration()
    }

    private func saveConfiguration() {
        config.displayMode = displayMode
        config.sortMode = sortMode
        if let encoded = try? JSONEncoder().encode(config) {
            widgetInstance.configurationData = encoded
        }
        PersistenceService.shared.save()
    }

    private func openBoundFolder() {
        guard let bookmark = config.bookmarkData else { return }
        var isStale = false
        guard let url = try? URL(
            resolvingBookmarkData: bookmark,
            options: .withSecurityScope,
            bookmarkDataIsStale: &isStale
        ) else { return }

        NSWorkspace.shared.open(url)
    }

    private func selectFolder() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.prompt = "绑定此文件夹"
        panel.message = "选择一个文件夹以在桌面上显示其内容"

        guard panel.runModal() == .OK,
              let url = panel.url else { return }

        guard let bookmark = try? url.bookmarkData(
            options: .withSecurityScope,
            includingResourceValuesForKeys: nil,
            relativeTo: nil
        ) else { return }

        stopObserving()

        config.bookmarkData = bookmark
        widgetInstance.title = url.lastPathComponent

        if let encoded = try? JSONEncoder().encode(config) {
            widgetInstance.configurationData = encoded
        }

        PersistenceService.shared.save()
        loadFiles()
        startObserving()
    }

    // MARK: Folder Observation

    @State private var folderObserver: FolderObserver?

    private func startObserving() {
        guard let url = boundFolderURL else { return }
        guard url.startAccessingSecurityScopedResource() else { return }

        folderObserver = FolderObserver(folderURL: url) {
            Task { @MainActor in
                url.stopAccessingSecurityScopedResource()
                self.loadFiles()
            }
        }
        folderObserver?.start()
    }

    private func stopObserving() {
        folderObserver?.stop()
        folderObserver = nil
    }

    // MARK: Drop Handling

    func acceptDrop(_ urls: [URL], isCopy: Bool) {
        guard let destination = boundFolderURL else { return }
        guard destination.startAccessingSecurityScopedResource() else { return }

        Task {
            for source in urls {
                do {
                    if isCopy {
                        _ = try FileOperationService.shared.copyItem(from: source, to: destination)
                    } else {
                        _ = try FileOperationService.shared.moveItem(from: source, to: destination)
                    }
                } catch {
                    logger.error("Drop failed for \(source.lastPathComponent): \(error.localizedDescription)")
                }
            }
            destination.stopAccessingSecurityScopedResource()
            loadFiles()
        }
    }
}

// MARK: - Grid Item

private struct FileGridItem: View {
    let url: URL

    @State private var thumbnail: NSImage?

    private let thumbnailSize = CGSize(width: 128, height: 128)

    var body: some View {
        VStack(spacing: 4) {
            // Thumbnail
            ZStack {
                if let thumbnail {
                    Image(nsImage: thumbnail)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                } else {
                    Image(nsImage: NSWorkspace.shared.icon(forFile: url.path))
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                }
            }
            .frame(height: 80)

            // Filename
            Text(url.lastPathComponent)
                .font(XuloraTypography.secondary)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .foregroundStyle(.primary)
        }
        .frame(maxWidth: .infinity)
        .padding(6)
        .background(
            RoundedRectangle(cornerRadius: XuloraRadius.item)
                .fill(Color.primary.opacity(0.04))
        )
        .contentShape(Rectangle())
        .onTapGesture(count: 2) {
            NSWorkspace.shared.open(url)
        }
        .contextMenu {
            fileContextMenu
        }
        .task {
            thumbnail = await generateThumbnail(for: url)
        }
    }

    @ViewBuilder
    private var fileContextMenu: some View {
        Button("打开") { NSWorkspace.shared.open(url) }
        Button("在 Finder 中显示") {
            NSWorkspace.shared.activateFileViewerSelecting([url])
        }
        Divider()
        Button("移到废纸篓") {
            try? FileManager.default.trashItem(at: url, resultingItemURL: nil)
        }
    }
}

// MARK: - List Row

private struct FileListRow: View {
    let url: URL

    var body: some View {
        HStack {
            Image(nsImage: NSWorkspace.shared.icon(forFile: url.path))
                .resizable()
                .frame(width: 20, height: 20)

            Text(url.lastPathComponent)
                .lineLimit(1)

            Spacer()
        }
        .contentShape(Rectangle())
        .onTapGesture(count: 2) {
            NSWorkspace.shared.open(url)
        }
        .contextMenu {
            Button("打开") { NSWorkspace.shared.open(url) }
            Button("在 Finder 中显示") {
                NSWorkspace.shared.activateFileViewerSelecting([url])
            }
            Divider()
            Button("移到废纸篓") {
                try? FileManager.default.trashItem(at: url, resultingItemURL: nil)
            }
        }
    }
}

// MARK: - Thumbnail Generation

private func generateThumbnail(for url: URL) async -> NSImage? {
    let request = QLThumbnailGenerator.Request(
        fileAt: url,
        size: CGSize(width: 128, height: 128),
        scale: NSScreen.main?.backingScaleFactor ?? 2.0,
        representationTypes: .thumbnail
    )

    return await withCheckedContinuation { continuation in
        QLThumbnailGenerator.shared.generateRepresentations(for: request) { representation, _, _ in
            continuation.resume(returning: representation?.nsImage)
        }
    }
}

// MARK: - Drop Modifier

enum DragModifier {
    case move, copy
}

// MARK: - Drop Delegate

private struct FileWidgetDropDelegate: DropDelegate {
    let view: FileWidgetView
    @Binding var isTarget: Bool
    @Binding var modifier: DragModifier

    func validateDrop(info: DropInfo) -> Bool {
        true
    }

    func dropEntered(info: DropInfo) {
        isTarget = true
    }

    func dropExited(info: DropInfo) {
        isTarget = false
    }

    func dropUpdated(info: DropInfo) -> DropProposal? {
        let isCopy = info.location.isOptionKeyPressed
        modifier = isCopy ? .copy : .move
        return DropProposal(operation: isCopy ? .copy : .move)
    }

    func performDrop(info: DropInfo) -> Bool {
        isTarget = false

        let isCopy = info.location.isOptionKeyPressed
        let providers = info.itemProviders(for: [.fileURL])

        Task { @MainActor in
            var urls: [URL] = []
            let typeId = UTType.fileURL.identifier

            for provider in providers {
                let url: URL? = await withUnsafeContinuation { continuation in
                    provider.loadItem(forTypeIdentifier: typeId, options: nil) { item, _ in
                        if let data = item as? Data,
                           let url = URL(dataRepresentation: data, relativeTo: nil) {
                            continuation.resume(returning: url)
                        } else {
                            continuation.resume(returning: nil)
                        }
                    }
                }
                if let url { urls.append(url) }
            }

            view.acceptDrop(urls, isCopy: isCopy)
        }

        return true
    }
}

// MARK: - Option Key Detection

private extension CGPoint {
    var isOptionKeyPressed: Bool {
        NSEvent.modifierFlags.contains(.option)
    }
}
