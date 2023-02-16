import Common
import IR

public class Block {
  public let label: Label
  public let generatedLabel: Bool
  public var instructions: [any BrilInstruction]

  public var successors = Set<Block>()
  public var predecessors = Set<Block>()

  public init(
    label: Label,
    generatedLabel: Bool,
    instructions: [any BrilInstruction]
  ) {
    self.label = label
    self.generatedLabel = generatedLabel
    self.instructions = instructions
  }
}

extension Block: Hashable {
  public static func == (lhs: Block, rhs: Block) -> Bool {
    lhs.label == rhs.label
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(label)
  }
}
