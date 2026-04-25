import AppKit
import CoreAudio
import IOKit
import SwiftUI
import Core

// MARK: - Private CoreGraphics Services API
//
// CGSSetConnectionProperty lets us disable the BezelServices OSD overlay
// (the system volume / brightness HUD) on a per-connection basis.
// These symbols live in CoreGraphics but are not in any public header.
// App Sandbox must be OFF for this to have any effect.

private typealias CGSConnectionID = UInt32

@_silgen_name("CGSMainConnectionID")
private func CGSMainConnectionID() -> CGSConnectionID

@_silgen_name("CGSSetConnectionProperty")
@discardableResult
private func CGSSetConnectionProperty(
    _ cid: CGSConnectionID,
    _ toConnection: CGSConnectionID,
    _ key: CFString,
    _ value: CFTypeRef?
) -> Int32

// MARK: - NX media-key codes  (IOKit/hidsystem/IOLLEvent.h)

private enum MediaKey: Int32 {
    case soundUp        = 0
    case soundDown      = 1
    case brightnessUp   = 2
    case brightnessDown = 3
    case mute           = 7
}

// MARK: - Manager

/// Intercepts global media-key events, suppresses the macOS bezel HUD,
/// and drives `NotchViewModel` to show the custom `SystemHUDPanel`.
@MainActor
public final class SystemHUDManager {

    public static let shared = SystemHUDManager()

    private weak var viewModel: NotchViewModel?
    private var eventMonitor: Any?
    private var collapseWork: DispatchWorkItem?

    private init() {}

    // MARK: - Lifecycle

    /// Call from the App's `init()` on the main thread.
    public func start(with viewModel: NotchViewModel) {
        self.viewModel = viewModel
        suppressBezelHUD()
        installMediaKeyMonitor()
    }

    public func stop() {
        if let m = eventMonitor { NSEvent.removeMonitor(m) }
        eventMonitor = nil
        collapseWork?.cancel()
    }

    // MARK: - Bezel suppression
    //
    // The "Bezel" connection property is an undocumented key recognised by
    // the WindowServer / BezelServices to enable or disable the per-process
    // OSD overlay.  Setting it to kCFBooleanFalse prevents the system from
    // drawing its own HUD for this connection.
    //
    // If this key is ever retired by Apple, replacing with a CGEventTap at
    // .cgHIDEventTap that consumes NX_SYSDEFINED events is the nuclear option
    // (requires Accessibility permission from the user).

    private func suppressBezelHUD() {
        let conn = CGSMainConnectionID()
        CGSSetConnectionProperty(conn, conn, "Bezel" as CFString, kCFBooleanFalse)
    }

    // MARK: - Event monitor
    //
    // NSEvent.addGlobalMonitorForEvents fires on the main thread when registered
    // from the main thread, so viewModel mutations here are safe.

    private func installMediaKeyMonitor() {
        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: .systemDefined) { [weak self] event in
            Task { @MainActor [weak self] in self?.handle(event) }
        }
    }

    private func handle(_ event: NSEvent) {
        // NX_SYSDEFINED subtype 8 carries media-key data
        guard event.type == .systemDefined, event.subtype.rawValue == 8 else { return }

        let rawKey  = Int32((event.data1 & 0xFFFF_0000) >> 16)
        let keyDown = (event.data1 & 0x0000_FF00) >> 8 == 0xA
        guard keyDown, let key = MediaKey(rawValue: rawKey) else { return }

        // Allow a brief settle so CoreAudio / IOKit state reflects the key press
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { [weak self] in
            switch key {
            case .soundUp, .soundDown, .mute:
                self?.showVolumeHUD()
            case .brightnessUp, .brightnessDown:
                self?.showBrightnessHUD()
            }
        }
    }

    // MARK: - Trigger HUD

    private func showVolumeHUD() {
        guard let vm = viewModel else { return }
        vm.hudType  = .volume
        vm.hudLevel = Self.readSystemVolume()
        vm.hudMuted = Self.readMuted()
        presentHUD(vm)
    }

    private func showBrightnessHUD() {
        guard let vm = viewModel else { return }
        vm.hudType  = .brightness
        vm.hudLevel = Self.readScreenBrightness()
        vm.hudMuted = false
        presentHUD(vm)
    }

    private func presentHUD(_ vm: NotchViewModel) {
        // Show the system plugin as a temporary overlay (non-dock panel).
        if let systemPlugin = PluginManager.shared.plugins.first(where: { $0.id == "space.notch.system" }) {
            PluginManager.shared.showOverlay(systemPlugin)
        }
        withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
            vm.isExpanded = true
        }
        scheduleCollapse(vm)
    }

    /// Resets the 1.5 s auto-collapse timer on every key press.
    /// Respects an active hover state — won't collapse while the cursor is inside.
    private func scheduleCollapse(_ vm: NotchViewModel) {
        collapseWork?.cancel()
        let work = DispatchWorkItem { [weak vm] in
            guard let vm, !vm.hovering else { return }
            PluginManager.shared.dismissOverlay()
            withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                vm.isExpanded = false
            }
        }
        collapseWork = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5, execute: work)
    }

    // MARK: - System value readers

    private static func readSystemVolume() -> Double {
        var deviceID  = AudioDeviceID(0)
        var size      = UInt32(MemoryLayout<AudioDeviceID>.size)
        var hwAddress = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultOutputDevice,
            mScope:    kAudioObjectPropertyScopeGlobal,
            mElement:  kAudioObjectPropertyElementMain
        )
        AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &hwAddress, 0, nil, &size, &deviceID
        )

        var volume: Float32 = 0
        var volSize = UInt32(MemoryLayout<Float32>.size)
        var volAddr = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyVolumeScalar,
            mScope:    kAudioDevicePropertyScopeOutput,
            mElement:  kAudioObjectPropertyElementMain
        )
        // Try master channel first, then left channel (element 1) as fallback
        if AudioObjectGetPropertyData(deviceID, &volAddr, 0, nil, &volSize, &volume) == noErr {
            return Double(volume)
        }
        volAddr.mElement = 1
        volSize = UInt32(MemoryLayout<Float32>.size)
        if AudioObjectGetPropertyData(deviceID, &volAddr, 0, nil, &volSize, &volume) == noErr {
            return Double(volume)
        }
        return 0
    }

    private static func readMuted() -> Bool {
        var deviceID  = AudioDeviceID(0)
        var size      = UInt32(MemoryLayout<AudioDeviceID>.size)
        var hwAddress = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultOutputDevice,
            mScope:    kAudioObjectPropertyScopeGlobal,
            mElement:  kAudioObjectPropertyElementMain
        )
        AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &hwAddress, 0, nil, &size, &deviceID
        )

        var muted: UInt32 = 0
        var muteSize = UInt32(MemoryLayout<UInt32>.size)
        var muteAddr = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyMute,
            mScope:    kAudioDevicePropertyScopeOutput,
            mElement:  kAudioObjectPropertyElementMain
        )
        AudioObjectGetPropertyData(deviceID, &muteAddr, 0, nil, &muteSize, &muted)
        return muted != 0
    }

    /// Reads the primary display's user brightness via IOKit.
    /// Returns 0.5 on Apple Silicon or when the display service is unavailable.
    private static func readScreenBrightness() -> Double {
        var iterator: io_iterator_t = 0
        guard IOServiceGetMatchingServices(
            0,  // kIOMainPortDefault
            IOServiceMatching("IODisplayConnect"),
            &iterator
        ) == KERN_SUCCESS else { return 0.5 }
        defer { IOObjectRelease(iterator) }

        let service = IOIteratorNext(iterator)
        guard service != 0 else { return 0.5 }
        defer { IOObjectRelease(service) }

        var brightness: Float = 0.5
        IODisplayGetFloatParameter(service, 0, "brightness" as CFString, &brightness)
        return Double(brightness)
    }
}
