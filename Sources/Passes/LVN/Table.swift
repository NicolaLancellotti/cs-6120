import IR

typealias Number = Int

struct Table {

  enum Value: Equatable, Hashable {
    case const(BrilValue)
    case op(BrilOperator, [NumberOrVariable])
  }

  struct Row {
    let value: Value
    let canonicalVariable: VersionedVariable
    let constant: BrilValue?
  }

  private var rows = [Row]()
  private var valueToNumber = [Value: Number]()

  subscript(number: Number) -> Row {
    rows[number]
  }
}

// MARK: - Update

extension Table {
  mutating func update(
    value: Value,
    variable: VersionedVariable,
    constant: BrilValue?
  ) -> Int {
    guard let number = valueToNumber[value] else {
      rows.append(Row(value: value, canonicalVariable: variable, constant: constant))
      let number = rows.count - 1
      valueToNumber[value] = number
      return number
    }
    return number
  }
}
