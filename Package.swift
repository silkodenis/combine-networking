// swift-tools-version:5.3
import PackageDescription

let package = Package(
    name: "CombineNetworking",
    platforms: [
            .macOS(.v10_15), .iOS(.v13), .tvOS(.v13), .watchOS(.v6)
        ],
    products: [
        .library(
            name: "CombineNetworking",
            targets: ["CombineNetworking"]),
    ],
    targets: [
        .target(
            name: "CombineNetworking"),
        .testTarget(
            name: "CombineNetworkingTests",
            dependencies: ["CombineNetworking"]),
    ]
)
