// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "TopwayCore",
    platforms: [.macOS("26.2")],
    products: [
        .library(name: "TopwayCore", targets: ["TopwayCore"])
    ],
    targets: [
        .target(name: "TopwayCore"),
        .testTarget(name: "TopwayCoreTests", dependencies: ["TopwayCore"]),
    ],
    swiftLanguageModes: [.v6]
)
