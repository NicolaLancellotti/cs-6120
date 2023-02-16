import Analysis
import CFG
import IR

public struct NaiveFromSSA: Pass {

  public init() {}

  public func run(on function: BrilFunction, analysis: Analysis) -> BrilFunction {
    let cfg = analysis.cfg
    cfg.addTerminators()

    for block in cfg.blocks {
      for (index, instruction) in block.instructions.enumerated() {
        guard let phi = instruction as? BrilPhi else {
          block.instructions = Array(block.instructions.dropFirst(index))
          break
        }

        for (label, argument) in zip(phi.labels, phi.arguments) {
          let id = BrilID(argument: argument, destination: phi.destination, type: phi.type)
          cfg[label].instructions.insert(id, at: cfg[label].instructions.count - 1)
        }
      }
    }

    var function = function
    function.instructions = cfg.makeInstructions(insertGeneratedLabels: false)
    return function
  }

}
