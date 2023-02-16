import Common

struct Environment {
  private var environment = [VersionedVariable: NumberOrVariable]()
  private var maxVersions = [Variable: Int]()
}

// MARK: - Environment

extension Environment {

  subscript(variable: VersionedVariable) -> NumberOrVariable {
    get {
      environment[variable] ?? .variable(variable)
    }
    set {
      environment[variable] = newValue
    }
  }

}

// MARK: - Environment's variables

extension Environment {
  mutating func resetVariables() -> [Variable: Int] {
    let oldMaxVersion = maxVersions
    maxVersions = [Variable: Int]()
    return oldMaxVersion
  }

  func currentVariable(name: Variable) -> VersionedVariable {
    VersionedVariable(name: name, version: maxVersions[name] ?? 0)
  }

  mutating func makeVariable(withName name: Variable) -> VersionedVariable {
    if let version = maxVersions[name] {
      let version = version + 1
      maxVersions[name] = version
      return VersionedVariable(name: name, version: version)
    } else {
      let version = 0
      maxVersions[name] = version
      return VersionedVariable(name: name, version: version)
    }
  }
}
