import CFG
import IR
import XCTest

final class CFGTests: XCTestCase {
  func test_cfg_makeGraphviz() throws {
    let url = Bundle.module.url(forResource: "cfg-program", withExtension: "json")!
    let data = try Data(contentsOf: url)
    let program = try BrilProgram(data: data)
    let cfg = CFG(function: program.functions.first!)
    let result = cfg.makeGraphviz()
    let expected = """
      digraph main {
          b1;
          b2;
          somewhere;
          b1 -> somewhere
          b2 -> somewhere
      }

      """
    XCTAssertEqual(result, expected)
  }
}
