import IR

enum RuntimeValue {
  case primitive(BrilValue)
  case pointer(BrilPointer)

  var type: BrilType {
    switch self {
    case .primitive(let value): value.type
    case .pointer(let pointer): BrilType.pointer(pointer.pointeeType)
    }
  }
}

extension RuntimeValue: CustomStringConvertible {
  var description: String {
    switch self {
    case .primitive(let value): value.description
    case .pointer: "pointer"
    }
  }
}
