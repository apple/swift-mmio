//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift MMIO open source project
//
// Copyright (c) 2023 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

import Foundation
import PackagePlugin

/// A build tool plugin that verifies the Swift toolchain version before building.
///
/// Logs the active Swift version, Xcode path, and SDK availability to help
/// diagnose cross-platform build failures on CI.
@main
struct BuildToolVersioning: BuildToolPlugin {
  func createBuildCommands(
    context: PluginContext,
    target: Target
  ) throws -> [Command] {
    let outputDir = context.pluginWorkDirectoryURL
      .appending(path: "toolchain-info")

    let script = """
      swift_ver=$(swift --version 2>&1 | head -1)
      xcode_path=$(xcode-select -p 2>/dev/null || echo "N/A")
      sdk=$(xcrun --show-sdk-path 2>/dev/null || echo "N/A")
      echo "swift: ${swift_ver}"
      echo "xcode: ${xcode_path}"
      echo "sdk:   ${sdk}"
      echo "arch:  $(uname -m)"
      """

    return [
      .prebuildCommand(
        displayName: "Checking toolchain for \(target.name)",
        executable: URL(fileURLWithPath: "/bin/sh"),
        arguments: ["-c", script],
        outputFilesDirectory: outputDir),
    ]
  }
}
