/**
 Copyright (c) 2022 Marc Prud'hommeaux

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
import XCTest
import FairApp
import FairExpo
import ArgumentParser
import fairtool

/// Tests different command options for the FairToolCommand.
///
/// These tests perform tool operations in the same process, which is different from the
/// `FairToolTests.swift`, which performs test by invoking the actual tool executable and parsing the output.
final class FairCommandTests: XCTestCase {
    typealias ToolMessage = (kind: MessageKind, items: [Any?])

    /// Invokes the `FairTool` with a command that expects a JSON-serialized output for a `FairParsableCommand`
    /// The command will be invoked and the result will be deserialized into the expected structure.
    private func runToolOutput<C: FairParsableCommand>(_ type: ParsableCommand.Type?, cmd: C.Type, _ args: [String]) async throws -> (output: [C.Output], messages: [(MessageKind, [Any?])]) where C.Output : Decodable {
        let result = try await runTool(type: type?.configuration.commandName, op: C.configuration.commandName, args)
        let output = result.output.joined()
        //dbg("output:", output)
        return (try [C.Output](fromJSON: output.utf8Data, dateDecodingStrategy: .iso8601), result.messages)
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

    /// Returns the URL of the app to download with the standard fairground layout.
    /// - Parameters:
    ///   - appName: the name of the app
    ///   - ios: whether this is iOS or macOS
    private static func appDownloadURL(for appName: String, version: String?, platform: AppPlatform) throws -> URL {
        func dlpath() throws -> String {
            switch platform {
            case .iOS: return appName + "-" + "iOS.ipa"
            case .macOS: return appName + "-" + "macOS.zip"
            default: throw AppError("unknown platform: \(platform)")
            }
        }
        if let version = version {
            guard let remoteURL = URL(string: "https://github.com/\(appName)/App/releases/download/\(version)/" + (try dlpath())) else {
                throw AppError("cannot create url")
            }
            return remoteURL
        } else {
            guard let remoteURL = URL(string: "https://github.com/\(appName)/App/releases/latest/download/" + (try dlpath())) else {
                throw AppError("cannot create url")
            }
            return remoteURL
        }
    }

    /// Downloads the most recent version of the given App Fair app.
    /// - Parameters:
    ///   - appName: the name of the app
    ///   - ios: whether this is iOS or macOS
    private static func downloadApp(name appName: String, version: String?, platform: AppPlatform) async throws -> URL {
        let remoteURL = try appDownloadURL(for: appName, version: version, platform: platform)
        let (localURL, response) = try await prf("download: \(remoteURL.absoluteURL)") {
            try await URLSession.shared.downloadFile(for: URLRequest(url: remoteURL, cachePolicy: .returnCacheDataElseLoad))
        }
        try response.validateHTTPCode()
        return localURL
    }

    func testVersionCommand() async throws {
        let result = try await runTool(op: FairToolCommand.VersionCommand.configuration.commandName)
        let output = extract(result.messages).first
        XCTAssertTrue(output?.hasPrefix("fairtool") == true, output ?? "")
    }

    func testSourceCreateAPI() async throws {
        let url = try Self.appDownloadURL(for: "Cloud-Cuckoo", version: nil, platform: .iOS)

        let catalog = try await AppCatalogAPI.shared.catalogApp(url: url)
        XCTAssertEqual("Cloud Cuckoo", catalog.name)
        XCTAssertEqual("A whimsical game of excitement and delight", catalog.subtitle)
        //XCTAssertEqual(nil, catalog.fundingLinks?.first?.platform) // no longer present in AppSource
    }

    func fetchApp(named name: String, unzip: Bool = true) async throws -> URL {
        let localURL = try await Self.downloadApp(name: name, version: nil, platform: .iOS)
        if !unzip {
            return localURL
        }

        let downloadName = localURL.deletingPathExtension().lastPathComponent

        let targetFolder = URL(fileURLWithPath: UUID().uuidString, isDirectory: true, relativeTo: .tmpdir)
        try FileManager.default.createDirectory(at: targetFolder, withIntermediateDirectories: true)

        let downloadAppURL = URL(fileURLWithPath: downloadName, isDirectory: true, relativeTo: targetFolder)
        if FileManager.default.fileExists(atPath: downloadAppURL.path) == true {
            try FileManager.default.removeItem(at: downloadAppURL)
        }

        try FileManager.default.unzipItem(at: localURL, to: downloadAppURL, skipCRC32: true)
        dbg("unzipped to:", downloadAppURL.path)

        return downloadAppURL
    }

    #if os(macOS)
    func testConvertIPA() async throws {
        let downloadAppURL = try await fetchApp(named: "Cloud-Cuckoo", unzip: true)
        let bundle = try await AppBundle(folderAt: downloadAppURL)

        try bundle.validatePaths()

        let convertedURL = try await bundle.setCatalystPlatform(resign: "-")
        dbg("converted platform at:", convertedURL.path)

        //try await Process.exec(cmd: "/usr/bin/open", convertedURL.path).expect()
        //try await Process.spctlAssess(appURL: convertedURL).expect()
        try await Process.codesignVerify(appURL: convertedURL).expect()
    }

    func testDisassembly() async throws {
        let downloadAppURL = try await fetchApp(named: "Cloud-Cuckoo", unzip: true)
        let lib = URL(fileURLWithPath: "Payload/Cloud Cuckoo.app/Frameworks/App.framework/App", isDirectory: false, relativeTo: downloadAppURL)
        let assembly = try await Process.otool(url: lib, params: ["-tVX"]).expect().stdout
        XCTAssertNotEqual(0, assembly.count)
    }
    #endif

    /// Runs "fairtool app info <url>" on a remote .ipa file, which it will download and analyze.
    func testArtifactInfoCommandiOS() async throws {
        let (result, _) = try await runToolOutput(ArtifactCommand.self, cmd: ArtifactCommand.InfoCommand.self, [Self.appDownloadURL(for: "Cloud-Cuckoo", version: nil, platform: .iOS).absoluteString])

        XCTAssertEqual("app.Cloud-Cuckoo", result.first?.info.object?["CFBundleIdentifier"]?.string)
        XCTAssertEqual(0, result.first?.entitlements?.count, "no entitlements expected in this ios app")
    }

    /// Runs "fairtool app info <url>" on a remote .app .zip file, which it will download and analyze.
    func testArtifactInfoCommandMacOS() async throws {
        let (result, _) = try await runToolOutput(ArtifactCommand.self, cmd: ArtifactCommand.InfoCommand.self, [Self.appDownloadURL(for: "Cloud-Cuckoo", version: nil, platform: .macOS).absoluteString])

        XCTAssertEqual("app.Cloud-Cuckoo", result.first?.info.object?["CFBundleIdentifier"]?.string)
        XCTAssertEqual(2, result.first?.entitlements?.count, "expected two entitlements in a fat binary")
        XCTAssertEqual(true, result.first?.entitlements?.first?.object?["com.apple.security.app-sandbox"])
        XCTAssertEqual(false, result.first?.entitlements?.first?.object?["com.apple.security.network.client"])
    }

    func testArtifactInfoCommandMacOSStream() async throws {
        var cmd = try ArtifactCommand.InfoCommand.parseAsRoot(["info"]) as! ArtifactCommand.InfoCommand

        cmd.apps = []
        cmd.apps += [try Self.appDownloadURL(for: "Cloud-Cuckoo", version: nil, platform: .iOS).absoluteString]
        cmd.apps += [try Self.appDownloadURL(for: "Cloud-Cuckoo", version: nil, platform: .macOS).absoluteString]

        var count = 0

        for try await result in cmd.executeCommand() {
            //XCTAssertEqual("app.Cloud-Cuckoo", result.info.obj?["CFBundleIdentifier"]?.str)
            XCTAssertNotNil(result.info.object?["CFBundleIdentifier"]?.string)

            if cmd.apps.first?.hasSuffix("macOS.zip") == true {
                XCTAssertEqual(2, result.entitlements?.count, "expected two entitlements in a fat binary")
                XCTAssertEqual(true, result.entitlements?.first?.object?["com.apple.security.app-sandbox"])
                XCTAssertEqual(false, result.entitlements?.first?.object?["com.apple.security.network.client"])
            }
            //return

            count += 1
        }

        XCTAssertGreaterThan(count, 0, "expected at least one result")
    }

    func checkSource(catalogURL: URL, count: Int) async throws {
        let cat = try await AppCatalog.parse(jsonData: URLSession.shared.fetch(request: URLRequest(url: catalogURL)).data)

        // check the smallest apps
        // let apps = cat.apps.sorting(by: \.versionDate, ascending: false)
        let apps = cat.apps.sorting(by: \.size, ascending: true)

        for app in apps.prefix(count) {
            dbg("verifying app \(app.bundleIdentifier ?? "noid") in \(catalogURL.absoluteString)")

            guard let id = app.bundleIdentifier else {
                XCTFail("missing id for \(app)")
                continue
            }
            let (results, _) = try await runToolOutput(SourceCommand.self, cmd: SourceCommand.VerifyCommand.self, ["--verbose", "--bundle-id", id, catalogURL.absoluteString])

            let result = try XCTUnwrap(results.first)

            dbg("catalog:", try? result.prettyJSON)
            XCTAssertEqual(app.name, result.app.name, "failed to verify app \(app.bundleIdentifier ?? "noid") in \(catalogURL.absoluteString)")
        }
    }

    /// Runs "fairtool app info <url>" on a remote .app .zip file, which it will download and analyze.
    func testSourceVerifyCommandMacOS() async throws {
        try await checkSource(catalogURL: appfairCatalogURLMacOS, count: 3)
    }

    func testSourceVerifyCommandSources() async throws {
        try await checkSource(catalogURL: appfairCatalogURLIOS, count: 3)
    }

    func testSourceCreateCommand() async throws {
//        let paths = [Self.appDownloadURL(for: "Tune-Out", version: nil, platform: .iOS), "https://github.com/Cloud-Cuckoo/App/releases/latest/download/Cloud-Cuckoo-macOS.zip", "https://github.com/Cloud-Cuckoo/App/releases/latest/download/Cloud-Cuckoo-iOS.ipa"]
        let paths = (try? FileManager.default.contentsOfDirectory(at: URL(fileURLWithPath: "/opt/src/ipas/"), includingPropertiesForKeys: nil).filter({ $0.pathExtension == "ipa" }).map(\.path)) ?? []

        if paths.isEmpty {
            throw XCTSkip("No local testing .ipa files")
        }

        let args = paths.shuffled().prefix(10)
        dbg("building source for apps:", args)

        // doesn't work because it expects an array output
        // let (results, _) = try await runToolOutput(SourceCommand.self, cmd: SourceCommand.CreateCommand.self, ["--verbose"] + args)

        let result = try await runTool(type: "source", op: SourceCommand.CreateCommand.configuration.commandName, Array(args))
        let output = result.output.joined()
        //dbg("output:", output)
        let catalog = try AppCatalog(fromJSON: output.utf8Data, dateDecodingStrategy: .iso8601)
        dbg("catalog:", try? catalog.toJSON(outputFormatting: [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes], dateEncodingStrategy: .iso8601).utf8String)
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
            // XCTAssertEqual(error.localizedDescription, #"Bad argument: "org""#)
        }
    }

    #if os(macOS)
    func testIconCommand() async throws {
        do {
            let result = try await runTool(type: FairCommand.configuration.commandName, op: FairCommand.IconCommand.configuration.commandName)
            XCTAssertFalse(result.messages.isEmpty)
        } catch {
            XCTAssertEqual("\(error)", #"CommandError(commandStack: [fairtool.FairToolCommand, fairtool.FairCommand, fairtool.FairCommand.IconCommand], parserError: ArgumentParser.ParserError.noValue(forKey: orgOptions.org))"#)
        }
    }

    /// Runs "fairtool app info <url>" on a homebrew cask .app .zip file
    func testArtifactInfoCommandStocks() async throws {
        let stocksPath = "/System/Applications/Stocks.app"
//        if !FileManager.default.itemExists(at: URL(fileURLWithPath: stocksPath)) {
//            throw XCTSkip("no stocks app") // e.g., Linux
//        }
        let (result, _) = try await runToolOutput(ArtifactCommand.self, cmd: ArtifactCommand.InfoCommand.self, [stocksPath])

        XCTAssertEqual("com.apple.stocks", result.first?.info.object?["CFBundleIdentifier"]?.string)
        XCTAssertEqual(2, result.first?.entitlements?.count, "expected two entitlements in a fat binary")
        XCTAssertEqual(true, result.first?.entitlements?.first?.object?["com.apple.security.app-sandbox"])
        XCTAssertEqual(true, result.first?.entitlements?.first?.object?["com.apple.security.network.client"])
    }

    #endif

    func testMergeCommand() async throws {
        do {
            let result = try await runTool(type: FairCommand.configuration.commandName, op: FairCommand.MergeCommand.configuration.commandName, ["--verbose", "--hub", "github.com/appfair", "--org", "Cloud-Cuckoo", "--token", "XXX", "--base", "XXX", "--project", "XXX", "--fair-properties", "Info.plist"])
            XCTAssertFalse(result.messages.isEmpty)
        } catch {
            //XCTAssertEqual("\(error)", #"CommandError(commandStack: [FairExpo.FairToolCommand, FairExpo.FairCommand, FairExpo.FairCommand.MergeCommand], parserError: FairCore.ParserError.noValue(forKey: FairCore.InputKey(rawValue: "org")))"#)
            XCTAssertTrue("\(error)".contains("file"), "unexpected error: \(error)")
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
            XCTAssertEqual("\(error)", #"CommandError(commandStack: [fairtool.FairToolCommand, fairtool.FairCommand, fairtool.FairCommand.CatalogCommand], parserError: ArgumentParser.ParserError.noValue(forKey: hubOptions.hub))"#)
        }
    }

    func testAppcasksCommand() async throws {
        do {
            let result = try await runTool(type: BrewCommand.configuration.commandName, op: BrewCommand.AppCasksCommand.configuration.commandName)
            XCTAssertFalse(result.messages.isEmpty)
        } catch {
            XCTAssertEqual("\(error)", #"CommandError(commandStack: [fairtool.FairToolCommand, fairtool.BrewCommand, fairtool.BrewCommand.AppCasksCommand], parserError: ArgumentParser.ParserError.noValue(forKey: hubOptions.hub))"#)
        }
    }

    func testFetchCaskInfo() async throws {
        let (casks, _) = try await HomebrewAPI(caskAPIEndpoint: HomebrewAPI.defaultEndpoint).fetchCasks()
        XCTAssertGreaterThan(casks.count, 4_000, "too few casks") // 4_021 at last count
    }

    func testFetchCaskStats() async throws {
        let stats = try await HomebrewAPI(caskAPIEndpoint: HomebrewAPI.defaultEndpoint).fetchAppStats()
        XCTAssertGreaterThan(stats.total_count, 1000, "too few casks") // 13936 at last count
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

    /// Ensures that the catalog verifies against various public sources
    func testExternalCatalogVerification() async throws {
        /// downloads the catalog at the given URL and ensures that it parses correctly
        let fetch = { url in try AppCatalog.parse(jsonData: await URLSession.shared.fetch(request: URLRequest(url: URL(string: dump(url, name: "downloading catalog from: \(url)"))!)).data) }

        do {
            let cat = try await fetch("https://apps.altstore.io")
            XCTAssertNotEqual(0, cat.apps.count)
        }

        do {
            let cat = try await fetch("https://alt.getutm.app")
            XCTAssertNotEqual(0, cat.apps.count)
        }

        do {
            let cat = try await fetch("https://flyinghead.github.io/flycast-builds/altstore.json")
            XCTAssertNotEqual(0, cat.apps.count)
        }
    }

    func testCatalogPost() async throws {
        let pre = try Bundle.module.loadResource(named: "fairapps-pre.json")
        let post = try Bundle.module.loadResource(named: "fairapps-post.json")
        XCTAssertNotEqual(pre, post)

        let cat1 = try AppCatalog.parse(jsonData: pre)
        let cat2 = try AppCatalog.parse(jsonData: post)
        XCTAssertNotEqual(try cat1.json(), try cat2.json())

        let diffs = AppCatalog.newReleases(from: cat1, to: cat2)
        let diff = try XCTUnwrap(diffs.first, "should have been differences between catalogs")
        XCTAssertEqual(1, diffs.count, "should have been only a single difference")

        XCTAssertEqual("0.9.75", diff.new.version)
        XCTAssertEqual("0.9.74", diff.old?.version)

        struct NewsFormat : NewsItemFormat {
            var postTitle: String?
            var postTitleUpdate: String?
            var postCaption: String?
            var postCaptionUpdate: String?
            var postBody: String?
            var postAppID: String?
            var postURL: String?
            var tweetBody: String?
        }

        let fmt = NewsFormat(postTitle: "New Release: #(appname) VERSION #(appversion)", postTitleUpdate: "Updated Release: #(appname) #(appversion)", postCaption: "#(appname) version #(appversion) has been released", postCaptionUpdate: "#(appname) version #(appversion) has been updated from #(oldappversion)", postBody: "NEW RELEASE", tweetBody: "New Release on the App Fair: #(appname) #(appversion) - https://appfair.app/fair?app=#(appname_hyphenated)")

        let twitterAuth: OAuth1.Info? = nil // wip(OAuth1.Info(consumerKey: "XXX", consumerSecret: "XXX", oauthToken: "XXX", oauthTokenSecret: "XXX"))

        var cat2Post = cat2
        _ = try await fmt.postUpdates(to: &cat2Post, with: diffs)
        // XCTAssertEqual(try cat2Post.json(), try cat2.json())
        _ = try await fmt.postUpdates(to: &cat2Post, with: diffs, twitterAuth: twitterAuth, newsLimit: 1, tweetLimit: 1)
        //XCTAssertNotEqual(try cat2Post.json(), try cat2.json())

        XCTAssertEqual("release-app.Cloud-Cuckoo-0.9.75", cat2Post.news?.first?.identifier)
        XCTAssertEqual("Updated Release: Cloud Cuckoo 0.9.75", cat2Post.news?.first?.title)
        XCTAssertEqual("Cloud Cuckoo version 0.9.75 has been updated from 0.9.74", cat2Post.news?.first?.caption)
        XCTAssertEqual("app.Cloud-Cuckoo", cat2Post.news?.first?.appID)
    }

    func testSignableJSON() throws {
        let key = "another test key"

        struct Demo : Encodable {
            let name: String
            let date: Date
        }

        let instance = Demo(name: "Abc", date: Date(timeIntervalSinceReferenceDate: 4321))

        struct SignableJSON<T: Encodable> : SigningContainer {
            let rawValue: T

            init(_ rawValue: T) {
                self.rawValue = rawValue
            }

            func encode(to encoder: Encoder) throws {
                try rawValue.encode(to: encoder)
            }
        }

        let signable = SignableJSON(instance)
        let sig = try signable.sign(key: key.utf8Data)
        XCTAssertEqual("lahFynjU/GPoeQA2xwqeiNE3i3nLVVvSvNhY0C0Ok1Q=", sig.base64EncodedString())

        do {
            // re-create the SignableJSON as a top-level type;
            // the signatures should match
            struct DemoSignable : Encodable, JSONSignable {
                let name: String
                let date: Date
                var signatureData: Data?
            }

            // fTr5rZNutkg8fmpQx0nWwiuA0UczFb3yfRxpducDw3Y=
            let instance2 = DemoSignable(name: instance.name, date: instance.date)
            let sig2 = try instance2.sign(key: key.utf8Data)
            XCTAssertEqual(sig.base64EncodedString(), sig2.base64EncodedString())
        }

    }

    func testLocalizableStrings() throws {
        do {
            let strings = """
            "A" = "B";
            """
            let file = try LocalizedStringsFile(fileContents: strings)
            XCTAssertEqual(["A"], file.keys)
        }

        do {
            let strings = """
            // comment 1
            "A" = "B";
            /* comment 2 */
            "C" = "D";
            """
            var file = try LocalizedStringsFile(fileContents: strings)
            XCTAssertEqual(["A", "C"], file.keys)
            try file.update(strings: .init(rawValue: ["A": "X"]))
            XCTAssertEqual(["A"], file.keys)

            XCTAssertEqual(file.fileContents, """
            // comment 1
            "A" = "X";
            /* comment 2 */
            "C" = "D";
            """)
        }
    }

    func testFairMetadataCommand() async throws {

        @discardableResult func check(_ yaml: String, customize: (inout FairCommand.MetadataCommand) -> () = { _ in }) async throws -> (folder: URL, metadata: [AppMetadata]) {
            let folder = URL(fileURLWithPath: UUID().uuidString, isDirectory: true, relativeTo: URL.tmpdir)
            try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)

            let metadata = URL(fileURLWithPath: "metadata.yml", isDirectory: false, relativeTo: folder)

            try yaml.write(to: metadata, atomically: true, encoding: .utf8)

            var cmd = try FairCommand.MetadataCommand.parseAsRoot(["metadata"]) as! FairCommand.MetadataCommand

            // cmd.valueOverride = ["key=value"]
            cmd.yaml = [metadata.absoluteString]
            cmd.export = folder.path // export to the same folder as the metadata source

            customize(&cmd)

            var results: [AppMetadata] = []
            for try await result in cmd.executeCommand() {
                results.append(result)
            }
            XCTAssertGreaterThan(results.count, 0, "expected at least one result")
            return (folder, results)
        }

        func load(from folder: URL, path: String) throws -> String {
            try String(contentsOf: URL(fileURLWithPath: path, relativeTo: folder))
        }

        do {
            let result = try await check("app:\n  name: 'Some App'\n  subtitle: '123456789012345678901234567890'")
            XCTAssertEqual("Some App", result.metadata.first?.name)
            XCTAssertEqual("123456789012345678901234567890", result.metadata.first?.subtitle)
            XCTAssertEqual("Some App", try load(from: result.folder, path: "default/name.txt"))
            XCTAssertEqual("123456789012345678901234567890", try load(from: result.folder, path: "default/subtitle.txt"))
        }


        // test localized prefix/override
        do {
            let result = try await check("""
            app:
              name: 'Some App'
              subtitle: '123456789012345678901234567890'
              localizations:
               fr-FR:
                 name: 'Le App'
               de-DE:
                 subtitle: 'Ein App Awesome!'
               en-GB:
                 description: 'A super good app that does anything you want.'
               xxx: # note: we currently tolerate unrecognized locales; should we fail?
                 name: 'XXX'
            """) { cmd in
                cmd.valueAppend = ["fr-FR/name=!!!"]
                cmd.valueDefault = ["de-DE/description=GERMAN DESCRIPTION"]
                cmd.valueOverride = ["en-GB/subtitle=A jolly good app"]
            }

            XCTAssertEqual("Some App", result.metadata.first?.name)
            XCTAssertEqual("123456789012345678901234567890", result.metadata.first?.subtitle)

            XCTAssertEqual("Some App", try load(from: result.folder, path: "default/name.txt"))
            XCTAssertEqual("123456789012345678901234567890", try load(from: result.folder, path: "default/subtitle.txt"))

            XCTAssertEqual("Le App!!!", try load(from: result.folder, path: "fr-FR/name.txt"))

            XCTAssertEqual("Ein App Awesome!", try load(from: result.folder, path: "de-DE/subtitle.txt"))
            XCTAssertEqual("GERMAN DESCRIPTION", try load(from: result.folder, path: "de-DE/description.txt"))

            XCTAssertEqual("A jolly good app", try load(from: result.folder, path: "en-GB/subtitle.txt"))
            XCTAssertEqual("A super good app that does anything you want.", try load(from: result.folder, path: "en-GB/description.txt"))

            // unrecognized locale; maybe we should fail?
            XCTAssertEqual("XXX", try load(from: result.folder, path: "xxx/name.txt"))
        }

        do {
            try await check("app:\n  subtitle: '1234567890123456789012345678901'") { cmd in
            }
            XCTFail("expected error from value over max length")
        } catch {
            // expected
        }

        do {
            try await check("""
            xapp:
                name: "parse_error"
            """) { cmd in

            }
            XCTFail("expected error from metadata parsing")
        } catch {
            // expected
        }
    }

    func testAppConfigureCommand() async throws {
        let projectFolder = URL(fileURLWithPath: #function, isDirectory: true, relativeTo: .tmpdir)
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: projectFolder, withIntermediateDirectories: true, attributes: nil)
        let xcconfig = projectFolder.appendingPathComponent("appfair.xcconfig", isDirectory: false)

        try """
        // This is the name of the app
        PRODUCT_NAME = Some App

        // This is the semantic version for the app
        MARKETING_VERSION = 1.2.3

        // This is the build number of the app
        CURRENT_PROJECT_VERSION = 987
        """.write(to: xcconfig, atomically: true, encoding: .utf8)

        func checkProject(_ args: String...) async throws -> FairConfigureOutput {
            let results = try await runToolOutput(AppCommand.self, cmd: AppCommand.ConfigureCommand.self, ["--project", projectFolder.path] + args)
            return try XCTUnwrap(results.output.first)
        }

        do {
            let output = try await checkProject()
            XCTAssertEqual("Some App", output.productName)
            XCTAssertEqual("1.2.3", output.version?.versionString)
            XCTAssertEqual(987, output.buildNumber)
        }

        do {
            let output = try await checkProject("--bump", "patch")
            XCTAssertEqual("1.2.4", output.version?.versionString)
        }

        do {
            let output = try await checkProject("--bump", "minor")
            XCTAssertEqual("1.3.0", output.version?.versionString)
        }

        do {
            let output = try await checkProject("--bump", "major")
            XCTAssertEqual("2.0.0", output.version?.versionString)
        }

        do {
            let output = try await checkProject("--version", "1.1.1")
            XCTAssertEqual("1.1.1", output.version?.versionString)
        }

        do {
            let output = try await checkProject("--name", "Another App")
            XCTAssertEqual("Another App", output.productName)
        }

        do {
            let output = try await checkProject("--build-number", "989")
            XCTAssertEqual(989, output.buildNumber)
        }

        do {
            let output = try await checkProject("--id", "app.Another-App")
            XCTAssertEqual("app.Another-App", output.bundleIdentifier)
        }

        do {
            let output = try await checkProject("--platforms", "macosx iphoneos iphonesimulator")
            XCTAssertEqual("macosx iphoneos iphonesimulator", output.supportedPlatforms)
        }

        XCTAssertEqual("""
        // This is the name of the app
        PRODUCT_NAME = Another App

        // This is the semantic version for the app
        MARKETING_VERSION = 1.1.1

        // This is the build number of the app
        CURRENT_PROJECT_VERSION = 989
        PRODUCT_BUNDLE_IDENTIFIER = app.Another-App
        SUPPORTED_PLATFORMS = macosx iphoneos iphonesimulator
        """, try String(contentsOf: xcconfig, encoding: .utf8), "comments should be preserved when updating env")
    }
}

public struct PackageManifest : Hashable, Decodable {
    public var name: String
    //public var toolsVersion: String // can be string or dict
    public var products: [Product]
    public var dependencies: [Dependency]
    //public var targets: [Either<Target>.Or<String>]
    public var platforms: [SupportedPlatform]
    public var cModuleName: String?
    public var cLanguageStandard: String?
    public var cxxLanguageStandard: String?

    public struct Target: Hashable, Decodable {
        public enum TargetType: String, Hashable, Decodable {
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


    public struct Product : Hashable, Decodable {
        //public var `type`: ProductType // can be string or dict
        public var name: String
        public var targets: [String]

        public enum ProductType: String, Hashable, Decodable, CaseIterable {
            case library
            case executable
        }
    }

    public struct Dependency : Hashable, Decodable {
        public var name: String?
        public var url: String
        //public var requirement: Requirement // revision/range/branch/exact
    }

    public struct SupportedPlatform : Hashable, Decodable {
        var platformName: String
        var version: String
    }
}

class TweetTests : XCTestCase {
    let oauth_consumer_key: String? = nil // wip("XXX")
    let oauth_consumer_secret: String? = nil // wip("XXX")
    let oauth_token: String? = nil // wip("XXX")
    let oauth_token_secret: String? = nil // wip("XXX")

    func testPostTweet() async throws {
        let msg = "Hello World: \((100...999).randomElement()!)"
        guard let oauth_consumer_key = oauth_consumer_key,
              let oauth_consumer_secret = oauth_consumer_secret,
              let oauth_token = oauth_token,
              let oauth_token_secret = oauth_token_secret else {
            throw XCTSkip("skipping test due to missing auth information")
              }

        let info = OAuth1.Info(consumerKey: oauth_consumer_key, consumerSecret: oauth_consumer_secret, oauthToken: oauth_token, oauthTokenSecret: oauth_token_secret)

        do {
            let response = try await Tweeter.post(text: msg, auth: info)
            dbg("received response:", response)
            XCTAssertEqual(response.response?.data.text, msg)
        }

        // duplicate tweets are forbidden
        do {
            let response = try await Tweeter.post(text: msg, auth: info)
            dbg("received response:", response)
            XCTAssertEqual(403, response.error?.status)
            XCTAssertEqual("Forbidden", response.error?.title)
            XCTAssertEqual("You are not allowed to create a Tweet with duplicate content.", response.error?.detail)
        }

    }
}
