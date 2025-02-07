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

import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxMacroExpansion
import SwiftSyntaxMacros

extension BitFieldDescription {
  func validate(
    in context: MacroContext<some ParsableMacro, some MacroExpansionContext>
  ) {
    self.validateBounds(in: context)

    if self.bitRanges.count > 1 {
      self.validateOverlappingRanges(in: context)
    }
  }

  func validateBounds(
    in context: MacroContext<some ParsableMacro, some MacroExpansionContext>
  ) {
    let range = 0..<self.bitWidth
    var notes: [Note] = []

    var error = false
    for index in self.bitRanges.indices {
      let bitRange = self.bitRanges[index]
      let bitRangeExpression = self.bitRangeExpressions[index]
      if let bound = bitRange.inclusiveLowerBound, !range.contains(bound) {
        notes.append(
          .bitFieldOutOfBounds(
            bitRangeExpression: bitRangeExpression,
            registerBitRange: range))
        error = true
        continue
      }

      if let bound = bitRange.inclusiveUpperBound, !range.contains(bound) {
        notes.append(
          .bitFieldOutOfBounds(
            bitRangeExpression: bitRangeExpression,
            registerBitRange: range))
        error = true
        continue
      }
    }

    if error {
      _ = context.error(
        at: self.attribute.attributeName,
        message: .bitFieldOutOfBounds(
          attribute: "\(self.attribute.trimmed)",
          pluralize: notes.count > 1),
        notes: notes,
        fixIts: [])
    }
  }

  /// Walk the bit ranges forming error diagnostics for overlapping of ranges.
  ///
  /// Given the example bit field:
  /// ```
  /// @BitField(bits: 0..<24, 8..<32, 16..<48, 36..<44)
  /// var field: Field
  /// ```
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
  /// The following diagnostics will be emitted:
  /// ```
  /// <location> error: overlapping bit ranges in '@BitField(bits: 0..<24, 8..<40, 16..<48, 36..<44)'
  /// @BitField(bits: 0..<24, 8..<40, 16..<48, 36..<44)
  ///  ^~~~~~~~
  ///
  /// <location> note: bit range '0..<24' overlaps bit ranges '8..<32' and '16..<48' over subrange '8..<24'
  /// @BitField(bits: 0..<24, 8..<40, 16..<48, 36..<44)
  ///                 ^~~~~~
  ///
  /// <location> note: bit range '8..<32' overlaps bit ranges '0..<24' and '16..<48'
  /// @BitField(bits: 0..<24, 8..<32, 16..<48, 36..<44)
  ///                         ^~~~~~
  ///
  /// <location> note: bit range '16..<48' overlaps bit ranges '0..<24', '8..<32', and '36..<44' over subranges '16..<32' and '36..<44'
  /// @BitField(bits: 0..<24, 8..<40, 16..<48, 36..<44)
  ///                                 ^~~~~~~
  ///
  /// <location> note: bit range '36..<44' overlaps bit range '16..<48'
  /// @BitField(bits: 0..<24, 8..<40, 16..<48, 36..<44)
  ///                                          ^~~~~~~
  /// ```
  func validateOverlappingRanges(
    in context: MacroContext<some ParsableMacro, some MacroExpansionContext>
  ) {
    // Create indirect references to our bit ranges using their indices and sort
    // the bit ranges by lower bound then by upper bound.
    let indices = self.bitRanges
      .indices
      .sorted { self.bitRanges[$0] < self.bitRanges[$1] }
    // Walk the bit ranges searching for overlapping ranges.
    var overlap = false
    var previousUpperBound: Int? = nil
    for index in indices {
      // If any overlaps are found, exit early from the loop so we can start a
      // new (slower) walk to emit proper diagnostics.
      let bitRange = self.bitRanges[index]
      if let previousUpperBound = previousUpperBound,
        bitRange.canonicalizedLowerBound < previousUpperBound
      {
        overlap = true
        break
      }
      previousUpperBound = bitRange.canonicalizedUpperBound
    }

    // If no overlaps are found, exit early from the function.
    guard overlap else { return }

    // Perform a worst case O(n^2) walk to find the overlap for each bit range,
    // collecting them into notes.
    var notes: [Note] = []
    var candidateIndirectStartIndex = indices.startIndex
    for targetIndirectIndex in indices.indices {
      // Get the target pair index: **bitRange -> *bitRange
      let targetIndex = indices[targetIndirectIndex]
      // Get the target pair: *bitRange -> (bitRange, expression)
      let targetRange = self.bitRanges[targetIndex]
      let targetRangeExpression = self.bitRangeExpressions[targetIndex]

      // Keep track of the overlapping bit subranges and source expressions for
      // the target bit range.
      var overlappingRanges: [Range<Int>] = []
      var overlappingExpressions: [ExprSyntax] = []

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
      let nextTargetIndirectIndex = indices.index(after: targetIndirectIndex)
      let nextTargetRangeLowerBound: Int?
      if nextTargetIndirectIndex < indices.endIndex {
        let nextTargetIndex = indices[nextTargetIndirectIndex]
        let nextTargetRange = self.bitRanges[nextTargetIndex]
        nextTargetRangeLowerBound = nextTargetRange.canonicalizedLowerBound
      } else {
        nextTargetRangeLowerBound = nil
      }

      // Exit early if there are no possible candidate matches for the target
      // range.
      guard candidateIndirectStartIndex < indices.endIndex else { break }

      // Iterate through the candidates looking for overlapping ranges.
      for candidateIndirectIndex
        in candidateIndirectStartIndex..<indices.endIndex
      {
        // Skip comparing a bit range to itself.
        guard targetIndirectIndex != candidateIndirectIndex else { continue }

        // Get the candidate pair index: **bitRange -> *bitRange
        let candidateIndex = indices[candidateIndirectIndex]
        // Get the candidate pair: *bitRange -> (bitRange, expression)
        let candidateRange = self.bitRanges[candidateIndex]
        let candidateRangeExpression = self.bitRangeExpressions[candidateIndex]

        // If the current candidate's upper bound is less than the next target's
        // lower bound, then it cannot overlap with the next target and the
        // candidate search for the next target should start after the current
        // candidate.
        if let nextTargetRangeLowerBound = nextTargetRangeLowerBound,
          candidateRange.canonicalizedUpperBound < nextTargetRangeLowerBound
        {
          candidateIndirectStartIndex =
            indices
            .index(after: candidateIndirectIndex)
        }

        // Exit early if the candidate lower bound is larger than the target
        // upper bound. This is ok because `indices` is sorted, no following
        // candidates will overlap the target.
        guard
          let overlappingRange =
            targetRange.rangeOverlapping(candidateRange)
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

        overlappingExpressions.append(candidateRangeExpression)
      }

      if !overlappingRanges.isEmpty {
        precondition(!overlappingExpressions.isEmpty)
        notes.append(
          .bitFieldOverlappingBitRanges(
            bitRange: Range(targetRange.canonicalizedClosedRange),
            bitRangeExpression: targetRangeExpression,
            overlappingRanges: overlappingRanges,
            overlappingExpressions:
              overlappingExpressions
              .map { "\($0.trimmed)" }))
      }
    }

    _ = context.error(
      at: self.attribute.attributeName,
      message: .bitFieldOverlappingBitRanges(
        attribute: "\(self.attribute.trimmed)"),
      notes: notes,
      fixIts: [])
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
}
