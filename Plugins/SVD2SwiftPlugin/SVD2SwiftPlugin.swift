//===----------------------------------------------------------*- swift -*-===//
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

@main
struct SVD2SwiftPlugin: BuildToolPlugin {
  func createBuildCommands(
    context: PluginContext,
    target: Target
  ) throws -> [Command] {
    // Ignore this plugin for non-source targets.
    guard let target = target as? SourceModuleTarget else { return [] }

    // Locate the input files.
    let executable = try context.tool(named: "SVD2Swift").path
    let svdFile = try target.sourceFile(kind: .svd)
    let pluginConfigFile = try target.sourceFile(kind: .svd2swift)
    let inputFiles = [executable, svdFile, pluginConfigFile]

    // Load the list of peripherals to generate from the config file.
    let pluginConfigURL = URL(filePath: pluginConfigFile.string)
    let pluginConfigData = try Data(contentsOf: pluginConfigURL)
    let pluginConfig = try JSONDecoder()
      .decode(SVD2SwiftPluginConfiguration.self, from: pluginConfigData)
    guard !pluginConfig.peripherals.isEmpty else {
      throw SVD2SwiftPluginError.missingPeripherals(target, pluginConfigFile)
    }

    // Create a list of output files.
    let outputDirectory = context.pluginWorkDirectory
    let outputFiles = (pluginConfig.peripherals + ["Device"])
      .map { outputDirectory.appending("\($0).swift") }

    // Produce argument list.
    var arguments = [
      "--plugin",
      "--input", svdFile.string,
      "--output", outputDirectory.string,
    ]
    if let accessLevel = pluginConfig.accessLevel {
      arguments += ["--access-level", accessLevel]
    }
    if let indentationWidth = pluginConfig.indentationWidth {
      arguments += ["--indentation-width", "\(indentationWidth)"]
    }
    if pluginConfig.indentUsingTabs == true {
      arguments += ["--indent-using-tabs"]
    }
    if pluginConfig.namespaceUnderDevice == true {
      arguments += ["--namespace-under-device"]
    }
    if pluginConfig.instanceMemberPeripherals == true {
      arguments += ["--instance-member-peripherals"]
    }
    if let overrideDeviceName = pluginConfig.overrideDeviceName {
      arguments += ["--device-name", "\(overrideDeviceName)"]
    }
    arguments += ["--peripherals"] + pluginConfig.peripherals

    // Create the build command.
    let command = Command.buildCommand(
      displayName: """
        Generating register interface in '\(target.name)' from \
        \(FileKind.svd) file '\(svdFile.lastComponent)' using \
        \(FileKind.svd2swift) file '\(pluginConfigFile.lastComponent)'.
        """,
      executable: executable,
      arguments: arguments,
      inputFiles: inputFiles,
      outputFiles: outputFiles)

    // Return the build commands.
    return [command]
  }
}
