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
    let executableFile = try context.tool(named: "SVD2Swift").url
    let svdFile = try target.sourceFile(kind: .svd).url
    let pluginConfigFile = try target.sourceFile(kind: .svd2swift).url
    let inputFiles = [executableFile, svdFile, pluginConfigFile]

    // Load the list of peripherals to generate from the config file.
    let pluginConfigData = try Data(contentsOf: pluginConfigFile)
    let pluginConfig: SVD2SwiftPluginConfiguration
    do {
      pluginConfig = try JSONDecoder()
        .decode(SVD2SwiftPluginConfiguration.self, from: pluginConfigData)
    } catch let error as DecodingError {
      throw SVD2SwiftPluginConfigurationDecodingError(
        url: pluginConfigFile,
        error: error)
    }
    guard !pluginConfig.peripherals.isEmpty else {
      throw SVD2SwiftPluginError.missingPeripherals(
        target,
        pluginConfigFile.path)
    }

    // Create a list of output files.
    let outputDirectory = context.pluginWorkDirectoryURL
    let outputFiles = (pluginConfig.peripherals + ["Device"])
      .map { outputDirectory.appendingPathComponent("\($0).swift") }

    // Produce argument list.
    var arguments = [
      "--plugin",
      "--input", svdFile.path,
      "--output", outputDirectory.path,
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
        \(FileKind.svd) file '\(svdFile.lastPathComponent)' using \
        \(FileKind.svd2swift) file '\(pluginConfigFile.lastPathComponent)'.
        """,
      executable: executableFile,
      arguments: arguments,
      inputFiles: inputFiles,
      outputFiles: outputFiles)

    // Return the build commands.
    return [command]
  }
}
