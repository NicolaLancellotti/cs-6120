import IR

enum ConstantFolder {

  static func tryFold(
    table: Table,
    op: BrilOperator,
    arguments: [NumberOrVariable]
  ) -> BrilValue? {

    func convertArguments() -> [ConstantOrVariable] {
      return arguments.map {
        switch $0 {
        case .number(let number):
          if let constant = table[number].constant {
            return ConstantOrVariable.constant(constant)
          }
          return ConstantOrVariable.variable(table[number].canonicalVariable)
        case .variable(let variable): return ConstantOrVariable.variable(variable)
        }
      }
    }

    return fold(op: op, arguments: convertArguments())
  }
}

extension ConstantFolder {

  fileprivate enum ConstantOrVariable {
    case constant(BrilValue)
    case variable(VersionedVariable)
  }

  fileprivate static func fold(op: BrilOperator, arguments: [ConstantOrVariable]) -> BrilValue? {

    func fold<Result>(
      op: (Int64, Int64) -> Result,
      constructor: (Result) -> BrilValue
    ) -> BrilValue? {
      if arguments.count == 2,
        case .constant(let c1) = arguments[0], case .constant(let c2) = arguments[1],
        case .int(let lhs) = c1, case .int(let rhs) = c2
      {
        return constructor(op(lhs, rhs))
      }
      return nil
    }

    func fold<Result>(
      op: (Bool, Bool) -> Result,
      constructor: (Result) -> BrilValue
    ) -> BrilValue? {
      if arguments.count == 2,
        case .constant(let c1) = arguments[0], case .constant(let c2) = arguments[1],
        case .bool(let lhs) = c1, case .bool(let rhs) = c2
      {
        return constructor(op(lhs, rhs))
      }
      return nil
    }

    func fold(op: (Int64, Int64) -> Int64) -> BrilValue? {
      fold(op: op, constructor: BrilValue.int)
    }

    func fold(op: (Int64, Int64) -> Bool) -> BrilValue? {
      fold(op: op, constructor: BrilValue.bool)
    }

    func fold(op: (Bool, Bool) -> Bool) -> BrilValue? {
      fold(op: op, constructor: BrilValue.bool)
    }

    func foldTwoEqualVariables(result: Bool) -> BrilValue? {
      if arguments.count == 2,
        case .variable(let v1) = arguments[0],
        case .variable(let v2) = arguments[1],
        v1 == v2
      {
        return .bool(result)
      }
      return nil
    }

    func foldOnlyOneConstant(result: Bool, ifConstantIs constantValue: Bool) -> BrilValue? {
      if case .constant(let c) = arguments.first,
        case .bool(let value) = c,
        value == constantValue
      {
        return .bool(result)
      }
      if case .constant(let c) = arguments.dropFirst(1).first,
        case .bool(let value) = c,
        value == constantValue
      {
        return .bool(result)
      }
      return nil
    }

    switch op {
    case .add: return fold(op: +)
    case .mul: return fold(op: *)
    case .sub: return fold(op: -)
    case .div: return fold(op: /)
    case .eq:
      return fold(op: (==) as (Int64, Int64) -> Bool)
        ?? fold(op: (==) as (Bool, Bool) -> Bool)
        ?? foldTwoEqualVariables(result: true)
    case .lt: return fold(op: <)  // ?? foldTwoEqualVariables(result: false)
    case .gt: return fold(op: >)  // ?? foldTwoEqualVariables(result: false)
    case .le: return fold(op: <=) ?? foldTwoEqualVariables(result: true)
    case .ge: return fold(op: >=) ?? foldTwoEqualVariables(result: true)
    case .not:
      if case .constant(let c) = arguments.first, case .bool(let value) = c {
        return .bool(!value)
      }
    case .and:
      return fold(op: { $0 && $1 })
        ?? foldOnlyOneConstant(result: false, ifConstantIs: false)
    case .or:
      return fold(op: { $0 || $1 })
        ?? foldOnlyOneConstant(result: true, ifConstantIs: true)
    }
    return nil
  }

}
