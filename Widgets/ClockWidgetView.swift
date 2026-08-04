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

    private var appearance: WidgetAppearance {
        widgetInstance.decodeAppearance()
    }

    var body: some View {
        VStack(spacing: style == .large ? XuloraSpacing.md : XuloraSpacing.xs) {
            Text(formattedTime)
                .font(style == .large
                    ? XuloraTypography.displayTime
                    : XuloraTypography.componentTitle)
                .monospacedDigit()

            Text(formattedDate)
                .font(XuloraTypography.body)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .widgetContentPadding()
        .background(WidgetBackground(appearance: appearance))
        .onReceive(timer) { date in
            currentDate = date
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
