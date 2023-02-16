import CFG
import Common
import IR

func findDominators(function: BrilFunction, cfg: CFG) -> [Label: Set<Block>] {
  var visited = Set<Block>()
  var dominators = [Label: Set<Block>]()

  func visit(_ block: Block) {
    guard !visited.contains(block) else { return }
    visited.insert(block)

    dominators[block.label, default: visited].formIntersection(visited)

    block.successors.forEach(visit)
    visited.remove(block)
  }

  visit(cfg.entry)
  return dominators
}
