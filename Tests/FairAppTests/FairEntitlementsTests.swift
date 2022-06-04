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
@testable import FairApp
import FairCore

// References:

// https://matrejek.eu/posts/reading-entitlements-swift/
// https://redmaple.tech/blogs/macho-files/
// https://github.com/matrejek/SwiftEntitlements/blob/master/Sources/SwiftEntitlements/ApplicationBinary.swift
// https://github.com/aidansteele/osx-abi-macho-file-format-reference
// https://iphonedev.wiki/index.php/Ldid

final class FairEntitlementsTests: XCTestCase {
    func extractEntitlements(_ data: Data) throws -> [AppEntitlements] {
        try MachOBinary(binary: SeekableDataHandle(data)).readEntitlements()
    }

    func testCurrentExecutable() throws {
        // probably: /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/Library/Xcode/Agents/xctest
        guard let exec = Bundle.main.executableURL else {
            return XCTFail("no executable URL")
        }

        dbg("test executable at:", exec.path)
        let entitlements = try extractEntitlements(Data(contentsOf: exec))
        dbg("entitlements:", entitlements.first)
        XCTAssertEqual(true, entitlements.first?.value(forKey: .get_task_allow) as? Bool)
    }

    func mktmpdir() throws -> URL {
        let tmpdir = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
        let testDir = URL(fileURLWithPath: ((#file as NSString).lastPathComponent as NSString).deletingPathExtension, isDirectory: true, relativeTo: tmpdir)
        let url = URL(fileURLWithPath: UUID().uuidString, isDirectory: true, relativeTo: testDir)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        dbg("created tmp dir:", url.path)
        return url
    }

    /// Saves the given data to the specified path beneath the given URL
    @discardableResult func save(data: Data, to path: String, in rootURL: URL) throws -> URL {
        let outputURL = URL(fileURLWithPath: path, isDirectory: false, relativeTo: rootURL)
        try FileManager.default.createDirectory(at: outputURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        try data.write(to: outputURL)
        return outputURL
    }

    func testDataWrappers() throws {
        let tmp = try mktmpdir()
        try save(data: "f1".utf8Data, to: "a.txt", in: tmp)
        try save(data: "f2".utf8Data, to: "a/b.txt", in: tmp)
        try save(data: "f3".utf8Data, to: "a/b/c.txt", in: tmp)
        try save(data: "f4".utf8Data, to: "a/b/c/d.txt", in: tmp)

        let dw1 = try FileSystemDataWrapper(root: tmp)

        let zipFile = tmp.appendingPathExtension("zip")
        try FileManager.default.zipItem(at: tmp, to: zipFile, shouldKeepParent: false, compressionMethod: .deflate)

        guard let zip = ZipArchive(url: zipFile, accessMode: .read) else {
            return XCTFail("could not create zip from: \(zipFile.path)")
        }
        let dw2 = ZipArchiveDataWrapper(archive: zip)

        // it is (currently) expected that directory paths will differ slightly between the zip wrapper and the FS wrapper: the zip has a trailing slash after directory entries, and the fs doesn't have any trailing slashes

        dbg("dw1 paths:", dw1.paths.map(\.relativePath))
        XCTAssertEqual(["a", "a/b.txt", "a/b", "a/b/c.txt", "a/b/c", "a/b/c/d.txt", "a.txt"], dw1.paths.map(\.relativePath))

        dbg("dw2 paths:", dw2.paths.map(\.path))
        XCTAssertEqual(["a/", "a/b.txt", "a/b/", "a/b/c.txt", "a/b/c/", "a/b/c/d.txt", "a.txt"], dw2.paths.map(\.path))

        for pattern in [
            "^a/b/c.txt$",
            "^a/b.txt$",
            "^a.txt$",
            "^.*/b.txt$",
            "^.*/c.txt$",
            "^[^/]/b.txt$",
        ] {
            XCTAssertEqual(1, dw1.find(pathsMatching: try NSRegularExpression(pattern: pattern)).count, "bad count for pattern: \(pattern)")
            XCTAssertEqual(1, dw2.find(pathsMatching: try NSRegularExpression(pattern: pattern)).count, "bad count for pattern: \(pattern)")
        }
    }

    func readFile(_ path: String) throws -> AppEntitlements {
        try XCTUnwrap(extractEntitlements(Data(contentsOf: URL(fileURLWithPath: dump(path, name: "reading file")))).first)
    }

    func testmacOSEntitlements() throws {

        let appsFolder = URL(fileURLWithPath: "/Applications")
        if FileManager.default.isDirectory(url: appsFolder) != true {
            throw XCTSkip("no /Applications folder on platform")
        }
        
        let macOSApps = try FileManager.default.contentsOfDirectory(at: appsFolder, includingPropertiesForKeys: nil).filter({ $0.pathExtension == "app" })

        for app in macOSApps {
            dbg("SCANNING:", app.path)
            do {

                let executable = app.appendingPathComponent("Contents/MacOS").appendingPathComponent(app.deletingPathExtension().lastPathComponent)

                if FileManager.default.isExecutableFile(atPath: executable.path) {
                    dbg("scanning macOS executable:", executable.path)

                    if executable.lastPathComponent == "Sonos" { continue }
                    if executable.lastPathComponent == "Docker" { continue }
                    if executable.lastPathComponent == "Transmission" { continue }
                    if executable.lastPathComponent == "Final Cut Pro" { continue }
                    if executable.lastPathComponent == "Xcode" { continue }

                    //XCTAssertNoThrow(try readFile(executable.path), "executable failed: \(executable.path)")
                    do {
                        let _ = try readFile(executable.path)
                    } catch {
                        XCTFail("executable failed: \(executable.path) with error: \(error)")
                    }


                    let archive = try AppBundle(folderAt: app)
                    try validate(archive: archive, from: app)

                    if executable.lastPathComponent == "Numbers" {
                        let sandboxed = try archive.isSandboxed()
                        XCTAssertEqual(true, sandboxed, "App not sandboxed: \(executable.lastPathComponent)")
                    }
                }
            }
        }
        dbg("scanned: \(macOSApps.count) macOS apps")

    }

    func validate<A: DataWrapper>(archive: AppBundle<A>, from: URL) throws {
        let plist = archive.infoDictionary
        dbg("validating:", from.relativePath, plist.CFBundleIdentifier, plist.CFBundleName, plist.CFBundleShortVersionString)
        if plist.CFBundleIdentifier?.hasPrefix("app.") == true {
            // perform fairground-app specific validation
        } else {
            guard let entitlements = try archive.entitlements(), !entitlements.isEmpty else {
                return XCTFail("no entitlements in executable")
            }

            dbg("entitlements:", "app groups:", entitlements.first?.value(forKey: .application_groups))
            let groups = try? archive.appGroups()
            dbg("app groups:", groups)
        }
    }
}


