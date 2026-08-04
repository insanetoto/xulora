import Foundation

enum FileDisplayMode: String, Codable, CaseIterable {
    case grid, list
}

enum FileSortMode: String, Codable, CaseIterable {
    case nameAscending, modificationDateDescending, kind
}

struct FileWidgetConfiguration: Codable, Equatable {
    var bookmarkData: Data?
    var displayMode: FileDisplayMode = .grid
    var sortMode: FileSortMode = .modificationDateDescending
    var contentDensity: WidgetSpacing = .standard
}
