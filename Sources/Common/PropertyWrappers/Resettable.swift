@propertyWrapper
public struct Resettable<Value> {
  private var defaultValue: Value
  private var value: Value

  public init(wrappedValue: Value) {
    self.defaultValue = wrappedValue
    self.value = self.defaultValue
  }

  public var wrappedValue: Value {
    get {
      self.value
    }
    set {
      self.value = newValue
    }
  }

  public var projectedValue: Resettable<Value> {
    get { self }
    set { self = newValue }
  }

  public mutating func reset() {
    self.value = defaultValue
  }
}
