import Common

struct VersionedVariable: Comparable, Hashable {
  let name: Variable
  let version: Int

  static func < (lhs: VersionedVariable, rhs: VersionedVariable) -> Bool {
    if lhs.name == rhs.name {
      return lhs.version < rhs.version
    }
    return lhs.name < rhs.name
  }
}
