import SwiftUI

extension Color {
    /// Initialize a Color from a hex string like `#RRGGBB` or `#RRGGBBAA`.
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
