//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift MMIO open source project
//
// Copyright (c) 2025 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

public struct OwnedArray<Element: ~Copyable>: ~Copyable {
  var buffer: UnsafeMutableBufferPointer<Element>?
  var _count: Int

  public var capacity: Int { self.buffer?.count ?? 0 }
  public var count: Int { self._count }
  public var isEmpty: Bool { self.count == 0 }
  public var indices: Range<Int> { 0..<self.count }

  public init() {
    self.buffer = nil
    self._count = 0
  }

  deinit {
    self.buffer?.extracting(..<self.count).deinitialize()
    self.buffer?.deallocate()
  }

  public subscript(_ index: Int) -> Element {
    _read {
      guard let buffer = self.buffer, index < self.count else {
        fatalError("Index out of range")
      }
      yield buffer[index]
    }
    _modify {
      guard let buffer = self.buffer, index < self.count else {
        fatalError("Index out of range")
      }
      yield &buffer[index]
    }
  }

  public mutating func push(_ value: consuming Element) {
    if self.count == self.capacity {
      if let oldBuffer = self.buffer {
        let newBuffer = UnsafeMutableBufferPointer<Element>.allocate(
          capacity: oldBuffer.count * 2)
        _ = newBuffer.moveInitialize(fromContentsOf: oldBuffer)
        oldBuffer.deallocate()
        self.buffer = newBuffer
      } else {
        self.buffer = .allocate(capacity: 4)
      }
    }
    self.buffer?.initializeElement(at: self.count, to: value)
    self._count += 1
  }

  public mutating func pop() -> Element? {
    guard self.count > 0 else { return nil }
    let element = self.buffer?.moveElement(from: self.count - 1)
    self._count -= 1
    return element
  }
}
