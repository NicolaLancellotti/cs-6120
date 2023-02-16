// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "CS-6120",
  platforms: [
    .macOS(.v13)
  ],
  products: [],
  dependencies: [
    .package(url: "https://github.com/apple/swift-argument-parser", from: "1.2.0")
  ],
  targets: [
    .executableTarget(
      name: "driver",
      dependencies: [
        "Common", "Serialize", "CFG", "Analysis", "Passes", "Interpreter",
        .product(name: "ArgumentParser", package: "swift-argument-parser"),
      ],
      path: "Sources/driver"),
    .target(
      name: "TestUtility",
      dependencies: ["Common", "Passes"],
      path: "Sources/TestUtility"),
    .target(
      name: "Common",
      dependencies: [],
      path: "Sources/Common"),
    .target(
      name: "Serialize",
      dependencies: ["CFG", "Common"],
      path: "Sources/Serialize"),
    .target(
      name: "IR",
      dependencies: ["Common"],
      path: "Sources/IR"),
    .testTarget(
      name: "IRTests",
      dependencies: ["IR"],
      resources: [.process("Resources")]),
    .target(
      name: "CFG",
      dependencies: ["Common", "IR"],
      path: "Sources/CFG"),
    .testTarget(
      name: "CFGTests",
      dependencies: ["CFG"],
      resources: [.process("Resources")]),
    .target(
      name: "Passes",
      dependencies: ["Common", "IR", "CFG", "Analysis"],
      path: "Sources/Passes"),
    .testTarget(
      name: "PassesTests",
      dependencies: ["Passes", "TestUtility"],
      resources: [.process("Resources")]),
    .target(
      name: "Analysis",
      dependencies: ["Common", "IR", "CFG"],
      path: "Sources/Analysis"),
    .testTarget(
      name: "AnalysisTests",
      dependencies: ["Serialize", "Analysis", "TestUtility"],
      resources: [.process("Resources")]),
    .target(
      name: "Interpreter",
      dependencies: ["IR", "CFG", "Common", "LLVM"],
      path: "Sources/Interpreter"),
    .systemLibrary(
      name: "LLVM",
      pkgConfig: "cllvm"),
  ]
)
