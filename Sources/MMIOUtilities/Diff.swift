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

public func diff(
  expected: String,
  actual: String,
  noun: String
) -> String {
  diff(
    expected: expected.split(separator: "\n", omittingEmptySubsequences: false),
    actual: actual.split(separator: "\n", omittingEmptySubsequences: false),
    noun: noun)
}

public func diff<Element>(
  expected: [Element],
  actual: [Element],
  noun: String
) -> String where Element: Equatable {
  assert(expected != actual)

  // Use `CollectionDifference` on supported platforms to get `diff`-like
  // line-based output.
  let difference = actual.difference(from: expected)
  var insertions: [Int: Element] = [:]
  var removals: [Int: Element] = [:]
  for change in difference {
    switch change {
    case .insert(let offset, let element, _):
      insertions[offset] = element
    case .remove(let offset, let element, _):
      removals[offset] = element
    }
  }

  var expectedLine = 0
  var actualLine = 0
  var result = ""
  while expectedLine < expected.count || actualLine < actual.count {
    if let removal = removals[expectedLine] {
      result += "-\(removal)\n"
      expectedLine += 1
    } else if let insertion = insertions[actualLine] {
      result += "+\(insertion)\n"
      actualLine += 1
    } else {
      result += " \(expected[expectedLine])\n"
      expectedLine += 1
      actualLine += 1
    }
  }

  result.removeLast()

  return """
    Actual \(noun) (+) differed from expected \(noun) (-):
    \(result)
    """
}
