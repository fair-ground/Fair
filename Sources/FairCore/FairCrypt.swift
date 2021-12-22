/**
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
import Swift
import Foundation

@available(macOS 10.14, iOS 12.0, *)
public extension Data {
    /// Returns the hex format for this data
    @inlinable func hex() -> String {
        map { String(format: "%02hhx", $0) }.joined()
    }

    /// Calculate the Adler32 checksum of the data.
    @inlinable func adler32() -> Adler32 {
        var res = Adler32()
        res.advance(withChunk: self)
        return res
    }

    /// Calculate the Crc32 checksum of the data.
    @inlinable func crc32() -> Crc32 {
        var res = Crc32()
        res.advance(withChunk: self)
        return res
    }
}

/// An actor that consumera data, such as a hashing function
public protocol DataConsumer : Actor {
    func update(data: Data)
}

#if canImport(CommonCrypto)
import CommonCrypto

extension Data {
    @available(*, deprecated, message: "known to be insecure")
    @inlinable public func sha1() -> Data {
        var digest = [UInt8](repeating: 0, count:Int(CC_SHA1_DIGEST_LENGTH))
        _ = withUnsafeBytes { CC_SHA1($0.baseAddress, CC_LONG(self.count), &digest) }
        return Data(digest)
    }

    @inlinable public func sha256() -> Data {
        var digest = [UInt8](repeating: 0, count:Int(CC_SHA256_DIGEST_LENGTH))
        _ = withUnsafeBytes { CC_SHA256($0.baseAddress, CC_LONG(self.count), &digest) }
        return Data(digest)
    }

    @inlinable public func sha512() -> Data {
        var digest = [UInt8](repeating: 0, count:Int(CC_SHA512_DIGEST_LENGTH))
        _ = withUnsafeBytes { CC_SHA512($0.baseAddress, CC_LONG(self.count), &digest) }
        return Data(digest)
    }
}

/// An actor that can keep a running hash of a stream of bytes.
public final actor SHA256Hasher : DataConsumer {
    @usableFromInline var context: CC_SHA256_CTX

    public init() {
        var ctx = CC_SHA256_CTX()
        CC_SHA256_Init(&ctx)
        self.context = ctx
    }

    /// Updates the hash with the given array
    @inlinable public func update(bytes: [UInt8]) {
        CC_SHA256_Update(&context, bytes, CC_LONG(bytes.count))
    }

    /// Updates the hash with the given data
    @inlinable public func update(data: Data) {
        data.withUnsafeBytes { bytes in
            _ = CC_SHA256_Update(&context, bytes.baseAddress, CC_LONG(bytes.count))
        }
    }

    /// Complete the hash and return the digest data
    @inlinable public func final() -> Data {
        var digest = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        CC_SHA256_Final(&digest, &context)
        CC_SHA256_Init(&context)
        return Data(digest)
    }

    /// Clear the current hash buffer and ready it for re-use
    @inlinable public func reset() {
        CC_SHA256_Init(&context)
    }
}

#endif


@available(macOS 10.14, iOS 12.0, *)
public struct Crc32: CustomStringConvertible {
    private static let zLibCrc32: ZLibCrc32FuncPtr? = loadCrc32fromZLib()

    public init() {}

    private typealias ZLibCrc32FuncPtr = @convention(c) (
        _ cks:  UInt32,
        _ buf:  UnsafePointer<UInt8>,
        _ len:  UInt32
    ) -> UInt32

    public var checksum: UInt32 = 0

    public mutating func advance(withChunk chunk: Data) {
        if let fastCrc32 = Crc32.zLibCrc32 {
            checksum = chunk.withUnsafeBytes({ (ptr: UnsafePointer<UInt8>) -> UInt32 in
                return fastCrc32(checksum, ptr, UInt32(chunk.count))
            })
        } else {
            checksum = slowCrc32(start: checksum, data: chunk)
        }
    }

    public var description: String {
        return String(format: "%08x", checksum)
    }

    private static func loadCrc32fromZLib() -> ZLibCrc32FuncPtr? {
        #if os(Windows)
        return nil
        #else
        guard let libz = dlopen("/usr/lib/libz.dylib", RTLD_NOW) else { return nil }
        guard let fptr = dlsym(libz, "crc32") else { return nil }
        return unsafeBitCast(fptr, to: ZLibCrc32FuncPtr.self)
        #endif
    }

    private func slowCrc32(start: UInt32, data: Data) -> UInt32 {
        return ~data.reduce(~start) { (crc: UInt32, next: UInt8) -> UInt32 in
            let tableOffset = (crc ^ UInt32(next)) & 0xff
            return lookUpTable[Int(tableOffset)] ^ crc >> 8
        }
    }

    /// Lookup table for faster crc32 calculation.
    /// table source: http://web.mit.edu/freebsd/head/sys/libkern/crc32.c
    private let lookUpTable: [UInt32] = [
        0x00000000, 0x77073096, 0xee0e612c, 0x990951ba, 0x076dc419, 0x706af48f, 0xe963a535, 0x9e6495a3,
        0x0edb8832, 0x79dcb8a4, 0xe0d5e91e, 0x97d2d988, 0x09b64c2b, 0x7eb17cbd, 0xe7b82d07, 0x90bf1d91,
        0x1db71064, 0x6ab020f2, 0xf3b97148, 0x84be41de, 0x1adad47d, 0x6ddde4eb, 0xf4d4b551, 0x83d385c7,
        0x136c9856, 0x646ba8c0, 0xfd62f97a, 0x8a65c9ec, 0x14015c4f, 0x63066cd9, 0xfa0f3d63, 0x8d080df5,
        0x3b6e20c8, 0x4c69105e, 0xd56041e4, 0xa2677172, 0x3c03e4d1, 0x4b04d447, 0xd20d85fd, 0xa50ab56b,
        0x35b5a8fa, 0x42b2986c, 0xdbbbc9d6, 0xacbcf940, 0x32d86ce3, 0x45df5c75, 0xdcd60dcf, 0xabd13d59,
        0x26d930ac, 0x51de003a, 0xc8d75180, 0xbfd06116, 0x21b4f4b5, 0x56b3c423, 0xcfba9599, 0xb8bda50f,
        0x2802b89e, 0x5f058808, 0xc60cd9b2, 0xb10be924, 0x2f6f7c87, 0x58684c11, 0xc1611dab, 0xb6662d3d,
        0x76dc4190, 0x01db7106, 0x98d220bc, 0xefd5102a, 0x71b18589, 0x06b6b51f, 0x9fbfe4a5, 0xe8b8d433,
        0x7807c9a2, 0x0f00f934, 0x9609a88e, 0xe10e9818, 0x7f6a0dbb, 0x086d3d2d, 0x91646c97, 0xe6635c01,
        0x6b6b51f4, 0x1c6c6162, 0x856530d8, 0xf262004e, 0x6c0695ed, 0x1b01a57b, 0x8208f4c1, 0xf50fc457,
        0x65b0d9c6, 0x12b7e950, 0x8bbeb8ea, 0xfcb9887c, 0x62dd1ddf, 0x15da2d49, 0x8cd37cf3, 0xfbd44c65,
        0x4db26158, 0x3ab551ce, 0xa3bc0074, 0xd4bb30e2, 0x4adfa541, 0x3dd895d7, 0xa4d1c46d, 0xd3d6f4fb,
        0x4369e96a, 0x346ed9fc, 0xad678846, 0xda60b8d0, 0x44042d73, 0x33031de5, 0xaa0a4c5f, 0xdd0d7cc9,
        0x5005713c, 0x270241aa, 0xbe0b1010, 0xc90c2086, 0x5768b525, 0x206f85b3, 0xb966d409, 0xce61e49f,
        0x5edef90e, 0x29d9c998, 0xb0d09822, 0xc7d7a8b4, 0x59b33d17, 0x2eb40d81, 0xb7bd5c3b, 0xc0ba6cad,
        0xedb88320, 0x9abfb3b6, 0x03b6e20c, 0x74b1d29a, 0xead54739, 0x9dd277af, 0x04db2615, 0x73dc1683,
        0xe3630b12, 0x94643b84, 0x0d6d6a3e, 0x7a6a5aa8, 0xe40ecf0b, 0x9309ff9d, 0x0a00ae27, 0x7d079eb1,
        0xf00f9344, 0x8708a3d2, 0x1e01f268, 0x6906c2fe, 0xf762575d, 0x806567cb, 0x196c3671, 0x6e6b06e7,
        0xfed41b76, 0x89d32be0, 0x10da7a5a, 0x67dd4acc, 0xf9b9df6f, 0x8ebeeff9, 0x17b7be43, 0x60b08ed5,
        0xd6d6a3e8, 0xa1d1937e, 0x38d8c2c4, 0x4fdff252, 0xd1bb67f1, 0xa6bc5767, 0x3fb506dd, 0x48b2364b,
        0xd80d2bda, 0xaf0a1b4c, 0x36034af6, 0x41047a60, 0xdf60efc3, 0xa867df55, 0x316e8eef, 0x4669be79,
        0xcb61b38c, 0xbc66831a, 0x256fd2a0, 0x5268e236, 0xcc0c7795, 0xbb0b4703, 0x220216b9, 0x5505262f,
        0xc5ba3bbe, 0xb2bd0b28, 0x2bb45a92, 0x5cb36a04, 0xc2d7ffa7, 0xb5d0cf31, 0x2cd99e8b, 0x5bdeae1d,
        0x9b64c2b0, 0xec63f226, 0x756aa39c, 0x026d930a, 0x9c0906a9, 0xeb0e363f, 0x72076785, 0x05005713,
        0x95bf4a82, 0xe2b87a14, 0x7bb12bae, 0x0cb61b38, 0x92d28e9b, 0xe5d5be0d, 0x7cdcefb7, 0x0bdbdf21,
        0x86d3d2d4, 0xf1d4e242, 0x68ddb3f8, 0x1fda836e, 0x81be16cd, 0xf6b9265b, 0x6fb077e1, 0x18b74777,
        0x88085ae6, 0xff0f6a70, 0x66063bca, 0x11010b5c, 0x8f659eff, 0xf862ae69, 0x616bffd3, 0x166ccf45,
        0xa00ae278, 0xd70dd2ee, 0x4e048354, 0x3903b3c2, 0xa7672661, 0xd06016f7, 0x4969474d, 0x3e6e77db,
        0xaed16a4a, 0xd9d65adc, 0x40df0b66, 0x37d83bf0, 0xa9bcae53, 0xdebb9ec5, 0x47b2cf7f, 0x30b5ffe9,
        0xbdbdf21c, 0xcabac28a, 0x53b39330, 0x24b4a3a6, 0xbad03605, 0xcdd70693, 0x54de5729, 0x23d967bf,
        0xb3667a2e, 0xc4614ab8, 0x5d681b02, 0x2a6f2b94, 0xb40bbe37, 0xc30c8ea1, 0x5a05df1b, 0x2d02ef8d,
    ]
}

@available(macOS 10.14, iOS 12.0, *)
public struct Adler32: CustomStringConvertible {
    private static let zLibAdler32: ZLibAdler32FuncPtr? = loadAdler32fromZLib()

    public init() {}

    // C convention function pointer type matching the signature of `libz::adler32`
    private typealias ZLibAdler32FuncPtr = @convention(c) (
        _ cks:  UInt32,
        _ buf:  UnsafePointer<UInt8>,
        _ len:  UInt32
    ) -> UInt32

    /// Raw checksum. Updated after a every call to `advance(withChunk:)`
    public var checksum: UInt32 = 1

    /// Advance the current checksum with a chunk of data. Designed t be called multiple times.
    /// - parameter chunk: data to advance the checksum
    public mutating func advance(withChunk chunk: Data) {
        if let fastAdler32 = Adler32.zLibAdler32 {
            checksum = chunk.withUnsafeBytes({ (ptr: UnsafePointer<UInt8>) -> UInt32 in
                return fastAdler32(checksum, ptr, UInt32(chunk.count))
            })
        }
        else {
            checksum = slowAdler32(start: checksum, data: chunk)
        }
    }

    public var description: String {
        String(format: "%08x", checksum)
    }

    private static func loadAdler32fromZLib() -> ZLibAdler32FuncPtr? {
        #if os(Windows)
        return nil
        #else
        guard let libz = dlopen("/usr/lib/libz.dylib", RTLD_NOW) else { return nil }
        guard let fptr = dlsym(libz, "adler32") else { return nil }
        return unsafeBitCast(fptr, to: ZLibAdler32FuncPtr.self)
        #endif
    }

    private func slowAdler32(start: UInt32, data: Data) -> UInt32 {
        var s1: UInt32 = start & 0xffff
        var s2: UInt32 = (start >> 16) & 0xffff
        let prime: UInt32 = 65521

        for byte in data {
            s1 += UInt32(byte)
            if s1 >= prime { s1 = s1 % prime }
            s2 += s1
            if s2 >= prime { s2 = s2 % prime }
        }
        return (s2 << 16) | s1
    }
}



@available(macOS 10.14, iOS 12.0, *)
extension Data {
    func withUnsafeBytes<ResultType, ContentType>(_ body: (UnsafePointer<ContentType>) throws -> ResultType) rethrows -> ResultType {
        try self.withUnsafeBytes({ (rawBufferPointer: UnsafeRawBufferPointer) -> ResultType in
            try body(rawBufferPointer.bindMemory(to: ContentType.self).baseAddress!)
        })
    }
}
