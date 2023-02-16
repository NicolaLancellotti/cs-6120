import CFG
import Common
import IR

public protocol DominanceAnalysis {
  static func run(
    on function: BrilFunction,
    analysis: Analysis
  ) -> [Label: Set<Block>]
}
