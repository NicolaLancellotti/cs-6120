import Foundation

enum ReferenceCount {
  static private var referenceCounts = [UnsafeMutableRawPointer: Int]()

  static func retain(_ value: RuntimeValue) {
    guard case .pointer(let pointer) = value else { return }
    referenceCounts[pointer.referenceCountAddress, default: 0] += 1
  }

  static func release(_ value: RuntimeValue) {
    guard case .pointer(let pointer) = value else { return }
    release(pointer)
  }

  static func release(_ pointer: BrilPointer) {
    let rc = referenceCounts[pointer.referenceCountAddress]! - 1
    referenceCounts[pointer.referenceCountAddress] = rc

    guard rc == 0 else { return }

    if case .pointer = pointer.pointeeType {
      for pointer in pointer.pointerBuffer.lazy.compactMap({ $0 }) { release(pointer) }
    }

    pointer.deinitializeAndDeallocate()
  }

}

// MARK: - Checks

extension ReferenceCount {

  static func checkAllZeros() {
    precondition(referenceCounts.values.allSatisfy { $0 == 0 })
  }

  static func checkZero(_ pointer: BrilPointer) {
    precondition(referenceCounts[pointer.referenceCountAddress, default: 0] == 0)
  }

}
