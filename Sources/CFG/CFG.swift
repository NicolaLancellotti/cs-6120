import Common
import Foundation
import IR

public class CFG {

  //: MARK - Properties

  public let functionName: String
  public let parameters: [BrilParameter]
  public let returnType: BrilType?
  public private(set) var blocks: [Block]
  private var labelToBlock: [Label: Block]

  //: MARK - Init

  public init(function: BrilFunction) {
    let rawBlocks = CFG.makeRawBlocks(from: function.instructions)
    self.functionName = function.name
    self.parameters = function.parameters
    self.returnType = function.type
    self.blocks = CFG.makeBlocks(from: rawBlocks)
    self.labelToBlock = Dictionary(uniqueKeysWithValues: blocks.lazy.map { ($0.label, $0) })
    CFG.addEdges(to: blocks, labelToBlock: labelToBlock)
  }
}

//: MARK - Public Interface

extension CFG {

  public subscript(label: Label) -> Block {
    labelToBlock[label]!
  }

  @discardableResult
  public func addEntry() -> Block? {
    let entry = self.entry
    guard !entry.predecessors.isEmpty else {
      return nil
    }

    let newEntry = Block(
      label: makeNewName(baseName: "entry"),
      generatedLabel: true,
      instructions: [])
    blocks.insert(newEntry, at: 0)
    newEntry.successors.insert(entry)
    entry.predecessors.insert(newEntry)
    labelToBlock[newEntry.label] = newEntry
    return newEntry
  }

  public var entry: Block {
    blocks[0]
  }

  public func exits() -> some Collection<Block> {
    blocks.filter(\.successors.isEmpty)
  }

  public func addTerminators() {
    func hasTerminator(_ block: Block) -> Bool {
      block.instructions.last?.isTerminator ?? false
    }

    for (index, block) in blocks.enumerated() where !hasTerminator(block) {
      let nextBlock = index + 1 < blocks.count ? blocks[index + 1] : nil

      if let nextBlock, block.successors.contains(nextBlock) {
        block.instructions.append(BrilJmp(label: nextBlock.label))
      } else {
        block.instructions.append(BrilRet(argument: nil))
      }
    }
  }

  public func makeInstructions(insertGeneratedLabels: Bool) -> [any BrilInstruction] {
    blocks.flatMap { block in
      if insertGeneratedLabels {
        return [BrilLabel(label: block.label)] + block.instructions
      } else {
        return block.generatedLabel
          ? block.instructions
          : [BrilLabel(label: block.label)] + block.instructions
      }
    }
  }

  public func makeGraphviz() -> String {
    var string = ""
    string.append("digraph \(functionName) {\n")
    for block in blocks {
      string.append("    \(block.label);\n")
    }

    for block in blocks.sorted(by: { $0.label < $1.label }) {
      for successor in block.successors {
        string.append("    \(block.label) -> \(successor.label)\n")
      }
    }
    string.append("}\n")
    return string.replacingOccurrences(of: ".", with: "_")
  }
}

//: MARK - Private Interface

extension CFG {

  private static func makeRawBlocks(from instructions: [any BrilInstruction])
    -> [[any BrilInstruction]]
  {
    var blocks = [[any BrilInstruction]]()

    func appendBlock(_ block: [any BrilInstruction]) {
      if !block.isEmpty {
        blocks.append(block)
      }
    }

    var block = [any BrilInstruction]()
    for instruction in instructions {
      switch instruction {
      case is BrilLabel:
        appendBlock(block)
        block = [instruction]
      default:
        block.append(instruction)
        if instruction.isTerminator {
          appendBlock(block)
          block = []
        }
      }
    }
    appendBlock(block)
    return blocks
  }

  private static func makeBlocks(from rawBlocks: [[any BrilInstruction]]) -> [Block] {
    func makeBlock(from instructions: [any BrilInstruction], at index: Int) -> Block {
      switch instructions[0] {
      case let instruction as BrilLabel:
        return Block(
          label: instruction.label,
          generatedLabel: false,
          instructions: Array(instructions.dropFirst(1)))
      default:
        return Block(
          label: "b\(index)",
          generatedLabel: true,
          instructions: instructions)
      }
    }

    return rawBlocks.enumerated().map { (index, block) in
      makeBlock(from: block, at: index + 1)
    }
  }

  private static func addEdges(to blocks: [Block], labelToBlock: [Label: Block]) {
    for (index, block) in blocks.enumerated() {
      switch block.instructions.last {
      case let instruction as BrilJmp:
        let successor = labelToBlock[instruction.label]!
        block.successors.insert(successor)
        successor.predecessors.insert(block)
      case let instruction as BrilBr:
        for successor in [instruction.trueLabel, instruction.falseLabel] {
          let successor = labelToBlock[successor]!
          block.successors.insert(successor)
          successor.predecessors.insert(block)
        }
      case is BrilRet:
        break
      default:
        if index != blocks.count - 1 {
          let successor = blocks[index + 1]
          block.successors.insert(successor)
          successor.predecessors.insert(block)
        }
      }
    }
  }

  private func makeNewName(baseName: String) -> String {
    var i = 1
    while true {
      let name = "\(baseName)\(i)"
      if labelToBlock[name] == nil {
        return name
      }
      i += 1
    }
  }
}
