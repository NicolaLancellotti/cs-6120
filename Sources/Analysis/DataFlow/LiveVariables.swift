import CFG
import Common
import IR

public enum LiveVariables: DataFlowAnalysis {

  public typealias Domain = Set<Variable>

  public static func run(
    on function: BrilFunction,
    analysis: Analysis
  ) -> DataFlowData<Domain> {
    DataFlowAnalysisFramework.run(
      cfg: analysis.cfg,
      parameters: LiveVariablesParameters())
  }
}

private struct LiveVariablesParameters: Parameters {

  typealias Domain = LiveVariables.Domain

  var forward: Bool { false }

  var boundaryValue: Domain { .init() }

  var initialValue: Domain { .init() }

  func meet(_ values: [Domain]) -> Domain { setUnion(values) }

  // Transfer function:
  // f_d(x) = use_d U (x - def_d)
  func transferFunction(block: Block, value: Domain) -> Domain {
    var value = value
    for instruction in block.instructions.reversed() {
      if let destination = instruction.instructionDestination {
        value = value.filter { $0 != destination }  // def
      }
      value.formUnion(instruction.instructionArguments)  // use
    }
    return value
  }

  static func text(_ value: Domain) -> String {
    value.isEmpty ? "∅" : String(value.sorted().joined(separator: ", "))
  }
}
