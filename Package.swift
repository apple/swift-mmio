// swift-tools-version: 5.9

import PackageDescription

let package = Package(
  name: "swift-mmio",
  products: [
    .library(name: "MMIO", targets: ["MMIO"]),
  ],
  targets: [
    .target(name: "MMIO"),
    .testTarget(name: "MMIOTests", dependencies: ["MMIO"]),
  ]
)
