extension Dictionary where Value: Default {
  public subscript(defaulting key: Key) -> Value {
    get {
      self[key, default: Value.default]
    }
    set {
      self[key] = newValue
    }
  }
}

extension Optional {
  public func unwrap(_ message: String) -> Wrapped {
    if let self {
      return self
    }
    fatalError(message)
  }
}
