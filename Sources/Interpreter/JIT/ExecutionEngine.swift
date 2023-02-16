import Common
import IR
import LLVM

class ExecutionEngine {
  private let dumpLLVM: Bool
  private var cache = [VariableToValue: Function]()

  init(dumpLLVM: Bool) {
    self.dumpLLVM = dumpLLVM
    LLVMLinkInMCJIT()
    LLVMInitializeNativeTarget()
    LLVMInitializeNativeAsmPrinter()
    LLVMInitializeNativeAsmParser()
  }
}

// MARK: - Build Function

extension ExecutionEngine {

  func buildFunction(tracer: Tracer) {
    func allocate(type: BrilType) -> UnsafeMutableRawPointer? {
      switch type {
      case .int: UnsafeMutableRawPointer(UnsafeMutablePointer<Int64>.allocate(capacity: 1))
      case .bool: UnsafeMutableRawPointer(UnsafeMutablePointer<Bool>.allocate(capacity: 1))
      case .pointer: nil
      }
    }

    let module: LLVMModuleRef = LLVMModuleCreateWithName("")
    let functionName = FunctionBuilder.buildFunction(
      module: module, tracer: tracer,
      dumpLLVM: dumpLLVM)

    var pointers = tracer.nonstaticParameters.map { allocate(type: $0.type) }
    if let type = tracer.returnType {
      pointers[pointers.count - 1] = allocate(type: type)
    }

    var engine: LLVMExecutionEngineRef?
    var error: UnsafeMutablePointer<CChar>?
    if (LLVMCreateMCJITCompilerForModule(&engine, module, nil, 0, &error)) != 0 {
      let stringError = String(cString: error!)
      LLVMDisposeMessage(error)
      fatalError(stringError)
    }

    let address = LLVMGetFunctionAddress(engine, functionName)
    cache[tracer.staticArguments] = Function(
      functionAddress: address,
      returnType: tracer.returnType,
      pointers: pointers,
      engine: engine!)
  }

}

// MARK: - Get Function

extension ExecutionEngine {

  subscript(staticArguments: VariableToValue) -> Function? {
    cache[staticArguments]
  }
}

// MARK: - Run

extension ExecutionEngine {

  func run(
    function: Function,
    nonstaticArguments: [RuntimeValue]
  ) -> RuntimeValue? {
    function.precall(nonstaticArguments: nonstaticArguments)
    function.call()
    return function.postreturn()
  }

}

// MARK: - Function

class Function {
  private typealias FunctionType = @convention(c) (UnsafeMutableRawPointer?) -> Void

  private let jitFunction: FunctionType
  private let returnType: BrilType?
  private var pointers: [UnsafeMutableRawPointer?]
  private var engine: LLVMExecutionEngineRef
  private var arguments: [UnsafeMutableRawPointer?]

  fileprivate init(
    functionAddress: UInt64,
    returnType: BrilType?,
    pointers: [UnsafeMutableRawPointer?],
    engine: LLVMExecutionEngineRef
  ) {
    precondition(functionAddress != 0)
    self.jitFunction = unsafeBitCast(functionAddress, to: Function.FunctionType.self)
    self.returnType = returnType
    self.pointers = pointers
    self.arguments = pointers
    self.engine = engine
  }

  deinit {
    LLVMDisposeExecutionEngine(engine)
    for pointer in pointers {
      pointer?.deallocate()
    }
  }

  fileprivate func precall(nonstaticArguments: [RuntimeValue]) {
    func store<T>(_ value: T, to pointer: UnsafeMutableRawPointer) {
      pointer.assumingMemoryBound(to: T.self).pointee = value
    }

    for (index, value) in nonstaticArguments.enumerated() {
      switch value {
      case .primitive(let value):
        switch value {
        case .bool(let value): store(value, to: arguments[index]!)
        case .int(let value): store(value, to: arguments[index]!)
        }
      case .pointer(let pointer): arguments[index] = pointer.rawPointer
      }
    }
  }

  fileprivate func call() {
    arguments.withUnsafeMutableBytes {
      jitFunction($0.baseAddress!)
    }
  }

  fileprivate func postreturn() -> RuntimeValue? {
    func load<T>(_ pointer: UnsafeMutableRawPointer) -> T {
      pointer.assumingMemoryBound(to: T.self).pointee
    }

    if let returnType = returnType {
      let pointer = arguments.last!!
      let value =
        switch returnType {
        case .int: BrilValue.int(load(pointer))
        case .bool: BrilValue.bool(load(pointer))
        case .pointer: unreachable()
        }
      return RuntimeValue.primitive(value)
    } else {
      return nil
    }
  }
}
