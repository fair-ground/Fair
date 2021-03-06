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

public extension Bundle {
    /// The URL for the `Fair` module's resource bundle
    static var fairBundleURL: URL! {
        Bundle.module.url(forResource: "Bundle", withExtension: nil)
    }
}

public extension Bundle {
    /// Returns the bundle's `infoDictionary` key value
    subscript<T>(info key: PropertyListKey) -> T? {
        self.infoDictionary?[key.plistKey] as? T
    }

    /// The bundle's `CFBundleName`
    var bundleName: String? { self[info: .CFBundleName] }

    /// The bundle's `CFBundleDisplayName`
    var bundleDisplayName: String? { self[info: .CFBundleDisplayName] }

    /// The bundle's `CFBundleIdentifier`
    var bundleID: String? { self[info: .CFBundleIdentifier] }

    /// The bundle's `CFBundleVersion` incrementing counter number
    var bundleVersionCounter: Int? { self[info: .CFBundleVersion] }

    /// The bundle's `CFBundleShortVersionString` semantic version string
    var bundleVersionString: String? { self[info: .CFBundleShortVersionString] }

    /// The `CFBundleShortVersionString` converted to an AppVersion. Note that these are always considered non-prerelease since the prerelease flag is an ephemeral part of the hub's release, and is not indicated in the app's plist in any way
    var bundleVersion: AppVersion? { bundleVersionString.flatMap({ AppVersion(string: $0, prerelease: false) }) }

    /// The name of the package's app/org, which is the bundle's name with hyphens for spaces
    var appOrgName: String? {
        if let bundleID = bundleID, let lastBundleComponent = bundleID.split(separator: ".").last {
            return lastBundleComponent.rehyphenated()
        } else {
            return bundleName?.rehyphenated()
        }
    }
}


extension Bundle {
    /// Returns the resources bundle for `FairCore`
    public static var fairCore: Bundle { Bundle.module }

    /// Returns the info dictionary for the `FairCore.plist` resource
    public static let fairCoreInfo = Plist(rawValue: Info as NSDictionary) // Info should be generated manually with: plutil -convert swift Info.plist

    /// The version of the FairCore library in use
    public static let fairCoreVersion = fairCoreInfo.CFBundleShortVersionString.flatMap({ AppVersion.init(string: $0, prerelease: false) })

    /// Returns all the URLs in the given folder of the bundle
    public func bundlePaths(in folder: String, includeFolders: Bool) throws -> [URL] {
        guard let bundleURL = url(forResource: folder, withExtension: nil, subdirectory: "Bundle") else {
            throw CocoaError(.fileReadNoSuchFile)
        }

        return try FileManager.default.deepContents(of: bundleURL, includeFolders: includeFolders)
    }

    /// Loads the resource with the given name
    public func loadResource(named name: String, options: Data.ReadingOptions = .mappedIfSafe) throws -> Data {
        guard let url = url(forResource: name, withExtension: nil, subdirectory: nil) else {
            throw CocoaError(.fileReadNoSuchFile)
        }
        return try Data(contentsOf: url, options: options)
    }

    /// Loads the resource with the given name from the `Bundle` resource path, which can be used to store non-flattened resource hierarchies
    public func loadBundleResource(named name: String, options: Data.ReadingOptions = .mappedIfSafe) throws -> Data {
        guard let url = url(forResource: name, withExtension: nil, subdirectory: "Bundle") else {
            throw CocoaError(.fileReadNoSuchFile)
        }
        return try Data(contentsOf: url, options: options)
    }
}

public extension Plist {
    /// Returns the untypes content of the given plist key
    func plistValue(for key: PropertyListKey) -> Any? {
        rawValue[key.plistKey]
    }

    /// Returns the string contents of the given plist key
    func stringValue(for key: PropertyListKey) -> String? {
        guard let value = plistValue(for: key) as? String else {
            return nil
        }

        if value.isEmpty {
            return nil
        }

        return value

    }

    /// The value of the `CFBundleIdentifier` string
    var CFBundleIdentifier: String? {
        stringValue(for: .CFBundleIdentifier)
    }


    /// The value of the `CFBundleName` string
    var CFBundleName: String? {
        stringValue(for: .CFBundleName)
    }

    /// The value of the `CFBundleDisplayName` string
    var CFBundleDisplayName: String? {
        stringValue(for: .CFBundleDisplayName)
    }


    /// The value of the `CFBundleVersion` string
    var CFBundleVersion: String? {
        stringValue(for: .CFBundleVersion)
    }

    /// The value of the `CFBundleShortVersionString` string
    var CFBundleShortVersionString: String? {
        stringValue(for: .CFBundleShortVersionString)
    }

    /// The value of the `CFBundleExecutable` string
    var CFBundleExecutable: String? {
        stringValue(for: .CFBundleExecutable)
    }

    /// The value of the `DTPlatformName` string
    var DTPlatformName: String? {
        stringValue(for: .DTPlatformName)
    }
}

/// A key in a ``Plist`` holding a standard `Info.plist`.
///
/// Some common properties include:
///
///  - ``CFBundleIdentifier``
///  - ``CFBundleExecutable``
///  - ``CFBundleName``
///  - ``CFBundleDisplayName``
///  - ``CFBundleVersion``
///  - ``CFBundleShortVersionString``
///
/// See:
/// https://developer.apple.com/documentation/bundleresources/information_property_list/bundle_configuration
public struct PropertyListKey : RawCodable {
    public static let CFBundleIdentifier = Self("CFBundleIdentifier") // e.g., "app.My-App"
    public static let CFBundleExecutable = Self("CFBundleExecutable") // e.g., "My App"
    public static let CFBundleName = Self("CFBundleName") // e.g., "My App"
    public static let CFBundleDisplayName = Self("CFBundleDisplayName") // e.g., "My App"
    public static let CFBundleVersion = Self("CFBundleVersion") // e.g., 699162671
    public static let CFBundleShortVersionString = Self("CFBundleShortVersionString")

    public static let CFBundlePackageType = Self("CFBundlePackageType") // e.g., "APPL"
    public static let CFBundleSupportedPlatforms = Self("CFBundleSupportedPlatforms") // e.g., ["iPhoneOS"]
    public static let CFBundleInfoDictionaryVersion = Self("CFBundleInfoDictionaryVersion") // e.g., 6.0

    public static let CFBundleIconName = Self("CFBundleIconName") // e.g., "AppIcon"
    public static let CFBundleIcons = Self("CFBundleIcons")
    public static let CFBundlePrimaryIcon = Self("CFBundlePrimaryIcon")
    public static let CFBundleIconFiles = Self("CFBundleIconFiles")

    public static let NSHumanReadableCopyright = Self("NSHumanReadableCopyright")

    public static let DTSDKName = Self("DTSDKName") // e.g., "iphoneos15.0" or "macosx12.0"
    public static let DTSDKBuild = Self("DTSDKBuild") // e.g., 19A5297f

    public static let DTPlatformBuild = Self("DTPlatformBuild") // e.g., 19A5297f
    public static let DTPlatformVersion = Self("DTPlatformVersion") // e.g., 15.0 or 12.0
    public static let DTPlatformName = Self("DTPlatformName") // e.g., "iphoneos" or "macosx"
    public static let DTCompiler = Self("DTCompiler") // e.g., "com.apple.compilers.llvm.clang.1_0"

    public static let DTXcode = Self("DTXcode") // e.g., 1300
    public static let DTXcodeBuild = Self("DTXcodeBuild") // e.g., "13A5192j"

    public static let LSMinimumSystemVersion = Self("LSMinimumSystemVersion")
    public static let LSApplicationCategoryType = Self("LSApplicationCategoryType")
    public static let LSApplicationSecondaryCategoryType = Self("LSApplicationSecondaryCategoryType")
    public static let LSFileQuarantineEnabled = Self("LSFileQuarantineEnabled")
    public static let LSBackgroundOnly = Self("LSBackgroundOnly")
    public static let LSUIElement = Self("LSUIElement")
    public static let LSUIPresentationMode = Self("LSUIPresentationMode")

    public static let MinimumOSVersion = Self("MinimumOSVersion")
    public static let BuildMachineOSBuild = Self("BuildMachineOSBuild") // e.g., 20G71

    public static let UIDeviceFamily = Self("UIDeviceFamily") // e.g., [1,2]
    public static let UIRequiredDeviceCapabilities = Self("UIRequiredDeviceCapabilities")
    public static let UISupportedInterfaceOrientations = Self("UISupportedInterfaceOrientations") // e.g., [UIInterfaceOrientationPortrait, UIInterfaceOrientationPortraitUpsideDown, UIInterfaceOrientationLandscapeLeft, UIInterfaceOrientationLandscapeRight]

    public let rawValue: String
    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    public init(_ rawValue: String) {
        self.rawValue = rawValue
    }

    /// Returns the key for the plist
    public var plistKey: String {
        rawValue
    }
}

/// A semantic version of an app with a `major`, `minor`, and `patch` component.
public struct AppVersion : Pure, Comparable {
    /// The lowest possible version that can exist
    public static let min = AppVersion(major: .min, minor: .min, patch: .min, prerelease: true)
    /// The highest possible version that can exist
    public static let max = AppVersion(major: .max, minor: .max, patch: .max, prerelease: false)

    public let major, minor, patch: UInt
    public let prerelease: Bool

    public init(major: UInt, minor: UInt, patch: UInt, prerelease: Bool) {
        self.major = major
        self.minor = minor
        self.patch = patch
        self.prerelease = prerelease
    }

    /// Initialize the version by parsing the string
    public init?(string versionString: String, prerelease: Bool) {
        guard let version = Self.parse(string: versionString, prerelease: prerelease) else {
            return nil
        }
        self = version
    }

    private static func parse(string versionString: String, prerelease: Bool) -> Self? {
        let versionElements = versionString.split(separator: ".", omittingEmptySubsequences: false).map({ UInt(String($0)) })
        if versionElements.count != 3 { return nil }
        let versionNumbers = versionElements.compactMap({ $0 })
        if versionNumbers.count != 3 { return nil }


        let major = versionNumbers[0]
        let minor = versionNumbers[1]
        let patch = versionNumbers[2]
        let prerelease = prerelease

        let version = Self(major: major, minor: minor, patch: patch, prerelease: prerelease)

        // this is what prevents us from successfully parsing ".1.2.3"
        if !version.versionString.hasPrefix("\(version.major)") { return nil }
        if !version.versionString.hasSuffix("\(version.patch)") { return nil }

        return version
    }

    public static func < (lhs: AppVersion, rhs: AppVersion) -> Bool {
        lhs.major < rhs.major
            || (lhs.major == rhs.major && lhs.minor < rhs.minor)
            || (lhs.major == rhs.major && lhs.minor == rhs.minor && lhs.patch < rhs.patch)
        || (lhs.major == rhs.major && lhs.minor == rhs.minor && lhs.patch == rhs.patch && (lhs.prerelease ? 0 : 1) < (rhs.prerelease ? 0 : 1))

    }

    /// The version string in the form `major`.`minor`.`patch`
    public var versionString: String {
        "\(major).\(minor).\(patch)"
    }

    /// The version string in the form `major`.`minor`.`patch` with a "??" character appended if this is a pre-release
    public var versionStringExtended: String {
        versionString + (prerelease == true ? "??" : "")
    }

    public func encode(to encoder: Encoder) throws {
        try versionStringExtended.encode(to: encoder)
    }

    public init(from decoder: Decoder) throws {
        let str = try decoder.singleValueContainer().decode(String.self)
        let version = Self.init(string: str, prerelease: false)
        guard let version = version else {
            throw Errors.cannotParseVersionString(str)
        }
        self = version
    }

    public enum Errors : Error {
        case cannotParseVersionString(String)
    }
}

extension FileManager {
    /// Returns the deep contents of the given file URL, with an option to preserve relative paths in the URLs.
    public func deepContents(of parentFolder: URL, includeFolders: Bool, relativePath: Bool = false) throws -> [URL] {
        // note that we would like the relativePath option to use
        // FileManager.DirectoryEnumerationOptions.producesRelativePathURLs
        // but it is not available on Linux, so we need to synthesize the relative URLs ourselves
        guard let walker = self.enumerator(at: parentFolder, includingPropertiesForKeys: [.isDirectoryKey, .isSymbolicLinkKey, .fileSizeKey], options: []) else {
            throw CocoaError(.fileReadNoSuchFile)
        }

        var paths: [URL] = []
        for case let url as URL in walker {
            if try includeFolders || url.resourceValues(forKeys: [.isDirectoryKey]).isDirectory != true {
                if !relativePath {
                    // we don't need to synthesize relative URLs
                    paths.append(url)
                } else {
                    let resolvedParent = try findCommonRelative(from: url, parent: parentFolder) ?? parentFolder
                    //dbg("parentFolder:", parentFolder, "resolvedParent:", resolvedParent)
                    let relativePath = url.pathComponents.suffix(from: resolvedParent.pathComponents.count).joined(separator: "/")
                    // not that the relative URL will be relative to the specified parent folder, rather than to the path that it resolves to
                    let relativeURL = URL(fileURLWithPath: relativePath, relativeTo: parentFolder)
                    paths.append(relativeURL)
                }
            }
        }

        return paths
    }

    /// Finds a common root from the given url to the specified parent.
    /// Handles the case where the parent may be a link to elsewhere, and the check urls are in the destination of that link
    private func findCommonRelative(from url: URL, parent: URL) throws -> URL? {
        // the common case where the child URL just includes the path of the parent
        if url.path.hasPrefix(parent.path) {
            return parent
        }

        var checkURL = url
        var rel: URLRelationship = .contains
        while rel == .contains {
            try getRelationship(&rel, ofDirectoryAt: parent, toItemAt: checkURL)
            if rel == .same {
                return checkURL
            }
            checkURL = checkURL.deletingLastPathComponent()
        }
        return nil
    }

    /// Attempts to place the item at the given URL in the Trash on platforms that support it.
    /// An error will be thrown if the operation fails, and on platforms that support Trash, the return value will be the URL of the trashed item.
    @discardableResult public func trash(url: URL) throws -> URL? {
        #if canImport(AppKit)
        var trashResult: NSURL? = nil
        try trashItem(at: url, resultingItemURL: &trashResult)
        return trashResult as URL?
        #else
        try removeItem(at: url)
        return nil
        #endif
    }

    /// Returns true if the folder is a directory, false if it is a file,
    /// and nil if it doesn't exist
    public func isDirectory(url: URL) -> Bool? {
        var isDir: ObjCBool = false
        if !fileExists(atPath: url.path, isDirectory: &isDir) {
            return nil
        }
        return isDir.boolValue
    }

    /// Returns true if the path at the given url has the `URLResourceKey.quarantinePropertiesKey` bit set.
    public func isQuarantined(at url: URL) throws -> Bool {
        #if os(macOS)
        try (url as NSURL).resourceValues(forKeys: [URLResourceKey.quarantinePropertiesKey]).isEmpty == false
        #else
        false
        #endif
    }

    /// Removes any quarantine properties from the given URL
    public func clearQuarantine(at url: URL) throws {
        #if os(macOS)
        // try to clear the quarantine flag
        do {
//            let quarantineProperties: [String: Any] = [
//                kLSQuarantineAgentNameKey as String: "App Fair",
//                kLSQuarantineTypeKey as String: kLSQuarantineTypeWebDownload,
//                kLSQuarantineDataURLKey as String: dataURL,
//                kLSQuarantineOriginURLKey as String: originURL
//            ]

            try (url as NSURL).setResourceValue(nil, forKey: .quarantinePropertiesKey)
        } catch {
            dbg("unable to clear quarantine flag for:", url.path, error)
        }

        // check to ensure we have cleared the props
        if try isQuarantined(at: url) == true {
            dbg("found quarantine xattr for:", url.path)
            throw CocoaError(.executableNotLoadable)
        }
        #endif
    }

}

public extension URL {
    /// The directory for temporary files
    static var tmpdir: URL { URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true) }
}

extension URL {
    /// Attempts to create a cached file based on the contents of the given URL's folder ending with ".parts".
    /// This folder is expected to contain individual files which, when concatinated in alphabetical order, will re-create the specified file
    ///
    /// This allows large files to be split into individual parts to work around [SPM's lack of git LFS support](https://forums.swift.org/t/swiftpm-with-git-lfs/42396/6).
    public func assemblePartsCache(overwrite: Bool = false) throws -> URL {
        let fm = FileManager.default

        if fm.isDirectory(url: self) != true {
            throw CocoaError(.fileReadUnsupportedScheme)
        }

        let cacheBase = self.deletingPathExtension().lastPathComponent
        let cacheFile = try fm.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: self, create: true).appendingPathComponent(cacheBase)

        let parts = try self.fileChildren(deep: false, keys: [.fileSizeKey, .contentModificationDateKey])
            .filter { fm.isDirectory(url: $0) == false }
            .filter { $0.lastPathComponent.hasPrefix(".") == false }
            .sorting(by: \.lastPathComponent)

        let totalSize = parts.compactMap({ $0.fileSize() }).reduce(0, +)
        let lastModified = parts.compactMap(\.modificationDate).sorted().last

        if fm.isReadableFile(atPath: cacheFile.path) && overwrite == false {
            // ensure that the file size is equal to the sum of the individual path components
            // note that we skip any checksum validation here, so we expect the resource to be trusted (which it will be if it is included in a signed app bundle)
            let cacheNewerThanParts = (cacheFile.modificationDate ?? Date()) > (lastModified ?? Date())
            if cacheFile.fileSize() == totalSize && cacheNewerThanParts == true {
                return cacheFile
            } else {
                if !cacheNewerThanParts {
                    dbg("rebuilding cache file:", cacheFile.path, "modified:", cacheFile.modificationDate, "latest part:", lastModified)
                }
            }
        }

        dbg("assembling parts in", self.path, "into:", cacheFile.path, "size:", totalSize.localizedByteCount(), "from:", parts.map(\.lastPathComponent))

        // clear any existing cache file that we aren't using (e.g., due to bad size)
        try? FileManager.default.removeItem(at: cacheFile)

        // file must exist before writing
        FileManager.default.createFile(atPath: cacheFile.path, contents: nil, attributes: nil)
        let fh = try FileHandle(forWritingTo: cacheFile)
        defer { try? fh.close() }

        for part in parts {
            try fh.write(contentsOf: Data(contentsOf: part))
        }

        return cacheFile
    }

    /// Returns the contents of the given file URL's folder.
    /// - Parameter deep: whether to retrieve the deep or shallow contents
    /// - Parameter skipHidden: whether to skip hidden files
    /// - Parameter keys: resource keys to pre-cache, such as `[.fileSizeKey]`
    /// - Returns: the list of URL children relative to the current URL's folder
    public func fileChildren(deep: Bool, skipHidden: Bool = false, keys: [URLResourceKey]? = nil) throws -> [URL] {
        let fm = FileManager.default

        if fm.isDirectory(url: self) != true {
            throw CocoaError(.fileReadUnknown)
        }

        var mask: FileManager.DirectoryEnumerationOptions = skipHidden ? [.skipsHiddenFiles] : []

        if deep == false {
            // we could alternatively use `enumerator` with the `FileManager.DirectoryEnumerationOptions.skipsSubdirectoryDescendants` mask
            return try fm.contentsOfDirectory(at: self, includingPropertiesForKeys: keys, options: mask) // ???the only supported option is skipsHiddenFiles???
        } else {
            #if !os(Linux) && !os(Windows)
            mask.insert(.producesRelativePathURLs) // unavailable on windows
            #endif

            guard let walker = fm.enumerator(at: self, includingPropertiesForKeys: keys, options: mask) else {
                throw CocoaError(.fileReadNoSuchFile)
            }

            var paths: [URL] = []
            for path in walker {
                if let url = path as? URL {
                    paths.append(url)
                } else if let path = path as? String {
                    paths.append(URL(fileURLWithPath: path, relativeTo: self))
                }
            }

            return paths
        }
    }
}

public extension Decodable {
    /// Initialized this instance from a JSON string
    init(json: Data, decoder: @autoclosure () -> JSONDecoder = JSONDecoder(), allowsJSON5: Bool = true, dataDecodingStrategy: JSONDecoder.DataDecodingStrategy? = nil, dateDecodingStrategy: JSONDecoder.DateDecodingStrategy? = nil, nonConformingFloatDecodingStrategy: JSONDecoder.NonConformingFloatDecodingStrategy? = nil, keyDecodingStrategy: JSONDecoder.KeyDecodingStrategy? = nil, userInfo: [CodingUserInfoKey : Any]? = nil) throws {
        let decoder = decoder()
    #if !os(Linux) && !os(Windows)
        if #available(macOS 12.0, iOS 15.0, *) {
            decoder.allowsJSON5 = allowsJSON5
        }
    #endif

        if let dateDecodingStrategy = dateDecodingStrategy {
            decoder.dateDecodingStrategy = dateDecodingStrategy
        }

        if let dataDecodingStrategy = dataDecodingStrategy {
            decoder.dataDecodingStrategy = dataDecodingStrategy
        }

        if let nonConformingFloatDecodingStrategy = nonConformingFloatDecodingStrategy {
            decoder.nonConformingFloatDecodingStrategy = nonConformingFloatDecodingStrategy
        }

        if let keyDecodingStrategy = keyDecodingStrategy {
            decoder.keyDecodingStrategy = keyDecodingStrategy
        }

        if let userInfo = userInfo {
            decoder.userInfo = userInfo
        }

        self = try decoder.decode(Self.self, from: json)
    }
}

extension Encodable {
    /// Encode this instance as JSON data
    /// - Parameters:
    ///   - encoder: the encoder to use, defaulting to a stock `JSONEncoder`
    ///   - outputFormatting: formatting options, defaulting to `.sortedKeys` and `.withoutEscapingSlashes`
    ///   - dateEncodingStrategy: the strategy for decoding `Date` instances
    ///   - dataEncodingStrategy: the strategy for decoding `Data` instances
    ///   - nonConformingFloatEncodingStrategy: the strategy for handling non-conforming floats
    ///   - keyEncodingStrategy: the strategy for encoding keys
    ///   - userInfo: additional user info to pass to the encoder
    /// - Returns: the JSON-encoded `Data`
    @inlinable public func json(encoder: @autoclosure () -> JSONEncoder = JSONEncoder(), outputFormatting: JSONEncoder.OutputFormatting? = [.sortedKeys, .withoutEscapingSlashes], dateEncodingStrategy: JSONEncoder.DateEncodingStrategy? = nil, dataEncodingStrategy: JSONEncoder.DataEncodingStrategy? = nil, nonConformingFloatEncodingStrategy: JSONEncoder.NonConformingFloatEncodingStrategy? = nil, keyEncodingStrategy: JSONEncoder.KeyEncodingStrategy? = nil, userInfo: [CodingUserInfoKey : Any]? = nil) throws -> Data {
        let encoder = encoder()
        if let outputFormatting = outputFormatting {
            encoder.outputFormatting = outputFormatting
        }

        if let dateEncodingStrategy = dateEncodingStrategy {
            encoder.dateEncodingStrategy = dateEncodingStrategy
        }

        if let dataEncodingStrategy = dataEncodingStrategy {
            encoder.dataEncodingStrategy = dataEncodingStrategy
        }

        if let nonConformingFloatEncodingStrategy = nonConformingFloatEncodingStrategy {
            encoder.nonConformingFloatEncodingStrategy = nonConformingFloatEncodingStrategy
        }

        if let keyEncodingStrategy = keyEncodingStrategy {
            encoder.keyEncodingStrategy = keyEncodingStrategy
        }

        if let userInfo = userInfo {
            encoder.userInfo = userInfo
        }

        let data = try encoder.encode(self)
        return data
    }

    /// Returns the pretty-printed form of the JSON
    public var prettyJSON: String {
        (try? String(data: json(outputFormatting: [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]), encoding: .utf8) ?? "{}") ?? "{}"
    }

    /// Returns the debug form of the JSON
    public var debugJSON: String {
        (try? String(data: json(outputFormatting: [.sortedKeys, .withoutEscapingSlashes]), encoding: .utf8) ?? "{}") ?? "{}"
    }
}

#if !os(Linux) && !os(Windows)
/// A watcher for changes to a folder
public actor FileSystemObserver {
    private let fileDescriptor: CInt
    private let source: DispatchSourceProtocol

    public init(URL: URL, queue: DispatchQueue = .global(), block: @escaping () -> Void) {
        self.fileDescriptor = open(URL.path, O_EVTONLY)
        self.source = DispatchSource.makeFileSystemObjectSource(fileDescriptor: self.fileDescriptor, eventMask: .all, queue: queue)
        self.source.setEventHandler {
            block()
        }
        self.source.resume()
    }

    deinit {
        self.source.cancel()
        close(fileDescriptor)
    }
}
#endif
