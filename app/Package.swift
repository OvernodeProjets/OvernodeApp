// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Overnode",
    defaultLocalization: "fr",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(
            name: "Overnode",
            targets: ["Overnode"]
        )
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "Overnode",
            dependencies: [],
            path: "Sources/Overnode",
            resources: [
                .process("Resources")
            ]
        ),
        .testTarget(
            name: "OvernodeTests",
            dependencies: ["Overnode"],
            path: "Tests/OvernodeTests"
        )
    ]
)
