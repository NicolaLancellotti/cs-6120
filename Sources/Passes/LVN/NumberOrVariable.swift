enum NumberOrVariable: Comparable, Hashable {
  case number(Number)
  case variable(VersionedVariable)
}
