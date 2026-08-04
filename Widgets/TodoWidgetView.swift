import SwiftUI

/// Todo list widget — add, complete, reorder, delete tasks.
struct TodoWidgetView: View {
    let widgetInstance: WidgetInstance

    @State private var items: [TodoItem] = []
    @State private var newTaskTitle: String = ""
    @State private var showCompleted: Bool = true

    private var visibleItems: [TodoItem] {
        showCompleted ? items : items.filter { !$0.isCompleted }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text(widgetInstance.title)
                    .font(.headline)
                Spacer()
                Menu {
                    Toggle("显示已完成", isOn: $showCompleted)
                    Button("清除已完成", role: .destructive) {
                        clearCompleted()
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 12)
            .padding(.top, 8)

            // Add new task
            HStack {
                TextField("添加任务", text: $newTaskTitle)
                    .textFieldStyle(.plain)
                    .onSubmit {
                        addTask()
                    }

                Button {
                    addTask()
                } label: {
                    Image(systemName: "plus.circle.fill")
                }
                .buttonStyle(.plain)
                .disabled(newTaskTitle.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 4)

            Divider()

            // Task list
            List {
                ForEach(visibleItems) { item in
                    HStack {
                        Button {
                            withAnimation {
                                item.toggle()
                            }
                        } label: {
                            Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(item.isCompleted ? .green : .secondary)
                        }
                        .buttonStyle(.plain)

                        Text(item.title)
                            .strikethrough(item.isCompleted)
                            .foregroundStyle(item.isCompleted ? .secondary : .primary)
                            .lineLimit(2)

                        Spacer()
                    }
                    .contentShape(Rectangle())
                }
                .onDelete(perform: deleteTasks)
                .onMove(perform: moveTasks)
            }
            .listStyle(.plain)
        }
        .background(backgroundView)
        .clipShape(RoundedRectangle(cornerRadius: widgetInstance.decodeAppearance().cornerRadius))
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

    private func addTask() {
        let trimmed = newTaskTitle.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }

        let item = TodoItem(
            widgetID: widgetInstance.id,
            title: trimmed,
            sortOrder: items.count
        )
        items.append(item)
        newTaskTitle = ""
    }

    private func deleteTasks(at offsets: IndexSet) {
        let ids = offsets.map { visibleItems[$0].id }
        items.removeAll { ids.contains($0.id) }
    }

    private func moveTasks(from source: IndexSet, to destination: Int) {
        var visible = visibleItems
        visible.move(fromOffsets: source, toOffset: destination)
        // Reassign sort orders
        for (index, item) in visible.enumerated() {
            item.sortOrder = index
        }
    }

    private func clearCompleted() {
        items.removeAll { $0.isCompleted }
    }
}
