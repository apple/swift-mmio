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

// O(N) lookup, only use this when the data set is not very wide.
final class PrefixTree<Element> where Element: Hashable {
  var source: Element?
  var element: Element
  // FIXME: SortedSet
  var children: [PrefixTree]

  init(element: Element) {
    self.source = nil
    self.element = element
    self.children = []
  }
}

extension PrefixTree {
  func insert(source: Element, sequence: some Sequence<Element>) {
    var tree = self
    for element in sequence {
      tree = tree.insert(element: element)
    }
    tree.source = source
  }

  private func insert(element: Element) -> PrefixTree {
    guard let tree = self.children.first(where: { $0.element == element }) else {
      let tree = Self(element: element)
      self.children.append(tree)
      return tree
    }
    return tree
  }
}

extension PrefixTree: CustomStringConvertible {
  var description: String {
    var description = ""
    self._description(into: &description, prefix: "")
    return description
  }

  func _description(into description: inout String, prefix: String) {
    description.append("\(prefix)\(self.element)")
    if let source = self.source {
      description.append(" -> \(source)")
    }
    description.append("\n")
    for child in self.children {
      child._description(into: &description, prefix: prefix + "  ")
    }
  }
}
