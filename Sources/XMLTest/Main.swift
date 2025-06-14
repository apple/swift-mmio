import Foundation
import XML

@XMLParsable
struct SVDTest {
//  var name: String
}

@XMLParsable
struct SVDDevice {
  var test: SVDTest
}

@XMLParsable
struct SVDDocument {
  var device: SVDDevice
}

@main
struct XMLTest {
  static func main() throws {
    let file = "/Volumes/Developer/org.swift/swift-mmio/Sources/XMLTest/ARM_Sample.svd"
    let url = URL(fileURLWithPath: file)
    let data = try Data(contentsOf: url)
    let value = try XMLParser.parse(SVDDocument.self, data: data)
    print(value)
  }
}
