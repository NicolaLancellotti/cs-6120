import IR
import Passes
import TestUtility
import XCTest

final class LVNTests: XCTestCase {
  func test_lvn_basic() throws {
    try testPasses(
      bundle: .module,
      input: "lvn",
      output: "lvn-output",
      passes: [LVNPass()])
  }

  func test_lvn_copyPropagation() throws {
    try testPasses(
      bundle: .module,
      input: "lvn-copy-propagation",
      output: "lvn-copy-propagation-output",
      passes: [LVNPass(config: .init(copyPropagation: true))])
  }

  func test_lvn_constantPropagation() throws {
    try testPasses(
      bundle: .module,
      input: "lvn-constant-propagation",
      output: "lvn-constant-propagation-output",
      passes: [
        LVNPass(
          config: .init(
            copyPropagation: true,
            constantPropagation: true))
      ])
  }

  func test_lvn_constantFolding() throws {
    try testPasses(
      bundle: .module,
      input: "lvn-constant-folding",
      output: "lvn-constant-folding-output",
      passes: [LVNPass(config: .init(constantFolding: true)), DCEPass()])
  }

  func test_lvn_cse() throws {
    try testPasses(
      bundle: .module,
      input: "lvn-cse",
      output: "lvn-cse-output",
      passes: [LVNPass(), DCEPass()])
  }

  func test_lvn_cseCommutativity() throws {
    try testPasses(
      bundle: .module,
      input: "lvn-cse-commutativity",
      output: "lvn-cse-commutativity-output",
      passes: [LVNPass(config: .init(canonicalise: true)), DCEPass()])
  }

  func test_lvn_rewriteVariables() throws {
    try testPasses(
      bundle: .module,
      input: "lvn-rewrite-variables",
      output: "lvn-rewrite-variables-output",
      passes: [LVNPass(config: .init(tryMakeID: true))])
  }

  func test_lvn_idChain() throws {
    try testPasses(
      bundle: .module,
      input: "lvn-id-chain",
      output: "lvn-id-chain-output",
      passes: [
        LVNPass(
          config: .init(
            copyPropagation: true,
            constantPropagation: true))
      ])
  }
}
