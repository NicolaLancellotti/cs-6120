import CFG
import Common
import IR

public protocol DataFlowAnalysis<Domain> {
  associatedtype Domain: Default

  static func run(on function: BrilFunction, analysis: Analysis) -> DataFlowData<Domain>
}
