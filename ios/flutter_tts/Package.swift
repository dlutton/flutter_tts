// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "flutter_tts",
    platforms: [
        .iOS("15.0")
    ],
    products: [
        .library(name: "flutter-tts", targets: ["flutter_tts"])
    ],
    dependencies: [
        .package(name: "FlutterFramework", path: "../FlutterFramework")
    ],
    targets: [
        .target(
            name: "flutter_tts",
            dependencies: [
                .product(name: "FlutterFramework", package: "FlutterFramework")
            ],
            resources: [
                // If this plugin requires a privacy manifest, for example if it uses any required
                // reason APIs, update the PrivacyInfo.xcprivacy file to describe the plugin's
                // privacy impact, and then uncomment this line.
                // .process("PrivacyInfo.xcprivacy"),
            ]
        )
    ]
)
