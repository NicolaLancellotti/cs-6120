import Common
import IR

struct Environment: ~Copyable {
  private var environment = [Variable: RuntimeValue]()

  deinit {
    for value in environment.values {
      ReferenceCount.release(value)
    }
  }

  subscript(variable: Variable) -> RuntimeValue {
    get {
      environment[variable].unwrap("`\(variable)` not found")
    }
    set {
      ReferenceCount.retain(newValue)
      if let value = environment[variable] {
        ReferenceCount.release(value)
      }
      environment[variable] = newValue
    }
  }

}

extension Environment {

  subscript(variables: [Variable]) -> [RuntimeValue] {
    variables.lazy.map { self[$0] }
  }

  func brilValue(of variable: Variable) -> BrilValue {
    let value = self[variable]
    return switch value {
    case .primitive(let value): value
    default: fatalError("Expected an `int` or `bool`, but found `\(value.type)`")
    }
  }

  func brilValues(of variables: [Variable]) -> [BrilValue] {
    variables.map { brilValue(of: $0) }
  }

  func valueAsBool(of variable: Variable) -> Bool {
    let runtimeValue = self[variable]
    guard case .primitive(let value) = runtimeValue,
      case .bool(let value) = value
    else {
      fatalError("Expected `bool`, but found `\(runtimeValue.type)`")
    }
    return value
  }

  func valueAsInt64(of variable: Variable) -> Int64 {
    let runtimeValue = self[variable]
    guard case .primitive(let value) = runtimeValue,
      case .int(let value) = value
    else {
      fatalError("Expected `bool`, but found `\(runtimeValue.type)`")
    }
    return value
  }

  func valueAsPointer(of variable: Variable) -> BrilPointer {
    let pointerValue = self[variable]
    guard case .pointer(let pointer) = pointerValue else {
      fatalError("Expected pointer type, but found `\(pointerValue.type)`")
    }
    return pointer
  }

}
