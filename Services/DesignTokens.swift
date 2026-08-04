import SwiftUI

// MARK: - Spacing Tokens (§5.1)

/// Semantic spacing tokens based on 4pt grid.
enum XuloraSpacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let xl: CGFloat = 20
    static let xxl: CGFloat = 24
    static let huge: CGFloat = 32
}

// MARK: - Radius Tokens (§6.1)

/// Corner radius values per component type.
enum XuloraRadius {
    static let widget: CGFloat = 24
    static let item: CGFloat = 10
    static let smallButton: CGFloat = 8
    static let thumbnail: CGFloat = 8
}

// MARK: - Typography Tokens (§7.2)

/// Font styles used throughout the app.
enum XuloraTypography {
    static var displayTime: Font { .system(size: 48, weight: .regular, design: .default) }
    static var componentTitle: Font { .system(size: 20, weight: .semibold) }
    static var sectionTitle: Font { .system(size: 16, weight: .semibold) }
    static var body: Font { .body }
    static var secondary: Font { .caption }
}

// MARK: - Border Tokens (§6.2)

/// Border widths for different states.
enum XuloraBorder {
    static let defaultWidth: CGFloat = 1
    static let editWidth: CGFloat = 1
    static let dragTargetWidth: CGFloat = 2
}
