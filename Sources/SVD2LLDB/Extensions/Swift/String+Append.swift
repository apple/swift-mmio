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

extension String {
  mutating func append(repeating character: Character, count: Int) {
    let additionalBytes = character.utf8.count * count
    let currentBytes = self.utf8.count
    let newBytes = currentBytes + additionalBytes
    self.reserveCapacity(newBytes)
    for _ in 0..<count {
      self.append(character)
    }
  }
}
