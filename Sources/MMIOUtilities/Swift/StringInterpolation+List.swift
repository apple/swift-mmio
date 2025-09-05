//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift MMIO open source project
//
// Copyright (c) 2023 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

extension String.StringInterpolation {
  public mutating func appendInterpolation(
    list collection: some Collection,
    quoted: Bool = true,
    separator: String = ",",
    conjunction: String = "or"
  ) {
    let count = collection.count
    switch count {
    case 0:
      break

    case 1:
      let element = collection[collection.startIndex]
      self.appendInterpolation(value: element, quoted: quoted)

    case 2:
      var index = collection.startIndex
      var element = collection[index]
      self.appendInterpolation(value: element, quoted: quoted)
      self.appendInterpolation(" ")
      self.appendInterpolation(conjunction)
      self.appendInterpolation(" ")
      collection.formIndex(after: &index)
      element = collection[index]
      self.appendInterpolation(value: element, quoted: quoted)

    default:
      for (index, element) in collection.enumerated() {
        self.appendInterpolation(value: element, quoted: quoted)
        if index < count - 2 {
          self.appendInterpolation(separator)
          self.appendInterpolation(" ")
        } else if index < count - 1 {
          self.appendInterpolation(separator)
          self.appendInterpolation(" ")
          self.appendInterpolation(conjunction)
          self.appendInterpolation(" ")
        }
      }
    }
  }

  public mutating func appendInterpolation<Value>(
    value: Value,
    quoted: Bool
  ) {
    if quoted {
      self.appendInterpolation("'")
    }
    self.appendInterpolation("\(value)")
    if quoted {
      self.appendInterpolation("'")
    }
  }

  public mutating func appendInterpolation<C>(
    cycle collection: C
  ) where C: Collection {
    for (index, element) in collection.enumerated() {
      self.appendInterpolation(value: element, quoted: true)
      if index < collection.count - 1 {
        self.appendInterpolation(" -> ")
      }
    }
  }
}
