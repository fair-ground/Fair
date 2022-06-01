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
#if canImport(SwiftUI)
@testable import FairApp

final class FairToolTests: XCTestCase {
    typealias ToolMessage = (kind: MessageKind, items: [Any?])

    func runTool(op: String?, _ args: String...) async throws -> [ToolMessage] {
        let arguments = (op != nil ? [op!] : []) + args
        let command = try FairTool.parseAsRoot(arguments)
        guard var asyncCommand = command as? FairParsableCommand else {
            throw AppError("Bad command type: \(command)")
        }

        // capture the output of the tool run
        let buffer = MessageBuffer()
        asyncCommand.messages = buffer
        defer { asyncCommand.messages = nil } // unnecessary cleanup
        try await asyncCommand.run()
        return buffer.messages
    }

    func extract(kind: MessageKind = .info, _ messages: [ToolMessage]) -> [String] {
        messages
            .filter({ $0.kind == kind })
            .map({
                $0.items.map({ $0.flatMap(String.init(describing:)) ?? "nil" }).joined(separator: " ")
            })
    }


    func testParsePackage() throws {
        //let cwd = FileManager.default.currentDirectoryPath
        let packageFile = URL(fileURLWithPath: #file)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("Package.swift")
        XCTAssertTrue(FileManager.default.fileExists(atPath: packageFile.path))
        let pm = try PackageManifest.parse(package: packageFile)
        XCTAssertEqual("Fair", pm.name)
        XCTAssertEqual(4, pm.platforms.count)
    }

    func testWelcomeCommand() async throws {
        let result = try await runTool(op: FairTool.WelcomeCommand.configuration.commandName)
        let output = extract(result).first
        XCTAssertTrue(output?.hasPrefix("Welcome") == true, output ?? "")
    }

    func testValidateCommand() async throws {
        do {
            let result = try await runTool(op: FairTool.ValidateCommand.configuration.commandName)
            XCTAssertFalse(result.isEmpty)
        } catch {
            XCTAssertEqual(error.localizedDescription, #"Bad argument: "org""#)
        }
    }

    func testIconCommand() async throws {
        do {
            let result = try await runTool(op: FairTool.IconCommand.configuration.commandName)
            XCTAssertFalse(result.isEmpty)
        } catch {
            XCTAssertEqual(error.localizedDescription, #"The operation requires the --app-icon flag"#)
        }
    }

    func testMergeCommand() async throws {
        do {
            let result = try await runTool(op: FairTool.MergeCommand.configuration.commandName)
            XCTAssertFalse(result.isEmpty)
        } catch {
            XCTAssertTrue(error.localizedDescription.hasPrefix("The output path specified"))
        }
    }

    func testFairsealCommand() async throws {
        do {
            let result = try await runTool(op: FairTool.FairsealCommand.configuration.commandName)
            XCTAssertFalse(result.isEmpty)
        } catch {
            XCTAssertEqual(error.localizedDescription, #"The operation requires the --trusted-artifact flag"#)
        }
    }

    func testCatalogCommand() async throws {
        do {
            let result = try await runTool(op: FairTool.CatalogCommand.configuration.commandName)
            XCTAssertFalse(result.isEmpty)
        } catch {
            XCTAssertEqual(error.localizedDescription, #"The hub ("null") specified by the -h/--hub flag is invalid"#)
        }
    }

    func testAppcasksCommand() async throws {
        do {
            let result = try await runTool(op: FairTool.AppcasksCommand.configuration.commandName)
            XCTAssertFalse(result.isEmpty)
        } catch {
            XCTAssertEqual(error.localizedDescription, #"The hub ("null") specified by the -h/--hub flag is invalid"#)
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
#endif
