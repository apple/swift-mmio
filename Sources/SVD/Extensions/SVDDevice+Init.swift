//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift MMIO open source project
//
// Copyright (c) 2024 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

public import Foundation
import XML

extension SVDDevice {
  public init(data: Data) throws {
    self = try XMLParserDecoder.decode(SVDDevice.self, from: data)
  }
}
