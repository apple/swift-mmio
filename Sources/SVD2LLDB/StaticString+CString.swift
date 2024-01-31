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

extension StaticString {
  var cString: UnsafePointer<CChar> {
    precondition(MemoryLayout<UInt8>.size == MemoryLayout<CChar>.size)
    precondition(MemoryLayout<UInt8>.stride == MemoryLayout<CChar>.stride)
    precondition(MemoryLayout<UInt8>.alignment == MemoryLayout<CChar>.alignment)
    return UnsafeRawPointer(self.utf8Start)
      .bindMemory(to: CChar.self, capacity: self.utf8CodeUnitCount)
  }
}
