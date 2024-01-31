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

import SVD

extension String {
  func coalescingConsecutiveSpaces() -> Self {
    if #available(macOS 13.0, *) {
      self.replacing(#/  +/#, with: " ")
    } else {
      self.split(separator: " ").joined(separator: " ")
    }
  }
}

extension Device {
  init(svdDevice: SVDDevice) throws {
    self.name = svdDevice.name
      .replacingOccurrences(of: "-", with: "_")
    self.description =
      svdDevice.description?
      .coalescingConsecutiveSpaces() ?? svdDevice.name
    self.peripherals = [Peripheral]()

    var allSVDPeripheralsByName = [String: SVDPeripheral]()
    for svdPeripheral in svdDevice.peripherals.peripheral {
      // FIXME: Error if duplicate name
      allSVDPeripheralsByName[svdPeripheral.name] = svdPeripheral
    }

    for svdPeripheral in svdDevice.peripherals.peripheral {
      var visitedPeripherals = [String]()
      let peripheral = try Peripheral(
        svdPeripheral: svdPeripheral,
        allSVDPeripheralsByName: allSVDPeripheralsByName,
        visitedPeripherals: &visitedPeripherals,
        defaultProperties: svdDevice.registerProperties)
      self.peripherals.append(peripheral)
    }

    self.peripherals.sort { $0.name < $1.name }
  }
}

extension Peripheral {
  init(
    svdPeripheral: SVDPeripheral,
    allSVDPeripheralsByName: [String: SVDPeripheral],
    visitedPeripherals: inout [String],
    defaultProperties: SVDRegisterProperties
  ) throws {
    let superPeripheral: Peripheral?
    if let derivedFrom = svdPeripheral.derivedFrom {
      if let cycleStartIndex = visitedPeripherals.firstIndex(of: derivedFrom) {
        throw SVD2SwiftError.cyclicPeripheralDerivation(
          visitedPeripherals[cycleStartIndex...])
      }
      visitedPeripherals.append(derivedFrom)

      guard let superSVDPeripheral = allSVDPeripheralsByName[derivedFrom] else {
        throw SVD2SwiftError.derivedFromUnknownPeripheral(
          svdPeripheral.name,
          derivedFrom,
          allSVDPeripheralsByName.values.map(\.name).sorted())
      }
      superPeripheral = try Peripheral(
        svdPeripheral: superSVDPeripheral,
        allSVDPeripheralsByName: allSVDPeripheralsByName,
        visitedPeripherals: &visitedPeripherals,
        defaultProperties: defaultProperties)
    } else {
      superPeripheral = nil
    }

    let registerProperties = svdPeripheral.registerProperties
      .merging(defaultProperties)

    self.name = svdPeripheral.name
      .replacingOccurrences(of: "%s", with: "")
      .replacingOccurrences(of: "[]", with: "")
      .replacingOccurrences(of: "-", with: "_")
    self.derivedFrom = superPeripheral?.name
    self.description =
      svdPeripheral.description?.coalescingConsecutiveSpaces()
      ?? superPeripheral?.description ?? svdPeripheral.name

    self.baseAddress = svdPeripheral.baseAddress
    if let count = svdPeripheral.dimensionElement.dim {
      // FIXME: registerProperties.size may be incorrect here.
      let stride =
        svdPeripheral.dimensionElement.dimIncrement
        ?? registerProperties.size ?? 0
      self.vector = Vector(stride: stride, count: count)
    } else {
      self.vector = nil
    }

    let registers = try svdPeripheral.registers?.register.map {
      try Register(svdRegister: $0, defaultProperties: registerProperties)
    }

    if let registers = registers {
      // Clear derivedFrom so we consider this peripheral to be independent from
      // its parent later in the code generation process.
      self.derivedFrom = nil
      self.registers = registers
    }

    self.interrupt =
      svdPeripheral.interrupt.map(Interrupt.init)
      ?? superPeripheral?.interrupt
  }
}

extension Register {
  init(
    svdRegister: SVDRegister,
    defaultProperties: SVDRegisterProperties
  ) throws {
    let registerProperties = svdRegister.registerProperties
      .merging(defaultProperties)

    self.name = svdRegister.name
      .replacingOccurrences(of: "%s", with: "")
      .replacingOccurrences(of: "[]", with: "")
      .replacingOccurrences(of: "-", with: "_")
    self.description =
      svdRegister.description?
      .coalescingConsecutiveSpaces() ?? self.name

    self.addressOffset = svdRegister.addressOffset
    if let count = svdRegister.dimensionElement.dim {
      let stride =
        svdRegister.dimensionElement.dimIncrement
        ?? registerProperties.size ?? 0
      self.vector = Vector(stride: stride, count: count)
    } else {
      self.vector = nil
    }
    self.size = registerProperties.size ?? 0
    self.resetValue = registerProperties.resetValue ?? 0

    self.fields = try (svdRegister.fields?.field ?? [])
      .map { try Field(svdField: $0, defaultProperties: registerProperties) }
  }
}

extension Field {
  init(svdField: SVDField, defaultProperties: SVDRegisterProperties) throws {
    self.name = svdField.name
      .replacingOccurrences(of: "%s", with: "")
      .replacingOccurrences(of: "[]", with: "")
      .replacingOccurrences(of: "-", with: "_")
    self.description =
      svdField.description?
      .coalescingConsecutiveSpaces() ?? self.name

    switch svdField.bitRange {
    case .lsbMsb(let value):
      self.lsb = value.lsb
      self.msb = value.msb
    case .offsetWidth(let value):
      self.lsb = value.bitOffset
      self.msb = value.bitOffset + (value.bitWidth ?? 1) - 1
    case .literal(let value):
      self.lsb = value.bitRange.lsb
      self.msb = value.bitRange.msb
    }
    let size = self.msb - self.lsb

    if let count = svdField.dimensionElement.dim {
      let stride = svdField.dimensionElement.dimIncrement ?? size
      self.vector = Vector(stride: stride, count: count)
    } else {
      self.vector = nil
    }

    self.access =
      try svdField.access.flatMap(FieldAccess.init)
      ?? defaultProperties.access.flatMap(FieldAccess.init)
      ?? .readWrite
  }
}

extension FieldAccess {
  init(svdAccess: SVDAccess) throws {
    switch svdAccess {
    case .readOnly: self = .readOnly
    case .writeOnly: self = .writeOnly
    case .readWrite: self = .readWrite
    // FIXME: How to express in Swift?
    case .writeOnce: self = .writeOnly
    // FIXME: How to express in Swift?
    case .readWriteOnce: self = .readWrite
    }
  }
}

extension Interrupt {
  init(svdInterrupt: SVDInterrupt) {
    self.name = svdInterrupt.name.replacingOccurrences(of: "-", with: "_")
    self.description = svdInterrupt.description ?? svdInterrupt.name
    self.value = svdInterrupt.value
  }
}
