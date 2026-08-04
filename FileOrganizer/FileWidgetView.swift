import SwiftUI
import UniformTypeIdentifiers

/// Displays the contents of a bound real folder as a desktop widget.
struct FileWidgetView: View {
    let widgetInstance: WidgetInstance

    @State private var config: FileWidgetConfiguration = FileWidgetConfiguration()
    @State private var fileURLs: [URL] = []
    @State private var isLoading = false

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text(widgetInstance.title)
                    .font(.headline)
                    .lineLimit(1)

                Spacer()

                Button {
                    openBoundFolder()
                } label: {
                    Image(systemName: "folder")
                }
                .buttonStyle(.plain)
                .help("在 Finder 中打开文件夹")
            }
            .padding(.horizontal, 12)
            .padding(.top, 8)
            .padding(.bottom, 4)

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
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 4)
        }
        .background(backgroundView)
        .clipShape(RoundedRectangle(cornerRadius: widgetInstance.decodeAppearance().cornerRadius))
        .onAppear {
            loadConfiguration()
        }
    }

    // MARK: Subviews

    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: "tray")
                .font(.system(size: 32))
                .foregroundStyle(.secondary)
            Text("拖入文件以整理")
                .font(.body)
                .foregroundStyle(.secondary)
            if config.bookmarkData == nil {
                Text("请先绑定文件夹")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                Button("选择文件夹") {
                    selectFolder()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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

    @ViewBuilder
    private var backgroundView: some View {
        if let hex = widgetInstance.decodeAppearance().backgroundColorHex,
           let color = Color(hex: hex) {
            color.opacity(widgetInstance.decodeAppearance().alpha)
        } else {
            VisualEffectView(material: .sidebar, blendingMode: .behindWindow)
        }
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

// MARK: - VisualEffectView (NSViewRepresentable)

struct VisualEffectView: NSViewRepresentable {
    let material: NSVisualEffectView.Material
    let blendingMode: NSVisualEffectView.BlendingMode

    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = .active
        return view
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
    }
}

// MARK: - Color Extensions

extension Color {
    init?(hex: String) {
        guard hex.hasPrefix("#") else { return nil }
        let hexString = String(hex.dropFirst())
        var int: UInt64 = 0
        guard Scanner(string: hexString).scanHexInt64(&int) else { return nil }

        let r, g, b, a: Double
        switch hexString.count {
        case 6:
            r = Double((int >> 16) & 0xFF) / 255
            g = Double((int >> 8) & 0xFF) / 255
            b = Double(int & 0xFF) / 255
            a = 1.0
        case 8:
            r = Double((int >> 24) & 0xFF) / 255
            g = Double((int >> 16) & 0xFF) / 255
            b = Double((int >> 8) & 0xFF) / 255
            a = Double(int & 0xFF) / 255
        default:
            return nil
        }
        self.init(.sRGB, red: r, green: g, blue: b, opacity: a)
    }
}
