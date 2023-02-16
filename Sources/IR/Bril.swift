import Foundation

// MARK: - Bril Program

public struct BrilProgram: Equatable, Codable {
  public var functions: [BrilFunction]

  public init(functions: [BrilFunction]) {
    self.functions = functions
  }

  public init(data: Data) throws {
    self = try JSONDecoder().decode(BrilProgram.self, from: data)
  }

  public func data() throws -> Data {
    let encoder = JSONEncoder()
    encoder.outputFormatting = .prettyPrinted
    return try encoder.encode(self)
  }

  public func json() -> String? {
    guard let data = try? data() else {
      return nil
    }
    return String(data: data, encoding: .utf8)
  }
}

// MARK: - Bril Type

public indirect enum BrilType: Equatable, Codable, CustomStringConvertible {
  case int
  case bool
  case pointer(BrilType)

  public init(from decoder: Decoder) throws {
    let container = try decoder.singleValueContainer()
    do {
      switch try container.decode(String.self) {
      case "int": self = .int
      case "bool": self = .bool
      case let type: fatalError("Type `\(type)` is not supported")
      }
    } catch {
      let dictionary = try container.decode([String: BrilType].self)

      if dictionary.count == 1 {
        if let type = dictionary["ptr"] {
          self = .pointer(type)
          return
        }
      }
      fatalError("Type `\(dictionary)` is not supported")
    }
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.singleValueContainer()
    switch self {
    case .int: try container.encode("int")
    case .bool: try container.encode("bool")
    case .pointer(let type): try container.encode(["ptr": type])
    }
  }

  public var pointeeType: BrilType {
    guard case .pointer(let pointeeType) = self else {
      fatalError("Expected pointer type, but found `\(self)`")
    }
    return pointeeType
  }

  public var description: String {
    switch self {
    case .int: "int"
    case .bool: "bool"
    case .pointer(let brilType): "ptr<\(brilType)>"
    }
  }
}

// MARK: - Bril Argument

public struct BrilParameter: Equatable, Codable {
  public let name: String
  public let type: BrilType

  public init(name: String, type: BrilType) {
    self.name = name
    self.type = type
  }
}

// MARK: - Bril Function

public struct BrilFunction: Codable {
  public let name: String
  public let parameters: [BrilParameter]
  public let type: BrilType?
  public var instructions: [any BrilInstruction]

  public init(
    name: String,
    parameters: [BrilParameter],
    type: BrilType? = nil,
    instructions: [any BrilInstruction]
  ) {
    self.name = name
    self.parameters = parameters
    self.type = type
    self.instructions = instructions
  }

  enum CodingKeys: String, CodingKey {
    case name
    case args
    case type
    case instrs
  }

  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    name = try container.decode(String.self, forKey: .name)
    parameters =
      container.contains(.args) ? try container.decode([BrilParameter].self, forKey: .args) : []
    type = container.contains(.type) ? try container.decode(BrilType.self, forKey: .type) : nil
    let anyInstructions = try container.decode([AnyInstruction].self, forKey: .instrs)
    instructions = anyInstructions.map(\.wrapped)
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(name, forKey: .name)
    try container.encode(parameters, forKey: .args)
    if let type {
      try container.encode(type, forKey: .type)
    }
    let anyInstructions = instructions.map { AnyInstruction(wrapped: $0) }
    try container.encode(anyInstructions, forKey: .instrs)
  }
}

extension BrilFunction: Equatable {
  public static func == (lhs: BrilFunction, rhs: BrilFunction) -> Bool {
    if lhs.name != rhs.name || lhs.parameters != rhs.parameters || lhs.type != rhs.type
      || lhs.instructions.count != rhs.instructions.count
    {
      return false
    }

    for (lhsInstr, rhsInstr) in zip(lhs.instructions, rhs.instructions) {
      if !lhsInstr.isEqual(rhsInstr) {
        return false
      }
    }

    return true
  }
}

// MARK: - Bril Operator

public enum BrilOperator: String, Comparable {
  case add
  case mul
  case sub
  case div
  case eq
  case lt
  case gt
  case le
  case ge
  case not
  case and
  case or

  public var isCommutative: Bool {
    switch self {
    case .add, .mul, .eq, .and, .or: return true
    case .sub, .div, .lt, .gt, .le, .ge, .not: return false
    }
  }

  public static func < (lhs: BrilOperator, rhs: BrilOperator) -> Bool {
    lhs.rawValue < rhs.rawValue
  }
}

// MARK: - Bril Value

public enum BrilValue: Equatable, Hashable, CustomStringConvertible {
  case bool(Bool)
  case int(Int64)

  public var type: BrilType {
    switch self {
    case .bool: BrilType.bool
    case .int: BrilType.int
    }
  }

  public var description: String {
    switch self {
    case .bool(let value): String(value)
    case .int(let value): String(value)
    }
  }
}
