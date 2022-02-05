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
import Swift
import Foundation


/// A simple pass-through from `FileHandle` to `TextOutputStream`
open class HandleStream: TextOutputStream {
    public let stream: FileHandle

    public init(stream: FileHandle) {
        self.stream = stream
    }

    public func write(_ string: String) {
        if let data = string.data(using: .utf8) {
            stream.write(data)
        }
    }
}

#if os(macOS)
public extension Process {
    /// The output of `execute`
    typealias CommandResult = (stdout: [String], stderr: [String])

    /// Invokes a tool with the given arguments
    @discardableResult static func execute(command executablePath: URL, environment: [String: String] = [:], _ args: [String], expectSuccess: Bool = true) throws -> CommandResult {
        // Some of the APIs that we use below are available in macOS 10.13 and above.
        guard #available(macOS 10.13, *) else { return ([], []) }

        // quick check to ensure we can read the executable
        let _ = try Data(contentsOf: executablePath)

        let process = Process()
        process.executableURL = executablePath
        process.arguments = args

        //dbg("executing: \(executablePath.path)", args.joined(separator: " "))

        do {
            var env = ProcessInfo.processInfo.environment
            for (key, value) in environment {
                env[key] = value
            }
            process.environment = env
        }

        let stdout = Pipe()
        process.standardOutput = stdout
        let stderr = Pipe()
        process.standardError = stderr

        try process.run()
        process.waitUntilExit()

        let outdata = stdout.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: outdata, encoding: .utf8) ?? ""

        let errdata = stderr.fileHandleForReading.readDataToEndOfFile()
        let errput = String(data: errdata, encoding: .utf8) ?? ""

        if expectSuccess && process.terminationStatus != 0 {
            print("error running tool \(process.terminationStatus); STDOUT:\n", output, "STDERR:\n", errput)
            throw Errors.processExit(executablePath, process.terminationStatus)
        }

        return (output.split(separator: "\n").map(\.description), errput.split(separator: "\n").map(\.description))
    }

    enum Errors : Pure, LocalizedError {
        case processExit(URL, Int32)

        public var errorDescription: String? {
            switch self {
            case .processExit(let url, let exitCode): return "The command \"\(url.lastPathComponent)\" exited with code: \(exitCode)"
            }
        }
    }
}

//#if os(macOS)
//@available(macOS 12.0, iOS 15.0, *)
//public extension Process {
//    func dispatch(command executablePath: URL, environment: [String: String] = [:], _ args: [String]) async throws {
//        let process = Process()
//        process.executableURL = executablePath
//
//        let pipe = Pipe()
//        process.standardOutput = pipe
//        process.standardError = pipe
//
//        process.standardInput = Pipe()
//
//        for try await line in pipe.fileHandleForReading.bytes.lines {
//            print("### received line: \(line)")
//            try Task.checkCancellation()
//        }
//    }
//}
//#endif
//

public extension Process {


    /// Convenience for executing a local command whose final argument is a target file
    static func exec(cmd: String, _ commands: String..., target: URL? = nil) throws -> CommandResult {
        try execute(command: URL(fileURLWithPath: cmd), commands + [target?.path].compactMap({ $0 }))
    }

    /// Returns `swift test <file>`. Untested.
    @discardableResult static func swift(op: String, xcrun: Bool, packageFolder: URL) throws -> CommandResult {
        if xcrun {
            return try exec(cmd: "/usr/bin/xcrun", "swift", op, "--package-path", target: packageFolder)
        } else {
            return try exec(cmd: "/usr/bin/swift", op, "--package-path", target: packageFolder)
        }
    }

    /// Returns `xattr -d com.apple.quarantine <file>`. Untested.
    @discardableResult static func removeQuarantine(appURL: URL) throws -> CommandResult {
        try exec(cmd: "/usr/bin/xattr", "-r", "-d", "com.apple.quarantine", target: appURL)
    }

    /// Returns `spctl --assess --verbose --type execute <file>`. Untested.
    @discardableResult static func spctlAssess(appURL: URL) throws -> CommandResult {
        try exec(cmd: "/usr/sbin/spctl", "--assess", "--verbose", "--type", "execute", target: appURL)
    }

    /// Returns `codesign -vv -d <file>`. Untested.
    @discardableResult static func codesignVerify(appURL: URL) throws -> CommandResult {
        try exec(cmd: "/usr/bin/codesign", "-vv", "-d", target: appURL)
    }

    /// Returns `codesign --remove-signature <file>`. Untested.
    @discardableResult static func codesignStrip(url: URL) throws -> CommandResult {
        try exec(cmd: "/usr/bin/codesign", "--remove-signature", target: url)
    }

    /// Returns `xip --expand <file>`. Untested.
    @discardableResult static func unxip(url: URL) throws -> CommandResult {
        try exec(cmd: "/usr/bin/xip", "--expand", target: url)
    }

    /// Returns `ditto -k -x <file>`.
    @discardableResult static func ditto(from source: URL, to destination: URL) throws -> CommandResult {
        try exec(cmd: "/usr/bin/ditto", "-k", "-x", source.path, destination.path)
    }

    /// Returns `sw_vers -buildVersion`. Untested.
    @discardableResult static func buildVersion() throws -> CommandResult {
        try exec(cmd: "/usr/bin/sw_vers", "-buildVersion")
    }

    /// Returns `getconf DARWIN_USER_CACHE_DIR`. Untested.
    @discardableResult static func getCacheDir() throws -> CommandResult {
        try exec(cmd: "/usr/bin/getconf", "DARWIN_USER_CACHE_DIR")
    }

    /// Returns `xcode-select -p`. Untested.
    @discardableResult static func xcodeShowPath() throws -> CommandResult {
        try exec(cmd: "/usr/bin/xcode-select", "-p")
    }
}

extension PackageManifest {
    /// Parses the Package.swift file at the given location
    public static func parse(package: URL) throws -> Self {
        let dumpPackage = try Process.execute(command: URL(fileURLWithPath: "/usr/bin/xcrun"), ["swift", "package", "dump-package", "--package-path", package.deletingLastPathComponent().path])
        let packageJSON = dumpPackage.stdout.joined(separator: "\n")
        let decoder = JSONDecoder()
        return try decoder.decode(Self.self, from: Data(packageJSON.utf8))
    }
}
#endif // os(macOS)
