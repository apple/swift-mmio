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

import CLLDB
import Foundation
import SVD
import MMIOUtilities

class SVD2LLDB {
  var device: SVDDevice?

  init(debugger: inout lldb.SBDebugger) {
    var interpreter = debugger.GetCommandInterpreter()
    var svdCommand = interpreter.AddMultiwordCommand(
      "svd", "Operate on registers by symbolic name.")
    _ = svdCommand.add(
      command: self.load,
      name: Self.loadName,
      help: Self.loadHelp,
      syntax: Self.loadSyntax)
    _ = svdCommand.add(
      command: self.address,
      name: Self.addressName,
      help: Self.addressHelp,
      syntax: Self.addressSyntax)
  }

  static let loadName: StaticString = "load"
  static let loadHelp: StaticString = "load an svd file from disk"
  static let loadSyntax: StaticString = "load <svd-file-path>"
  func load(
    debugger: inout lldb.SBDebugger,
    arguments: [String],
    result: inout lldb.SBCommandReturnObject
  ) -> Bool {
    guard arguments.count == 1 else {
      // Report a usage error to the user.
      result.SetError("Usage: \(Self.loadSyntax)")
      // Return failure.
      return false
    }
    
    do {
      // Convert the argument to a url.
      let url = URL(fileURLWithPath: arguments[0])
      // Load input file from disk.
      let data = try Data(contentsOf: url)
      // Decode raw data into SVD types and save into plugin memory.
      self.device = try SVDDevice(svdData: data)
      // Report success to the user.
      result.Print("Loaded file “\(url.path)”.")
      // Return success.
      return true
    } catch {
      // Report the error to the user.
      result.SetError("\(error.localizedDescription)")
      // Return failure.
      return false
    }
  }

  static let addressName: StaticString = "address"
  static let addressHelp: StaticString = "get the address of a peripheral, cluster, or register"
  static let addressSyntax: StaticString = "address <key-path>..."
  func address(
    debugger: inout lldb.SBDebugger,
    arguments: [String],
    result: inout lldb.SBCommandReturnObject
  ) -> Bool {
    guard let device = self.device else {
      // Report a usage error to the user.
      result.SetError("No svd loaded, please run `svd \(Self.loadSyntax)` before running other commands.")
      // Return failure.
      return false
    }

    // Walk through the user's arguments, and look for the corresponding item in
    // the svd file. Collect the results into an array. While walking keep track
    // of the number of characters in the longest argument and note if an item
    // was was not found.
    var success = true
    var maximumArgumentCharacters = 0
    var argumentsAndAddresses = [(String, UInt64?)]()
    argumentsAndAddresses.reserveCapacity(arguments.count)
    for argument in arguments {
      // Split the argument by "."s into a key path.
      let keyPath = argument.split(separator: ".")
      // Get the address of the argument in the svd file.
      let address = device.address(at: keyPath[...], baseAddress: 0)
      // Note if an error occurred.
      success = success && address != nil
      // Updates the longest argument.
      maximumArgumentCharacters = max(maximumArgumentCharacters, argument.count)
      // Save the result.
      argumentsAndAddresses.append((argument, address))
    }

    // Partition the arguments and their address, placing the arguments which we
    // failed to find at the end in the order they were specified. This relies
    _ = argumentsAndAddresses.partition { $0.1 != nil }

    let addressBytes = device.addressUnitBits / 8
    // Walk through the arguments and their address printing the results.
    for (argument, address) in argumentsAndAddresses {
      // Compute padding to place after the colon the results are aligned.
      let padding = String(
        repeating: " ",
        count: maximumArgumentCharacters - argument.count)
      if let address = address {
        // Report the address to the user.
        result.Print("""
          \(success ? "" : "       ")\
          \(argument):\(padding) \
          \(hex: address, bytes: Int(addressBytes))
          """)
      } else {
        // Report an error to the user.
        result.SetError("\(argument):\(padding) Unknown item")
      }
    }

    // Return true if all items were found.
    return success
  }
}

extension String {
  func matches(_ other: some StringProtocol) -> Bool {
    self.localizedCaseInsensitiveCompare(other) == .orderedSame
  }
}

extension SVDDevice {
  func peripheral(name: some StringProtocol) -> SVDPeripheral? {
    self.peripherals.peripheral.first(where: { $0.name.matches(name) })
  }

  func address(
    at keyPath: ArraySlice<Substring>,
    baseAddress: UInt64
  ) -> UInt64? {
    var keyPath = keyPath
    guard !keyPath.isEmpty else { return baseAddress }
    let key = keyPath.removeFirst()
    if let item = self.peripheral(name: key) {
      return item.address(
        at: keyPath,
        baseAddress: baseAddress + item.baseAddress)
    } else {
      return nil
    }
  }
}

extension SVDPeripheral {
  func cluster(name: some StringProtocol) -> SVDCluster? {
    self.registers?.cluster.first(where: { $0.name.matches(name) })
  }

  func register(name: some StringProtocol) -> SVDRegister? {
    self.registers?.register.first(where: { $0.name.matches(name) })
  }

  func address(
    at keyPath: ArraySlice<Substring>,
    baseAddress: UInt64
  ) -> UInt64? {
    var keyPath = keyPath
    guard !keyPath.isEmpty else { return baseAddress }
    let key = keyPath.removeFirst()
    if let item = self.cluster(name: key) {
      return item.address(
        at: keyPath,
        baseAddress: baseAddress + item.addressOffset)
    } else if let item = self.register(name: key) {
      return item.address(
        at: keyPath,
        baseAddress: baseAddress + item.addressOffset)
    } else {
      return nil
    }
  }
}

extension SVDCluster {
  func cluster(name: some StringProtocol) -> SVDCluster? {
    self.cluster?.first(where: { $0.name.matches(name) })
  }

  func register(name: some StringProtocol) -> SVDRegister? {
    self.register?.first(where: { $0.name.matches(name) })
  }

  func address(
    at keyPath: ArraySlice<Substring>,
    baseAddress: UInt64
  ) -> UInt64? {
    var keyPath = keyPath
    guard !keyPath.isEmpty else { return baseAddress }
    let key = keyPath.removeFirst()
    if let item = self.cluster(name: key) {
      return item.address(
        at: keyPath,
        baseAddress: baseAddress + item.addressOffset)
    } else if let item = self.register(name: key) {
      return item.address(
        at: keyPath,
        baseAddress: baseAddress + item.addressOffset)
    } else {
      return nil
    }
  }
}

extension SVDRegister {
  func field(name: some StringProtocol) -> SVDField? {
    self.fields?.field.first(where: { $0.name.matches(name) })
  }

  func address(
    at keyPath: ArraySlice<Substring>,
    baseAddress: UInt64
  ) -> UInt64? {
    var keyPath = keyPath
    guard !keyPath.isEmpty else { return baseAddress }
    let key = keyPath.removeFirst()
    if let item = self.field(name: key) {
      return item.address(
        at: keyPath,
        baseAddress: baseAddress)
    } else {
      return nil
    }
  }
}

extension SVDField {
  func address(
    at keyPath: ArraySlice<Substring>,
    baseAddress: UInt64
  ) -> UInt64? {
    guard !keyPath.isEmpty else { return baseAddress }
    return nil
  }
}
