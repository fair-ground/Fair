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
            return lastBundleComponent.replacingOccurrences(of: " ", with: "-")
        } else {
            return bundleName?.replacingOccurrences(of: " ", with: "-")
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

