import Analysis
import CFG
import IR
import TestUtility
import XCTest

final class DataFlowTests: XCTestCase {
  func test_dataFlow_reachingDefinitions() throws {
    let program = try loadProgram(withName: "program", from: .module)
    let function = program.functions[0]
    let analysis = Analysis(function: function)
    let result = ReachingDefinitions.run(
      on: function,
      analysis: analysis)
    let expected = """
      b1:
        in:  [arg.cond]
        out: [b1.a, b1.b, arg.cond]
      left:
        in:  [b1.a, b1.b, arg.cond]
        out: [b1.a, left.b, left.c, arg.cond]
      right:
        in:  [b1.a, b1.b, arg.cond]
        out: [right.a, b1.b, right.c, arg.cond]
      end:
        in:  [b1.a, right.a, b1.b, left.b, left.c, right.c, arg.cond]
        out: [b1.a, right.a, b1.b, left.b, left.c, right.c, arg.cond, end.d]

      """
    XCTAssertEqual(result.text(), expected)
  }

  func test_dataFlow_liveVariables() throws {
    let program = try loadProgram(withName: "program", from: .module)
    let function = program.functions[0]
    let analysis = Analysis(function: function)
    let result = LiveVariables.run(on: function, analysis: analysis)
    let expected = """
      b1:
        in:  cond
        out: a
      left:
        in:  a
        out: a, c
      right:
        in:  ∅
        out: a, c
      end:
        in:  a, c
        out: ∅

      """
    XCTAssertEqual(result.text(), expected)
  }

  func test_dataFlow_constantPropagation() throws {
    let program = try loadProgram(withName: "fact", from: .module)
    let function = program.functions[0]
    let analysis = Analysis(function: function)
    let result = ConstantPropagation.run(
      on: function,
      analysis: analysis)
    let expected = """
      b1:
        in:  ∅
        out: i: 8, result: 1
      header:
        in:  cond: ?, i: ?, one: 1, result: ?, zero: 0
        out: cond: ?, i: ?, one: 1, result: ?, zero: 0
      body:
        in:  cond: ?, i: ?, one: 1, result: ?, zero: 0
        out: cond: ?, i: ?, one: 1, result: ?, zero: 0
      end:
        in:  cond: ?, i: ?, one: 1, result: ?, zero: 0
        out: cond: ?, i: ?, one: 1, result: ?, zero: 0

      """
    XCTAssertEqual(result.text(), expected)
  }
}
