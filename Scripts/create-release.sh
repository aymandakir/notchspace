#!/usr/bin/env bash
# create-release.sh — Publishes the GitHub release for v1.0.0.
# Prerequisites: gh auth login

set -euo pipefail

gh release create v1.0.0 \
  --repo aymandakir/notchspace \
  --title "NotchSpace v1.0.0" \
  --notes "$(cat <<'NOTES'
## NotchSpace v1.0.0

> **Live inside your notch.** NotchSpace turns the MacBook Pro notch from dead space into a persistent command center.

### Features

- 🎵 **Media Player** — album art, transport controls, 12-bar real-time audio visualizer
- 📋 **Clipboard History** — last 10 items, one-tap re-copy, swipe to delete
- ✨ **AI Assistant** — OpenAI-compatible streaming (OpenRouter, Ollama, local), Keychain API key
- ⏱ **Focus Timer** — Pomodoro 25/5/15 min with notifications
- 🎨 **Aurora Shader** — reactive Metal background that pulses with music and AI activity
- 🎛 **System HUD** — replaces the macOS volume/brightness bezel overlay
- 🔌 **Plugin API** — drop `.notchplugin` bundles into `~/Library/Application Support/NotchSpace/Plugins/`
- 🖥 **Multi-monitor** — always positions on the notch screen automatically

### Requirements

- macOS 14 Sonoma or later
- MacBook Pro with notch (M1 Pro/Max/Ultra, M2, M3, M4)

### Installation

1. Download **NotchSpace.dmg** below
2. Open the DMG and drag **NotchSpace.app** to `/Applications`
3. Launch — grant Accessibility permission when prompted

Or via Homebrew:
\`\`\`bash
brew tap aymandakir/notchspace
brew install --cask notchspace
\`\`\`

### Building from source

\`\`\`bash
git clone https://github.com/aymandakir/notchspace.git
cd notchspace
swift Scripts/GenerateIcon.swift   # generate app icon (run once)
open Package.swift                 # opens Xcode, resolves SPM deps
\`\`\`

### What's new in 1.0.0

Initial public release.
NOTES
)" \
  --latest
