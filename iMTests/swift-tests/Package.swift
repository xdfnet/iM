// swift-tools-version:6.0
//
// Local test scaffold for pure-Foundation helpers from the app and the
// Quick Look extension. The Xcode project is the source of truth — source
// files live under `quick-look/` and `iM/` and are symlinked into
// `Sources/<Target>/` so SPM can compile them without duplication.
//
// Run: `swift test --package-path tests/swift-tests`
//
import PackageDescription

let package = Package(
    name: "iMHelperTests",
    platforms: [.macOS(.v15)],
    dependencies: [
        .package(
            url: "https://github.com/swiftlang/swift-markdown.git",
            from: "0.7.3"
        ),
    ],
    targets: [
        .target(name: "QuickLookHelpers"),
        .testTarget(
            name: "QuickLookHelperTests",
            dependencies: ["QuickLookHelpers"]
        ),
        .target(
            name: "PreviewHelpers",
            dependencies: [
                .product(name: "Markdown", package: "swift-markdown"),
            ]
        ),
        .testTarget(
            name: "PreviewHelpersTests",
            dependencies: ["PreviewHelpers"]
        ),
    ]
)
