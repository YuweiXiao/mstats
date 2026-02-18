// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "MacStatsBar",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "MacStatsBar",
            targets: ["MacStatsBar"]
        )
    ],
    dependencies: [],
    targets: [
        .target(
            name: "MacStatsBar"
        ),
        .testTarget(
            name: "MacStatsBarTests",
            dependencies: ["MacStatsBar"]
        )
    ]
)
