// swift-tools-version: 5.9

import CompilerPluginSupport
import Foundation
import PackageDescription

var package = Package(
  name: "swift-mmio",
  platforms: [
    .macOS(.v10_15),
    .iOS(.v13),
    .tvOS(.v13),
    .watchOS(.v6),
    .macCatalyst(.v13),
    .visionOS(.v1),
  ],
  products: [
    // MMIO
    .library(name: "MMIO", targets: ["MMIO"]),

    // SVD
    .executable(
      // FIXME: rdar://112530586
      // XPM skips build plugin if product and target names are not identical.
      // Rename this product to "svd2swift" when Xcode bug is resolved.
      name: "SVD2Swift",
      targets: ["SVD2Swift"]),
    .plugin(name: "SVD2SwiftPlugin", targets: ["SVD2SwiftPlugin"]),
    .library(name: "SVD", targets: ["SVD"]),
  ],
  dependencies: [
    .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.3.0"),
    .package(url: "https://github.com/apple/swift-syntax.git", from: "509.0.2"),
  ],
  targets: [
    // MMIO
    .target(
      name: "MMIO",
      dependencies: ["MMIOMacros", "MMIOVolatile"]),
    .testTarget(
      name: "MMIOFileCheckTests",
      dependencies: ["MMIOUtilities"],
      exclude: ["Tests"]),
    .testTarget(
      name: "MMIOInterposableTests",
      dependencies: ["MMIO", "MMIOUtilities"]),
    .testTarget(
      name: "MMIOTests",
      dependencies: ["MMIO", "MMIOUtilities"]),

    .macro(
      name: "MMIOMacros",
      dependencies: [
        "MMIOUtilities",
        .product(name: "SwiftCompilerPlugin", package: "swift-syntax"),
        .product(name: "SwiftDiagnostics", package: "swift-syntax"),
        .product(name: "SwiftOperators", package: "swift-syntax"),
        .product(name: "SwiftSyntax", package: "swift-syntax"),
        .product(name: "SwiftSyntaxBuilder", package: "swift-syntax"),
        .product(name: "SwiftSyntaxMacroExpansion", package: "swift-syntax"),
        .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
      ]),
    .testTarget(
      name: "MMIOMacrosTests",
      dependencies: [
        "MMIOMacros",
        // FIXME: rdar://119344431
        // XPM drops transitive dependency causing linker errors.
        // Remove this dependency when Xcode bug is resolved.
        "MMIOUtilities",
        .product(name: "SwiftSyntax", package: "swift-syntax"),
        .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
        .product(name: "SwiftSyntaxMacrosTestSupport", package: "swift-syntax"),
      ]),

    .target(name: "MMIOUtilities"),
    .testTarget(
      name: "MMIOUtilitiesTests",
      dependencies: ["MMIOUtilities"]),

    .systemLibrary(name: "MMIOVolatile"),

    // SVD
    .target(
      name: "SVD",
      dependencies: ["MMIOUtilities", "SVDMacros"]),
    .testTarget(
      name: "SVDTests",
      dependencies: ["MMIOUtilities", "SVD"]),

    .executableTarget(
      name: "SVD2Swift",
      dependencies: [
        .product(name: "ArgumentParser", package: "swift-argument-parser"),
        "SVD",
      ]),
    .testTarget(
      name: "SVD2SwiftTests",
      dependencies: ["SVD", "SVD2Swift"]),

    .plugin(
      name: "SVD2SwiftPlugin",
      capability: .buildTool,
      dependencies: ["SVD2Swift"]),
    .testTarget(
      name: "SVD2SwiftPluginTests",
      dependencies: ["MMIO"],
      // FIXME: rdar://113256834,apple/swift-package-manager#6935
      // SPM 5.9 produces warnings for plugin input files.
      // Remove this exclude list when Swift Package Manager bug is resolved.
      exclude: ["ARM_Sample.svd", "svd2swift.json"],
      plugins: ["SVD2SwiftPlugin"]),

    .macro(
      name: "SVDMacros",
      dependencies: [
        .product(name: "SwiftCompilerPlugin", package: "swift-syntax"),
        .product(name: "SwiftSyntax", package: "swift-syntax"),
        .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
      ]),
    .testTarget(
      name: "SVDMacrosTests",
      dependencies: [
        "SVDMacros",
        .product(name: "SwiftSyntax", package: "swift-syntax"),
        .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
        .product(name: "SwiftSyntaxMacrosTestSupport", package: "swift-syntax"),
      ]),
  ])

// Replace this with a native SPM feature flag if/when supported.
let interposable = "FEATURE_INTERPOSABLE"
if featureIsEnabled(named: interposable, override: nil) {
  package.products = package.products.filter { $0.name.hasPrefix("MMIO") }
  let allowedTargets = Set([
    "MMIO", "MMIOVolatile", "MMIOMacros", "MMIOUtilities",
    "MMIOInterposableTests",
  ])
  package.targets = package.targets.filter {
    allowedTargets.contains($0.name)
  }
  for target in package.targets where target.type != .system {
    target.swiftDefine(interposable)
  }
} else {
  let disallowedTargets = Set(["MMIOInterposableTests"])
  package.targets = package.targets.filter {
    !disallowedTargets.contains($0.name)
  }
}

func featureIsEnabled(named featureName: String, override: Bool?) -> Bool {
  let key = "SWIFT_MMIO_\(featureName)"
  let environment = ProcessInfo.processInfo.environment[key] != nil
  return override ?? environment
}

extension Target {
  func swiftDefine(_ value: String) {
    var swiftSettings = self.swiftSettings ?? []
    swiftSettings.append(.define(value))
    self.swiftSettings = swiftSettings
  }
}
