import CFG
import Common
import IR

public class Interpreter {
  private var cfgs: [String: CFG]
  private let printFunctionDuration: String?

  private let executionEngine: ExecutionEngine
  private var jitFunction: String?
  private var jitStaticArguments: [String]
  private let jitVerbose: Bool

  public init(
    program: BrilProgram,
    jitFunction: String?, jitStaticArguments: [String], jitVerbose: Bool,
    dumpLLVM: Bool, printFunctionDuration: String?
  ) {
    self.executionEngine = ExecutionEngine(dumpLLVM: dumpLLVM)
    self.jitFunction = jitFunction
    self.jitStaticArguments = jitStaticArguments
    self.jitVerbose = jitVerbose
    self.printFunctionDuration = printFunctionDuration
    cfgs = Dictionary(
      uniqueKeysWithValues: program.functions.lazy.map {
        let cfg = CFG(function: $0)
        cfg.addTerminators()
        return ($0.name, cfg)
      }
    )
  }

  public func run(arguments: [String]) {
    defer { ReferenceCount.checkAllZeros() }

    let arguments = parseArguments(arguments)
    var environment = Environment()
    _ = runFunction("main", arguments: arguments, environment: &environment)
  }
}

extension Interpreter {

  fileprivate func parseArguments(_ arguments: [String]) -> [RuntimeValue] {
    let parameters = cfg(functionName: "main").parameters
    return zip(parameters, arguments).lazy.map { parameter, argument in
      switch parameter.type {
      case .int:
        BrilValue.int(Int64(argument).unwrap("Expected an `int` argument, but found `\(argument)`"))
      case .bool:
        switch argument {
        case "true": BrilValue.bool(true)
        case "false": BrilValue.bool(false)
        default: fatalError("Expected a `bool` argument, but found `\(argument)`")
        }
      default:
        fatalError("Expected an `int` or `bool` argument, but found `\(argument)`")
      }
    }.map(RuntimeValue.primitive)
  }

  fileprivate func cfg(functionName: String) -> CFG {
    cfgs[functionName].unwrap("Function `\(functionName)` not found")
  }

  fileprivate func runFunction(
    _ functionName: String,
    arguments: [RuntimeValue],
    environment: inout Environment
  ) -> RuntimeValue? {
    guard functionName != printFunctionDuration else {
      var result: RuntimeValue?

      let (seconds, attoseconds) = ContinuousClock().measure {
        result = runFunctionImpl(functionName, arguments: arguments, environment: &environment)
      }.components
      let secondsString = String(format: "%.9f", Double(seconds) + Double(attoseconds) / 1e18)
      print("Function: \(functionName): \(secondsString) seconds")

      return result
    }

    return runFunctionImpl(functionName, arguments: arguments, environment: &environment)
  }

  fileprivate func runFunctionImpl(
    _ functionName: String,
    arguments: [RuntimeValue],
    environment: inout Environment
  ) -> RuntimeValue? {
    let cfg = cfg(functionName: functionName)
    let parameters = cfg.parameters
    guard parameters.count == arguments.count else {
      fatalError(
        "Function `\(functionName)`, expected \(parameters.count) arguments, but found \(arguments.count)"
      )
    }

    for (parameter, argument) in zip(parameters, arguments) {
      environment[parameter.name] = argument
      if parameter.type != argument.type {
        fatalError("Expected type `\(parameter.type)`, but found \(argument.type)")
      }
    }

    var tracer: Tracer?
    if functionName == jitFunction {
      let staticArguments = Dictionary(
        uniqueKeysWithValues: zip(
          jitStaticArguments, environment.brilValues(of: jitStaticArguments)))
      let nonstaticParameters = parameters.filter { !jitStaticArguments.contains($0.name) }

      if let function = executionEngine[staticArguments] {
        let nonstaticArguments = nonstaticParameters.map { environment[$0.name] }
        let result = executionEngine.run(function: function, nonstaticArguments: nonstaticArguments)
        if jitVerbose { print("JIT") }
        return result
      } else {
        tracer = Tracer(
          staticArguments: staticArguments,
          nonstaticParameters: nonstaticParameters,
          returnType: cfg.returnType)
      }
    }

    defer {
      tracer.map { executionEngine.buildFunction(tracer: $0) }
    }

    var block = cfg.entry
    var predecessor: Label = ""
    while true {
      switch run(block, environment: &environment, predecessor: predecessor, tracer: &tracer) {
      case .jump(let label):
        predecessor = block.label
        block = cfg[label]
      case .return(let value):
        checkType(value?.type, expected: cfg.returnType)
        return value
      }
    }
  }

  fileprivate enum BlockTerminator {
    case jump(Label)
    case `return`(RuntimeValue?)
  }

  fileprivate func run(
    _ block: Block,
    environment: inout Environment,
    predecessor: Label,
    tracer: inout Tracer?
  ) -> BlockTerminator {
    for instruction in block.instructions {
      defer { tracer?.trace(instruction: instruction) }

      switch instruction {
      case let instruction as BrilConstant:
        environment[instruction.destination] = .primitive(instruction.value)
      case let instruction as BrilOperation:
        let arguments = environment.brilValues(of: instruction.arguments)
        let result = computeOperation(
          instruction.op,
          arguments: arguments
        )
        .unwrap(
          "Operator `\(instruction.op.rawValue)` cannot be applied to operands `\(instruction.arguments)`"
        )
        environment[instruction.destination] = .primitive(result)
      case let instruction as BrilID:
        environment[instruction.destination] = environment[instruction.argument]
      case let instruction as BrilPrint:
        print(environment[instruction.arguments].map(\.description).joined(separator: " "))
      case let instruction as BrilJmp:
        return .jump(instruction.label)
      case let instruction as BrilBr:
        let value = environment.valueAsBool(of: instruction.argument)
        return .jump(value ? instruction.trueLabel : instruction.falseLabel)
      case let instruction as BrilCall:
        var calleeEnvironment = Environment()
        let result = runFunction(
          instruction.function,
          arguments: environment[instruction.arguments],
          environment: &calleeEnvironment)
        switch (instruction.destination, result) {
        case (.some(let destination), .some(let result)):
          environment[destination] = result
        case (.none, .none): break
        case (.some, .none):
          fatalError("Call to `\(instruction.function)` does not return a value")
        case (.none, .some):
          fatalError("Result of call to `\(instruction.function)` is unused")
        }
      case let instruction as BrilRet:
        let value = instruction.argument.map { environment[$0] }
        return .return(value)
      case let instruction as BrilPhi:
        let index = instruction.labels.firstIndex(of: predecessor)
          .unwrap("Label `\(predecessor)` not found in phi instruction")
        environment[instruction.destination] = environment[instruction.arguments[index]]
      case is BrilNop:
        break
      case let instruction as BrilAlloc:
        let count = environment.valueAsInt64(of: instruction.capacity)
        let pointeeType = instruction.type.pointeeType
        environment[instruction.destination] = .pointer(
          .allocate(count: count, pointeeType: pointeeType))
      case let instruction as BrilStore:
        let pointer = environment.valueAsPointer(of: instruction.pointer)
        let value = environment[instruction.value]
        checkType(value.type, expected: pointer.pointeeType)
        pointer.store(value: value)
      case let instruction as BrilLoad:
        let pointer = environment.valueAsPointer(of: instruction.pointer)
        checkType(pointer.pointeeType, expected: instruction.type)
        environment[instruction.destination] = pointer.load()
      case let instruction as BrilPtrAdd:
        let pointer = environment.valueAsPointer(of: instruction.pointer)
        let value = environment.valueAsInt64(of: instruction.offset)
        environment[instruction.destination] = pointer.ptradd(value: value)
      default: unreachable()
      }
    }
    unreachable()
  }

  fileprivate func checkType(_ type: BrilType?, expected: BrilType?) {
    if expected != type {
      fatalError(
        "Expected type \(String(describing: expected)), but found `\(String(describing: type))`")
    }
  }
}
