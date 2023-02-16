import CFG
import Common
import Foundation

public enum Serialize {

  public static func makeJSON(_ dictionary: [String: some Collection<some Comparable & Encodable>])
    -> String
  {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

    let dictionary = dictionary.mapValues { $0.sorted() }
    guard let data = try? encoder.encode(dictionary),
      let json = String(data: data, encoding: .utf8)
    else {
      return ""
    }

    return json
  }

  public static func makeJSON(_ dictionary: [Label: Set<Block>]) -> String {
    makeJSON(dictionary.mapValues { $0.map(\.label) })
  }
}
