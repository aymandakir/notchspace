import SwiftUI
import LaunchAtLogin
import Sparkle
import Core
import Features

// MARK: - Settings window (Cmd+, or menu bar → Settings)

struct SettingsView: View {

    @ObservedObject private var plugins   = PluginManager.shared
    @ObservedObject private var aiManager = AIAssistantManager.shared

    private let updater: SPUUpdater

    init(updater: SPUUpdater) { self.updater = updater }

    var body: some View {
        TabView {
            pluginsTab
                .tabItem { Label("Plugins", systemImage: "puzzlepiece.extension") }

            aiTab
                .tabItem { Label("AI", systemImage: "sparkles") }

            generalTab
                .tabItem { Label("General", systemImage: "gear") }
        }
        .frame(width: 500, height: 360)
    }

    // MARK: - Plugins tab

    private var pluginsTab: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionHeader("Built-in")
            builtinList

            Divider().padding(.vertical, 12)

            sectionHeader("Installed")
            externalList
        }
        .padding(20)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private var builtinList: some View {
        let builtins = plugins.plugins.filter { $0.id.hasPrefix("space.notch.") && $0.id != "space.notch.system" }
        return ForEach(builtins, id: \.id) { plugin in
            pluginRow(plugin: plugin)
        }
    }

    private var externalList: some View {
        let external = plugins.plugins.filter { !$0.id.hasPrefix("space.notch.") }
        return Group {
            if external.isEmpty {
                Text("No plugins installed.\nDrop .notchplugin bundles into ~/Library/Application Support/NotchSpace/Plugins/")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.leading)
            } else {
                ForEach(external, id: \.id) { plugin in
                    pluginRow(plugin: plugin)
                }
            }
        }
    }

    private func pluginRow(plugin: any NotchPlugin) -> some View {
        HStack(spacing: 10) {
            Image(systemName: plugin.icon)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.secondary)
                .frame(width: 22)

            VStack(alignment: .leading, spacing: 1) {
                Text(plugin.name)
                    .font(.system(size: 13, weight: .medium))
                Text(plugin.id)
                    .font(.system(size: 10))
                    .foregroundStyle(.tertiary)
            }

            Spacer()

            Toggle("", isOn: Binding(
                get: { plugins.isEnabled(plugin) },
                set: { plugins.setEnabled(plugin, $0) }
            ))
            .labelsHidden()
            .toggleStyle(.switch)
            .controlSize(.small)
        }
        .padding(.vertical, 5)
    }

    // MARK: - AI tab

    private var aiTab: some View {
        Form {
            Section("Connection") {
                LabeledContent("Base URL") {
                    TextField("https://openrouter.ai/api/v1",
                              text: Binding(
                                get: { aiManager.config.baseURL },
                                set: { aiManager.config.baseURL = $0; aiManager.config.save() }
                              ))
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 260)
                }

                LabeledContent("Model") {
                    TextField("anthropic/claude-3-haiku",
                              text: Binding(
                                get: { aiManager.config.model },
                                set: { aiManager.config.model = $0; aiManager.config.save() }
                              ))
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 260)
                }
            }

            Section("API Key") {
                LabeledContent("Status") {
                    Text(aiManager.apiKey != nil ? "Stored in Keychain" : "Not set")
                        .foregroundStyle(aiManager.apiKey != nil ? .green : .secondary)
                }

                HStack {
                    Button("Set API Key…")   { promptAPIKey(replace: false) }
                    if aiManager.apiKey != nil {
                        Button("Replace…")  { promptAPIKey(replace: true)  }
                        Button("Delete", role: .destructive) { aiManager.deleteAPIKey() }
                    }
                }
            }
        }
        .formStyle(.grouped)
        .padding(.top, 6)
    }

    // MARK: - General tab

    private var generalTab: some View {
        Form {
            Section("Startup") {
                LaunchAtLogin.Toggle()
            }

            Section("Updates") {
                HStack {
                    Text("Version \(Bundle.main.shortVersionString)")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Button("Check for Updates…") { updater.checkForUpdates() }
                }
            }
        }
        .formStyle(.grouped)
        .padding(.top, 6)
    }

    // MARK: - Helpers

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(.secondary)
            .textCase(.uppercase)
            .padding(.bottom, 4)
    }

    private func promptAPIKey(replace: Bool) {
        let alert             = NSAlert()
        alert.messageText     = replace ? "Replace API Key" : "Set API Key"
        alert.informativeText = "Stored securely in Keychain."
        alert.addButton(withTitle: "Save")
        alert.addButton(withTitle: "Cancel")

        let field             = NSSecureTextField(frame: NSRect(x: 0, y: 0, width: 280, height: 22))
        field.placeholderString = "sk-…"
        alert.accessoryView   = field

        if alert.runModal() == .alertFirstButtonReturn {
            let key = field.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
            if !key.isEmpty { aiManager.saveAPIKey(key) }
        }
    }
}

// MARK: - Bundle convenience

private extension Bundle {
    var shortVersionString: String {
        infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }
}
