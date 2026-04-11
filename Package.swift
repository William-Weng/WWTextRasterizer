// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "WWTextRasterizer",
    platforms: [
        .iOS(.v16)
    ],
    products: [
        .library(name: "WWTextRasterizer", targets: ["WWTextRasterizer"]),
    ],
    targets: [
        .target(name: "WWTextRasterizer", resources: [.copy("Privacy")]),

    ],
    swiftLanguageVersions: [
        .v5
    ]
)
