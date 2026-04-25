import SwiftUI
import Core

// MARK: - Panel

/// Shown inside the notch shell when a volume or brightness key is pressed.
/// Receives live values directly from `NotchViewModel` so it re-renders on every change.
public struct SystemHUDPanel: View {

    @ObservedObject public var viewModel: NotchViewModel

    private let spring = Animation.spring(response: 0.35, dampingFraction: 0.7)

    public init(viewModel: NotchViewModel) {
        self.viewModel = viewModel
    }

    // MARK: - Body

    public var body: some View {
        HStack(spacing: 14) {
            icon
                .frame(width: 28, height: 28)

            levelBar
        }
        .padding(.horizontal, 4)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Icon

    private var icon: some View {
        Image(systemName: iconName)
            .font(.system(size: 20, weight: .medium))
            .foregroundStyle(glowColor.opacity(0.9))
            .shadow(color: glowColor.opacity(0.6), radius: 6)
            .contentTransition(.symbolEffect(.replace))
            .animation(spring, value: viewModel.hudMuted)
            .animation(spring, value: viewModel.hudLevel)
    }

    private var iconName: String {
        switch viewModel.hudType {
        case .volume:
            if viewModel.hudMuted  { return "speaker.slash.fill" }
            if viewModel.hudLevel < 0.01 { return "speaker.fill" }
            if viewModel.hudLevel < 0.34 { return "speaker.wave.1.fill" }
            if viewModel.hudLevel < 0.67 { return "speaker.wave.2.fill" }
            return "speaker.wave.3.fill"
        case .brightness:
            return viewModel.hudLevel < 0.15 ? "sun.min.fill" : "sun.max.fill"
        }
    }

    // MARK: - Level bar

    private var levelBar: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                // Track
                Capsule()
                    .fill(Color.white.opacity(0.10))
                    .frame(height: barHeight)

                // Fill
                Capsule()
                    .fill(fillGradient)
                    .frame(
                        width: max(barHeight, geo.size.width * clampedLevel),
                        height: barHeight
                    )
                    // Outer glow — two layers for depth
                    .shadow(color: glowColor.opacity(0.55), radius: 8,  x: 0, y: 0)
                    .shadow(color: glowColor.opacity(0.25), radius: 18, x: 0, y: 0)
                    .animation(spring, value: viewModel.hudLevel)
                    .animation(spring, value: viewModel.hudMuted)
            }
            .frame(height: geo.size.height, alignment: .center)
        }
        .frame(height: 40)  // gives the glow vertical room
    }

    private var barHeight: CGFloat { 7 }

    private var clampedLevel: CGFloat {
        viewModel.hudMuted ? 0 : CGFloat(max(0, min(1, viewModel.hudLevel)))
    }

    // MARK: - Theming

    private var glowColor: Color {
        switch viewModel.hudType {
        case .volume:
            return viewModel.hudMuted ? .gray : .white
        case .brightness:
            // Warm yellow-white for brightness
            return Color(red: 1.0, green: 0.92, blue: 0.6)
        }
    }

    private var fillGradient: LinearGradient {
        switch viewModel.hudType {
        case .volume:
            return LinearGradient(
                colors: [.white, Color(white: 0.82)],
                startPoint: .leading,
                endPoint: .trailing
            )
        case .brightness:
            return LinearGradient(
                colors: [
                    Color(red: 1.0, green: 0.95, blue: 0.75),
                    Color(red: 1.0, green: 0.78, blue: 0.30),
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
        }
    }
}
