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
  associatedtype Raw: RegisterValueRaw where Raw.Value == Self
  associatedtype Read: RegisterValueRead where Read.Value == Self
  associatedtype Write: RegisterValueWrite where Write.Value == Self
}

public protocol RegisterValueRaw {
  associatedtype Value: RegisterValue where Value.Raw == Self
  associatedtype Storage: FixedWidthInteger & UnsignedInteger & _RegisterStorage
  var storage: Storage { get set }
  init(_ storage: Storage)
  init(_ value: Value.Read)
  init(_ value: Value.Write)
}

public protocol RegisterValueRead {
  associatedtype Value: RegisterValue where Value.Read == Self
  init(_ value: Value.Raw)
}

extension RegisterValueRead {
  // FIXME: Avoid @_disfavoredOverload if possible
  /// Yields a view of the data underlying the read view, allowing for direct
  /// manipulation of the register's bits.
  ///
  /// Mutation through the raw view are unchecked. The user is responsible for
  /// ensuring the bit pattern yielded back to the read view is valid.
  @_disfavoredOverload
  @inlinable @inline(__always)
  public var raw: Value.Raw {
    _read {
      yield Value.Raw(self)
    }
    _modify {
      var raw = Value.Raw(self)
      yield &raw
      self = Self(raw)
    }
  }
}

public protocol RegisterValueWrite {
  associatedtype Value: RegisterValue where Value.Write == Self
  init(_ value: Value.Raw)
  init(_ read: Value.Read)
}

extension RegisterValueWrite {
  /// Yields a view of the data underlying the read view, allowing for direct
  /// manipulation of the register's bits.
  ///
  /// Mutation through the raw view are unchecked. The user is responsible for
  /// ensuring the bit pattern yielded back to the write view is valid.
  @inlinable @inline(__always)
  public var raw: Value.Raw {
    _read {
      yield Value.Raw(self)
    }
    _modify {
      var raw = Value.Raw(self)
      yield &raw
      self = Self(raw)
    }
  }
}
