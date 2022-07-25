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
import FairCore
#if canImport(CoreFoundation)
import CoreFoundation
#endif

// MARK: AppBundle

/// A structure that contains an app, whether as an expanded folder or a zip archive.
public class AppBundle<Source: DataWrapper> {
    public let source: Source
    let infoDictionary: Plist
    let infoParentNode: Source.Path
    let infoNode: Source.Path

    /// Cache of entitlements once loaded
    private var _entitlements: [AppEntitlements]??

    public func entitlements() throws -> [AppEntitlements]? {
        if let entitlements = _entitlements {
            return entitlements
        }
        let ent = try self.loadEntitlements()
        self._entitlements = .some(ent)
        return ent
    }

    public func isSandboxed() throws -> Bool? {
        try entitlement(for: .app_sandbox)
    }

    public func appGroups() throws -> [String]? {
        try entitlement(for: .application_groups)
    }

    public init(source: Source) throws {
        self.source = source
        guard let (info, parent, node) = try Self.readInfo(source: source) else {
            throw AppBundleErrors.missingInfo
        }
        self.infoDictionary = info
        self.infoParentNode = parent
        self.infoNode = node
    }

    public func entitlement<T>(for key: AppEntitlement) throws -> T? {
        try self.entitlements()?.compactMap({ $0.value(forKey: key) as? T }).first
    }
}

public enum AppBundleLoader {
    /// Loads the entitlements from an app bundle (either a ipa zip or an expanded binary package).
    /// Multiple entitlements will be returned when an executable is a fat binary, although they are likely to all be equal.
    public static func loadInfo(fromAppBundle url: URL) throws -> (info: Plist, entitlements: [AppEntitlements]?) {
        if FileManager.default.isDirectory(url: url) == true {
            return try AppBundle(folderAt: url).loadInfo()
        } else {
            return try AppBundle(zipArchiveAt: url).loadInfo()
        }
    }
}

extension AppBundle {
    func loadInfo() throws -> (info: Plist, entitlements: [AppEntitlements]?) {
        return try (infoDictionary, entitlements())
    }
}

public enum AppBundleErrors : Error, LocalizedError {
    /// The Info.plist is missing from the archive
    case missingInfo

    public var failureReason: String? {
        switch self {
        case .missingInfo: return "Missing Info.plist in application bundle"
        }
    }
}

extension AppBundle {

    public var appType: AppType {
        self.infoDictionary.DTPlatformName == "iphoneos" ? .ios : .macos // not necessarily reliable
    }

    public enum AppType {
        /// A macOS .app folder containing the app
        case macos
        /// An iOS .ipa file, which is a zip containing an .app folder
        case ios
    }

    private func loadEntitlements() throws -> [AppEntitlements]? {
        guard let executable = try self.loadExecutableData() else {
            return nil
        }
        return try MachOBinary(binary: executable).readEntitlements()
    }

    public func loadExecutableData() throws -> SeekableData? {
        guard let executableName = infoDictionary.CFBundleExecutable else {
            return nil
        }

        // check first for macOS convention executable "AppName.app/Contents/MacOS/CFBundleExecutable"
        let folder = try self.source.nodes(at: infoParentNode).first(where: { $0.pathIsDirectory && $0.pathName.lastPathComponent == "MacOS" }) ?? infoParentNode

        guard let execNode = try self.source.nodes(at: folder).first(where: { $0.pathName.lastPathComponent == executableName }) else {
            return nil
        }

        return try self.source.seekableData(at: execNode)
    }

    private static func readInfo(source: Source) throws -> (Plist, parent: Source.Path, node: Source.Path)? {
        // dbg("reading info node from:", fs.containerURL.path)
        let rootNodes = try source.nodes(at: nil)
        //dbg("rootNodes:", rootNodes.map(\.pathName))

        func loadInfoPlist(from node: Source.Path) throws -> (Plist, parent: Source.Path, node: Source.Path)? {
            //dbg("attempting to load Info.plist from:", node.pathName)
            let contents = try source.nodes(at: node)
            guard let infoNode = contents.first(where: { $0.pathComponents.last == "Info.plist" }) else {
                // dbg("missing Info.plist node from:", contents.map(\.pathName))
                return nil
            }
            dbg("found Info.plist node:", infoNode.pathName) // , "from:", contents.map(\.pathName))

            return try (Plist(data: source.seekableData(at: infoNode).readData(ofLength: nil)), parent: node, node: infoNode)
        }

        func rootFolders(named names: Set<String>) -> [Source.Path] {
            rootNodes.filter({
                $0.pathIsDirectory && names.contains($0.pathName.lastPathComponent)
            })
        }

        if let contentsNode = rootFolders(named: ["Contents"]).first {
            // dbg("contentsNode", contentsNode)
            // check the "Contents/Info.plist" convention (macOS)
            return try loadInfoPlist(from: contentsNode)
        } else {
            for payloadNode in rootFolders(named: ["Payload", "Wrapper"]) {
                // dbg("payloadNode", payloadNode)
                // check the "Payload/App Name.app/Info.plist" convention
                let payloadContents = try source.nodes(at: payloadNode)
                guard let appNode = payloadContents.first(where: {
                    $0.pathIsDirectory && $0.pathName.hasSuffix(".app")
                }) else {
                    continue
                }

                return try loadInfoPlist(from: appNode)
            }
        }

        // finally, check for root-level .app files; this handles both the case where a macOS app is distributed in a .zip, as well as .ipa files that are missing a root "Payload/" folder
        for appNode in rootNodes.filter({
            $0.pathIsDirectory && $0.pathName.hasSuffix(".app")
        }) {
            // check the "App Name.app/Info.plist" convention
            let appContents = try source.nodes(at: appNode)

            dbg("appNode:", appNode.pathName, "appContents:", appContents.map(\.pathName))

            if let contentsNode = appContents.first(where: {
                $0.pathIsDirectory && $0.pathName.lastPathComponent == "Contents"
            }) {
                // dbg("contentsNode", contentsNode)
                // check the "AppName.app/Contents/Info.plist" convention (macOS)
                return try loadInfoPlist(from: contentsNode)
            }

            // fall back to "AppName.app/Info.plist" convention (iOS)
            return try loadInfoPlist(from: appNode)
        }

        dbg("returning nil")
        return nil
    }
}

extension AppBundle where Source.Path == URL {
    /// Returns a tuple of the paths to the ".app" file and the associated "Info.plist"
    public func appInfoURLs(plistName: String = "Info.plist") throws -> (app: Source.Path, info: Source.Path) {
        let rootNodes = try self.source.nodes(at: nil)

        if let containerFolder = rootNodes.first(where: { ["Payload", "Wrapper"].contains($0.pathName) }) {
            // .ipa file: Payload/AppName.app/Info.plist
            if let appFolder = try self.source.nodes(at: containerFolder).first(where: { $0.pathName.hasSuffix(".app") }) {
                if let infoPlist = try self.source.nodes(at: appFolder).first(where: { $0.pathName.split(separator: "/").last == .init(plistName) }) {
                    return (appFolder, infoPlist)
                }
            }
        } else if let contentsFolder = rootNodes.first(where: { ["Contents"].contains($0.pathName) }) {
            // .app file: AppName.app/Contents/Info.plist
            if let infoPlist = try self.source.nodes(at: contentsFolder).first(where: { $0.pathName.split(separator: "/").last == .init(plistName) }) {
                return (self.source.containerURL, infoPlist) // in this case, the app folder is the root itself
            }
        }

        throw CocoaError(.fileNoSuchFile)
    }

    #if os(macOS)
    /// Changes the given platform of this app bundle.
    /// - Parameters:
    ///   - resign: the signature to re-sign with
    ///   - params: the parameters set in the version
    /// - Returns: the URL of the changed app (which will be changed in-place)
    public func setPlatformVersion(resign: String?, params: [String]) async throws -> URL {
        let (appURL, infoURL) = try self.appInfoURLs()

        dbg("setting platform for:", appURL.path, "info:", infoURL.path)

        do {
            // doesn't seem to be necessary, but it actually is, at least for the initial launch of an app
            // let _ = try await Process.executeAsync(command: URL(fileURLWithPath: "/usr/bin/plutil"), ["-replace", "MinimumOSVersion", "-string", "11"] + params + [infoURL.path]).expect()
        }

        for exeFile in try self.machOBinaries() {
            dbg("setting version in:", exeFile.path)

            try await Process.setBuildVersion(url: exeFile, params: params).expect()
            if let identity = resign {
                try await Process.codesign(url: exeFile, identity: identity, deep: false, preserveMetadata: "entitlements").expect()
            }
        }

        if let identity = resign {
            try await Process.codesign(url: appURL, identity: identity, deep: true, preserveMetadata: "entitlements").expect()
        }

        return appURL
    }

    /// Sets the bundle platform to be `"maccatalyst"`.
    /// - Parameters:
    ///   - resign: the signature to resign with
    ///   - platformName: the name of the platform
    ///   - min: the minimum platform version
    ///   - max: the maximum platform version
    /// - Returns: the URL of the converted (in-place) application URL
    public func setCatalystPlatform(resign: String? = "-", name platformName: String = "maccatalyst", min: String = "11.0", max: String = "14.0") async throws -> URL {
        try await setPlatformVersion(resign: resign, params: [platformName, min, max])

    }
    #endif
}

/// A collection of data resources, such as a file system hierarchy or a zip archive of files.
public protocol DataWrapper : AnyObject {
    associatedtype Path : DataWrapperPath
    /// The root URL of this data wrapper
    var containerURL: URL { get }
    func nodes(at path: Path?) throws -> [Path]
    /// A pointer to the data at the given path; this could be either an in-memory structure (in the case if zip archives) or a wrapper around a FilePointer (in the case of a file system hierarchy)
    func seekableData(at path: Path) throws -> SeekableData

    /// All the paths contained in this wrapper
    var paths: [Path] { get }

    func find(pathsMatching: NSRegularExpression) -> [Path]
}

public protocol DataWrapperPath {
    /// The name of this path relative to the root of the file system
    var pathName: String { get }
    /// The size of the element represented by this path
    var pathSize: UInt64? { get }
    /// True if the path is a directory
    var pathIsDirectory: Bool { get }
}

extension DataWrapperPath {
    /// The individual components of this path.
    ///
    /// - TODO: on Windows do we need to use backslash?
    var pathComponents: [String] {
        // (pathName as NSString).pathComponents // not correct: will return "/" elements when they are at the beginning or else
        pathName
            .split(separator: "/", omittingEmptySubsequences: true)
            .map(\.description)
    }
}

// MARK: FileSystemDataWrapper

public class FileSystemDataWrapper : DataWrapper {
    public typealias Path = URL
    let root: Path
    let fm: FileManager
    public let paths: [URL]

    public init(root: Path, fileManager: FileManager = .default) throws {
        self.root = root
        self.fm = fileManager
        self.paths = try fileManager.deepContents(of: root, includeFolders: true, relativePath: true)
    }

    public var containerURL: URL {
        root
    }

    public func parent(of path: Path) throws -> Path? {
        path.deletingLastPathComponent()
    }

    /// FileManager nodes
    public func nodes(at path: Path?) throws -> [Path] {
        #if os(Linux) || os(Windows)
        try fm.contentsOfDirectory(at: path ?? root, includingPropertiesForKeys: [.fileSizeKey, .isDirectoryKey], options: []) // .producesRelativePathURLs unavailable
        #else
        try fm.contentsOfDirectory(at: path ?? root, includingPropertiesForKeys: [.fileSizeKey, .isDirectoryKey], options: [.producesRelativePathURLs])
        #endif
    }

    public func seekableData(at path: Path) throws -> SeekableData {
        // try URLSession.shared.fetch(request: URLRequest(url: path)).data
        // SeekableDataHandle(try Data(contentsOf: path), bigEndian: bigEndian)
        try SeekableFileHandle(FileHandle(forReadingFrom: path))
    }

    public func find(pathsMatching expression: NSRegularExpression) -> [Path] {
        paths.filter { path in
            expression.firstMatch(in: path.relativePath, range: path.relativePath.span) != nil
        }
    }
}

extension AppBundle where Source == FileSystemDataWrapper {
    public convenience init(folderAt url: URL) throws {
        try self.init(source: FileSystemDataWrapper(root: url))
    }
}


extension FileSystemDataWrapper.Path : DataWrapperPath {
    public var pathName: String {
        self.relativePath
    }

    public var pathSize: UInt64? {
        (try? self.resourceValues(forKeys: [.fileSizeKey]).fileSize).flatMap({ .init($0) }) ?? 0
    }

    public var pathIsDirectory: Bool {
        (try? self.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) ?? false
    }
}

// MARK: ZipArchiveDataWrapper

public class ZipArchiveDataWrapper : DataWrapper {
    public typealias Path = ZipArchivePath
    let archive: ZipArchive
    public let paths: [ZipArchivePath]

    public struct ZipArchivePath : DataWrapperPath {
        let path: String
        public let pathIsDirectory: Bool
        fileprivate let entry: ZipArchive.Entry?

        public var pathName: String {
            self.path
        }

        public var pathSize: UInt64? {
            entry?.uncompressedSize
        }
    }

    public init(archive: ZipArchive) {
        self.archive = archive

        var paths = archive.map { entry in
            ZipArchivePath(path: entry.path.deletingTrailingSlash, pathIsDirectory: entry.type == .directory, entry: entry)
        }

        // find all the paths that do not have a directory entry and synthesize a folder for it, since zip file are not guaranteed to have a proper directory entry for each file entry
        var allPaths = paths.map(\.path).set()
        let parentPaths = allPaths.map(\.deletingLastPathComponent).set()
        for parentPath in parentPaths.sorted() {
            var path = parentPath
            while !path.isEmpty {
                if allPaths.insert(path).inserted == true {
                    // synthesize a directory entry
                    // dbg("synthesizing parent directory:", parentPath)
                    paths.append(ZipArchivePath(path: path.deletingTrailingSlash, pathIsDirectory: true, entry: nil))
                }
                path = path.deletingLastPathComponent
            }
        }
        self.paths = paths
    }

    public var containerURL: URL {
        archive.url
    }

    public func parent(of path: Path) throws -> Path? {
        paths.first(where: { p in
            path.path.deletingLastPathComponent == p.path
        })
    }

    /// ZipArchive nodes
    public func nodes(at path: Path?) throws -> [Path] {
        if let parentPath = path {
            // brute-force scan all the entries; this should be made into a tree
            return paths.filter({ p in
                p.path.deletingLastPathComponent == parentPath.path
            })
        } else {
            let rootEntries = paths.filter({ p in
                p.pathComponents.count == 1 // all top-level entries
            })

            //dbg("root entries:", rootEntries.map(\.path))
            return rootEntries
        }
    }

    public func seekableData(at path: Path) throws -> SeekableData {
        guard let entry = path.entry else {
            throw AppError(NSLocalizedString("path was not backed by a zip entry", bundle: .module, comment: "error message"))
        }
        return SeekableDataHandle(try archive.extractData(from: entry))
    }

    public func find(pathsMatching expression: NSRegularExpression) -> [Path] {
        paths.filter { path in
            expression.firstMatch(in: path.path, range: path.path.span) != nil
        }
    }
}

// Utilities from NSString cast
private extension String {
    var deletingTrailingSlash: String {
        var str = self
        while str.last == "/" {
            str = String(str.dropLast())
        }
        return str
    }

    var deletingLastPathComponent: String {
        (self as NSString).deletingLastPathComponent
    }

    var lastPathComponent: String {
        (self as NSString).lastPathComponent
    }
}

extension AppBundle where Source == ZipArchiveDataWrapper {
    public convenience init(zipArchiveAt url: URL) throws {
        guard let zip = ZipArchive(url: url, accessMode: .read) else {
            throw URLError(.badURL)
        }
        try self.init(source: ZipArchiveDataWrapper(archive: zip))
    }
}

extension AppBundle {
    /// Returns `true` if the data at the specified path has the Mach-O magic header.
    public func maybeMachO(at path: Source.Path) throws -> Bool {
        // this will throw
        let data = try source.seekableData(at: path)
        // but this will swallow exceptions, since MachOBinary is assuming sufficient header size
        return (try? MachOBinary(binary: data).getBinaryType(fromSliceStartingAt: 0)) != nil
    }

    /// Returns the list of paths that are probably (based on magic header) Mach-O binaries,
    /// either executable or dynamic libraries.
    public func machOBinaries() throws -> [Source.Path] {
        try prf {
            try source.paths
                .filter { fileURL in
                    try (fileURL.pathIsDirectory == false)
                        && (fileURL.pathSize ?? 0 > 1024)
                        && (self.maybeMachO(at: fileURL) == true)
                }
        }
    }
}


// MARK: Internal Mach-O structures

class MachOBinary {
    enum Error: Swift.Error {
        case binaryOpeningError
        case unknownBinaryFormat
        case codeSignatureCommandMissing
        case signatureReadingError
        case badMagicInSignature
        case unsupportedFatBinary

        var localizedDescription: String {
            switch self {
            case .binaryOpeningError:
                return "Error while opening application binary for reading"
            case .unknownBinaryFormat:
                return "The binary format is not supported"
            case .codeSignatureCommandMissing:
                return "Unable to find code signature load command"
            case .signatureReadingError:
                return "Signature reading error occurred"
            case .unsupportedFatBinary:
                return "Fat application binaries are unsupported"
            case .badMagicInSignature:
                return "The code page magic was incorrect"
            }
        }
    }

    fileprivate enum BinaryType {
        struct HeaderData {
            let headerSize: Int
            let commandCount: Int
        }
        case singleArch(headerInfo: HeaderData)
        case fat(header: MachOFatHeader)
    }

    private let binary: SeekableData

    init(binary: SeekableData) throws {
        self.binary = binary.reversedEndian()
    }

    fileprivate func getBinaryType(fromSliceStartingAt offset: SeekableData.Offset) throws -> BinaryType? {
        try binary.seek(to: offset)
        let header: MachOHeader = try binary.readBinary()
        let commandCount = Int(header.ncmds)
        switch header.magic {
        case MachOMagic.MH_MAGIC:
            let data = BinaryType.HeaderData(headerSize: MemoryLayout<MachOHeader>.size, commandCount: commandCount)
            return .singleArch(headerInfo: data)
        case MachOMagic.MH_MAGIC_64:
            let data = BinaryType.HeaderData(headerSize: MemoryLayout<MachOHeader64>.size, commandCount: commandCount)
            return .singleArch(headerInfo: data)
//        case MachOMagic.FAT_MAGIC: // doesn't work
//            try binary.seek(to: offset)
//            let data: MachOFatHeader = try binary.readBinary()
//            return .fat(header: data)
//        default:
//            return nil
        default:
            try binary.seek(to: offset)
            let fatHeader: MachOFatHeader = try binary.readBinary()
            return CFSwapInt32(fatHeader.magic) == MachOMagic.FAT_MAGIC ? .fat(header: fatHeader) : nil
        }
    }

    func readEntitlements(fromSliceStartingAt offset: SeekableData.Offset = 0) throws -> [AppEntitlements] {
        switch try getBinaryType(fromSliceStartingAt: offset) {
        case .singleArch(let headerInfo):
            let headerSize = headerInfo.headerSize
            let commandCount = headerInfo.commandCount
            //dbg("singleArch:", "offset:", offset, "headerSize:", headerSize, "commandCount:", commandCount)
            return try readEntitlementsFromBinarySlice(startingAt: offset + .init(headerSize), cmdCount: commandCount)
        case .fat(header: let header):
            return try readEntitlementsFromFatBinary(header)
        case .none:
            throw Error.unknownBinaryFormat
        }
    }

    private func readEntitlementsFromBinarySlice(startingAt offset: SeekableData.Offset, cmdCount: Int) throws -> [AppEntitlements] {
        try binary.seek(to: offset)
        var entitlements: [AppEntitlements] = []
        for _ in 0..<cmdCount {
            //dbg("checking for entitlements in offset:", offset, "index:", index, "count:", cmdCount)
            let command: LoadCommand = try binary.readBinary()
            if command.cmd == MachOMagic.LC_CODE_SIGNATURE {
                let signatureOffset: UInt32 = try binary.readUInt32()
                //dbg("checking for sig in signatureOffset:", signatureOffset, "offset:", offset, "index:", index, "count:", cmdCount)
                if let ent = try readEntitlementsFromSignature(startingAt: signatureOffset) {
                    entitlements.append(ent)
                }
            }
            try binary.seek(to: binary.offset() + .init(command.cmdsize - UInt32(MemoryLayout<LoadCommand>.size)))
        }

        return entitlements
    }

    private func readEntitlementsFromFatBinary(_ header: MachOFatHeader) throws -> [AppEntitlements] {
        let archCount = CFSwapInt32(header.nfat_arch)
        //dbg("readEntitlementsFromFatBinary:", header, "archCount:", archCount)

        if archCount <= 0 {
            throw Error.unsupportedFatBinary
        }

//        let arches: [FatArch] = try (0..<archCount).map { _ in
//            try binary.readBinary()
//        }
        var arches: [FatArch] = []
        for _ in 0..<archCount {
            arches.append(try binary.readBinary())
        }

        var entitlementList: [AppEntitlements] = []

        for arch in arches {
            let offset = CFSwapInt32(arch.offset)
            let size = CFSwapInt32(arch.size)
            //dbg("arch:", "offset:", offset, "size:", size)

            let entitlements: [AppEntitlements]

//            if false {
//                // this should work, but it fails at readEntitlementsFromSignature
//                entitlements = try readEntitlements(fromSliceStartingAt: .init(offset))
//            } else {
                try binary.seek(to: .init(offset))
                let slice = try binary.readData(ofLength: .init(size))
                entitlements = try MachOBinary(binary: SeekableDataHandle(slice)).readEntitlements(fromSliceStartingAt: 0)
//            }

            //dbg("fat binary entitlements:", entitlements)
            entitlementList.append(contentsOf: entitlements)
        }

        return entitlementList

    }

    private func readEntitlementsFromSignature(startingAt offset: UInt32) throws -> AppEntitlements? {
        try binary.seek(to: .init(offset))
        let metaBlob: CSSuperBlob = try binary.readBinary()
        //dbg("checking for magic in superblob at:", offset, ":", CFSwapInt32(metaBlob.magic))
        if CFSwapInt32(metaBlob.magic) != CSMagic.embeddedSignature {
            throw Error.badMagicInSignature
        }

        let metaBlobSize = UInt32(MemoryLayout<CSSuperBlob>.size)
        let blobSize = UInt32(MemoryLayout<CSBlob>.size)
        let itemCount = CFSwapInt32(metaBlob.count)
        //dbg("itemCount:", itemCount)
        for index in 0..<itemCount {
            //dbg("checking code index:", index, "/", itemCount)
            let readOffset = Int(offset + metaBlobSize + index * blobSize)
            try binary.seek(to: SeekableData.Offset(readOffset))
            let blob: CSBlob = try binary.readBinary()
            try binary.seek(to: SeekableData.Offset(offset + CFSwapInt32(blob.offset)))
            let blobMagic = CFSwapInt32(try binary.readUInt32())
            if blobMagic == CSMagic.embededEntitlements {
                let signatureLength = CFSwapInt32(try binary.readUInt32())
                let signatureData = try binary.readData(ofLength: .init(signatureLength) - 8)
                return AppEntitlements.readEntitlements(from: signatureData)
            }
        }

        // no entitlements
        return nil
    }
}

enum MachOMagic {
    static let LC_SEGMENT = UInt32(0x01)
    static let LC_SYMTAB = UInt32(0x02)
    static let LC_DYSYMTAB = UInt32(0x0b)
    static let LC_LOAD_DYLIB = UInt32(0x0c)
    static let LC_ID_DYLIB = UInt32(0x0d)
    static let LC_SEGMENT_64 = UInt32(0x19)
    static let LC_UUID = UInt32(0x1b)
    static let LC_CODE_SIGNATURE = UInt32(0x1d) // MachO.LC_CODE_SIGNATURE
    static let LC_SEGMENT_SPLIT_INFO = UInt32(0x1e)
    //static let LC_REEXPORT_DYLIB = UInt32(0x1f | LC_REQ_DYLD)
    static let LC_ENCRYPTION_INFO = UInt32(0x21)
    static let LC_DYLD_INFO = UInt32(0x22)
    //static let LC_DYLD_INFO_ONLY = UInt32(0x22 | LC_REQ_DYLD)
    static let LC_ENCRYPTION_INFO_64 = UInt32(0x2c)

    static var MH_MAGIC: UInt32 {
        0xfeedface /* MachO.MH_MAGIC */
    }

    static var MH_MAGIC_64: UInt32 {
        0xfeedfacf /* MachO.MH_MAGIC_64 */
    }

    static var FAT_MAGIC: UInt32 {
        0xcafebabe /* MachO.FAT_MAGIC */
    }
}

private extension SeekableData {
    func readBinary<T: BinaryReadable>() throws -> T {
        try T(data: self)
    }
}

private protocol BinaryReadable {
    init(data: SeekableData) throws
}

extension UInt32 : BinaryReadable {
    init(data: SeekableData) throws {
        self = try data.readUInt32()
    }
}

struct CSSuperBlob {
    var magic: UInt32
    var length: UInt32
    var count: UInt32
}

extension CSSuperBlob : BinaryReadable {
    init(data: SeekableData) throws {
        self = try CSSuperBlob(magic: data.readUIntX(), length: data.readUIntX(), count: data.readUIntX())
    }
}

struct CSBlob {
    var type: UInt32
    var offset: UInt32
}

extension CSBlob : BinaryReadable {
    init(data: SeekableData) throws {
        self = try CSBlob(type: data.readUIntX(), offset: data.readUIntX())
    }
}

struct CSMagic {
    static let embeddedSignature: UInt32 = 0xfade0cc0
    static let embededEntitlements: UInt32 = 0xfade7171
}

//const cpuType = {
//  0x00000003: 'i386',
//  0x80000003: 'x86_64',
//  0x00000009: 'arm',
//  0x80000009: 'arm64',
//  0x00000000: 'arm64',
//  0x0000000a: 'ppc_32',
//  0x8000000a: 'ppc_64'
//};

typealias cpu_type_t = Int32
typealias cpu_subtype_t = Int32
typealias cpu_threadtype_t = Int32

struct MachOHeader {
    var magic: UInt32 /* mach magic number identifier */
    var cputype: cpu_type_t /* cpu specifier */
    var cpusubtype: cpu_subtype_t /* machine specifier */
    var filetype: UInt32 /* type of file */
    var ncmds: UInt32 /* number of load commands */
    var sizeofcmds: UInt32 /* the size of all the load commands */
    var flags: UInt32 /* flags */
}

extension MachOHeader : BinaryReadable {
    init(data: SeekableData) throws {
        self = try MachOHeader(magic: data.readUIntX(), cputype: data.readInt32(), cpusubtype: data.readInt32(), filetype: data.readUIntX(), ncmds: data.readUIntX(), sizeofcmds: data.readUIntX(), flags: data.readUIntX())
    }
}

/*
 * The 64-bit mach header appears at the very beginning of object files for
 * 64-bit architectures.
 */
struct MachOHeader64 {
    var magic: UInt32 /* mach magic number identifier */
    var cputype: cpu_type_t /* cpu specifier */
    var cpusubtype: cpu_subtype_t /* machine specifier */
    var filetype: UInt32 /* type of file */
    var ncmds: UInt32 /* number of load commands */
    var sizeofcmds: UInt32 /* the size of all the load commands */
    var flags: UInt32 /* flags */
    var reserved: UInt32 /* reserved */
}

struct MachOFatHeader {
    var magic: UInt32 /* FAT_MAGIC or FAT_MAGIC_64 */
    var nfat_arch: UInt32 /* number of structs that follow */
}

extension MachOFatHeader : BinaryReadable {
    init(data: SeekableData) throws {
        self = try MachOFatHeader(magic: data.readUIntX(), nfat_arch: data.readUIntX())
    }
}

// mach-o loader.h `load_command`
struct LoadCommand {
    public var cmd: UInt32 /* type of load command */
    public var cmdsize: UInt32 /* total size of command in bytes */
}

extension LoadCommand : BinaryReadable {
    init(data: SeekableData) throws {
        self = try LoadCommand(cmd: data.readUIntX(), cmdsize: data.readUIntX())
    }
}

/// From mach-o fat.h: `struct fat_arch`222
struct FatArch {
    var cputype: cpu_type_t /* cpu specifier (int) */
    var cpusubtype: cpu_subtype_t /* machine specifier (int) */
    var offset: UInt32 /* file offset to this object file */
    var size: UInt32 /* size of this object file */
    var align: UInt32 /* alignment as a power of 2 */
}

extension FatArch : BinaryReadable {
    init(data: SeekableData) throws {
        self = try FatArch(cputype: data.readInt32(), cpusubtype: data.readInt32(), offset: data.readUIntX(), size: data.readUIntX(), align: data.readUIntX())
    }
}
