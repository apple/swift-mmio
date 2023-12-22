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

extension MutableCollection {
  /// Iterate through a collection mutating each element.
  ///
  /// This is a workaround for Swift not having first class support for:
  /// ```swift
  /// for mutating element in collection
  /// ```
  ///
  /// - Parameter body: Mutating operation to perform on each element.
  mutating func mutatingForEach(body: (inout Self.Element) -> Void) {
    var currentIndex = self.startIndex
    while currentIndex != self.endIndex {
      body(&self[currentIndex])
      self.formIndex(after: &currentIndex)
    }
  }
}

extension Device {
  mutating func sanitize() {
    self.peripherals.mutatingForEach { peripheral in
      peripheral.sanitize()
    }
  }
}

extension Peripheral {
  mutating func sanitize() {
    self.registers?.mutatingForEach { register in
      register.sanitize()
    }
  }
}

extension Register {
  mutating func sanitize() {
    self.fields.mutatingForEach { field in
      field.sanitize(registerName: self.name)
    }
  }
}

extension Field {
  mutating func sanitize(registerName: String) {
    if self.name == registerName {
      // This assumes no other field in the register has the same name as
      // this field suffixed by `_FIELD`.
      self.name += "_FIELD"
    }
    if self.name == self.name.lowercased() {
      // If the field's name is all lowercase then the generated type and
      // property will collide.
      self.name = self.name.uppercased()
    }
  }
}
