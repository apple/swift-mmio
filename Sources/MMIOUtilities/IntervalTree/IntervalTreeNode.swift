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

/// A node of an interval tree.
public class IntervalTreeNode<Bound, Value> where Bound: Comparable {
  /// The value associated with this node.
  public internal(set) var value: Value
  /// The lower bound of the interval associated by this node.
  public internal(set) var lowerBound: Bound
  /// The upper bound of the interval associated by this node.
  public internal(set) var upperBound: Bound
  /// The maximum bound of all descendent nodes of this node.
  public internal(set) var maximumBound: Bound
  /// The left child of this node.
  public internal(set) var leftChild: IntervalTreeNode<Bound, Value>?
  /// The right child of this node.
  public internal(set) var rightChild: IntervalTreeNode<Bound, Value>?
  /// The height of the tree descending from this node.
  public internal(set) var height: Int

  /// Constructs a new node from an element detached from any tree.
  public init(element: Element<Bound, Value>) {
    self.value = element.value
    self.lowerBound = element.range.lowerBound
    self.upperBound = element.range.upperBound
    self.maximumBound = element.range.upperBound
    self.leftChild = nil
    self.rightChild = nil
    self.height = 1
  }
}

extension IntervalTreeNode {
  /// A rotation direction.
  enum Rotation {
    /// A rightward or clockwise rotation.
    case right
    /// A leftward or counterclockwise rotation.
    case left
  }

  /// Rotates a node right or left returning the new root node after the
  /// rotation.
  ///
  /// Given the following two trees, rotating the tree rooted at node y right
  /// yields the tree rooted at node x. Inversely, rotating the tree rooted at
  /// node x to the left yields the tree rooted at node y.
  ///
  /// ```
  ///     y               x
  ///    ╱ ╲    right    ╱ ╲
  ///   x   c   ─────>  a   y
  ///  ╱ ╲     <─────      ╱ ╲
  /// a   b     left      b   c
  /// ```
  ///
  /// Rotating a node maintains the binary tree property where
  /// `sortOrder(left) < sortOrder(root) < sortOrder(right)`.
  func rotate(_ rotation: Rotation) -> IntervalTreeNode {
    switch rotation {
    case .right: self.rotateRight()
    case .left: self.rotateLeft()
    }
  }

  private func rotateRight() -> IntervalTreeNode {
    // y: self
    // x: leftChild
    // b: leftRightChild
    guard let leftChild = self.leftChild else {
      preconditionFailure(
        "Cannot rotate node to the right, node has no left child")
    }
    let leftRightChild = leftChild.rightChild

    // Rotate the nodes.
    leftChild.rightChild = self
    self.leftChild = leftRightChild

    // Update node properties, first `self` then `leftChild`; order matters.
    self.recomputeMaximumBoundAndHeight()
    leftChild.recomputeMaximumBoundAndHeight()

    // Return new root node.
    return leftChild
  }

  private func rotateLeft() -> IntervalTreeNode {
    // x: self
    // y: rightChild
    // b: rightLeftChild

    guard let rightChild = self.rightChild else {
      preconditionFailure(
        "Cannot rotate node to the left, node has no right child")
    }
    let rightLeftChild = rightChild.leftChild

    // Rotate the nodes.
    rightChild.leftChild = self
    self.rightChild = rightLeftChild

    // Update node properties, first `self` then `rightChild`; order matters.
    self.recomputeMaximumBoundAndHeight()
    rightChild.recomputeMaximumBoundAndHeight()

    // Return new root node.
    return rightChild
  }
}

extension IntervalTreeNode {
  func recomputeMaximumBoundAndHeight() {
    self.height = 0
    self.maximumBound = self.upperBound
    if let leftChild = self.leftChild {
      self.height = max(self.height, leftChild.height)
      self.maximumBound = max(self.maximumBound, leftChild.maximumBound)
    }
    if let rightChild = self.rightChild {
      self.height = max(self.height, rightChild.height)
      self.maximumBound = max(self.maximumBound, rightChild.maximumBound)
    }
    self.height += 1
  }

  /// The height difference between the children of this node.
  ///
  /// A positive value indicates the left child is higher than the right child.
  /// Inversely, a negative value indicates the left child is lower than the
  /// right child. A value of zero (`0`) indicates the children are of equal
  /// height.
  var balanceFactor: Int {
    (self.leftChild?.height ?? 0) - (self.rightChild?.height ?? 0)
  }
}

extension IntervalTreeNode {
  public func insert(element: Element<Bound, Value>) -> IntervalTreeNode {
    self.insert(node: IntervalTreeNode(element: element))
  }

  public func insert(node newNode: IntervalTreeNode) -> IntervalTreeNode {
    // Standard binary search tree node insertion.
    if newNode.lowerBound < self.lowerBound {
      self.leftChild = self.leftChild?.insert(node: newNode) ?? newNode
    } else {
      self.rightChild = self.rightChild?.insert(node: newNode) ?? newNode
    }

    // Update properties of this node with the new node inserted.
    self.recomputeMaximumBoundAndHeight()

    // Get the height difference of this node's children in order to check if
    // it has become unbalanced.
    let balanceFactor = self.balanceFactor
    if balanceFactor > 1 {
      // The left child is 2 or more nodes higher than the right node.
      guard let leftChild = self.leftChild else {
        preconditionFailure("""
          left child cannot be nil if child height difference is greater than 0
          """)
      }

      if newNode.lowerBound < leftChild.lowerBound {
        // Left Left Case
        return self.rotate(.right)
      } else {
        // Left Right Case
        self.leftChild = leftChild.rotate(.left)
        return self.rotate(.right)
      }

    } else if balanceFactor < -1 {
      // The right child is 2 or more nodes higher than the left node.
      guard let rightChild = self.rightChild else {
        preconditionFailure("""
          right child cannot be nil if child height difference is less than 0
          """)
      }

      if newNode.lowerBound > rightChild.lowerBound {
        // Right Right Case
        return self.rotate(.left)
      } else {
        // Right Left Case
        self.rightChild = rightChild.rotate(.right)
        return self.rotate(.left)
      }

    } else {
      return self
    }
  }
}

extension IntervalTreeNode {
  var dotGraphKey: String {
    """
    "\(self.value) \
    (\(self.lowerBound)..<\(self.upperBound), \
    \(self.maximumBound))"
    """
  }

  func dotGraph(into: inout String) {
    if let leftChild = self.leftChild {
      into += "  \(self.dotGraphKey) -> \(leftChild.dotGraphKey) [label=left];\n"
      leftChild.dotGraph(into: &into)
    }
    if let rightChild = self.rightChild {
      into += "  \(self.dotGraphKey) -> \(rightChild.dotGraphKey) [label=right];\n"
      rightChild.dotGraph(into: &into)
    }
  }
}
