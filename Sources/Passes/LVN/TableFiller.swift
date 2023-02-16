import Analysis
import CFG
import Common
import IR

struct TableFiller {
  let config: LVNConfiguration
  var environment = Environment()
  var table = Table()

  mutating func run(block: Block) -> (
    table: Table,
    environment: Environment,
    maxVersions: [Variable: Int]
  ) {
    for instruction in block.instructions {
      fillTable(for: instruction)
    }
    let maxVersions = environment.resetVariables()
    return (table: table, environment: environment, maxVersions: maxVersions)
  }

  private mutating func fillTable(for instruction: any BrilInstruction) {
    switch instruction {
    case let instruction as BrilConstant:
      let variable = environment.makeVariable(withName: instruction.destination)
      let number = table.update(
        value: .const(instruction.value),
        variable: variable,
        constant: instruction.value)
      environment[variable] = .number(number)
    case let instruction as BrilOperation:
      var numbersOrVariables = instruction.arguments.map(environment.currentVariable).map {
        environment[$0]
      }

      // Exploit Commutativity
      if config.canonicalise && instruction.op.isCommutative {
        numbersOrVariables.sort()
      }

      // Constant Folding
      let constant =
        config.constantFolding
        ? ConstantFolder.tryFold(table: table, op: instruction.op, arguments: numbersOrVariables)
        : nil

      let variable = environment.makeVariable(withName: instruction.destination)
      let number = table.update(
        value: .op(instruction.op, numbersOrVariables),
        variable: variable,
        constant: constant)
      environment[variable] = .number(number)
    case let instruction as BrilID:
      if config.copyPropagation {
        let variable = environment.makeVariable(withName: instruction.destination)
        let argument = environment.currentVariable(name: instruction.argument)
        switch environment[argument] {
        case .number(let number): environment[variable] = .number(number)
        case .variable(let value): environment[variable] = .variable(value)
        }
      }
    case is BrilCall:
      break
    case is BrilPhi:
      fatalError("Phi node in non-SSA LVN version")
    default:
      break
    }
  }

}
