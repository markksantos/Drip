// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "Drip",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .library(name: "Drip", targets: ["Drip"]),
        .library(name: "DripEngine", targets: ["DripEngine"]),
        .library(name: "DripUI", targets: ["DripUI"]),
        .executable(name: "DripApp", targets: ["DripApp"])
    ],
    targets: [
        .target(
            name: "Drip",
            path: "Sources/Drip"
        ),
        .target(
            name: "DripEngine",
            dependencies: ["Drip"],
            path: "Sources/DripEngine"
        ),
        .target(
            name: "DripUI",
            dependencies: ["Drip", "DripEngine"],
            path: "Sources/DripUI"
        ),
        .executableTarget(
            name: "DripApp",
            dependencies: ["DripEngine", "DripUI"],
            path: "Sources/DripApp"
        ),
        .testTarget(
            name: "DripEngineTests",
            dependencies: ["DripEngine"],
            path: "Tests/DripEngineTests"
        ),
        .testTarget(
            name: "DripUITests",
            dependencies: ["DripUI"],
            path: "Tests/DripUITests"
        ),
        .testTarget(
            name: "IntegrationTests",
            dependencies: ["Drip", "DripEngine", "DripUI"],
            path: "Tests/IntegrationTests"
        )
    ]
)
