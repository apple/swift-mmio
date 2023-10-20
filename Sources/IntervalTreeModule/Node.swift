//===--------------------------------------------------------------*- c -*-===//
//
// This source file is part of the Swift MMIO open source project
//
// Copyright (c) 2023 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

// FIXME: Improve performance with array allocation
//
// Node could be made more performant by allocating into an array and using
// array offsets to reference child nodes instead of pointers.

/// A node of an interval tree.
class Node<Bound, Value> where Bound: Comparable {
  /// The value associated with this node.
  var value: Value
  /// The lower bound of the interval associated by this node.
  var lowerBound: Bound
  /// The upper bound of the interval associated by this node.
  var upperBound: Bound
  /// The maximum bound of all descendent nodes of this node.
  var maximumBound: Bound
  /// The left child of this node.
  var leftChild: Node<Bound, Value>?
  /// The right child of this node.
  var rightChild: Node<Bound, Value>?
  /// The height of the tree descending from this node.
  var height: Int

  /// Constructs a new node from an element detached from any tree.
  init(element: Element<Bound, Value>) {
    self.value = element.value
    self.lowerBound = element.range.lowerBound
    self.upperBound = element.range.upperBound
    self.maximumBound = element.range.upperBound
    self.leftChild = nil
    self.rightChild = nil
    self.height = 1
  }
}

extension Node {
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
  /// `sortOrder(left) < sortOrder(root) < sortOrders(right)`.
  func rotate(_ rotation: Rotation) -> Node {
    switch rotation {
    case .right: self.rotateRight()
    case .left: self.rotateLeft()
    }
  }

  private func rotateRight() -> Node {
    guard var x = self.leftChild else {
      preconditionFailure(
        "Cannot rotate node to the right, node has no left child")
    }
    var b = x.rightChild

    // Rotate the nodes.
    x.rightChild = self
    self.leftChild = b

    // Update node heights.
    self.recomputeHeight()
    x.recomputeHeight()

    // Return new root node.
    return x
  }

  private func rotateLeft() -> Node {
    guard var y = self.rightChild else {
      preconditionFailure(
        "Cannot rotate node to the left, node has no right child")
    }
    var b = y.leftChild

    // Rotate the nodes.
    y.leftChild = self
    self.rightChild = b

    // Update node heights.
    self.recomputeHeight()
    y.recomputeHeight()

    // Return new root node.
    return y
  }

  @inline(__always)
  private func recomputeHeight() {
    let childHeight = max(
      self.leftChild?.height ?? 0,
      self.rightChild?.height ?? 0)
    self.height = childHeight + 1
  }
}

extension Node {
//  /// The relative height of a node's children.
//  enum ChildHeightDifference {
//    /// The node's left child is higher than the right child.
//    case leftHigher
//    /// The node's left and right children are of equal height.
//    case equalHeight
//    /// The node's right child is higher than the left child.
//    case rightHigher
//  }

  /// The height difference between the children of this node.
  ///
  /// A positive value indicates the left child is higher than the right child.
  /// Inversely, a negative value indicates the left child is lower than the
  /// right child. A value of zero (`0`) indicates the children are of equal
  /// height.
  var childHeightDifference: Int {
    (self.leftChild?.height ?? 0) - (self.rightChild?.height ?? 0)
  }
}

extension Node {
  // TODO: Document
  func insert(node: Node) -> Node {
    // Standard binary search tree node insertion.
    if node.lowerBound < self.lowerBound {
      self.leftChild = self.leftChild?.insert(node: node) ?? node
    } else {
      self.rightChild = self.rightChild?.insert(node: node) ?? node
    }
    self.maximumBound = max(self.maximumBound, node.upperBound)

    // Update height of this new node.
    node.recomputeHeight()

    // Get the child height difference for this node in order to check if the
    // node has become unbalanced.
    let childHeightDifference = node.childHeightDifference

    switch childHeightDifference {
    case 2...:
      // The left child is 2 or more nodes higher than the right node.
      guard let leftChild = self.leftChild else {
        preconditionFailure("""
          left child cannot be nil if child height difference is greater than 0
          """)
      }

      if node.lowerBound < leftChild.lowerBound {
        // Left Left Case
        return node.rotate(.right)
      } else {
        // Left Right Case
        self.leftChild = self.leftChild?.rotate(.left)
        return node.rotate(.right)
      }

    case ...(-2):
      guard let rightChild = self.rightChild else {
        preconditionFailure("""
          right child cannot be nil if child height difference is less than 0
          """)
      }

      if node.lowerBound > rightChild.lowerBound {
        // Right Right Case
        return node.rotate(.left)
      } else {
        // Right Left Case
        self.rightChild = self.rightChild?.rotate(.right)
        return node.rotate(.left)
      }

    default:
      return node
    }
  }
}
