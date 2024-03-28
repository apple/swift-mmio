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

extension SVD2LLDB {
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
        result.Print(
          """
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
