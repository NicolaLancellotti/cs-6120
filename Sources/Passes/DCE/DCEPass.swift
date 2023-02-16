import Analysis
import CFG
import IR

public struct DCEPass: Pass {

  public init() {}

  public func run(on function: BrilFunction, analysis: Analysis) -> BrilFunction {
    var instructions = function.instructions
    var changed = true

    while changed {
      let argumentsUsed = Set(instructions.map(\.instructionArguments).joined())
      let newInstructions = instructions.compactMap { instruction in
        switch instruction.instructionDestination {
        case .none:
          return instruction
        case .some(let destination) where argumentsUsed.contains(destination):
          return instruction
        default: return nil
        }
      }
      changed = newInstructions.count != instructions.count
      instructions = newInstructions
    }

    var function = function
    function.instructions = instructions
    analysis.resetAll(function: function)
    return function
  }
}
