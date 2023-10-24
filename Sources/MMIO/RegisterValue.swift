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

public protocol RegisterValue {
  associatedtype Raw: RegisterValueRaw where Raw.Layout == Self
  associatedtype Read: RegisterValueRead where Read.Layout == Self
  associatedtype Write: RegisterValueWrite where Write.Layout == Self
}

public protocol RegisterValueRaw {
  associatedtype Layout: RegisterValue where Layout.Raw == Self
  associatedtype Storage: FixedWidthInteger & UnsignedInteger & _RegisterStorage
  var storage: Storage { get set }
  init(_ storage: Storage)
  init(_ value: Layout.Read)
  init(_ value: Layout.Write)
}

public protocol RegisterValueRead {
  associatedtype Layout: RegisterValue where Layout.Read == Self
  init(_ value: Layout.Raw)
}

extension RegisterValueRead {
  /// Yields a view of the data underlying the read view, allowing for direct
  /// manipulation of the register's bits.
  ///
  /// Mutation through the raw view are unchecked. The user is responsible for
  /// ensuring the bit pattern is valid.
  public var raw: Layout.Raw {
    _read {
      yield Layout.Raw(self)
    }
    _modify {
      var raw = Layout.Raw(self)
      yield &raw
      self = Self(raw)
    }
  }
}

public protocol RegisterValueWrite {
  associatedtype Layout: RegisterValue where Layout.Write == Self
  init(_ value: Layout.Raw)
  init(_ read: Layout.Read)
}

extension RegisterValueWrite {
  /// Yields a view of the data underlying the read view, allowing for direct
  /// manipulation of the register's bits.
  ///
  /// Mutation through the raw view are unchecked. The user is responsible for
  /// ensuring the bit pattern is valid.
  public var raw: Layout.Raw {
    _read {
      yield Layout.Raw(self)
    }
    _modify {
      var raw = Layout.Raw(self)
      yield &raw
      self = Self(raw)
    }
  }
}
