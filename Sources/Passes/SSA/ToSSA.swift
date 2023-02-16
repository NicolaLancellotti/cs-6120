import Analysis
import CFG
import Common
import IR

public struct ToSSA: Pass {
  public init() {}

  private typealias PhiNode = [Block: [Variable: BrilPhi]]

  public func run(on function: BrilFunction, analysis: Analysis) -> BrilFunction {
    let cfg = analysis.cfg
    cfg.addEntry()
    cfg.addTerminators()
    let dominanceFrontier = analysis.dominanceFrontier
    let dominanceTree = analysis.dominanceTree

    let variableToDefiningBlocks = findWhereVariablesAreDefined(in: cfg)
    var phiNodes = PhiNode()
    findPhiNodes(
      variableToDefiningBlocks: variableToDefiningBlocks,
      dominanceFrontier: dominanceFrontier, phiNodes: &phiNodes)

    var names = SSANames(arguments: function.parameters)
    renameVariables(
      block: cfg.entry, dominanceTree: dominanceTree,
      names: &names, phiNodes: &phiNodes)
    addPhiNodes(phiNodes)

    var function = function
    function.instructions = cfg.makeInstructions(insertGeneratedLabels: true)
    analysis.resetAll(function: function)
    return function
  }

  private func findWhereVariablesAreDefined(in cfg: CFG) -> [Variable: Set<Block>] {
    var dic = [Variable: Set<Block>]()
    for block in cfg.blocks {
      for instruction in block.instructions {
        if let destination = instruction.instructionDestination {
          dic[defaulting: destination].insert(block)
        }
      }
    }
    return dic
  }

  /// Find the type of `variable` in `block`.
  ///
  /// In bril there is no type check, for the following non-SSA bril code:
  /// ```
  /// @main() {
  /// .entry:
  ///     cond: bool = const true;
  ///     br cond .left .right;
  /// .left:
  ///     a: int = const 10;
  ///     jmp .exit;
  /// .right:
  ///     a: bool = const true;
  ///     jmp .exit;
  /// .exit:
  ///     print a;
  /// }
  /// ```
  ///
  /// `to_ssa.py` script generates:
  ///
  /// ```
  /// @main {
  /// .entry:
  ///   cond.0: bool = const true;
  ///   br cond.0 .left .right;
  /// .left:
  ///   a.1: int = const 10;
  ///   jmp .exit;
  /// .right:
  ///   a.2: bool = const true;
  ///   jmp .exit;
  /// .exit:
  ///   a.0: bool = phi a.1 a.2 .left .right;
  ///   print a.0;
  ///   ret;
  /// }
  /// ```
  private func findTypeOfVariable(_ variable: Variable, in block: Block) -> BrilType {
    var predecessors = Array(block.predecessors)

    while !predecessors.isEmpty {
      let block = predecessors.removeFirst()
      if let instruction = block.instructions.first(where: { $0.instructionDestination == variable }
      ),
        let type = instruction.instructionType
      {
        return type
      }
      predecessors.append(contentsOf: block.predecessors)
    }
    unreachable()
  }

  private func findPhiNodes(
    variableToDefiningBlocks: [Variable: Set<Block>],
    dominanceFrontier: [Label: Set<Block>],
    phiNodes: inout PhiNode
  ) {
    for (variable, var toVisit) in variableToDefiningBlocks {
      var visited = Set<Block>()

      while let definingBlock = toVisit.popFirst() {
        visited.insert(definingBlock)

        for blockInFrontier in dominanceFrontier[defaulting: definingBlock.label] {
          if phiNodes[defaulting: blockInFrontier][variable] == nil {
            let type = findTypeOfVariable(variable, in: blockInFrontier)
            let phi = BrilPhi(arguments: [], labels: [], destination: variable, type: type)
            phiNodes[defaulting: blockInFrontier][variable] = phi
          }

          if !visited.contains(blockInFrontier) {
            toVisit.insert(blockInFrontier)
          }
        }
      }
    }
  }

  private func renameVariables(
    block: Block,
    dominanceTree: [Label: Set<Block>],
    names: inout SSANames,
    phiNodes: inout PhiNode
  ) {
    var stack = [String]()

    for variable in phiNodes[defaulting: block].keys {
      phiNodes[block]![variable]!.destination = names.new(for: variable, stack: &stack)
    }

    block.instructions = block.instructions.map {
      var instruction = $0
      instruction.instructionArguments = instruction.instructionArguments
        .map(names.current)
      instruction.instructionDestination = instruction.instructionDestination
        .map { names.new(for: $0, stack: &stack) }
      return instruction
    }

    for successor in block.successors {
      for variable in phiNodes[defaulting: successor].keys {
        let name = names.current(for: variable)
        phiNodes[successor]![variable]!.arguments.append(name)
        phiNodes[successor]![variable]!.labels.append(block.label)
      }
    }

    let sortedDominanceTree = dominanceTree[defaulting: block.label].sorted { $0.label < $1.label }
    for block in sortedDominanceTree {
      renameVariables(
        block: block, dominanceTree: dominanceTree,
        names: &names, phiNodes: &phiNodes)
    }

    names.popStack(&stack)
  }

  private func addPhiNodes(_ phiNodes: PhiNode) {
    for (block, variableToPhi) in phiNodes {
      let sortedPhiNodes = variableToPhi.sorted { $0.key < $1.key }.map { $0.value }
      for phi in sortedPhiNodes {
        block.instructions.insert(phi, at: 0)
      }
    }
  }
}

struct SSANames {
  private var nameToIndexes = [String: [Int]]()
  private var nameToMaxIndex = [String: Int]()

  init(arguments: [BrilParameter]) {
    for argument in arguments {
      nameToIndexes[argument.name] = [-1]
    }
  }

  mutating func new(for variable: String, stack: inout [String]) -> String {
    let index = nameToMaxIndex[variable, default: -1] + 1
    nameToMaxIndex[variable] = index
    nameToIndexes[defaulting: variable].append(index)
    stack.append(variable)
    return current(for: variable)
  }

  func current(for variable: String) -> String {
    guard let index = nameToIndexes[variable]?.last else {
      return "__undefined"
    }
    return variable + (index == -1 ? "" : ".\(index)")
  }

  mutating func popStack(_ stack: inout [String]) {
    for variable in stack {
      nameToIndexes[variable]?.removeLast()
    }
  }
}
