import CFG
import Common
import IR

public enum AvailableExpressions: DataFlowAnalysis {

  public typealias Domain = Set<Expression>

  public struct Expression: Hashable {
    let op: BrilOperator
    let arguments: [String]
  }

  public static func run(
    on function: BrilFunction,
    analysis: Analysis
  ) -> DataFlowData<Domain> {
    let parameters = AvailableExpressionsParameters(blocks: analysis.cfg.blocks)
    return DataFlowAnalysisFramework.run(
      cfg: analysis.cfg,
      parameters: parameters)
  }
}

private struct AvailableExpressionsParameters: Parameters {

  private var expressions = Domain()

  typealias Domain = AvailableExpressions.Domain

  init(blocks: [Block]) {
    for instruction in blocks.map(\.instructions).joined() {
      switch instruction {
      case let instruction as BrilOperation:
        expressions.update(with: .init(op: instruction.op, arguments: instruction.arguments))
      default: break
      }
    }
  }

  var forward: Bool { true }

  var boundaryValue: Domain { .init() }

  var initialValue: Domain { expressions }

  func meet(_ values: [Domain]) -> Domain { setIntersection(values) }

  func transferFunction(block: Block, value: Domain) -> Domain {
    var value = value
    for instruction in block.instructions {
      if let instruction = instruction as? BrilOperation {
        value.update(with: .init(op: instruction.op, arguments: instruction.arguments))
      }
      if let dest = instruction.instructionDestination {
        value = value.filter { !$0.arguments.contains(dest) }
      }
    }
    return value
  }

  static func text(_ value: Domain) -> String {
    value.isEmpty ? "∅" : value.sorted().map(\.debugDescription).joined(separator: ", ")
  }
}

extension AvailableExpressions.Expression: Comparable {
  public static func < (lhs: AvailableExpressions.Expression, rhs: AvailableExpressions.Expression)
    -> Bool
  {
    switch lhs.op != rhs.op {
    case true: return lhs.op < rhs.op
    case false: return lhs.arguments.lexicographicallyPrecedes(rhs.arguments)
    }
  }
}

extension AvailableExpressions.Expression: CustomDebugStringConvertible {
  public var debugDescription: String {
    "\(op.rawValue)(\(arguments.joined(separator: ", ")))"
  }
}
