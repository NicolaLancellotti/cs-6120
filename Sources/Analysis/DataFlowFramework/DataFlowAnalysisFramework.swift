import CFG
import IR

enum DataFlowAnalysisFramework<P> where P: Parameters {

  static func run(cfg: CFG, parameters: P) -> DataFlowData<P.Domain> {
    var parameters = parameters
    let blocks = parameters.iterateInDFSOrder ? dfsOrder(cfg: cfg) : cfg.blocks
    let fakeBlock = Block(label: "", generatedLabel: true, instructions: [])

    var inValue = [Block: P.Domain]()
    var outValue = [Block: P.Domain]()

    var successors = \Block.successors
    var predecessors = \Block.predecessors

    switch parameters.forward {
    case true:
      let newEntry = fakeBlock
      outValue[newEntry] = parameters.boundaryValue

      let entry = cfg.entry
      entry.predecessors.insert(newEntry)
      newEntry.successors = [entry]
    case false:
      let newExit = fakeBlock
      outValue[newExit] = parameters.boundaryValue

      for exit in cfg.exits() {
        exit.successors = [newExit]
        newExit.predecessors.insert(exit)
      }

      swap(&successors, &predecessors)
    }

    for block in blocks {
      outValue[block] = parameters.initialValue
    }

    var changed: Bool
    repeat {
      changed = false

      for block in blocks {
        inValue[block] = parameters.meet(
          block[keyPath: predecessors].map { outValue[defaulting: $0] })
        let newValue = parameters.transferFunction(block: block, value: inValue[block]!)

        if outValue[block] != newValue {
          outValue[block] = newValue
          changed = true
        }
      }
    } while changed

    switch parameters.forward {
    case true:
      fakeBlock.successors.first!.predecessors.remove(fakeBlock)
    case false:
      for block in fakeBlock.predecessors { block.successors = [] }
    }
    inValue[fakeBlock] = nil
    outValue[fakeBlock] = nil

    return DataFlowData(
      inValue: parameters.forward ? inValue : outValue,
      outValue: parameters.forward ? outValue : inValue,
      forward: parameters.forward,
      blocksOrder: blocks,
      asTextFunction: P.text)
  }

  private static func dfsOrder(cfg: CFG) -> [Block] {
    var blocks = [Block]()
    var visited = Set<Block>()

    func dfs(_ value: Block) {
      visited.insert(value)

      for succ in value.successors where !visited.contains(succ) {
        dfs(succ)
      }

      blocks.append(value)
    }

    dfs(cfg.entry)

    blocks.reverse()
    return blocks
  }
}
