// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "OHeasCore",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(name: "OHeasCore", targets: ["OHeasCore"])
    ],
    targets: [
        .target(name: "OHeasCore"),
        .testTarget(
            name: "OHeasCoreTests",
            dependencies: ["OHeasCore"]
        )
    ]
)
