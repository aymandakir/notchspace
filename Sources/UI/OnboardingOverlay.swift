import SwiftUI

// MARK: - OnboardingOverlay

/// Brief first-launch tip card shown the first time the notch expands.
///
/// Dismisses automatically after 5 s or immediately on tap.
/// The seen flag is stored in UserDefaults under "notchspace.onboarding.v1"
/// so a future feature update can use "v2" to re-show a revised overlay.
public struct OnboardingOverlay: View {

    public let onDismiss: () -> Void

    @State private var opacity:  Double = 0
    @State private var appeared: Bool   = false

    private let hints: [(symbol: String, label: String)] = [
        ("cursorarrow.motionlines", "Hover to expand"),
        ("arrow.left.arrow.right",  "Swipe panels"),
        ("hand.tap",                "Tap icons"),
    ]

    public init(onDismiss: @escaping () -> Void) {
        self.onDismiss = onDismiss
    }

    public var body: some View {
        ZStack {
            // Frosted-glass dark background
            Color.black.opacity(0.78)
                .background(.ultraThinMaterial)

            VStack(spacing: 10) {
                hintRow
                    .padding(.top, 6)

                Text("Tap anywhere to dismiss")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(.white.opacity(0.28))
                    .padding(.bottom, 4)
            }
        }
        .opacity(opacity)
        .onTapGesture(perform: dismiss)
        .onAppear {
            withAnimation(.easeIn(duration: 0.25)) { opacity = 1 }
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) { dismiss() }
        }
    }

    // MARK: - Layout

    private var hintRow: some View {
        HStack(spacing: 0) {
            ForEach(hints, id: \.symbol) { hint in
                VStack(spacing: 7) {
                    Image(systemName: hint.symbol)
                        .font(.system(size: 22, weight: .light))
                        .foregroundStyle(.white.opacity(0.72))
                        .frame(height: 28)
                    Text(hint.label)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(.white.opacity(0.48))
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, 12)
    }

    // MARK: - Dismiss

    private func dismiss() {
        guard !appeared else { return }
        appeared = true
        withAnimation(.easeOut(duration: 0.25)) { opacity = 0 }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25, execute: onDismiss)
    }
}

// MARK: - Seen flag

public extension UserDefaults {
    var hasSeenOnboarding: Bool {
        get { bool(forKey: "notchspace.onboarding.v1") }
        set { set(newValue, forKey: "notchspace.onboarding.v1") }
    }
}
