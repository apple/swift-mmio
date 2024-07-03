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

extension String {
  var svdNormalizedText: String {
    var result = ""
    var currentSelfIndex = self.startIndex

    while currentSelfIndex < self.endIndex {
      var nextSelfIndex = self.index(after: currentSelfIndex)
      var character = self[currentSelfIndex]
      if character == #"\"#, nextSelfIndex < self.endIndex {
        let nextCharacter = self[nextSelfIndex]
        if nextCharacter == "n" {
          character = "\n"
          currentSelfIndex = nextSelfIndex
          nextSelfIndex = self.index(after: nextSelfIndex)
        }
      }
      currentSelfIndex = nextSelfIndex

      switch character {
      case " ":
        if result.last != " " && result.last != "\n" {
          result.append(character)
        }
      case "\n":
        if result.last != "\n" {
          if result.last == " " {
            result.removeLast()
          }
          result.append(character)
        }
      default:
        result.append(character)
      }
    }

    return result
  }
}
