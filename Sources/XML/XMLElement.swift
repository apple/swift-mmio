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

public import MMIOUtilities

public struct XMLElement: ~Copyable {
  public var name: String
  public var attributes: OwnedArray<(String, String)>
  public var value: String?
  public var children: OwnedArray<XMLElement>
}

extension XMLElement {
  public var description: String {
    self.formattedDescription(indent: "")
  }

  func formattedDescription(indent: String) -> String {
    let nextIndent = indent + "  "
    var result = "\(indent){\n"
    result += "\(nextIndent)name: \"\(name)\",\n"

    if let value = self.value {
      result += "\(nextIndent)value: \"\(value)\",\n"
    }

    if !self.attributes.isEmpty {
      result += "\(nextIndent)attributes: {\n"
      for index in self.attributes.indices {
        let (key, value) = self.attributes[index]
        result += "\(nextIndent)  \"\(key)\": \"\(value)\",\n"
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
  public func decode<T>(
    _: T.Type = T.self
  ) throws -> T where T: XMLElementInitializable {
    try self
      .decode(T?.self)
      .unwrap()
  }

  public func decode<T>(
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
  public func decode<T>(
    _: T.Type = T.self,
    fromChild name: String
  ) throws -> T where T: XMLElementInitializable {
    try self
      .decode(T?.self, fromChild: name)
      .unwrap(or: XMLError.missingValue(name: name))
  }

  public func decode<T>(
    _: T?.Type = T?.self,
    fromChild name: String
  ) throws -> T? where T: XMLElementInitializable {
    for index in self.children.indices {
      guard self.children[index].name == name else { continue }
      return try T(self.children[index])
    }
    return nil
  }

  public func decode<T>(
    _: [T].Type = [T].self,
    fromChild name: String
  ) throws -> [T] where T: XMLElementInitializable {
    try self
      .decode([T]?.self, fromChild: name)
      .unwrap(or: XMLError.missingValue(name: name))
  }

  public func decode<T>(
    _: [T]?.Type = [T]?.self,
    fromChild name: String
  ) throws -> [T]? where T: XMLElementInitializable {
    var values: [T] = []
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
  public func decode<T>(
    _: T.Type = T.self,
    fromAttribute name: String
  ) throws -> T where T: XMLElementInitializable {
    try self
      .decode(T?.self, fromAttribute: name)
      .unwrap(or: XMLError.missingValue(name: name))
  }

  public func decode<T>(
    _: T?.Type = T?.self,
    fromAttribute name: String
  ) throws -> T? where T: XMLElementInitializable {
    for index in self.attributes.indices {
      let (key, value) = self.attributes[index]
      guard key == name else { continue }
      let element = XMLElement(
        name: "", attributes: OwnedArray(), value: value, children: OwnedArray()
      )
      return try T(element)
    }
    return nil
  }
}
