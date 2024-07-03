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

import SVD

enum SVDItem {
  case device(SVDDevice)
  case peripheral(SVDPeripheral)
  case cluster(SVDCluster)
  case register(SVDRegister)
  case field(SVDField)
}

extension SVDItem {
  var kind: SVDItemKind {
    switch self {
    case .device: .device
    case .peripheral: .peripheral
    case .cluster: .cluster
    case .register: .register
    case .field: .field
    }
  }
}
