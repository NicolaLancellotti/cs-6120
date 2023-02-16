import Analysis
import CFG
import Common
import IR
import Serialize
import TestUtility
import XCTest

final class DominatorsTests: XCTestCase {
  func test_dominators_dominators1() throws {
    let program = try loadProgram(withName: "loopcond+unreachable", from: .module)
    let function = program.functions[0]
    let analysis = Analysis(function: function)
    let dominators = Dominators.run(
      on: function,
      analysis: analysis
    ).dictionary()
    let result = Serialize.makeJSON(dominators)
    let expected = """
      {
        "body" : [
          "body",
          "entry",
          "loop"
        ],
        "endif" : [
          "body",
          "endif",
          "entry",
          "loop"
        ],
        "entry" : [
          "entry"
        ],
        "exit" : [
          "entry",
          "exit",
          "loop"
        ],
        "loop" : [
          "entry",
          "loop"
        ],
        "then" : [
          "body",
          "entry",
          "loop",
          "then"
        ]
      }
      """
    XCTAssertEqual(result, expected)
  }

  func test_dominators_dominators2() throws {
    for input in ["loopcond+unreachable", "while", "loopcond"] {
      let program = try loadProgram(withName: input, from: .module)
      let function = program.functions[0]
      let analysis = Analysis(function: function)
      let result = Dominators.run(
        on: function,
        analysis: analysis
      ).dictionary()
      let expected = findDominators(function: function, cfg: analysis.cfg)
      XCTAssertEqual(result, expected)
    }
  }

  func test_dominators_dominanceTree() throws {
    let program = try loadProgram(withName: "loopcond+unreachable", from: .module)
    let function = program.functions[0]
    let analysis = Analysis(function: function)
    let dominanceTree = DominanceTree.run(
      on: function,
      analysis: analysis)
    let result = Serialize.makeJSON(dominanceTree)
    let expected = """
      {
        "body" : [
          "endif",
          "then"
        ],
        "endif" : [

        ],
        "entry" : [
          "loop"
        ],
        "exit" : [

        ],
        "loop" : [
          "body",
          "exit"
        ],
        "then" : [

        ]
      }
      """
    XCTAssertEqual(result, expected)
  }

  func test_dominators_dominanceFrontier1() throws {
    let program = try loadProgram(withName: "loopcond+unreachable", from: .module)
    let function = program.functions[0]
    let analysis = Analysis(function: function)
    let dominanceFrontier = DominanceFrontier.run(
      on: function,
      analysis: analysis)
    let result = Serialize.makeJSON(dominanceFrontier)
    let expected = """
      {
        "body" : [
          "loop"
        ],
        "endif" : [
          "loop"
        ],
        "entry" : [

        ],
        "exit" : [

        ],
        "loop" : [
          "loop"
        ],
        "then" : [
          "endif"
        ]
      }
      """
    XCTAssertEqual(result, expected)
  }

  func test_dominators_dominanceFrontier2() throws {
    let program = try loadProgram(withName: "while", from: .module)
    let function = program.functions[0]
    let analysis = Analysis(function: function)
    let dominanceFrontier = DominanceFrontier.run(
      on: function,
      analysis: analysis)
    let result = Serialize.makeJSON(dominanceFrontier)
    let expected = """
      {
        "while.body" : [
          "while.cond"
        ],
        "while.cond" : [
          "while.cond"
        ],
        "while.finish" : [

        ]
      }
      """
    XCTAssertEqual(result, expected)
  }
}
