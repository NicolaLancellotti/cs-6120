import Analysis
import CFG
import Common
import IR

public struct LVNPass: Pass {

  private let config: LVNConfiguration

  public init(config: LVNConfiguration = LVNConfiguration()) {
    self.config = config
  }

  public func run(on function: BrilFunction, analysis: Analysis) -> BrilFunction {
    for block in analysis.cfg.blocks {
      var tableFiller = TableFiller(config: config)
      let result = tableFiller.run(block: block)
      var reconstructor = InstructionReconstructor(
        config: config,
        table: result.table,
        environment: result.environment,
        maxVersions: result.maxVersions)
      block.instructions = block.instructions.map { reconstructor.run($0) }
    }

    var function = function
    function.instructions = analysis.cfg.makeInstructions(insertGeneratedLabels: false)
    analysis.resetAll(function: function)
    return function
  }

}
