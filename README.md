# NotchSpace

[![CI](https://github.com/YOUR_USERNAME/notchspace/actions/workflows/build.yml/badge.svg)](https://github.com/YOUR_USERNAME/notchspace/actions/workflows/build.yml)
![macOS 14+](https://img.shields.io/badge/macOS-14%2B-black?logo=apple)
![Swift 5.9](https://img.shields.io/badge/Swift-5.9-orange?logo=swift)
![License MIT](https://img.shields.io/badge/license-MIT-blue)

> **Live inside your notch.** NotchSpace turns the MacBook Pro notch from dead space into a persistent command center — media controls, clipboard history, AI assistant, Pomodoro timer, and an open plugin API, all hovering above your content.

<!-- Replace with actual screenshots -->
```
┌─────────────────────────────────────────────────────┐
│           [ ◼ NotchSpace collapsed ]                │
│        hover → expands to full panel ↓              │
└─────────────────────────────────────────────────────┘
```

---

## Features

| Feature | Description |
|---------|-------------|
| 🎵 **Media Player** | Album art, scrolling title/artist, transport controls, 12-bar real-time audio visualizer |
| 📋 **Clipboard History** | Last 10 entries, one-tap re-copy with green glow feedback, swipe to delete |
| ✨ **AI Assistant** | OpenAI-compatible API (OpenRouter, Ollama, etc.), streaming responses, Keychain-stored key |
| ⏱ **Focus Timer** | Standard Pomodoro — 4× 25/5 min cycles then 15 min long break, notifications + NSSound |
| 🎨 **Aurora Shader** | Reactive Metal background that pulses with music and AI activity |
| 🎛 **System HUD** | Intercepts volume/brightness keys, replaces the macOS stock bezel overlay |
| 🔌 **Plugin API** | Drop `.notchplugin` bundles into `~/Library/Application Support/NotchSpace/Plugins/` |
| ↕ **Smart expand** | Hover to expand, swipe to switch panels, auto-collapses when cursor leaves |
| 🖥 **Multi-monitor** | Always positions on the notch screen; repositions automatically on display changes |

---

## Requirements

- **macOS 14 Sonoma** or later
- **MacBook Pro with notch** (M1 Pro/Max/Ultra, M2, M3, or M4 series)
- Xcode 15+ (to build from source)

> The app launches and runs on any Mac but the panel is centred at the top of the primary display when no notch screen is detected.

---

## Installation

### Option 1 — DMG (recommended)

1. Download the latest `NotchSpace-x.x.x.dmg` from [Releases](https://github.com/YOUR_USERNAME/notchspace/releases)
2. Open the DMG and drag **NotchSpace.app** to `/Applications`
3. Launch — grant Accessibility permission when prompted (needed for media-key interception)

### Option 2 — Homebrew Cask

```bash
brew tap YOUR_USERNAME/notchspace
brew install --cask notchspace
```

### Option 3 — Build from source

```bash
git clone https://github.com/YOUR_USERNAME/notchspace.git
cd notchspace

# Generate the app icon (requires macOS, run once)
swift Scripts/GenerateIcon.swift

# Open in Xcode — SPM dependencies are resolved automatically
open Package.swift
```

Select the **NotchSpace** scheme, choose **My Mac** as the destination, and press **⌘R**.

---

## Permissions

NotchSpace requests the following permissions at first launch:

| Permission | Why |
|-----------|-----|
| **Accessibility** | Global media-key monitoring (`NSEvent.addGlobalMonitorForEvents`) |
| **Notifications** | Focus Timer completion alerts |

No network access is required unless you configure the AI Assistant.

---

## Plugin Development Guide

NotchSpace exposes a public plugin protocol so you can add custom panels without modifying the main app.

### 1. Create the package

```bash
swift package init --type library --name MyPlugin
```

### 2. Add `NotchSpace` as a dependency

In `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/YOUR_USERNAME/notchspace.git", from: "1.0.0"),
],
targets: [
    .target(name: "MyPlugin", dependencies: [
        .product(name: "Core", package: "notchspace"),
    ]),
]
```

### 3. Implement `NotchPlugin`

```swift
import SwiftUI
import Core

@objc public final class MyPlugin: NSObject, NotchPlugin {

    public let id   = "com.yourname.myplugin"
    public let name = "My Plugin"
    public let icon = "star.fill"          // SF Symbol name

    public var panelView: AnyView {
        AnyView(MyPanelView())
    }

    public func onActivate()   { /* called when user switches to this panel */ }
    public func onDeactivate() { /* called when user switches away */ }
}
```

> **Note:** External plugin classes must inherit from `NSObject` so the bundle loader can instantiate them via the Objective-C runtime.

### 4. Declare the principal class

In your target's `Info.plist`:

```xml
<key>NSPrincipalClass</key>
<string>MyPlugin.MyPlugin</string>
```

### 5. Bundle and install

```bash
# Build a release dylib
swift build -c release

# Copy to the plugins directory (the app loads it on next launch)
mkdir -p ~/Library/Application\ Support/NotchSpace/Plugins/
cp -r .build/release/MyPlugin ~/Library/Application\ Support/NotchSpace/Plugins/MyPlugin.notchplugin
```

### Plugin lifecycle

```
App launch
  └─ PluginManager.loadExternalPlugins()
       └─ Bundle.load() → NSObject.init() as NotchPlugin → register()
            └─ onActivate() called when user taps dock icon
            └─ onDeactivate() called when user taps another dock icon
```

---

## Architecture

NotchSpace uses a strict acyclic module graph:

```
App  →  Features  →  UI  →  Core
 ↓           ↓
Utilities   Utilities
```

| Module | Responsibility |
|--------|----------------|
| **Core** | `NotchWindowManager`, `NotchViewModel`, `PluginManager`, `NotchPlugin` protocol — no SwiftUI views |
| **UI** | `NotchShellView`, `MetalView`/aurora shader, `OnboardingOverlay` — pure SwiftUI, no feature managers |
| **Features** | Self-contained panels (Media, Clipboard, AI, Focus, SystemHUD) + built-in plugin wrappers |
| **App** | Wires everything together, hosts `MenuBarExtra`, `SettingsView`, `IntensityDriver` |
| **Utilities** | Foundation/AppKit extensions |

### Key design decisions

- **Generic shell view injection** was replaced by the `NotchPlugin` protocol: `UI` never imports `Features` because plugin content arrives as `AnyView` through `Core.PluginManager`.
- **Private framework safety**: `MediaRemote.framework` and `CGSSetConnectionProperty` are loaded dynamically (`CFBundleCreate` + `CFBundleGetFunctionPointerForName`) so the app degrades gracefully on simulator or restricted environments.
- **Metal aurora** uses a single fullscreen triangle (no vertex buffer) with source-over alpha blending. The `MTKView` is paused when intensity is 0 to eliminate idle GPU usage.
- **Keyboard interception** uses `NSEvent.addGlobalMonitorForEvents`. App Sandbox must be **OFF**.

---

## Contributing

1. Fork the repo and create a feature branch (`git checkout -b feat/my-feature`)
2. Write your changes. The project has no external test infrastructure yet — add tests under `Tests/` if your change has meaningful unit-testable logic.
3. Run `swift build` to verify nothing is broken.
4. Open a pull request. CI will run `swift build` on each target and (eventually) `swift test`.

### Code style

- SwiftUI views: keep state in `@ObservedObject` managers, not in view state.
- No third-party UI dependencies — everything uses SwiftUI + AppKit + Metal.
- Comments only for non-obvious WHY, never for WHAT.
- `@MainActor` on all `ObservableObject` subclasses.

### Reporting bugs

Please include:
- macOS version and Mac model
- Whether any `.notchplugin` bundles are installed
- Console output from `Console.app` filtered by `NotchSpace`

---

## License

MIT — see [LICENSE](LICENSE).

---

*Built with Swift, SwiftUI, Metal, and a deep appreciation for hardware that ships with dead space.*
