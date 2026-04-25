import SwiftUI
import Combine

// MARK: - HUD type

public enum HUDType: Equatable, Sendable {
    case volume
    case brightness
}

// MARK: - ViewModel

@MainActor
public final class NotchViewModel: ObservableObject {

    /// Whether the notch panel is in its expanded state.
    @Published public var isExpanded: Bool = false

    /// True while the cursor is inside the notch hit-area.
    @Published public var hovering: Bool = false

    /// Aurora shader intensity, 0–1. Driven by App layer via IntensityDriver.
    /// 0 = barely-visible shimmer, 1 = vivid glow.
    @Published public var backgroundIntensity: Float = 0

    // MARK: HUD state — written by SystemHUDManager, read by SystemHUDPanel

    @Published public var hudLevel: Double  = 0.0
    @Published public var hudType:  HUDType = .volume
    @Published public var hudMuted: Bool    = false

    public init() {}
}
