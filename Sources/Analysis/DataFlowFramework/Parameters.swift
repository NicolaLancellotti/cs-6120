import CFG
import Common

protocol Parameters<Domain> {
  associatedtype Domain: Default & Equatable

  var forward: Bool { get }
  var iterateInDFSOrder: Bool { get }
  var boundaryValue: Domain { get }
  var initialValue: Domain { get }
  func meet(_ values: [Domain]) -> Domain
  mutating func transferFunction(block: Block, value: Domain) -> Domain
  static func text(_ value: Domain) -> String
}

extension Parameters {
  var iterateInDFSOrder: Bool { false }
}
