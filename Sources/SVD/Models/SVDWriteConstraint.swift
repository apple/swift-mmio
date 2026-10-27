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

public import XML

/// Define constraints for writing values to a field.
///
/// You can choose between three options, which are mutually exclusive.
public enum SVDWriteConstraint {
  /// If true, only the last read value can be written.
  case writeAsRead(SVDWriteConstraintWriteAsRead)
  /// If true, only the values listed in the enumeratedValues list can be
  /// written.
  case useEnumeratedValues(Bool)
  /// Contains the following two elements:
  /// - minimum: Specify the smallest number to be written to the field.
  /// - maximum: Specify the largest number to be written to the field.
  case range(SVDWriteConstraintRange)
}

extension SVDWriteConstraint: Decodable {}

extension SVDWriteConstraint: Encodable {}

extension SVDWriteConstraint: Equatable {}

extension SVDWriteConstraint: Hashable {}

extension SVDWriteConstraint: Sendable {}

extension SVDWriteConstraint: XMLElementDecodable {
  /// Decodes each form of write constraint from the same element, and uses
  /// the first form that decodes.
  public struct XMLBuilder: XMLElementBuilder {
    var writeAsRead = SVDWriteConstraintWriteAsRead.XMLBuilder()
    var useEnumeratedValues = XMLSlot<Bool>()
    var range = XMLSlot<SVDWriteConstraintRange>()

    public init() {}

    public mutating func attribute(_ name: XMLName, _ value: XMLText) {}

    public static func child(
      _ name: XMLName,
      of builder: XMLBuilderPointer<Self>
    ) -> XMLFrame? {
      switch name {
      case "useEnumeratedValues": builder.decode(\.useEnumeratedValues)
      case "range": builder.decode(\.range)
      default:
        SVDWriteConstraintWriteAsRead.XMLBuilder.child(
          name, of: builder.member(\.writeAsRead))
      }
    }

    public mutating func build() throws(XMLBuildError) -> SVDWriteConstraint {
      if let value = try? self.writeAsRead.build() {
        .writeAsRead(value)
      } else if let value = try? self.useEnumeratedValues.required(
        "useEnumeratedValues")
      {
        .useEnumeratedValues(value)
      } else if let value = try? self.range.required("range") {
        .range(value)
      } else {
        throw .failure(XMLError.unknownElement("write constraint"))
      }
    }
  }
}
