import Foundation
import OSLog

private let logger = Logger(subsystem: "com.nuochong.xulora", category: "FolderObserver")

/// Monitors a directory for external changes using DispatchSource file system events.
/// Debounces rapid changes to avoid excessive refreshes.
final class FolderObserver: @unchecked Sendable {
    private var source: (any DispatchSourceFileSystemObject)?
    private let folderURL: URL
    private let onChange: @Sendable () -> Void
    private let queue = DispatchQueue(label: "com.nuochong.xulora.folder-observer")

    private var debounceWorkItem: DispatchWorkItem?
    private let debounceInterval: TimeInterval = 1.0

    init(folderURL: URL, onChange: @escaping @Sendable () -> Void) {
        self.folderURL = folderURL
        self.onChange = onChange
    }

    deinit {
        stop()
    }

    func start() {
        stop()

        let fileDescriptor = open(folderURL.path, O_EVTONLY)
        guard fileDescriptor >= 0 else {
            logger.error("Failed to open folder for observation: \(self.folderURL.path)")
            return
        }

        source = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: fileDescriptor,
            eventMask: [.write, .rename, .delete, .extend],
            queue: queue
        )

        source?.setEventHandler { [weak self] in
            self?.handleChange()
        }

        source?.setCancelHandler {
            close(fileDescriptor)
        }

        source?.resume()
        logger.info("Started observing: \(self.folderURL.path)")
    }

    func stop() {
        source?.cancel()
        source = nil
        debounceWorkItem?.cancel()
    }

    private func handleChange() {
        debounceWorkItem?.cancel()

        let workItem = DispatchWorkItem { [weak self] in
            guard let self else { return }
            self.onChange()
        }

        debounceWorkItem = workItem
        queue.asyncAfter(deadline: .now() + debounceInterval, execute: workItem)
    }
}
