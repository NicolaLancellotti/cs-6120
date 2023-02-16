import Common

// MARK: - Bril Instruction

public protocol BrilInstruction: Equatable {
  var isTerminator: Bool { get }
  var instructionType: BrilType? { get }
  var instructionDestination: Variable? { get set }
  var instructionArguments: [Variable] { get set }
}

extension BrilInstruction {
  public var isTerminator: Bool { false }
  public var instructionType: BrilType? { nil }
  public var instructionDestination: Variable? {
    get { nil }
    set {}
  }
  public var instructionArguments: [Variable] {
    get { [] }
    set {}
  }

  public func isEqual(_ value: any BrilInstruction) -> Bool {
    guard let value = value as? Self else {
      return false
    }
    return self == value
  }

}

// MARK: - Bril Label

public struct BrilLabel: BrilInstruction {
  public let label: Label

  public init(label: Label) {
    self.label = label
  }
}

// MARK: - Bril Operation

public struct BrilOperation: BrilInstruction {
  public let op: BrilOperator
  public var arguments: [Variable]
  public var destination: Variable
  public let type: BrilType

  public init(
    op: BrilOperator,
    arguments: [Variable],
    destination: Variable,
    type: BrilType
  ) {
    self.op = op
    self.arguments = arguments
    self.destination = destination
    self.type = type
  }

  public var instructionDestination: Variable? {
    get { destination }
    set { destination = newValue ?? destination }
  }

  public var instructionArguments: [Variable] {
    get { arguments }
    set { arguments = newValue }
  }

  public var instructionType: BrilType? {
    type
  }
}

// MARK: - Bril Constant

public struct BrilConstant: BrilInstruction {
  public var value: BrilValue
  public var destination: Variable
  public let type: BrilType

  public init(value: BrilValue, destination: Variable, type: BrilType) {
    self.value = value
    self.destination = destination
    self.type = type
  }

  public var instructionDestination: Variable? {
    get { destination }
    set { destination = newValue ?? destination }
  }

  public var instructionType: BrilType? {
    type
  }
}

// MARK: - Bril Jmp

public struct BrilJmp: BrilInstruction {
  public let label: Label

  public var isTerminator: Bool { true }

  public init(label: Label) {
    self.label = label
  }
}

// MARK: - Bril Br

public struct BrilBr: BrilInstruction {
  public var argument: Variable
  public let trueLabel: Label
  public let falseLabel: Label

  public var isTerminator: Bool { true }

  public init(argument: Variable, trueLabel: Label, falseLabel: Label) {
    self.argument = argument
    self.trueLabel = trueLabel
    self.falseLabel = falseLabel
  }

  public var instructionArguments: [Variable] {
    get { [argument] }
    set { argument = newValue[0] }
  }
}

// MARK: - Bril Call

public struct BrilCall: BrilInstruction {
  public let function: String
  public var arguments: [Variable]
  public var destination: Variable?
  public let type: BrilType?

  public init(
    function: String,
    arguments: [Variable],
    destination: Variable?,
    type: BrilType?
  ) {
    self.function = function
    self.arguments = arguments
    self.destination = destination
    self.type = type
  }

  public var instructionDestination: Variable? {
    get { destination }
    set { destination = newValue ?? destination }
  }

  public var instructionArguments: [Variable] {
    get { arguments }
    set { arguments = newValue }
  }

  public var instructionType: BrilType? {
    type
  }
}

// MARK: - Bril Ret

public struct BrilRet: BrilInstruction {
  public var argument: Variable?

  public var isTerminator: Bool { true }

  public init(argument: Variable?) {
    self.argument = argument
  }

  public var instructionArguments: [Variable] {
    get { argument.map { [$0] } ?? [] }
    set { argument = newValue.isEmpty ? nil : newValue[0] }
  }
}

// MARK: - Bril ID

public struct BrilID: BrilInstruction {
  public var argument: Variable
  public var destination: Variable
  public let type: BrilType

  public init(argument: Variable, destination: Variable, type: BrilType) {
    self.argument = argument
    self.destination = destination
    self.type = type
  }

  public var instructionDestination: Variable? {
    get { destination }
    set { destination = newValue ?? destination }
  }

  public var instructionArguments: [Variable] {
    get { [argument] }
    set { argument = newValue[0] }
  }

  public var instructionType: BrilType? {
    type
  }
}

// MARK: - Bril Print

public struct BrilPrint: BrilInstruction {
  public var arguments: [Variable]

  public init(arguments: [Variable]) {
    self.arguments = arguments
  }

  public var instructionArguments: [Variable] {
    get { arguments }
    set { arguments = newValue }
  }
}

// MARK: - Bril Nop

public struct BrilNop: BrilInstruction {

  public init() {}
}

// MARK: - Bril Phi

public struct BrilPhi: BrilInstruction {
  public var arguments: [Variable]
  public var labels: [Label]
  public var destination: Variable
  public let type: BrilType

  public init(
    arguments: [Variable],
    labels: [Label],
    destination: Variable,
    type: BrilType
  ) {
    self.arguments = arguments
    self.labels = labels
    self.destination = destination
    self.type = type
  }

  public var instructionArguments: [Variable] {
    get { arguments }
    set { arguments = newValue }
  }

  public var instructionDestination: Variable? {
    get { destination }
    set { destination = newValue ?? destination }
  }

  public var instructionType: BrilType? {
    type
  }
}

// MARK: - Bril Alloc

public struct BrilAlloc: BrilInstruction {
  public var capacity: Variable
  public var destination: Variable
  public let type: BrilType

  public init(capacity: Variable, destination: Variable, type: BrilType) {
    self.capacity = capacity
    self.destination = destination
    self.type = type
  }

  public var instructionDestination: Variable? {
    get { destination }
    set { destination = newValue ?? destination }
  }

  public var instructionArguments: [Variable] {
    get { [capacity] }
    set { capacity = newValue[0] }
  }

  public var instructionType: BrilType? {
    type
  }
}

// MARK: - Bril Store

public struct BrilStore: BrilInstruction {
  public var pointer: Variable
  public var value: Variable

  public init(pointer: Variable, value: Variable) {
    self.pointer = pointer
    self.value = value
  }

  public var instructionArguments: [Variable] {
    get { [pointer, value] }
    set {
      pointer = newValue[0]
      value = newValue[1]
    }
  }
}

// MARK: - Bril Load

public struct BrilLoad: BrilInstruction {
  public var pointer: Variable
  public var destination: Variable
  public let type: BrilType

  public init(pointer: Variable, destination: Variable, type: BrilType) {
    self.pointer = pointer
    self.destination = destination
    self.type = type
  }

  public var instructionDestination: Variable? {
    get { destination }
    set { destination = newValue ?? destination }
  }

  public var instructionArguments: [Variable] {
    get { [pointer] }
    set { pointer = newValue[0] }
  }

  public var instructionType: BrilType? {
    type
  }
}

// MARK: - Bril Ptr Add

public struct BrilPtrAdd: BrilInstruction {
  public var pointer: Variable
  public var offset: Variable
  public var destination: Variable
  public let type: BrilType

  public init(pointer: Variable, offset: Variable, destination: Variable, type: BrilType) {
    self.pointer = pointer
    self.offset = offset
    self.destination = destination
    self.type = type
  }

  public var instructionDestination: Variable? {
    get { destination }
    set { destination = newValue ?? destination }
  }

  public var instructionArguments: [Variable] {
    get { [pointer, offset] }
    set {
      pointer = newValue[0]
      offset = newValue[1]
    }
  }

  public var instructionType: BrilType? {
    type
  }
}
