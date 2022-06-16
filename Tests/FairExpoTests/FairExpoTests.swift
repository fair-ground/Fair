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
import FairCore
import FairExpo

/// Tests different command options for the FairToolCommand.
///
/// These tests perform tool operations in the same process, which is different from the
/// `FairToolTests.swift`, which performs test by invoking the actual tool executable and parsing the output.
final class FairExpoTests: XCTestCase {
    typealias ToolMessage = (kind: MessageKind, items: [Any?])

    /// Invokes the `FairTool` with a command that expects a JSON-serialized output for a `FairParsableCommand`
    /// The command will be invoked and the result will be deserialized into the expected structure.
    private func runToolOutput<C: FairParsableCommand>(_ type: ParsableCommand.Type?, cmd: C.Type, _ args: String...) async throws -> (output: [C.Output], messages: [(MessageKind, [Any?])]) where C.Output : Decodable {
        let result = try await runTool(type: type?.configuration.commandName, op: C.configuration.commandName, args)
        return (try [C.Output](json: result.output.joined().utf8Data), result.messages)
    }

    /// Invokes the `FairTool` in-process using the specified arguments
    private func runTool(type: String? = nil, op: String?, _ args: [String] = []) async throws -> (output: [String], messages: [ToolMessage]) {
        let arguments = [type, op].compacted() + args

        let command = try FairToolCommand.parseAsRoot(arguments)
        guard var cmd = command as? FairMsgCommand else {
            struct NoCommandError : Error { }
            throw NoCommandError()
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
        let result = try await runTool(op: FairToolCommand.VersionCommand.configuration.commandName)
        let output = extract(result.messages).first
        XCTAssertTrue(output?.hasPrefix("fairtool") == true, output ?? "")
    }

    /// Runs "fairtool app info <url>" on a remote .ipa file, which it will download and analyze.
    func testAppInfoCommandiOS() async throws {
        let (result, _) = try await runToolOutput(AppCommand.self, cmd: AppCommand.InfoCommand.self, "https://github.com/Cloud-Cuckoo/App/releases/latest/download/Cloud-Cuckoo-iOS.ipa")

        XCTAssertEqual("app.Cloud-Cuckoo", result.first?.info.obj?["CFBundleIdentifier"]?.str)
        XCTAssertEqual(0, result.first?.entitlements?.count, "no entitlements expected in this ios app")
    }

    /// Runs "fairtool app info <url>" on a remote .app .zip file, which it will download and analyze.
    func testAppInfoCommandMacOS() async throws {
        let (result, _) = try await runToolOutput(AppCommand.self, cmd: AppCommand.InfoCommand.self, "https://github.com/Cloud-Cuckoo/App/releases/latest/download/Cloud-Cuckoo-macOS.zip")

        XCTAssertEqual("app.Cloud-Cuckoo", result.first?.info.obj?["CFBundleIdentifier"]?.str)
        XCTAssertEqual(2, result.first?.entitlements?.count, "expected two entitlements in a fat binary")
        XCTAssertEqual(true, result.first?.entitlements?.first?.obj?["com.apple.security.app-sandbox"])
        XCTAssertEqual(false, result.first?.entitlements?.first?.obj?["com.apple.security.network.client"])
    }

    func XXXtestAppInfoCommandMacOSStream() async throws {
        var cmd = try AppCommand.InfoCommand.parseAsRoot(["info"]) as! AppCommand.InfoCommand
        cmd.apps = ["https://github.com/Cloud-Cuckoo/App/releases/latest/download/Cloud-Cuckoo-macOS.zip"]

        for try await result in cmd.executeCommand() {
            XCTAssertEqual("app.Cloud-Cuckoo", result.info.obj?["CFBundleIdentifier"]?.str)
            XCTAssertEqual(2, result.entitlements?.count, "expected two entitlements in a fat binary")
            XCTAssertEqual(true, result.entitlements?.first?.obj?["com.apple.security.app-sandbox"])
            XCTAssertEqual(false, result.entitlements?.first?.obj?["com.apple.security.network.client"])
            return
        }

        XCTFail("expected at least one result")
    }

    /// Runs "fairtool app info <url>" on a remote .app .zip file, which it will download and analyze.
    func XXXtestSourceVerifyCommandMacOS() async throws {
        let catalog = "https://appfair.net/fairapps-macos.json"
        let (results, _) = try await runToolOutput(SourceCommand.self, cmd: SourceCommand.VerifyCommand.self, "--verbose", "--bundle-id", "app.Stanza-Redux", catalog)

        let result = try XCTUnwrap(results.first)

        dbg("catalog:", result.prettyJSON)
        XCTAssertEqual("Stanza Redux", result.app.name)
        var items = try XCTUnwrap(result.failures).makeIterator()

        do {
            let failure = try XCTUnwrap(items.next(), "expected a validation failure")
            XCTAssertEqual(failure.type, "missing_checksum")
        }

        do {
            let failure = try XCTUnwrap(items.next(), "expected a validation failure")
            XCTAssertEqual(failure.type, "invalid_size")
        }
    }

    func testSourceVerifyCommandSources() async throws {
        guard let url = URL(string: "https://cdn.altstore.io/file/altstore/apps.json") else {
            return XCTFail("bad url")
        }

        let (results, _) = try await runToolOutput(SourceCommand.self, cmd: SourceCommand.VerifyCommand.self, "--verbose", url.absoluteString)

        dbg("catalog:", results.prettyJSON)
        let result = try XCTUnwrap(results.first)

    }


    func testSourceVerifyCommandiOSDemo() async throws {
        let path = URL(fileURLWithPath: "/tmp/sources/demostore.json")
        if !FileManager.default.isReadableFile(atPath: path.path) {
            throw XCTSkip("Source file does not exist at: \(path)")
        }
        let (results, _) = try await runToolOutput(SourceCommand.self, cmd: SourceCommand.VerifyCommand.self, "--verbose", path.absoluteString)

        let result = try XCTUnwrap(results.first)

        dbg("catalog:", result.prettyJSON)
        XCTAssertEqual("Paperback", result.app.name)
        var items = try XCTUnwrap(result.failures).makeIterator()

        do {
            let failure = try XCTUnwrap(items.next(), "expected a validation failure")
            XCTAssertEqual(failure.type, "missing_checksum")
        }

        do {
            let failure = try XCTUnwrap(items.next(), "expected a validation failure")
            XCTAssertEqual(failure.type, "invalid_size")
        }
    }

    func testValidateCommand() async throws {
        do {
            let result = try await runTool(type: FairCommand.configuration.commandName, op: FairCommand.ValidateCommand.configuration.commandName)
            // TODO:
            // let result = try await runToolOutput(FairCommand.self, cmd: FairCommand.ValidateCommand.self, "--hub", "appfair/App")
            XCTAssertFalse(result.messages.isEmpty)
        } catch { // let error as CommandError {
            // the hub key is required
            // XCTAssertEqual("\(error.parserError)", #"noValue(forKey: FairCore.InputKey(rawValue: "hub"))"#)
            //XCTAssertEqual(error.localizedDescription, #"Bad argument: "org""#)
        }
    }

    #if os(macOS)
    func testIconCommand() async throws {
        do {
            let result = try await runTool(type: FairCommand.configuration.commandName, op: FairCommand.IconCommand.configuration.commandName)
            XCTAssertFalse(result.messages.isEmpty)
        } catch {
            XCTAssertEqual("\(error)", #"CommandError(commandStack: [FairExpo.FairToolCommand, FairExpo.FairCommand, FairExpo.FairCommand.IconCommand], parserError: FairCore.ParserError.noValue(forKey: FairCore.InputKey(rawValue: "org")))"#)
        }
    }

    /// Runs "fairtool app info <url>" on a homebrew cask .app .zip file
    func testAppInfoCommandStocks() async throws {
        let stocksPath = "/System/Applications/Stocks.app"
//        if !FileManager.default.itemExists(at: URL(fileURLWithPath: stocksPath)) {
//            throw XCTSkip("no stocks app") // e.g., Linux
//        }
        let (result, _) = try await runToolOutput(AppCommand.self, cmd: AppCommand.InfoCommand.self, stocksPath)

        XCTAssertEqual("com.apple.stocks", result.first?.info.obj?["CFBundleIdentifier"]?.str)
        XCTAssertEqual(2, result.first?.entitlements?.count, "expected two entitlements in a fat binary")
        XCTAssertEqual(true, result.first?.entitlements?.first?.obj?["com.apple.security.app-sandbox"])
        XCTAssertEqual(true, result.first?.entitlements?.first?.obj?["com.apple.security.network.client"])
    }

    #endif

    func testMergeCommand() async throws {
        do {
            let result = try await runTool(type: FairCommand.configuration.commandName, op: FairCommand.MergeCommand.configuration.commandName)
            XCTAssertFalse(result.messages.isEmpty)
        } catch {
            XCTAssertEqual("\(error)", #"CommandError(commandStack: [FairExpo.FairToolCommand, FairExpo.FairCommand, FairExpo.FairCommand.MergeCommand], parserError: FairCore.ParserError.noValue(forKey: FairCore.InputKey(rawValue: "org")))"#)
        }
    }

    func testFairsealCommand() async throws {
        do {
            let result = try await runTool(type: FairCommand.configuration.commandName, op: FairCommand.FairsealCommand.configuration.commandName)
            XCTAssertFalse(result.messages.isEmpty)
        } catch {
            //XCTAssertEqual("\(error)", #"CommandError(commandStack: [FairApp.FairToolCommand, FairApp.FairToolCommand.FairsealCommand], parserError: FairCore.ParserError.noValue(forKey: FairCore.InputKey(rawValue: "hub")))"#)
        }
    }

    func testCatalogCommand() async throws {
        do {
            let result = try await runTool(type: FairCommand.configuration.commandName, op: FairCommand.CatalogCommand.configuration.commandName)
            XCTAssertFalse(result.messages.isEmpty)
        } catch {
            XCTAssertEqual("\(error)", #"CommandError(commandStack: [FairExpo.FairToolCommand, FairExpo.FairCommand, FairExpo.FairCommand.CatalogCommand], parserError: FairCore.ParserError.noValue(forKey: FairCore.InputKey(rawValue: "hub")))"#)
        }
    }

    func testAppcasksCommand() async throws {
        do {
            let result = try await runTool(type: BrewCommand.configuration.commandName, op: BrewCommand.AppCasksCommand.configuration.commandName)
            XCTAssertFalse(result.messages.isEmpty)
        } catch {
            XCTAssertEqual("\(error)", #"CommandError(commandStack: [FairExpo.FairToolCommand, FairExpo.BrewCommand, FairExpo.BrewCommand.AppCasksCommand], parserError: FairCore.ParserError.noValue(forKey: FairCore.InputKey(rawValue: "hub")))"#)
        }
    }

    #if !os(Windows) // async test compile issues: “error: invalid conversion from 'async' function of type '() async throws -> ()' to synchronous function type '() throws -> Void'”
    @available(macOS 11, iOS 14, *)
    func XXXtestCLIHelp() async throws {
        FairToolCommand.main(["help"])
    }
    #endif

    /// if the environment uses the "GH_TOKEN" or "GITHUB_TOKEN" (e.g., in an Action), then pass it along to the API requests
    static let authToken: String? = ProcessInfo.processInfo.environment["GH_TOKEN"] ?? ProcessInfo.processInfo.environment["GITHUB_TOKEN"]


    #if !os(Windows) // async test compile issues: “error: invalid conversion from 'async' function of type '() async throws -> ()' to synchronous function type '() throws -> Void'”
    @available(macOS 11, iOS 14, *)
    func XXXtestCLICatalog() async throws {
        //if Self.authToken == nil { throw XCTSkip("cannot run API tests without a token") }
        FairToolCommand.main(["fairtool", "catalog", "--org", "App-Fair", "--fairseal-issuer", "appfairbot", "--hub", "github.com/appfair", "--token", Self.authToken ?? "", "--output", "/tmp/fairapps-\(UUID().uuidString).json"])
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
