// swift-tools-version: 5.8
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let featureFlags: [SwiftSetting] = [
    .enableExperimentalFeature("StrictConcurrency=complete"),
    .enableUpcomingFeature("StrictConcurrency=complete"),
]

let package = Package(
    name: "CachingPlayerItem",
    platforms: [
        .iOS(.v16),
        .macOS(.v13),
        .tvOS(.v14),
        .watchOS(.v7)
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "CachingPlayerItem",
            targets: ["CachingPlayerItem"]
        ),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(name: "CachingPlayerItem", swiftSettings: featureFlags),
        .testTarget(
            name: "CachingPlayerItemTests",
            dependencies: ["CachingPlayerItem"]
        ),
    ]
)
