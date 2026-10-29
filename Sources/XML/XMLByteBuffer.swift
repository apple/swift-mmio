//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift MMIO open source project
//
// Copyright (c) 2026 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

/// A growable byte buffer without the checks of `Array`.
///
/// The buffer owns its memory and reads only the initialized bytes, so its
/// API is safe except for the methods that take unsafe pointers.
@safe
struct XMLByteBuffer: ~Copyable {
  private var base: UnsafeMutablePointer<UInt8>
  private var capacity: Int
  private(set) var count: Int

  init() {
    self.capacity = 64
    unsafe self.base = .allocate(capacity: self.capacity)
    self.count = 0
  }

  deinit {
    unsafe self.base.deallocate()
  }

  var isEmpty: Bool { self.count == 0 }

  mutating func append(contentsOf bytes: UnsafeBufferPointer<UInt8>) {
    guard let source = bytes.baseAddress else { return }
    let newCount = self.count + bytes.count
    if newCount > self.capacity {
      let capacity = max(self.capacity * 2, newCount)
      let base = UnsafeMutablePointer<UInt8>.allocate(capacity: capacity)
      unsafe base.initialize(from: self.base, count: self.count)
      unsafe self.base.deallocate()
      unsafe self.base = base
      self.capacity = capacity
    }
    unsafe (self.base + self.count).initialize(from: source, count: bytes.count)
    self.count = newCount
  }

  mutating func removeAll() {
    self.count = 0
  }

  func string() -> String {
    unsafe String(
      decoding: UnsafeBufferPointer(start: self.base, count: self.count),
      as: UTF8.self)
  }
}
