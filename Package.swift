// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SpeechCoach",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(
            name: "SpeechCoach",
            targets: ["SpeechCoach"]
        )
    ],
    targets: [
        .executableTarget(
            name: "SpeechCoach",
            path: "SpeechCoach",
            resources: [
                .process("Resources")
            ]
        ),
        .testTarget(
            name: "SpeechCoachTests",
            dependencies: ["SpeechCoach"],
            path: "SpeechCoachTests"
        )
    ]
)
