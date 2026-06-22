// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "MRTracker",
    platforms: [
        .macOS(.v15)
    ],
    targets: [
        .executableTarget(
            name: "MRTracker",
            path: "Sources/MRTracker"
        ),
        .testTarget(
            name: "MRTrackerTests",
            dependencies: ["MRTracker"],
            path: "Tests/MRTrackerTests"
        )
    ]
)
