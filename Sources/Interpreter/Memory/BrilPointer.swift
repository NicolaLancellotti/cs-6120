import IR

struct BrilPointer {
  let buffer: UnsafeMutableRawBufferPointer
  let index: Int
  var pointeeType: BrilType

  private init(buffer: UnsafeMutableRawBufferPointer, index: Int, pointeeType: BrilType) {
    self.buffer = buffer
    self.index = index
    self.pointeeType = pointeeType
  }

}

// MARK: - Buffer Views

extension BrilPointer {

  var referenceCountAddress: UnsafeMutableRawPointer {
    buffer.baseAddress!
  }

  var intBuffer: UnsafeMutableBufferPointer<Int64> {
    buffer.assumingMemoryBound(to: Int64.self)
  }

  var boolBuffer: UnsafeMutableBufferPointer<Bool> {
    buffer.assumingMemoryBound(to: Bool.self)
  }

  var pointerBuffer: UnsafeMutableBufferPointer<BrilPointer?> {
    buffer.assumingMemoryBound(to: BrilPointer?.self)
  }

  var rawPointer: UnsafeMutableRawPointer {
    switch pointeeType {
    case .int: UnsafeMutableRawPointer(intBuffer.baseAddress!.advanced(by: index))
    case .bool: UnsafeMutableRawPointer(boolBuffer.baseAddress!.advanced(by: index))
    case .pointer: UnsafeMutableRawPointer(pointerBuffer.baseAddress!.advanced(by: index))
    }
  }

}

// MARK: - Operations

extension BrilPointer {

  func deinitializeAndDeallocate() {
    switch pointeeType {
    case .int: intBuffer.deinitialize()
    case .bool: boolBuffer.deinitialize()
    case .pointer: pointerBuffer.deinitialize()
    }
    buffer.deallocate()
  }

  static func allocate(count: Int64, pointeeType: BrilType) -> BrilPointer {
    let count = Int(count)

    func allocate() -> UnsafeMutableRawBufferPointer {
      switch pointeeType {
      case .int:
        let pointer = UnsafeMutableBufferPointer<Int64>.allocate(capacity: count)
        pointer.initialize(repeating: 0)
        return UnsafeMutableRawBufferPointer(pointer)
      case .bool:
        let pointer = UnsafeMutableBufferPointer<Bool>.allocate(capacity: count)
        pointer.initialize(repeating: false)
        return UnsafeMutableRawBufferPointer(pointer)
      case .pointer:
        let pointer = UnsafeMutableBufferPointer<BrilPointer?>.allocate(capacity: count)
        pointer.initialize(repeating: nil)
        return UnsafeMutableRawBufferPointer(pointer)
      }
    }

    let pointer = BrilPointer(
      buffer: allocate(),
      index: 0,
      pointeeType: pointeeType)
    ReferenceCount.checkZero(pointer)
    return pointer
  }

  func load() -> RuntimeValue {
    switch pointeeType {
    case .int: .primitive(.int(intBuffer[index]))
    case .bool: .primitive(.bool(boolBuffer[index]))
    case .pointer: .pointer(pointerBuffer[index]!)
    }
  }

  func ptradd(value: Int64) -> RuntimeValue {
    .pointer(
      BrilPointer(
        buffer: buffer,
        index: index + Int(value),
        pointeeType: pointeeType))
  }

  func store(value: RuntimeValue) {
    ReferenceCount.retain(value)
    switch value {
    case .primitive(let value):
      switch value {
      case .int(let value): intBuffer[index] = value
      case .bool(let value): boolBuffer[index] = value
      }
    case .pointer(let value):
      pointerBuffer[index].map { ReferenceCount.release($0) }
      pointerBuffer[index] = value
    }
  }

}
