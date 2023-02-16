func setUnion<T>(_ values: [Set<T>]) -> Set<T> {
  values.reduce(into: .init()) { $0.formUnion($1) }
}

func setIntersection<T>(_ values: [Set<T>]) -> Set<T> {
  let first = values.first ?? .init()
  return values.dropFirst(1).reduce(into: first) { $0.formIntersection($1) }
}
