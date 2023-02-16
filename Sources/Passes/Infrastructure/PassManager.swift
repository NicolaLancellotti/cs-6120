import Analysis
import IR

public class PassManager {

  private let passes: [any Pass]

  public init(passes: [any Pass]) {
    self.passes = passes
  }

  public func callAsFunction(_ program: BrilProgram) -> BrilProgram {
    var functions = program.functions
    functions = functions.map { function in
      var function = function
      let analysis = Analysis(function: function)
      for pass in passes {
        function = pass.run(on: function, analysis: analysis)
      }
      return function
    }
    return BrilProgram(functions: functions)
  }
}
