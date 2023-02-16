import CFG
import Common

public struct DataFlowData<Domain: Default> {
  var inValue: [Block: Domain]
  var outValue: [Block: Domain]

  var blocksOrder: [Block]
  let asTextFunction: (Domain) -> String
  var forward: Bool

  internal init(
    inValue: [Block: Domain],
    outValue: [Block: Domain],
    forward: Bool,
    blocksOrder: [Block],
    asTextFunction: @escaping (Domain) -> String
  ) {
    self.inValue = inValue
    self.outValue = outValue
    self.forward = forward
    self.blocksOrder = blocksOrder
    self.asTextFunction = asTextFunction
  }
}
