import Swift
import Foundation

#if canImport(Compression)
import Compression

@available(macOS 10.14, iOS 12.0, *)
public extension Data {
    enum CompressionAlgorithm : String, CaseIterable, Codable {
        case zlib
        case lz4
        case lzma
        case lzfse
    }

    func compress(withAlgorithm algo: CompressionAlgorithm) -> Data? {
        withUnsafeBytes {
            perform((operation: COMPRESSION_STREAM_ENCODE, algorithm: algo.lowLevelType), source: $0, sourceSize: count)
        }
    }

    func decompress(withAlgorithm algo: CompressionAlgorithm) -> Data? {
        withUnsafeBytes {
            perform((operation: COMPRESSION_STREAM_DECODE, algorithm: algo.lowLevelType), source: $0, sourceSize: count)
        }
    }


    func deflate() -> Data? {
        withUnsafeBytes {
            perform((operation: COMPRESSION_STREAM_ENCODE, algorithm: COMPRESSION_ZLIB), source: $0, sourceSize: count)
        }
    }

    func inflate() -> Data? {
        withUnsafeBytes {
            perform((operation: COMPRESSION_STREAM_DECODE, algorithm: COMPRESSION_ZLIB), source: $0, sourceSize: count)
        }
    }

    /// Compresses the data using the deflate algorithm and makes it comply to the zlib format.
    /// Note that this only creates an individual deflated blob; for multi-file zip support,
    /// use `ZipArchive` instead.
    func zip() -> Data? {
        let header = Data([0x78, 0x5e])

        let deflated = self.withUnsafeBytes { (sourcePtr: UnsafePointer<UInt8>) -> Data? in
            let config = (operation: COMPRESSION_STREAM_ENCODE, algorithm: COMPRESSION_ZLIB)
            return perform(config, source: sourcePtr, sourceSize: count, preload: header)
        }

        guard var result = deflated else { return nil }

        var adler = self.adler32().checksum.bigEndian
        result.append(Data(bytes: &adler, count: MemoryLayout<UInt32>.size))

        return result
    }

    /// Decompresses the data using the zlib deflate algorithm.
    /// Note that this only creates an individual inflated blob; for multi-file zip support,
    /// use `ZipArchive` instead.
    func unzip(skipCheckSumValidation: Bool = true) -> Data? {
        // 2 byte header + 4 byte adler32 checksum
        let overhead = 6
        guard count > overhead else { return nil }

        let header: UInt16 = withUnsafeBytes { (ptr: UnsafePointer<UInt16>) -> UInt16 in
            return ptr.pointee.bigEndian
        }

        // check for the deflate stream bit
        guard header >> 8 & 0b1111 == 0b1000 else { return nil }
        // check the header checksum
        guard header % 31 == 0 else { return nil }

        let cresult: Data? = withUnsafeBytes { (ptr: UnsafePointer<UInt8>) -> Data? in
            let source = ptr.advanced(by: 2)
            let config = (operation: COMPRESSION_STREAM_DECODE, algorithm: COMPRESSION_ZLIB)
            return perform(config, source: source, sourceSize: count - overhead)
        }

        guard let inflated = cresult else { return nil }

        if skipCheckSumValidation { return inflated }

        let cksum: UInt32 = withUnsafeBytes { (bytePtr: UnsafePointer<UInt8>) -> UInt32 in
            let last = bytePtr.advanced(by: count - 4)
            return last.withMemoryRebound(to: UInt32.self, capacity: 1) { (intPtr) -> UInt32 in
                return intPtr.pointee.bigEndian
            }
        }

        return cksum == inflated.adler32().checksum ? inflated : nil
    }

    /// Compresses the data using the gzip deflate algorithm.
    func gzip() -> Data? {
        var header = Data([0x1f, 0x8b, 0x08, 0x00]) // magic, magic, deflate, noflags
        var unixtime = UInt32(Date().timeIntervalSince1970).littleEndian
        header.append(Data(bytes: &unixtime, count: MemoryLayout<UInt32>.size))

        header.append(contentsOf: [0x00, 0x03])  // normal compression level, unix file type
        let deflated = self.withUnsafeBytes { (sourcePtr: UnsafePointer<UInt8>) -> Data? in
            let config = (operation: COMPRESSION_STREAM_ENCODE, algorithm: COMPRESSION_ZLIB)
            return perform(config, source: sourcePtr, sourceSize: count, preload: header)
        }

        guard var result = deflated else { return nil }

        // append checksum
        var crc32: UInt32 = self.crc32().checksum.littleEndian
        result.append(Data(bytes: &crc32, count: MemoryLayout<UInt32>.size))

        // append size of original data
        var isize: UInt32 = UInt32(truncatingIfNeeded: count).littleEndian
        result.append(Data(bytes: &isize, count: MemoryLayout<UInt32>.size))

        return result
    }

    /// Decompresses the data with the gunzip inflate algorithm.
    func gunzip() -> Data? {
        // 10 byte header + data +  8 byte footer. See https://tools.ietf.org/html/rfc1952#section-2
        let overhead = 10 + 8
        guard count >= overhead else { return nil }


        typealias GZipHeader = (id1: UInt8, id2: UInt8, cm: UInt8, flg: UInt8, xfl: UInt8, os: UInt8)
        let hdr: GZipHeader = withUnsafeBytes { (ptr: UnsafePointer<UInt8>) -> GZipHeader in
            // +---+---+---+---+---+---+---+---+---+---+
            // |ID1|ID2|CM |FLG|     MTIME     |XFL|OS |
            // +---+---+---+---+---+---+---+---+---+---+
            return (id1: ptr[0], id2: ptr[1], cm: ptr[2], flg: ptr[3], xfl: ptr[8], os: ptr[9])
        }

        typealias GZipFooter = (crc32: UInt32, isize: UInt32)
        let ftr: GZipFooter = withUnsafeBytes { (bptr: UnsafePointer<UInt8>) -> GZipFooter in
            // +---+---+---+---+---+---+---+---+
            // |     CRC32     |     ISIZE     |
            // +---+---+---+---+---+---+---+---+
            return bptr.advanced(by: count - 8).withMemoryRebound(to: UInt32.self, capacity: 2) { ptr in
                return (ptr[0].littleEndian, ptr[1].littleEndian)
            }
        }

        // Wrong gzip magic or unsupported compression method
        guard hdr.id1 == 0x1f && hdr.id2 == 0x8b && hdr.cm == 0x08 else { return nil }

        let has_crc16: Bool = hdr.flg & 0b00010 != 0
        let has_extra: Bool = hdr.flg & 0b00100 != 0
        let has_fname: Bool = hdr.flg & 0b01000 != 0
        let has_cmmnt: Bool = hdr.flg & 0b10000 != 0

        let cresult: Data? = withUnsafeBytes { (ptr: UnsafePointer<UInt8>) -> Data? in
            var pos = 10 ; let limit = count - 8

            if has_extra {
                pos += ptr.advanced(by: pos).withMemoryRebound(to: UInt16.self, capacity: 1) {
                    return Int($0.pointee.littleEndian) + 2 // +2 for xlen
                }
            }
            if has_fname {
                while pos < limit && ptr[pos] != 0x0 { pos += 1 }
                pos += 1 // skip null byte as well
            }
            if has_cmmnt {
                while pos < limit && ptr[pos] != 0x0 { pos += 1 }
                pos += 1 // skip null byte as well
            }
            if has_crc16 {
                pos += 2 // ignoring header crc16
            }

            guard pos < limit else { return nil }
            let config = (operation: COMPRESSION_STREAM_DECODE, algorithm: COMPRESSION_ZLIB)
            return perform(config, source: ptr.advanced(by: pos), sourceSize: limit - pos)
        }

        guard let inflated = cresult else { return nil }
        guard ftr.isize == UInt32(truncatingIfNeeded: inflated.count) else { return nil }
        guard ftr.crc32 == inflated.crc32().checksum else { return nil }
        return inflated
    }
}

@available(macOS 10.14, iOS 12.0, *)
fileprivate extension Data.CompressionAlgorithm {
    var lowLevelType: compression_algorithm {
        switch self {
        case .zlib: return COMPRESSION_ZLIB
        case .lzfse: return COMPRESSION_LZFSE
        case .lz4: return COMPRESSION_LZ4
        case .lzma: return COMPRESSION_LZMA
        }
    }
}

@available(macOS 10.14, iOS 12.0, *)
fileprivate typealias Config = (operation: compression_stream_operation, algorithm: compression_algorithm)


@available(macOS 10.14, iOS 12.0, *)
fileprivate func perform(_ config: Config, source: UnsafePointer<UInt8>, sourceSize: Int, preload: Data = Data()) -> Data? {
    guard config.operation == COMPRESSION_STREAM_ENCODE || sourceSize > 0 else { return nil }

    let streamBase = UnsafeMutablePointer<compression_stream>.allocate(capacity: 1)
    defer { streamBase.deallocate() }
    var stream = streamBase.pointee

    let status = compression_stream_init(&stream, config.operation, config.algorithm)
    guard status != COMPRESSION_STATUS_ERROR else { return nil }
    defer { compression_stream_destroy(&stream) }

    var result = preload
    var flags: Int32 = Int32(COMPRESSION_STREAM_FINALIZE.rawValue)
    let blockLimit = 64 * 1024
    var bufferSize = Swift.max(sourceSize, 64)

    if sourceSize > blockLimit {
        bufferSize = blockLimit
        if config.algorithm == COMPRESSION_LZFSE && config.operation != COMPRESSION_STREAM_ENCODE   {
            // This fixes a bug in Apples lzfse decompressor. it will sometimes fail randomly when the input gets
            // splitted into multiple chunks and the flag is not 0. Even though it should always work with FINALIZE...
            flags = 0
        }
    }

    let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
    defer { buffer.deallocate() }

    stream.dst_ptr  = buffer
    stream.dst_size = bufferSize
    stream.src_ptr  = source
    stream.src_size = sourceSize

    while true {
        switch compression_stream_process(&stream, flags) {
        case COMPRESSION_STATUS_OK:
            guard stream.dst_size == 0 else { return nil }
            result.append(buffer, count: stream.dst_ptr - buffer)
            stream.dst_ptr = buffer
            stream.dst_size = bufferSize

            if flags == 0 && stream.src_size == 0 { // part of the lzfse bugfix above
                flags = Int32(COMPRESSION_STREAM_FINALIZE.rawValue)
            }

        case COMPRESSION_STATUS_END:
            result.append(buffer, count: stream.dst_ptr - buffer)
            return result

        default:
            return nil
        }
    }
}






// ZipArchive is mostly based on ZIPFoundation with some patches (notably https://github.com/weichsel/ZIPFoundation/pull/187 ), which uses the following license:
//
// MIT License
//
// Copyright (c) 2017-2021 Thomas Zoechling (https://www.peakstep.com)
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

// MARK: ZipArchive

/// A sequence of uncompressed or compressed ZIP entries.
///
/// You use an `ZipArchive` to create, read or update ZIP files.
/// To read an existing ZIP file, you have to pass in an existing file `URL` and `AccessMode.read`:
///
///     var archiveURL = URL(fileURLWithPath: "/path/file.zip")
///     var archive = ZipArchive(url: archiveURL, accessMode: .read)
///
/// An `ZipArchive` is a sequence of entries. You can
/// iterate over an archive using a `for`-`in` loop to get access to individual `Entry` objects:
///
///     for entry in archive {
///         print(entry.path)
///     }
///
/// Each `Entry` in an `ZipArchive` is represented by its `path`. You can
/// use `path` to retrieve the corresponding `Entry` from an `ZipArchive` via subscripting:
///
///     let entry = archive['/path/file.txt']
///
/// To create a new `ZipArchive`, pass in a non-existing file URL and `AccessMode.create`. To modify an
/// existing `ZipArchive` use `AccessMode.update`:
///
///     var archiveURL = URL(fileURLWithPath: "/path/file.zip")
///     var archive = ZipArchive(url: archiveURL, accessMode: .update)
///     try archive?.addEntry("test.txt", relativeTo: baseURL, compressionMethod: .deflate)
public final class ZipArchive: Sequence {
    typealias LocalFileHeader = ZipArchive.Entry.LocalFileHeader
    typealias DataDescriptor = ZipArchive.Entry.DataDescriptor
    typealias CentralDirectoryStructure = ZipArchive.Entry.CentralDirectoryStructure

    /// The default chunk size when reading entry data from an archive.
    public static let defaultReadChunkSize = UInt32(16*1024)
    /// The default chunk size when writing entry data to an archive.
    public static let defaultWriteChunkSize = defaultReadChunkSize
    /// The default permissions for newly added entries.
    public static let defaultFilePermissions = UInt16(0o644)
    public static let defaultDirectoryPermissions = UInt16(0o755)
    static let defaultPOSIXBufferSize = defaultReadChunkSize
    static let defaultDirectoryUnitCount = Int64(1)
    static let minDirectoryEndOffset = 22
    static let maxDirectoryEndOffset = 66000
    static let endOfCentralDirectoryStructSignature = 0x06054b50
    static let localFileHeaderStructSignature = 0x04034b50
    static let dataDescriptorStructSignature = 0x08074b50
    static let centralDirectoryStructSignature = 0x02014b50
    static let memoryURLScheme = "memory"

    /// An error that occurs during reading, creating or updating a ZIP file.
    public enum ZipArchiveError: Error {
        /// Thrown when an archive file is either damaged or inaccessible.
        case unreadableArchive
        /// Thrown when an archive is either opened with AccessMode.read or the destination file is unwritable.
        case unwritableArchive
        /// Thrown when the path of an `Entry` cannot be stored in an archive.
        case invalidEntryPath
        /// Thrown when the destination path of a symlink `Entry` cannot be restored.
        case invalidSymlinkDestinationPath
        /// Thrown when an `Entry` can't be stored in the archive with the proposed compression method.
        case invalidCompressionMethod
        /// Thrown when the start of the central directory exceeds `UInt32.max`
        case invalidStartOfCentralDirectoryOffset
        /// Thrown when an archive does not contain the required End of Central Directory Record.
        case missingEndOfCentralDirectoryRecord
        /// Thrown when number of entries on disk exceeds `UInt16.max`
        case invalidNumberOfEntriesOnDisk
        /// Thrown when number of entries in central directory exceeds `UInt16.max`
        case invalidNumberOfEntriesInCentralDirectory
        /// Thrown when an extract, add or remove operation was canceled.
        case cancelledOperation
        /// Thrown when an extract operation was called with zero or negative `bufferSize` parameter.
        case invalidBufferSize
    }

    /// The access mode for an `Archive`.
    public enum AccessMode: UInt {
        /// Indicates that a newly instantiated `Archive` should create its backing file.
        case create
        /// Indicates that a newly instantiated `Archive` should read from an existing backing file.
        case read
        /// Indicates that a newly instantiated `Archive` should update an existing backing file.
        case update
    }

    struct EndOfCentralDirectoryRecord: DataSerializable {
        let endOfCentralDirectorySignature = UInt32(endOfCentralDirectoryStructSignature)
        let numberOfDisk: UInt16
        let numberOfDiskStart: UInt16
        let totalNumberOfEntriesOnDisk: UInt16
        let totalNumberOfEntriesInCentralDirectory: UInt16
        let sizeOfCentralDirectory: UInt32
        let offsetToStartOfCentralDirectory: UInt32
        let zipFileCommentLength: UInt16
        let zipFileCommentData: Data
        static let size = 22
    }

    /// URL of an Archive's backing file.
    public let url: URL
    /// Access mode for an archive file.
    public let accessMode: AccessMode
    var archiveFile: UnsafeMutablePointer<FILE>
    var endOfCentralDirectoryRecord: EndOfCentralDirectoryRecord
    var preferredEncoding: String.Encoding?

    /// Initializes a new ZIP `Archive`.
    ///
    /// You can use this initalizer to create new archive files or to read and update existing ones.
    /// The `mode` parameter indicates the intended usage of the archive: `.read`, `.create` or `.update`.
    /// - Parameters:
    ///   - url: File URL to the receivers backing file.
    ///   - mode: Access mode of the receiver.
    ///   - preferredEncoding: Encoding for entry paths. Overrides the encoding specified in the archive.
    ///                        This encoding is only used when _decoding_ paths from the receiver.
    ///                        Paths of entries added with `addEntry` are always UTF-8 encoded.
    /// - Returns: An archive initialized with a backing file at the passed in file URL and the given access mode
    ///   or `nil` if the following criteria are not met:
    /// - Note:
    ///   - The file URL _must_ point to an existing file for `AccessMode.read`.
    ///   - The file URL _must_ point to a non-existing file for `AccessMode.create`.
    ///   - The file URL _must_ point to an existing file for `AccessMode.update`.
    public init?(url: URL, accessMode mode: AccessMode, preferredEncoding: String.Encoding? = nil) {
        self.url = url
        self.accessMode = mode
        self.preferredEncoding = preferredEncoding
        guard let config = ZipArchive.configureFileBacking(for: url, mode: mode) else {
            return nil
        }
        self.archiveFile = config.file
        self.endOfCentralDirectoryRecord = config.endOfCentralDirectoryRecord
        setvbuf(self.archiveFile, nil, _IOFBF, Int(ZipArchive.defaultPOSIXBufferSize))
    }

    var memoryFile: MemoryFile?

    /// Initializes a new in-memory ZIP `Archive`.
    ///
    /// You can use this initalizer to create new in-memory archive files or to read and update existing ones.
    ///
    /// - Parameters:
    ///   - data: `Data` object used as backing for in-memory archives.
    ///   - mode: Access mode of the receiver.
    ///   - preferredEncoding: Encoding for entry paths. Overrides the encoding specified in the archive.
    ///                        This encoding is only used when _decoding_ paths from the receiver.
    ///                        Paths of entries added with `addEntry` are always UTF-8 encoded.
    /// - Returns: An in-memory archive initialized with passed in backing data.
    /// - Note:
    ///   - The backing `data` _must_ contain a valid ZIP archive for `AccessMode.read` and `AccessMode.update`.
    ///   - The backing `data` _must_ be empty (or omitted) for `AccessMode.create`.
    public init?(data: Data = Data(), accessMode mode: AccessMode, preferredEncoding: String.Encoding? = nil) {
        guard let url = URL(string: "\(ZipArchive.memoryURLScheme)://"),
              let config = ZipArchive.configureMemoryBacking(for: data, mode: mode) else {
                  return nil
              }

        self.url = url
        self.accessMode = mode
        self.preferredEncoding = preferredEncoding
        self.archiveFile = config.file
        self.memoryFile = config.memoryFile
        self.endOfCentralDirectoryRecord = config.endOfCentralDirectoryRecord
    }

    deinit {
        fclose(self.archiveFile)
    }

    public func makeIterator() -> AnyIterator<Entry> {
        let endOfCentralDirectoryRecord = self.endOfCentralDirectoryRecord
        var directoryIndex = Int(endOfCentralDirectoryRecord.offsetToStartOfCentralDirectory)
        var index = 0
        return AnyIterator {
            guard index < Int(endOfCentralDirectoryRecord.totalNumberOfEntriesInCentralDirectory) else { return nil }
            guard let centralDirStruct: CentralDirectoryStructure = Data.readStruct(from: self.archiveFile,
                                                                                    at: directoryIndex) else {
                return nil
            }
            let offset = Int(centralDirStruct.relativeOffsetOfLocalHeader)
            guard let localFileHeader: LocalFileHeader = Data.readStruct(from: self.archiveFile,
                                                                         at: offset) else { return nil }
            var dataDescriptor: DataDescriptor?
            if centralDirStruct.usesDataDescriptor {
                let additionalSize = Int(localFileHeader.fileNameLength) + Int(localFileHeader.extraFieldLength)
                let isCompressed = centralDirStruct.compressionMethod != CompressionMethod.none.rawValue
                let dataSize = isCompressed ? centralDirStruct.compressedSize : centralDirStruct.uncompressedSize
                let descriptorPosition = offset + LocalFileHeader.size + additionalSize + Int(dataSize)
                dataDescriptor = Data.readStruct(from: self.archiveFile, at: descriptorPosition)
            }
            defer {
                directoryIndex += CentralDirectoryStructure.size
                directoryIndex += Int(centralDirStruct.fileNameLength)
                directoryIndex += Int(centralDirStruct.extraFieldLength)
                directoryIndex += Int(centralDirStruct.fileCommentLength)
                index += 1
            }
            return Entry(centralDirectoryStructure: centralDirStruct,
                         localFileHeader: localFileHeader, dataDescriptor: dataDescriptor)
        }
    }

    /// Retrieve the ZIP `Entry` with the given `path` from the receiver.
    ///
    /// - Note: The ZIP file format specification does not enforce unique paths for entries.
    ///   Therefore an archive can contain multiple entries with the same path. This method
    ///   always returns the first `Entry` with the given `path`.
    ///
    /// - Parameter path: A relative file path identifying the corresponding `Entry`.
    /// - Returns: An `Entry` with the given `path`. Otherwise, `nil`.
    public subscript(path: String) -> Entry? {
        if let encoding = preferredEncoding {
            return self.first { $0.path(using: encoding) == path }
        }
        return self.first { $0.path == path }
    }

    // MARK: - Helpers
    struct BackingConfiguration {
        let file: UnsafeMutablePointer<FILE>
        let endOfCentralDirectoryRecord: EndOfCentralDirectoryRecord
        let memoryFile: MemoryFile?

        init(file: UnsafeMutablePointer<FILE>,
             endOfCentralDirectoryRecord: EndOfCentralDirectoryRecord,
             memoryFile: MemoryFile? = nil) {
            self.file = file
            self.endOfCentralDirectoryRecord = endOfCentralDirectoryRecord
            self.memoryFile = memoryFile
        }
    }

    private static func configureFileBacking(for url: URL, mode: AccessMode)
    -> BackingConfiguration? {
        let fileManager = FileManager()
        switch mode {
        case .read:
            let fileSystemRepresentation = fileManager.fileSystemRepresentation(withPath: url.path)
            guard let archiveFile = fopen(fileSystemRepresentation, "rb"),
                  let endOfCentralDirectoryRecord = ZipArchive.scanForEndOfCentralDirectoryRecord(in: archiveFile) else {
                      return nil
                  }
            return BackingConfiguration(file: archiveFile, endOfCentralDirectoryRecord: endOfCentralDirectoryRecord)
        case .create:
            let endOfCentralDirectoryRecord = EndOfCentralDirectoryRecord(numberOfDisk: 0, numberOfDiskStart: 0,
                                                                          totalNumberOfEntriesOnDisk: 0,
                                                                          totalNumberOfEntriesInCentralDirectory: 0,
                                                                          sizeOfCentralDirectory: 0,
                                                                          offsetToStartOfCentralDirectory: 0,
                                                                          zipFileCommentLength: 0,
                                                                          zipFileCommentData: Data())
            do {
                try endOfCentralDirectoryRecord.data.write(to: url, options: .withoutOverwriting)
            } catch { return nil }
            fallthrough
        case .update:
            let fileSystemRepresentation = fileManager.fileSystemRepresentation(withPath: url.path)
            guard let archiveFile = fopen(fileSystemRepresentation, "rb+"),
                  let endOfCentralDirectoryRecord = ZipArchive.scanForEndOfCentralDirectoryRecord(in: archiveFile) else {
                      return nil
                  }
            fseek(archiveFile, 0, SEEK_SET)
            return BackingConfiguration(file: archiveFile, endOfCentralDirectoryRecord: endOfCentralDirectoryRecord)
        }
    }

    static func scanForEndOfCentralDirectoryRecord(in file: UnsafeMutablePointer<FILE>)
    -> EndOfCentralDirectoryRecord? {
        var directoryEnd = 0
        var index = minDirectoryEndOffset
        fseek(file, 0, SEEK_END)
        let archiveLength = ftell(file)
        while directoryEnd == 0 && index < maxDirectoryEndOffset && index <= archiveLength {
            fseek(file, archiveLength - index, SEEK_SET)
            var potentialDirectoryEndTag: UInt32 = UInt32()
            fread(&potentialDirectoryEndTag, 1, MemoryLayout<UInt32>.size, file)
            if potentialDirectoryEndTag == UInt32(endOfCentralDirectoryStructSignature) {
                directoryEnd = archiveLength - index
                return Data.readStruct(from: file, at: directoryEnd)
            }
            index += 1
        }
        return nil
    }
}

extension ZipArchive.EndOfCentralDirectoryRecord {
    var data: Data {
        var endOfCDSignature = self.endOfCentralDirectorySignature
        var numberOfDisk = self.numberOfDisk
        var numberOfDiskStart = self.numberOfDiskStart
        var totalNumberOfEntriesOnDisk = self.totalNumberOfEntriesOnDisk
        var totalNumberOfEntriesInCD = self.totalNumberOfEntriesInCentralDirectory
        var sizeOfCentralDirectory = self.sizeOfCentralDirectory
        var offsetToStartOfCD = self.offsetToStartOfCentralDirectory
        var zipFileCommentLength = self.zipFileCommentLength
        var data = Data()
        withUnsafePointer(to: &endOfCDSignature, { data.append(UnsafeBufferPointer(start: $0, count: 1))})
        withUnsafePointer(to: &numberOfDisk, { data.append(UnsafeBufferPointer(start: $0, count: 1))})
        withUnsafePointer(to: &numberOfDiskStart, { data.append(UnsafeBufferPointer(start: $0, count: 1))})
        withUnsafePointer(to: &totalNumberOfEntriesOnDisk, { data.append(UnsafeBufferPointer(start: $0, count: 1))})
        withUnsafePointer(to: &totalNumberOfEntriesInCD, { data.append(UnsafeBufferPointer(start: $0, count: 1))})
        withUnsafePointer(to: &sizeOfCentralDirectory, { data.append(UnsafeBufferPointer(start: $0, count: 1))})
        withUnsafePointer(to: &offsetToStartOfCD, { data.append(UnsafeBufferPointer(start: $0, count: 1))})
        withUnsafePointer(to: &zipFileCommentLength, { data.append(UnsafeBufferPointer(start: $0, count: 1))})
        data.append(self.zipFileCommentData)
        return data
    }

    init?(data: Data, additionalDataProvider provider: (Int) throws -> Data) {
        guard data.count == ZipArchive.EndOfCentralDirectoryRecord.size else { return nil }
        guard data.scanValue(start: 0) == endOfCentralDirectorySignature else { return nil }
        self.numberOfDisk = data.scanValue(start: 4)
        self.numberOfDiskStart = data.scanValue(start: 6)
        self.totalNumberOfEntriesOnDisk = data.scanValue(start: 8)
        self.totalNumberOfEntriesInCentralDirectory = data.scanValue(start: 10)
        self.sizeOfCentralDirectory = data.scanValue(start: 12)
        self.offsetToStartOfCentralDirectory = data.scanValue(start: 16)
        self.zipFileCommentLength = data.scanValue(start: 20)
        guard let commentData = try? provider(Int(self.zipFileCommentLength)) else { return nil }
        guard commentData.count == Int(self.zipFileCommentLength) else { return nil }
        self.zipFileCommentData = commentData
    }

    init(record: ZipArchive.EndOfCentralDirectoryRecord,
         numberOfEntriesOnDisk: UInt16,
         numberOfEntriesInCentralDirectory: UInt16,
         updatedSizeOfCentralDirectory: UInt32,
         startOfCentralDirectory: UInt32) {
        numberOfDisk = record.numberOfDisk
        numberOfDiskStart = record.numberOfDiskStart
        totalNumberOfEntriesOnDisk = numberOfEntriesOnDisk
        totalNumberOfEntriesInCentralDirectory = numberOfEntriesInCentralDirectory
        sizeOfCentralDirectory = updatedSizeOfCentralDirectory
        offsetToStartOfCentralDirectory = startOfCentralDirectory
        zipFileCommentLength = record.zipFileCommentLength
        zipFileCommentData = record.zipFileCommentData
    }
}


extension ZipArchive {
    /// The number of the work units that have to be performed when
    /// removing `entry` from the receiver.
    ///
    /// - Parameter entry: The entry that will be removed.
    /// - Returns: The number of the work units.
    public func totalUnitCountForRemoving(_ entry: Entry) -> Int64 {
        return Int64(self.endOfCentralDirectoryRecord.offsetToStartOfCentralDirectory
                     - UInt32(entry.localSize))
    }

    func makeProgressForRemoving(_ entry: Entry) -> Progress {
        return Progress(totalUnitCount: self.totalUnitCountForRemoving(entry))
    }

    /// The number of the work units that have to be performed when
    /// reading `entry` from the receiver.
    ///
    /// - Parameter entry: The entry that will be read.
    /// - Returns: The number of the work units.
    public func totalUnitCountForReading(_ entry: Entry) -> Int64 {
        switch entry.type {
        case .file, .symlink:
            return Int64(entry.uncompressedSize)
        case .directory:
            return ZipArchive.defaultDirectoryUnitCount
        }
    }

    func makeProgressForReading(_ entry: Entry) -> Progress {
        return Progress(totalUnitCount: self.totalUnitCountForReading(entry))
    }

    /// The number of the work units that have to be performed when
    /// adding the file at `url` to the receiver.
    /// - Parameter entry: The entry that will be removed.
    /// - Returns: The number of the work units.
    public func totalUnitCountForAddingItem(at url: URL) -> Int64 {
        var count = Int64(0)
        do {
            let type = try FileManager.typeForItem(at: url)
            switch type {
            case .file, .symlink:
                count = Int64(try FileManager.fileSizeForItem(at: url))
            case .directory:
                count = ZipArchive.defaultDirectoryUnitCount
            }
        } catch { count = -1 }
        return count
    }

    func makeProgressForAddingItem(at url: URL) -> Progress {
        return Progress(totalUnitCount: self.totalUnitCountForAddingItem(at: url))
    }
}

extension ZipArchive {
    /// Return all `entries` in the receiver sorted in an order that ensures that contained symlinks can be
    /// restored.
    ///
    /// Directories and files are sorted in the order they are in the archive. Symlinks will be
    /// sorted in the order they need to be extracted. Symlink sorting also takes transitive symlinks into account:
    /// If restoration of a symlink requires prior restoration of another symlink, entries will be sorted accordingly.
    ///
    /// - Returns: The sorted entries.
    /// - Throws: An error if an entry contains malformed path information.
    public func sortedEntries() throws -> [Entry] {
        let entries = Array(self.makeIterator())
        let sortedSymlinks = try sortSymblinks(in: entries)
        let sortedFilesAndDirectories = sortFilesAndDirectories(in: entries)
        return sortedFilesAndDirectories + sortedSymlinks
    }

    // MARK: - Helpers

    private func sortSymblinks(in entries: [ZipArchive.Entry]) throws -> [ZipArchive.Entry] {
        return try entries
            .lazy
            .filter { entry in
                entry.type == .symlink
            }.map { entry -> (entry: ZipArchive.Entry, destinationPath: String) in
                guard let destinationPath = try self.symlinkDestinationPath(for: entry) else {
                    throw ZipArchiveError.invalidSymlinkDestinationPath
                }
                return (entry, destinationPath)
            }.reduce(into: [(entry: Entry, destinationPath: String)]()) { entries, element in
                let unsortedPath = element.entry.path
                let unsortedDestinationPath = element.destinationPath

                for (index, sortedElement) in entries.enumerated() {
                    let sortedPath = sortedElement.entry.path
                    let sortedDestinationPath = sortedElement.destinationPath

                    if unsortedDestinationPath.hasPrefix(sortedDestinationPath) {
                        entries.insert(element, at: entries.index(after: index))
                        return
                    } else if sortedDestinationPath.hasPrefix(unsortedDestinationPath) {
                        entries.insert(element, at: index)
                        return
                    } else if sortedDestinationPath.hasPrefix(unsortedPath) {
                        entries.insert(element, at: index)
                        return
                    } else if unsortedDestinationPath.hasPrefix(sortedPath) {
                        entries.insert(element, at: entries.index(after: index))
                        return
                    }
                }

                entries.append(element)
            }.map { $0.entry }
    }

    private func symlinkDestinationPath(for entry: Entry) throws -> String? {
        var destinationPath: String?
        _ = try self.extract(entry, bufferSize: entry.localFileHeader.compressedSize, skipCRC32: true) { data in
            guard let linkPath = String(data: data, encoding: .utf8) else { return }

            destinationPath = entry
                .path
                .split(separator: "/")
                .dropLast()
                .joined(separator: "/")
            + "/"
            + linkPath
        }
        return destinationPath
    }

    private func sortFilesAndDirectories(in entries: [Entry]) -> [Entry] {
        return entries
            .filter { entry in
                entry.type != .symlink
            }.sorted { (left, right) -> Bool in
                switch (left.type, right.type) {
                case (.file, .directory): return false
                default: return true
                }
            }
    }
}

extension ZipArchive {
    /// Read a ZIP `Entry` from the receiver and write it to `url`.
    ///
    /// - Parameters:
    ///   - entry: The ZIP `Entry` to read.
    ///   - url: The destination file URL.
    ///   - bufferSize: The maximum size of the read buffer and the decompression buffer (if needed).
    ///   - skipCRC32: Optional flag to skip calculation of the CRC32 checksum to improve performance.
    ///   - progress: A progress object that can be used to track or cancel the extract operation.
    /// - Returns: The checksum of the processed content or 0 if the `skipCRC32` flag was set to `true`.
    /// - Throws: An error if the destination file cannot be written or the entry contains malformed content.
    public func extract(_ entry: Entry, to url: URL, bufferSize: UInt32 = defaultReadChunkSize, skipCRC32: Bool = false,
                        progress: Progress? = nil) throws -> CRC32 {
        guard bufferSize > 0 else {
            throw ZipArchiveError.invalidBufferSize
        }
        let fileManager = FileManager()
        var checksum = CRC32(0)
        switch entry.type {
        case .file:
            guard !fileManager.itemExists(at: url) else {
                throw CocoaError(.fileWriteFileExists, userInfo: [NSFilePathErrorKey: url.path])
            }
            try fileManager.createParentDirectoryStructure(for: url)
            let destinationRepresentation = fileManager.fileSystemRepresentation(withPath: url.path)
            guard let destinationFile: UnsafeMutablePointer<FILE> = fopen(destinationRepresentation, "wb+") else {
                throw CocoaError(.fileNoSuchFile)
            }
            defer { fclose(destinationFile) }
            let consumer = { _ = try Data.write(chunk: $0, to: destinationFile) }
            checksum = try self.extract(entry, bufferSize: bufferSize, skipCRC32: skipCRC32,
                                        progress: progress, consumer: consumer)
        case .directory:
            let consumer = { (_: Data) in
                try fileManager.createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
            }
            checksum = try self.extract(entry, bufferSize: bufferSize, skipCRC32: skipCRC32,
                                        progress: progress, consumer: consumer)
        case .symlink:
            guard !fileManager.itemExists(at: url) else {
                throw CocoaError(.fileWriteFileExists, userInfo: [NSFilePathErrorKey: url.path])
            }
            let consumer = { (data: Data) in
                guard let linkPath = String(data: data, encoding: .utf8) else { throw ZipArchiveError.invalidEntryPath }
                try fileManager.createParentDirectoryStructure(for: url)
                try fileManager.createSymbolicLink(atPath: url.path, withDestinationPath: linkPath)
            }
            checksum = try self.extract(entry, bufferSize: bufferSize, skipCRC32: skipCRC32,
                                        progress: progress, consumer: consumer)
        }
        let attributes = FileManager.attributes(from: entry)
        try fileManager.setAttributes(attributes, ofItemAtPath: url.path)
        return checksum
    }

    /// Read a ZIP `Entry` from the receiver and forward its contents to a `Consumer` closure.
    ///
    /// - Parameters:
    ///   - entry: The ZIP `Entry` to read.
    ///   - bufferSize: The maximum size of the read buffer and the decompression buffer (if needed).
    ///   - skipCRC32: Optional flag to skip calculation of the CRC32 checksum to improve performance.
    ///   - progress: A progress object that can be used to track or cancel the extract operation.
    ///   - consumer: A closure that consumes contents of `Entry` as `Data` chunks.
    /// - Returns: The checksum of the processed content or 0 if the `skipCRC32` flag was set to `true`..
    /// - Throws: An error if the destination file cannot be written or the entry contains malformed content.
    public func extract(_ entry: Entry, bufferSize: UInt32 = defaultReadChunkSize, skipCRC32: Bool = false,
                        progress: Progress? = nil, consumer: Consumer) throws -> CRC32 {
        guard bufferSize > 0 else {
            throw ZipArchiveError.invalidBufferSize
        }
        var checksum = CRC32(0)
        let localFileHeader = entry.localFileHeader
        fseek(self.archiveFile, entry.dataOffset, SEEK_SET)
        progress?.totalUnitCount = self.totalUnitCountForReading(entry)
        switch entry.type {
        case .file:
            guard let compressionMethod = CompressionMethod(rawValue: localFileHeader.compressionMethod) else {
                throw ZipArchiveError.invalidCompressionMethod
            }
            switch compressionMethod {
            case .none: checksum = try self.readUncompressed(entry: entry, bufferSize: bufferSize,
                                                             skipCRC32: skipCRC32, progress: progress, with: consumer)
            case .deflate: checksum = try self.readCompressed(entry: entry, bufferSize: bufferSize,
                                                              skipCRC32: skipCRC32, progress: progress, with: consumer)
            }
        case .directory:
            try consumer(Data())
            progress?.completedUnitCount = self.totalUnitCountForReading(entry)
        case .symlink:
            let localFileHeader = entry.localFileHeader
            let size = Int(localFileHeader.compressedSize)
            let data = try Data.readChunk(of: size, from: self.archiveFile)
            checksum = data.crc32(checksum: 0)
            try consumer(data)
            progress?.completedUnitCount = self.totalUnitCountForReading(entry)
        }
        return checksum
    }

    // MARK: - Helpers
    private func readUncompressed(entry: Entry, bufferSize: UInt32, skipCRC32: Bool,
                                  progress: Progress? = nil, with consumer: Consumer) throws -> CRC32 {
        let size = Int(entry.centralDirectoryStructure.uncompressedSize)
        return try Data.consumePart(of: size, chunkSize: Int(bufferSize), skipCRC32: skipCRC32,
                                    provider: { (_, chunkSize) -> Data in
            return try Data.readChunk(of: Int(chunkSize), from: self.archiveFile)
        }, consumer: { (data) in
            if progress?.isCancelled == true { throw ZipArchiveError.cancelledOperation }
            try consumer(data)
            progress?.completedUnitCount += Int64(data.count)
        })
    }

    private func readCompressed(entry: Entry, bufferSize: UInt32, skipCRC32: Bool,
                                progress: Progress? = nil, with consumer: Consumer) throws -> CRC32 {
        let size = Int(entry.centralDirectoryStructure.compressedSize)
        return try Data.decompress(size: size, bufferSize: Int(bufferSize), skipCRC32: skipCRC32,
                                   provider: { (_, chunkSize) -> Data in
            return try Data.readChunk(of: chunkSize, from: self.archiveFile)
        }, consumer: { (data) in
            if progress?.isCancelled == true { throw ZipArchiveError.cancelledOperation }
            try consumer(data)
            progress?.completedUnitCount += Int64(data.count)
        })
    }
}

extension ZipArchive {
    private enum ModifyOperation: Int {
        case remove = -1
        case add = 1
    }

    /// Write files, directories or symlinks to the receiver.
    ///
    /// - Parameters:
    ///   - path: The path that is used to identify an `Entry` within the `Archive` file.
    ///   - baseURL: The base URL of the resource to add.
    ///              The `baseURL` combined with `path` must form a fully qualified file URL.
    ///   - compressionMethod: Indicates the `CompressionMethod` that should be applied to `Entry`.
    ///                        By default, no compression will be applied.
    ///   - bufferSize: The maximum size of the write buffer and the compression buffer (if needed).
    ///   - progress: A progress object that can be used to track or cancel the add operation.
    /// - Throws: An error if the source file cannot be read or the receiver is not writable.
    public func addEntry(with path: String, relativeTo baseURL: URL,
                         compressionMethod: CompressionMethod = .none,
                         bufferSize: UInt32 = defaultWriteChunkSize, progress: Progress? = nil) throws {
        let fileURL = baseURL.appendingPathComponent(path)

        try self.addEntry(with: path, fileURL: fileURL, compressionMethod: compressionMethod,
                          bufferSize: bufferSize, progress: progress)
    }

    /// Write files, directories or symlinks to the receiver.
    ///
    /// - Parameters:
    ///   - path: The path that is used to identify an `Entry` within the `Archive` file.
    ///   - fileURL: An absolute file URL referring to the resource to add.
    ///   - compressionMethod: Indicates the `CompressionMethod` that should be applied to `Entry`.
    ///                        By default, no compression will be applied.
    ///   - bufferSize: The maximum size of the write buffer and the compression buffer (if needed).
    ///   - progress: A progress object that can be used to track or cancel the add operation.
    /// - Throws: An error if the source file cannot be read or the receiver is not writable.
    public func addEntry(with path: String, fileURL: URL, compressionMethod: CompressionMethod = .none,
                         bufferSize: UInt32 = defaultWriteChunkSize, progress: Progress? = nil) throws {
        let fileManager = FileManager()
        guard fileManager.itemExists(at: fileURL) else {
            throw CocoaError(.fileReadNoSuchFile, userInfo: [NSFilePathErrorKey: fileURL.path])
        }
        let type = try FileManager.typeForItem(at: fileURL)
        // symlinks do not need to be readable
        guard type == .symlink || fileManager.isReadableFile(atPath: fileURL.path) else {
            throw CocoaError(.fileReadNoPermission, userInfo: [NSFilePathErrorKey: url.path])
        }
        let modDate = try FileManager.fileModificationDateTimeForItem(at: fileURL)
        let uncompressedSize = type == .directory ? 0 : try FileManager.fileSizeForItem(at: fileURL)
        let permissions = try FileManager.permissionsForItem(at: fileURL)
        var provider: Provider
        switch type {
        case .file:
            let entryFileSystemRepresentation = fileManager.fileSystemRepresentation(withPath: fileURL.path)
            guard let entryFile: UnsafeMutablePointer<FILE> = fopen(entryFileSystemRepresentation, "rb") else {
                throw CocoaError(.fileNoSuchFile)
            }
            defer { fclose(entryFile) }
            provider = { _, _ in return try Data.readChunk(of: Int(bufferSize), from: entryFile) }
            try self.addEntry(with: path, type: type, uncompressedSize: uncompressedSize,
                              modificationDate: modDate, permissions: permissions,
                              compressionMethod: compressionMethod, bufferSize: bufferSize,
                              progress: progress, provider: provider)
        case .directory:
            provider = { _, _ in return Data() }
            try self.addEntry(with: path.hasSuffix("/") ? path : path + "/",
                              type: type, uncompressedSize: uncompressedSize,
                              modificationDate: modDate, permissions: permissions,
                              compressionMethod: compressionMethod, bufferSize: bufferSize,
                              progress: progress, provider: provider)
        case .symlink:
            provider = { _, _ -> Data in
                let linkDestination = try fileManager.destinationOfSymbolicLink(atPath: fileURL.path)
                let linkFileSystemRepresentation = fileManager.fileSystemRepresentation(withPath: linkDestination)
                let linkLength = Int(strlen(linkFileSystemRepresentation))
                let linkBuffer = UnsafeBufferPointer(start: linkFileSystemRepresentation, count: linkLength)
                return Data(buffer: linkBuffer)
            }
            try self.addEntry(with: path, type: type, uncompressedSize: uncompressedSize,
                              modificationDate: modDate, permissions: permissions,
                              compressionMethod: compressionMethod, bufferSize: bufferSize,
                              progress: progress, provider: provider)
        }
    }

    /// Write files, directories or symlinks to the receiver.
    ///
    /// - Parameters:
    ///   - path: The path that is used to identify an `Entry` within the `Archive` file.
    ///   - type: Indicates the `Entry.EntryType` of the added content.
    ///   - uncompressedSize: The uncompressed size of the data that is going to be added with `provider`.
    ///   - modificationDate: A `Date` describing the file modification date of the `Entry`.
    ///                       Default is the current `Date`.
    ///   - permissions: POSIX file permissions for the `Entry`.
    ///                  Default is `0`o`644` for files and symlinks and `0`o`755` for directories.
    ///   - compressionMethod: Indicates the `CompressionMethod` that should be applied to `Entry`.
    ///                        By default, no compression will be applied.
    ///   - bufferSize: The maximum size of the write buffer and the compression buffer (if needed).
    ///   - progress: A progress object that can be used to track or cancel the add operation.
    ///   - provider: A closure that accepts a position and a chunk size. Returns a `Data` chunk.
    /// - Throws: An error if the source data is invalid or the receiver is not writable.
    public func addEntry(with path: String, type: Entry.EntryType, uncompressedSize: UInt32,
                         modificationDate: Date = Date(), permissions: UInt16? = nil,
                         compressionMethod: CompressionMethod = .none, bufferSize: UInt32 = defaultWriteChunkSize,
                         progress: Progress? = nil, provider: Provider) throws {
        guard self.accessMode != .read else { throw ZipArchiveError.unwritableArchive }
        // Directories and symlinks cannot be compressed
        let compressionMethod = type == .file ? compressionMethod : .none
        progress?.totalUnitCount = type == .directory ? ZipArchive.defaultDirectoryUnitCount : Int64(uncompressedSize)
        var endOfCentralDirRecord = self.endOfCentralDirectoryRecord
        var startOfCD = Int(endOfCentralDirRecord.offsetToStartOfCentralDirectory)
        fseek(self.archiveFile, startOfCD, SEEK_SET)
        let existingCentralDirData = try Data.readChunk(of: Int(endOfCentralDirRecord.sizeOfCentralDirectory),
                                                        from: self.archiveFile)
        fseek(self.archiveFile, startOfCD, SEEK_SET)
        let localFileHeaderStart = ftell(self.archiveFile)
        let modDateTime = modificationDate.fileModificationDateTime
        defer { fflush(self.archiveFile) }
        do {
            var localFileHeader = try self.writeLocalFileHeader(path: path, compressionMethod: compressionMethod,
                                                                size: (uncompressedSize, 0), checksum: 0,
                                                                modificationDateTime: modDateTime)
            let (written, checksum) = try self.writeEntry(localFileHeader: localFileHeader, type: type,
                                                          compressionMethod: compressionMethod, bufferSize: bufferSize,
                                                          progress: progress, provider: provider)
            startOfCD = ftell(self.archiveFile)
            fseek(self.archiveFile, localFileHeaderStart, SEEK_SET)
            // Write the local file header a second time. Now with compressedSize (if applicable) and a valid checksum.
            localFileHeader = try self.writeLocalFileHeader(path: path, compressionMethod: compressionMethod,
                                                            size: (uncompressedSize, written),
                                                            checksum: checksum, modificationDateTime: modDateTime)
            fseek(self.archiveFile, startOfCD, SEEK_SET)
            _ = try Data.write(chunk: existingCentralDirData, to: self.archiveFile)
            let permissions = permissions ?? (type == .directory ? ZipArchive.defaultDirectoryPermissions : ZipArchive.defaultFilePermissions)
            let externalAttributes = FileManager.externalFileAttributesForEntry(of: type, permissions: permissions)
            let offset = UInt32(localFileHeaderStart)
            let centralDir = try self.writeCentralDirectoryStructure(localFileHeader: localFileHeader,
                                                                     relativeOffset: offset,
                                                                     externalFileAttributes: externalAttributes)
            if startOfCD > UInt32.max { throw ZipArchiveError.invalidStartOfCentralDirectoryOffset }
            endOfCentralDirRecord = try self.writeEndOfCentralDirectory(centralDirectoryStructure: centralDir,
                                                                        startOfCentralDirectory: UInt32(startOfCD),
                                                                        operation: .add)
            self.endOfCentralDirectoryRecord = endOfCentralDirRecord
        } catch ZipArchiveError.cancelledOperation {
            try rollback(localFileHeaderStart, existingCentralDirData, endOfCentralDirRecord)
            throw ZipArchiveError.cancelledOperation
        }
    }

    /// Remove a ZIP `Entry` from the receiver.
    ///
    /// - Parameters:
    ///   - entry: The `Entry` to remove.
    ///   - bufferSize: The maximum size for the read and write buffers used during removal.
    ///   - progress: A progress object that can be used to track or cancel the remove operation.
    /// - Throws: An error if the `Entry` is malformed or the receiver is not writable.
    public func remove(_ entry: Entry, bufferSize: UInt32 = defaultReadChunkSize, progress: Progress? = nil) throws {
        guard self.accessMode != .read else { throw ZipArchiveError.unwritableArchive }
        let (tempArchive, tempDir) = try self.makeTempArchive()
        defer { tempDir.map { try? FileManager().removeItem(at: $0) } }
        progress?.totalUnitCount = self.totalUnitCountForRemoving(entry)
        var centralDirectoryData = Data()
        var offset = 0
        for currentEntry in self {
            let centralDirectoryStructure = currentEntry.centralDirectoryStructure
            if currentEntry != entry {
                let entryStart = Int(currentEntry.centralDirectoryStructure.relativeOffsetOfLocalHeader)
                fseek(self.archiveFile, entryStart, SEEK_SET)
                let provider: Provider = { (_, chunkSize) -> Data in
                    return try Data.readChunk(of: Int(chunkSize), from: self.archiveFile)
                }
                let consumer: Consumer = {
                    if progress?.isCancelled == true { throw ZipArchiveError.cancelledOperation }
                    _ = try Data.write(chunk: $0, to: tempArchive.archiveFile)
                    progress?.completedUnitCount += Int64($0.count)
                }
                _ = try Data.consumePart(of: Int(currentEntry.localSize), chunkSize: Int(bufferSize),
                                         provider: provider, consumer: consumer)
                let centralDir = CentralDirectoryStructure(centralDirectoryStructure: centralDirectoryStructure,
                                                           offset: UInt32(offset))
                centralDirectoryData.append(centralDir.data)
            } else { offset = currentEntry.localSize }
        }
        let startOfCentralDirectory = ftell(tempArchive.archiveFile)
        _ = try Data.write(chunk: centralDirectoryData, to: tempArchive.archiveFile)
        tempArchive.endOfCentralDirectoryRecord = self.endOfCentralDirectoryRecord
        let endOfCentralDirectoryRecord = try
        tempArchive.writeEndOfCentralDirectory(centralDirectoryStructure: entry.centralDirectoryStructure,
                                               startOfCentralDirectory: UInt32(startOfCentralDirectory),
                                               operation: .remove)
        tempArchive.endOfCentralDirectoryRecord = endOfCentralDirectoryRecord
        self.endOfCentralDirectoryRecord = endOfCentralDirectoryRecord
        fflush(tempArchive.archiveFile)
        try self.replaceCurrentArchive(with: tempArchive)
    }

    // MARK: - Helpers
    func replaceCurrentArchive(with archive: ZipArchive) throws {
        fclose(self.archiveFile)
        if self.isMemoryArchive {
            guard let data = archive.data,
                  let config = ZipArchive.configureMemoryBacking(for: data, mode: .update) else {
                      throw ZipArchiveError.unwritableArchive
                  }

            self.archiveFile = config.file
            self.memoryFile = config.memoryFile
            self.endOfCentralDirectoryRecord = config.endOfCentralDirectoryRecord
        } else {
            let fileManager = FileManager()
            do {
                _ = try fileManager.replaceItemAt(self.url, withItemAt: archive.url)
            } catch {
                _ = try fileManager.removeItem(at: self.url)
                _ = try fileManager.moveItem(at: archive.url, to: self.url)
            }
            let fileSystemRepresentation = fileManager.fileSystemRepresentation(withPath: self.url.path)
            self.archiveFile = fopen(fileSystemRepresentation, "rb+")
        }
    }

    private func writeLocalFileHeader(path: String, compressionMethod: CompressionMethod,
                                      size: (uncompressed: UInt32, compressed: UInt32), checksum: CRC32,
                                      modificationDateTime: (UInt16, UInt16)) throws -> LocalFileHeader {
        // We always set Bit 11 in generalPurposeBitFlag, which indicates an UTF-8 encoded path.
        guard let fileNameData = path.data(using: .utf8) else { throw ZipArchiveError.invalidEntryPath }

        let localFileHeader = LocalFileHeader(versionNeededToExtract: UInt16(20), generalPurposeBitFlag: UInt16(2048),
                                              compressionMethod: compressionMethod.rawValue,
                                              lastModFileTime: modificationDateTime.1,
                                              lastModFileDate: modificationDateTime.0, crc32: checksum,
                                              compressedSize: size.compressed, uncompressedSize: size.uncompressed,
                                              fileNameLength: UInt16(fileNameData.count), extraFieldLength: UInt16(0),
                                              fileNameData: fileNameData, extraFieldData: Data())
        _ = try Data.write(chunk: localFileHeader.data, to: self.archiveFile)
        return localFileHeader
    }

    private func writeEntry(localFileHeader: LocalFileHeader, type: Entry.EntryType,
                            compressionMethod: CompressionMethod, bufferSize: UInt32, progress: Progress? = nil,
                            provider: Provider) throws -> (sizeWritten: UInt32, crc32: CRC32) {
        var checksum = CRC32(0)
        var sizeWritten = UInt32(0)
        switch type {
        case .file:
            switch compressionMethod {
            case .none:
                (sizeWritten, checksum) = try self.writeUncompressed(size: localFileHeader.uncompressedSize,
                                                                     bufferSize: bufferSize,
                                                                     progress: progress, provider: provider)
            case .deflate:
                (sizeWritten, checksum) = try self.writeCompressed(size: localFileHeader.uncompressedSize,
                                                                   bufferSize: bufferSize,
                                                                   progress: progress, provider: provider)
            }
        case .directory:
            _ = try provider(0, 0)
            if let progress = progress { progress.completedUnitCount = progress.totalUnitCount }
        case .symlink:
            (sizeWritten, checksum) = try self.writeSymbolicLink(size: localFileHeader.uncompressedSize,
                                                                 provider: provider)
            if let progress = progress { progress.completedUnitCount = progress.totalUnitCount }
        }
        return (sizeWritten, checksum)
    }

    private func writeUncompressed(size: UInt32, bufferSize: UInt32, progress: Progress? = nil,
                                   provider: Provider) throws -> (sizeWritten: UInt32, checksum: CRC32) {
        var position = 0
        var sizeWritten = 0
        var checksum = CRC32(0)
        while position < size {
            if progress?.isCancelled == true { throw ZipArchiveError.cancelledOperation }
            let readSize = (Int(size) - position) >= bufferSize ? Int(bufferSize) : (Int(size) - position)
            let entryChunk = try provider(Int(position), Int(readSize))
            checksum = entryChunk.crc32(checksum: checksum)
            sizeWritten += try Data.write(chunk: entryChunk, to: self.archiveFile)
            position += Int(bufferSize)
            progress?.completedUnitCount = Int64(sizeWritten)
        }
        return (UInt32(sizeWritten), checksum)
    }

    private func writeCompressed(size: UInt32, bufferSize: UInt32, progress: Progress? = nil,
                                 provider: Provider) throws -> (sizeWritten: UInt32, checksum: CRC32) {
        var sizeWritten = 0
        let consumer: Consumer = { data in sizeWritten += try Data.write(chunk: data, to: self.archiveFile) }
        let checksum = try Data.compress(size: Int(size), bufferSize: Int(bufferSize),
                                         provider: { (position, size) -> Data in
            if progress?.isCancelled == true { throw ZipArchiveError.cancelledOperation }
            let data = try provider(position, size)
            progress?.completedUnitCount += Int64(data.count)
            return data
        }, consumer: consumer)
        return(UInt32(sizeWritten), checksum)
    }

    private func writeSymbolicLink(size: UInt32, provider: Provider) throws -> (sizeWritten: UInt32, checksum: CRC32) {
        let linkData = try provider(0, Int(size))
        let checksum = linkData.crc32(checksum: 0)
        let sizeWritten = try Data.write(chunk: linkData, to: self.archiveFile)
        return (UInt32(sizeWritten), checksum)
    }

    private func writeCentralDirectoryStructure(localFileHeader: LocalFileHeader, relativeOffset: UInt32,
                                                externalFileAttributes: UInt32) throws -> CentralDirectoryStructure {
        let centralDirectory = CentralDirectoryStructure(localFileHeader: localFileHeader,
                                                         fileAttributes: externalFileAttributes,
                                                         relativeOffset: relativeOffset)
        _ = try Data.write(chunk: centralDirectory.data, to: self.archiveFile)
        return centralDirectory
    }

    private func writeEndOfCentralDirectory(centralDirectoryStructure: CentralDirectoryStructure,
                                            startOfCentralDirectory: UInt32,
                                            operation: ModifyOperation) throws -> EndOfCentralDirectoryRecord {
        var record = self.endOfCentralDirectoryRecord
        let countChange = operation.rawValue
        var dataLength = Int(centralDirectoryStructure.extraFieldLength)
        dataLength += Int(centralDirectoryStructure.fileNameLength)
        dataLength += Int(centralDirectoryStructure.fileCommentLength)
        let centralDirectoryDataLengthChange = operation.rawValue * (dataLength + CentralDirectoryStructure.size)
        var updatedSizeOfCentralDirectory = Int(record.sizeOfCentralDirectory)
        updatedSizeOfCentralDirectory += centralDirectoryDataLengthChange
        let numberOfEntriesOnDiskInt = Int(record.totalNumberOfEntriesOnDisk) + countChange
        guard numberOfEntriesOnDiskInt <= UInt16.max else {
            throw ZipArchiveError.invalidNumberOfEntriesOnDisk
        }
        let numberOfEntriesOnDisk = UInt16(numberOfEntriesOnDiskInt)
        let numberOfEntriesInCentralDirectoryInt = Int(record.totalNumberOfEntriesInCentralDirectory) + countChange
        guard numberOfEntriesInCentralDirectoryInt <= UInt16.max else {
            throw ZipArchiveError.invalidNumberOfEntriesInCentralDirectory
        }
        let numberOfEntriesInCentralDirectory = UInt16(numberOfEntriesInCentralDirectoryInt)
        record = EndOfCentralDirectoryRecord(record: record, numberOfEntriesOnDisk: numberOfEntriesOnDisk,
                                             numberOfEntriesInCentralDirectory: numberOfEntriesInCentralDirectory,
                                             updatedSizeOfCentralDirectory: UInt32(updatedSizeOfCentralDirectory),
                                             startOfCentralDirectory: startOfCentralDirectory)
        _ = try Data.write(chunk: record.data, to: self.archiveFile)
        return record
    }

    private func rollback(_ localFileHeaderStart: Int, _ existingCentralDirectoryData: Data,
                          _ endOfCentralDirRecord: EndOfCentralDirectoryRecord) throws {
        fflush(self.archiveFile)
        ftruncate(fileno(self.archiveFile), off_t(localFileHeaderStart))
        fseek(self.archiveFile, localFileHeaderStart, SEEK_SET)
        _ = try Data.write(chunk: existingCentralDirectoryData, to: self.archiveFile)
        _ = try Data.write(chunk: endOfCentralDirRecord.data, to: self.archiveFile)
    }

    func makeTempArchive() throws -> (ZipArchive, URL?) {
        var archive: ZipArchive
        var url: URL?
        if self.isMemoryArchive {
            guard let tempArchive = ZipArchive(data: Data(), accessMode: .create,
                                               preferredEncoding: self.preferredEncoding) else {
                throw ZipArchiveError.unwritableArchive
            }
            archive = tempArchive
        } else {
            let manager = FileManager()
            let tempDir = URL.temporaryReplacementDirectoryURL(for: self)
            let uniqueString = ProcessInfo.processInfo.globallyUniqueString
            let tempArchiveURL = tempDir.appendingPathComponent(uniqueString)
            try manager.createParentDirectoryStructure(for: tempArchiveURL)
            guard let tempArchive = ZipArchive(url: tempArchiveURL, accessMode: .create) else {
                throw ZipArchiveError.unwritableArchive
            }
            archive = tempArchive
            url = tempDir
        }
        return (archive, url)
    }
}

extension ZipArchive {
    var isMemoryArchive: Bool { return self.url.scheme == ZipArchive.memoryURLScheme }
}

extension ZipArchive {
    /// Returns a `Data` object containing a representation of the receiver.
    public var data: Data? { return self.memoryFile?.data }

    static func configureMemoryBacking(for data: Data, mode: AccessMode)
    -> BackingConfiguration? {
        let posixMode: String
        switch mode {
        case .read: posixMode = "rb"
        case .create: posixMode = "wb+"
        case .update: posixMode = "rb+"
        }
        let memoryFile = MemoryFile(data: data)
        guard let archiveFile = memoryFile.open(mode: posixMode) else { return nil }

        switch mode {
        case .read:
            guard let endOfCentralDirectoryRecord = ZipArchive.scanForEndOfCentralDirectoryRecord(in: archiveFile) else {
                return nil
            }

            return BackingConfiguration(file: archiveFile,
                                        endOfCentralDirectoryRecord: endOfCentralDirectoryRecord,
                                        memoryFile: memoryFile)
        case .create:
            let endOfCentralDirectoryRecord = EndOfCentralDirectoryRecord(numberOfDisk: 0, numberOfDiskStart: 0,
                                                                          totalNumberOfEntriesOnDisk: 0,
                                                                          totalNumberOfEntriesInCentralDirectory: 0,
                                                                          sizeOfCentralDirectory: 0,
                                                                          offsetToStartOfCentralDirectory: 0,
                                                                          zipFileCommentLength: 0,
                                                                          zipFileCommentData: Data())
            _ = endOfCentralDirectoryRecord.data.withUnsafeBytes { (buffer: UnsafeRawBufferPointer) in
                fwrite(buffer.baseAddress, buffer.count, 1, archiveFile) // Errors handled during read
            }
            fallthrough
        case .update:
            guard let endOfCentralDirectoryRecord = ZipArchive.scanForEndOfCentralDirectoryRecord(in: archiveFile) else {
                return nil
            }

            fseek(archiveFile, 0, SEEK_SET)
            return BackingConfiguration(file: archiveFile,
                                        endOfCentralDirectoryRecord: endOfCentralDirectoryRecord,
                                        memoryFile: memoryFile)
        }
    }
}

class MemoryFile {
    private(set) var data: Data
    private var offset = 0

    init(data: Data = Data()) {
        self.data = data
    }

    func open(mode: String) -> UnsafeMutablePointer<FILE>? {
        let cookie = Unmanaged.passRetained(self)
        let writable = mode.count > 0 && (mode.first! != "r" || mode.last! == "+")
        let append = mode.count > 0 && mode.first! == "a"
        let result = writable
        ? funopen(cookie.toOpaque(), readStub, writeStub, seekStub, closeStub)
        : funopen(cookie.toOpaque(), readStub, nil, seekStub, closeStub)
        if append {
            fseek(result, 0, SEEK_END)
        }
        return result
    }
}

private extension MemoryFile {
    func readData(buffer: UnsafeMutableRawBufferPointer) -> Int {
        let size = min(buffer.count, data.count-offset)
        let start = data.startIndex
        data.copyBytes(to: buffer.bindMemory(to: UInt8.self), from: start+offset..<start+offset+size)
        offset += size
        return size
    }

    func writeData(buffer: UnsafeRawBufferPointer) -> Int {
        let start = data.startIndex
        if offset < data.count && offset+buffer.count > data.count {
            data.removeSubrange(start+offset..<start+data.count)
        } else if offset > data.count {
            data.append(Data(count: offset-data.count))
        }
        if offset == data.count {
            data.append(buffer.bindMemory(to: UInt8.self))
        } else {
            let start = data.startIndex // May have changed in earlier mutation
            data.replaceSubrange(start+offset..<start+offset+buffer.count, with: buffer.bindMemory(to: UInt8.self))
        }
        offset += buffer.count
        return buffer.count
    }

    func seek(offset: Int, whence: Int32) -> Int {
        var result = -1
        if whence == SEEK_SET {
            result = offset
        } else if whence == SEEK_CUR {
            result = self.offset + offset
        } else if whence == SEEK_END {
            result = data.count + offset
        }
        self.offset = result
        return self.offset
    }
}

private func fileFromCookie(cookie: UnsafeRawPointer) -> MemoryFile {
    return Unmanaged<MemoryFile>.fromOpaque(cookie).takeUnretainedValue()
}

private func closeStub(_ cookie: UnsafeMutableRawPointer?) -> Int32 {
    if let cookie = cookie {
        Unmanaged<MemoryFile>.fromOpaque(cookie).release()
    }
    return 0
}

private func readStub(_ cookie: UnsafeMutableRawPointer?,
                      _ bytePtr: UnsafeMutablePointer<Int8>?,
                      _ count: Int32) -> Int32 {
    guard let cookie = cookie, let bytePtr = bytePtr else { return 0 }
    return Int32(fileFromCookie(cookie: cookie).readData(
        buffer: UnsafeMutableRawBufferPointer(start: bytePtr, count: Int(count))))
}

private func writeStub(_ cookie: UnsafeMutableRawPointer?,
                       _ bytePtr: UnsafePointer<Int8>?,
                       _ count: Int32) -> Int32 {
    guard let cookie = cookie, let bytePtr = bytePtr else { return 0 }
    return Int32(fileFromCookie(cookie: cookie).writeData(
        buffer: UnsafeRawBufferPointer(start: bytePtr, count: Int(count))))
}

private func seekStub(_ cookie: UnsafeMutableRawPointer?,
                      _ offset: fpos_t,
                      _ whence: Int32) -> fpos_t {
    guard let cookie = cookie else { return 0 }
    return fpos_t(fileFromCookie(cookie: cookie).seek(offset: Int(offset), whence: whence))
}

/// The compression method of an `Entry` in a ZIP `Archive`.
public enum CompressionMethod: UInt16 {
    /// Indicates that an `Entry` has no compression applied to its contents.
    case none = 0
    /// Indicates that contents of an `Entry` have been compressed with a zlib compatible Deflate algorithm.
    case deflate = 8
}

/// An unsigned 32-Bit Integer representing a checksum.
public typealias CRC32 = UInt32
/// A custom handler that consumes a `Data` object containing partial entry data.
/// - Parameters:
///   - data: A chunk of `Data` to consume.
/// - Throws: Can throw to indicate errors during data consumption.
public typealias Consumer = (_ data: Data) throws -> Void
/// A custom handler that receives a position and a size that can be used to provide data from an arbitrary source.
/// - Parameters:
///   - position: The current read position.
///   - size: The size of the chunk to provide.
/// - Returns: A chunk of `Data`.
/// - Throws: Can throw to indicate errors in the data source.
public typealias Provider = (_ position: Int, _ size: Int) throws -> Data

/// The lookup table used to calculate `CRC32` checksums.
let crcTable: [CRC32] = [
    0x00000000, 0x77073096, 0xee0e612c, 0x990951ba, 0x076dc419,
    0x706af48f, 0xe963a535, 0x9e6495a3, 0x0edb8832, 0x79dcb8a4,
    0xe0d5e91e, 0x97d2d988, 0x09b64c2b, 0x7eb17cbd, 0xe7b82d07,
    0x90bf1d91, 0x1db71064, 0x6ab020f2, 0xf3b97148, 0x84be41de,
    0x1adad47d, 0x6ddde4eb, 0xf4d4b551, 0x83d385c7, 0x136c9856,
    0x646ba8c0, 0xfd62f97a, 0x8a65c9ec, 0x14015c4f, 0x63066cd9,
    0xfa0f3d63, 0x8d080df5, 0x3b6e20c8, 0x4c69105e, 0xd56041e4,
    0xa2677172, 0x3c03e4d1, 0x4b04d447, 0xd20d85fd, 0xa50ab56b,
    0x35b5a8fa, 0x42b2986c, 0xdbbbc9d6, 0xacbcf940, 0x32d86ce3,
    0x45df5c75, 0xdcd60dcf, 0xabd13d59, 0x26d930ac, 0x51de003a,
    0xc8d75180, 0xbfd06116, 0x21b4f4b5, 0x56b3c423, 0xcfba9599,
    0xb8bda50f, 0x2802b89e, 0x5f058808, 0xc60cd9b2, 0xb10be924,
    0x2f6f7c87, 0x58684c11, 0xc1611dab, 0xb6662d3d, 0x76dc4190,
    0x01db7106, 0x98d220bc, 0xefd5102a, 0x71b18589, 0x06b6b51f,
    0x9fbfe4a5, 0xe8b8d433, 0x7807c9a2, 0x0f00f934, 0x9609a88e,
    0xe10e9818, 0x7f6a0dbb, 0x086d3d2d, 0x91646c97, 0xe6635c01,
    0x6b6b51f4, 0x1c6c6162, 0x856530d8, 0xf262004e, 0x6c0695ed,
    0x1b01a57b, 0x8208f4c1, 0xf50fc457, 0x65b0d9c6, 0x12b7e950,
    0x8bbeb8ea, 0xfcb9887c, 0x62dd1ddf, 0x15da2d49, 0x8cd37cf3,
    0xfbd44c65, 0x4db26158, 0x3ab551ce, 0xa3bc0074, 0xd4bb30e2,
    0x4adfa541, 0x3dd895d7, 0xa4d1c46d, 0xd3d6f4fb, 0x4369e96a,
    0x346ed9fc, 0xad678846, 0xda60b8d0, 0x44042d73, 0x33031de5,
    0xaa0a4c5f, 0xdd0d7cc9, 0x5005713c, 0x270241aa, 0xbe0b1010,
    0xc90c2086, 0x5768b525, 0x206f85b3, 0xb966d409, 0xce61e49f,
    0x5edef90e, 0x29d9c998, 0xb0d09822, 0xc7d7a8b4, 0x59b33d17,
    0x2eb40d81, 0xb7bd5c3b, 0xc0ba6cad, 0xedb88320, 0x9abfb3b6,
    0x03b6e20c, 0x74b1d29a, 0xead54739, 0x9dd277af, 0x04db2615,
    0x73dc1683, 0xe3630b12, 0x94643b84, 0x0d6d6a3e, 0x7a6a5aa8,
    0xe40ecf0b, 0x9309ff9d, 0x0a00ae27, 0x7d079eb1, 0xf00f9344,
    0x8708a3d2, 0x1e01f268, 0x6906c2fe, 0xf762575d, 0x806567cb,
    0x196c3671, 0x6e6b06e7, 0xfed41b76, 0x89d32be0, 0x10da7a5a,
    0x67dd4acc, 0xf9b9df6f, 0x8ebeeff9, 0x17b7be43, 0x60b08ed5,
    0xd6d6a3e8, 0xa1d1937e, 0x38d8c2c4, 0x4fdff252, 0xd1bb67f1,
    0xa6bc5767, 0x3fb506dd, 0x48b2364b, 0xd80d2bda, 0xaf0a1b4c,
    0x36034af6, 0x41047a60, 0xdf60efc3, 0xa867df55, 0x316e8eef,
    0x4669be79, 0xcb61b38c, 0xbc66831a, 0x256fd2a0, 0x5268e236,
    0xcc0c7795, 0xbb0b4703, 0x220216b9, 0x5505262f, 0xc5ba3bbe,
    0xb2bd0b28, 0x2bb45a92, 0x5cb36a04, 0xc2d7ffa7, 0xb5d0cf31,
    0x2cd99e8b, 0x5bdeae1d, 0x9b64c2b0, 0xec63f226, 0x756aa39c,
    0x026d930a, 0x9c0906a9, 0xeb0e363f, 0x72076785, 0x05005713,
    0x95bf4a82, 0xe2b87a14, 0x7bb12bae, 0x0cb61b38, 0x92d28e9b,
    0xe5d5be0d, 0x7cdcefb7, 0x0bdbdf21, 0x86d3d2d4, 0xf1d4e242,
    0x68ddb3f8, 0x1fda836e, 0x81be16cd, 0xf6b9265b, 0x6fb077e1,
    0x18b74777, 0x88085ae6, 0xff0f6a70, 0x66063bca, 0x11010b5c,
    0x8f659eff, 0xf862ae69, 0x616bffd3, 0x166ccf45, 0xa00ae278,
    0xd70dd2ee, 0x4e048354, 0x3903b3c2, 0xa7672661, 0xd06016f7,
    0x4969474d, 0x3e6e77db, 0xaed16a4a, 0xd9d65adc, 0x40df0b66,
    0x37d83bf0, 0xa9bcae53, 0xdebb9ec5, 0x47b2cf7f, 0x30b5ffe9,
    0xbdbdf21c, 0xcabac28a, 0x53b39330, 0x24b4a3a6, 0xbad03605,
    0xcdd70693, 0x54de5729, 0x23d967bf, 0xb3667a2e, 0xc4614ab8,
    0x5d681b02, 0x2a6f2b94, 0xb40bbe37, 0xc30c8ea1, 0x5a05df1b,
    0x2d02ef8d]





// MARK: Data



extension Data {
    enum CompressionError: Error {
        case invalidStream
        case corruptedData
    }

    /// Calculate the `CRC32` checksum of the receiver.
    ///
    /// - Parameter checksum: The starting seed.
    /// - Returns: The checksum calculated from the bytes of the receiver and the starting seed.
    public func crc32(checksum: CRC32) -> CRC32 {
        // The typecast is necessary on 32-bit platforms because of
        // https://bugs.swift.org/browse/SR-1774
        let mask = 0xffffffff as CRC32
        var result = checksum ^ mask
        crcTable.withUnsafeBufferPointer { crcTablePointer in
            self.withUnsafeBytes { bufferPointer in
                var bufferIndex = 0
                while bufferIndex < self.count {
                    let byte = bufferPointer[bufferIndex]
                    let index = Int((result ^ CRC32(byte)) & 0xff)
                    result = (result >> 8) ^ crcTablePointer[index]
                    bufferIndex += 1
                }
            }
        }
        return result ^ mask
    }

    /// Compress the output of `provider` and pass it to `consumer`.
    /// - Parameters:
    ///   - size: The uncompressed size of the data to be compressed.
    ///   - bufferSize: The maximum size of the compression buffer.
    ///   - provider: A closure that accepts a position and a chunk size. Returns a `Data` chunk.
    ///   - consumer: A closure that processes the result of the compress operation.
    /// - Returns: The checksum of the processed content.
    public static func compress(size: Int, bufferSize: Int, provider: Provider, consumer: Consumer) throws -> CRC32 {
        return try self.process(operation: COMPRESSION_STREAM_ENCODE, size: size, bufferSize: bufferSize,
                                provider: provider, consumer: consumer)
    }

    /// Decompress the output of `provider` and pass it to `consumer`.
    /// - Parameters:
    ///   - size: The compressed size of the data to be decompressed.
    ///   - bufferSize: The maximum size of the decompression buffer.
    ///   - skipCRC32: Optional flag to skip calculation of the CRC32 checksum to improve performance.
    ///   - provider: A closure that accepts a position and a chunk size. Returns a `Data` chunk.
    ///   - consumer: A closure that processes the result of the decompress operation.
    /// - Returns: The checksum of the processed content.
    public static func decompress(size: Int, bufferSize: Int, skipCRC32: Bool,
                                  provider: Provider, consumer: Consumer) throws -> CRC32 {
        return try self.process(operation: COMPRESSION_STREAM_DECODE, size: size, bufferSize: bufferSize,
                                skipCRC32: skipCRC32, provider: provider, consumer: consumer)
    }
}


extension Data {

    static func process(operation: compression_stream_operation, size: Int, bufferSize: Int, skipCRC32: Bool = false,
                        provider: Provider, consumer: Consumer) throws -> CRC32 {
        var crc32 = CRC32(0)
        let destPointer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
        defer { destPointer.deallocate() }
        let streamPointer = UnsafeMutablePointer<compression_stream>.allocate(capacity: 1)
        defer { streamPointer.deallocate() }
        var stream = streamPointer.pointee
        var status = compression_stream_init(&stream, operation, COMPRESSION_ZLIB)
        guard status != COMPRESSION_STATUS_ERROR else { throw CompressionError.invalidStream }
        defer { compression_stream_destroy(&stream) }
        stream.src_size = 0
        stream.dst_ptr = destPointer
        stream.dst_size = bufferSize
        var position = 0
        var sourceData: Data?
        repeat {
            if stream.src_size == 0 {
                do {
                    sourceData = try provider(position, Swift.min((size - position), bufferSize))
                    position += stream.prepare(for: sourceData)
                } catch { throw error }
            }
            if let sourceData = sourceData {
                sourceData.withUnsafeBytes { (rawBufferPointer) in
                    if let baseAddress = rawBufferPointer.baseAddress {
                        let pointer = baseAddress.assumingMemoryBound(to: UInt8.self)
                        stream.src_ptr = pointer.advanced(by: sourceData.count - stream.src_size)
                        let flags = sourceData.count < bufferSize ? Int32(COMPRESSION_STREAM_FINALIZE.rawValue) : 0
                        status = compression_stream_process(&stream, flags)
                    }
                }
                if operation == COMPRESSION_STREAM_ENCODE && !skipCRC32 { crc32 = sourceData.crc32(checksum: crc32) }
            }
            switch status {
            case COMPRESSION_STATUS_OK, COMPRESSION_STATUS_END:
                let outputData = Data(bytesNoCopy: destPointer, count: bufferSize - stream.dst_size, deallocator: .none)
                try consumer(outputData)
                if operation == COMPRESSION_STREAM_DECODE && !skipCRC32 { crc32 = outputData.crc32(checksum: crc32) }
                stream.dst_ptr = destPointer
                stream.dst_size = bufferSize
            default: throw CompressionError.corruptedData
            }
        } while status == COMPRESSION_STATUS_OK
        return crc32
    }
}

private extension compression_stream {

    mutating func prepare(for sourceData: Data?) -> Int {
        guard let sourceData = sourceData else { return 0 }

        self.src_size = sourceData.count
        return sourceData.count
    }
}


protocol DataSerializable {
    static var size: Int { get }
    init?(data: Data, additionalDataProvider: (Int) throws -> Data)
    var data: Data { get }
}

extension Data {
    enum DataError: Error {
        case unreadableFile
        case unwritableFile
    }

    func scanValue<T>(start: Int) -> T {
        let subdata = self.subdata(in: start..<start+MemoryLayout<T>.size)
        return subdata.withUnsafeBytes { $0.load(as: T.self) }
    }

    static func readStruct<T>(from file: UnsafeMutablePointer<FILE>, at offset: Int) -> T? where T: DataSerializable {
        fseek(file, offset, SEEK_SET)
        guard let data = try? self.readChunk(of: T.size, from: file) else {
            return nil
        }
        let structure = T(data: data, additionalDataProvider: { (additionalDataSize) -> Data in
            return try self.readChunk(of: additionalDataSize, from: file)
        })
        return structure
    }

    static func consumePart(of size: Int, chunkSize: Int, skipCRC32: Bool = false,
                            provider: Provider, consumer: Consumer) throws -> CRC32 {
        var checksum = CRC32(0)
        guard size > 0 else {
            try consumer(Data())
            return checksum
        }

        let readInOneChunk = (size < chunkSize)
        var chunkSize = readInOneChunk ? size : chunkSize
        var bytesRead = 0
        while bytesRead < size {
            let remainingSize = size - bytesRead
            chunkSize = remainingSize < chunkSize ? remainingSize : chunkSize
            let data = try provider(bytesRead, chunkSize)
            try consumer(data)
            if !skipCRC32 {
                checksum = data.crc32(checksum: checksum)
            }
            bytesRead += chunkSize
        }
        return checksum
    }

    static func readChunk(of size: Int, from file: UnsafeMutablePointer<FILE>) throws -> Data {
        let alignment = MemoryLayout<UInt>.alignment
        let bytes = UnsafeMutableRawPointer.allocate(byteCount: size, alignment: alignment)
        let bytesRead = fread(bytes, 1, size, file)
        let error = ferror(file)
        if error > 0 {
            throw DataError.unreadableFile
        }
        return Data(bytesNoCopy: bytes, count: bytesRead, deallocator: .custom({ buf, _ in buf.deallocate() }))
    }

    static func write(chunk: Data, to file: UnsafeMutablePointer<FILE>) throws -> Int {
        var sizeWritten = 0
        chunk.withUnsafeBytes { (rawBufferPointer) in
            if let baseAddress = rawBufferPointer.baseAddress, rawBufferPointer.count > 0 {
                let pointer = baseAddress.assumingMemoryBound(to: UInt8.self)
                sizeWritten = fwrite(pointer, 1, chunk.count, file)
            }
        }
        let error = ferror(file)
        if error > 0 {
            throw DataError.unwritableFile
        }
        return sizeWritten
    }
}


extension ZipArchive {
    /// A value that represents a file, a directory or a symbolic link within a ZIP `Archive`.
    ///
    /// You can retrieve instances of `Entry` from an `Archive` via subscripting or iteration.
    /// Entries are identified by their `path`.
    public struct Entry: Equatable {
        /// The type of an `Entry` in a ZIP `Archive`.
        public enum EntryType: Int {
            /// Indicates a regular file.
            case file
            /// Indicates a directory.
            case directory
            /// Indicates a symbolic link.
            case symlink

            init(mode: mode_t) {
                switch mode & S_IFMT {
                case S_IFDIR:
                    self = .directory
                case S_IFLNK:
                    self = .symlink
                default:
                    self = .file
                }
            }
        }

        enum OSType: UInt {
            case msdos = 0
            case unix = 3
            case osx = 19
            case unused = 20
        }

        struct LocalFileHeader: DataSerializable {
            let localFileHeaderSignature = UInt32(ZipArchive.localFileHeaderStructSignature)
            let versionNeededToExtract: UInt16
            let generalPurposeBitFlag: UInt16
            let compressionMethod: UInt16
            let lastModFileTime: UInt16
            let lastModFileDate: UInt16
            let crc32: UInt32
            let compressedSize: UInt32
            let uncompressedSize: UInt32
            let fileNameLength: UInt16
            let extraFieldLength: UInt16
            static let size = 30
            let fileNameData: Data
            let extraFieldData: Data
        }

        struct DataDescriptor: DataSerializable {
            let data: Data
            let dataDescriptorSignature = UInt32(ZipArchive.dataDescriptorStructSignature)
            let crc32: UInt32
            let compressedSize: UInt32
            let uncompressedSize: UInt32
            static let size = 16
        }

        struct CentralDirectoryStructure: DataSerializable {
            let centralDirectorySignature = UInt32(ZipArchive.centralDirectoryStructSignature)
            let versionMadeBy: UInt16
            let versionNeededToExtract: UInt16
            let generalPurposeBitFlag: UInt16
            let compressionMethod: UInt16
            let lastModFileTime: UInt16
            let lastModFileDate: UInt16
            let crc32: UInt32
            let compressedSize: UInt32
            let uncompressedSize: UInt32
            let fileNameLength: UInt16
            let extraFieldLength: UInt16
            let fileCommentLength: UInt16
            let diskNumberStart: UInt16
            let internalFileAttributes: UInt16
            let externalFileAttributes: UInt32
            let relativeOffsetOfLocalHeader: UInt32
            static let size = 46
            let fileNameData: Data
            let extraFieldData: Data
            let fileCommentData: Data
            var usesDataDescriptor: Bool { return (self.generalPurposeBitFlag & (1 << 3 )) != 0 }
            var usesUTF8PathEncoding: Bool { return (self.generalPurposeBitFlag & (1 << 11 )) != 0 }
            var isEncrypted: Bool { return (self.generalPurposeBitFlag & (1 << 0)) != 0 }
            var isZIP64: Bool { return UInt8(truncatingIfNeeded: self.versionNeededToExtract) >= 45 }
        }
        /// Returns the `path` of the receiver within a ZIP `Archive` using a given encoding.
        ///
        /// - Parameters:
        ///   - encoding: `String.Encoding`
        public func path(using encoding: String.Encoding) -> String {
            return String(data: self.centralDirectoryStructure.fileNameData, encoding: encoding) ?? ""
        }
        /// The `path` of the receiver within a ZIP `Archive`.
        public var path: String {
            let dosLatinUS = 0x400
            let dosLatinUSEncoding = CFStringEncoding(dosLatinUS)
            let dosLatinUSStringEncoding = CFStringConvertEncodingToNSStringEncoding(dosLatinUSEncoding)
            let codepage437 = String.Encoding(rawValue: dosLatinUSStringEncoding)
            let encoding = self.centralDirectoryStructure.usesUTF8PathEncoding ? .utf8 : codepage437
            return self.path(using: encoding)
        }
        /// The file attributes of the receiver as key/value pairs.
        ///
        /// Contains the modification date and file permissions.
        public var fileAttributes: [FileAttributeKey: Any] {
            return FileManager.attributes(from: self)
        }
        /// The `CRC32` checksum of the receiver.
        ///
        /// - Note: Always returns `0` for entries of type `EntryType.directory`.
        public var checksum: CRC32 {
            var checksum = self.centralDirectoryStructure.crc32
            if self.centralDirectoryStructure.usesDataDescriptor {
                guard let dataDescriptor = self.dataDescriptor else { return 0 }
                checksum = dataDescriptor.crc32
            }
            return checksum
        }
        /// The `EntryType` of the receiver.
        public var type: EntryType {
            // OS Type is stored in the upper byte of versionMadeBy
            let osTypeRaw = self.centralDirectoryStructure.versionMadeBy >> 8
            let osType = OSType(rawValue: UInt(osTypeRaw)) ?? .unused
            var isDirectory = self.path.hasSuffix("/")
            switch osType {
            case .unix, .osx:
                let mode = mode_t(self.centralDirectoryStructure.externalFileAttributes >> 16) & S_IFMT
                switch mode {
                case S_IFREG:
                    return .file
                case S_IFDIR:
                    return .directory
                case S_IFLNK:
                    return .symlink
                default:
                    return isDirectory ? .directory : .file
                }
            case .msdos:
                isDirectory = isDirectory || ((centralDirectoryStructure.externalFileAttributes >> 4) == 0x01)
                fallthrough // For all other OSes we can only guess based on the directory suffix char
            default: return isDirectory ? .directory : .file
            }
        }
        /// The size of the receiver's compressed data.
        public var compressedSize: Int {
            return Int(dataDescriptor?.compressedSize ?? localFileHeader.compressedSize)
        }
        /// The size of the receiver's uncompressed data.
        public var uncompressedSize: Int {
            return Int(dataDescriptor?.uncompressedSize ?? localFileHeader.uncompressedSize)
        }
        /// The combined size of the local header, the data and the optional data descriptor.
        var localSize: Int {
            let localFileHeader = self.localFileHeader
            var extraDataLength = Int(localFileHeader.fileNameLength)
            extraDataLength += Int(localFileHeader.extraFieldLength)
            var size = LocalFileHeader.size + extraDataLength
            let isCompressed = localFileHeader.compressionMethod != CompressionMethod.none.rawValue
            size += isCompressed ? self.compressedSize : self.uncompressedSize
            size += self.dataDescriptor != nil ? DataDescriptor.size : 0
            return size
        }
        var dataOffset: Int {
            var dataOffset = Int(self.centralDirectoryStructure.relativeOffsetOfLocalHeader)
            dataOffset += LocalFileHeader.size
            dataOffset += Int(self.localFileHeader.fileNameLength)
            dataOffset += Int(self.localFileHeader.extraFieldLength)
            return dataOffset
        }
        let centralDirectoryStructure: CentralDirectoryStructure
        let localFileHeader: LocalFileHeader
        let dataDescriptor: DataDescriptor?

        public static func == (lhs: Entry, rhs: Entry) -> Bool {
            return lhs.path == rhs.path
            && lhs.localFileHeader.crc32 == rhs.localFileHeader.crc32
            && lhs.centralDirectoryStructure.relativeOffsetOfLocalHeader
            == rhs.centralDirectoryStructure.relativeOffsetOfLocalHeader
        }

        init?(centralDirectoryStructure: CentralDirectoryStructure,
              localFileHeader: LocalFileHeader,
              dataDescriptor: DataDescriptor?) {
            // We currently don't support ZIP64 or encrypted archives
            guard !centralDirectoryStructure.isZIP64 else { return nil }
            guard !centralDirectoryStructure.isEncrypted else { return nil }
            self.centralDirectoryStructure = centralDirectoryStructure
            self.localFileHeader = localFileHeader
            self.dataDescriptor = dataDescriptor
        }
    }
}

extension ZipArchive.Entry.LocalFileHeader {
    var data: Data {
        var localFileHeaderSignature = self.localFileHeaderSignature
        var versionNeededToExtract = self.versionNeededToExtract
        var generalPurposeBitFlag = self.generalPurposeBitFlag
        var compressionMethod = self.compressionMethod
        var lastModFileTime = self.lastModFileTime
        var lastModFileDate = self.lastModFileDate
        var crc32 = self.crc32
        var compressedSize = self.compressedSize
        var uncompressedSize = self.uncompressedSize
        var fileNameLength = self.fileNameLength
        var extraFieldLength = self.extraFieldLength
        var data = Data()
        withUnsafePointer(to: &localFileHeaderSignature, { data.append(UnsafeBufferPointer(start: $0, count: 1))})
        withUnsafePointer(to: &versionNeededToExtract, { data.append(UnsafeBufferPointer(start: $0, count: 1))})
        withUnsafePointer(to: &generalPurposeBitFlag, { data.append(UnsafeBufferPointer(start: $0, count: 1))})
        withUnsafePointer(to: &compressionMethod, { data.append(UnsafeBufferPointer(start: $0, count: 1))})
        withUnsafePointer(to: &lastModFileTime, { data.append(UnsafeBufferPointer(start: $0, count: 1))})
        withUnsafePointer(to: &lastModFileDate, { data.append(UnsafeBufferPointer(start: $0, count: 1))})
        withUnsafePointer(to: &crc32, { data.append(UnsafeBufferPointer(start: $0, count: 1))})
        withUnsafePointer(to: &compressedSize, { data.append(UnsafeBufferPointer(start: $0, count: 1))})
        withUnsafePointer(to: &uncompressedSize, { data.append(UnsafeBufferPointer(start: $0, count: 1))})
        withUnsafePointer(to: &fileNameLength, { data.append(UnsafeBufferPointer(start: $0, count: 1))})
        withUnsafePointer(to: &extraFieldLength, { data.append(UnsafeBufferPointer(start: $0, count: 1))})
        data.append(self.fileNameData)
        data.append(self.extraFieldData)
        return data
    }

    init?(data: Data, additionalDataProvider provider: (Int) throws -> Data) {
        guard data.count == ZipArchive.Entry.LocalFileHeader.size else { return nil }
        guard data.scanValue(start: 0) == localFileHeaderSignature else { return nil }
        self.versionNeededToExtract = data.scanValue(start: 4)
        self.generalPurposeBitFlag = data.scanValue(start: 6)
        self.compressionMethod = data.scanValue(start: 8)
        self.lastModFileTime = data.scanValue(start: 10)
        self.lastModFileDate = data.scanValue(start: 12)
        self.crc32 = data.scanValue(start: 14)
        self.compressedSize = data.scanValue(start: 18)
        self.uncompressedSize = data.scanValue(start: 22)
        self.fileNameLength = data.scanValue(start: 26)
        self.extraFieldLength = data.scanValue(start: 28)
        let additionalDataLength = Int(self.fileNameLength) + Int(self.extraFieldLength)
        guard let additionalData = try? provider(additionalDataLength) else { return nil }
        guard additionalData.count == additionalDataLength else { return nil }
        var subRangeStart = 0
        var subRangeEnd = Int(self.fileNameLength)
        self.fileNameData = additionalData.subdata(in: subRangeStart..<subRangeEnd)
        subRangeStart += Int(self.fileNameLength)
        subRangeEnd = subRangeStart + Int(self.extraFieldLength)
        self.extraFieldData = additionalData.subdata(in: subRangeStart..<subRangeEnd)
    }
}

extension ZipArchive.Entry.CentralDirectoryStructure {
    var data: Data {
        var centralDirectorySignature = self.centralDirectorySignature
        var versionMadeBy = self.versionMadeBy
        var versionNeededToExtract = self.versionNeededToExtract
        var generalPurposeBitFlag = self.generalPurposeBitFlag
        var compressionMethod = self.compressionMethod
        var lastModFileTime = self.lastModFileTime
        var lastModFileDate = self.lastModFileDate
        var crc32 = self.crc32
        var compressedSize = self.compressedSize
        var uncompressedSize = self.uncompressedSize
        var fileNameLength = self.fileNameLength
        var extraFieldLength = self.extraFieldLength
        var fileCommentLength = self.fileCommentLength
        var diskNumberStart = self.diskNumberStart
        var internalFileAttributes = self.internalFileAttributes
        var externalFileAttributes = self.externalFileAttributes
        var relativeOffsetOfLocalHeader = self.relativeOffsetOfLocalHeader
        var data = Data()
        withUnsafePointer(to: &centralDirectorySignature, { data.append(UnsafeBufferPointer(start: $0, count: 1))})
        withUnsafePointer(to: &versionMadeBy, { data.append(UnsafeBufferPointer(start: $0, count: 1))})
        withUnsafePointer(to: &versionNeededToExtract, { data.append(UnsafeBufferPointer(start: $0, count: 1))})
        withUnsafePointer(to: &generalPurposeBitFlag, { data.append(UnsafeBufferPointer(start: $0, count: 1))})
        withUnsafePointer(to: &compressionMethod, { data.append(UnsafeBufferPointer(start: $0, count: 1))})
        withUnsafePointer(to: &lastModFileTime, { data.append(UnsafeBufferPointer(start: $0, count: 1))})
        withUnsafePointer(to: &lastModFileDate, { data.append(UnsafeBufferPointer(start: $0, count: 1))})
        withUnsafePointer(to: &crc32, { data.append(UnsafeBufferPointer(start: $0, count: 1))})
        withUnsafePointer(to: &compressedSize, { data.append(UnsafeBufferPointer(start: $0, count: 1))})
        withUnsafePointer(to: &uncompressedSize, { data.append(UnsafeBufferPointer(start: $0, count: 1))})
        withUnsafePointer(to: &fileNameLength, { data.append(UnsafeBufferPointer(start: $0, count: 1))})
        withUnsafePointer(to: &extraFieldLength, { data.append(UnsafeBufferPointer(start: $0, count: 1))})
        withUnsafePointer(to: &fileCommentLength, { data.append(UnsafeBufferPointer(start: $0, count: 1))})
        withUnsafePointer(to: &diskNumberStart, { data.append(UnsafeBufferPointer(start: $0, count: 1))})
        withUnsafePointer(to: &internalFileAttributes, { data.append(UnsafeBufferPointer(start: $0, count: 1))})
        withUnsafePointer(to: &externalFileAttributes, { data.append(UnsafeBufferPointer(start: $0, count: 1))})
        withUnsafePointer(to: &relativeOffsetOfLocalHeader, { data.append(UnsafeBufferPointer(start: $0, count: 1))})
        data.append(self.fileNameData)
        data.append(self.extraFieldData)
        data.append(self.fileCommentData)
        return data
    }

    init?(data: Data, additionalDataProvider provider: (Int) throws -> Data) {
        guard data.count == ZipArchive.Entry.CentralDirectoryStructure.size else { return nil }
        guard data.scanValue(start: 0) == centralDirectorySignature else { return nil }
        self.versionMadeBy = data.scanValue(start: 4)
        self.versionNeededToExtract = data.scanValue(start: 6)
        self.generalPurposeBitFlag = data.scanValue(start: 8)
        self.compressionMethod = data.scanValue(start: 10)
        self.lastModFileTime = data.scanValue(start: 12)
        self.lastModFileDate = data.scanValue(start: 14)
        self.crc32 = data.scanValue(start: 16)
        self.compressedSize = data.scanValue(start: 20)
        self.uncompressedSize = data.scanValue(start: 24)
        self.fileNameLength = data.scanValue(start: 28)
        self.extraFieldLength = data.scanValue(start: 30)
        self.fileCommentLength = data.scanValue(start: 32)
        self.diskNumberStart = data.scanValue(start: 34)
        self.internalFileAttributes = data.scanValue(start: 36)
        self.externalFileAttributes = data.scanValue(start: 38)
        self.relativeOffsetOfLocalHeader = data.scanValue(start: 42)
        let additionalDataLength = Int(self.fileNameLength) + Int(self.extraFieldLength) + Int(self.fileCommentLength)
        guard let additionalData = try? provider(additionalDataLength) else { return nil }
        guard additionalData.count == additionalDataLength else { return nil }
        var subRangeStart = 0
        var subRangeEnd = Int(self.fileNameLength)
        self.fileNameData = additionalData.subdata(in: subRangeStart..<subRangeEnd)
        subRangeStart += Int(self.fileNameLength)
        subRangeEnd = subRangeStart + Int(self.extraFieldLength)
        self.extraFieldData = additionalData.subdata(in: subRangeStart..<subRangeEnd)
        subRangeStart += Int(self.extraFieldLength)
        subRangeEnd = subRangeStart + Int(self.fileCommentLength)
        self.fileCommentData = additionalData.subdata(in: subRangeStart..<subRangeEnd)
    }

    init(localFileHeader: ZipArchive.Entry.LocalFileHeader, fileAttributes: UInt32, relativeOffset: UInt32) {
        versionMadeBy = UInt16(789)
        versionNeededToExtract = localFileHeader.versionNeededToExtract
        generalPurposeBitFlag = localFileHeader.generalPurposeBitFlag
        compressionMethod = localFileHeader.compressionMethod
        lastModFileTime = localFileHeader.lastModFileTime
        lastModFileDate = localFileHeader.lastModFileDate
        crc32 = localFileHeader.crc32
        compressedSize = localFileHeader.compressedSize
        uncompressedSize = localFileHeader.uncompressedSize
        fileNameLength = localFileHeader.fileNameLength
        extraFieldLength = UInt16(0)
        fileCommentLength = UInt16(0)
        diskNumberStart = UInt16(0)
        internalFileAttributes = UInt16(0)
        externalFileAttributes = fileAttributes
        relativeOffsetOfLocalHeader = relativeOffset
        fileNameData = localFileHeader.fileNameData
        extraFieldData = Data()
        fileCommentData = Data()
    }

    init(centralDirectoryStructure: ZipArchive.Entry.CentralDirectoryStructure, offset: UInt32) {
        let relativeOffset = centralDirectoryStructure.relativeOffsetOfLocalHeader - offset
        relativeOffsetOfLocalHeader = relativeOffset
        versionMadeBy = centralDirectoryStructure.versionMadeBy
        versionNeededToExtract = centralDirectoryStructure.versionNeededToExtract
        generalPurposeBitFlag = centralDirectoryStructure.generalPurposeBitFlag
        compressionMethod = centralDirectoryStructure.compressionMethod
        lastModFileTime = centralDirectoryStructure.lastModFileTime
        lastModFileDate = centralDirectoryStructure.lastModFileDate
        crc32 = centralDirectoryStructure.crc32
        compressedSize = centralDirectoryStructure.compressedSize
        uncompressedSize = centralDirectoryStructure.uncompressedSize
        fileNameLength = centralDirectoryStructure.fileNameLength
        extraFieldLength = centralDirectoryStructure.extraFieldLength
        fileCommentLength = centralDirectoryStructure.fileCommentLength
        diskNumberStart = centralDirectoryStructure.diskNumberStart
        internalFileAttributes = centralDirectoryStructure.internalFileAttributes
        externalFileAttributes = centralDirectoryStructure.externalFileAttributes
        fileNameData = centralDirectoryStructure.fileNameData
        extraFieldData = centralDirectoryStructure.extraFieldData
        fileCommentData = centralDirectoryStructure.fileCommentData
    }
}

extension ZipArchive.Entry.DataDescriptor {
    init?(data: Data, additionalDataProvider provider: (Int) throws -> Data) {
        guard data.count == ZipArchive.Entry.DataDescriptor.size else { return nil }
        let signature: UInt32 = data.scanValue(start: 0)
        // The DataDescriptor signature is not mandatory so we have to re-arrange the input data if it is missing.
        var readOffset = 0
        if signature == self.dataDescriptorSignature { readOffset = 4 }
        self.crc32 = data.scanValue(start: readOffset + 0)
        self.compressedSize = data.scanValue(start: readOffset + 4)
        self.uncompressedSize = data.scanValue(start: readOffset + 8)
        // Our add(_ entry:) methods always maintain compressed & uncompressed
        // sizes and so we don't need a data descriptor for newly added entries.
        // Data descriptors of already existing entries are manually preserved
        // when copying those entries to the tempArchive during remove(_ entry:).
        self.data = Data()
    }
}

extension FileManager {
    typealias CentralDirectoryStructure = ZipArchive.Entry.CentralDirectoryStructure

    /// Zips the file or directory contents at the specified source URL to the destination URL.
    ///
    /// If the item at the source URL is a directory, the directory itself will be
    /// represented within the ZIP `Archive`. Calling this method with a directory URL
    /// `file:///path/directory/` will create an archive with a `directory/` entry at the root level.
    /// You can override this behavior by passing `false` for `shouldKeepParent`. In that case, the contents
    /// of the source directory will be placed at the root of the archive.
    /// - Parameters:
    ///   - sourceURL: The file URL pointing to an existing file or directory.
    ///   - destinationURL: The file URL that identifies the destination of the zip operation.
    ///   - shouldKeepParent: Indicates that the directory name of a source item should be used as root element
    ///                       within the archive. Default is `true`.
    ///   - compressionMethod: Indicates the `CompressionMethod` that should be applied.
    ///                        By default, `zipItem` will create uncompressed archives.
    ///   - progress: A progress object that can be used to track or cancel the zip operation.
    /// - Throws: Throws an error if the source item does not exist or the destination URL is not writable.
    public func zipItem(at sourceURL: URL, to destinationURL: URL,
                        shouldKeepParent: Bool = true, compressionMethod: CompressionMethod = .none,
                        progress: Progress? = nil) throws {
        let fileManager = FileManager()
        guard fileManager.itemExists(at: sourceURL) else {
            throw CocoaError(.fileReadNoSuchFile, userInfo: [NSFilePathErrorKey: sourceURL.path])
        }
        guard !fileManager.itemExists(at: destinationURL) else {
            throw CocoaError(.fileWriteFileExists, userInfo: [NSFilePathErrorKey: destinationURL.path])
        }
        guard let archive = ZipArchive(url: destinationURL, accessMode: .create) else {
            throw ZipArchive.ZipArchiveError.unwritableArchive
        }
        let isDirectory = try FileManager.typeForItem(at: sourceURL) == .directory
        if isDirectory {
            let subPaths = try self.subpathsOfDirectory(atPath: sourceURL.path)
            var totalUnitCount = Int64(0)
            if let progress = progress {
                totalUnitCount = subPaths.reduce(Int64(0), {
                    let itemURL = sourceURL.appendingPathComponent($1)
                    let itemSize = archive.totalUnitCountForAddingItem(at: itemURL)
                    return $0 + itemSize
                })
                progress.totalUnitCount = totalUnitCount
            }

            // If the caller wants to keep the parent directory, we use the lastPathComponent of the source URL
            // as common base for all entries (similar to macOS' Archive Utility.app)
            let directoryPrefix = sourceURL.lastPathComponent
            for entryPath in subPaths {
                let finalEntryPath = shouldKeepParent ? directoryPrefix + "/" + entryPath : entryPath
                let finalBaseURL = shouldKeepParent ? sourceURL.deletingLastPathComponent() : sourceURL
                if let progress = progress {
                    let itemURL = sourceURL.appendingPathComponent(entryPath)
                    let entryProgress = archive.makeProgressForAddingItem(at: itemURL)
                    progress.addChild(entryProgress, withPendingUnitCount: entryProgress.totalUnitCount)
                    try archive.addEntry(with: finalEntryPath, relativeTo: finalBaseURL,
                                         compressionMethod: compressionMethod, progress: entryProgress)
                } else {
                    try archive.addEntry(with: finalEntryPath, relativeTo: finalBaseURL,
                                         compressionMethod: compressionMethod)
                }
            }
        } else {
            progress?.totalUnitCount = archive.totalUnitCountForAddingItem(at: sourceURL)
            let baseURL = sourceURL.deletingLastPathComponent()
            try archive.addEntry(with: sourceURL.lastPathComponent, relativeTo: baseURL,
                                 compressionMethod: compressionMethod, progress: progress)
        }
    }

    /// Unzips the contents at the specified source URL to the destination URL.
    ///
    /// - Parameters:
    ///   - sourceURL: The file URL pointing to an existing ZIP file.
    ///   - destinationURL: The file URL that identifies the destination directory of the unzip operation.
    ///   - skipCRC32: Optional flag to skip calculation of the CRC32 checksum to improve performance.
    ///   - progress: A progress object that can be used to track or cancel the unzip operation.
    ///   - preferredEncoding: Encoding for entry paths. Overrides the encoding specified in the archive.
    /// - Throws: Throws an error if the source item does not exist or the destination URL is not writable.
    public func unzipItem(at sourceURL: URL, to destinationURL: URL, skipCRC32: Bool = false,
                          progress: Progress? = nil, preferredEncoding: String.Encoding? = nil) throws {
        let fileManager = FileManager()
        guard fileManager.itemExists(at: sourceURL) else {
            throw CocoaError(.fileReadNoSuchFile, userInfo: [NSFilePathErrorKey: sourceURL.path])
        }
        guard let archive = ZipArchive(url: sourceURL, accessMode: .read, preferredEncoding: preferredEncoding) else {
            throw ZipArchive.ZipArchiveError.unreadableArchive
        }
        let sortedEntries = try archive.sortedEntries()
        var totalUnitCount = Int64(0)
        if let progress = progress {
            totalUnitCount = sortedEntries.reduce(0, { $0 + archive.totalUnitCountForReading($1) })
            progress.totalUnitCount = totalUnitCount
        }

        for entry in sortedEntries {
            let path = preferredEncoding == nil ? entry.path : entry.path(using: preferredEncoding!)
            let destinationEntryURL = destinationURL.appendingPathComponent(path)
            guard destinationEntryURL.isContained(in: destinationURL) else {
                throw CocoaError(.fileReadInvalidFileName,
                                 userInfo: [NSFilePathErrorKey: destinationEntryURL.path])
            }
            if let progress = progress {
                let entryProgress = archive.makeProgressForReading(entry)
                progress.addChild(entryProgress, withPendingUnitCount: entryProgress.totalUnitCount)
                _ = try archive.extract(entry, to: destinationEntryURL, skipCRC32: skipCRC32, progress: entryProgress)
            } else {
                _ = try archive.extract(entry, to: destinationEntryURL, skipCRC32: skipCRC32)
            }
        }
    }

    // MARK: - Helpers
    func itemExists(at url: URL) -> Bool {
        // Use `URL.checkResourceIsReachable()` instead of `FileManager.fileExists()` here
        // because we don't want implicit symlink resolution.
        // As per documentation, `FileManager.fileExists()` traverses symlinks and therefore a broken symlink
        // would throw a `.fileReadNoSuchFile` false positive error.
        // For ZIP files it may be intended to archive "broken" symlinks because they might be
        // resolvable again when extracting the archive to a different destination.
        return (try? url.checkResourceIsReachable()) == true
    }

    func createParentDirectoryStructure(for url: URL) throws {
        let parentDirectoryURL = url.deletingLastPathComponent()
        try self.createDirectory(at: parentDirectoryURL, withIntermediateDirectories: true, attributes: nil)
    }

    class func attributes(from entry: ZipArchive.Entry) -> [FileAttributeKey: Any] {
        let centralDirectoryStructure = entry.centralDirectoryStructure
        let entryType = entry.type
        let fileTime = centralDirectoryStructure.lastModFileTime
        let fileDate = centralDirectoryStructure.lastModFileDate
        let defaultPermissions = entryType == .directory ? ZipArchive.defaultDirectoryPermissions : ZipArchive.defaultFilePermissions
        var attributes = [.posixPermissions: defaultPermissions] as [FileAttributeKey: Any]
        attributes[.modificationDate] = Date(dateTime: (fileDate, fileTime))
        let versionMadeBy = centralDirectoryStructure.versionMadeBy
        guard let osType = ZipArchive.Entry.OSType(rawValue: UInt(versionMadeBy >> 8)) else { return attributes }

        let externalFileAttributes = centralDirectoryStructure.externalFileAttributes
        let permissions = self.permissions(for: externalFileAttributes, osType: osType, entryType: entryType)
        attributes[.posixPermissions] = NSNumber(value: permissions)
        return attributes
    }

    class func permissions(for externalFileAttributes: UInt32, osType: ZipArchive.Entry.OSType,
                           entryType: ZipArchive.Entry.EntryType) -> UInt16 {
        switch osType {
        case .unix, .osx:
            let permissions = mode_t(externalFileAttributes >> 16) & (~S_IFMT)
            let defaultPermissions = entryType == .directory ? ZipArchive.defaultDirectoryPermissions : ZipArchive.defaultFilePermissions
            return permissions == 0 ? defaultPermissions : UInt16(permissions)
        default:
            return entryType == .directory ? ZipArchive.defaultDirectoryPermissions : ZipArchive.defaultFilePermissions
        }
    }

    class func externalFileAttributesForEntry(of type: ZipArchive.Entry.EntryType, permissions: UInt16) -> UInt32 {
        var typeInt: UInt16
        switch type {
        case .file:
            typeInt = UInt16(S_IFREG)
        case .directory:
            typeInt = UInt16(S_IFDIR)
        case .symlink:
            typeInt = UInt16(S_IFLNK)
        }
        var externalFileAttributes = UInt32(typeInt|UInt16(permissions))
        externalFileAttributes = (externalFileAttributes << 16)
        return externalFileAttributes
    }

    class func permissionsForItem(at URL: URL) throws -> UInt16 {
        let fileManager = FileManager()
        let entryFileSystemRepresentation = fileManager.fileSystemRepresentation(withPath: URL.path)
        var fileStat = stat()
        lstat(entryFileSystemRepresentation, &fileStat)
        let permissions = fileStat.st_mode
        return UInt16(permissions)
    }

    class func fileModificationDateTimeForItem(at url: URL) throws -> Date {
        let fileManager = FileManager()
        guard fileManager.itemExists(at: url) else {
            throw CocoaError(.fileReadNoSuchFile, userInfo: [NSFilePathErrorKey: url.path])
        }
        let entryFileSystemRepresentation = fileManager.fileSystemRepresentation(withPath: url.path)
        var fileStat = stat()
        lstat(entryFileSystemRepresentation, &fileStat)
        let modTimeSpec = fileStat.st_mtimespec

        let timeStamp = TimeInterval(modTimeSpec.tv_sec) + TimeInterval(modTimeSpec.tv_nsec)/1000000000.0
        let modDate = Date(timeIntervalSince1970: timeStamp)
        return modDate
    }

    class func fileSizeForItem(at url: URL) throws -> UInt32 {
        let fileManager = FileManager()
        guard fileManager.itemExists(at: url) else {
            throw CocoaError(.fileReadNoSuchFile, userInfo: [NSFilePathErrorKey: url.path])
        }
        let entryFileSystemRepresentation = fileManager.fileSystemRepresentation(withPath: url.path)
        var fileStat = stat()
        lstat(entryFileSystemRepresentation, &fileStat)
        return UInt32(fileStat.st_size)
    }

    class func typeForItem(at url: URL) throws -> ZipArchive.Entry.EntryType {
        let fileManager = FileManager()
        guard url.isFileURL, fileManager.itemExists(at: url) else {
            throw CocoaError(.fileReadNoSuchFile, userInfo: [NSFilePathErrorKey: url.path])
        }
        let entryFileSystemRepresentation = fileManager.fileSystemRepresentation(withPath: url.path)
        var fileStat = stat()
        lstat(entryFileSystemRepresentation, &fileStat)
        return ZipArchive.Entry.EntryType(mode: fileStat.st_mode)
    }
}

extension Date {
    init(dateTime: (UInt16, UInt16)) {
        var msdosDateTime = Int(dateTime.0)
        msdosDateTime <<= 16
        msdosDateTime |= Int(dateTime.1)
        var unixTime = tm()
        unixTime.tm_sec = Int32((msdosDateTime&31)*2)
        unixTime.tm_min = Int32((msdosDateTime>>5)&63)
        unixTime.tm_hour = Int32((Int(dateTime.1)>>11)&31)
        unixTime.tm_mday = Int32((msdosDateTime>>16)&31)
        unixTime.tm_mon = Int32((msdosDateTime>>21)&15)
        unixTime.tm_mon -= 1 // UNIX time struct month entries are zero based.
        unixTime.tm_year = Int32(1980+(msdosDateTime>>25))
        unixTime.tm_year -= 1900 // UNIX time structs count in "years since 1900".
        let time = timegm(&unixTime)
        self = Date(timeIntervalSince1970: TimeInterval(time))
    }

    var fileModificationDateTime: (UInt16, UInt16) {
        return (self.fileModificationDate, self.fileModificationTime)
    }

    var fileModificationDate: UInt16 {
        var time = time_t(self.timeIntervalSince1970)
        guard let unixTime = gmtime(&time) else {
            return 0
        }
        var year = unixTime.pointee.tm_year + 1900 // UNIX time structs count in "years since 1900".
                                                   // ZIP uses the MSDOS date format which has a valid range of 1980 - 2099.
        year = year >= 1980 ? year : 1980
        year = year <= 2099 ? year : 2099
        let month = unixTime.pointee.tm_mon + 1 // UNIX time struct month entries are zero based.
        let day = unixTime.pointee.tm_mday
        return (UInt16)(day + ((month) * 32) +  ((year - 1980) * 512))
    }

    var fileModificationTime: UInt16 {
        var time = time_t(self.timeIntervalSince1970)
        guard let unixTime = gmtime(&time) else {
            return 0
        }
        let hour = unixTime.pointee.tm_hour
        let minute = unixTime.pointee.tm_min
        let second = unixTime.pointee.tm_sec
        return (UInt16)((second/2) + (minute * 32) + (hour * 2048))
    }
}

public extension URL {
    func isContained(in parentDirectoryURL: URL) -> Bool {
        // Ensure this URL is contained in the passed in URL
        let parentDirectoryURL = URL(fileURLWithPath: parentDirectoryURL.path, isDirectory: true).standardized
        return self.standardized.absoluteString.hasPrefix(parentDirectoryURL.absoluteString)
    }
}

extension URL {

    static func temporaryReplacementDirectoryURL(for archive: ZipArchive) -> URL {
        if archive.url.isFileURL,
           let tempDir = try? FileManager().url(for: .itemReplacementDirectory, in: .userDomainMask, appropriateFor: archive.url, create: true) {
            return tempDir
        }

        return URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(ProcessInfo.processInfo.globallyUniqueString)
    }
}

#endif // canImport(Compression)
