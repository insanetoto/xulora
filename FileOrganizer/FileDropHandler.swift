import Foundation
import SwiftUI
import UniformTypeIdentifiers
import OSLog

private let logger = Logger(subsystem: "com.nuochong.xulora", category: "DropHandler")

/// Handles drag-and-drop of files from Finder into a file widget.
@MainActor
struct FileDropHandler {
    let destinationURL: URL
    let onDropCompleted: @Sendable () -> Void

    /// Supported UTIs for file drop.
    static let supportedTypes: [UTType] = [
        .fileURL, .folder, .item
    ]

    /// Process a drop of NSItemProviders.
    func handleDrop(providers: [NSItemProvider], isCopy: Bool) -> Bool {
        let targetURL = destinationURL
        let onComplete = onDropCompleted

        for provider in providers {
            for type in Self.supportedTypes {
                if provider.hasItemConformingToTypeIdentifier(type.identifier) {
                    provider.loadItem(forTypeIdentifier: type.identifier, options: nil) { item, error in
                        if let error {
                            logger.error("Drop load failed: \(error.localizedDescription)")
                            return
                        }

                        guard let urlData = item as? Data,
                              let url = URL(dataRepresentation: urlData, relativeTo: nil) else {
                            return
                        }

                        Task { @MainActor in
                            await Self.processFile(url: url, isCopy: isCopy, destinationURL: targetURL, onComplete: onComplete)
                        }
                    }
                    break
                }
            }
        }
        return true
    }

    @MainActor
    private static func processFile(url: URL, isCopy: Bool, destinationURL: URL, onComplete: @escaping @Sendable () -> Void) async {
        do {
            if isCopy {
                _ = try FileOperationService.shared.copyItem(from: url, to: destinationURL)
            } else {
                _ = try FileOperationService.shared.moveItem(from: url, to: destinationURL)
            }
            onComplete()
        } catch {
            logger.error("Drop operation failed: \(error.localizedDescription)")
        }
    }
}
