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

// coalescingConsecutiveWhitespace
extension String {
  enum State {
    case initial
    case character
    case space
    case newline
    case end

    mutating func next(_ character: UnicodeScalar) -> UnicodeScalar {
      switch self {
      case .initial:
        switch character {
          self = .space
        default:
          self = .character
        }
      case .character:
      }
    }
  }

  var svdNormalized: String {

  }
}
