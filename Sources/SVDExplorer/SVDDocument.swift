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

import SwiftUI
import UniformTypeIdentifiers
import SVD

extension UTType {
  static let svd: UTType = UTType(exportedAs: "com.keil.svd")
}

struct SVDDocument: FileDocument {
  var data: Data
  var device: SVDDevice

  static var readableContentTypes: [UTType] { [.svd] }

  init(configuration: ReadConfiguration) throws {
    do {
      let data = try configuration.file.regularFileContents.unwrap()
      try self.init(data: data)
    } catch {
      print("failed to load file: \(error)")
      throw CocoaError(.fileReadCorruptFile)
    }
  }

  init(data: Data) throws {
    self.data = data
    self.device = try! SVDDevice(svdData: data)
    self.device.peripherals.peripheral.sort { $0.name < $1.name }
  }

  func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
    .init(regularFileWithContents: self.data)
  }
}

extension SVDDocument {
  init() {
    let url = URL(filePath: "/Users/rauhul/Desktop/ARM_Sample.svd")
//    let url = Bundle.main.url(forResource: "ARM_Sample", withExtension: "svd", subdirectory: nil)
    let data = try! Data(contentsOf: url)
    try! self.init(data: data)
  }
}
