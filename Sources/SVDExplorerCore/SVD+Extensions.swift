//
//  SVD+Extensions.swift
//  SVDExplorer
//
//  Created by Rauhul Varma on 1/30/24.
//

import SVD

extension SVDField {
  var accessDisplayName: String {
    switch self.access {
    case .readOnly:
      "Read Only"
    case .writeOnly:
      "Write Only"
    case .readWrite:
      "Read Write"
    case .writeOnce:
      "Write Once"
    case .readWriteOnce:
      "Read Write Once"
    case nil:
      "Unknown"
    }
  }
}
