import IR
import XCTest

final class BrilTests: XCTestCase {
  func test_bril_decodeEncode() throws {
    let program1 = try {
      let url = Bundle.module.url(forResource: "ir-program", withExtension: "json")!
      let data = try Data(contentsOf: url)
      return try BrilProgram(data: data)
    }()

    let program2 = try {
      let data = try program1.data()
      return try BrilProgram(data: data)
    }()

    XCTAssertEqual(program1, program2)
  }
}
