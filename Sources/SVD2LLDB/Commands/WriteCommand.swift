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
import MMIOUtilities
import SVD

struct WriteCommand: SVD2LLDBCommand {
  static let autoRepeat = ""
  static let configuration = CommandConfiguration(
    commandName: "write",
    _superCommandName: "svd",
    abstract: "Write a new value to a register.")

  @Argument(help: "Key-path to a register or field.")
  var keyPath: String

  @Argument(help: "Value to write.")
  var value: String

  @Flag(help: "Always write or modify ignoring side-effects.")
  var force: Bool = false

  mutating func run(
    debugger: inout some SVD2LLDBDebugger,
    result: inout some SVD2LLDBResult,
    context: SVD2LLDB
  ) throws -> Bool {
    let device = try context.device.unwrap(or: NoSVDLoadedError())
    guard self.force else {
      throw GenericError(
        """
        Use “--force“ to write values. Tracking side effects is not \
        implemented yet.
        """)
    }
    let info = try self.lookupRegister(item: device)
    let value = try self.value(info: info)
    try debugger.write(address: info.address, value: value, bits: info.size)
    result.output("Wrote: \(hex: value, bits: info.size)")
    return true
  }

  struct RegisterInfo {
    var register: SVDRegister
    var name: String
    var readAction: SVDReadAction?
    var writeAction: SVDModifiedWriteValues?
    var address: UInt64
    var size: UInt64
  }

  func lookupRegister(item: any SVDItem) throws -> RegisterInfo {
    // Split the first argument by "."s into a key path and normalize by
    // lowercasing keys.
    var keyPath = self.keyPath.split(separator: ".").map { $0.lowercased() }
    guard !keyPath.isEmpty else {
      throw ValidationError("Invalid key path “\(self.keyPath)”.")
    }

    // Find the user requested item in device. While searching, normalize the
    // key path name and determine metadata about the register.
    var item = item
    var name = ""
    var readAction = item.readAction
    var modifiedWriteValues = item.modifiedWriteValues
    var address = item.addressOffset
    var size = item.registerProperties.size ?? 0
    // Flip the keyPath so we pop from the back O(1) instead of the front O(N).
    keyPath.reverse()
    while let key = keyPath.last {
      defer { keyPath.removeLast() }
      guard let childItem = item.child(at: key) else {
        throw GenericError("Unknown item “\(self.keyPath)”.")
      }

      if !name.isEmpty {
        name.append(".")
      }
      name.append(childItem.name)
      item = childItem
      readAction = childItem.readAction ?? readAction
      modifiedWriteValues = childItem.modifiedWriteValues ?? modifiedWriteValues
      address = childItem.addressOffset + address
      size = childItem.registerProperties.size ?? size
    }

    // Error if the item was found but isn't a register.
    guard let register = item as? SVDRegister else {
      throw GenericError("Invalid register key path “\(name)”.")
    }

    // Error if the register is too large to handle.
    let sizeSingular = size == 1
    guard size <= 64 else {
      throw GenericError(
        "Invalid register size “\(size)“ bit\(sizeSingular ? "" : "s").")
    }

    return RegisterInfo(
      register: register,
      name: name,
      readAction: readAction,
      address: address,
      size: size)
  }

  func value(
    info: RegisterInfo
  ) throws -> UInt64 {
    // Parse the value into a UInt64.
    let userValue = self.value
    let valueParser = Parser.swiftInteger(UInt64.self)
    var valueRaw = userValue[...]
    guard let value = valueParser.run(&valueRaw) else {
      throw ValidationError("Invalid value “\(userValue)”.")
    }
    // Error if the user provided value exceeds the size of the register.
    let sizeSingular = info.size == 1
    guard (value >> info.size) == 0 else {
      throw GenericError(
        """
        Invalid value “\(userValue)“ larger than register size \
        “\(info.size)“ bit\(sizeSingular ? "" : "s").
        """)
    }
    return value
  }
}
