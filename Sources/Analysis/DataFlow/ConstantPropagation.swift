import CFG
import Common
import IR

public enum ConstantPropagation: DataFlowAnalysis {

  public typealias Domain = [Variable: Value]

  public enum Value: Equatable {
    case constant(BrilValue)
    case nonConstant
  }

  public static func run(
    on function: BrilFunction,
    analysis: Analysis
  ) -> DataFlowData<Domain> {
    DataFlowAnalysisFramework.run(
      cfg: analysis.cfg,
      parameters: ConstantPropagationParameters())
  }
}

private struct ConstantPropagationParameters: Parameters {

  typealias Domain = ConstantPropagation.Domain

  var forward: Bool { true }

  var boundaryValue: Domain { .init() }

  var initialValue: Domain { .init() }

  // Meet: union, but if the keys are equal and the values are not,
  // the new value is non-constant
  func meet(_ values: [Domain]) -> Domain {
    values.reduce(into: Domain()) {
      $0.merge($1) { $0 == $1 ? $0 : .nonConstant }
    }
  }

  // Transfer function:
  // f_d(x) = if statement has dest then x[dest] = (statement is const ? const : non-const)
  func transferFunction(block: Block, value: Domain) -> Domain {
    var value = value
    for instruction in block.instructions {
      if let instruction = instruction as? BrilConstant {
        value[instruction.destination] = .constant(instruction.value)
      } else if let dest = instruction.instructionDestination {
        value[dest] = .nonConstant
      }
    }
    return value
  }

  static func text(_ value: Domain) -> String {
    value.isEmpty
      ? "∅"
      : value
        .map { ($0, $1) }
        .sorted { $0.0 < $1.0 }
        .map { "\($0): \($1)" }
        .joined(separator: ", ")
  }
}

extension ConstantPropagation.Value: CustomDebugStringConvertible {
  public var debugDescription: String {
    switch self {
    case .nonConstant: return "?"
    case .constant(let constant):
      switch constant {
      case .bool(let value): return value ? "True" : "False"
      case .int(let value): return "\(value)"
      }
    }
  }
}
