import SwiftUI

/// Simple rich text note widget. Editable plain text, auto-saved.
struct NoteWidgetView: View {
    let widgetInstance: WidgetInstance

    @State private var title: String = ""
    @State private var bodyText: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            TextField("标题", text: $title)
                .font(.headline)
                .textFieldStyle(.plain)

            Divider()

            TextEditor(text: $bodyText)
                .font(.body)
                .scrollContentBackground(.hidden)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .padding(12)
        .background(backgroundView)
        .clipShape(RoundedRectangle(cornerRadius: widgetInstance.decodeAppearance().cornerRadius))
        .onAppear {
            loadContent()
        }
        .onChange(of: bodyText) { _, _ in saveContent() }
        .onChange(of: title) { _, _ in saveContent() }
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

    private func loadContent() {
        title = widgetInstance.title
        bodyText = ""
    }

    private func saveContent() {
        // Stub: will persist via PersistenceService
    }
}
