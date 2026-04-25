// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "NotchSpace",
    platforms: [
        .macOS(.v14),
    ],
    dependencies: [
        .package(
            url: "https://github.com/sindresorhus/LaunchAtLogin-Modern",
            from: "1.0.0"
        ),
        .package(
            url: "https://github.com/sparkle-project/Sparkle",
            from: "2.0.0"
        ),
    ],
    targets: [
        .executableTarget(
            name: "NotchSpace",
            dependencies: [
                "Core",
                "Features",
                "UI",
                "Utilities",
                .product(name: "LaunchAtLogin", package: "LaunchAtLogin-Modern"),
                .product(name: "Sparkle", package: "Sparkle"),
            ],
            path: "Sources/App",
            // Asset catalog (app icon) and Info.plist are bundled as resources.
            resources: [
                .process("Resources"),
            ]
        ),
        .target(
            name: "Core",
            path: "Sources/Core"
        ),
        .target(
            name: "Features",
            dependencies: ["Core", "UI"],
            path: "Sources/Features"
        ),
        .target(
            name: "UI",
            dependencies: ["Core"],
            path: "Sources/UI",
            // The Shaders/ directory contains NotchShader.metal.
            // Xcode compiles .metal files into the target's default Metal library
            // (accessible via MTLDevice.makeDefaultLibrary()).
            resources: [
                .process("Shaders"),
            ]
        ),
        .target(
            name: "Utilities",
            path: "Sources/Utilities"
        ),
    ]
)
