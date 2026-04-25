import SwiftUI
import Core

// MARK: - Shell

/// Root SwiftUI view rendered inside the notch NSPanel.
///
/// Panel content is fully decoupled from this view: it reads the active plugin's
/// `panelView` from PluginManager (Core), keeping the UI module free of any
/// Features dependency.  The overlay mechanism lets SystemHUDManager temporarily
/// replace the active panel without touching the plugin stack.
public struct NotchShellView: View {

    @ObservedObject public  var viewModel: NotchViewModel
    @ObservedObject private var plugins   = PluginManager.shared

    @State private var showOnboarding = !UserDefaults.standard.hasSeenOnboarding

    public init(viewModel: NotchViewModel) { self.viewModel = viewModel }

    // MARK: Animation

    private let spring = Animation.spring(response: 0.35, dampingFraction: 0.7)

    // MARK: Derived geometry

    private var isExpanded: Bool { viewModel.isExpanded }
    private var pillWidth:  CGFloat { isExpanded ? NotchLayout.expandedWidth  : NotchLayout.collapsedWidth  }
    private var pillHeight: CGFloat { isExpanded ? NotchLayout.expandedHeight : NotchLayout.collapsedHeight }
    private var pillRadius: CGFloat { isExpanded ? 26 : 19 }

    // MARK: Body

    public var body: some View {
        ZStack(alignment: .top) {
            pill
            if isExpanded {
                // Aurora lives between the black pill and the content so it
                // glows through the panel without covering interactive elements.
                AuroraBackground(intensity: viewModel.backgroundIntensity)
                    .frame(width: NotchLayout.expandedWidth, height: NotchLayout.expandedHeight)
                    .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
                    .animation(.easeInOut(duration: 1.2), value: viewModel.backgroundIntensity)
                    .transition(.opacity.animation(.easeIn(duration: 0.14).delay(0.07)))
                expandedOverlay
                    .overlay {
                        if showOnboarding {
                            OnboardingOverlay {
                                UserDefaults.standard.hasSeenOnboarding = true
                                withAnimation(.easeOut(duration: 0.2)) { showOnboarding = false }
                            }
                            .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
                        }
                    }
            }
        }
        .frame(
            width:  NotchLayout.expandedWidth,
            height: NotchLayout.expandedHeight,
            alignment: .top
        )
        .onChange(of: isExpanded) { _, newValue in
            NotchWindowManager.shared.setExpanded(newValue)
        }
    }

    // MARK: - Pill

    private var pill: some View {
        ZStack {
            RoundedRectangle(cornerRadius: pillRadius, style: .continuous)
                .fill(Color.black)
            RoundedRectangle(cornerRadius: pillRadius, style: .continuous)
                .strokeBorder(innerGlowGradient, lineWidth: 0.75)
        }
        .frame(width: pillWidth, height: pillHeight)
        .animation(spring, value: isExpanded)
        .onHover { hovering in
            withAnimation(spring) {
                viewModel.isExpanded = hovering
                viewModel.hovering   = hovering
            }
        }
    }

    private var innerGlowGradient: LinearGradient {
        LinearGradient(
            stops: [
                .init(color: .white.opacity(0.20), location: 0.00),
                .init(color: .white.opacity(0.07), location: 0.38),
                .init(color: .clear,               location: 1.00),
            ],
            startPoint: .top,
            endPoint:   .bottom
        )
    }

    // MARK: - Expanded overlay

    private var expandedOverlay: some View {
        VStack(spacing: 0) {
            panelBody
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            pluginDock
        }
        .frame(
            width:  NotchLayout.expandedWidth,
            height: NotchLayout.expandedHeight
        )
        .transition(
            .asymmetric(
                insertion: .opacity.animation(.easeIn(duration: 0.14).delay(0.07)),
                removal:   .opacity.animation(.easeOut(duration: 0.09))
            )
        )
    }

    // MARK: - Panel body

    private var panelBody: some View {
        Group {
            // Overlay takes priority (system HUD), otherwise show active plugin.
            if let overlay = plugins.overlayPlugin {
                overlay.panelView
            } else if let active = plugins.activePlugin {
                active.panelView
            } else {
                Color.clear
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 12)
        .padding(.top, 8)
        .contentShape(Rectangle())
        .gesture(swipeGesture)
    }

    // MARK: - Plugin dock

    private var pluginDock: some View {
        VStack(spacing: 0) {
            Divider()
                .background(Color.white.opacity(0.08))

            HStack(spacing: 0) {
                // Skip the system plugin — it's an overlay, not a navigable panel.
                ForEach(plugins.enabledPlugins.filter { $0.id != "space.notch.system" }, id: \.id) { plugin in
                    dockIcon(for: plugin)
                }
            }
            .padding(.vertical, 4)
        }
    }

    private func dockIcon(for plugin: any NotchPlugin) -> some View {
        let isActive = plugins.activePlugin?.id == plugin.id && plugins.overlayPlugin == nil
        return Button {
            withAnimation(spring) { plugins.activate(plugin) }
        } label: {
            Image(systemName: plugin.icon)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(isActive ? Color.white : Color.white.opacity(0.27))
                .frame(width: 40, height: 20)
                .background(
                    isActive
                        ? Color.white.opacity(0.10)
                        : Color.clear,
                    in: RoundedRectangle(cornerRadius: 6, style: .continuous)
                )
                .animation(spring, value: isActive)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Swipe gesture

    private var swipeGesture: some Gesture {
        DragGesture(minimumDistance: 24, coordinateSpace: .local)
            .onEnded { v in
                guard plugins.overlayPlugin == nil else { return }
                if      v.translation.width < -50 { withAnimation(spring) { plugins.activateNext() } }
                else if v.translation.width >  50 { withAnimation(spring) { plugins.activatePrev() } }
            }
    }
}
