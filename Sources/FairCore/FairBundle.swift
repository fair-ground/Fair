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
    subscript<T>(info key: InfoPlistKey) -> T? {
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
    
    // TODO: use StringLocalizationKey for the message
    public func error(_ message: String, code: Int = 0) -> Error {
        NSError(domain: "Fair", code: code, userInfo: [NSLocalizedFailureReasonErrorKey: NSLocalizedString(message, tableName: nil, bundle: self, comment: "")])
    }
}

extension FileManager {
    /// Returns the deep contents of the given file URL
    func deepContents(of url: URL, includeFolders: Bool) throws -> [URL] {
        guard let walker = self.enumerator(atPath: url.path) else {
            throw CocoaError(.fileReadNoSuchFile)
        }

        var paths: [URL] = []
        for path in walker {
            if let path = path as? String {
                let pathURL = URL(fileURLWithPath: path, relativeTo: url)
                if includeFolders || isDirectory(url: pathURL) == false {
                    paths.append(pathURL)
                }
            }
        }

        return paths
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

    /// Removes any quarantine properties from the given URL
    public func clearQuarantine(at url: URL) throws {
#if macOS
        // try to clear the quarantine flag
        var resourceValues = URLResourceValues()
        resourceValues.quarantineProperties = nil // this should clear the quarantine flag
        do {
            try url.setResourceValues(resourceValues) // note: “Attempts to set a read-only resource property or to set a resource property not supported by the resource are ignored and are not considered errors. This method is currently applicable only to URLs for file system resources.”
        } catch {
            dbg("unable to clear quarantine flag for:", url.path)
        }

        // check to ensure we have cleared the props
        let qtprops2 = try (url as NSURL).resourceValues(forKeys: [URLResourceKey.quarantinePropertiesKey])
        if !qtprops2.isEmpty {
            dbg("found quarantine xattr for:", url.path, "keys:", qtprops2)
            throw AppError("Quarantined App", failureReason: "The app was quarantined by the system and cannot be installed.")
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

        let mask: FileManager.DirectoryEnumerationOptions = skipHidden ? [.producesRelativePathURLs, .skipsHiddenFiles] : [.producesRelativePathURLs]

        if deep == false {
            // we could alternatively use `enumerator` with the `FileManager.DirectoryEnumerationOptions.skipsSubdirectoryDescendants` mask
            return try fm.contentsOfDirectory(at: self, includingPropertiesForKeys: keys, options: mask) // “the only supported option is skipsHiddenFiles”
        } else {
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
    public func json(encoder: @autoclosure () -> JSONEncoder = JSONEncoder(), outputFormatting: JSONEncoder.OutputFormatting? = [.sortedKeys, .withoutEscapingSlashes], dateEncodingStrategy: JSONEncoder.DateEncodingStrategy? = nil, dataEncodingStrategy: JSONEncoder.DataEncodingStrategy? = nil, nonConformingFloatEncodingStrategy: JSONEncoder.NonConformingFloatEncodingStrategy? = nil, keyEncodingStrategy: JSONEncoder.KeyEncodingStrategy? = nil, userInfo: [CodingUserInfoKey : Any]? = nil) throws -> Data {
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
