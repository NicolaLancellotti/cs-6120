import IR
import Passes
import TestUtility
import XCTest

final class DCETests: XCTestCase {
  func test_dce_1() throws {
    try testPasses(
      bundle: .module,
      input: "dce-program",
      output: "dce-output",
      passes: [DCEPass()])
  }

  func test_dce_2() throws {
    try testPasses(
      bundle: .module,
      input: "dce-diamond",
      output: "dce-diamond",
      passes: [DCEPass()])
  }
}
