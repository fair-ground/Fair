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
import FairCore
import FairApp
@testable import FairExpo
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// Tests different command options for the FairToolCommand.
///
/// These tests perform tool operations in the same process, which is different from the
/// `FairToolTests.swift`, which performs test by invoking the actual tool executable and parsing the output.
final class FairExpoTests: XCTestCase {
    typealias ToolMessage = (kind: MessageKind, items: [Any?])

    /// Invokes the `FairTool` with a command that expects a JSON-serialized output for a `FairParsableCommand`
    /// The command will be invoked and the result will be deserialized into the expected structure.
    private func runToolOutput<C: FairParsableCommand>(_ type: ParsableCommand.Type?, cmd: C.Type, _ args: [String]) async throws -> (output: [C.Output], messages: [(MessageKind, [Any?])]) where C.Output : Decodable {
        let result = try await runTool(type: type?.configuration.commandName, op: C.configuration.commandName, args)
        let output = result.output.joined()
        //dbg("output:", output)
        return (try [C.Output](json: output.utf8Data, dateDecodingStrategy: .iso8601), result.messages)
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
        XCTAssertEqual(nil, catalog.fundingLinks?.first?.platform) // no longer present in AppSource
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
        let bundle = try AppBundle(folderAt: downloadAppURL)

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
    func testAppInfoCommandiOS() async throws {
        let (result, _) = try await runToolOutput(AppCommand.self, cmd: AppCommand.InfoCommand.self, [Self.appDownloadURL(for: "Cloud-Cuckoo", version: nil, platform: .iOS).absoluteString])

        XCTAssertEqual("app.Cloud-Cuckoo", result.first?.info.obj?["CFBundleIdentifier"]?.str)
        XCTAssertEqual(0, result.first?.entitlements?.count, "no entitlements expected in this ios app")
    }

    /// Runs "fairtool app info <url>" on a remote .app .zip file, which it will download and analyze.
    func testAppInfoCommandMacOS() async throws {
        let (result, _) = try await runToolOutput(AppCommand.self, cmd: AppCommand.InfoCommand.self, [Self.appDownloadURL(for: "Cloud-Cuckoo", version: nil, platform: .macOS).absoluteString])

        XCTAssertEqual("app.Cloud-Cuckoo", result.first?.info.obj?["CFBundleIdentifier"]?.str)
        XCTAssertEqual(2, result.first?.entitlements?.count, "expected two entitlements in a fat binary")
        XCTAssertEqual(true, result.first?.entitlements?.first?.obj?["com.apple.security.app-sandbox"])
        XCTAssertEqual(false, result.first?.entitlements?.first?.obj?["com.apple.security.network.client"])
    }

    func testAppInfoCommandMacOSStream() async throws {
        var cmd = try AppCommand.InfoCommand.parseAsRoot(["info"]) as! AppCommand.InfoCommand

        cmd.apps = []
        cmd.apps += [try Self.appDownloadURL(for: "Cloud-Cuckoo", version: nil, platform: .iOS).absoluteString]
        cmd.apps += [try Self.appDownloadURL(for: "Cloud-Cuckoo", version: nil, platform: .macOS).absoluteString]

        var count = 0

        for try await result in cmd.executeCommand() {
            //XCTAssertEqual("app.Cloud-Cuckoo", result.info.obj?["CFBundleIdentifier"]?.str)
            XCTAssertNotNil(result.info.obj?["CFBundleIdentifier"]?.str)

            if cmd.apps.first?.hasSuffix("macOS.zip") == true {
                XCTAssertEqual(2, result.entitlements?.count, "expected two entitlements in a fat binary")
                XCTAssertEqual(true, result.entitlements?.first?.obj?["com.apple.security.app-sandbox"])
                XCTAssertEqual(false, result.entitlements?.first?.obj?["com.apple.security.network.client"])
            }
            //return

            count += 1
        }

        XCTAssertGreaterThan(count, 0, "expected at least one result")
    }

    func checkSource(catalogURL: URL, count: Int) async throws {
        let cat = try await AppCatalog.parse(jsonData: URLSession.shared.fetch(request: URLRequest(url: catalogURL)).data)

        let apps = cat.apps.sorting(by: \.versionDate, ascending: false)

        for app in apps.prefix(count) {
            dbg("verifying app \(app.bundleIdentifier) in \(catalogURL.absoluteString)")

            let (results, _) = try await runToolOutput(SourceCommand.self, cmd: SourceCommand.VerifyCommand.self, ["--verbose", "--bundle-id", app.bundleIdentifier, catalogURL.absoluteString])

            let result = try XCTUnwrap(results.first)

            dbg("catalog:", result.prettyJSON)
            XCTAssertEqual(app.name, result.app.name, "failed to verify app \(app.bundleIdentifier) in \(catalogURL.absoluteString)")
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
        let catalog = try AppCatalog(json: output.utf8Data, dateDecodingStrategy: .iso8601)
        dbg("catalog:", try? catalog.json(outputFormatting: [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes], dateEncodingStrategy: .iso8601).utf8String)
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
            XCTAssertEqual("\(error)", #"CommandError(commandStack: [FairExpo.FairToolCommand, FairExpo.FairCommand, FairExpo.FairCommand.IconCommand], parserError: FairCore.ParserError.noValue(forKey: FairCore.InputKey(rawValue: "org")))"#)
        }
    }

    /// Runs "fairtool app info <url>" on a homebrew cask .app .zip file
    func testAppInfoCommandStocks() async throws {
        let stocksPath = "/System/Applications/Stocks.app"
//        if !FileManager.default.itemExists(at: URL(fileURLWithPath: stocksPath)) {
//            throw XCTSkip("no stocks app") // e.g., Linux
//        }
        let (result, _) = try await runToolOutput(AppCommand.self, cmd: AppCommand.InfoCommand.self, [stocksPath])

        XCTAssertEqual("com.apple.stocks", result.first?.info.obj?["CFBundleIdentifier"]?.str)
        XCTAssertEqual(2, result.first?.entitlements?.count, "expected two entitlements in a fat binary")
        XCTAssertEqual(true, result.first?.entitlements?.first?.obj?["com.apple.security.app-sandbox"])
        XCTAssertEqual(true, result.first?.entitlements?.first?.obj?["com.apple.security.network.client"])
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

    func testFetchCaskInfo() async throws {
        let (casks, _) = try await HomebrewAPI(caskAPIEndpoint: HomebrewAPI.defaultEndpoint).fetchCasks()
        XCTAssertGreaterThan(casks.count, 4_000, "too few casks") // 4_021 at last count
    }

    func testFetchCaskStats() async throws {
        let stats = try await HomebrewAPI(caskAPIEndpoint: HomebrewAPI.defaultEndpoint).fetchAppStats()
        XCTAssertGreaterThan(stats.total_count, 500_000, "too few casks") // 889272 at last count
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
        let pre = try Bundle.module.loadBundleResource(named: "fairapps-pre.json")
        let post = try Bundle.module.loadBundleResource(named: "fairapps-post.json")
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
        XCTAssertEqual(try cat2Post.json(), try cat2.json())
        _ = try await fmt.postUpdates(to: &cat2Post, with: diffs, twitterAuth: twitterAuth, newsLimit: 1, tweetLimit: 1)
        //XCTAssertNotEqual(try cat2Post.json(), try cat2.json())

        XCTAssertEqual("release-app.Cloud-Cuckoo-0.9.75", cat2Post.news?.first?.identifier)
        XCTAssertEqual("Updated Release: Cloud Cuckoo 0.9.75", cat2Post.news?.first?.title)
        XCTAssertEqual("Cloud Cuckoo version 0.9.75 has been updated from 0.9.74", cat2Post.news?.first?.caption)
        XCTAssertEqual("app.Cloud-Cuckoo", cat2Post.news?.first?.appID)
    }

    func testSignableJSum() throws {
        let key = "another test key"

        struct Demo : Encodable {
            let name: String
            let date: Date
        }

        let instance = Demo(name: "Abc", date: Date(timeIntervalSinceReferenceDate: 4321))

        struct SignableJSum<T: Encodable> : SigningContainer {
            let rawValue: T

            init(_ rawValue: T) {
                self.rawValue = rawValue
            }

            func encode(to encoder: Encoder) throws {
                try rawValue.encode(to: encoder)
            }
        }

        let signable = SignableJSum(instance)
        let sig = try signable.sign(key: key.utf8Data)
        XCTAssertEqual("lahFynjU/GPoeQA2xwqeiNE3i3nLVVvSvNhY0C0Ok1Q=", sig.base64EncodedString())

        do {
            // re-create the SignableJSum as a top-level type;
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
