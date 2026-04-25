import AppKit
import SwiftUI

// MARK: - Dimensions (shared source of truth)

public enum NotchLayout {
    public static let collapsedWidth:  CGFloat = 200
    public static let collapsedHeight: CGFloat = 38
    public static let expandedWidth:   CGFloat = 500
    public static let expandedHeight:  CGFloat = 132
}

// MARK: - Panel

public final class NotchWindowManager {

    public static let shared = NotchWindowManager()

    private var panel:          NSPanel?
    private var isExpanded      = false
    private var screenObserver: Any?

    private init() {}

    deinit {
        if let obs = screenObserver { NotificationCenter.default.removeObserver(obs) }
    }

    // MARK: - Configuration

    /// Call once at launch with any SwiftUI view.
    /// Generic keeps Core free of a UI-module dependency.
    public func configure<Content: View>(with content: Content) {
        let screen = Self.notchScreen()
        let frame  = Self.notchFrame(for: screen)

        let p = NotchPanel(
            contentRect: frame,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        p.backgroundColor = .clear
        p.isOpaque        = false
        p.hasShadow       = false

        // Float above every other window, including full-screen apps.
        // .screenSaver (1000) is the highest named level; +1 clears it too.
        p.level = NSWindow.Level(rawValue: NSWindow.Level.screenSaver.rawValue + 1)

        // Visible on every Space; never repositioned by Mission Control.
        p.collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenNone, .ignoresCycle]

        p.hidesOnDeactivate         = false
        p.isMovable                 = false
        p.isMovableByWindowBackground = false
        p.acceptsMouseMovedEvents   = true

        let host = PassthroughHostingView(rootView: content)
        host.frame = NSRect(origin: .zero, size: frame.size)
        p.contentView = host

        self.panel = p
        setupScreenObserver()
    }

    // MARK: - Visibility

    public func show() { panel?.orderFrontRegardless() }
    public func hide() { panel?.orderOut(nil) }

    // MARK: - Expand / collapse

    /// Resize the panel to give the SwiftUI view room to animate.
    ///
    /// - Expand:  resize immediately so the view has canvas before the spring begins.
    /// - Collapse: delay until the spring settles (~0.4 s) to prevent clipping.
    public func setExpanded(_ expanded: Bool) {
        isExpanded = expanded
        let screen = Self.notchScreen()

        let resize = { [weak self] in
            guard let p = self?.panel else { return }
            let target = expanded
                ? Self.expandedPanelFrame(for: screen)
                : Self.notchFrame(for: screen)
            p.setFrame(target, display: true, animate: false)
            p.contentView?.frame = NSRect(origin: .zero, size: target.size)
        }

        if expanded {
            resize()
        } else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.40, execute: resize)
        }
    }

    // MARK: - Multi-monitor

    /// Returns the screen that physically hosts the hardware notch.
    ///
    /// The notch display reports a non-zero `safeAreaInsets.top` on macOS 12+.
    /// When multiple screens have insets (unlikely), we prefer the one with the
    /// tallest inset.  Falls back to `NSScreen.main` on non-notch hardware.
    public static func notchScreen() -> NSScreen {
        let candidate = NSScreen.screens
            .max(by: { $0.safeAreaInsets.top < $1.safeAreaInsets.top })
        if let screen = candidate, screen.safeAreaInsets.top > 0 { return screen }
        return NSScreen.main ?? NSScreen.screens[0]
    }

    private func setupScreenObserver() {
        screenObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.repositionPanel()
        }
    }

    private func repositionPanel() {
        guard let p = panel else { return }
        let screen = Self.notchScreen()
        let target = isExpanded
            ? Self.expandedPanelFrame(for: screen)
            : Self.notchFrame(for: screen)
        p.setFrame(target, display: true, animate: false)
        p.contentView?.frame = NSRect(origin: .zero, size: target.size)
    }

    // MARK: - Geometry

    /// The frame that exactly covers the physical notch on `screen`.
    public static func notchFrame(for screen: NSScreen = notchScreen()) -> NSRect {
        let sf  = screen.frame
        let top = screen.safeAreaInsets.top
        let h: CGFloat = top > 0 ? top : NotchLayout.collapsedHeight

        if let left  = screen.auxiliaryTopLeftArea,
           let right = screen.auxiliaryTopRightArea,
           right.minX > left.maxX {
            return NSRect(x: left.maxX, y: sf.maxY - h,
                          width: right.minX - left.maxX, height: h)
        }

        let w = NotchLayout.collapsedWidth
        return NSRect(x: sf.midX - w / 2, y: sf.maxY - h, width: w, height: h)
    }

    /// Panel frame for the expanded state: centered on the notch, growing downward.
    public static func expandedPanelFrame(for screen: NSScreen = notchScreen()) -> NSRect {
        let notch = notchFrame(for: screen)
        return NSRect(
            x:      notch.midX - NotchLayout.expandedWidth  / 2,
            y:      notch.maxY - NotchLayout.expandedHeight,
            width:  NotchLayout.expandedWidth,
            height: NotchLayout.expandedHeight
        )
    }
}

// MARK: - NotchPanel

/// NSPanel subclass that prevents any activation of the app.
private final class NotchPanel: NSPanel {
    override var canBecomeKey:  Bool { false }
    override var canBecomeMain: Bool { false }
}

// MARK: - PassthroughHostingView

/// NSHostingView that passes mouse events through to the desktop in areas
/// where SwiftUI renders nothing (transparent background).
private final class PassthroughHostingView<Content: View>: NSHostingView<Content> {
    override func hitTest(_ point: NSPoint) -> NSView? {
        let hit = super.hitTest(point)
        return hit === self ? nil : hit
    }
}
