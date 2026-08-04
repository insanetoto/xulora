import SwiftUI

// MARK: - Widget Background

/// Unified widget background that renders either a hex color or the default visual effect material.
struct WidgetBackground: View {
    let appearance: WidgetAppearance

    var body: some View {
        if let hex = appearance.backgroundColorHex,
           let color = Color(hex: hex) {
            color.opacity(appearance.alpha)
        } else {
            VisualEffectView(material: .sidebar, blendingMode: .behindWindow)
        }
    }
}

// MARK: - Widget Border Overlay

/// Renders border as an overlay on widget content.
/// Normal mode: 1px neutral border.
/// Edit mode: 1px accent border.
struct WidgetBorderOverlay: View {
    let cornerRadius: CGFloat
    let isEditing: Bool

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .strokeBorder(
                isEditing ? Color.accentColor : Color.primary.opacity(0.10),
                lineWidth: XuloraBorder.defaultWidth
            )
            .allowsHitTesting(false)
    }
}

// MARK: - Widget Content Padding

/// Applies the standard 24pt content padding to a widget.
struct WidgetContentPadding: ViewModifier {
    func body(content: Content) -> some View {
        content.padding(XuloraSpacing.xxl)
    }
}

extension View {
    func widgetContentPadding() -> some View {
        modifier(WidgetContentPadding())
    }
}

// MARK: - Widget Title Bar

/// Standard widget title bar: 56pt height, title left, controls right.
struct WidgetTitleBar<Controls: View>: View {
    let title: String
    @ViewBuilder let controls: () -> Controls

    var body: some View {
        HStack(spacing: XuloraSpacing.md) {
            Text(title)
                .font(XuloraTypography.componentTitle)
                .lineLimit(1)

            Spacer(minLength: 0)

            controls()
        }
        .frame(height: 56)
        .padding(.horizontal, XuloraSpacing.xxl)
    }
}
