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
        ),
        .executable(
            name: "MacStatsBarApp",
            targets: ["MacStatsBarApp"]
        )
    ],
    dependencies: [],
    targets: [
        .target(
            name: "MacStatsBar"
        ),
        .executableTarget(
            name: "MacStatsBarApp",
            dependencies: ["MacStatsBar"]
        ),
        .testTarget(
            name: "MacStatsBarTests",
            dependencies: ["MacStatsBar"]
        )
    ]
)
