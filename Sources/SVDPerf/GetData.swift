//
//  Run.swift
//  swift-mmio
//
//  Created by Rauhul Varma on 6/10/25.
//

public import Foundation

public func getData() -> Data {
  try! Data(contentsOf: Bundle.module.url(forResource: "MIMXRT1062", withExtension: "svd")!)
}
