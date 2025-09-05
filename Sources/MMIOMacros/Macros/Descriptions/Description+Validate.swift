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

import MMIOUtilities
import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

extension BitFieldDescription {
  func validate(
    in context: MacroContext<some ParsableMacro, some MacroExpansionContext>
  ) {
    self.validateBounds(in: context)
    self.validateOverlappingRanges(in: context)
  }

  func validateBounds(
    in context: MacroContext<some ParsableMacro, some MacroExpansionContext>
  ) {
    let range = 0..<self.bitWidth
    var notes: [Note] = []

    for index in self.bitRanges.indices {
      let bitRange = self.bitRanges[index]
      let bitRangeExpression = self.bitRangeExpressions[index]
      if let bound = bitRange.inclusiveLowerBound, !range.contains(bound) {
        notes.append(
          .bitFieldOutOfBounds(
            bitRangeExpression: bitRangeExpression,
            registerBitRange: range))
        continue
      }

      if let bound = bitRange.inclusiveUpperBound, !range.contains(bound) {
        notes.append(
          .bitFieldOutOfBounds(
            bitRangeExpression: bitRangeExpression,
            registerBitRange: range))
        continue
      }
    }

    if !notes.isEmpty {
      _ = context.error(
        at: self.attribute.attributeName,
        message: .bitFieldOutOfBounds(
          attribute: "\(self.attribute.trimmed)",
          pluralize: notes.count > 1),
        notes: notes,
        fixIts: [])
    }
  }

  struct BitRangeRef {
    var range: Int
  }

  func validateOverlappingRanges(
    in context: MacroContext<some ParsableMacro, some MacroExpansionContext>
  ) {
    // Only run this code if there is more than one bit range in the field.
    guard self.bitRanges.count > 1 else { return }

    // Create indirect references to the bit ranges using their indices
    let refs = self.bitRanges.indices.map { BitRangeRef(range: $0) }

    // Helpers to easily retrieve a range/expression from a ref.
    func range(for index: BitRangeRef) -> BitRange {
      self.bitRanges[index.range]
    }

    func expr(for index: BitRangeRef) -> ExprSyntax {
      self.bitRangeExpressions[index.range]
    }

    var notes: [Note] = []
    Validator.locateOverlappingRanges(
      refs: refs,
      rangeForRef: { range(for: $0) },
      overlappingRange: { targetRef, overlappingRefs, overlappingRanges in
        let targetRange = range(for: targetRef)
        let targetRangeExpression = expr(for: targetRef)
        let overlappingExpressions = overlappingRefs.map { expr(for: $0) }
        notes.append(
          .bitFieldOverlappingBitRanges(
            bitRange: Range(targetRange.canonicalizedClosedRange),
            bitRangeExpression: targetRangeExpression,
            overlappingRanges: overlappingRanges,
            overlappingExpressions: overlappingExpressions.map {
              "\($0.trimmed)"
            }))
      })
    guard !notes.isEmpty else { return }

    _ = context.error(
      at: self.attribute.attributeName,
      message: .bitFieldOverlappingBitRanges(
        attribute: "\(self.attribute.trimmed)"),
      notes: notes,
      fixIts: [])
  }
}

extension RegisterDescription {
  func validate(
    in context: MacroContext<some ParsableMacro, some MacroExpansionContext>
  ) {
    // Validate bit range in each bit field.
    for bitField in self.bitFields {
      bitField.validate(in: context)
    }

    // Validate bit ranges across bit fields.
    self.validateOverlappingRanges(in: context)
  }

  struct BitRangeRef {
    var field: Int
    var range: Int
  }

  func validateOverlappingRanges(
    in context: MacroContext<some ParsableMacro, some MacroExpansionContext>
  ) {
    // Only run this code if there is more than one bit field in the register.
    guard self.bitFields.count > 1 else { return }

    // Calculate the total number of ranges in the register
    var totalBitRanges = 0
    for bitField in self.bitFields {
      totalBitRanges += bitField.bitRanges.count
    }

    // Create indirect references to the bit ranges using their register /
    // bitfield indices.
    var refs: [BitRangeRef] = []
    refs.reserveCapacity(totalBitRanges)
    for fieldIndex in self.bitFields.indices {
      let bitField = self.bitFields[fieldIndex]
      for rangeIndex in bitField.bitRanges.indices {
        refs.append(.init(field: fieldIndex, range: rangeIndex))
      }
    }

    // Helpers to easily retrieve a range/expression from a ref.
    func range(for index: BitRangeRef) -> BitRange {
      self.bitFields[index.field].bitRanges[index.range]
    }

    func expr(for index: BitRangeRef) -> ExprSyntax {
      self.bitFields[index.field].bitRangeExpressions[index.range]
    }

    var notes: [Note] = []
    Validator.locateOverlappingRanges(
      refs: refs,
      rangeForRef: { range(for: $0) },
      overlappingRange: { targetRef, overlappingRefs, overlappingRanges in
        // Group the overlaps by field. Use an array because the number of
        // fields is small and we want this to remain sorted.
        var groups: [(Int, IdentifierPatternSyntax, [ExprSyntax])] = []

        for overlappingRef in overlappingRefs {
          let field = overlappingRef.field
          let group: Int
          let _group = groups.firstIndex { field == $0.0 }
          if let _group {
            group = _group
          } else {
            let fieldName = self.bitFields[field].fieldName
            groups.append((field, fieldName, []))
            group = groups.endIndex - 1
          }
          groups[group].2.append(expr(for: overlappingRef))
        }

        notes.append(
          .registerOverlappingBitRanges(
            bitRangeExpression: expr(for: targetRef),
            overlappingCount: overlappingRefs.count,
            overlappingGroups: groups))
      })
    guard !notes.isEmpty else { return }

    _ = context.error(
      at: self.name,
      message: .bitFieldOverlappingBitRanges(
        attribute: "\(self.name.trimmed)"),
      notes: notes,
      fixIts: [])
  }
}

enum Validator {
  static func hasOverlappingRanges<Ref>(
    refs: some Sequence<Ref>,
    rangeForRef: (Ref) -> BitRange
  ) -> Bool {
    // Walk the bit ranges searching for overlapping ranges.
    var previousUpperBound: Int? = nil
    for ref in refs {
      // If any overlaps are found, exit early from the loop.
      let bitRange = rangeForRef(ref)
      if let previousUpperBound = previousUpperBound,
        bitRange.canonicalizedLowerBound < previousUpperBound
      {
        return true
      }
      previousUpperBound = bitRange.canonicalizedUpperBound
    }
    return false
  }

  /// Walk the bit ranges to find overlapping ranges and invoke a callback for
  /// each overlap.
  ///
  /// Given the example bit ranges: `[0..<24, 8..<32, 16..<48, 36..<44]`
  ///
  /// The ranges visually look like:
  /// ```
  /// 0       8       16      24      32  36      44  48
  /// ╎       ╎       ╎       ╎       ╎   ╎       ╎   ╎
  /// •───────────────────────◦       ╎   ╎       ╎   ╎
  /// ╎       •───────────────────────◦   ╎       ╎   ╎
  /// ╎       ╎       •───────────────────────────────◦
  /// ╎       ╎       ╎       ╎       ╎   •───────◦   ╎
  /// ╎       ╎       ╎       ╎       ╎   ╎       ╎   ╎
  /// 0       8       16      24      32  36      44  48
  /// ```
  ///
  /// For each bit range that has overlaps, the `overlappingRange` callback
  /// will be invoked with:
  /// - The target range reference
  /// - An array of references to ranges that overlap with the target
  /// - An array of the specific overlapping subranges
  ///
  /// For the example above, the callback would be invoked for:
  /// - Range `0..<24` with overlapping ranges `[8..<32, 16..<48]` and subrange
  ///   `[8..<24]`
  /// - Range `8..<32` with overlapping ranges `[0..<24, 16..<48]` and subrange
  ///   `[8..<32]`
  /// - Range `16..<48` with overlapping ranges `[0..<24, 8..<32, 36..<44]` and
  ///   subranges `[16..<32, 36..<44]`
  /// - Range `36..<44` with overlapping range `[16..<48]` and subrange
  ///   `[36..<44]`
  ///
  /// The caller can use the callback to emit diagnostics.
  static func locateOverlappingRanges<Ref>(
    refs: consuming [Ref],
    rangeForRef: (Ref) -> BitRange,
    overlappingRange: (Ref, [Ref], [Range<Int>]) -> Void
  ) {
    // Sort the bit ranges.
    refs.sort { rangeForRef($0) < rangeForRef($1) }

    // Fast walk the bit ranges searching for overlapping ranges. If there are
    // any, We can start a new (slower) walk to emit proper diagnostics.
    let overlap = Self.hasOverlappingRanges(refs: refs) { rangeForRef($0) }

    // If no overlaps are found, exit early from the function.
    guard overlap else { return }

    // Perform a worst case O(n^2) walk to find the overlap for each bit range,
    // collecting them into notes.
    var candidateRefStartIndex = refs.startIndex
    for targetRefIndex in refs.indices {
      // Get the target range to check overlap against.
      let targetRef = refs[targetRefIndex]
      let targetRange = rangeForRef(targetRef)

      // Keep track of the overlapping bit ranges for the target bit range.
      var overlappingRefs: [Ref] = []
      var overlappingRanges: [Range<Int>] = []

      // Determine the index where the candidate overlap search should start
      // from. We do this by getting the bounds of the next target range and
      // keeping track of the first candidate range which could overlap with it.
      // This allows us to skip comparing against earlier candidate ranges which
      // we already know fall out of lower bounds.
      //
      //    0   4   8   12  16  20  24  28
      //    ╎   ╎   ╎   ╎   ╎   ╎   ╎   ╎
      // 0: •───────────────◦   ╎   ╎   ╎ // Candidates start at 0
      // 1: ╎   •───◦   ╎   ╎   ╎   ╎   ╎ // Candidates start at 0
      // 2: ╎   ╎   ╎   •───────────◦   ╎ // Candidates start at 0
      // 3: ╎   ╎   ╎   ╎   ╎   •───────◦ // Candidates start at 2
      //    ╎   ╎   ╎   ╎   ╎   ╎   ╎   ╎
      //    0   4   8   12  16  20  24  28
      //
      // Get the index of the next target range and its lower bound.
      let nextTargetRefIndex = refs.index(after: targetRefIndex)
      let nextTargetRange: BitRange
      if nextTargetRefIndex < refs.endIndex {
        nextTargetRange = rangeForRef(refs[nextTargetRefIndex])
      } else {
        nextTargetRange = BitRange(lowerBound: nil, upperBound: nil)
      }

      // Iterate through the candidates looking for overlapping ranges.
      for candidateRefIndex in candidateRefStartIndex..<refs.endIndex {
        // Skip comparing a bit range to itself.
        guard targetRefIndex != candidateRefIndex else { continue }

        // Get the candidate range to check overlap with.
        let candidateRef = refs[candidateRefIndex]
        let candidateRange = rangeForRef(candidateRef)

        // If the current candidate's upper bound is less than the next target's
        // lower bound, then it cannot overlap with the next target and the
        // candidate search for the next target should start after the current
        // candidate.
        if candidateRange.canonicalizedUpperBound
          < nextTargetRange.canonicalizedLowerBound
        {
          candidateRefStartIndex = refs.index(after: candidateRefIndex)
        }

        // Exit early if the candidate lower bound is larger than the target
        // upper bound. This is ok because `refs` is sorted, no following
        // candidates will overlap the target.
        guard
          let overlappingRange = targetRange.rangeOverlapping(candidateRange)
        else {
          break
        }

        // Attempt to merge the overlapping range into the previous overlapping
        // range to form larger continuous overlapping ranges.
        if let previousOverlappingRange = overlappingRanges.last,
          overlappingRange.lowerBound <= previousOverlappingRange.upperBound
        {
          overlappingRanges.removeLast()
          overlappingRanges.append(
            previousOverlappingRange.lowerBound..<overlappingRange.upperBound)
        } else {
          overlappingRanges.append(overlappingRange)
        }

        overlappingRefs.append(candidateRef)
      }

      // If there are overlapping ranges after walking, call the handler.
      if !overlappingRefs.isEmpty {
        overlappingRange(targetRef, overlappingRefs, overlappingRanges)
      }
    }
  }
}

extension ErrorDiagnostic {
  static func bitFieldOutOfBounds(
    attribute: String,
    pluralize: Bool
  ) -> Self {
    .init(
      """
      bit range\(pluralize ? "s" : "") in '\(attribute)' \
      extend\(pluralize ? "" : "s") outside register bounds
      """)
  }

  static func bitFieldOverlappingBitRanges(
    attribute: String
  ) -> Self {
    .init("overlapping bit ranges in '\(attribute)'")
  }

  static func registerOverlappingBitRanges(
    name: String
  ) -> Self {
    .init("overlapping bit ranges in '\(name)'")
  }
}

extension Note {
  static func bitFieldOutOfBounds(
    bitRangeExpression: ExprSyntax,
    registerBitRange: Range<Int>
  ) -> Self {
    .init(
      node: Syntax(bitRangeExpression),
      message: MacroExpansionNoteMessage(
        """
        bit range '\(bitRangeExpression)' extends outside register bit range \
        '\(registerBitRange)'
        """
      ))
  }

  static func bitFieldOverlappingBitRanges(
    bitRange: Range<Int>,
    bitRangeExpression: ExprSyntax,
    overlappingRanges: [Range<Int>],
    overlappingExpressions: [ExprSyntax]
  ) -> Note {
    let pluralizeRanges = overlappingExpressions.count != 1
    var message = """
      bit range '\(bitRangeExpression.trimmed)' \
      overlaps bit range\(pluralizeRanges ? "s" : "") \
      \(list: overlappingExpressions, conjunction: "and")
      """

    let fullRange =
      overlappingRanges.count == 1
      && bitRange == overlappingRanges[0]
    if !fullRange {
      let pluralizeSubranges = overlappingRanges.count != 1
      message.append(
        contentsOf: """
           over subrange\(pluralizeSubranges ? "s" : "") \
          \(list: overlappingRanges, conjunction: "and")
          """)
    }

    return .init(
      node: Syntax(bitRangeExpression),
      message: MacroExpansionNoteMessage(message))
  }

  static func registerOverlappingBitRanges(
    bitRangeExpression: ExprSyntax,
    overlappingCount: Int,
    overlappingGroups: [(Int, IdentifierPatternSyntax, [ExprSyntax])],
  ) -> Note {
    let pluralizeRanges = overlappingCount != 1
    var segments: [String] = []
    for (_, fieldName, expressions) in overlappingGroups {
      segments.append(
        "\(list: expressions, conjunction: "and") in '\(fieldName)'")
    }

    let message = """
      bit range '\(bitRangeExpression.trimmed)' \
      overlaps bit range\(pluralizeRanges ? "s" : "") \
      \(list: segments, quoted: false, conjunction: "and")
      """

    return .init(
      node: Syntax(bitRangeExpression),
      message: MacroExpansionNoteMessage(message))
  }
}
