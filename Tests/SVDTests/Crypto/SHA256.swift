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

@available(macOS 9999, *)
enum SHA256 {}

@available(macOS 9999, *)
extension SHA256 {
  static let initialState: InlineArray<8, UInt32> = [
    0x6a09e667, 0xbb67ae85, 0x3c6ef372, 0xa54ff53a,
    0x510e527f, 0x9b05688c, 0x1f83d9ab, 0x5be0cd19
  ]

  static let keys: InlineArray<64, UInt32> = [
    0x428a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5,
    0x3956c25b, 0x59f111f1, 0x923f82a4, 0xab1c5ed5,
    0xd807aa98, 0x12835b01, 0x243185be, 0x550c7dc3,
    0x72be5d74, 0x80deb1fe, 0x9bdc06a7, 0xc19bf174,
    0xe49b69c1, 0xefbe4786, 0x0fc19dc6, 0x240ca1cc,
    0x2de92c6f, 0x4a7484aa, 0x5cb0a9dc, 0x76f988da,
    0x983e5152, 0xa831c66d, 0xb00327c8, 0xbf597fc7,
    0xc6e00bf3, 0xd5a79147, 0x06ca6351, 0x14292967,
    0x27b70a85, 0x2e1b2138, 0x4d2c6dfc, 0x53380d13,
    0x650a7354, 0x766a0abb, 0x81c2c92e, 0x92722c85,
    0xa2bfe8a1, 0xa81a664b, 0xc24b8b70, 0xc76c51a3,
    0xd192e819, 0xd6990624, 0xf40e3585, 0x106aa070,
    0x19a4c116, 0x1e376c08, 0x2748774c, 0x34b0bcb5,
    0x391c0cb3, 0x4ed8aa4a, 0x5b9cca4f, 0x682e6ff3,
    0x748f82ee, 0x78a5636f, 0x84c87814, 0x8cc70208,
    0x90befffa, 0xa4506ceb, 0xbef9a3f7, 0xc67178f2,
  ]

  struct Hasher: ~Copyable {
    var state: InlineArray<8, UInt32>
    var buffer: InlineArray<64, UInt8>
    var bufferCount: UInt64
    var totalCount: UInt64

    init() {
      self.state = SHA256.initialState
      self.buffer = .init(repeating: 0)
      self.bufferCount = 0
      self.totalCount = 0
    }
  }

  struct Digest {
    var storage: InlineArray<32, UInt8>
  }
}

@available(macOS 9999, *)
extension SHA256.Hasher {
  mutating func hash(_ bytes: RawSpan) {
    bytes.withUnsafeBytes { buffer in
      for byte in buffer {
        self.append(byte: byte)
      }
    }
  }

  consuming func finalize() -> SHA256.Digest {
    let totalCount = self.totalCount

    // Pad to block with 56 bytes.
    self.append(byte: 0x80)
    while self.bufferCount != 56 {
      self.append(byte: 0)
    }

    // Fill remaining block with total byte count.
    var totalBitCount = (totalCount * 8).bigEndian
    for _ in 0..<8 {
      let byte = UInt8(truncatingIfNeeded: totalBitCount)
      totalBitCount = totalBitCount >> 8
      self.append(byte: byte)
    }

    // Convert state to big endian
    for index in self.state.span.indices {
      self.state[index] = self.state[index].bigEndian
    }

    // Return state as digest
    return SHA256.Digest(storage: unsafeBitCast(self.state, to: InlineArray<32, UInt8>.self))
  }
}

@available(macOS 9999, *)
extension SHA256.Hasher {
  fileprivate mutating func append(byte: UInt8) {
    self.buffer[Int(self.bufferCount)] = byte
    self.bufferCount += 1
    self.totalCount += 1

    if self.bufferCount == buffer.count {
      self.bufferCount = 0
      self.block()
    }
  }

  fileprivate mutating func block() {
    var a = self.state[0]
    var b = self.state[1]
    var c = self.state[2]
    var d = self.state[3]
    var e = self.state[4]
    var f = self.state[5]
    var g = self.state[6]
    var h = self.state[7]

    var w = InlineArray<16, UInt32>(repeating: 0)
    for i in stride(from: 0, to: 64, by: 16) {
      self.update_w(&w, i, self.buffer.span.bytes)

      for j in stride(from: 0, to: 16, by: 4) {
        let k = i &+ j

        let t0 = h &+ self.step1(e, f, g) &+ SHA256.keys[k &+ 0] &+ w[j &+ 0]
        h = t0 &+ d
        d = t0 &+ self.step2(a, b, c)

        let t1 = g &+ self.step1(h, e, f) &+ SHA256.keys[k &+ 1] &+ w[j &+ 1]
        g = t1 &+ c
        c = t1 &+ self.step2(d, a, b)

        let t2 = f &+ self.step1(g, h, e) &+ SHA256.keys[k &+ 2] &+ w[j &+ 2]
        f = t2 &+ b
        b = t2 &+ self.step2(c, d, a)

        let t3 = e &+ self.step1(f, g, h) &+ SHA256.keys[k &+ 3] &+ w[j + 3]
        e = t3 &+ a
        a = t3 &+ self.step2(b, c, d)
      }
    }

    self.state[0] &+= a
    self.state[1] &+= b
    self.state[2] &+= c
    self.state[3] &+= d
    self.state[4] &+= e
    self.state[5] &+= f
    self.state[6] &+= g
    self.state[7] &+= h
  }

  private func rotr(_ value: UInt32, _ count: Int) -> UInt32 {
    (value >> count) | (value << (value.bitWidth - count))
  }

  private func step1(_ e: UInt32, _ f: UInt32, _ g: UInt32) -> UInt32 {
    (rotr(e, 6) ^ rotr(e, 11) ^ rotr(e, 25)) &+ ((e & f) ^ ((~e) & g))
  }

  private func step2(_ a: UInt32, _ b: UInt32, _ c: UInt32) -> UInt32 {
    (rotr(a, 2) ^ rotr(a, 13) ^ rotr(a, 22)) &+ ((a & b) ^ (a & c) ^ (b & c))
  }

  private func update_w(_ w: inout InlineArray<16, UInt32>, _ i: Int, _ buffer: RawSpan) {
    buffer.withUnsafeBytes { buffer in
      var index = 0
      for j in 0..<0x10 {
        if i < 0x10 {
          w[j] =
            (UInt32(buffer[index + 0]) << 0x18) |
            (UInt32(buffer[index + 1]) << 0x10) |
            (UInt32(buffer[index + 2]) << 0x08) |
            (UInt32(buffer[index + 3]) << 0x00)
          index += 4
        } else {
          let a = w[(j + 1) & 0x0f]
          let b = w[(j + 14) & 0x0f]
          let s0 = rotr(a,  7) ^ rotr(a, 18) ^ (a >>  3)
          let s1 = rotr(b, 17) ^ rotr(b, 19) ^ (b >> 10)
          w[j] &+= w[(j + 9) & 0x0f] &+ s0 &+ s1
        }
      }
    }
  }
}
