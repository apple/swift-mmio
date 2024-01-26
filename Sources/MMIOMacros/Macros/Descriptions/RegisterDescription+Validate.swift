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
import SwiftSyntaxMacros
import SwiftSyntaxMacroExpansion

extension RegisterDescription {
  func validate(
    in context: MacroContext<some ParsableMacro, some MacroExpansionContext>
  ) {
    // Validate bit range in each bit field.
    for bitField in self.bitFields {
      bitField.validate(in: context)
    }

    // FIXME: Validate bit range overlap across bit fields.
  }
//
//  /// Walk the bit ranges forming error diagnostics for overlapping of ranges.
//  ///
//  /// Given the example bit fields:
//  /// ```
//  /// @BitField(bits: 0..<24, 36..<44)
//  /// var field0: Field1
//  ///
//  /// @BitField(bits: 8..<32)
//  /// var field1: Field1
//  ///
//  /// @BitField(bits: 16..<48)
//  /// var field2: Field2
//  /// ```
//  ///
//  /// The ranges visually look like:
//  /// ```
//  ///         0       8       16      24      32  36      44  48
//  ///         ╎       ╎       ╎       ╎       ╎   ╎       ╎   ╎
//  /// field0: •───────────────────────◦       ╎   ╎       ╎   ╎
//  /// field1: ╎       •───────────────────────◦   ╎       ╎   ╎
//  /// field2: ╎       ╎       •───────────────────────────────◦
//  /// field0: ╎       ╎       ╎       ╎       ╎   •───────◦   ╎
//  ///         ╎       ╎       ╎       ╎       ╎   ╎       ╎   ╎
//  ///         0       8       16      24      32  36      44  48
//  /// ```
//  ///
//  /// The following diagnostics will be emitted:
//  /// ```
//  /// <location> error: bit field 'field0' references bit ranges \
//  /// '0..<24', '8..<40', '16..<48', and '36..<44'
//  /// var field0: Field0
//  ///     ^~~~~
//  ///
//  /// <location> note: bit subrange '8..<24' of bit range '0..<24' overlaps \
//  /// bit ranges '8..<32' and '16..<48'
//  /// @BitField(bits: 0..<24, 8..<40, 16..<48, 36..<44)
//  ///                 ^~~~~~
//  ///
//  /// <location> note: bit subrange '8..<32' of bit range '8..<32' overlaps \
//  /// bit ranges '0..<24' and '16..<48'
//  /// @BitField(bits: 0..<24, 8..<32, 16..<48, 36..<44)
//  ///                         ^~~~~~
//  ///
//  /// <location> note: bit subranges '16..<32' and '36..<44' of bit range \
//  /// '16..<48' overlap bit ranges '0..<24', '8..<32', and '36..<44'
//  /// @BitField(bits: 0..<24, 8..<40, 16..<48, 36..<44)
//  ///                                 ^~~~~~~
//  ///
//  /// <location> note: bit subrange '36..<44' of bit range '36..<44' overlaps \
//  /// bit range '16..<48'
//  /// @BitField(bits: 0..<24, 8..<40, 16..<48, 36..<44)
//  ///                                          ^~~~~~~
//  /// ```
//  func validateOverlappingRanges(
//    in context: MacroContext<some ParsableMacro, some MacroExpansionContext>
//  ) {
//    // Create indirect references to our bit ranges using their indices and sort
//    // the bit ranges by lower bound then by upper bound.
//    let indices = self.bitRanges
//      .indices
//      .sorted { self.bitRanges[$0] < self.bitRanges[$1] }
//    // Walk the bit ranges searching for overlapping ranges.
//    var overlap = false
//    var previousUpperBound: Int? = nil
//    for index in indices {
//      // If any overlaps are found, exit early from the loop so we can start a
//      // new (slower) walk to emit proper diagnostics.
//      let bitRange = self.bitRanges[index]
//      if let previousUpperBound = previousUpperBound,
//         bitRange.canonicalizedLowerBound < previousUpperBound {
//        overlap = true
//        break
//      }
//      previousUpperBound = bitRange.canonicalizedUpperBound
//    }
//
//    // If no overlaps are found, exit early from the function.
//    guard overlap else { return }
//
//    // Perform a worst case O(n^2) walk to find the overlap for each bit range,
//    // collecting them into notes.
//    var notes = [Note]()
//    var candidateIndirectStartIndex = indices.startIndex
//    for targetIndirectIndex in indices.indices {
//      // Get the target pair index: **bitRange -> *bitRange
//      let targetIndex = indices[targetIndirectIndex]
//      // Get the target pair: *bitRange -> (bitRange, expression)
//      let targetRange = self.bitRanges[targetIndex]
//      let targetRangeExpression = self.bitRangeExpressions[targetIndex]
//
//      // Keep track of the overlapping bit subranges and source expressions for
//      // the target bit range.
//      var overlappingRanges = [Range<Int>]()
//      var overlappingExpressions = [ExprSyntax]()
//
//      // Determine the index where the candidate overlap search should start
//      // from. We do this by getting the bounds of the next target range and
//      // keeping track of the first candidate range which could overlap with it.
//      // This allows us to skip comparing against earlier candidate ranges which
//      // we already know fall out of lower bounds.
//      //
//      //    0   4   8   12  16  20  24  28
//      //    ╎   ╎   ╎   ╎   ╎   ╎   ╎   ╎
//      // 0: •───────────────◦   ╎   ╎   ╎ // Candidates start at 0
//      // 1: ╎   •───◦   ╎   ╎   ╎   ╎   ╎ // Candidates start at 0
//      // 2: ╎   ╎   ╎   •───────────◦   ╎ // Candidates start at 0
//      // 3: ╎   ╎   ╎   ╎   ╎   •───────◦ // Candidates start at 2
//      //    ╎   ╎   ╎   ╎   ╎   ╎   ╎   ╎
//      //    0   4   8   12  16  20  24  28
//      //
//      // Get the index of the next target range and its lower bound.
//      let nextTargetIndirectIndex = indices.index(after: targetIndirectIndex)
//      let nextTargetRangeLowerBound: Int?
//      if nextTargetIndirectIndex < indices.endIndex {
//        let nextTargetIndex = indices[nextTargetIndirectIndex]
//        let nextTargetRange = self.bitRanges[nextTargetIndex]
//        nextTargetRangeLowerBound = nextTargetRange.canonicalizedLowerBound
//      } else {
//        nextTargetRangeLowerBound = nil
//      }
//
//      // Exit early if there are no possible candidate matches for the target
//      // range.
//      guard candidateIndirectStartIndex < indices.endIndex else { break }
//
//      // Iterate through the candidates looking for overlapping ranges.
//      for candidateIndirectIndex in candidateIndirectStartIndex..<indices.endIndex {
//        // Skip comparing a bit range to itself.
//        guard targetIndirectIndex != candidateIndirectIndex else { continue }
//
//        // Get the candidate pair index: **bitRange -> *bitRange
//        let candidateIndex = indices[candidateIndirectIndex]
//        // Get the candidate pair: *bitRange -> (bitRange, expression)
//        let candidateRange = self.bitRanges[candidateIndex]
//        let candidateRangeExpression = self.bitRangeExpressions[candidateIndex]
//
//        // If the current candidate's upper bound is less than the next target's
//        // lower bound, then it cannot overlap with the next target and the
//        // candidate search for the next target should start after the current
//        // candidate.
//        if let nextTargetRangeLowerBound = nextTargetRangeLowerBound,
//           candidateRange.canonicalizedUpperBound < nextTargetRangeLowerBound {
//          candidateIndirectStartIndex = indices
//            .index(after: candidateIndirectIndex)
//        }
//
//        // Exit early if the candidate lower bound is larger than the target
//        // upper bound. This is ok because `indices` is sorted, no following
//        // candidates will overlap the target.
//        guard let overlappingRange =
//          targetRange.rangeOverlapping(candidateRange) else {
//          break
//        }
//
//        // Attempt to merge the overlapping range into the previous overlapping
//        // range to form larger continuous overlapping ranges.
//        if let previousOverlappingRange = overlappingRanges.last,
//           overlappingRange.lowerBound <= previousOverlappingRange.upperBound {
//          overlappingRanges.removeLast()
//          overlappingRanges.append(previousOverlappingRange.lowerBound..<overlappingRange.upperBound)
//        } else {
//          overlappingRanges.append(overlappingRange)
//        }
//
//        overlappingExpressions.append(candidateRangeExpression)
//      }
//
//      if !overlappingRanges.isEmpty {
//        precondition(!overlappingExpressions.isEmpty)
//        notes.append(.bitFieldOverlappingBitRanges(
//          bitRange: targetRangeExpression,
//          overlappingRanges: overlappingRanges,
//          overlappingExpressions: overlappingExpressions
//            .map { "\($0.trimmed)" }))
//      }
//    }
//
//    _ = context.error(
//      at: self.fieldName,
//      message: .bitFieldOverlappingBitRanges(
//        fieldName: "\(self.fieldName.trimmed)",
//        overlappingRangeExpressions: self.bitRangeExpressions
//          .map { "\($0.trimmed)" }),
//      notes: notes,
//      fixIts: [])
//  }
}

//extension ErrorDiagnostic {
//  static func bitFieldOutOfRange(
//    fieldName: String,
//    bitRange: String,
//    bitWidth: Int
//  ) -> Self {
//    .init(
//      """
//      bit field '\(fieldName)' references bit range '\(bitRange)' which falls \
//      outside of the bit range '0..<\(bitWidth)' of the enclosing register
//      """)
//  }
//
//  static func bitFieldOverlappingBitRanges(
//    fieldName: String,
//    overlappingRangeExpressions: [String]
//  ) -> Self {
//    precondition(overlappingRangeExpressions.count > 1)
//    return .init(
//      """
//      bit field '\(fieldName)' references overlapping bit ranges \
//      \(list: overlappingRangeExpressions, separator: ",", conjunction: "and")
//      """)
//  }
//}
//
//extension Note {
//  static func bitFieldOverlappingBitRanges(
//    bitRange: ExprSyntax,
//    overlappingRanges: [Range<Int>],
//    overlappingExpressions: [ExprSyntax]
//  ) -> Note {
//    let pluralizeSubranges = overlappingRanges.count != 1
//    let pluralizeRanges = overlappingExpressions.count != 1
//    return .init(
//      node: Syntax(bitRange),
//      message: MacroExpansionNoteMessage(
//        """
//        bit subrange\(pluralizeSubranges ? "s" : "") \
//        \(list: overlappingRanges, separator: ",", conjunction: "and") of bit \
//        range '\(bitRange.trimmed)' overlap\(pluralizeSubranges ? "" : "s") \
//        bit range\(pluralizeRanges ? "s" : "") \
//        \(list: overlappingExpressions, separator: ",", conjunction: "and")
//        """
//      ))
//  }
//}
//
