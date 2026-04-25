import SwiftUI

// MARK: - Protocol

/// A panel that can be shown inside the expanded notch.
///
/// External plugins are loaded from .notchplugin bundles.  The principal class
/// in each bundle must be an NSObject subclass that conforms to this protocol.
/// Built-in features conform directly (no NSObject requirement for them).
public protocol NotchPlugin: AnyObject {
    /// Stable reverse-DNS identifier, e.g. "space.notch.media".
    var id:   String { get }
    var name: String { get }
    /// SF Symbol name used in the dock.
    var icon: String { get }
    /// The view rendered inside the expanded panel while this plugin is active.
    var panelView: AnyView { get }

    func onActivate()
    func onDeactivate()
}

// Default no-ops so built-in plugins only override when needed.
public extension NotchPlugin {
    func onActivate()   {}
    func onDeactivate() {}
}
