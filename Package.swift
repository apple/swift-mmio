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
  ],
  products: [
    .library(name: "MMIO", targets: ["MMIO"])
  ],
  dependencies: [
    .package(url: "https://github.com/apple/swift-syntax.git", from: "509.0.2")
  ],
  targets: [
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
        // FIXME: rdar://119344431 (XPM drops transitive dependency causing linker errors)
        // Remove this dependency when Xcode bug is resolved
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
  ])

// Replace this with a native spm feature flag if/when supported
let interposable = "FEATURE_INTERPOSABLE"
if featureIsEnabled(named: interposable, override: nil) {
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
