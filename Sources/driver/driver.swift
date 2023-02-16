import Analysis
import ArgumentParser
import CFG
import Common
import Foundation
import IR
import Interpreter
import Passes
import Serialize

// MARK: - DriverError

enum DriverError: Error {
  case encodeJSON
  case readProgram
  case parseArgument
}

// MARK: - Driver

@main
struct Driver: ParsableCommand {
  static let configuration = CommandConfiguration(
    abstract: "Bril compiler.",
    subcommands: [
      ControlFlowGraphCommand.self,
      DeadCodeEliminationCommand.self,
      LocalValueNumberingCommand.self,
      DataFlowAnalysisCommand.self,
      DominatorsCommand.self,
      StaticSingleAssignmentCommand.self,
      InterpreterCommand.self,
    ])
}

extension Driver {
  static func runPass(_ pass: Pass) throws {
    let program = try readProgram()
    let passManager = PassManager(passes: [pass])
    let newProgram = passManager(program)
    guard let json = newProgram.json() else {
      throw DriverError.encodeJSON
    }
    print(json)
  }

  static func forEachFunction(_ closure: (BrilFunction) -> Void) throws {
    try readProgram().functions.forEach(closure)
  }

  static func readProgram(url: URL? = nil) throws -> BrilProgram {
    do {
      let data =
        if let url {
          try Data(contentsOf: url)
        } else {
          try FileHandle.standardInput.readToEnd()
        }
      if let data {
        return try BrilProgram(data: data)
      }
    } catch {}
    throw DriverError.readProgram
  }
}

// MARK: - Control Flow Graph Command

struct ControlFlowGraphCommand: ParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "cfg",
    abstract: "Control Flow Graph.")

  func run() throws {
    try Driver.forEachFunction {
      print(CFG(function: $0).makeGraphviz())
    }
  }
}

// MARK: - Dead Code Elimination Command

struct DeadCodeEliminationCommand: ParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "dce",
    abstract: "Dead Code Elimination.")

  func run() throws {
    try Driver.runPass(DCEPass())
  }
}

// MARK: - Local Value Numbering Command

struct LocalValueNumberingCommand: ParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "lvn",
    abstract: "Local Value Numbering.")

  @Flag(name: [.customShort("c")], help: "Canonicalise.")
  var canonicalise = false

  @Flag(name: [.customShort("p")], help: "Copy and constant propagation.")
  var copyAndConstantPropagation = false

  @Flag(name: [.customShort("f")], help: "Constant folding.")
  var constantFolding = false

  func run() throws {
    let config = LVNConfiguration(
      canonicalise: canonicalise,
      copyPropagation: copyAndConstantPropagation,
      constantPropagation: copyAndConstantPropagation,
      constantFolding: constantFolding)
    let pass = LVNPass(config: config)
    try Driver.runPass(pass)
  }
}

// MARK: - Data Flow Analysis Command

struct DataFlowAnalysisCommand: ParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "df",
    abstract: "Data Flow Analysis.")

  @Argument(
    help: "Data Flow Analysis.\nEither: 'defined', 'live', 'cprop', 'initvar', 'expr' or 'dom'.",
    transform: {
      switch $0 {
      case "defined": return DefinedVariables.self
      case "live": return LiveVariables.self
      case "cprop": return ConstantPropagation.self
      case "initvar": return InitializedVariables.self
      case "expr": return AvailableExpressions.self
      case "dom": return Dominators.self
      default: throw DriverError.parseArgument
      }
    })
  var dataFlowAnalysis: any DataFlowAnalysis.Type

  func run() throws {
    try Driver.forEachFunction {
      let analysis = Analysis(function: $0)
      switch dataFlowAnalysis {
      case let dataFlowAnalysis as Dominators.Type:
        print(
          Serialize.makeJSON(
            dataFlowAnalysis.run(
              on: $0,
              analysis: analysis
            ).dictionary()))
      case let dataFlowAnalysis:
        func run(_ dataFlowAnalysis: (some DataFlowAnalysis).Type, on function: BrilFunction) {
          print(dataFlowAnalysis.run(on: function, analysis: analysis).text(), terminator: "")
        }
        run(dataFlowAnalysis, on: $0)
      }
    }

  }
}

// MARK: - Dominators Command

struct DominatorsCommand: ParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "dom",
    abstract: "Dominators.")

  @Argument(
    help: "Dominator Analysis.\nEither: 'front' or 'tree'.",
    transform: {
      switch $0 {
      case "tree": return DominanceTree.self
      case "front": return DominanceFrontier.self
      default: throw DriverError.parseArgument
      }
    })
  var dominatorsAnalysis: any DominanceAnalysis.Type

  func run() throws {
    try Driver.forEachFunction {
      let analysis = Analysis(function: $0)
      let result = dominatorsAnalysis.run(on: $0, analysis: analysis)
      print(Serialize.makeJSON(result))
    }
  }
}

// MARK: - Static Single Assignment

struct StaticSingleAssignmentCommand: ParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "ssa",
    abstract: "Static Single Assignment.")

  @Argument(
    help: "Static Single Assignment.\nEither: 'to_ssa' or 'from_ssa'.",
    transform: {
      switch $0 {
      case "to_ssa": return ToSSA()
      case "from_ssa": return NaiveFromSSA()
      default: throw DriverError.parseArgument
      }
    })
  var pass: any Pass

  func run() throws {
    try Driver.runPass(pass)
  }
}

// MARK: - Interpreter

struct InterpreterCommand: ParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "interp",
    abstract: "Interpreter.")

  @Option(help: "The json input file.", transform: { URL(fileURLWithPath: $0) })
  var file: URL?

  @Option(
    name: [.customLong("jit-func")],
    help: "The function name to be jitted.")
  var jitFunction: String?

  @Option(
    name: [.customLong("jit-static-argname")],
    help: "An optional string specifying an argument to treat as static.")
  var jitStaticArguments = [String]()

  @Flag(
    name: [.customLong("jit-verbose")],
    help: "Print `JIT` after the execution of a JIT compiled function")
  var jitVerbose: Bool = false

  @Flag(
    name: [.customLong("dump-llvm")],
    help: "Dump the LLVM IR for JIT compiled functions.")
  var dumpLLVM: Bool = false

  @Option(
    name: [.customLong("print-function-duration")],
    help: "The function name to print the duration.")
  var printFunctionDuration: String?

  @Argument(help: "The program arguments.")
  var arguments = [String]()

  func run() throws {
    var program = try Driver.readProgram(url: file)
    let passManager = PassManager(passes: [
      NaiveFromSSA(),
      LVNPass(
        config: LVNConfiguration(
          canonicalise: true,
          copyPropagation: true,
          constantPropagation: true,
          constantFolding: true,
          tryMakeID: true)),
      DCEPass(),
    ])
    program = passManager(program)

    let interpreter = Interpreter(
      program: program,
      jitFunction: jitFunction,
      jitStaticArguments: jitStaticArguments,
      jitVerbose: jitVerbose,
      dumpLLVM: dumpLLVM,
      printFunctionDuration: printFunctionDuration)
    interpreter.run(arguments: arguments)
  }
}
