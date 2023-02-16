import CFG
import Common
import Foundation

extension DataFlowData {
  public func text() -> String {
    var string = ""
    for block in blocksOrder {
      """
      \(block.label):
        in:  \(asTextFunction(inValue[defaulting: block]))
        out: \(asTextFunction(outValue[defaulting: block]))\n
      """.write(to: &string)
    }
    return string
  }

  public func dictionary() -> [Label: Domain] {
    let values = (self.forward ? outValue : inValue).lazy
      .map { ($0.key.label, $0.value) }
    return Dictionary(uniqueKeysWithValues: values)
  }
}
