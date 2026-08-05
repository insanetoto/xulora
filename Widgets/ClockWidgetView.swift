import SwiftUI

/// Digital clock widget with date display, refreshed every second.
struct ClockWidgetView: View {
    let widgetInstance: WidgetInstance

    private var appearance: WidgetAppearance {
        widgetInstance.decodeAppearance()
    }

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { _ in
            VStack(spacing: XuloraSpacing.xs) {
                Spacer()

                // Time
                Text(formattedTime)
                    .font(XuloraTypography.displayTime)
                    .foregroundStyle(.primary)
                    .monospacedDigit()

                // Date
                Text(formattedDate)
                    .font(XuloraTypography.sectionTitle)
                    .foregroundStyle(.secondary)

                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(WidgetBackground(appearance: appearance))
    }

    private var formattedTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: Date())
    }

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "yyyy年M月d日 EEEE"
        return formatter.string(from: Date())
    }
}
