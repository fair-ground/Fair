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
import FairApp

final class FairCLITests: XCTestCase {
    typealias ToolMessage = (kind: FairCLI.MessageKind, items: [Any?])

    func runTool(op: FairCLI.Operation, _ args: String...) throws -> [ToolMessage] {
        var messages: [ToolMessage] = []
        // first argument is tool name
        let it = try FairCLI(arguments: ["fairtool"] + [op.rawValue] + args, environment: [:])

        func addMessage(_ kind: FairCLI.MessageKind, items: Any?...) {
            messages.append((kind, items))
        }

        try it.runCLI(msg: addMessage)

        return messages
    }

    func extract(kind: FairCLI.MessageKind = .info, _ messages: [ToolMessage]) -> [String] {
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

    func testToolWelcome() throws {
        try XCTAssertEqual(extract(runTool(op: .welcome)).first, "Welcome to Fair Ground!")
    }
}
#endif
