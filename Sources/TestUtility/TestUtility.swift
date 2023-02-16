import Foundation
import IR
import Passes
import XCTest

public func loadProgram(withName name: String, from bundle: Bundle) throws -> BrilProgram {
  let url = bundle.url(forResource: name, withExtension: "json")!
  let data = try Data(contentsOf: url)
  return try BrilProgram(data: data)
}

public func testPasses(
  bundle: Bundle, input: String, output: String,
  passes: [any Pass], verbose: Bool = false
) throws {
  let program = try loadProgram(withName: input, from: bundle)
  let passManager = PassManager(passes: passes)
  let result = passManager(program)

  let expected = try {
    let url = bundle.url(forResource: output, withExtension: "json")!
    let data = try Data(contentsOf: url)
    return try BrilProgram(data: data)
  }()

  if verbose {
    print(result.json() ?? "")
  }

  XCTAssertEqual(result, expected)
}
