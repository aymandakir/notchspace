import SwiftUI
import AppKit

public struct AIPanel: View {

    @ObservedObject public var manager: AIAssistantManager

    @State private var prompt:      String = ""
    @State private var showConfig:  Bool   = false
    @State private var cursorOn:    Bool   = true
    @FocusState private var focused: Bool

    private let spring = Animation.spring(response: 0.3, dampingFraction: 0.75)

    public init(manager: AIAssistantManager) { self.manager = manager }

    public var body: some View {
        VStack(spacing: 0) {
            inputRow
            Divider().background(Color.white.opacity(0.08))
            responseArea
        }
        .onAppear { focused = true; startCursorBlink() }
    }

    // MARK: - Input row

    private var inputRow: some View {
        HStack(spacing: 8) {
            modelChip
            TextField("Ask anything…", text: $prompt)
                .textFieldStyle(.plain)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.white)
                .focused($focused)
                .onSubmit(submit)
                .frame(maxWidth: .infinity)

            if manager.isLoading {
                cancelButton
            } else if !prompt.isEmpty {
                sendButton
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
    }

    // MARK: Model chip

    private var modelChip: some View {
        Button { showConfig.toggle() } label: {
            Text(shortModelName)
                .font(.system(size: 9.5, weight: .semibold))
                .foregroundStyle(.white.opacity(0.55))
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(Color.white.opacity(0.08), in: Capsule())
        }
        .buttonStyle(.plain)
        .popover(isPresented: $showConfig, arrowEdge: .bottom) {
            configPopover
        }
    }

    private var shortModelName: String {
        let m = manager.config.model
        // "anthropic/claude-3-haiku" → "claude-3-haiku"
        return m.contains("/") ? String(m.split(separator: "/").last ?? Substring(m)) : m
    }

    // MARK: Send / Cancel

    private var sendButton: some View {
        Button(action: submit) {
            Image(systemName: "arrow.up.circle.fill")
                .font(.system(size: 15))
                .foregroundStyle(.white.opacity(0.65))
        }
        .buttonStyle(.plain)
    }

    private var cancelButton: some View {
        Button(action: manager.cancel) {
            Image(systemName: "stop.circle.fill")
                .font(.system(size: 15))
                .foregroundStyle(.white.opacity(0.45))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Response area

    private var responseArea: some View {
        ZStack(alignment: .topTrailing) {
            ScrollView(.vertical, showsIndicators: false) {
                responseText
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
            }

            if !manager.response.isEmpty && !manager.isLoading {
                copyButton
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var responseText: some View {
        Group {
            if let err = manager.error {
                Text(err)
                    .font(.system(size: 11))
                    .foregroundStyle(Color(red: 1, green: 0.42, blue: 0.42))
            } else if manager.response.isEmpty && !manager.isLoading {
                Text("Enter a prompt above and press Return")
                    .font(.system(size: 11))
                    .foregroundStyle(.white.opacity(0.18))
            } else {
                // Response + blinking cursor while streaming
                (Text(manager.response)
                    .font(.system(size: 11, weight: .regular))
                    .foregroundStyle(.white.opacity(0.85))
                 + (manager.isLoading
                    ? Text(cursorOn ? "▌" : " ")
                        .font(.system(size: 11))
                        .foregroundStyle(.white.opacity(0.6))
                    : Text(""))
                )
            }
        }
    }

    private var copyButton: some View {
        Button {
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(manager.response, forType: .string)
        } label: {
            Image(systemName: "doc.on.doc")
                .font(.system(size: 11))
                .foregroundStyle(.white.opacity(0.35))
                .frame(width: 24, height: 24)
                .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 6, style: .continuous))
        }
        .buttonStyle(.plain)
        .padding(6)
    }

    // MARK: - Config popover

    private var configPopover: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("AI Settings", systemImage: "cpu")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.primary)

            Divider()

            configRow(label: "Base URL", placeholder: "https://openrouter.ai/api/v1",
                      binding: Binding(get: { manager.config.baseURL },
                                       set: { manager.config.baseURL = $0; manager.config.save() }))

            configRow(label: "Model", placeholder: "anthropic/claude-3-haiku",
                      binding: Binding(get: { manager.config.model },
                                       set: { manager.config.model = $0; manager.config.save() }))

            apiKeyRow
        }
        .padding(14)
        .frame(width: 280)
    }

    private func configRow(label: String, placeholder: String, binding: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(.secondary)
            TextField(placeholder, text: binding)
                .textFieldStyle(.roundedBorder)
                .font(.system(size: 11))
        }
    }

    private var apiKeyRow: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text("API Key")
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(.secondary)
            SecureField(manager.apiKey != nil ? "•••• stored in Keychain" : "sk-…",
                        text: .constant(""))
                .textFieldStyle(.roundedBorder)
                .font(.system(size: 11))
                .disabled(true)
                .overlay(alignment: .trailing) {
                    Button(manager.apiKey != nil ? "Replace" : "Set") {
                        promptAPIKey()
                    }
                    .font(.system(size: 10))
                    .padding(.trailing, 6)
                }
        }
    }

    // MARK: - Helpers

    private func submit() {
        let trimmed = prompt.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !manager.isLoading else { return }
        manager.send(prompt: trimmed)
        prompt = ""
    }

    private func startCursorBlink() {
        let t = Timer(timeInterval: 0.5, repeats: true) { [weak manager] _ in
            guard manager?.isLoading == true else { return }
            Task { @MainActor in cursorOn.toggle() }
        }
        RunLoop.main.add(t, forMode: .common)
    }

    private func promptAPIKey() {
        let alert       = NSAlert()
        alert.messageText    = "Enter API Key"
        alert.informativeText = "Stored securely in Keychain. Used for \(manager.config.baseURL)."
        alert.addButton(withTitle: "Save")
        alert.addButton(withTitle: "Cancel")
        if manager.apiKey != nil {
            alert.addButton(withTitle: "Delete")
        }

        let field = NSSecureTextField(frame: NSRect(x: 0, y: 0, width: 260, height: 22))
        field.placeholderString = "sk-…"
        alert.accessoryView = field

        let resp = alert.runModal()
        switch resp {
        case .alertFirstButtonReturn:
            let key = field.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
            if !key.isEmpty { manager.saveAPIKey(key) }
        case .alertThirdButtonReturn:
            manager.deleteAPIKey()
        default:
            break
        }
    }
}
