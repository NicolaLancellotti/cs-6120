struct AnyInstruction: Codable {
  let wrapped: any BrilInstruction

  enum CodingKeys: String, CodingKey {
    case op
    case dest
    case type
    case args
    case funcs
    case labels
    case value
    case label
  }

  init(wrapped: any BrilInstruction) {
    self.wrapped = wrapped
  }

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)

    func decode<T: Decodable>(key: CodingKeys) throws -> T {
      try container.decode(T.self, forKey: key)
    }

    func decodeArgs() throws -> [String] {
      container.contains(.args) ? try decode(key: .args) : []
    }

    if !container.contains(.op) {
      wrapped = try BrilLabel(label: decode(key: .label))
      return
    }

    let op: String = try decode(key: .op)

    if let operation = BrilOperator(rawValue: op) {
      wrapped = try BrilOperation(
        op: operation,
        arguments: decodeArgs(),
        destination: decode(key: .dest),
        type: decode(key: .type))
      return
    }

    switch op {
    case "const":
      let value: BrilValue
      if let intValue: Int64 = try? decode(key: .value) {
        value = BrilValue.int(intValue)
      } else {
        value = BrilValue.bool(try decode(key: .value))
      }

      wrapped = try BrilConstant(
        value: value,
        destination: decode(key: .dest),
        type: decode(key: .type))
    case "jmp":
      wrapped = BrilJmp(
        label: try container.decode(
          [String].self,
          forKey: .labels)[0])
    case "br":
      let labels: [String] = try decode(key: .labels)
      wrapped = try BrilBr(
        argument: decodeArgs()[0],
        trueLabel: labels[0],
        falseLabel: labels[1])
    case "call":
      wrapped = try BrilCall(
        function: container.decode(
          [String].self,
          forKey: .funcs)[0],
        arguments: decodeArgs(),
        destination: try? decode(key: .dest),
        type: try? decode(key: .type))
    case "print":
      wrapped = try BrilPrint(arguments: decodeArgs())
    case "ret":
      wrapped = BrilRet(argument: try decodeArgs().first)
    case "id":
      wrapped = try BrilID(
        argument: decodeArgs()[0],
        destination: decode(key: .dest),
        type: decode(key: .type))
    case "nop":
      wrapped = BrilNop()
    case "phi":
      wrapped = try BrilPhi(
        arguments: decodeArgs(),
        labels: decode(key: .labels),
        destination: decode(key: .dest),
        type: decode(key: .type))
    case "alloc":
      wrapped = try BrilAlloc(
        capacity: decodeArgs()[0],
        destination: decode(key: .dest),
        type: decode(key: .type))
    case "store":
      let arguments = try decodeArgs()
      wrapped = BrilStore(pointer: arguments[0], value: arguments[1])
    case "ptradd":
      let arguments = try decodeArgs()
      wrapped = try BrilPtrAdd(
        pointer: arguments[0],
        offset: arguments[1],
        destination: decode(key: .dest),
        type: decode(key: .type))
    case "load":
      wrapped = try BrilLoad(
        pointer: decodeArgs()[0],
        destination: decode(key: .dest),
        type: decode(key: .type))
    case "free":
      wrapped = BrilNop()
    case let op: fatalError("Op `\(op)` does not exists")
    }
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    switch wrapped {
    case let instruction as BrilLabel:
      try container.encode(instruction.label, forKey: .label)
    case let instruction as BrilOperation:
      try container.encode(instruction.op.rawValue, forKey: .op)
      try container.encode(instruction.instructionArguments, forKey: .args)
      try container.encode(instruction.instructionDestination, forKey: .dest)
      try container.encode(instruction.instructionType, forKey: .type)
    case let instruction as BrilConstant:
      try container.encode("const", forKey: .op)
      try container.encode(instruction.instructionDestination, forKey: .dest)
      try container.encode(instruction.instructionType, forKey: .type)
      switch instruction.value {
      case .bool(let value):
        try container.encode(value, forKey: .value)
      case .int(let value):
        try container.encode(value, forKey: .value)
      }
    case let instruction as BrilJmp:
      try container.encode("jmp", forKey: .op)
      try container.encode([instruction.label], forKey: .labels)
    case let instruction as BrilBr:
      try container.encode("br", forKey: .op)
      try container.encode(instruction.instructionArguments, forKey: .args)
      try container.encode(
        [instruction.trueLabel, instruction.falseLabel],
        forKey: .labels)
    case let instruction as BrilCall:
      try container.encode("call", forKey: .op)
      try container.encode([instruction.function], forKey: .funcs)
      try container.encode(instruction.instructionArguments, forKey: .args)
      if let dest = instruction.instructionDestination {
        try container.encode(dest, forKey: .dest)
      }
      if let type = instruction.instructionType {
        try container.encode(type, forKey: .type)
      }
    case let instruction as BrilRet:
      try container.encode("ret", forKey: .op)
      if let arg = instruction.argument {
        try container.encode([arg], forKey: .args)
      }
    case let instruction as BrilID:
      try container.encode("id", forKey: .op)
      try container.encode(instruction.instructionArguments, forKey: .args)
      try container.encode(instruction.instructionDestination, forKey: .dest)
      try container.encode(instruction.instructionType, forKey: .type)
    case let instruction as BrilPrint:
      try container.encode("print", forKey: .op)
      try container.encode(instruction.instructionArguments, forKey: .args)
    case is BrilNop:
      try container.encode("nop", forKey: .op)
    case let instruction as BrilPhi:
      try container.encode("phi", forKey: .op)
      try container.encode(instruction.instructionArguments, forKey: .args)
      try container.encode(instruction.labels, forKey: .labels)
      try container.encode(instruction.instructionDestination, forKey: .dest)
      try container.encode(instruction.instructionType, forKey: .type)
    case let instruction as BrilAlloc:
      try container.encode("alloc", forKey: .op)
      try container.encode(instruction.instructionArguments, forKey: .args)
      try container.encode(instruction.instructionDestination, forKey: .dest)
      try container.encode(instruction.instructionType, forKey: .type)
    case let instruction as BrilStore:
      try container.encode("store", forKey: .op)
      try container.encode(instruction.instructionArguments, forKey: .args)
    case let instruction as BrilPtrAdd:
      try container.encode("ptradd", forKey: .op)
      try container.encode(instruction.instructionArguments, forKey: .args)
      try container.encode(instruction.instructionDestination, forKey: .dest)
      try container.encode(instruction.instructionType, forKey: .type)
    case let instruction as BrilLoad:
      try container.encode("load", forKey: .op)
      try container.encode(instruction.instructionArguments, forKey: .args)
      try container.encode(instruction.instructionDestination, forKey: .dest)
      try container.encode(instruction.instructionType, forKey: .type)
    default:
      fatalError("")
    }
  }
}
