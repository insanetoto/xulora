import SwiftUI

/// Displays the contents of a bound real folder as a desktop widget.
struct FileWidgetView: View {
    let widgetInstance: WidgetInstance

    @State private var config: FileWidgetConfiguration = FileWidgetConfiguration()
    @State private var fileURLs: [URL] = []
    @State private var isLoading = false

    private var appearance: WidgetAppearance {
        widgetInstance.decodeAppearance()
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            WidgetTitleBar(title: widgetInstance.title) {
                Button {
                    openBoundFolder()
                } label: {
                    Image(systemName: "folder")
                }
                .buttonStyle(.plain)
                .help("在 Finder 中打开文件夹")
            }

            Divider()

            // Content
            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if fileURLs.isEmpty {
                emptyStateView
            } else {
                fileListView
            }

            // Footer status
            HStack {
                Text("\(fileURLs.count) 个项目")
                    .font(XuloraTypography.secondary)
                    .foregroundStyle(.secondary)
                Spacer()
            }
            .padding(.horizontal, XuloraSpacing.xxl)
            .padding(.vertical, XuloraSpacing.sm)
        }
        .background(WidgetBackground(appearance: appearance))
        .onAppear {
            loadConfiguration()
        }
    }

    // MARK: Subviews

    private var emptyStateView: some View {
        VStack(spacing: XuloraSpacing.md) {
            Image(systemName: "tray")
                .font(.system(size: 32))
                .foregroundStyle(.secondary)
            Text("拖入文件以整理")
                .font(XuloraTypography.body)
                .foregroundStyle(.secondary)
            if config.bookmarkData == nil {
                Text("请先绑定文件夹")
                    .font(XuloraTypography.secondary)
                    .foregroundStyle(.tertiary)
                Button("选择文件夹") {
                    selectFolder()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .widgetContentPadding()
    }

    private var fileListView: some View {
        List(fileURLs, id: \.self) { url in
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
        .listStyle(.plain)
    }

    // MARK: Actions

    private func loadConfiguration() {
        guard let data = try? JSONDecoder().decode(
            FileWidgetConfiguration.self,
            from: widgetInstance.configurationData
        ) else { return }
        config = data
        loadFiles()
    }

    private func loadFiles() {
        guard let bookmark = config.bookmarkData else { return }
        var isStale = false
        guard let url = try? URL(
            resolvingBookmarkData: bookmark,
            options: .withSecurityScope,
            bookmarkDataIsStale: &isStale
        ) else { return }

        guard url.startAccessingSecurityScopedResource() else { return }
        defer { url.stopAccessingSecurityScopedResource() }

        fileURLs = (try? FileManager.default.contentsOfDirectory(
            at: url,
            includingPropertiesForKeys: [.contentModificationDateKey],
            options: .skipsHiddenFiles
        )) ?? []
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
        // Stub: will use NSOpenPanel in FileOperationService
    }
}
