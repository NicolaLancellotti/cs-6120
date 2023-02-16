import CFG
import Common
import IR

public enum DefinedVariables: DataFlowAnalysis {

  public typealias Domain = Set<Variable>

  public static func run(
    on function: BrilFunction,
    analysis: Analysis
  ) -> DataFlowData<Domain> {
    DataFlowAnalysisFramework.run(
      cfg: analysis.cfg,
      parameters: DefinedVariablesParameters())
  }
}

private struct DefinedVariablesParameters {

  private var _gen = [Block: [Variable]]()

  mutating func gen(_ block: Block) -> [Variable] {
    if let value = _gen[block] {
      return value
    }
    _gen[block] = block.instructions.lazy.compactMap(\.instructionDestination)
    return gen(block)
  }

}

extension DefinedVariablesParameters: Parameters {

  typealias Domain = DefinedVariables.Domain

  var forward: Bool { true }

  var boundaryValue: Domain { .init() }

  var initialValue: Domain { .init() }

  func meet(_ values: [Domain]) -> Domain { setUnion(values) }

  // Transfer function:
  // f_d(x) = gen_d U x

  // Transfer function for block:
  // f_B(x) = gen_B U x

  // where
  // gen_B = gen_1 U ... U gen_n
  mutating func transferFunction(
    block: Block,
    value: DefinedVariables.Domain
  ) -> DefinedVariables.Domain {
    value.union(gen(block))
  }

  static func text(_ value: DefinedVariables.Domain) -> String {
    value.isEmpty ? "∅" : String(value.sorted().joined(separator: ", "))
  }
}
