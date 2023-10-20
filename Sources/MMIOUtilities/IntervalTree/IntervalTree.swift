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

public class IntervalTree<Bound, Value> where Bound: Comparable {
  public internal(set) var root: IntervalTreeNode<Bound, Value>?

  public init() {
    self.root = nil
  }
}

extension IntervalTree {
  func rotate(_ rotation: IntervalTreeNode<Bound, Value>.Rotation) {
    self.root = self.root?.rotate(rotation)
  }

  public func insert(element: Element<Bound, Value>) {
    self.root = self.root?.insert(element: element) ?? .init(element: element)
  }
}

extension IntervalTree {
  public var dotGraph: String {
    var dotGraph = "digraph tree {\n"
    if let root = self.root {
      dotGraph += "  \"root\" -> \(root.dotGraphKey);\n"
      root.dotGraph(into: &dotGraph)
    } else {
      dotGraph += "  \"root\" -> \"none\";\n"
    }
    dotGraph += "}"
    return dotGraph
  }
}
