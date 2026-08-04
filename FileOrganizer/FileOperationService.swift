import Foundation
import OSLog

private let logger = Logger(subsystem: "com.nuochong.xulora", category: "FileOps")

/// Handles all file system operations: move, copy, trash, conflict resolution.
/// Uses Foundation FileManager exclusively — never shell commands.
@MainActor
final class FileOperationService {
    static let shared = FileOperationService()

    private let fileManager = FileManager.default
    private let conflictResolver = FileConflictResolver()

    // MARK: Move

    func moveItem(
        from source: URL,
        to destinationDirectory: URL,
        allowReplacement: Bool = false
    ) throws -> URL {
        let destination = destinationDirectory.appendingPathComponent(source.lastPathComponent)

        if fileManager.fileExists(atPath: destination.path) && !allowReplacement {
            throw FileOperationError.fileExists(destination)
        }

        try fileManager.moveItem(at: source, to: destination)
        logger.info("Moved: \(source.lastPathComponent) → \(destinationDirectory.path)")
        return destination
    }

    func moveItems(
        from sources: [URL],
        to destination: URL,
        onConflict: FileConflictResolution = .prompt
    ) async throws -> [URL] {
        var results: [URL] = []

        for source in sources {
            let destURL = destination.appendingPathComponent(source.lastPathComponent)

            if fileManager.fileExists(atPath: destURL.path) {
                let resolvedName = conflictResolver.resolveConflict(
                    originalName: source.lastPathComponent,
                    destinationDir: destination
                )
                let resolvedDest = destination.appendingPathComponent(resolvedName)
                try fileManager.moveItem(at: source, to: resolvedDest)
                results.append(resolvedDest)
            } else {
                try fileManager.moveItem(at: source, to: destURL)
                results.append(destURL)
            }
        }

        return results
    }

    // MARK: Copy

    func copyItem(from source: URL, to destinationDirectory: URL) throws -> URL {
        let destination = destinationDirectory.appendingPathComponent(source.lastPathComponent)

        if fileManager.fileExists(atPath: destination.path) {
            throw FileOperationError.fileExists(destination)
        }

        try fileManager.copyItem(at: source, to: destination)
        logger.info("Copied: \(source.lastPathComponent) → \(destinationDirectory.path)")
        return destination
    }

    // MARK: Trash

    func trashItem(at url: URL) throws {
        var resultingURL: NSURL?
        try fileManager.trashItem(at: url, resultingItemURL: &resultingURL)
        logger.info("Trashed: \(url.lastPathComponent)")
    }

    // MARK: Validation

    func validateDestination(_ url: URL) throws {
        guard fileManager.fileExists(atPath: url.path) else {
            throw FileOperationError.directoryNotFound(url)
        }
        guard fileManager.isWritableFile(atPath: url.path) else {
            throw FileOperationError.directoryNotWritable(url)
        }
    }
}

// MARK: Errors

enum FileOperationError: LocalizedError {
    case fileExists(URL)
    case directoryNotFound(URL)
    case directoryNotWritable(URL)
    case crossVolumeMoveNotSupported(URL, URL)
    case permissionDenied(URL)

    var errorDescription: String? {
        switch self {
        case .fileExists(let url):
            return "目标位置已存在同名文件：\(url.lastPathComponent)"
        case .directoryNotFound(let url):
            return "目标文件夹不存在：\(url.lastPathComponent)"
        case .directoryNotWritable:
            return "目标文件夹不可写入"
        case .crossVolumeMoveNotSupported(let from, let to):
            return "无法在 \(from.lastPathComponent) 和 \(to.lastPathComponent) 之间直接移动（跨磁盘）。建议改为先复制再删除。"
        case .permissionDenied(let url):
            return "没有权限访问：\(url.lastPathComponent)"
        }
    }
}

// MARK: Conflict Types

enum FileConflictResolution {
    case prompt
    case keepBoth
    case replace
    case skip
}
