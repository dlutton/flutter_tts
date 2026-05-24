// swift-tools-version: 5.9

import PackageDescription

let package = Package(
  name: "flutter_tts",
  platforms: [
    .macOS("10.15")
  ],
  products: [
    .library(name: "flutter-tts", targets: ["flutter_tts"])
  ],
  dependencies: [],
  targets: [
    .target(
      name: "flutter_tts",
      dependencies: [],
      path: "Sources/flutter_tts"
    )
  ]
)
