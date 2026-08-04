import SwiftUI
import UserNotifications
import OSLog

private let logger = Logger(subsystem: "com.nuochong.xulora", category: "Pomodoro")

/// Pomodoro timer widget — focus and break cycles with system notifications.
struct PomodoroWidgetView: View {
    let widgetInstance: WidgetInstance

    @State private var state: PomodoroState?
    @State private var remainingSeconds: Int = 0
    @State private var isRunning = false

    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(spacing: 12) {
            // Phase indicator
            Text(state?.currentPhase == .focus ? "专注" : "休息")
                .font(.headline)
                .foregroundStyle(state?.currentPhase == .focus ? .orange : .green)

            // Timer display
            Text(formatTime(remainingSeconds))
                .font(.system(size: 36, weight: .thin, design: .monospaced))
                .monospacedDigit()

            // Controls
            HStack(spacing: 16) {
                Button {
                    toggleTimer()
                } label: {
                    Image(systemName: isRunning ? "pause.circle.fill" : "play.circle.fill")
                        .font(.title)
                }
                .buttonStyle(.plain)
                .help(isRunning ? "暂停" : "开始")

                Button {
                    resetTimer()
                } label: {
                    Image(systemName: "stop.circle.fill")
                        .font(.title)
                }
                .buttonStyle(.plain)
                .help("重置")
            }

            // Session counter
            Text("25 分钟专注 · 5 分钟休息")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(16)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(backgroundView)
        .clipShape(RoundedRectangle(cornerRadius: widgetInstance.decodeAppearance().cornerRadius))
        .onAppear {
            initializeState()
        }
        .onReceive(timer) { _ in
            if isRunning {
                updateTimer()
            }
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

    // MARK: Actions

    private func initializeState() {
        let s = PomodoroState(widgetID: widgetInstance.id)
        state = s
        remainingSeconds = s.focusMinutes * 60
    }

    private func toggleTimer() {
        isRunning.toggle()
    }

    private func updateTimer() {
        guard remainingSeconds > 0 else {
            completePhase()
            return
        }
        remainingSeconds -= 1
    }

    private func resetTimer() {
        isRunning = false
        remainingSeconds = (state?.focusMinutes ?? 25) * 60
    }

    private func completePhase() {
        isRunning = false
        sendNotification()
        // Switch to next phase
    }

    private func sendNotification() {
        let content = UNMutableNotificationContent()
        content.title = "番茄钟完成"
        content.body = state?.currentPhase == .focus ? "专注时间结束，休息一下吧。" : "休息结束，可以开始新的专注了。"
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error {
                logger.error("Notification failed: \(error.localizedDescription)")
            }
        }
    }

    private func formatTime(_ seconds: Int) -> String {
        let m = seconds / 60
        let s = seconds % 60
        return String(format: "%02d:%02d", m, s)
    }
}
