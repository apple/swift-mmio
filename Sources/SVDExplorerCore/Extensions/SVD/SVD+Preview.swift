//===----------------------------------------------------------*- swift -*-===//
//
// This source file is part of the Swift MMIO open source project
//
// Copyright (c) 2025 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

import SVD
import Foundation

extension SVDDocument {
  static let preview: Self = {
    let url = Bundle.main.url(forResource: "ARM_Sample", withExtension: "svd")!
    let data = try! Data(contentsOf: url)
    return try! SVDDocument(data: data)
  }()
}

extension SVDDevice {
  static let preview = SVDDocument.preview.device
}

extension SVDPeripheral {
  static let preview = SVDDevice.preview.peripherals.peripheral[0]
}

extension SVDRegister {
  static let preview = (SVDPeripheral.preview.registers?.register ?? [])[0]
}

extension SVDField {
  static let preview = (SVDRegister.preview.fields?.field ?? [])[0]
}
