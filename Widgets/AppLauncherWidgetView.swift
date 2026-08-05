import SwiftUI
import AppKit
import UniformTypeIdentifiers

/// App launcher widget — grid of application shortcuts.
struct AppLauncherWidgetView: View {
    let widgetInstance: WidgetInstance

    @State private var appPaths: [String] = []
    @State private var dropTargeted = false

    private var appearance: WidgetAppearance {
        widgetInstance.decodeAppearance()
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            WidgetTitleBar(title: widgetInstance.title) {
                Button {
                    showOpenPanel()
                } label: {
                    Image(systemName: "plus")
                }
                .buttonStyle(.plain)
            }

            Divider()

            // App grid or empty state
            if appPaths.isEmpty {
                emptyView
            } else {
                ScrollView {
                    LazyVGrid(
                        columns: [GridItem(.adaptive(minimum: 72), spacing: XuloraSpacing.md)],
                        spacing: XuloraSpacing.md
                    ) {
                        ForEach(Array(appPaths.enumerated()), id: \.offset) { index, path in
                            appItem(path: path, index: index)
                        }
                    }
                    .padding(XuloraSpacing.md)
                }
            }
        }
        .background(WidgetBackground(appearance: appearance))
        .overlay(
            dropTargeted
                ? RoundedRectangle(cornerRadius: XuloraRadius.widget)
                    .strokeBorder(Color.accentColor, lineWidth: XuloraBorder.dragTargetWidth)
                : nil
        )
        .onDrop(of: [.fileURL], isTargeted: $dropTargeted) { providers in
            handleDrop(providers: providers)
        }
        .task {
            loadAppPaths()
        }
    }

    // MARK: Subviews

    private func appItem(path: String, index: Int) -> some View {
        let url = URL(fileURLWithPath: path)
        let name = url.deletingPathExtension().lastPathComponent
        let icon = NSWorkspace.shared.icon(forFile: path)

        return VStack(spacing: XuloraSpacing.xs) {
            Button {
                launchApp(path: path)
            } label: {
                Image(nsImage: icon)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.plain)
            .contextMenu {
                Button("移除") {
                    removeApp(at: index)
                }
            }

            Text(name)
                .font(.system(size: 9))
                .lineLimit(1)
                .truncationMode(.tail)
                .frame(width: 72)
        }
    }

    private var emptyView: some View {
        VStack(spacing: XuloraSpacing.md) {
            Image(systemName: "square.grid.3x3")
                .font(.system(size: 28))
                .foregroundStyle(.secondary)
            Text("拖入应用或点击 + 添加")
                .font(XuloraTypography.secondary)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .widgetContentPadding()
    }

    // MARK: Actions

    private func showOpenPanel() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = true
        panel.allowedContentTypes = [.application]
        panel.directoryURL = URL(fileURLWithPath: "/Applications")

        panel.begin { response in
            if response == .OK {
                for url in panel.urls {
                    addApp(path: url.path)
                }
            }
        }
    }

    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        for provider in providers {
            provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, _ in
                guard let data = item as? Data,
                      let url = URL(dataRepresentation: data, relativeTo: nil)
                else { return }

                // Check if it's a valid app bundle in the nonisolated callback.
                guard Self.isAppBundleURL(url) else { return }

                DispatchQueue.main.async {
                    addApp(path: url.path)
                }
            }
        }
        return true
    }

    /// Static helper to check if a URL is an app bundle, safe to call from any context.
    private nonisolated static func isAppBundleURL(_ url: URL) -> Bool {
        url.pathExtension == "app" || ((try? url.resourceValues(forKeys: [.contentTypeKey]).contentType)?.conforms(to: .application) ?? false)
    }

    private func launchApp(path: String) {
        let url = URL(fileURLWithPath: path)
        NSWorkspace.shared.open(url)
    }

    private func removeApp(at index: Int) {
        guard index < appPaths.count else { return }
        appPaths.remove(at: index)
        saveAppPaths()
    }

    // MARK: Persistence

    private func addApp(path: String) {
        guard !appPaths.contains(path) else { return }
        appPaths.append(path)
        saveAppPaths()
    }

    private func saveAppPaths() {
        guard let data = try? JSONEncoder().encode(appPaths) else { return }
        widgetInstance.configurationData = data
    }

    private func loadAppPaths() {
        let data = widgetInstance.configurationData
        guard !data.isEmpty,
              let paths = try? JSONDecoder().decode([String].self, from: data)
        else { return }
        appPaths = paths.filter { FileManager.default.fileExists(atPath: $0) }
    }
}
