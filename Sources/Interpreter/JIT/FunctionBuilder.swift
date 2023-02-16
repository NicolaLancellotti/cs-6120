import Common
import IR
import LLVM

enum FunctionBuilder {
  private typealias SymbolTable = [String: LLVMValueRef]
  static let returnPointerName = "@return"

  static func buildFunction(module: LLVMModuleRef, tracer: Tracer, dumpLLVM: Bool) -> String {
    let functionName = makeFunctionName()

    let builder = LLVMCreateBuilder()!
    defer { LLVMDisposeBuilder(builder) }

    // Types
    let pointerType = LLVMPointerType(LLVMInt8Type(), 0)

    // Function
    let returnType = LLVMVoidType()
    var paramTypes = [pointerType]
    let functionType = LLVMFunctionType(returnType, &paramTypes, 1, LLVMBool(0))
    let function = LLVMAddFunction(module, functionName, functionType)

    let entry = LLVMAppendBasicBlock(function, "entry")
    LLVMPositionBuilderAtEnd(builder, entry)

    // Prologue
    do {
      var symbolTable = SymbolTable()

      for (index, argument) in tracer.nonstaticParameters.enumerated() {
        let args = LLVMGetParam(function, 0)
        var indices = [LLVMConstInt(LLVMInt32Type(), UInt64(index), LLVMBool(0))]
        let gep = LLVMBuildGEP2(builder, pointerType, args, &indices, 1, "gep\(index)")
        let argp = LLVMBuildLoad2(builder, pointerType, gep, "\(argument.name)-pointer")

        switch argument.type {
        case .int, .bool:
          symbolTable[argument.name] = LLVMBuildLoad2(
            builder, argument.type.llvm, argp, argument.name)
        case .pointer:
          symbolTable[argument.name] = argp
        }
      }

      // Body
      for instruction in tracer.trace {
        buildInstruction(instruction, builder: builder, symbolTable: &symbolTable)
      }
    }

    if dumpLLVM {
      LLVMDumpModule(module)
    }

    return functionName
  }

  private static func buildInstruction(
    _ instruction: any BrilInstruction,
    builder: LLVMBuilderRef,
    symbolTable: inout SymbolTable
  ) {
    switch instruction {
    case let instruction as BrilConstant:
      symbolTable[instruction.destination] =
        switch instruction.value {
        case .bool(let value): LLVMConstInt(instruction.type.llvm, value ? 1 : 0, LLVMBool(0))
        case .int(let value):
          LLVMConstInt(instruction.type.llvm, UInt64(bitPattern: value), LLVMBool(0))
        }
    case let instruction as BrilOperation:
      let lhs = symbolTable[instruction.arguments[0]]
      let rhs = symbolTable[instruction.arguments[1]]
      symbolTable[instruction.destination] =
        switch instruction.op {
        case .add: LLVMBuildAdd(builder, lhs, rhs, "")
        case .mul: LLVMBuildMul(builder, lhs, rhs, "")
        case .sub: LLVMBuildSub(builder, lhs, rhs, "")
        case .div: LLVMBuildSDiv(builder, lhs, rhs, "")
        case .eq: LLVMBuildICmp(builder, LLVMIntEQ, lhs, rhs, "")
        case .lt: LLVMBuildICmp(builder, LLVMIntSLT, lhs, rhs, "")
        case .gt: LLVMBuildICmp(builder, LLVMIntSGT, lhs, rhs, "")
        case .le: LLVMBuildICmp(builder, LLVMIntSLE, lhs, rhs, "")
        case .ge: LLVMBuildICmp(builder, LLVMIntSGE, lhs, rhs, "")
        case .not: LLVMBuildNot(builder, lhs, "")
        case .and: LLVMBuildAnd(builder, lhs, rhs, "")
        case .or: LLVMBuildOr(builder, lhs, rhs, "")
        }
    case let instruction as BrilID:
      symbolTable[instruction.destination] = symbolTable[instruction.argument]
    case let instruction as BrilRet:
      if let argument = instruction.argument {
        LLVMBuildStore(
          builder, symbolTable[argument], symbolTable[FunctionBuilder.returnPointerName])
      }
      LLVMBuildRetVoid(builder)
    case let instruction as BrilStore:
      LLVMBuildStore(
        builder,
        symbolTable[instruction.value],
        symbolTable[instruction.pointer])
    case let instruction as BrilLoad:
      let value = LLVMBuildLoad2(
        builder,
        instruction.type.llvm,
        symbolTable[instruction.pointer],
        "")
      symbolTable[instruction.destination] = value
    case let instruction as BrilPtrAdd:
      let pointer = symbolTable[instruction.pointer]
      let index = symbolTable[instruction.offset]
      var indices = [index]
      let pointeeType = instruction.type.pointeeType.llvm
      let gep = LLVMBuildGEP2(builder, pointeeType, pointer, &indices, 1, "ptradd_gep")
      symbolTable[instruction.destination] = gep
    case is BrilNop: break
    default: unreachable()
    }
  }
}

extension FunctionBuilder {
  fileprivate static var jitCount = 0

  fileprivate static func makeFunctionName() -> String {
    jitCount += 1
    return "_jit\(jitCount)"
  }
}

extension BrilType {
  fileprivate var llvm: LLVMTypeRef {
    switch self {
    case .int: LLVMInt64Type()
    case .bool: LLVMInt8Type()
    case .pointer(let type): LLVMPointerType(type.llvm, 0)
    }
  }
}
