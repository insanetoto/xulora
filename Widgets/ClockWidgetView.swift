import SwiftUI

/// Displays current time and date with optional seconds.
struct ClockWidgetView: View {
    let widgetInstance: WidgetInstance

    @State private var currentDate = Date()
    @State private var showSeconds = false
    @State private var use24Hour = true
    @State private var style: ClockStyle = .compact

    enum ClockStyle: String, CaseIterable {
        case compact, large
    }

    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(spacing: style == .large ? 12 : 4) {
            Text(formattedTime)
                .font(style == .large ? .system(size: 48, weight: .thin, design: .default) : .title)
                .monospacedDigit()

            Text(formattedDate)
                .font(.body)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(16)
        .background(backgroundView)
        .clipShape(RoundedRectangle(cornerRadius: widgetInstance.decodeAppearance().cornerRadius))
        .onReceive(timer) { date in
            currentDate = date
        }
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

    private var formattedTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = showSeconds
            ? (use24Hour ? "HH:mm:ss" : "hh:mm:ss a")
            : (use24Hour ? "HH:mm" : "hh:mm a")
        return formatter.string(from: currentDate)
    }

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.setLocalizedDateFormatFromTemplate("yyyyMMMdEEE")
        return formatter.string(from: currentDate)
    }
}
