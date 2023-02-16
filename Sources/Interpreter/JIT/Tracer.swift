import Common
import IR

struct Tracer {
  let staticArguments: VariableToValue
  let nonstaticParameters: [BrilParameter]
  let returnType: BrilType?

  private(set) var trace = [any BrilInstruction]()
  private var staticVariables = Set<String>()

  init(
    staticArguments: VariableToValue, nonstaticParameters: [BrilParameter], returnType: BrilType?
  ) {
    self.staticArguments = staticArguments
    self.returnType = returnType

    var nonstaticParameters = nonstaticParameters
    if let returnType {
      if case .pointer = returnType {
        // no reference count problems
        fatalError("`pointer` return type unsupported during tracing")
      }
      nonstaticParameters.append(
        BrilParameter(
          name: FunctionBuilder.returnPointerName,
          type: .pointer(returnType)))
    }
    self.nonstaticParameters = nonstaticParameters

    for (variable, value) in staticArguments {
      staticVariables.insert(variable)
      trace.append(BrilConstant(value: value, destination: variable, type: value.type))
    }
  }

  private mutating func updateStaticVariable(instruction: any BrilInstruction) {
    guard let destination = instruction.instructionDestination else {
      return
    }
    if (instruction.instructionArguments.allSatisfy { staticVariables.contains($0) }) {
      staticVariables.insert(destination)
    } else {
      staticVariables.remove(destination)
    }
  }

  mutating func trace(instruction: any BrilInstruction) {
    defer {
      updateStaticVariable(instruction: instruction)
    }
    switch instruction {
    case let instruction as BrilConstant:
      trace.append(instruction)
    case let instruction as BrilOperation:
      trace.append(instruction)
    case let instruction as BrilID:
      trace.append(instruction)
    case is BrilPrint:
      fatalError("`print` unsupported during tracing")
    case is BrilJmp:
      break
    case let instruction as BrilBr:
      guard staticVariables.contains(instruction.argument) else {
        fatalError("`br` argument must be static during tracing")
      }
      break
    case is BrilCall:
      fatalError("`call` unsupported during tracing")
    case let instruction as BrilRet:
      trace.append(instruction)
    case is BrilPhi:
      break
    case is BrilNop:
      break
    case is BrilAlloc:
      fatalError("`alloc` unsupported during tracing")  // no reference count problems
    case let instruction as BrilStore:
      // It is possible to store only Int64 and Bool -> no reference count problems
      trace.append(instruction)
    case let instruction as BrilLoad:
      // It is possible to load only Int64 and Bool -> no reference count problems
      trace.append(instruction)
    case let instruction as BrilPtrAdd:
      trace.append(instruction)
    default: unreachable()
    }
  }
}

extension Tracer: CustomStringConvertible {
  var description: String {
    var string = ""
    for instruction in trace {
      print(instruction, to: &string)
    }
    return string
  }
}
