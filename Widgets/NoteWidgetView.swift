import SwiftUI
import OSLog

private let logger = Logger(subsystem: "com.nuochong.xulora", category: "NoteWidget")

/// Quick note widget — shows existing system Notes.app notes and creates new ones.
struct NoteWidgetView: View {
    let widgetInstance: WidgetInstance

    @State private var existingNotes: [(id: String, name: String)] = []
    @State private var isLoading = false
    @State private var showEditor = false
    @State private var editorTitle: String = ""
    @State private var editorBody: String = ""
    @State private var lastSavedNoteID: String? = nil

    private var appearance: WidgetAppearance {
        widgetInstance.decodeAppearance()
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            WidgetTitleBar(title: widgetInstance.title) {
                Button {
                    Task { await loadNotes() }
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .buttonStyle(.plain)
                .help("刷新备忘录")
                .disabled(isLoading)
            }

            Divider()

            // Content
            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if existingNotes.isEmpty {
                emptyView
            } else {
                noteListView
            }

            // Create new note
            if showEditor {
                editorView
            } else {
                createButton
            }
        }
        .background(WidgetBackground(appearance: appearance))
        .task {
            await loadNotes()
        }
    }

    // MARK: Note List

    private var noteListView: some View {
        List(existingNotes, id: \.id) { note in
            HStack {
                Image(systemName: "note.text")
                    .foregroundStyle(.secondary)
                Text(note.name)
                    .lineLimit(1)
                Spacer()
            }
            .contentShape(Rectangle())
            .onTapGesture {
                openNoteInNotesApp(noteID: note.id)
            }
        }
        .listStyle(.plain)
    }

    // MARK: Editor

    private var editorView: some View {
        VStack(alignment: .leading, spacing: XuloraSpacing.sm) {
            Divider()

            TextField("标题", text: $editorTitle)
                .font(XuloraTypography.body)
                .textFieldStyle(.plain)

            TextEditor(text: $editorBody)
                .font(XuloraTypography.secondary)
                .scrollContentBackground(.hidden)
                .frame(minHeight: 60)

            HStack {
                if lastSavedNoteID != nil {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                        .font(.caption)
                    Text("已保存")
                        .font(XuloraTypography.secondary)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button("取消") {
                    showEditor = false
                    editorTitle = ""
                    editorBody = ""
                    lastSavedNoteID = nil
                }
                .buttonStyle(.plain)
                .controlSize(.small)
                Button("保存") {
                    saveToNotes()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
                .disabled(editorTitle.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .padding(XuloraSpacing.md)
    }

    private var createButton: some View {
        VStack(spacing: 0) {
            Divider()
            Button {
                showEditor = true
            } label: {
                Label("新建备忘录", systemImage: "plus")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, XuloraSpacing.sm)
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: Empty State

    private var emptyView: some View {
        VStack(spacing: XuloraSpacing.md) {
            Image(systemName: "note.text")
                .font(.system(size: 28))
                .foregroundStyle(.secondary)
            Text("没有备忘录")
                .font(XuloraTypography.body)
                .foregroundStyle(.secondary)
            Button("新建备忘录") {
                showEditor = true
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .widgetContentPadding()
    }

    // MARK: Actions

    private func loadNotes() async {
        isLoading = true
        defer { isLoading = false }

        let script = """
        tell application "Notes"
            set output to ""
            repeat with n in notes
                try
                    set noteID to id of n as string
                    set noteName to name of n as string
                    set output to output & noteID & "\t" & noteName & "\n"
                end try
            end repeat
            return output
        end tell
        """

        guard let result = runAppleScript(script) else { return }

        let parsed: [(id: String, name: String)] = result
            .split(separator: "\n")
            .compactMap { line in
                let parts = line.split(separator: "\t", maxSplits: 1)
                guard parts.count == 2 else { return nil }
                return (id: String(parts[0]), name: String(parts[1]))
            }

        await MainActor.run {
            existingNotes = parsed
        }
    }

    private func saveToNotes() {
        let trimmed = editorTitle.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }

        let escapedTitle = trimmed.replacingOccurrences(of: "\"", with: "\\\"")
        let escapedBody = editorBody.replacingOccurrences(of: "\"", with: "\\\"")

        let script = """
        tell application "Notes"
            activate
            make new note with properties {name:"\(escapedTitle)", body:"\(escapedTitle)\\n\\n\(escapedBody)"}
        end tell
        """

        runAppleScript(script)
        lastSavedNoteID = UUID().uuidString
        editorTitle = ""
        editorBody = ""
        showEditor = false

        logger.info("Note saved to system Notes app")

        Task { await loadNotes() }
    }

    private func openNoteInNotesApp(noteID: String) {
        let script = """
        tell application "Notes"
            activate
            show note id "\(noteID)"
        end tell
        """

        runAppleScript(script)
    }

    // MARK: AppleScript Helper

    @discardableResult
    private func runAppleScript(_ script: String) -> String? {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
        process.arguments = ["-e", script]

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = Pipe()

        do {
            try process.run()
        } catch {
            logger.error("Failed to run AppleScript: \(error.localizedDescription)")
            return nil
        }

        process.waitUntilExit()

        guard process.terminationStatus == 0 else { return nil }

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        return String(data: data, encoding: .utf8)
    }
}
