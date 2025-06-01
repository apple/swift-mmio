//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift MMIO open source project
//
// Copyright (c) 2023 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

enum FileCheckDirectiveKind {
  case label
  case plain
  case next
  case same
}

struct FileCheckDirective {
  var kind: FileCheckDirectiveKind
  var match: Substring
  var column: Int
}

extension FileCheckDirective {
  init?(input: Substring) {
    let original = input
    guard let startIndex = original.firstIndex(of: "/") else { return nil }

    var input = original[startIndex...]
    if input.hasPrefix("// CHECK-LABEL:") {
      input.removeFirst("// CHECK-LABEL:".count)
      self.kind = .label
    } else if input.hasPrefix("// CHECK:") {
      input.removeFirst("// CHECK:".count)
      self.kind = .plain
    } else if input.hasPrefix("// CHECK-NEXT:") {
      input.removeFirst("// CHECK-NEXT:".count)
      self.kind = .next
    } else if input.hasPrefix("// CHECK-SAME:") {
      input.removeFirst("// CHECK-SAME:".count)
      self.kind = .same
    } else {
      return nil
    }
    input = input.drop(while: \.isWhitespace)

    self.match = input
    self.column = original.distance(from: original.startIndex, to: startIndex)
  }
}
