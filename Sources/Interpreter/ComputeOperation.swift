import IR

func computeOperation(_ op: BrilOperator, arguments: [BrilValue]) -> BrilValue? {

  func compute<Result>(
    op: (Int64, Int64) -> Result,
    constructor: (Result) -> BrilValue
  ) -> BrilValue? {
    if case .int(let lhs) = arguments[0], case .int(let rhs) = arguments[1] {
      return constructor(op(lhs, rhs))
    }
    return nil
  }

  func compute(op: (Int64, Int64) -> Int64) -> BrilValue? {
    compute(op: op, constructor: BrilValue.int)
  }

  func compute(op: (Int64, Int64) -> Bool) -> BrilValue? {
    compute(op: op, constructor: BrilValue.bool)
  }

  func compute(op: (Bool, Bool) -> Bool) -> BrilValue? {
    if case .bool(let lhs) = arguments[0], case .bool(let rhs) = arguments[1] {
      return .bool(op(lhs, rhs))
    }
    return nil
  }

  func compute(op: (Bool) -> Bool) -> BrilValue? {
    if case .bool(let value) = arguments[0] {
      return .bool(op(!value))
    }
    return nil
  }

  return switch op {
  case .add: compute(op: &+)
  case .mul: compute(op: &*)
  case .sub: compute(op: &-)
  case .div: compute(op: /)
  case .eq:
    compute(op: (==) as (Int64, Int64) -> Bool)
      ?? compute(op: (==) as (Bool, Bool) -> Bool)
  case .lt: compute(op: <)
  case .gt: compute(op: >)
  case .le: compute(op: <=)
  case .ge: compute(op: >=)
  case .and: compute(op: { $0 && $1 })
  case .or: compute(op: { $0 || $1 })
  case .not: compute(op: { !$0 })
  }
}
