import SwiftUI
@preconcurrency import EventKit

/// System calendar widget — displays today's events from macOS Calendar.
struct CalendarWidgetView: View {
    let widgetInstance: WidgetInstance

    @State private var events: [EKEvent] = []
    @State private var needsAuth: Bool = false

    private let store = EKEventStore()

    private var appearance: WidgetAppearance {
        widgetInstance.decodeAppearance()
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            WidgetTitleBar(title: widgetInstance.title) {
                HStack(spacing: XuloraSpacing.md) {
                    Button {
                        loadTodayEvents()
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                    .buttonStyle(.plain)
                }
            }

            Divider()

            // Content
            if needsAuth {
                authRequestView
            } else if events.isEmpty {
                emptyView
            } else {
                List {
                    ForEach(events, id: \.eventIdentifier) { event in
                        eventRow(event)
                    }
                }
                .listStyle(.plain)
            }
        }
        .background(WidgetBackground(appearance: appearance))
        .task {
            requestAccess()
        }
        .onReceive(
            NotificationCenter.default.publisher(for: .EKEventStoreChanged)
        ) { _ in
            loadTodayEvents()
        }
    }

    // MARK: Subviews

    private func eventRow(_ event: EKEvent) -> some View {
        HStack(spacing: XuloraSpacing.md) {
            // Calendar color dot
            Circle()
                .fill(Color(event.calendar.color))
                .frame(width: 8, height: 8)

            VStack(alignment: .leading, spacing: 2) {
                Text(event.title)
                    .font(XuloraTypography.body)
                    .lineLimit(1)

                Text(timeLabel(for: event))
                    .font(XuloraTypography.secondary)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .contentShape(Rectangle())
    }

    private var emptyView: some View {
        VStack(spacing: XuloraSpacing.md) {
            Image(systemName: "calendar")
                .font(.system(size: 28))
                .foregroundStyle(.secondary)
            Text("今天没有日程")
                .font(XuloraTypography.body)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .widgetContentPadding()
    }

    private var authRequestView: some View {
        VStack(spacing: XuloraSpacing.md) {
            Image(systemName: "exclamationmark.shield")
                .font(.system(size: 28))
                .foregroundStyle(.secondary)
            Text("需要访问日历")
                .font(XuloraTypography.body)
                .foregroundStyle(.secondary)
            Button("授权访问") {
                Task { await requestFullAccess() }
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .widgetContentPadding()
    }

    // MARK: Helpers

    private func timeLabel(for event: EKEvent) -> String {
        if event.isAllDay {
            return "全天"
        }
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return "\(formatter.string(from: event.startDate)) – \(formatter.string(from: event.endDate))"
    }

    // MARK: EventKit

    private func requestAccess() {
        let status = EKEventStore.authorizationStatus(for: .event)
        switch status {
        case .fullAccess, .writeOnly:
            needsAuth = false
            loadTodayEvents()
        case .notDetermined:
            needsAuth = true
        case .denied, .restricted:
            needsAuth = true
        @unknown default:
            needsAuth = true
        }
    }

    private func requestFullAccess() async {
        if #available(macOS 26.0, *) {
            do {
                let granted = try await store.requestFullAccessToEvents()
                needsAuth = !granted
                if granted {
                    loadTodayEvents()
                }
            } catch {
                needsAuth = true
            }
        } else {
            let granted = (try? await store.requestAccess(to: .event)) ?? false
            needsAuth = !granted
            if granted {
                loadTodayEvents()
            }
        }
    }

    private func loadTodayEvents() {
        let start = Calendar.current.startOfDay(for: Date())
        guard let end = Calendar.current.date(byAdding: .day, value: 1, to: start) else { return }

        let predicate = store.predicateForEvents(withStart: start, end: end, calendars: nil)
        let fetched = store.events(matching: predicate)

        Task { @MainActor in
            self.events = fetched.sorted { $0.startDate < $1.startDate }
        }
    }
}
