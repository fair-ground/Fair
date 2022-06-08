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
import XCTest
@testable import FairCore
@testable import FairApp

/// Tests different command options for the FairTool.
///
/// These tests perform tool operations in the same process, which is different from the
/// `FairToolTests.swift`, which performs test by invoking the actual tool executable and parsing the output.
final class FairCommandTests: XCTestCase {
    typealias ToolMessage = (kind: MessageKind, items: [Any?])

    /// Invokes the `FairTool` with a command that expects a JSON-serialized output for a `FairParsableCommand`
    /// The command will be invoked and the result will be deserialized into the expected structure.
    private func runToolOutput<C: FairParsableCommand>(_ type: ParsableCommand.Type?, cmd: C.Type, _ args: String...) async throws -> (output: C.Output, messages: [(MessageKind, [Any?])]) where C.Output : Decodable {
        let result = try await runTool(type: type?.configuration.commandName, op: C.configuration.commandName, args)
        return (try C.Output(json: result.output.joined().utf8Data), result.messages)
    }

    /// Invokes the `FairTool` in-process using the specified arguments
    private func runTool(type: String? = nil, op: String?, _ args: [String] = []) async throws -> (output: [String], messages: [ToolMessage]) {
        let arguments = [type, op].compacted() + args

        let command = try FairTool.parseAsRoot(arguments)
        guard var cmd = command as? FairToolCommand else {
            throw AppError("Bad command type: \(command)")
        }

        // capture the output of the tool run
        let buffer = MessageBuffer()
        cmd.msgOptions.messages = buffer
        try await cmd.run()
        return (buffer.output, buffer.messages)
    }

    func extract(kind: MessageKind = .info, _ messages: [ToolMessage]) -> [String] {
        messages
            .filter({ $0.kind == kind })
            .map({
                $0.items.map({ $0.flatMap(String.init(describing:)) ?? "nil" }).joined(separator: " ")
            })
    }

    func testVersionCommand() async throws {
        let result = try await runTool(op: FairTool.VersionCommand.configuration.commandName)
        let output = extract(result.messages).first
        XCTAssertTrue(output?.hasPrefix("fairtool") == true, output ?? "")
    }

    /// Runs "fairtool app info <url>" on a remote .ipa file, which it will download and analyze.
    func testAppInfoCommandiOS() async throws {
        let (result, _) = try await runToolOutput(AppCommand.self, cmd: AppCommand.InfoCommand.self, "https://github.com/Cloud-Cuckoo/App/releases/latest/download/Cloud-Cuckoo-iOS.ipa")

        XCTAssertEqual("app.Cloud-Cuckoo", result.info.obj?["CFBundleIdentifier"]?.str)
        XCTAssertEqual(0, result.entitlements?.count, "no entitlements expected in this ios app")
    }

    /// Runs "fairtool app info <url>" on a remote .app .zip file, which it will download and analyze.
    func testAppInfoCommandMacOS() async throws {
        let (result, _) = try await runToolOutput(AppCommand.self, cmd: AppCommand.InfoCommand.self, "https://github.com/Cloud-Cuckoo/App/releases/latest/download/Cloud-Cuckoo-macOS.zip")

        XCTAssertEqual("app.Cloud-Cuckoo", result.info.obj?["CFBundleIdentifier"]?.str)
        XCTAssertEqual(2, result.entitlements?.count, "expected two entitlements in a fat binary")
        XCTAssertEqual(true, result.entitlements?.first?.obj?["com.apple.security.app-sandbox"])
        XCTAssertEqual(false, result.entitlements?.first?.obj?["com.apple.security.network.client"])
    }

    func testValidateCommand() async throws {
        do {
            let result = try await runTool(type: FairCommand.configuration.commandName, op: FairCommand.ValidateCommand.configuration.commandName)
            XCTAssertFalse(result.messages.isEmpty)
        } catch let error as CommandError {
            // the hub key is required
            XCTAssertEqual("\(error.parserError)", #"noValue(forKey: FairCore.InputKey(rawValue: "hub"))"#)
            //XCTAssertEqual(error.localizedDescription, #"Bad argument: "org""#)
        }
    }

    #if os(macOS)
    func testIconCommand() async throws {
        do {
            let result = try await runTool(type: FairCommand.configuration.commandName, op: FairCommand.IconCommand.configuration.commandName)
            XCTAssertFalse(result.messages.isEmpty)
        } catch {
            XCTAssertEqual("\(error)", #"CommandError(commandStack: [FairApp.FairTool, FairApp.FairCommand, FairApp.FairCommand.IconCommand], parserError: FairCore.ParserError.noValue(forKey: FairCore.InputKey(rawValue: "org")))"#)
        }
    }
    #endif

    func testMergeCommand() async throws {
        do {
            let result = try await runTool(type: FairCommand.configuration.commandName, op: FairCommand.MergeCommand.configuration.commandName)
            XCTAssertFalse(result.messages.isEmpty)
        } catch {
            XCTAssertEqual("\(error)", #"CommandError(commandStack: [FairApp.FairTool, FairApp.FairCommand, FairApp.FairCommand.MergeCommand], parserError: FairCore.ParserError.noValue(forKey: FairCore.InputKey(rawValue: "org")))"#)
        }
    }

    func testFairsealCommand() async throws {
        do {
            let result = try await runTool(type: FairCommand.configuration.commandName, op: FairCommand.FairsealCommand.configuration.commandName)
            XCTAssertFalse(result.messages.isEmpty)
        } catch {
            //XCTAssertEqual("\(error)", #"CommandError(commandStack: [FairApp.FairTool, FairApp.FairTool.FairsealCommand], parserError: FairCore.ParserError.noValue(forKey: FairCore.InputKey(rawValue: "hub")))"#)
        }
    }

    func testCatalogCommand() async throws {
        do {
            let result = try await runTool(type: FairCommand.configuration.commandName, op: FairCommand.CatalogCommand.configuration.commandName)
            XCTAssertFalse(result.messages.isEmpty)
        } catch {
            XCTAssertEqual("\(error)", #"CommandError(commandStack: [FairApp.FairTool, FairApp.FairCommand, FairApp.FairCommand.CatalogCommand], parserError: FairCore.ParserError.noValue(forKey: FairCore.InputKey(rawValue: "hub")))"#)
        }
    }

    func testAppcasksCommand() async throws {
        do {
            let result = try await runTool(type: BrewCommand.configuration.commandName, op: BrewCommand.AppCasksCommand.configuration.commandName)
            XCTAssertFalse(result.messages.isEmpty)
        } catch {
            XCTAssertEqual("\(error)", #"CommandError(commandStack: [FairApp.FairTool, FairApp.BrewCommand, FairApp.BrewCommand.AppCasksCommand], parserError: FairCore.ParserError.noValue(forKey: FairCore.InputKey(rawValue: "hub")))"#)
        }
    }

    #if !os(Windows) // async test compile issues: “error: invalid conversion from 'async' function of type '() async throws -> ()' to synchronous function type '() throws -> Void'”
    @available(macOS 11, iOS 14, *)
    func XXXtestCLIHelp() async throws {
        FairTool.main(["help"])
    }
    #endif

    /// if the environment uses the "GH_TOKEN" or "GITHUB_TOKEN" (e.g., in an Action), then pass it along to the API requests
    static let authToken: String? = ProcessInfo.processInfo.environment["GH_TOKEN"] ?? ProcessInfo.processInfo.environment["GITHUB_TOKEN"]


    #if !os(Windows) // async test compile issues: “error: invalid conversion from 'async' function of type '() async throws -> ()' to synchronous function type '() throws -> Void'”
    @available(macOS 11, iOS 14, *)
    func XXXtestCLICatalog() async throws {
        //if Self.authToken == nil { throw XCTSkip("cannot run API tests without a token") }
        FairTool.main(["fairtool", "catalog", "--org", "App-Fair", "--fairseal-issuer", "appfairbot", "--hub", "github.com/appfair", "--token", Self.authToken ?? "", "--output", "/tmp/fairapps-\(UUID().uuidString).json"])
    }
    #endif


}


public struct PackageManifest : Pure {
    public var name: String
    //public var toolsVersion: String // can be string or dict
    public var products: [Product]
    public var dependencies: [Dependency]
    //public var targets: [Either<Target>.Or<String>]
    public var platforms: [SupportedPlatform]
    public var cModuleName: String?
    public var cLanguageStandard: String?
    public var cxxLanguageStandard: String?

    public struct Target: Pure {
        public enum TargetType: String, Pure {
            case regular
            case test
            case system
        }

        public var `type`: TargetType
        public var name: String
        public var path: String?
        public var excludedPaths: [String]?
        //public var dependencies: [String]? // dict
        //public var resources: [String]? // dict
        public var settings: [String]?
        public var cModuleName: String?
        // public var providers: [] // apt, brew, etc.
    }


    public struct Product : Pure {
        //public var `type`: ProductType // can be string or dict
        public var name: String
        public var targets: [String]

        public enum ProductType: String, Pure, CaseIterable {
            case library
            case executable
        }
    }

    public struct Dependency : Pure {
        public var name: String?
        public var url: String
        //public var requirement: Requirement // revision/range/branch/exact
    }

    public struct SupportedPlatform : Pure {
        var platformName: String
        var version: String
    }
}


//extension PackageManifest {
//    /// Parses the Package.swift file at the given location
//    public static func parse(package: URL) throws -> Self {
//        let dumpPackage = try Process.execute(command: URL(fileURLWithPath: "/usr/bin/xcrun"), ["swift", "package", "dump-package", "--package-path", package.deletingLastPathComponent().path])
//        let packageJSON = dumpPackage.stdout.joined(separator: "\n")
//        let decoder = JSONDecoder()
//        return try decoder.decode(Self.self, from: Data(packageJSON.utf8))
//    }
//}
