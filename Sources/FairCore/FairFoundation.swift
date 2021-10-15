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
import Foundation

#if canImport(_Concurrency)
/// A value whose content can be hashed and serialized, and is concurrent-safe
public typealias Pure = Hashable & Codable & Sendable

//// cannot declare conformance outside of the source file
//// TODO: use `@unchecked Sendable` once the compiler supports it:
//// warning: 'UnsafeSendable' is deprecated: Use @unchecked Sendable instead
//// error: Unknown attribute 'unchecked'
@available(*, deprecated)
extension Foundation.Date : UnsafeSendable { }

@available(*, deprecated)
extension Foundation.URL : UnsafeSendable { }

@available(*, deprecated)
extension Foundation.UUID : UnsafeSendable { }
#else
/// A value whose content can be hashed and serialized
public typealias Pure = Hashable & Codable
#endif

public extension Result {
    /// Returns the successful value, or nil if unset
    @inlinable var successValue: Success? {
        switch self {
        case .success(let value): return value
        case .failure: return nil
        }
    }

    /// Returns the failure value, or nil if unset
    @inlinable var failureValue: Failure? {
        switch self {
        case .success: return nil
        case .failure(let value): return value
        }
    }
}


#if canImport(OSLog)
import OSLog
#endif

/// Logs the given items to `os_log` if `DEBUG` is set
/// - Parameters:
///   - level: the level: 0 for default, 1 for debug, 2 for info, 3 for error, 4+ for fault
@inlinable public func dbg(level: UInt8 = 0, _ arg1: @autoclosure () -> Any? = nil, _ arg2: @autoclosure () -> Any? = nil, _ arg3: @autoclosure () -> Any? = nil, _ arg4: @autoclosure () -> Any? = nil, _ arg5: @autoclosure () -> Any? = nil, _ arg6: @autoclosure () -> Any? = nil, _ arg7: @autoclosure () -> Any? = nil, _ arg8: @autoclosure () -> Any? = nil, _ arg9: @autoclosure () -> Any? = nil, _ arg10: @autoclosure () -> Any? = nil, _ arg11: @autoclosure () -> Any? = nil, _ arg12: @autoclosure () -> Any? = nil, functionName: StaticString = #function, fileName: StaticString = #file, lineNumber: Int = #line) {

    // log .debug level only in debug mode
    let logit: Bool = assertionsEnabled || (level > 1)
    if logit {
        let items = [arg1(), arg2(), arg3(), arg4(), arg5(), arg6(), arg7(), arg8(), arg9(), arg10(), arg11(), arg12()]
        let msg = items.compactMap({ $0 }).map(String.init(describing:)).joined(separator: " ")

        let funcName = functionName.description.split(separator: "(").first?.description ?? functionName.description

        // use just the last path component
        let filePath = fileName.description
            .split(separator: "/").last?.description
            .split(separator: ".").first?.description
            ?? fileName.description

        let message = "\(filePath):\(lineNumber) \(funcName): \(msg)"
	#if canImport(OSLog)
        os_log(level == 0 ? .debug : level == 1 ? .default : level == 2 ? .info : level == 3 ? .error : .fault, "%{public}@", message)
	#else
        print(level == 0 ? "debug" : level == 1 ? "default" : level == 2 ? "info" : level == 3 ? "error" : "fault", message)
	#endif
    }
}


@inlinable public func nanos() -> UInt64 {
    DispatchTime.now().uptimeNanoseconds
}

@usableFromInline internal func fmtnanos(from: UInt64, to: UInt64 = nanos()) -> String {
    let ms = Double(to - from) / 1_000_000
    if ms >= 1 {
        // round when over 1ms for formatting
        return "\(Int64(ceil(ms)))ms"
    } else {
        return "\(ms)ms"
    }
}

#if canImport(OSLog)
import OSLog

@usableFromInline let signpostLog = OSLog(subsystem: "fair-ground", category: .pointsOfInterest)
#endif

/// Output a message with the amount of time the given block took to exeucte
/// - Parameter message: the static message to log
/// - Parameter messageBlock: the dynamic message to log; the parameter to the closure is the result of the `block`
/// - Parameter level: the log level fot `dbg`
/// - Parameter threshold: the threshold below which a message will not be printed
/// - Parameter functionName: the name of the calling function
/// - Parameter fileName: the fileName containg the calling function
/// - Parameter lineNumber: the line on which the function was called
/// - Parameter block: the block to execute
@inlinable public func prf<T>(_ message: @autoclosure () -> String? = nil, msg messageBlock: ((T) -> String)? = nil, level: UInt8 = 0, threshold: Double = -0.0, functionName: StaticString = #function, fileName: StaticString = #file, lineNumber: Int = #line, block: () throws -> T) rethrows -> T {
    //#if DEBUG

    let start: UInt64 = nanos()

    #if canImport(OSLog)
    os_signpost(.begin, log: signpostLog, name: functionName)
    #endif
    defer { 
        #if canImport(OSLog)
        os_signpost(.end, log: signpostLog, name: functionName) 
        #endif
    }

    let result = try block()

    let end: UInt64 = max(nanos(), start)
    let secs = Double(end - start) / 1_000_000_000.0

    if secs >= threshold {
        let timeStr = fmtnanos(from: start, to: end)
        dbg(level: level, message(), messageBlock?(result), "time: \(timeStr)", functionName: functionName, fileName: fileName, lineNumber: lineNumber)
    }
    return result
}



public extension BinaryInteger {
    /// Returns this integer formatted as byte counts
    func localizedByteCount(countStyle: ByteCountFormatter.CountStyle = .file) -> String {
        ByteCountFormatter.string(fromByteCount: .init(self), countStyle: countStyle)
    }

    func localizedNumber(style: NumberFormatter.Style = .decimal) -> String {
        NumberFormatter.localizedString(from: NSNumber(integerLiteral: .init(self)), number: style)
    }
}

public extension String {
    /// The UTF8-encoded data for this string
    @inlinable var utf8Data: Data {
        data(using: .utf8) ?? Data(utf8)
    }

    func enquote(with char: Character = "\"") -> String {
        String(char) + self + String(char)
    }

    func trimmed(_ characters: CharacterSet = .whitespacesAndNewlines) -> String {
        trimmingCharacters(in: characters)
    }
}

public extension Data {
    /// The UTF8-encoded String for this data
    @inlinable var utf8String: String? {
        String(data: self, encoding: .utf8)
    }
}

public extension Date {
    /// Formats the date string for display
    func localizedDate(dateStyle: DateFormatter.Style = .medium, timeStyle: DateFormatter.Style = .medium) -> String {
        DateFormatter.localizedString(from: self, dateStyle: dateStyle, timeStyle: timeStyle)
    }
}

public extension URL {
    /// The temporary directory for this process; note that this will probably vary between launches for sandboxed apps
    static let tmpDir = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)

    /// If this is a file URL and a directory, return the URL itself, otherwise nil
    var asDirectory: URL? {
        FileManager.default.isDirectory(url: self) == true ? self : nil
    }

    /// Returns the value for a single resource key.
    private func singleResourceValue(forKey key: URLResourceKey) -> Any? {
        try? resourceValues(forKeys: [key]).allValues[key]
    }

    /// The size represented by this file URL, or nil if it is not a file URL.
    func fileSize(includeMetadata: Bool = false, allocated: Bool = false) throws -> Int? {
        switch (includeMetadata, allocated) {
        case (false, false):
            return singleResourceValue(forKey: .fileSizeKey) as? Int
        case (false, true):
            return singleResourceValue(forKey: .fileAllocatedSizeKey) as? Int
        case (true, false):
            return singleResourceValue(forKey: .totalFileSizeKey) as? Int
        case (true, true):
            return singleResourceValue(forKey: .totalFileAllocatedSizeKey) as? Int
        }
    }
    
    /// The date this file URL was created
    var creationDate: Date? {
        singleResourceValue(forKey: .creationDateKey) as? Date
    }

    /// The date this file URL was last modified
    var modificationDate: Date? {
        contentModificationDateKey
    }

    var attributeModificationDate: Date? {
        singleResourceValue(forKey: .attributeModificationDateKey) as? Date
    }

    /// The date the contents of the URL changed
    var contentModificationDateKey: Date? {
        singleResourceValue(forKey: .contentModificationDateKey) as? Date
    }
}


/// `true` if assertions are enabled for the current build
public let assertionsEnabled: Bool = {
    var enabled = false
    assert({
        enabled = true
        return enabled
    }())
    return enabled
}()


// MARK: Package-Specific Utilities

/// Returns the localized string for the current module.
internal func loc(_ key: StaticString, tableName: String? = nil, comment: String? = nil) -> String {
    // TODO: use StringLocalizationKey
    NSLocalizedString(key.description, tableName: tableName, bundle: .module, comment: comment ?? "")
    // macOS 12 TODO:
    // String(localized: keyAndValue, table: table, bundle: .module, locale: Locale.current, comment: comment)
}

/// Work-in-Progress marker
@available(*, deprecated, message: "work in progress")
internal func wip<T>(_ value: T) -> T { value }
