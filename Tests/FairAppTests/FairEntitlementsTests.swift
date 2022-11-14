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
import FairApp
import FairCore

// References:

// https://matrejek.eu/posts/reading-entitlements-swift/
// https://redmaple.tech/blogs/macho-files/
// https://github.com/matrejek/SwiftEntitlements/blob/master/Sources/SwiftEntitlements/ApplicationBinary.swift
// https://github.com/aidansteele/osx-abi-macho-file-format-reference
// https://iphonedev.wiki/index.php/Ldid

final class FairEntitlementsTests: XCTestCase {
    func extractEntitlements(_ data: Data) async throws -> [AppEntitlements] {
        try await MachOBinary(binary: SeekableDataHandle(data)).readEntitlements()
    }

    func testCurrentExecutable() async throws {
        // probably: /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/Library/Xcode/Agents/xctest
        guard let exec = Bundle.main.executableURL else {
            return XCTFail("no executable URL")
        }

        dbg("test executable at:", exec.path)
        #if !os(Linux) && !os(Android) && !os(Windows) // binaries are not Mach-O
        let entitlements = try await extractEntitlements(Data(contentsOf: exec))
        dbg("entitlements:", entitlements.first)
        XCTAssertEqual(true, entitlements.first?.value(forKey: .get_task_allow) as? Bool)
        #endif
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
        #if os(Linux) || os(Android)
        throw XCTSkip("crashes for some reason")
        #endif

        let tmp = try mktmpdir()
        try save(data: "f1".utf8Data, to: "a.txt", in: tmp)
        try save(data: "f2".utf8Data, to: "a/b.txt", in: tmp)
        try save(data: "f3".utf8Data, to: "a/b/c.txt", in: tmp)
        try save(data: "f4".utf8Data, to: "a/b/c/d.txt", in: tmp)

        let dw1 = try FileSystemDataWrapper(root: tmp)

        let zipFile = tmp.appendingPathExtension("zip")

        dbg("zipping file to:", zipFile.path)
        try FileManager.default.zipItem(at: tmp, to: zipFile, shouldKeepParent: false, compressionMethod: .deflate)
        dbg("zipped file size:", zipFile.fileSize()?.localizedByteCount())

        guard let zip = ZipArchive(url: zipFile, accessMode: .read) else {
            return XCTFail("could not create zip from: \(zipFile.path)")
        }

        dbg("opened zip archive")

        let dw2 = ZipArchiveDataWrapper(archive: zip)

        // it is (currently) expected that directory paths will differ slightly between the zip wrapper and the FS wrapper: the zip has a trailing slash after directory entries, and the fs doesn't have any trailing slashes

        let dw1Paths = dw1.paths.map(\.pathName)
        let dw2Paths = dw2.paths.map(\.pathName)

        dbg("dw1 paths:", dw1Paths)
        XCTAssertEqual(["a", "a/b.txt", "a/b", "a/b/c.txt", "a/b/c", "a/b/c/d.txt", "a.txt"], dw1Paths.set())

        dbg("dw2 paths:", dw2Paths)
        XCTAssertEqual(["a", "a/b.txt", "a/b", "a/b/c.txt", "a/b/c", "a/b/c/d.txt", "a.txt"], dw2Paths.set())

        XCTAssertEqual(dw1Paths.set(), dw2Paths.set(), "zip and fs data wrapper paths should have been identical")

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

    func readEntitlements(_ path: String) async throws -> AppEntitlements {
        let entitlements = try await extractEntitlements(Data(contentsOf: URL(fileURLWithPath: dump(path, name: "reading file")))).first
        return try XCTUnwrap(entitlements, "could not find entitlement for \(path)")
    }

    func testMacOSEntitlements() async throws {

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

                    if executable.lastPathComponent == "Xcode" { continue }
                    if executable.lastPathComponent == "Firefox" { continue }
                    if executable.lastPathComponent == "Final Cut Pro" { continue }
                    if executable.lastPathComponent == "Docker" { continue }
                    if executable.lastPathComponent == "Sonos" { continue }
                    if executable.lastPathComponent == "Hex Fiend" { continue }
                    if executable.lastPathComponent == "Transmission" { continue }
                    if executable.lastPathComponent == "eDEX-UI" { continue }
                    if executable.lastPathComponent == "MacDown" { continue }

                    do {
                        let _ = try await readEntitlements(executable.path)
                    } catch {
                        XCTFail("executable failed: \(executable.path) with error: \(error)")
                    }

                    let archive = try await AppBundle(folderAt: FileManager.default.resolvingSymbolicLink(app))
                    try await validate(archive: archive, from: app)

                    if executable.lastPathComponent == "Numbers" {
                        let sandboxed = try await archive.isSandboxed()
                        XCTAssertEqual(true, sandboxed, "App not sandboxed: \(executable.lastPathComponent)")
                    }
                }
            }
        }
        dbg("scanned: \(macOSApps.count) macOS apps")

    }

    func validate<A: DataWrapper>(archive: AppBundle<A>, from: URL) async throws {
        let plist = archive.infoDictionary
        dbg("validating:", from.relativePath, plist.CFBundleIdentifier, plist.CFBundleName, plist.CFBundleShortVersionString)
        if plist.CFBundleIdentifier?.hasPrefix("app.") == true {
            // perform fairground-app specific validation
        } else {
            guard let entitlements = try await archive.entitlements(), !entitlements.isEmpty else {
                return XCTFail("no entitlements in executable")
            }

            dbg("entitlements:", "app groups:", entitlements.first?.value(forKey: .application_groups))
            let groups = try? await archive.appGroups()
            dbg("app groups:", groups)
        }
    }

#if os(macOS)
    func testCodesignVerify() async throws {
        let appFile = URL(fileURLWithPath: "TextEdit.app", relativeTo: try? FileManager.default.url(for: .applicationDirectory, in: .systemDomainMask, appropriateFor: nil, create: false))

        let result = try await Process.codesignVerify(appURL: appFile).expect()
        let verified = [result.stdout, result.stderr].compacted().compactMap({ $0.utf8String?.split(separator: "\n") }).joined()

        // ["Executable=/System/Applications/TextEdit.app/Contents/MacOS/TextEdit", "Identifier=com.apple.TextEdit", "Format=app bundle with Mach-O universal (x86_64 arm64e)", "CodeDirectory v=20400 size=1899 flags=0x0(none) hashes=49+7 location=embedded", "Platform identifier=13", "Signature size=4442", "Authority=Software Signing", "Authority=Apple Code Signing Certification Authority", "Authority=Apple Root CA", "Signed Time=Jul 31, 2021 at 08:16:31", "Info.plist entries=34", "TeamIdentifier=not set", "Sealed Resources version=2 rules=2 files=0", "Internal requirements count=1 size=68"]
        // print(verified)

        XCTAssertEqual(0, result.terminationStatus)
        XCTAssertTrue(verified.contains("Identifier=com.apple.TextEdit"))
        XCTAssertTrue(verified.contains("Authority=Apple Root CA"))
    }

#endif //os(macOS)


}


