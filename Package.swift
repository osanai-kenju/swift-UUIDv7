// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "UUIDv7",
    platforms: [
        .iOS(.v18),
        .macOS(.v15)
    ],
    products: [
        .library(
            name: "UUIDv7",
            targets: ["UUIDv7"]
        )
    ],
    targets: [
        .target(
            name: "UUIDv7"
        )
    ]
)
