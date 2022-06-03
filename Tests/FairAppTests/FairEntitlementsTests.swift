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

    func testEntitlements() throws {
        // /Applications/zoom.us.app/Contents/MacOS/zoom.us: Mach-O 64-bit executable arm64
        XCTAssertEqual(true, (try readFile("/Applications/zoom.us.app/Contents/MacOS/zoom.us")).value(forKey: .device_camera) as? Bool)

        // /Applications/Graphic.app/Contents/MacOS/Graphic: Mach-O 64-bit executable x86_64
        XCTAssertEqual("Production", dump(try readFile("/Applications/Graphic.app/Contents/MacOS/Graphic")).value(forKey: .iCloudContainersEnvironment) as? String)

        XCTAssertEqual(true, dump(try readFile("/opt/src/ipas/extract/Payload/Audible.app/Audible")).value(forKey: .init("com.apple.developer.carplay-audio")) as? Bool)

        XCTAssertEqual(true, dump(try readFile("/Applications/NetNewsWire.app/Contents/MacOS/NetNewsWire")).value(forKey: .app_sandbox) as? Bool)


        // fat binaries have multiple entitlements:
        XCTAssertEqual(0, dump(try readFile("/Applications/AltServer.app/Contents/MacOS/AltServer")).count)
        XCTAssertEqual(24, dump(try readFile("/Applications/Xcode.app/Contents/MacOS/Xcode")).count)
        XCTAssertEqual(5, dump(try readFile("/Applications/Transmit.app/Contents/MacOS/Transmit")).count)

        XCTAssertEqual(9, dump(try readFile("/Applications/Handbrake.app/Contents/MacOS/Handbrake")).count)
        XCTAssertEqual(3, dump(try readFile("/Applications/SF Symbols.app/Contents/MacOS/SF Symbols")).count)
        XCTAssertEqual(12, dump(try readFile("/Applications/NetNewsWire.app/Contents/MacOS/NetNewsWire")).count)
    }

    func testmacOSEntitlements() throws {

        let macOSApps = try FileManager.default.contentsOfDirectory(at: URL(fileURLWithPath: "/Applications"), includingPropertiesForKeys: nil).filter({ $0.pathExtension == "app" })

        for app in macOSApps {
            dbg("SCANNING:", app.path)
            // note under Contents on macOS, top-level in iOS
//                let info = app.appendingPathComponent("Info.plist")
//                let plist = try PropertyListSerialization.propertyList(from: Data(contentsOf: info), format: nil) as? NSDictionary

            // let executablePath = plist?["CFBundleExecutable"]
            // dbg("executablePath:", executablePath)

            do {

                let executable = app.appendingPathComponent("Contents/MacOS").appendingPathComponent(app.deletingPathExtension().lastPathComponent)

                if FileManager.default.isExecutableFile(atPath: executable.path) {
                    dbg("scanning macOS executable:", executable.path)
                    // XCTAssertNoThrow failed: threw error "codeSignatureCommandMissing" - executable failed: /Applications/cool-retro-term.app/Contents/MacOS/cool-retro-term

                    // XCTAssertNoThrow failed: threw error "signatureReadingError" - executable failed: /Applications/Transmission.app/Contents/MacOS/Transmission

                    if executable.lastPathComponent == "cool-retro-term" { continue }
                    if executable.lastPathComponent == "Docker" { continue }
                    if executable.lastPathComponent == "Final Cut Pro" { continue }
                    if executable.lastPathComponent == "Hex Fiend" { continue }
                    if executable.lastPathComponent == "Plex Media Server" { continue }
                    if executable.lastPathComponent == "Sonos" { continue }
                    if executable.lastPathComponent == "Transmission" { continue }

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

    func testiOSEntitlementsExpanded() throws {
        let iOSApps = try FileManager.default.contentsOfDirectory(at: URL(fileURLWithPath: "/opt/src/ipas/extract/Payload"), includingPropertiesForKeys: nil).filter({ $0.pathExtension == "app" })

        for app in iOSApps {
            do {
                // iOS executable
                let executable = app
                    .appendingPathComponent(app.deletingPathExtension().lastPathComponent)
                dbg("CHECKING:", executable)

                if FileManager.default.isReadableFile(atPath: executable.path) {
                    dbg("scanning iOS executable:", executable.path)

                    if executable.lastPathComponent == "Bon Mot" { continue }
                    if executable.lastPathComponent == "Cloud Cuckoo" { continue }
                    if executable.lastPathComponent == "Lottie Motion" { continue }
                    if executable.lastPathComponent == "Sita Sings the Blues" { continue }
                    if executable.lastPathComponent == "Tune Out" { continue }

                    // Signal is a fat IPA
                    // /opt/src/ipas/extract/Payload/Signal.app/Signal
                    // let expectedCount = executable.lastPathComponent == "Signal" ? 2 : 1

                    let actualCount = try readFile(executable.path).count
                    XCTAssertGreaterThan(actualCount, 0, "no entitlements in: \(executable.path)")
                }
            }
        }

        dbg("scanned: \(iOSApps.count) iOS apps")
    }


    /// Scans iOS apps packaged within an IPA
    func testiOSEntitlements() throws {
        let ipaFolder = URL(fileURLWithPath: "/opt/src/ipas")
        //var iOSApps = try FileManager.default.contentsOfDirectory(at: ipaFolder, includingPropertiesForKeys: nil)
        var iOSApps = try FileManager.default.deepContents(of: ipaFolder, includeFolders: false, relativePath: true)
        iOSApps = iOSApps.filter({ $0.pathExtension == "ipa" })

        for app in iOSApps {
            // no entitlements in executable
            if app.lastPathComponent == "Rewound.ipa" { continue }
            if app.lastPathComponent == "Taurine-1.1.3.ipa" { continue }
            if app.lastPathComponent == "NineAnimator_1.2.7_Build_6.ipa" { continue }
            if app.lastPathComponent == "Instagram-Rocket.ipa" { continue }
            if app.lastPathComponent == "Crunchyroll++.ipa" { continue }

            // missingInfo
            if app.lastPathComponent == "BHTwitter_2-7_8-87.ipa" { continue }
            if app.lastPathComponent == "BHTwitterPlus_9.2-2.9.2.ipa" { continue }
            if app.lastPathComponent == "CercubePlus_17.21.3_5.3.9.ipa" { continue }
            if app.lastPathComponent == "Duolingo++.ipa" { continue }
            if app.lastPathComponent == "Reborn_5-3-4_17-07-2.ipa" { continue }
            if app.lastPathComponent == "uYouPlus_17.21.3_2.1.ipa" { continue }

//            #warning("TODO: remove")
//            if app.lastPathComponent != ("Spotify%2B%2B.ipa") { continue }
             if app.lastPathComponent == "Spotify%2B%2B.ipa" { continue }

            // invalidSignature
            if app.lastPathComponent == "iNDS.ipa" { continue }
            if app.lastPathComponent == "Play.ipa" { continue }
            if app.lastPathComponent == "XPatcher_2.2.ipa" { continue }
            do {
                dbg("validating IPA:", app.relativePath)

                let archive = try AppBundle(zipArchiveAt: app)
                try validate(archive: archive, from: app)
            } catch {
                XCTFail("error with \(app.path): \(error)")
            }
        }

        dbg("scanned: \(iOSApps.count) iOS apps")
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


