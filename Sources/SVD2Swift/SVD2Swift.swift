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

import ArgumentParser
import Foundation
import SVD

@main
struct SVD2Swift: ParsableCommand {
  static let configuration = CommandConfiguration(commandName: "svd2swift")

  @Flag(
    name: .customLong("plugin"),
    help: .init(
      "Specify svd2swift was ran via a Swift package plugin.",
      visibility: .hidden))
  var ranViaSwiftPackagePlugin: Bool = false

  @Option(
    name: [.short, .customLong("input")],
    help: "Specify the input SVD file. Use '-' for stdin.",
    completion: .file(extensions: ["svd"]))
  var inputSVDFile: String

  @Option(
    name: [.short, .customLong("output")],
    help: "Specify the output directory. Use '-' for stdout.",
    completion: .directory)
  var outputDirectory: String

  @Option(
    name: [.customShort("p"), .customLong("peripherals")],
    parsing: .upToNextOption,
    help: .init(
      """
      Specify which peripherals in the SVD to include in the output. Skipping \
      this option includes all peripherals in the output.
      """,
      valueName: "peripherals"))
  var selectedPeripherals: [String] = []

  @Option(
    name: .long,
    help:
      """
      Specify the access level of generated Swift types. Skipping this option \
      omits an access level modifier on generated declarations.
      """)
  var accessLevel: AccessLevel?

  @Option(
    name: .long,
    help:
      """
      Specify the number spaces to use for indentation. This option is only \
      applicable when '--indent-using-tabs' is not used.
      """)
  var indentationWidth: Int = 4

  @Flag(
    name: .long,
    help: "Specify indentation should use tabs.")
  var indentUsingTabs: Bool = false

  @Flag(
    name: .long,
    help:
      """
      Specify generated types and peripheral instances should be namespaced \
      under a device type.
      """)
  var namespaceUnderDevice: Bool = false

  @Flag(
    name: .long,
    help:
      """
      Specify peripheral instances should be instance members of the device \
      type. This option is only applicable when \
      '--namespace-under-device' is used.
      """)
  var instanceMemberPeripherals: Bool = false

  @Option(
    name: .customLong("device-name"),
    help:
      """
      Specify a custom top-level device name. This option is only applicable \
      when '--namespace-under-device-type' is used.
      """)
  var overrideDeviceName: String?

  func inputReader() -> InputReader {
    let input =
      if self.inputSVDFile == "-" {
        Input.standardInput
      } else {
        Input.file(self.inputSVDFile)
      }
    return InputReader(input: input)
  }

  func output() -> Output {
    if self.outputDirectory == "-" {
      Output.standardOutput
    } else {
      Output.directory(self.outputDirectory)
    }
  }

  func indentation() -> Indentation {
    if self.indentUsingTabs {
      Indentation.tab
    } else {
      Indentation.space(self.indentationWidth)
    }
  }

  func validate() throws {
    if self.selectedPeripherals.isEmpty && self.ranViaSwiftPackagePlugin {
      throw ValidationError(
        """
        Missing expected argument '--peripherals <peripherals> ...'. \
        Peripherals must be explicitly specified when running 'svd2swift' via \
        a Swift package plugin.
        """)
    }
  }

  func run() throws {
    // Load input file from disk.
    let svdData = try self.inputReader().read()

    // Decode raw data into SVD types.
    let svdDevice = try SVDDevice(svdData: svdData)

    // Convert decoded data into an IR for exporting.
    var device = try Device(svdDevice: svdDevice)

    // Sanitize the IR device.
    device.sanitize()

    // Create export options and an output destination.
    let options = ExportOptions(
      indentation: self.indentation(),
      accessLevel: self.accessLevel,
      selectedPeripherals: self.selectedPeripherals,
      namespaceUnderDevice: self.namespaceUnderDevice,
      instanceMemberPeripherals: self.instanceMemberPeripherals,
      overrideDeviceName: self.overrideDeviceName)
    var output = self.output()

    // Export the swift interface into the output directory.
    try device.export(with: options, to: &output)
  }
}
