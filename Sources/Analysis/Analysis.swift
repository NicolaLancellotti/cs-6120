import CFG
import Common
import IR

public class Analysis {
  private var function: BrilFunction

  private func resettableLazy<Value>(_ closure: @autoclosure @escaping () -> Value) -> Resettable<
    Lazy<Value>
  > {
    Resettable(wrappedValue: Lazy(wrappedValue: closure()))
  }

  public init(function: BrilFunction) {
    self.function = function
    initAnalysis()
  }

  func initAnalysis() {
    _cfg = resettableLazy(CFG(function: self.function))
    _dominators = resettableLazy(Dominators.run(on: self.function, analysis: self).dictionary())
    _dominanceTree = resettableLazy(DominanceTree.run(on: self.function, analysis: self))
    _dominanceFrontier = resettableLazy(DominanceFrontier.run(on: self.function, analysis: self))
  }

  @Resettable @Lazy
  public private(set) var cfg: CFG = { unreachable() }()

  @Resettable @Lazy
  public private(set) var dominators: [Label: Dominators.Domain] = { unreachable() }()

  @Resettable @Lazy
  public private(set) var dominanceTree: [Label: Set<Block>] = { unreachable() }()

  @Resettable @Lazy
  public private(set) var dominanceFrontier: [Label: Set<Block>] = { unreachable() }()

  public func resetAll(function: BrilFunction) {
    self.function = function
    $cfg.reset()
    $dominators.reset()
    $dominanceTree.reset()
    $dominanceFrontier.reset()
  }
}
