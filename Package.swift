// swift-tools-version: 5.9

import CompilerPluginSupport
import PackageDescription

let package = Package(
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
    .library(name: "SVD", targets: ["SVD"]),
    .library(name: "SVD2LLDB", type: .dynamic, targets: ["SVD2LLDB"]),
    .executable(
      // FIXME: rdar://112530586
      // XPM skips build plugin if product and target names are not identical.
      // Rename this product to "svd2swift" when Xcode bug is resolved.
      name: "SVD2Swift",
      targets: ["SVD2Swift"]),
    .plugin(name: "SVD2SwiftPlugin", targets: ["SVD2SwiftPlugin"]),
  ],
  dependencies: [
    .package(
      url: "https://github.com/apple/swift-argument-parser.git",
      from: "1.4.0"),
    .package(
      url: "https://github.com/apple/swift-syntax.git",
      from: "509.0.2"),
  ],
  targets: [
    // MMIO
    .target(
      name: "MMIO",
      dependencies: ["MMIOMacros", "MMIOVolatile"]),
    .testTarget(
      name: "MMIOTests",
      dependencies: ["MMIO", "MMIOUtilities"]),

    // FIXME: feature flag
    // Ideally this would be represented as MMIO + Feature: Interposable
    // MMIOInterposable would have a dependency on MMIO with this feature
    // enabled.
    .target(
      name: "MMIOInterposable",
      dependencies: ["MMIOMacros", "MMIOVolatile"],
      swiftSettings: [.define("FEATURE_INTERPOSABLE")]),
    .testTarget(
      name: "MMIOInterposableTests",
      dependencies: ["MMIOInterposable", "MMIOUtilities"],
      swiftSettings: [.define("FEATURE_INTERPOSABLE")]),

    .testTarget(
      name: "MMIOFileCheckTests",
      dependencies: ["MMIOUtilities"],
      exclude: ["Tests"]),

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

    .target(name: "CLLDB"),
    .target(
      name: "SVD2LLDB",
      dependencies: [
        .product(name: "ArgumentParser", package: "swift-argument-parser"),
        "CLLDB",
        "SVD",
      ],
      swiftSettings: [.interoperabilityMode(.Cxx)]),
    .testTarget(
      name: "SVD2LLDBTests",
      dependencies: ["SVD2LLDB"],
      swiftSettings: [.interoperabilityMode(.Cxx)]),

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
  ],
  cxxLanguageStandard: .cxx11)

#if compiler(>=6.0)
#warning("Skipping SVD2SwiftTests, see apple/swift-package-manager#7596.")
package.targets = package.targets.filter { $0.name != "SVD2SwiftTests" }
#warning("Skipping SVD2SwiftPluginTests, see apple/swift-package-manager#7597.")
package.targets = package.targets.filter { $0.name != "SVD2SwiftPluginTests" }
#endif

#if compiler(<6.0) && os(Linux)
#warning("Skipping SVD2LLDBTests, see apple/swift-package-manager#6990")
// Note: Additional needed bug fixes were only merged to SwiftPM 6.0.
package.targets = package.targets.filter { $0.name != "SVD2LLDBTests" }
#endif

let svd2lldb = "FEATURE_SVD2LLDB"
if featureIsEnabled(named: svd2lldb, override: nil) {
  let target = package.targets.first { $0.name == "SVD2LLDB" }
  guard let target = target else { fatalError("Manifest inconsistency") }
  target.linkerSettings = [.linkedFramework("LLDB")]
}

// Package API Extensions
func featureIsEnabled(named featureName: String, override: Bool?) -> Bool {
  let key = "SWIFT_MMIO_\(featureName)"
  let environment = Context.environment[key] != nil
  return override ?? environment
}

extension Target {
  func swiftDefine(_ value: String) {
    var swiftSettings = self.swiftSettings ?? []
    swiftSettings.append(.define(value))
    self.swiftSettings = swiftSettings
  }
}
