import IR
import Passes
import TestUtility
import XCTest

final class SSATests: XCTestCase {
  func test_ssa_toSSA1() throws {
    try testPasses(
      bundle: .module,
      input: "ssa-if",
      output: "ssa-if-output",
      passes: [ToSSA()])
  }

  func test_ssa_toSSA2() throws {
    try testPasses(
      bundle: .module,
      input: "ssa-argwrite-no-ssa",
      output: "ssa-argwrite-ssa",
      passes: [ToSSA()])
  }

  func test_ssa_toSSA3() throws {
    try testPasses(
      bundle: .module,
      input: "ssa-while",
      output: "ssa-while-output",
      passes: [ToSSA()])
  }

  func test_ssa_naiveFromSSA() throws {
    try testPasses(
      bundle: .module,
      input: "ssa-argwrite-ssa",
      output: "ssa-argwrite-no-ssa2",
      passes: [NaiveFromSSA()])
  }
}
