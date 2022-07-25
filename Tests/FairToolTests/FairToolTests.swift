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
import FairExpo
import FairApp

#if os(macOS)

final class FairToolTests: XCTestCase {
    func testToolVersion() async throws {
        let result = try await invokeTool(["version"])
        XCTAssertEqual(result.stderr, ["fairtool \(Bundle.fairCoreVersion?.versionStringExtended ?? "")"])
    }

    #if os(macOS)
    /// Verified that the "fairtool app info" command will output valid JSON that correctly identifies the app.
    func testToolAppInfo() async throws {
        let infoJSON = try await invokeTool(["app", "info", "/System/Applications/TextEdit.app"]).stdout
        let json = try [AppCommand.InfoCommand.Output](json: infoJSON.joined().utf8Data)
        XCTAssertEqual("com.apple.TextEdit", json.first?.info.obj?["CFBundleIdentifier"]?.str)
    }
    #endif

    @discardableResult func invokeTool(toolPath: String = "fairtool", _ args: [String], expectSuccess: Int32? = 0) async throws -> CommandResult {
        try await Process.exec(cmd: buildOutputFolder().appendingPathComponent(toolPath).path, args: args).expect(exitCode: expectSuccess)
    }

    /// Returns path to the built products directory.
    func buildOutputFolder() -> URL {
        #if os(macOS) // check for Xcode test bundles
        for bundle in Bundle.allBundles where bundle.bundlePath.hasSuffix(".xctest") {
            return bundle.bundleURL.deletingLastPathComponent()
        }
        #endif

        // on linux, this should be the folder above the tool
        return Bundle.main.bundleURL
    }
}

#endif //os(macOS)
