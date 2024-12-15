//===----------------------------------------------------------*- swift -*-===//
//
// This source file is part of the Swift MMIO open source project
//
// Copyright (c) 2024 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

#if canImport(System) && canImport(CryptoKit)
import CryptoKit
import Foundation
import System

extension FileManager {
  private func combineHashOfFile<H>(
    at url: URL,
    into hashFunction: inout H,
    bufferingFileDataInto buffer: UnsafeMutableRawBufferPointer
  ) throws where H: HashFunction {
    let fd = try FileDescriptor.open(url.path, .readOnly)
    defer { try? fd.close() }
    while true {
      let count = try fd.read(into: buffer)
      guard count > 0 else { break }
      let buffer = UnsafeRawBufferPointer(rebasing: buffer[0..<count])
      hashFunction.update(bufferPointer: buffer)
    }
  }

  func hashOfFile<H>(
    at url: URL,
    using hashFunction: H.Type = H.self
  ) throws -> H.Digest where H: HashFunction {
    var hash = H()
    try withUnsafeTemporaryAllocation(byteCount: 2048, alignment: 1) { buffer in
      try self.combineHashOfFile(
        at: url,
        into: &hash,
        bufferingFileDataInto: buffer)
    }
    return hash.finalize()
  }

  func hashOfFiles<H>(
    inDirectory directoryURL: URL,
    withPathExtension pathExtension: String,
    using hashFunction: H.Type = H.self
  ) throws -> H.Digest where H: HashFunction {
    let fd = try FileDescriptor.open(directoryURL.path, .readOnly)
    try fd.close()

    let matchingURLs = self.files(
      inDirectory: directoryURL,
      withPathExtension: pathExtension)

    var hash = H()
    let fileReadBufferCapacity = 2048
    try withUnsafeTemporaryAllocation(
      byteCount: fileReadBufferCapacity,
      alignment: MemoryLayout<UInt8>.alignment
    ) { buffer in
      for url in matchingURLs {
        try self.combineHashOfFile(
          at: url,
          into: &hash,
          bufferingFileDataInto: buffer)
      }
    }
    return hash.finalize()
  }
}
#endif
