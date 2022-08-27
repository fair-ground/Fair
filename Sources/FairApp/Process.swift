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

 The full text of the GNU Affero General Public License can be
 found in the COPYING.txt file or at https://www.gnu.org/licenses/

 Linking this library statically or dynamically with other modules is
 making a combined work based on this library.  Thus, the terms and
 conditions of the GNU Affero General Public License cover the whole
 combination.

 As a special exception, the copyright holders of this library give you
 permission to link this library with independent modules to produce an
 executable, regardless of the license terms of these independent
 modules, and to copy and distribute the resulting executable under
 terms of your choice, provided that you also meet, for each linked
 independent module, the terms and conditions of the license of that
 module.  An independent module is a module which is not derived from
 or based on this library.  If you modify this library, you may extend
 this exception to your version of the library, but you are not
 obligated to do so.  If you do not wish to do so, delete this
 exception statement from your version.
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

#if os(macOS) || os(Linux) || os(Windows)

/// The result of a command execution
public struct CommandResult {
    public let url: URL
    public let terminationStatus: Int32
    public let stdout: Data
    public let stderr: Data
}

extension CommandResult : LocalizedError {
    public var failureReason: String? {
        return "The command \"\(url.lastPathComponent)\" exited with code: \(self.terminationStatus)"
    }
}

extension CommandResult {
    /// Expects that the result of the command be the specified value.
    ///
    /// - Parameter terminationStatus: the expected exit valud, defaulting to zero
    /// - Returns: the item itself, which can be used for checking stdout and stderror
    @discardableResult public func expect(exitCode: Int32? = 0) throws -> Self {
        //process.waitUntilExit()
        //let exitCode = process.terminationStatus

        if let exitCode = exitCode, exitCode != terminationStatus {
            throw self
        } else {
            return self
        }
    }
}

extension Process {
    /// Executes the given task, either synchronously or asynchronously.
    ///
    /// - Parameters:
    ///   - executablePath: the path of the command to execute.
    ///   - environment: the environment to pass to the command.
    ///   - args: the arguments for the command
    /// - Returns: the standard out and error, along with the process itself
    fileprivate static func execute(cmd command: String, environment: [String: String] = [:], _ args: [String]) async throws -> CommandResult {
//        #if os(macOS) && false // TODO: executeAsync on all platforms
//        return try await executeAsync(cmd: command, environment: environment, args)
//        #else
        return try executeSync(cmd: command, environment: environment, args)
//        #endif
    }

    /// Invokes a tool with the given arguments
    ///
    /// - TODO: @available(*, deprecated, renamed: "executeAsync")
    public static func executeSync(cmd: String, environment: [String: String] = [:], _ args: [String]) throws -> CommandResult {
        let executablePath = URL(fileURLWithPath: cmd)
        let process = try createProcess(command: executablePath, environment: environment, args: args)

        let (stdout, stderr) = (Pipe(), Pipe())
        (process.standardOutput, process.standardError) = (stdout, stderr)

        try process.run()

        let outdata = stdout.fileHandleForReading.readDataToEndOfFile()
        let errdata = stderr.fileHandleForReading.readDataToEndOfFile()

        process.waitUntilExit() // needs to come after consuming stdout/stderr

        return CommandResult(url: executablePath, terminationStatus: process.terminationStatus, stdout: outdata, stderr: errdata)
    }

}

extension Process {
    #if os(macOS) // not available on Linux: “error: value of type 'FileHandle' has no member 'bytes'”
    /// Executes the given task asynchronously.
    /// - Parameters:
    ///   - executablePath: the path of the command to execute.
    ///   - environment: the environment to pass to the command.
    ///   - args: the arguments for the command
    /// - Returns: the standard out and error, along with the process itself
    @available(*, deprecated, message: "cannot use until FileHandle.bytes is available on Linux")
    fileprivate static func executeAsync(cmd command: String, environment: [String: String] = [:], _ args: [String]) async throws -> CommandResult {
        let executablePath = URL(fileURLWithPath: command)
        let process = try createProcess(command: executablePath, environment: environment, args: args)

        let (stdout, stderr) = (Pipe(), Pipe())
        (process.standardOutput, process.standardError) = (stdout, stderr)

        try process.run()

        let (asyncout, asyncerr) = (stdout.fileHandleForReading.bytes.lines, stderr.fileHandleForReading.bytes.lines)

        var out: [String] = []
        for try await o in asyncout { out.append(o) }

        var err: [String] = []
        for try await e in asyncerr { err.append(e) }

        //return CommandResult(url: executablePath, process: process, stdout: out, stderr: err)
        fatalError("TODO: replace static stdout with dynamic")
    }
    #endif
}

extension Process {

    fileprivate static func createProcess(command executablePath: URL, environment: [String: String] = [:], args: [String]) throws -> Process {
        // quick check to ensure we can read the executable
        if FileManager.default.isReadableFile(atPath: executablePath.path) == false {
            throw CocoaError(.fileNoSuchFile)
        }

        if FileManager.default.isExecutableFile(atPath: executablePath.path) == false {
            throw CocoaError(.executableNotLoadable)
        }

        let process = Process()
        process.executableURL = executablePath
        process.arguments = args

        dbg("executing: \(executablePath.path)", args.joined(separator: " "))

        do {
            var env = ProcessInfo.processInfo.environment
            for (key, value) in environment {
                env[key] = value
            }
            process.environment = env
        }

        return process
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

extension Process {
    /// Convenience for executing a local command whose final argument is a target file
    public static func exec(cmd: String, _ commands: String...) async throws -> CommandResult {
        try await execute(cmd: cmd, commands)
    }

    /// Convenience for executing a local command whose final argument is a target file
    public static func exec(cmd: String, args params: [String]) async throws -> CommandResult {
        try await execute(cmd: cmd, params)
    }

    #if os(macOS)
    /// Returns `swift test <file>`. Untested.
    public static func swift(op: String, xcrun: Bool, packageFolder: URL) async throws -> CommandResult {
        if xcrun {
            return try await exec(cmd: "/usr/bin/xcrun", "swift", op, "--package-path", packageFolder.path)
        } else {
            return try await exec(cmd: "/usr/bin/swift", op, "--package-path", packageFolder.path)
        }
    }
    #endif

    #if os(macOS)
    /// Returns `xattr -d com.apple.quarantine <file>`. Untested.
    public static func removeQuarantine(appURL: URL) async throws -> CommandResult {
        try await exec(cmd: "/usr/bin/xattr", "-r", "-d", "com.apple.quarantine", appURL.path)
    }
    #endif

    #if os(macOS)
    /// Returns `spctl --assess --verbose --type execute <file>`. .
    public static func spctlAssess(appURL: URL) async throws -> CommandResult {
        try await exec(cmd: "/usr/sbin/spctl", "--assess", "--verbose", "--type", "execute", appURL.path)
    }
    #endif

    #if os(macOS)
    /// Returns `codesign -vv -d <file>`.
    public static func codesignVerify(appURL: URL) async throws -> CommandResult {
        try await exec(cmd: "/usr/bin/codesign", "-vv", "-d", appURL.path)
    }
    #endif

    #if os(macOS)
    /// Returns `codesign -vv -d <file>`. Untested.
    public static func codesign(url: URL, force: Bool = true, identity: String = "-", deep: Bool, preserveMetadata: String? = nil) async throws -> CommandResult {
        try await exec(cmd: "/usr/bin/codesign", args: [(force ? "-f" : nil), "--sign", identity, (deep ? "--deep" : nil), preserveMetadata.flatMap({ "--preserve-metadata=\($0)" }), url.path].compacted())
    }
    #endif

    #if os(macOS)
    /// Sets the version in the given file `url`, which is expected to be a Macho-O file.
    ///
    /// Returns `vtool -set-build-version [args] -replace -output <file> <file>`.
    public static func setBuildVersion(url: URL, params args: [String]) async throws -> CommandResult {
        try await exec(cmd: "/usr/bin/vtool", args: ["-set-build-version"] + args + ["-replace", "-output", url.path, url.path].compacted())
    }
    #endif

    #if os(macOS)
    /// Returns the disassembly of the given binary.
    ///
    /// Returns `otool <args> <file>`
    public static func otool(tool: String = "/usr/bin/otool", url: URL, params args: [String] = ["-tV"]) async throws -> CommandResult {
        try await exec(cmd: tool, args: [] + args + [url.path])
    }
    #endif

    #if os(macOS)
    /// Returns `codesign --remove-signature <file>`.
    public static func codesignStrip(url: URL) async throws -> CommandResult {
        try await exec(cmd: "/usr/bin/codesign", "--remove-signature", url.path)
    }
    #endif

    #if os(macOS)
    /// Returns `xip --expand <file>`. Untested.
    public static func unxip(url: URL) async throws -> CommandResult {
        try await exec(cmd: "/usr/bin/xip", "--expand", url.path)
    }
    #endif

    #if os(macOS)
    /// Returns `ditto -k -x <file>`.
    static func ditto(from source: URL, to destination: URL) async throws -> CommandResult {
        try await exec(cmd: "/usr/bin/ditto", "-k", "-x", source.path, destination.path)
    }
    #endif

    #if os(macOS)
    /// Returns `sw_vers -buildVersion`. Untested.
    public static func buildVersion(expect: UInt?) async throws -> CommandResult {
        try await exec(cmd: "/usr/bin/sw_vers", "-buildVersion")
    }
    #endif

    #if os(macOS)
    /// Returns `getconf DARWIN_USER_CACHE_DIR`. Untested.
    public static func getCacheDir(expect: UInt?) async throws -> CommandResult {
        try await exec(cmd: "/usr/bin/getconf", "DARWIN_USER_CACHE_DIR")
    }
    #endif

    #if os(macOS)
    /// Returns `xcode-select -p`. Untested.
    public static func xcodeShowPath(expect: UInt?) async throws -> CommandResult {
        try await exec(cmd: "/usr/bin/xcode-select", "-p")
    }
    #endif
}
#endif // os(macOS) || os(Linux) || os(Windows)
