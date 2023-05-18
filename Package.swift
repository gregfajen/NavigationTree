// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "NavigationTree",
    platforms: [
        .iOS(.v16),
        .macOS(.v13),
    ],
    products: [
        .library(
            name: "Trees",
            targets: ["Trees"]
        ),
        .library(
            name: "Slabs",
            targets: ["Slabs"]
        ),
        .library(
            name: "PresentationStyles",
            targets: ["PresentationStyles"]
        ),
        .library(
            name: "NavigationTree",
            targets: ["NavigationTree"]
        ),
        .library(
            name: "Demo",
            targets: ["Demo"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/pointfreeco/swift-dependencies", from: "0.4.0"),
        .package(url: "https://github.com/pointfreeco/xctest-dynamic-overlay", from: "0.8.0"),
        .package(url: "https://github.com/pointfreeco/swift-custom-dump", from: "0.10.0"),
        .package(url: "https://github.com/pointfreeco/swift-composable-architecture", from: "0.52.0"),
        .package(url: "https://github.com/apple/swift-algorithms", from: "1.0.0"),
        .package(url: "https://github.com/apple/swift-async-algorithms", from: "0.0.0"),
    ],
    targets: [
        .target(
            name: "Trees",
            dependencies: [
                .product(name: "Algorithms", package: "swift-algorithms"),
                .product(name: "AsyncAlgorithms", package: "swift-async-algorithms"),
                .product(name: "Dependencies", package: "swift-dependencies"),
                .product(name: "XCTestDynamicOverlay", package: "xctest-dynamic-overlay"),
                .product(name: "CustomDump", package: "swift-custom-dump"),
            ]
        ),
        .target(
            name: "Slabs",
            dependencies: [
                "Trees",
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
            ]
        ),
        .target(
            name: "PresentationStyles",
            dependencies: [
                "Trees",
            ]
        ),
        .target(
            name: "NavigationTree",
            dependencies: [
                "Trees",
                "Slabs",
                "PresentationStyles",
            ]
        ),

        .target(
            name: "Demo",
            dependencies: [
                "NavigationTree",
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
            ]
        ),

        .testTarget(
            name: "NavigationTreeTests",
            dependencies: [
                "NavigationTree",
                "Trees",
                "Slabs",
            ]
        ),
    ]
)
