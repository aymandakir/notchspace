import SwiftUI
import Combine
import LaunchAtLogin
import Sparkle
import Core
import UI
import Features

// MARK: - Intensity driver

// @MainActor so it can safely subscribe to @MainActor-isolated publishers.
@MainActor
private final class IntensityDriver {
    private var cancellables = Set<AnyCancellable>()

    init(viewModel: NotchViewModel) {
        Publishers.CombineLatest(
            MediaManager.shared.$isPlaying,
            AIAssistantManager.shared.$isLoading
        )
        .receive(on: RunLoop.main)
        .map { isPlaying, isLoading -> Float in
            if isLoading { return 0.65 }
            if isPlaying { return 0.28 }
            return 0.0
        }
        .removeDuplicates()
        .sink { [weak viewModel] intensity in
            // Capture weak ref as a local let before the Task boundary to
            // avoid the "captured var in concurrently-executing code" error.
            let vm = viewModel
            Task { @MainActor in vm?.backgroundIntensity = intensity }
        }
        .store(in: &cancellables)
    }
}

// MARK: - App

// @MainActor ensures that stored-property inline initializers (NotchViewModel(),
// SPUStandardUpdaterController, etc.) are evaluated on the main actor, which
// satisfies the actor-isolation requirements of those @MainActor types.
@MainActor
@main
struct NotchSpaceApp: App {

    private let viewModel          = NotchViewModel()
    private let updaterController  = SPUStandardUpdaterController(
        startingUpdater:    true,
        updaterDelegate:    nil,
        userDriverDelegate: nil
    )
    private let intensityDriver: IntensityDriver

    init() {
        // 1. Register built-in plugins (order determines dock order).
        let pm = PluginManager.shared
        pm.register(MediaPlugin())
        pm.register(ClipboardPlugin())
        pm.register(AIPlugin())
        pm.register(FocusPlugin())
        pm.register(SystemPlugin(viewModel: viewModel))

        // 2. Load any .notchplugin bundles the user has installed.
        pm.loadExternalPlugins()

        // 3. Mount the notch panel.
        NotchWindowManager.shared.configure(with: NotchShellView(viewModel: viewModel))
        NotchWindowManager.shared.show()

        // 4. Start feature managers.
        SystemHUDManager.shared.start(with: viewModel)
        MediaManager.shared.start()
        ClipboardManager.shared.start()

        // 5. Drive aurora shader intensity from feature state.
        intensityDriver = IntensityDriver(viewModel: viewModel)
    }

    var body: some Scene {
        Settings {
            SettingsView(updater: updaterController.updater)
        }

        MenuBarExtra("NotchSpace", systemImage: "rectangle.topthird.inset.filled") {
            Button("Settings…") {
                NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
                NSApp.activate(ignoringOtherApps: true)
            }
            .keyboardShortcut(",")

            Button("About NotchSpace") {
                NSApp.orderFrontStandardAboutPanel(nil)
                NSApp.activate(ignoringOtherApps: true)
            }

            Divider()

            Button("Quit NotchSpace", role: .destructive) {
                NSApp.terminate(nil)
            }
            .keyboardShortcut("q")
        }
    }
}
