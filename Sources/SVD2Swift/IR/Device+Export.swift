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

let fileHeader = """
  // Generated by svd2swift.

  import MMIO\n\n
  """

struct ExportOptions {
  var indentation: Indentation
  var accessLevel: AccessLevel?
  var selectedPeripherals: [String]
  var namespaceUnderDevice: Bool
  var instanceMemberPeripherals: Bool
  var overrideDeviceName: String?
}

private struct ExportContext {
  var outputWriter: OutputWriter
  var accessLevel: AccessLevel?
  var selectedPeripherals: [String]
  var namespaceUnderDevice: Bool
  var instanceMemberPeripherals: Bool
  var overrideDeviceName: String?
}

extension Device {
  func export(
    with options: ExportOptions,
    to output: inout Output
  ) throws {
    var context = ExportContext(
      outputWriter: .init(output: output, indentation: options.indentation),
      accessLevel: options.accessLevel,
      selectedPeripherals: options.selectedPeripherals,
      namespaceUnderDevice: options.namespaceUnderDevice,
      instanceMemberPeripherals: options.instanceMemberPeripherals,
      overrideDeviceName: options.overrideDeviceName)
    defer { output = context.outputWriter.output }
    try self.export(into: &context)
  }

  fileprivate func export(into context: inout ExportContext) throws {
    var outputPeripherals = [Peripheral]()
    if context.selectedPeripherals.isEmpty {
      outputPeripherals = self.peripherals
    } else {
      var peripheralsByName = [String: Peripheral]()
      for peripheral in self.peripherals {
        peripheralsByName[peripheral.name] = peripheral
      }
      for selectedPeripheral in context.selectedPeripherals {
        guard let peripheral = peripheralsByName[selectedPeripheral] else {
          throw SVD2SwiftError.unknownPeripheral(
            selectedPeripheral, self.peripherals.map(\.name))
        }
        outputPeripherals.append(peripheral)
      }
    }

    let deviceName = context.overrideDeviceName ?? self.name
    context.outputWriter.append(fileHeader)
    if context.namespaceUnderDevice {
      let deviceDeclarationType =
        if context.instanceMemberPeripherals {
          "struct"
        } else {
          "enum"
        }
      context.outputWriter.append(
        """
        \(comment: self.description)
        \(context.accessLevel)\(deviceDeclarationType) \(deviceName) {

        """)
      context.outputWriter.indent()
    }
    for (index, peripheral) in outputPeripherals.enumerated() {
      peripheral.exportAccessor(context: &context)
      if index < outputPeripherals.count - 1 {
        context.outputWriter.append("\n")
      }
    }
    if context.namespaceUnderDevice {
      context.outputWriter.outdent()
      context.outputWriter.append("}\n")
    }
    try context.outputWriter.writeOutput(to: "Device.swift")

    for peripheral in outputPeripherals {
      context.outputWriter.append(fileHeader)
      peripheral.exportType(context: &context, deviceName: deviceName)
      try context.outputWriter.writeOutput(to: "\(peripheral.name).swift")
    }
  }
}

extension Peripheral {
  fileprivate func exportAccessor(context: inout ExportContext) {
    let accessorModifier =
      if context.instanceMemberPeripherals {
        ""
      } else {
        "static "
      }
    if let vector = self.vector {
      for index in 0..<vector.count {
        let addressOffset = vector.stride * index
        context.outputWriter.append(
          """
          \(comment: self.description)
          \(context.accessLevel)\(accessorModifier)let \(identifier: self.name.lowercased() + "\(index)") = \(self.name)(unsafeAddress: \(hex: self.baseAddress + addressOffset))

          """)
      }
    } else {
      context.outputWriter.append(
        """
        \(comment: self.description)
        \(context.accessLevel)\(accessorModifier)let \(identifier: self.name.lowercased()) = \(self.name)(unsafeAddress: \(hex: self.baseAddress))

        """)
    }
  }

  fileprivate func exportType(context: inout ExportContext, deviceName: String) {
    if context.namespaceUnderDevice {
      context.outputWriter.append("extension \(deviceName) {\n")
      context.outputWriter.indent()
    }

    if let derivedFrom = self.derivedFrom {
      // FIXME: Handle only exporting B where B deriveFrom A
      context.outputWriter.append("\(context.accessLevel)typealias \(self.name) = \(derivedFrom)\n")
      if context.namespaceUnderDevice {
        context.outputWriter.outdent()
        context.outputWriter.append("}\n")
      }
      return
    }

    context.outputWriter.append(
      """
      \(comment: self.description)
      @RegisterBlock
      \(context.accessLevel)struct \(self.name) {

      """)
    context.outputWriter.indent()
    if let registers = self.registers {
      for (index, register) in registers.enumerated() {
        register.exportAccessor(context: &context)
        if index < registers.count - 1 {
          context.outputWriter.append("\n")
        }
      }
    }
    context.outputWriter.outdent()
    context.outputWriter.append("}\n")
    if context.namespaceUnderDevice {
      context.outputWriter.outdent()
      context.outputWriter.append("}\n")
    }

    context.outputWriter.append("\n")

    let name =
      if context.namespaceUnderDevice {
        "\(deviceName).\(self.name)"
      } else {
        self.name
      }
    context.outputWriter.append("extension \(name) {\n")
    context.outputWriter.indent()
    if let registers = self.registers {
      for (index, register) in registers.enumerated() {
        register.exportType(context: &context)
        if index < registers.count - 1 {
          context.outputWriter.append("\n")
        }
      }
    }
    context.outputWriter.outdent()
    context.outputWriter.append("}\n")
  }
}

extension Register {
  fileprivate func exportAccessor(context: inout ExportContext) {
    if let vector = self.vector {
      context.outputWriter.append(
        """
        \(comment: self.description)
        @RegisterBlock(offset: \(hex: self.addressOffset), stride: \(hex: vector.stride), count: \(vector.count))
        \(context.accessLevel)var \(identifier: self.name.lowercased()): RegisterArray<\(self.name)>

        """)
    } else {
      context.outputWriter.append(
        """
        \(comment: self.description)
        @RegisterBlock(offset: \(hex: self.addressOffset))
        \(context.accessLevel)var \(identifier: self.name.lowercased()): Register<\(self.name)>

        """)
    }
  }

  fileprivate func exportType(context: inout ExportContext) {
    context.outputWriter.append(
      """
      \(comment: self.description)
      @Register(bitWidth: \(self.size))
      \(context.accessLevel)struct \(self.name) {

      """)
    context.outputWriter.indent()
    for (index, field) in self.fields.enumerated() {
      field.exportAccessor(context: &context)
      if index < self.fields.count - 1 {
        context.outputWriter.append("\n")
      }
    }
    context.outputWriter.outdent()
    context.outputWriter.append("}\n")
  }
}

extension Field {
  fileprivate func exportAccessor(context: inout ExportContext) {
    let macro =
      switch access {
      case .readOnly: "ReadOnly"
      case .writeOnly: "WriteOnly"
      case .readWrite: "ReadWrite"
      }

    // FIXME: array fields
    // Instead of splatting out N copies of the field we should have some way to
    // describe an array like RegisterArray
    if let vector = self.vector {
      for index in 0..<vector.count {
        let bitOffset = vector.stride * index
        context.outputWriter.append(
          """
          \(comment: self.description)
          @\(macro)(bits: \(self.lsb + bitOffset)..<\(self.msb + bitOffset + 1))
          \(context.accessLevel)var \(identifier: self.name.lowercased() + "\(index)"): \(self.name + "\(index)")

          """)
        if index < vector.count - 1 {
          context.outputWriter.append("\n")
        }
      }
    } else {
      context.outputWriter.append(
        """
        \(comment: self.description)
        @\(macro)(bits: \(self.lsb)..<\(self.msb + 1))
        \(context.accessLevel)var \(identifier: self.name.lowercased()): \(self.name)

        """)
    }
  }
}
