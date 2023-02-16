#if os(macOS)
  import AppKit

  extension CFG {
    public func viewGraph() {
      guard let data = makeGraphviz().data(using: .utf8) else {
        print("Error")
        return
      }

      let tmpDirectoryPath = NSTemporaryDirectory()
      let dotPath = tmpDirectoryPath.appending("/CS_6120_graph.dot")
      let pdfPath = tmpDirectoryPath.appending("/CS_6120_graph.pdf")

      do {
        try data.write(to: URL(filePath: dotPath))

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/zsh")
        process.arguments = ["--login", "-c", "dot -K dot -T pdf -o \(pdfPath) \(dotPath)"]
        try process.run()
        process.waitUntilExit()
      } catch {
        print("Error: \(error.localizedDescription)")
        return
      }

      NSWorkspace.shared.open(URL(filePath: pdfPath))
    }
  }

#endif
