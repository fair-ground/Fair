/**
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
import XCTest
import FairExpo
import FairApp

#if os(macOS)

final class FairToolTests: XCTestCase {
    func testToolVersion() async throws {
        let result = try await invokeTool(["version"])
        XCTAssertEqual(result.stderr.utf8String, "fairtool \(Bundle.fairCoreVersion?.versionStringExtended ?? "")\n")
    }

    #if os(macOS)
    /// Verifies that the "fairtool app info" command will output valid JSON that correctly identifies the app.
    func testToolAppInfo() async throws {
        let infoJSON = try await invokeTool(["app", "info", "/System/Applications/TextEdit.app"]).stdout
        let json = try [ArtifactCommand.InfoCommand.Output](json: infoJSON)
        XCTAssertEqual("com.apple.TextEdit", json.first?.info.obj?["CFBundleIdentifier"]?.str)
    }
    #endif

    @discardableResult func invokeTool(toolPath: String = "fairtool", _ args: [String], expectSuccess: Int32? = 0) async throws -> CommandResult {
        try await Process.exec(cmd: buildOutputFolder().appendingPathComponent(toolPath).path, args: args).expect(exitCode: expectSuccess)
    }

    /// Returns the path to the built products directory.
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
