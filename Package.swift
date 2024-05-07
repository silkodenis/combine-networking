// swift-tools-version:5.3
import PackageDescription

let package = Package(
    name: "HTTPClient",
    platforms: [
            .macOS(.v10_15), .iOS(.v13), .tvOS(.v13), .watchOS(.v6)
        ],
    products: [
        .library(
            name: "HTTPClient",
            targets: ["HTTPClient"]),
    ],
    targets: [
        .target(
            name: "HTTPClient"),
        .testTarget(
            name: "HTTPClientTests",
            dependencies: ["HTTPClient"]),
    ]
)
