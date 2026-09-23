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
        ),
        .executable(
            name: "OvernodeWidgetExtension",
            targets: ["OvernodeWidget"]
        )
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "Overnode",
            dependencies: [],
            path: "Sources/Overnode",
            exclude: [
                "Resources"
            ]
        ),
        .executableTarget(
            name: "OvernodeWidget",
            dependencies: [],
            path: "Sources/OvernodeWidget"
        ),
        .testTarget(
            name: "OvernodeTests",
            dependencies: ["Overnode"],
            path: "Tests/OvernodeTests"
        )
    ]
)

