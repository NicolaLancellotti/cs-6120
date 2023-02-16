import CFG
import Common
import IR

public enum ReachingDefinitions: DataFlowAnalysis {

  public typealias Domain = Set<DefBlock>

  public struct DefBlock: Hashable {
    let definition: String
    let block: Label
  }

  public static func run(
    on function: BrilFunction,
    analysis: Analysis
  ) -> DataFlowData<Domain> {
    let functionParameters = Set(
      function.parameters.map(\.name)
        .map { DefBlock(definition: $0, block: "arg") })
    let parameters = ReachingDefinitionsParameters(
      parameters: functionParameters,
      blocks: analysis.cfg.blocks)
    return DataFlowAnalysisFramework.run(
      cfg: analysis.cfg,
      parameters: parameters)
  }
}

private struct ReachingDefinitionsParameters {
  private let parameters: Domain
  private var definitions = [Label: [ReachingDefinitions.DefBlock]]()

  init(parameters: Domain, blocks: [Block]) {
    self.parameters = parameters

    for block in blocks {
      for instruction in block.instructions {
        if let destination = instruction.instructionDestination {
          definitions[defaulting: destination].append(
            .init(
              definition: destination,
              block: block.label))
        }
      }
    }
  }

  // MARK: - Gen Kill

  private var _genKill = [Block: (gen: Domain, kill: Domain)]()

  mutating func genKill(_ block: Block) -> (gen: Domain, kill: Domain) {
    if let value = _genKill[block] {
      return value
    }

    let kill = block.instructions
      .compactMap { $0.instructionDestination }
      .compactMap { dest in definitions[dest] }
      .joined()

    var gen = Domain()

    let instructions = block.instructions
    for i in 0..<instructions.count {
      guard let dest = instructions[i].instructionDestination else { continue }

      var value: Domain = [.init(definition: dest, block: block.label)]

      for j in stride(from: i + 1, to: instructions.count, by: 1) {
        guard let dest = instructions[j].instructionDestination else { continue }
        value.subtract(definitions[dest]!)
      }

      gen.formUnion(value)
    }

    _genKill[block] = (gen: gen, kill: Set(kill))
    return genKill(block)
  }
}

extension ReachingDefinitionsParameters: Parameters {

  typealias Domain = ReachingDefinitions.Domain

  var forward: Bool { true }

  var boundaryValue: Domain { parameters }

  var initialValue: Domain { .init() }

  func meet(_ values: [Domain]) -> Domain { setUnion(values) }

  // Transfer function:
  // f_d(x) = gen_d U (x - kill_d)

  // Transfer function for block:
  // f_B(x) = gen_B U (x - kill_B)

  // where
  // kill_B = kill_1 U kill_2 U ... U kill_n

  // gen_B = gen_n U (gen_n-1 - kill_n) U ... U (gen_1 - kill_2 - kill_3 - ... - kill_n)
  mutating func transferFunction(block: Block, value: Domain) -> Domain {
    let (gen, kill) = genKill(block)
    var value = value.subtracting(kill)
    value.formUnion(gen)
    return value
  }

  static func text(_ value: Domain) -> String {
    "\(value.sorted())"
  }
}

extension ReachingDefinitions.DefBlock: CustomDebugStringConvertible {
  public var debugDescription: String {
    "\(block).\(definition)"
  }
}

extension ReachingDefinitions.DefBlock: Comparable {
  public static func < (lhs: ReachingDefinitions.DefBlock, rhs: ReachingDefinitions.DefBlock)
    -> Bool
  {
    switch lhs.definition != rhs.definition {
    case true: return lhs.definition < rhs.definition
    case false: return lhs.block < rhs.block
    }
  }
}
