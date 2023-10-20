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

@testable import MMIOUtilities
import XCTest

final class IntervalTreeTests: XCTestCase {
  func testDotGraph() {
    let y = IntervalTreeNode(element: .init(range: 0..<1, value: "y"))
    let x = IntervalTreeNode(element: .init(range: 0..<1, value: "x"))
    let c = IntervalTreeNode(element: .init(range: 0..<1, value: "c"))
    let a = IntervalTreeNode(element: .init(range: 0..<1, value: "a"))
    let b = IntervalTreeNode(element: .init(range: 0..<1, value: "b"))

    y.leftChild = x
    y.rightChild = c
    x.leftChild = a
    x.rightChild = b

    let tree = IntervalTree<Int, String>()
    tree.root = y

    XCTAssertEqual(
      tree.dotGraph,
      """
      digraph tree {
        "root" -> "y (0..<1, 1)";
        "y (0..<1, 1)" -> "x (0..<1, 1)" [label=left];
        "x (0..<1, 1)" -> "a (0..<1, 1)" [label=left];
        "x (0..<1, 1)" -> "b (0..<1, 1)" [label=right];
        "y (0..<1, 1)" -> "c (0..<1, 1)" [label=right];
      }
      """)
  }


  /// ```
  ///     y               x
  ///    ╱ ╲    right    ╱ ╲
  ///   x   c   ─────>  a   y
  ///  ╱ ╲     <─────      ╱ ╲
  /// a   b     left      b   c
  /// ```
  func testRotate() {
    let y = IntervalTreeNode(element: .init(range: 0..<1, value: "y"))
    let x = IntervalTreeNode(element: .init(range: 0..<1, value: "x"))
    let c = IntervalTreeNode(element: .init(range: 0..<1, value: "c"))
    let a = IntervalTreeNode(element: .init(range: 0..<1, value: "a"))
    let b = IntervalTreeNode(element: .init(range: 0..<1, value: "b"))

    y.leftChild = x
    y.rightChild = c
    x.leftChild = a
    x.rightChild = b

    let tree = IntervalTree<Int, String>()
    tree.root = y
    XCTAssertEqual(
      tree.dotGraph,
      """
      digraph tree {
        "root" -> "y (0..<1, 1)";
        "y (0..<1, 1)" -> "x (0..<1, 1)" [label=left];
        "x (0..<1, 1)" -> "a (0..<1, 1)" [label=left];
        "x (0..<1, 1)" -> "b (0..<1, 1)" [label=right];
        "y (0..<1, 1)" -> "c (0..<1, 1)" [label=right];
      }
      """)

    tree.rotate(.right)
    XCTAssertEqual(
      tree.dotGraph,
      """
      digraph tree {
        "root" -> "x (0..<1, 1)";
        "x (0..<1, 1)" -> "a (0..<1, 1)" [label=left];
        "x (0..<1, 1)" -> "y (0..<1, 1)" [label=right];
        "y (0..<1, 1)" -> "b (0..<1, 1)" [label=left];
        "y (0..<1, 1)" -> "c (0..<1, 1)" [label=right];
      }
      """)

    tree.rotate(.left)
    XCTAssertEqual(
      tree.dotGraph,
      """
      digraph tree {
        "root" -> "y (0..<1, 1)";
        "y (0..<1, 1)" -> "x (0..<1, 1)" [label=left];
        "x (0..<1, 1)" -> "a (0..<1, 1)" [label=left];
        "x (0..<1, 1)" -> "b (0..<1, 1)" [label=right];
        "y (0..<1, 1)" -> "c (0..<1, 1)" [label=right];
      }
      """)
  }

  func test() {

    let tree = IntervalTree<Int, String>()

    tree.insert(element: .init(range: 5..<10, value: "N"))
    print(tree.dotGraph, "\n\n")
    tree.insert(element: .init(range: 15..<25, value: "N"))
    print(tree.dotGraph, "\n\n")
    tree.insert(element: .init(range: 1..<12, value: "N"))
    print(tree.dotGraph, "\n\n")
    tree.insert(element: .init(range: 8..<16, value: "N"))
    print(tree.dotGraph, "\n\n")
    tree.insert(element: .init(range: 14..<20, value: "N"))
    print(tree.dotGraph, "\n\n")
    tree.insert(element: .init(range: 18..<21, value: "N"))
    print(tree.dotGraph, "\n\n")
    tree.insert(element: .init(range: 2..<8, value: "N"))
    print(tree.dotGraph, "\n\n")
  }
}
