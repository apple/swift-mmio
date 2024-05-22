//===----------------------------------------------------------*- swift -*-===//
//
// This source file is part of the Swift MMIO open source project
//
// Copyright (c) 2024 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

import ArgumentParser
import MMIOUtilities
import SVD

struct DecodeCommand: SVD2LLDBCommand {
  static let autoRepeat = ""
  static let configuration = CommandConfiguration(
    commandName: "decode",
    _superCommandName: "svd",
    abstract: "Decode a register value into fields.")

  @Argument(help: "Key-path to a register.")
  var keyPath: String

  @Argument(help: "Existing value to decode.")
  var value: String?

  @Flag(help: "Print table values in binary instead of hexadecimal.")
  var binary: Bool = false

  @Flag(help: "Read the value from the device instead of an existing value.")
  var read: Bool = false

  @Flag(help: "Always read ignoring side-effects.")
  var force: Bool = false

  @Flag(help: "Include a visual diagram of the fields.")
  var visual: Bool = false

  mutating func run(
    debugger: inout some SVD2LLDBDebugger,
    result: inout some SVD2LLDBResult,
    context: SVD2LLDB
  ) throws -> Bool {
    let device = try context.device.unwrap(or: NoSVDLoadedError())
    let info = try self.lookupRegister(item: device)
    let value = try self.value(debugger: &debugger, info: info)

    result.output("\(info.name): \(hex: value, bits: info.size)")
    result.output("\n")
    if visual {
      self.renderVisual(
        register: info.register,
        size: info.size,
        value: value,
        result: &result)
      result.output("\n")
    }
    self.renderTable(register: info.register, value: value, result: &result)

    return true
  }

  struct RegisterInfo {
    var register: SVDRegister
    var name: String
    var readAction: SVDReadAction?
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
    debugger: inout some SVD2LLDBDebugger,
    info: RegisterInfo
  ) throws -> UInt64 {
    if let userValue = self.value {
      // Parse the value into a UInt64, if provided.
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
    } else if read {
      // Skip reading if it would cause a side effect and the user did not
      // specify force.
      guard info.readAction == nil || force else {
        throw GenericError(
          """
          Skipped register with side-effect. Use “--force” to read this \
          register.
          """)
      }
      // Read the value from the register.
      do {
        return try debugger.read(
          address: info.address,
          bits: Int(info.size))
      } catch {
        throw GenericError("Failed to read register: \(error)")
      }
    } else {
      throw ValidationError(
        "Must either supply a “<value>“ or use the “--read“ flag.")
    }
  }
}

// MARK: - Output rendering
extension DecodeCommand {
  func renderVisual(
    register: SVDRegister,
    size: UInt64,
    value: UInt64,
    result: inout some SVD2LLDBResult
  ) {
    // Allocate rows to store field names into. The 0th row is the base of each
    // flag and the rows above are the tops of the flags and field names.
    var above = [""]
    var below = [""]

    // The field stems are drawn from high to low bit so lets start by sorting
    // the fields in that order.
    let fields = (register.fields?.field ?? []).sorted {
      $0.bitRange.range.upperBound > $1.bitRange.range.upperBound
    }

    // Track if we're rendering field names into the lines above (true) or below
    // (false) the bit-pattern.
    var side = true
    for field in fields {
      let range = field.bitRange.range
      if side {
        addBase(to: &above[0], range: range, base: "┴")
        addStem(to: &above, name: field.name, range: range, flag: "╭")
      } else {
        addBase(to: &below[0], range: range, base: "┬")
        addStem(to: &below, name: field.name, range: range, flag: "╰")
      }
      // Flip the side we're rendering to for the next field.
      side.toggle()
    }

    func addBase(
      to row: inout String,
      range: Range<UInt64>,
      base: String
    ) {
      // Add two to the padding to account for the "0b" prefix.
      let padding = Int(size - range.upperBound) - row.count + 2
      row.append(repeating: " ", count: padding)
      row.append(base)
      row.append(repeating: "─", count: range.count - 1)
    }

    func addStem(
      to rows: inout [String],
      name: String,
      range: Range<UInt64>,
      flag: String
    ) {
      let flagStartOffset = Int(size - range.upperBound + 2)
      // Skip the first row, thats done by `addBase`.
      var rowIndex = 1
      while true {
        // Add a new row starting with "  " if needed.
        if rows.count - 1 < rowIndex {
          rows.append("  ")
        }

        // Compute the amount of padding before rendering the field name.
        let padding = flagStartOffset - rows[rowIndex].count
        guard padding >= 0 else {
          // If the padding we need to "add" is negative, then there already is
          // text where we want to place the field name. Instead, move to the
          // next row.
          rowIndex += 1
          continue
        }

        // Add the padding.
        rows[rowIndex].append(repeating: " ", count: padding)
        // Add the flag and field name.
        rows[rowIndex].append(flag)
        rows[rowIndex].append("╴")
        rows[rowIndex].append(name)
        break
      }
    }

    // Render the result to the screen.
    for line in above.reversed() {
      result.output(line)
    }
    result.output("\(binary: value, bits: Int(size), segmented: false)")
    for line in below {
      result.output(line)
    }
  }

  struct FieldRow {
    var bitRange: String
    var name: String
    var value: String
    var valueName: String?
  }

  func renderTable(
    register: SVDRegister,
    value: UInt64,
    result: inout some SVD2LLDBResult
  ) {
    // We want the rows to match the visual order of the bits in the hex value
    // printed above, so sort the fields by highest msb first.
    let fields = (register.fields?.field ?? []).sorted {
      $0.bitRange.range.upperBound > $1.bitRange.range.upperBound
    }

    // Walk through the fields once to compute the longest rendered bit range
    // and field name so we can align all the columns in the output. Also slice
    // the field's value from provided value.
    var longestBitRangePrefix = 0
    var longestNamePrefix = 0
    var longestValuePrefix = 0
    var rows = [FieldRow]()
    for field in fields {

      let range = field.bitRange.range
      let value = value[bits: range]

      var valueName: String?
      var defaultValueName: String?
      for enumeratedValue in field.enumeratedValues?.enumeratedValue ?? [] {
        switch enumeratedValue.data {
        case .value(let data):
          let mask = data.value.mask[bits: range]
          if (value & mask) == data.value.value {
            valueName = enumeratedValue.name
            // FIXME: this doesn't handle read vs write enumerated value
            break
          }
        case .isDefault(let data):
          if data.isDefault {
            defaultValueName = enumeratedValue.name
          }
        }
      }

      let valueString: String =
        if self.binary {
          "\(binary: value, bits: range.count)"
        } else {
          "\(hex: value, bits: range.count)"
        }

      let row = FieldRow(
        bitRange: "[\(range.upperBound - 1):\(range.lowerBound)]",
        name: field.name,
        value: valueString,
        valueName: valueName ?? defaultValueName)
      longestBitRangePrefix = max(row.bitRange.count, longestBitRangePrefix)
      longestNamePrefix = max(row.name.count, longestNamePrefix)
      longestValuePrefix = max(row.value.count, longestValuePrefix)
      rows.append(row)
    }

    // Render the rows.
    for row in rows {
      var description = ""
      do {
        // Add one for a trailing space separating the columns.
        let trailingPadding = longestBitRangePrefix - row.bitRange.count + 1
        description.append(row.bitRange)
        description.append(repeating: " ", count: trailingPadding)
      }

      do {
        // Add one for a trailing space separating the columns.
        let trailingPadding = longestNamePrefix - row.name.count + 1
        description.append(row.name)
        description.append(repeating: " ", count: trailingPadding)
      }

      do {
        // Add one for a trailing space separating the columns.
        let trailingPadding = longestValuePrefix - row.value.count + 1
        description.append(row.value)
        if row.valueName != nil {
          description.append(repeating: " ", count: trailingPadding)
        }
      }

      if let valueName = row.valueName {
        description.append("(")
        description.append(valueName)
        description.append(")")
      }

      result.output(description)
    }
  }
}
