// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "FocusApp",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "FocusApp", targets: ["FocusApp"])
    ],
    targets: [
        .executableTarget(
            name: "FocusApp",
            dependencies: [],
            path: "Sources/FocusApp"
        )
    ]
)
