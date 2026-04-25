import Foundation
import SwiftUI

// MARK: - Manager

@MainActor
public final class PluginManager: ObservableObject {

    public static let shared = PluginManager()

    /// All registered plugins in insertion order.
    @Published public private(set) var plugins: [any NotchPlugin] = []

    /// Currently active plugin (shown in the panel body).
    @Published public private(set) var activePlugin: (any NotchPlugin)?

    /// Temporary overlay — takes display priority over `activePlugin`.
    /// Set by SystemHUDManager for the volume/brightness HUD.
    @Published public private(set) var overlayPlugin: (any NotchPlugin)?

    /// IDs of plugins the user has explicitly disabled.
    @Published public private(set) var disabledIDs: Set<String> = {
        Set(UserDefaults.standard.stringArray(forKey: "notchspace.disabled.plugins") ?? [])
    }()

    private var overlayTask: DispatchWorkItem?
    private static let disabledKey = "notchspace.disabled.plugins"

    private init() {}

    // MARK: - Registration

    public func register(_ plugin: any NotchPlugin) {
        guard !plugins.contains(where: { $0.id == plugin.id }) else { return }
        plugins.append(plugin)
        if activePlugin == nil && isEnabled(plugin) {
            activePlugin = plugin
        }
    }

    // MARK: - Activation

    public func activate(_ plugin: any NotchPlugin) {
        guard isEnabled(plugin) else { return }
        guard activePlugin?.id != plugin.id else { return }
        activePlugin?.onDeactivate()
        activePlugin = plugin
        plugin.onActivate()
    }

    public func activateNext() { cycleActive(by: +1) }
    public func activatePrev() { cycleActive(by: -1) }

    private func cycleActive(by step: Int) {
        let enabled = enabledPlugins
        guard !enabled.isEmpty,
              let current = activePlugin,
              let idx = enabled.firstIndex(where: { $0.id == current.id })
        else { return }
        let next = enabled[(idx + step + enabled.count) % enabled.count]
        activate(next)
    }

    // MARK: - Overlay (temporary HUD takeover)

    public func showOverlay(_ plugin: any NotchPlugin) {
        overlayTask?.cancel()
        overlayPlugin = plugin
        plugin.onActivate()
    }

    public func dismissOverlay() {
        overlayTask?.cancel()
        overlayTask = nil
        overlayPlugin?.onDeactivate()
        overlayPlugin = nil
    }

    // MARK: - Enable / disable

    public func isEnabled(_ plugin: any NotchPlugin) -> Bool {
        !disabledIDs.contains(plugin.id)
    }

    public func setEnabled(_ plugin: any NotchPlugin, _ enabled: Bool) {
        if enabled {
            disabledIDs.remove(plugin.id)
            if activePlugin == nil {
                activePlugin = plugin
            }
        } else {
            disabledIDs.insert(plugin.id)
            if activePlugin?.id == plugin.id {
                activePlugin = enabledPlugins.first
                activePlugin?.onActivate()
            }
        }
        UserDefaults.standard.set(Array(disabledIDs), forKey: Self.disabledKey)
    }

    public var enabledPlugins: [any NotchPlugin] {
        plugins.filter { isEnabled($0) }
    }

    // MARK: - External bundle loading

    /// Scans ~/Library/Application Support/NotchSpace/Plugins/ for .notchplugin bundles.
    /// The principal class in each bundle must be an NSObject subclass conforming to NotchPlugin.
    public func loadExternalPlugins() {
        guard let dir = FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)
            .first?
            .appendingPathComponent("NotchSpace/Plugins")
        else { return }

        let urls = (try? FileManager.default.contentsOfDirectory(
            at: dir,
            includingPropertiesForKeys: nil
        ))?.filter { $0.pathExtension == "notchplugin" } ?? []

        for url in urls {
            guard let bundle = Bundle(url: url), bundle.load() else { continue }
            guard let cls = bundle.principalClass as? NSObject.Type else { continue }
            guard let plugin = cls.init() as? any NotchPlugin else { continue }
            register(plugin)
        }
    }
}
