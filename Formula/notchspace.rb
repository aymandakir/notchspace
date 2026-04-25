cask "notchspace" do
  version "1.0.0"
  # Update sha256 after each release:
  #   shasum -a 256 NotchSpace-{version}.dmg
  sha256 :no_check

  url "https://github.com/YOUR_USERNAME/notchspace/releases/download/v#{version}/NotchSpace-#{version}.dmg"
  name "NotchSpace"
  desc "Turns the MacBook Pro notch into a persistent command center"
  homepage "https://github.com/YOUR_USERNAME/notchspace"

  # Requires a MacBook Pro with a notch (macOS 14+)
  depends_on macos: ">= :sonoma"

  app "NotchSpace.app"

  # Remove all traces of NotchSpace from the system
  zap trash: [
    "~/Library/Application Support/NotchSpace",
    "~/Library/Preferences/space.notch.plist",
    "~/Library/Caches/space.notch.NotchSpace",
    "~/Library/Saved Application State/space.notch.NotchSpace.savedState",
  ]
end
