import SwiftUI

/// Simple rich text note widget. Editable plain text, auto-saved.
struct NoteWidgetView: View {
    let widgetInstance: WidgetInstance

    @State private var title: String = ""
    @State private var bodyText: String = ""

    private var appearance: WidgetAppearance {
        widgetInstance.decodeAppearance()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: XuloraSpacing.sm) {
            TextField("标题", text: $title)
                .font(XuloraTypography.componentTitle)
                .textFieldStyle(.plain)

            Divider()

            TextEditor(text: $bodyText)
                .font(XuloraTypography.body)
                .scrollContentBackground(.hidden)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .widgetContentPadding()
        .background(WidgetBackground(appearance: appearance))
        .onAppear {
            loadContent()
        }
        .onChange(of: bodyText) { _, _ in saveContent() }
        .onChange(of: title) { _, _ in saveContent() }
    }

    private func loadContent() {
        title = widgetInstance.title
        bodyText = ""
    }

    private func saveContent() {
        // Stub: will persist via PersistenceService
    }
}
