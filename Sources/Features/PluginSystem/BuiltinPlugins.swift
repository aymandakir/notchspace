import SwiftUI
import Core

// MARK: - Built-in plugin wrappers
//
// Each class is a thin NotchPlugin (Core) adapter around an existing manager + panel.
// SystemPlugin is never shown in the dock — it is used exclusively as a temporary
// overlay by SystemHUDManager when volume/brightness keys fire.

// MARK: Media

public final class MediaPlugin: NotchPlugin {
    public let id   = "space.notch.media"
    public let name = "Media"
    public let icon = "music.note"
    public var panelView: AnyView { AnyView(MediaPanel(media: MediaManager.shared)) }
    public init() {}
}

// MARK: Clipboard

public final class ClipboardPlugin: NotchPlugin {
    public let id   = "space.notch.clipboard"
    public let name = "Clipboard"
    public let icon = "doc.on.clipboard"
    public var panelView: AnyView { AnyView(ClipboardPanel(manager: ClipboardManager.shared)) }
    public init() {}
}

// MARK: System HUD (overlay-only)

public final class SystemPlugin: NotchPlugin {
    public let id   = "space.notch.system"
    public let name = "System HUD"
    public let icon = "dial.medium"

    private weak var viewModel: NotchViewModel?

    public init(viewModel: NotchViewModel) { self.viewModel = viewModel }

    public var panelView: AnyView {
        guard let vm = viewModel else { return AnyView(Color.clear) }
        return AnyView(SystemHUDPanel(viewModel: vm))
    }
}

// MARK: AI Assistant

public final class AIPlugin: NotchPlugin {
    public let id   = "space.notch.ai"
    public let name = "AI"
    public let icon = "sparkles"
    public var panelView: AnyView { AnyView(AIPanel(manager: AIAssistantManager.shared)) }
    public init() {}
}

// MARK: Focus Timer

public final class FocusPlugin: NotchPlugin {
    public let id   = "space.notch.focus"
    public let name = "Focus"
    public let icon = "timer"
    public var panelView: AnyView { AnyView(FocusTimerPanel(manager: FocusTimerManager.shared)) }
    public init() {}
}
