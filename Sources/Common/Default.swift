public protocol Default {
  static var `default`: Self { get }
}

extension Array: Default {
  public static var `default`: Self { .init() }
}

extension Set: Default {
  public static var `default`: Self { .init() }
}

extension Dictionary: Default {
  public static var `default`: Self { .init() }
}

extension Int: Default {
  public static var `default`: Self { .init() }
}
