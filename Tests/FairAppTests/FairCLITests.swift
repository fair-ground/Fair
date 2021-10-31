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

    func testToolResources() throws {
        XCTAssertEqual(2, try FairTemplate.packageParts.get().count)
    }

    func testBuildTemplate() throws {
        let fm = FileManager.default
        let folder = URL.tmpdir.appendingPathComponent("FairApps") // random folder for testing apps
        try? fm.trashItem(at: folder, resultingItemURL: nil) // clobber any existing folder if it exists
        let mkdir = { try fm.createDirectory(at: $0, withIntermediateDirectories: true, attributes: [:]) }


        @discardableResult func mkproj(_ name: String, build: Bool = true) throws -> URL {

            let scaffold = { try self.extract(kind: .info, self.runTool(op: .initialize, $0, $1)) }

            func createProject(named name: String) throws -> URL {
                let projectDir = folder.appendingPathComponent(name)
                try mkdir(projectDir)
                let output = try scaffold("-o", projectDir.path)
                let _ = output
                return projectDir
            }

            let appRoot = try createProject(named: name)
            let res = { try String(contentsOf: appRoot.appendingPathComponent($0), encoding: .utf8) }

            let readme = try res("README.md")
            let _ = readme

            let package_swift = try res("Package.swift")
            let _ = package_swift
            //XCTAssertEqual(2, package_swift.components(separatedBy: FairTemplate.guardLine).count)

            let app_container_swift = try res("Sources/App/AppContainer.swift")
            let _ = app_container_swift
            //XCTAssertEqual(2, app_swift.components(separatedBy: FairTemplate.guardLine).count)

            let app_main_swift = try res("Sources/App/AppMain.swift")
            let _ = app_main_swift

            let apptests_swift = try res("Tests/AppTests/AppTests.swift")
            let _ = apptests_swift

            let project_contents = try res("project.xcodeproj/project.pbxproj")
            let _ = project_contents

            let workspace_contents = try res("App.xcworkspace/contents.xcworkspacedata")
            let _ = workspace_contents

            if build {
                dbg("building:", appRoot.path)
                let appBaseDash = appRoot.lastPathComponent
                let appBaseCompact = appBaseDash.split(separator: "-").joined(separator: "").description
                let _ = appBaseCompact

                let workspace = appRoot.appendingPathComponent(appBaseDash).appendingPathExtension("xcworkspace")
                if !fm.fileExists(atPath: workspace.path) {
                    throw CocoaError(.fileReadNoSuchFile)
                }

                // no targets are configured for testing by default
                // let _ = try Process.exec(cmd: "/usr/bin/xcodebuild", "-workspace", workspace.path, "-scheme", "App", "test")

                try Process.swift(op: "build", xcrun: true, packageFolder: appRoot) // xcrun is needed when there is a non-default DEVELOPER_DIR

                // archive seems to fail on CI machines (maybe due to Xcode 12.4)
                //let _ = try Process.exec(cmd: "/usr/bin/xcodebuild", "-workspace", workspace.path, "-scheme", appBaseCompact, "-archivePath", workspace.appendingPathExtension("App.xcarchive").path, "build", "CODE_SIGNING_ALLOWED=NO", "CODE_SIGNING_REQUIRED=NO")

                // try Process.spctlAssess(appURL:)

                // try exec(cmd: "/usr/bin/swift", op, "--package-path", target: packageFolder)

                // next try xcodebuild: mkdir -p /tmp/Abc-Xyz; swift run fairtool init -o /tmp/Abc-Xyz && xcodebuild -workspace /tmp/Abc-Xyz/*.xcworkspace -scheme AbcXyz build ; codesign --verify -vv ~/Library/Developer/Xcode/DerivedData/Abc-Xyz*/Build/Products/Debug/AbcXyz.app
            }


            return appRoot
        }

        let pname = AppNameValidation.defaultAppName

        // $TMPDIR/FairApps/Foo-Bar/
        let appRoot = try mkproj(pname)
        let _ = appRoot

        let _ = try mkproj(pname)
        //XCTAssertThrowsError(try mkproj(pname)) // try again without overwrite
    }
}
#endif
