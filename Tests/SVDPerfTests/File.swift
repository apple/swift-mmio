//
//  File.swift
//  swift-mmio
//
//  Created by Rauhul Varma on 6/10/25.
//

import Testing
import SVD
import SVDPerf

@Test
func go() throws {
  let device = try SVDDevice(data: getData())
  print(device.name)
}
