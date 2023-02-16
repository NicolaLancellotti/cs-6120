import CFG
import Common
import IR

public enum Dominators: DataFlowAnalysis {

  public typealias Domain = Set<Block>

  public static func run(
    on function: BrilFunction,
    analysis: Analysis
  ) -> DataFlowData<Domain> {
    let parameters = DominatorsParameters(blocks: analysis.cfg.blocks)
    return DataFlowAnalysisFramework.run(
      cfg: analysis.cfg,
      parameters: parameters)
  }
}

private struct DominatorsParameters: Parameters {

  typealias Domain = Dominators.Domain

  private var blocks: [Block]

  init(blocks: [Block]) {
    self.blocks = blocks
  }

  var forward: Bool { true }

  var iterateInDFSOrder: Bool { true }

  var boundaryValue: Domain { .init() }

  var initialValue: Domain { .init(blocks) }

  func meet(_ values: [Domain]) -> Domain { setIntersection(values) }

  func transferFunction(
    block: Block,
    value: Dominators.Domain
  ) -> Dominators.Domain {
    value.union([block])
  }

  static func text(_ value: Dominators.Domain) -> String {
    String(value.map(\.label).sorted().joined(separator: ", "))
  }
}
