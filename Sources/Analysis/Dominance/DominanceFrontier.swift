import CFG
import Common
import IR

// A’s dominance frontier contains B iff A does not strictly dominate B,
// and A does dominate some predecessor of B.
public enum DominanceFrontier: DominanceAnalysis {

  public static func run(
    on function: BrilFunction,
    analysis: Analysis
  ) -> [Label: Set<Block>] {
    let cfg = analysis.cfg
    let dominators = analysis.dominators
    let dominanceTree = analysis.dominanceTree
    let initalFrontier = dominators.keys.lazy.map { ($0, Set<Block>()) }
    var frontier = Dictionary(uniqueKeysWithValues: initalFrontier)

    let iDomSequence = dominanceTree.lazy.map { parent, children in
      children.map { child in (child, cfg[parent]) }
    }.joined()
    let iDom = Dictionary(uniqueKeysWithValues: iDomSequence)

    for block in cfg.blocks where block == cfg.entry || block.predecessors.count > 1 {
      for predecessor in block.predecessors {
        for predecessor in sequence(first: predecessor, next: { iDom[$0] })
          .lazy
          .prefix(while: { $0 != iDom[block] })
        {
          frontier[defaulting: predecessor.label].insert(block)
        }
      }
    }
    return frontier
  }
}
