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

extension Array where Element: SVDDerivable {
  private struct UnsafeRef<T> {
    var index: Int
  }

  private var mutableReferences: some Sequence<UnsafeRef<Element>> {
    self.indices.lazy.map { UnsafeRef<Element>(index: $0) }
  }

  private subscript(ref: UnsafeRef<Element>) -> Element {
    _read { yield self[ref.index] }
    _modify { yield &self[ref.index] }
  }

  mutating func deriveElements() throws {
    // Create a map to look up peripherals by name.
    var refByName: [String: UnsafeRef<Element>] = [:]
    for ref in self.mutableReferences {
      // FIXME: Error if duplicate name
      refByName[self[ref].name] = ref
    }

    // Expand derived-from relationships.
    for node in self.mutableReferences {
      // Create a stack of derived-from nodes.
      var stack = [node]
      while let childRef = stack.last {
        // Skip nodes without a derived-from relationship.
        guard let parentName = self[childRef].derivedFrom else { break }
        // Ensure the parent node doesn't already exist in the stack. If so,
        // then we have a cyclic derived-from relationship.
        // Note: stack.contains is O(N) but N is expected to be small.
        guard !stack.contains(where: { self[$0].name == parentName }) else {
          throw SVDDerivationError.cyclicDerivation(
            Element.kind,
            stack.map { self[$0].name })
        }
        // Find the parent node by name, if we can't find it throw an error.
        guard let parentRef = refByName[parentName] else {
          throw SVDDerivationError.derivationFromUnknownNode(
            Element.kind,
            self[childRef].name,
            parentName,
            self.map(\.name))
        }
        // Add the parent node to the stack and continue until the stack built.
        stack.append(parentRef)
      }

      // Pop backwards from the stack copying values from parents to children.
      var parentRef: UnsafeRef<Element>?
      while let childRef = stack.popLast() {
        // Update the parent to reference the current child.
        defer { parentRef = childRef }
        // Only copy from the parent if we have a parent node.
        guard let parentRef = parentRef else { continue }
        // Update the child's values using the parent's.
        self[childRef].merging(self[parentRef])
      }
    }
  }
}
