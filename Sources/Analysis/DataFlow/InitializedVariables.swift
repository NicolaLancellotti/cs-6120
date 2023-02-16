import CFG
import Common
import IR

public enum InitializedVariables: DataFlowAnalysis {

  public typealias Domain = Set<Variable>

  public static func run(
    on function: BrilFunction,
    analysis: Analysis
  ) -> DataFlowData<Domain> {
    DataFlowAnalysisFramework.run(
      cfg: analysis.cfg,
      parameters: InitializedVariablesParameters())
  }
}

private struct InitializedVariablesParameters: Parameters {

  typealias Domain = InitializedVariables.Domain

  var forward: Bool { true }

  var boundaryValue: Domain { .init() }

  var initialValue: Domain { .init() }

  func meet(_ values: [Domain]) -> Domain { setIntersection(values) }

  func transferFunction(block: Block, value: Domain) -> Domain {
    var value = value
    for instruction in block.instructions {
      if let dest = instruction.instructionDestination {
        value.update(with: dest)
      }
    }
    return value
  }

  static func text(_ value: Domain) -> String {
    value.isEmpty ? "∅" : String(value.sorted().joined(separator: ", "))
  }
}
