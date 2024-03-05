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

#if os(macOS)
import CryptoKit
import Foundation
import MMIOUtilities
import SVD
import XCTest
import System

extension FormatStyle where Self == Duration.UnitsFormatStyle {
  static var elapsedSeconds: Self {
    .units(
      width: .narrow,
      fractionalPart: .init(lengthLimits: 0...2))
  }
}

final class SVDTests: XCTestCase {
  struct TestError: Error, CustomStringConvertible {
    var description: String
  }

  let selfFileURL = URL(fileURLWithPath: #file)
  lazy var selfDirectoryURL = self.selfFileURL
    .deletingLastPathComponent()
  lazy var packageDirectoryURL = self.selfDirectoryURL
    .deletingLastPathComponent()
    .deletingLastPathComponent()
  lazy var buildDirectoryURL: URL = self.packageDirectoryURL
    .appendingPathComponent(".build")
  lazy var testDataZipFileURL: URL = self.buildDirectoryURL
    .appendingPathComponent("cmsis-svd-data.zip")
  lazy var testDataDirectoryURL: URL = self.buildDirectoryURL
    .appendingPathComponent("cmsis-svd-data")

  // These constants will need to be updated if the external resources change.
  let testDataRemoteURL = URL(
    string: """
      https://github.com/cmsis-svd/cmsis-svd-data/archive/\
      853bb02dc1ac496576fd9de49483a35fa43ca90e.zip
      """)!
  let testDataZipFileSHA512 =
    """
    cefcb870b6e38372e070410020d9d7eb2e0187c85898a24bb95036ab63a3aee7\
    d76566fa6f52fe135375ced84d4ee2ad44335bfc7524cd80eb703d8da030e361
    """
  /// SHA 512 of all SVD files contained in the zip.
  ///
  /// Validated manually by via:
  /// ```bash
  /// fd '\.svd$' -IH .build/cmsis-svd-data \
  ///   | sort \
  ///   | xargs cat \
  ///   | shasum -a 512 -
  /// ```
  let testDataSVDFilesSHA512 =
    """
    48f3ec6df67c5282199bc5e1085b18892e1a0e090c44d1daaec06b225c7b2858\
    89de5cf7f999c33d818d6ea2933c16f1678c98655ca7830d53e0c76a1861ba32
    """
  let testDataSVDFilesCount = 1880

  @available(macOS 12.0, *)
  func test_decode() async throws {
    if ProcessInfo.processInfo.environment["CI"] != nil {
      throw XCTSkip("Skipping SVDTests in CI: download times out on macOS.")
    }

    try await validateTestData(downloadingIfNeeded: true)

    let svdURLs = FileManager.default.files(
      inDirectory: self.testDataDirectoryURL,
      withPathExtension: "svd")

    XCTAssertEqual(
      svdURLs.count,
      testDataSVDFilesCount,
      "Failed to locate all expected SVD files")

    let time = await ContinuousClock().measure {
      let parsedSVDs = await svdURLs.parallelReduce(
        into: 0,
        using: +,
        taskLimit: 8,
        priority: .high,
        operation: Self.parseSVD)
      XCTAssertEqual(parsedSVDs, svdURLs.count, "Failed to parse all svd files")
    }
    print("Tests completed in \(time.formatted(.elapsedSeconds)).")
  }

  @Sendable
  static func parseSVD(url: URL) -> Int {
    print("Running:", url.lastPathComponent)
    let data: Data
    do {
      data = try Data(contentsOf: url)
    } catch {
      XCTFail("Failed to load contents of svd at '\(url.path)': \(error)")
      return 0
    }

    do {
      _ = try SVDDevice(svdData: data)
    } catch {
      XCTFail("Failed to parse svd at '\(url.path)': \(error)")
      return 0
    }

    return 1
  }

  func validateTestData(downloadingIfNeeded: Bool) async throws {
    let fm = FileManager.default
    let us = URLSession.shared

    do {
      let sha512 = try fm.hashOfFile(
        at: self.testDataZipFileURL,
        using: SHA512.self)
      guard sha512.equals(self.testDataZipFileSHA512) else {
        throw TestError(
          description: """
            Test data at '\(self.testDataZipFileURL.path)' does not match \
            expected checksum, please remove file and re-run: expected 'SHA512 \
            digest: \(self.testDataZipFileSHA512)' but found '\(sha512)'.
            """)
      }
    } catch Errno.noSuchFileOrDirectory where downloadingIfNeeded {
      print("Downloading test data from '\(self.testDataRemoteURL)'")
      let downloadURL = try await us.download(from: self.testDataRemoteURL).0
      let sha512 = try fm.hashOfFile(at: downloadURL, using: SHA512.self)
      guard sha512.equals(self.testDataZipFileSHA512) else {
        throw TestError(
          description: """
            Downloaded test data at '\(downloadURL.path)' does not match \
            expected checksum, please validate data: expected 'SHA512 digest: \
            \(self.testDataZipFileSHA512)' but found '\(sha512)'.
            """)
      }
      try fm.moveItem(at: downloadURL, to: self.testDataZipFileURL)
    }

    do {
      let sha512 = try fm.hashOfFiles(
        inDirectory: self.testDataDirectoryURL,
        withPathExtension: "svd",
        using: SHA512.self)
      guard sha512.equals(self.testDataSVDFilesSHA512) else {
        throw TestError(
          description: """
            Test data at '\(self.testDataDirectoryURL.path)' does not match \
            the expected checksum, please remove directory and re-run: \
            Expected 'SHA512 digest: \(self.testDataZipFileSHA512)' but found \
            '\(sha512)'.
            """)
      }
    } catch Errno.noSuchFileOrDirectory where downloadingIfNeeded {
      print("Extracting download at '\(self.testDataZipFileURL.path)'")
      _ = try sh(
        """
        unzip -o \
          -d \(self.testDataDirectoryURL.path) \
          \(self.testDataZipFileURL.path)
        """)
      let sha512 = try fm.hashOfFiles(
        inDirectory: self.testDataDirectoryURL,
        withPathExtension: "svd",
        using: SHA512.self)
      guard sha512.equals(self.testDataSVDFilesSHA512) else {
        throw TestError(
          description: """
            Extracted test data at '\(self.testDataDirectoryURL.path)' does \
            not match the expected checksum, please validate data: Expected \
            'SHA512 digest: \(self.testDataSVDFilesSHA512)' but found \
            '\(sha512)'.
            """)
      }
    }
  }
}

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

  func files(
    inDirectory directoryURL: URL,
    withPathExtension pathExtension: String
  ) -> [URL] {
    let enumerator = self.enumerator(
      at: directoryURL,
      includingPropertiesForKeys: [])
    guard let enumerator = enumerator else { return [] }

    return enumerator
      .lazy
      .compactMap { $0 as? URL }
      .filter { $0.pathExtension == pathExtension }
      .sorted { $0.path < $1.path }
  }
}

extension Digest {
  // This is not production quality code. This is strictly test support code.
  func equals(_ hexString: String) -> Bool {
    withUnsafeTemporaryAllocation(
      byteCount: Self.byteCount,
      alignment: MemoryLayout<UInt8>.alignment
    ) { expected in
      precondition(hexString.utf8.count == Self.byteCount * 2)
      var hexString = hexString
      var index = 0
      while !hexString.isEmpty {
        let hexByte = hexString.prefix(2)
        hexString.removeFirst(2)
        let byte = UInt8(hexByte, radix: 16)!
        expected[index] = byte
        index += 1
      }
      return self.withUnsafeBytes { actual in
        actual.elementsEqual(expected)
      }
    }
  }
}

extension Sequence where Element: Sendable {
  func parallelReduce<Result, PartialResult>(
    into initial: Result,
    using reducer: (Result, PartialResult) -> (Result),
    taskLimit: Int,
    priority: TaskPriority? = nil,
    operation: @Sendable @escaping (Element) async -> PartialResult
  ) async -> Result {
    await withTaskGroup(
      of: PartialResult.self,
      returning: Result.self
    ) { group in
      var value = initial
      var tasks = 0
      for element in self {
        if tasks < taskLimit {
          tasks += 1
        } else {
          if let newValue = await group.next() {
            value = reducer(value, newValue)
          }
        }
        group.addTask(priority: priority) { await operation(element) }
      }
      while let newValue = await group.next() {
        value = reducer(value, newValue)
      }
      return value
    }
  }
}
#endif
