/**
 Copyright (c) 2022 Marc Prud'hommeaux

 This program is free software: you can redistribute it and/or modify
 it under the terms of the GNU Affero General Public License as
 published by the Free Software Foundation, either version 3 of the
 License, or (at your option) any later version.

 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU Affero General Public License for more details.

 You should have received a copy of the GNU Affero General Public License
 along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */
import Foundation

/// A handle to some data that maintains its `offset` location and can access subsets of data
public protocol SeekableData : AnyObject {
    typealias Offset = UInt64
    func offset() throws -> Offset
    func seek(to offset: Offset) throws
    func readUIntX<Result: UnsignedInteger>() throws -> Result
    func readData(ofLength length: Offset?) throws -> Data
}

/// SeekableData implementation that flips the data it accesses from big-endian to little endian
public class LittleEndianSeekableData : SeekableData {
    let delegate: SeekableData

    public init(delegate: SeekableData) {
        self.delegate = delegate
    }

    public func readUIntX<Result: UnsignedInteger>() throws -> Result {
        try readNumber(bigEndian: false)
    }

    public func offset() throws -> Offset {
        try delegate.offset()
    }

    public func seek(to offset: Offset) throws {
        try delegate.seek(to: offset)
    }

    public func readData(ofLength length: Offset?) throws -> Data {
        try delegate.readData(ofLength: length)
    }
}

public extension SeekableData {
    func readUIntX<Result: UnsignedInteger>() throws -> Result {
        try readNumber(bigEndian: true)
    }

    /// Reads a number with the given expected memory layout.
    /// - Parameter bigEndian: if true, read in big-endian order, otherwise little-endian
    /// - Returns: the number as read from the data
    fileprivate func readNumber<Result: UnsignedInteger>(bigEndian: Bool) throws -> Result {
        let expected = MemoryLayout<Result>.size

        let slice = try readData(ofLength: .init(expected))

        if slice.count != expected {
            throw CocoaError(.fileReadCorruptFile)
        }

        func buildResult(result: Result, element: Data.Element) -> Result {
            (result << 8) | Result(element)
        }

        if bigEndian {
            return slice.reduce(0, buildResult)
        } else {
            return slice.reversed().reduce(0, buildResult)
        }
    }
}

/// SeekableData implementation that is backed by a `FileHandle`
public class SeekableFileHandle : SeekableData {
    let handle: FileHandle

    public init(_ handle: FileHandle) {
        self.handle = handle
    }

    public func offset() throws -> Offset {
        try handle.offset()
    }

    public func seek(to offset: Offset) throws {
        try handle.seek(toOffset: offset)
    }

    public func readData(ofLength length: Offset?) throws -> Data {
        let d2 = try readData(ofLength: length, async: false)
        return d2

        // sadly, the truly async form is 200x slower than the sync version in debug builds and 86x slower in release builds
        // let d1 = try await readData(ofLength: length, async: true) // 200x slower!!
        // return d1
        // let o = try offset()
        // try await seek(to: o) // move back to seek
        // assert(d1.count == d2.count, "\(d1.count) != \(d2.count)")
        // assert(d1 == d2)
        // return d1
    }

    private func readData(ofLength length: Offset?, async: Bool) throws -> Data {
//        if async {
//            var data = Data()
//            if let length = length {
//                data.reserveCapacity(Int(truncatingIfNeeded: length))
//            }
//
//            // 1.8x slower!
////            return try await handle.bytes.prefix(length.flatMap({ Int(truncatingIfNeeded: $0) }) ?? .max).reduce(into: data, { result, element in
////                result.append(element)
////            })
//
//            for try await byte in handle.bytes { // .dropFirst(.init(try handle.offset())) {
//                data.append(byte)
//                if let length = length, data.count >= length {
//                    return data
//                }
//            }
//            return data
//        } else { // asyncAPIs
            if let length = length {
                return try handle.read(upToCount: Int(truncatingIfNeeded: length)) ?? Data()
            } else {
                return try handle.readToEnd() ?? Data()
            }
//        }
    }
}

/// SeekableData implementation that is backed by an in-memory `Data` instance
public class SeekableDataHandle : SeekableData {
    let data: Data
    private(set) var off: Offset

    public init(_ data: Data) {
        self.off = 0
        self.data = data
    }

    public func offset() -> Offset {
        off
    }

    public func seek(to offset: Offset) throws {
        if offset < 0 || offset >= self.data.count {
            throw CocoaError(.coderInvalidValue)
        }
        self.off = offset
    }

    @available(*, deprecated, message: "unsafe; use validating and throwing form instead")
    public func unsafeRead<T>() -> T {
        readData(ofLength: Offset(MemoryLayout<T>.size))
            .withUnsafeBytes( { $0.load(as: T.self) })
    }

    public func readData(ofLength length: Offset?) -> Data {
        guard let length = length else {
            let remainder = data[off...]
            off += Offset(remainder.count)
            return remainder
        }

        defer { off += length }
        let range = (Offset(data.startIndex) + off)..<(Offset(data.startIndex) + off + length)

        // return data.subdata(in: range) // if we don't wrap, we can get a crash when accessing raw memory: 2022-05-27 14:12:22.072709-0400 xctest[26521:9661824] Swift/UnsafeRawPointer.swift:354: Fatal error: load from misaligned raw pointer
        return data[range]
    }
}

public extension SeekableData {
    /// Reads an unsigned little-endian 8-bit integer
    func readUInt8() throws -> UInt8 {
        try readUIntX()
    }

    /// Reads a signed little-endian 16-bit integer
    func readInt8() throws -> Int8 {
        Int8(bitPattern: try readUInt8())
    }

    /// Reads an unsigned little-endian 16-bit integer
    func readUInt16() throws -> UInt16 {
        try readUIntX()
    }

    /// Reads a signed little-endian 16-bit integer
    func readInt16() throws -> Int16 {
        Int16(bitPattern: try readUInt16())
    }

    /// Reads an unsigned little-endian 32-bit integer
    func readUInt32() throws -> UInt32 {
        try readUIntX()
    }

    /// Reads a signed little-endian 32-bit integer
    func readInt32() throws -> Int32 {
        Int32(bitPattern: try readUInt32())
    }

    func readUInt64() throws -> UInt64 {
        try readUIntX()
    }

    /// Reads a signed little-endian 64-bit integer
    func readInt64() throws -> Int64 {
        Int64(bitPattern: try readUInt64())
    }
}


