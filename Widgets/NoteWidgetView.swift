import SwiftUI
import OSLog

private let logger = Logger(subsystem: "com.nuochong.xulora", category: "NoteWidget")

/// Quick note widget — saves to system Notes app via AppleScript.
struct NoteWidgetView: View {
    let widgetInstance: WidgetInstance

    @State private var title: String = ""
    @State private var bodyText: String = ""
    @State private var lastSavedNoteID: String? = nil

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

            // Footer
            HStack {
                if lastSavedNoteID != nil {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                        .font(.caption)
                    Text("已保存到备忘录")
                        .font(XuloraTypography.secondary)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Button("保存到备忘录") {
                    saveToNotes()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            }
        }
        .widgetContentPadding()
        .background(WidgetBackground(appearance: appearance))
    }

    // MARK: Actions

    private func saveToNotes() {
        guard !title.trimmingCharacters(in: .whitespaces).isEmpty else { return }

        let script = createNoteViaShortcuts(title: title, body: bodyText)

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
        process.arguments = ["-e", script]

        do {
            try process.run()
            process.waitUntilExit()
            if process.terminationStatus == 0 {
                lastSavedNoteID = UUID().uuidString
                logger.info("Note saved to system Notes app")
            } else {
                logger.error("Notes AppleScript failed with status \(process.terminationStatus)")
            }
        } catch {
            logger.error("Failed to run AppleScript: \(error.localizedDescription)")
        }
    }

    /// Generate AppleScript that creates a note in the system Notes app.
    private func createNoteViaShortcuts(title: String, body: String) -> String {
        let escapedTitle = title.replacingOccurrences(of: "\"", with: "\\\"")
        let escapedBody = body.replacingOccurrences(of: "\"", with: "\\\"")
        return """
        tell application "Notes"
            activate
            make new note with properties {name:"\(escapedTitle)", body:"\(escapedTitle)\\n\\n\(escapedBody)"}
        end tell
        """
    }
}
