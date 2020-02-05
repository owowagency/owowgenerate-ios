// swift-tools-version:5.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "owowgenerate-ios",
    platforms: [
        .macOS(.v10_15),
    ],
    products: [
        .executable(name: "owowgenerate-ios", targets: ["owowgenerate-ios"])
    ],
    targets: [
        .target(
            name: "owowgenerate-ios",
            dependencies: []),
        .testTarget(
            name: "owowgenerate-iosTests",
            dependencies: ["owowgenerate-ios"]),
    ]
)
