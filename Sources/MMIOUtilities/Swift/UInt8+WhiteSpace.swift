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

extension UInt8 {
  // FIXME: use InlineArray if/when back deployed
  static let whiteSpaceMap: [Bool] = {
    var whiteSpaceMap = [Bool](repeating: false, count: 256)
    let horizontalTab = 0x9
    let newline = 0xa
    let verticalTab = 0xb
    let formFeed = 0xc
    let carriageReturn = 0xd
    let space = 0x20

    whiteSpaceMap[horizontalTab] = true
    whiteSpaceMap[newline] = true
    whiteSpaceMap[verticalTab] = true
    whiteSpaceMap[formFeed] = true
    whiteSpaceMap[carriageReturn] = true
    whiteSpaceMap[space] = true

    return whiteSpaceMap
  }()

  public var isWhiteSpace: Bool {
    Self.whiteSpaceMap[Int(self)]
  }
}
