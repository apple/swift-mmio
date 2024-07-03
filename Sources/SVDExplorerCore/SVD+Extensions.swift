//
//  SVD+Extensions.swift
//  SVDExplorer
//
//  Created by Rauhul Varma on 1/30/24.
//

import SVD

extension SVDAccess {
  var displayName: String {
    switch self {
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
    }
  }
}

extension SVDField {
  var accessDisplayName: String {
    self.access?.displayName ?? "Unknown"
  }
}
