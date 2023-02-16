import Analysis
import IR

public protocol Pass {

  func run(on function: BrilFunction, analysis: Analysis) -> BrilFunction
}
