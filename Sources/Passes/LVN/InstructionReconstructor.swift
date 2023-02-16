import Analysis
import CFG
import Common
import IR

struct InstructionReconstructor {
  let config: LVNConfiguration
  let table: Table
  var environment: Environment
  let maxVersions: [Variable: Int]

  mutating func run(_ instruction: any BrilInstruction) -> any BrilInstruction {
    switch instruction {
    case var instruction as BrilConstant:
      let destination = environment.makeVariable(withName: instruction.destination)

      if config.constantFolding,
        let constant = constantFold(
          destination: destination,
          type: instruction.type)
      {
        return constant
      }

      return makeInstruction(
        variable: destination, type: instruction.type,
        tryMakeID: config.tryMakeID
      ) {
        guard case .const(let value) = $0 else { unreachable() }
        instruction.value = value
        instruction.destination = variableToString(destination)
        return instruction
      }
    case var instruction as BrilOperation:
      let destination = environment.makeVariable(withName: instruction.destination)

      if config.constantFolding,
        let constant = constantFold(
          destination: destination,
          type: instruction.type)
      {
        return constant
      }

      return makeInstruction(variable: destination, type: instruction.type) {
        guard case .op(_, let numbersOrVariables) = $0 else { unreachable() }
        let stringVariables = numbersOrVariables.map {
          switch $0 {
          case .number(let number): return table[number].canonicalVariable
          case .variable(let variable): return variable
          }
        }.map(variableToString)
        instruction.arguments = stringVariables
        instruction.destination = variableToString(destination)
        return instruction
      }
    case var instruction as BrilBr:
      instruction.argument = variableToString(canonicalVariable(instruction.argument))
      return instruction
    case var instruction as BrilCall:
      let destination = instruction.destination.map { environment.makeVariable(withName: $0) }
      instruction.arguments = instruction.arguments.map(canonicalVariable).map(variableToString)
      instruction.destination = destination.map(variableToString)
      return instruction
    case var instruction as BrilRet:
      instruction.argument = instruction.argument.map(canonicalVariable).map(variableToString)
      return instruction
    case var instruction as BrilID:
      let destination = environment.makeVariable(withName: instruction.destination)

      if config.constantPropagation,
        case .number(let number) = environment[canonicalVariable(instruction.argument)],
        case .const(let value) = table[number].value
      {
        return BrilConstant(
          value: value,
          destination: variableToString(destination),
          type: instruction.type)
      }
      instruction.argument = variableToString(canonicalVariable(instruction.argument))
      instruction.destination = variableToString(destination)
      return instruction
    case var instruction as BrilPrint:
      instruction.arguments = instruction.arguments.map(canonicalVariable).map(variableToString)
      return instruction
    case is BrilPhi:
      fatalError("Phi node in LVN non-SSA version")
    case let instruction:
      return instruction
    }
  }

  //  @main {
  //  a: int = const 4;
  //  b: int = const 4;
  //  }

  //  tryMakeID = True
  //  @main {
  //  a: int = const 4;
  //  b: int = id a;
  //  }

  //  tryMakeID = False
  //  @main {
  //  a: int = const 4;
  //  b: int = const 4;
  //  }
  private func makeInstruction(
    variable: VersionedVariable,
    type: BrilType,
    tryMakeID: Bool = true,
    fromTableValue: (Table.Value) -> any BrilInstruction
  ) -> any BrilInstruction {
    switch environment[variable] {
    case .number(let number):
      let row = table[number]
      if variable == row.canonicalVariable || !tryMakeID {
        return fromTableValue(row.value)
      } else {
        return BrilID(
          argument: variableToString(row.canonicalVariable),
          destination: variableToString(variable),
          type: type)
      }
    case .variable: fatalError("unreachable")
    }
  }

  private func constantFold(
    destination: VersionedVariable,
    type: BrilType
  ) -> (any BrilInstruction)? {
    if case .number(let number) = environment[destination],
      let constant = table[number].constant
    {
      return BrilConstant(
        value: constant,
        destination: variableToString(destination),
        type: type)
    }
    return nil
  }

  private func variableToString(_ variable: VersionedVariable) -> String {
    let maxVersion = maxVersions[variable.name]
    if maxVersion == nil || maxVersion == variable.version {
      return variable.name
    }
    return variable.name + ".\(variable.version)"
  }

  private func canonicalVariable(_ variable: String) -> VersionedVariable {
    let variable = environment.currentVariable(name: variable)
    switch environment[variable] {
    case .number(let number): return table[number].canonicalVariable
    case .variable(let variable): return variable
    }
  }

}
