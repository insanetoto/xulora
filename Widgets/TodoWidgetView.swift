import SwiftUI
@preconcurrency import EventKit

/// System Reminders widget — displays and manages macOS Reminders app tasks.
struct TodoWidgetView: View {
    let widgetInstance: WidgetInstance

    @State private var reminders: [EKReminder] = []
    @State private var newTaskTitle: String = ""
    @State private var showCompleted: Bool = true
    @State private var needsAuth: Bool = false

    private let store = EKEventStore()

    private var appearance: WidgetAppearance {
        widgetInstance.decodeAppearance()
    }

    private var visibleReminders: [EKReminder] {
        showCompleted ? reminders : reminders.filter { !$0.isCompleted }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            WidgetTitleBar(title: widgetInstance.title) {
                Menu {
                    Toggle("显示已完成", isOn: $showCompleted)
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
                .buttonStyle(.plain)
            }

            // Add new task
            HStack {
                TextField("添加提醒事项", text: $newTaskTitle)
                    .textFieldStyle(.plain)
                    .onSubmit { addReminder() }

                Button { addReminder() } label: {
                    Image(systemName: "plus.circle.fill")
                }
                .buttonStyle(.plain)
                .disabled(newTaskTitle.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            .padding(.horizontal, XuloraSpacing.xxl)
            .padding(.vertical, XuloraSpacing.sm)

            Divider()

            // Reminder list
            if needsAuth {
                authRequestView
            } else if visibleReminders.isEmpty {
                emptyView
            } else {
                List {
                    ForEach(visibleReminders, id: \.calendarItemIdentifier) { reminder in
                        reminderRow(reminder)
                    }
                }
                .listStyle(.plain)
            }
        }
        .background(WidgetBackground(appearance: appearance))
        .task {
            requestAccess()
        }
    }

    // MARK: Subviews

    private func reminderRow(_ reminder: EKReminder) -> some View {
        HStack {
            Button {
                toggleReminder(reminder)
            } label: {
                Image(systemName: reminder.isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(reminder.isCompleted ? .green : .secondary)
            }
            .buttonStyle(.plain)

            Text(reminder.title)
                .strikethrough(reminder.isCompleted)
                .foregroundStyle(reminder.isCompleted ? .secondary : .primary)
                .lineLimit(2)

            Spacer()
        }
        .contentShape(Rectangle())
    }

    private var emptyView: some View {
        VStack(spacing: XuloraSpacing.md) {
            Image(systemName: "checklist")
                .font(.system(size: 28))
                .foregroundStyle(.secondary)
            Text("没有提醒事项")
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
            Text("需要访问提醒事项")
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

    // MARK: EventKit

    private func requestAccess() {
        let status = EKEventStore.authorizationStatus(for: .reminder)
        switch status {
        case .fullAccess, .writeOnly:
            needsAuth = false
            loadReminders()
        case .notDetermined:
            needsAuth = true
        case .denied, .restricted:
            needsAuth = true
        @unknown default:
            needsAuth = true
        }
    }

    private func requestFullAccess() async {
        do {
            let granted = try await store.requestFullAccessToReminders()
            needsAuth = !granted
            if granted {
                loadReminders()
            }
        } catch {
            needsAuth = true
        }
    }

    private func loadReminders() {
        let predicate = store.predicateForIncompleteReminders(
            withDueDateStarting: nil,
            ending: nil,
            calendars: nil
        )

        store.fetchReminders(matching: predicate) { fetched in
            Task { @MainActor in
                self.reminders = fetched ?? []
            }
        }
    }

    private func addReminder() {
        let trimmed = newTaskTitle.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }

        let reminder = EKReminder(eventStore: store)
        reminder.title = trimmed
        reminder.calendar = store.defaultCalendarForNewReminders()

        do {
            try store.save(reminder, commit: true)
            reminders.append(reminder)
            newTaskTitle = ""
        } catch {
            // Silently fail for now
        }
    }

    private func toggleReminder(_ reminder: EKReminder) {
        reminder.isCompleted.toggle()
        do {
            try store.save(reminder, commit: true)
            withAnimation {
                // Trigger view refresh
                reminders = reminders.map { $0 }
            }
        } catch {
            reminder.isCompleted.toggle()
        }
    }
}
