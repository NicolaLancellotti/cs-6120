public struct LVNConfiguration {
  public let canonicalise: Bool
  public let copyPropagation: Bool
  public let constantPropagation: Bool
  public let constantFolding: Bool
  public let tryMakeID: Bool

  public init(
    canonicalise: Bool = false,
    copyPropagation: Bool = false,
    constantPropagation: Bool = false,
    constantFolding: Bool = false,
    tryMakeID: Bool = false
  ) {
    self.canonicalise = canonicalise
    self.copyPropagation = copyPropagation
    self.constantPropagation = constantPropagation
    self.constantFolding = constantFolding
    self.tryMakeID = tryMakeID
  }
}
