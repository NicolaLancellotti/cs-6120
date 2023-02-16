import CFG
import Common
import IR

public enum DominanceTree: DominanceAnalysis {

  public static func run(
    on function: BrilFunction,
    analysis: Analysis
  ) -> [Label: Set<Block>] {
    let cfg = analysis.cfg
    let dominators = analysis.dominators
    // sortedDominators[i].count < sortedDominators[i + 1].count
    let sortedDominators = dominators.sorted { $0.value.count < $1.value.count }

    var tree = [Label: Set<Block>]()
    var hight = [Label: Int]()

    for (label, dominators) in sortedDominators {
      hight[label] = dominators.count
      switch dominators.count {
      case 1:
        tree[label] = []
      default:
        let parent = dominators.lazy.filter { $0.label != label }
          .map { (label: $0, hight: hight[$0.label]!) }
          .max { $0.hight < $1.hight }
          .map(\.label)!
        tree[label] = []
        tree[parent.label]!.insert(cfg[label])
      }
    }

    return tree
  }
}
