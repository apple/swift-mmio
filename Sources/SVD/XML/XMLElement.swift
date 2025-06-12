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

struct XMLElement: ~Copyable {
  var name: String
  var attributes: [String: String]
  var value: String?
  var children: OwnedArray<XMLElement>
}

extension XMLElement {
  var description: String {
    self.formattedDescription(indent: "")
  }

  private func formattedDescription(indent: String) -> String {
    let nextIndent = indent + "  "
    var result = "\(indent){\n"
    result += "\(nextIndent)name: \"\(name)\",\n"

    if let value = self.value {
      result += "\(nextIndent)value: \"\(value)\",\n"
    }

    if !self.attributes.isEmpty {
      result += "\(nextIndent)attributes: {\n"
      for (key, val) in self.attributes {
        result += "\(nextIndent)  \"\(key)\": \"\(val)\",\n"
      }
      result += "\(nextIndent)},\n"
    }

    if !self.children.isEmpty {
      result += "\(nextIndent)children: [\n"
      for child in self.children.indices {
        result += self.children[child]
          .formattedDescription(indent: nextIndent + "  ")
        result += ",\n"
      }
      result += "\(nextIndent)]\n"
    }

    result += "\(indent)}"
    return result
  }
}

// Support for @XMLInlineElement
extension XMLElement {
  func decode<T>(
    _: T.Type = T.self
  ) throws -> T where T: XMLElementInitializable {
    try self
      .decode(T?.self)
      .unwrap()
  }

  func decode<T>(
    _: T?.Type = T?.self
  ) throws -> T? where T: XMLElementInitializable {
    do {
      return try T.init(self)
    } catch XMLError.missingValue {
      return nil
    }
  }
}

// Support for @XMLChild
extension XMLElement {
  func decode<T>(
    _: T.Type = T.self,
    fromChild name: String
  ) throws -> T where T: XMLElementInitializable {
    try self
      .decode(T?.self, fromChild: name)
      .unwrap(or: XMLError.missingValue(name: name))
  }

  func decode<T>(
    _: T?.Type = T?.self,
    fromChild name: String
  ) throws -> T? where T: XMLElementInitializable {
    for index in self.children.indices {
      guard self.children[index].name == name else { continue }
      return try T(self.children[index])
    }
    return nil
  }

  func decode<T>(
    _: [T].Type = [T].self,
    fromChild name: String
  ) throws -> [T] where T: XMLElementInitializable {
    try self
      .decode([T]?.self, fromChild: name)
      .unwrap(or: XMLError.missingValue(name: name))
  }

  func decode<T>(
    _: [T]?.Type = [T]?.self,
    fromChild name: String
  ) throws -> [T]? where T: XMLElementInitializable {
    var values = [T]()
    for index in self.children.indices {
      guard self.children[index].name == name else { continue }
      let value = try T(self.children[index])
      values.append(value)
    }
    return values
  }
}

// Support for @XMLAttribute
extension XMLElement {
  func decode<T>(
    _: T.Type = T.self,
    fromAttribute name: String
  ) throws -> T where T: XMLElementInitializable {
    try self
      .decode(T?.self, fromAttribute: name)
      .unwrap(or: XMLError.missingValue(name: name))
  }

  func decode<T>(
    _: T?.Type = T?.self,
    fromAttribute name: String
  ) throws -> T? where T: XMLElementInitializable {
    guard let attribute = self.attributes[name] else { return nil }
    let element = XMLElement(name: "", attributes: [:], value: attribute, children: OwnedArray())
    return try T(element)
  }
}
