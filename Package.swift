// swift-tools-version: 6.1

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
    // FIXME: Update to non-prerelease
    // The 6.2 release is needed for `swiftlang/swift-syntax#2947` "Don’t remove
    //#if attributes with AttributeRemover" which missed the 6.1 release.
    .package(
      url: "https://github.com/swiftlang/swift-syntax.git",
      from: "602.0.0-prerelease-2025-05-29"),
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
    // MMIOInterposableTests would have a dependency on MMIO with this feature
    // enabled.
    .target(
      name: "MMIOInterposable",
      dependencies: ["MMIOMacros", "MMIOVolatile"],
      swiftSettings: [.define("FEATURE_INTERPOSABLE")]),
    .testTarget(
      name: "MMIOInterposableTests",
      dependencies: ["MMIOInterposable", "MMIOUtilities"],
      swiftSettings: [.define("FEATURE_INTERPOSABLE")]),

    // Only runs in release.
    .testTarget(
      name: "MMIOFileCheckTests",
      dependencies: [
        // This is conceptually a build-time only dependency.
        "MMIO",
        "MMIOUtilities",
      ],
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
        .product(
          name: "SwiftSyntaxMacrosGenericTestSupport", package: "swift-syntax"),
      ]),

    .target(name: "MMIOUtilities"),
    .testTarget(
      name: "MMIOUtilitiesTests",
      dependencies: ["MMIOUtilities"]),

    .systemLibrary(name: "MMIOVolatile"),

    // SVD
    .target(
      name: "SVD",
      dependencies: ["MMIOUtilities", "SVDMacros", "XML"]),
    .testTarget(
      name: "SVDTests",
      dependencies: ["MMIOUtilities", "SVD"]),

    .target(
      name: "SVDPerf",
      resources: [.copy("MIMXRT1062.svd")]),
    .testTarget(
      name: "SVDPerfTests",
      dependencies: ["SVD", "SVDPerf"]),

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
        .product(
          name: "SwiftSyntaxMacrosGenericTestSupport", package: "swift-syntax"),
      ]),

    // XML
    .target(name: "XML")
  ],
  cxxLanguageStandard: .cxx11)

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

// MARK: - Language Feature Flags
for target in package.targets {
  guard ![.system, .plugin].contains(target.type) else { continue }
  var swiftSettings = target.swiftSettings ?? []

  // Swift 6.0 - SE-335: Introduce existential any
  swiftSettings.append(.enableUpcomingFeature("ExistentialAny"))

  // Swift 6.0 - SE-409: Access-level modifiers on import declarations
  swiftSettings.append(.enableUpcomingFeature("InternalImportsByDefault"))

  // Swift 6.1 - SE-444: Member import visibility
  swiftSettings.append(.enableUpcomingFeature("MemberImportVisibility"))

  // Swift 6.2 - SE-461: Run nonisolated async functions on the caller's actor
  swiftSettings.append(.enableUpcomingFeature("NonisolatedNonsendingByDefault"))

  // Swift 6.2 - SE-470: Global-actor isolated conformances
  swiftSettings.append(.enableUpcomingFeature("InferIsolatedConformances"))

  target.swiftSettings = swiftSettings
}
