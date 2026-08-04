import Foundation
import OSLog

private let logger = Logger(subsystem: "com.nuochong.xulora", category: "ConflictResolver")

/// Resolves file name conflicts by generating non-colliding names.
struct FileConflictResolver {

    /// Generate a unique name for a file in the target directory.
    /// Pattern: "文件名" → "文件名 2", "文件名 2" → "文件名 3", etc.
    func resolveConflict(originalName: String, destinationDir: URL) -> String {
        let nsName = originalName as NSString
        let nameWithoutExt = nsName.deletingPathExtension
        let ext = nsName.pathExtension

        let existingNames = fileNames(in: destinationDir)

        var candidate = originalName
        var counter = 2

        while existingNames.contains(candidate) {
            if ext.isEmpty {
                candidate = "\(nameWithoutExt) \(counter)"
            } else {
                candidate = "\(nameWithoutExt) \(counter).\(ext)"
            }
            counter += 1
        }

        return candidate
    }

    private func fileNames(in directory: URL) -> Set<String> {
        guard let contents = try? FileManager.default.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: nil,
            options: .skipsHiddenFiles
        ) else {
            return []
        }
        return Set(contents.map(\.lastPathComponent))
    }
}
