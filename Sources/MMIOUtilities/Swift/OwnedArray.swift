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

/// A growable array of noncopyable elements.
///
/// The array owns its buffer and checks each index, so its API is safe.
@safe
public struct OwnedArray<Element: ~Copyable>: ~Copyable {
  private var buffer: UnsafeMutableBufferPointer<Element>?
  private var _count: Int

  public var capacity: Int { unsafe self.buffer?.count ?? 0 }
  public var count: Int { self._count }
  public var isEmpty: Bool { self.count == 0 }
  public var indices: Range<Int> { 0..<self.count }

  public init() {
    unsafe self.buffer = nil
    self._count = 0
  }

  deinit {
    unsafe self.buffer?.extracting(..<self.count).deinitialize()
    unsafe self.buffer?.deallocate()
  }

  public subscript(_ index: Int) -> Element {
    _read {
      guard let buffer = unsafe self.buffer, self.indices.contains(index) else {
        fatalError("Index out of range")
      }
      yield unsafe buffer[index]
    }
    _modify {
      guard let buffer = unsafe self.buffer, self.indices.contains(index) else {
        fatalError("Index out of range")
      }
      yield unsafe &buffer[index]
    }
  }

  public mutating func push(_ value: consuming Element) {
    if self.count == self.capacity {
      if let oldBuffer = unsafe self.buffer {
        let newBuffer = UnsafeMutableBufferPointer<Element>.allocate(
          capacity: oldBuffer.count * 2)
        _ = unsafe newBuffer.moveInitialize(fromContentsOf: oldBuffer)
        unsafe oldBuffer.deallocate()
        unsafe self.buffer = newBuffer
      } else {
        unsafe self.buffer = .allocate(capacity: 4)
      }
    }
    unsafe self.buffer?.initializeElement(at: self.count, to: value)
    self._count += 1
  }

  public mutating func pop() -> Element? {
    guard self.count > 0 else { return nil }
    let element = unsafe self.buffer?.moveElement(from: self.count - 1)
    self._count -= 1
    return element
  }
}
