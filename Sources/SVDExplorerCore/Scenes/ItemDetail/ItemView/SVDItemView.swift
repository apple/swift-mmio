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
import SwiftUI

struct SVDItemView: View {
  @Environment(\.openWindow) var openWindow
  @State var keyPath: SVDKeyPath
  @State var item: SVDItem

  var body: some View {
    VStack(alignment: .leading) {
      Group {
        switch self.item {
        case .device(let device):
          SVDDeviceItemView(device: device)
        case .peripheral(let peripheral):
          SVDPeripheralItemView(peripheral: peripheral)
        case .cluster(let cluster):
          SVDClusterItemView(cluster: cluster)
        case .register(let register):
          SVDRegisterItemView(register: register)
        case .field(let field):
          SVDFieldItemView(field: field)
        }
      }
      .padding(8)
      Spacer()
    }.frame(minHeight: 100)
  }
}
