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

 You should have received a copy of the GNU Affero General Public License
 along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */
import Swift
import Foundation
import FairCore
import FairApp
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

#if canImport(SwiftUI)
import SwiftUI
#endif

#if canImport(AppKit)
import AppKit
#endif

#if canImport(UIKit)
import UIKit
#endif

public protocol FairMsgCommand : AsyncParsableCommand {
    var msgOptions: MsgOptions { get set }
}

/// A specific command that can write messages (to stderr) and JSON encodable tool output (to stdout)
public protocol FairParsableCommand : FairMsgCommand {
    /// The structured output of this tool
    associatedtype Output
}

/// A command that will issue an asynchronous stream of output items
public protocol FairStructuredCommand : FairParsableCommand where Output : FairCommandOutput {
    /// Executes the command and results a streaming result of command responses
    func executeCommand() async throws -> AsyncThrowingStream<Output, Error>
}

public extension FairStructuredCommand {
    mutating func run() async throws {
        msgOptions.writeOutputStart()
        defer { msgOptions.writeOutputEnd() }
        var elements = try await self.executeCommand().makeAsyncIterator()
        if let first = try await elements.next() {
            try msgOptions.writeOutput(first)
            while let element = try await elements.next() {
                msgOptions.writeOutputSeparator()
                try msgOptions.writeOutput(element)
            }
        }
    }
}

public final class MessageBuffer {
    /// The list of messages
    public var messages: [(MessageKind, [Any?])] = []

    /// The output that is written
    public var output: [String] = []

    public init() {
    }
}

// Buffer contents are not really decidable, but the protocol is requires for `ParsableCommand` conformance
extension MessageBuffer : Decodable {
    public convenience init(from decoder: Decoder) throws {
        self.init()
    }
}

/// The type of message output
public enum MessageKind {
    case debug, info, warn, error

    public var name: String {
        switch self {
        case .debug: return "DEBUG"
        case .info: return "INFO"
        case .warn: return "WARN"
        case .error: return "ERROR"
        }
    }
}

public struct FairToolCommand : AsyncParsableCommand {
    public static let experimental = false
    public static var configuration = CommandConfiguration(commandName: "fairtool",
        abstract: "Manage an ecosystem of apps.",
        shouldDisplay: !experimental,
        subcommands: [
            AppCommand.self,
            FairCommand.self,
            BrewCommand.self,
            SourceCommand.self,
            VersionCommand.self, // `fairtool version` shows the current version
            ]
        )

    public init() {
    }

    public struct VersionCommand: FairParsableCommand {
        public static let experimental = false
        public typealias Output = Never
        public static var configuration = CommandConfiguration(commandName: "version",
                                                               abstract: "Show the fairtool version.",
                                                               shouldDisplay: !experimental)
        @OptionGroup public var msgOptions: MsgOptions

        public init() {
        }

        public mutating func run() async throws {
            let version = Bundle.fairCoreVersion
            msg(.info, "fairtool", version?.versionStringExtended)
        }
    }
}

public struct AppCommand : AsyncParsableCommand {
    public static let experimental = false
    public static var configuration = CommandConfiguration(commandName: "app",
        abstract: "App and ipa package tools.",
        shouldDisplay: !experimental,
        subcommands: [
            InfoCommand.self,
        ])

    public init() {
    }

    public struct InfoCommand: FairStructuredCommand {
        public static let experimental = false
        public static var configuration = CommandConfiguration(commandName: "info",
            abstract: "Output information about the specified app(s).",
            shouldDisplay: !experimental)

        public typealias Output = InfoItem

        public struct InfoItem : FairCommandOutput, Decodable {
            public var url: URL
            public var info: JSum
            public var entitlements: [JSum]?
        }

        @OptionGroup public var msgOptions: MsgOptions
        @OptionGroup public var downloadOptions: DownloadOptions

        @Argument(help: ArgumentHelp("path(s) or url(s) for app folders or ipa archives", valueName: "apps", visibility: .default))
        public var apps: [String]

        public init() {
        }

        public func executeCommand() -> AsyncThrowingStream<InfoItem, Error> {
            msg(.debug, "getting info from apps:", apps)
            return msgOptions.executeStream(apps) { app in
                return try await extractInfo(from: downloadOptions.acquire(path: app, onDownload: { url in
                    msg(.info, "downloading from URL:", url.absoluteString)
                    return url
                }))
            }
        }

        private func extractInfo(from: (from: URL, local: URL)) async throws -> InfoItem {
            msg(.info, "extracting info: \(from.from)")
            let (info, entitlements) = try AppBundleLoader.loadInfo(fromAppBundle: from.local)

            return try InfoItem(url: from.from, info: info.jsum(), entitlements: entitlements?.map({ try $0.jsum() }))
        }
    }
}

public struct SourceCommand : AsyncParsableCommand {
    public static let experimental = false
    public static var configuration = CommandConfiguration(commandName: "source",
        abstract: "AltStore source management commands.",
        shouldDisplay: !experimental,
        subcommands: [
            CreateCommand.self,
            VerifyCommand.self,
        ])

    public init() {
    }

    public struct CreateCommand: FairStructuredCommand {
        public static let experimental = false
        public typealias Output = AppCatalogItem

        public static var configuration = CommandConfiguration(commandName: "create",
            abstract: "Create a source from the specified .ipa or .zip.",
            shouldDisplay: !experimental)
        @OptionGroup public var msgOptions: MsgOptions

        @Argument(help: ArgumentHelp("path(s) or url(s) for app folders or ipa archives", valueName: "apps", visibility: .default))
        public var apps: [String]

        public init() { }

        public func executeCommand() async throws -> AsyncThrowingStream<Output, Error> {
            return msgOptions.executeStream(apps) { app in
                msg(.info, "creating app catalog:", app)
                let url = URL(fileOrScheme: app)
                return try await AppCatalogAPI.shared.catalogApp(url: url)
            }
        }
    }

    public struct VerifyCommand: FairStructuredCommand, AppCatalogVerificationAction {
        public static let experimental = false
        public typealias Output = AppCatalogVerifyResult

        public static var configuration = CommandConfiguration(commandName: "verify",
            abstract: "Verify the files in the specified catalog JSON.",
            shouldDisplay: !experimental)
        @OptionGroup public var msgOptions: MsgOptions
        @OptionGroup public var downloadOptions: DownloadOptions

        @Option(name: [.long], help: ArgumentHelp("verify only the specified bundle ID(s).", valueName: "id"))
        public var bundleID: Array<String> = []

        @Argument(help: ArgumentHelp("path or url for catalog", valueName: "path", visibility: .default))
        public var catalogs: [String]

        public init() { }

        public func executeCommand() async throws -> AsyncThrowingStream<Output, Error> {
            return msgOptions.executeStreamJoined(catalogs) { catalog in
                msg(.debug, "verifying catalog:", catalog)
                let url = URL(string: catalog)

                let catalogURL = url == nil || url?.scheme == nil ? URL(fileURLWithPath: catalog) : url!
                let (data, _) = try await URLSession.shared.fetch(request: URLRequest(url: catalogURL))
                let catalog = try AppCatalog.parse(jsonData: data)
                var apps = catalog.apps

                // if we are filtering by bundle IDs, find ones that match
                if !bundleID.isEmpty {
                    let bundleIDs = bundleID.set()
                    apps = apps.filter({ bundleIDs.contains($0.bundleIdentifier.rawValue) })
                }

                return apps.mapAsync({ try await verifyAppItem(app: $0, catalogURL: catalogURL) })
            }
        }

        public func addFailure(to failures: inout [AppCatalogVerifyFailure], app: AppCatalogItem, _ failure: AppCatalogVerifyFailure) {
            msg(.warn, "app verify failure for \(app.downloadURL.absoluteString): \(failure.type) \(failure.message)")
            failures.append(failure)
        }
    }
}

public extension URL {
    init(fileOrScheme: String) {
        guard let url = URL(string: fileOrScheme) else {
            self = URL(fileURLWithPath: fileOrScheme)
            return
        }

        if url.scheme == nil {
            self = URL(fileURLWithPath: fileOrScheme)
        } else {
            self = url
        }
    }
}
extension AppCatalogItem : FairCommandOutput {
}

/// A single `AppCatalogItem` entry from a catalog along with a list of validation failures
public struct AppCatalogVerifyResult : FairCommandOutput, Pure {
    public var app: AppCatalogItem
    public var failures: [AppCatalogVerifyFailure]?
}

//@available(*, deprecated, message: "move into central validation code")
public struct AppCatalogVerifyFailure : FairCommandOutput, Pure {
    /// The type of failure
    public var type: String

    /// A string describing the verification failure
    public var message: String
}

public final class AppCatalogAPI {
    public static let shared = AppCatalogAPI()

    private init() {
    }
}

public extension AppCatalogAPI {
    func catalogApp(url: URL) async throws -> AppCatalogItem {
        let localURL = url.isFileURL ? url : try await URLSession.shared.downloadFile(for: URLRequest(url: url)).localURL

        let (info, entitlements) = try AppBundleLoader.loadInfo(fromAppBundle: localURL)

        guard let bundleID = info.CFBundleIdentifier else {
            throw AppError("Missing CFBundleIdentifier for \(url.absoluteString)")
        }

        guard let bundleName = info.CFBundleDisplayName ?? info.CFBundleName else {
            throw AppError("Missing CFBundleDisplayName for \(url.absoluteString)")
        }
        
        var item = AppCatalogItem(name: bundleName, bundleIdentifier: BundleIdentifier(bundleID), downloadURL: url)
        item.version = info.CFBundleShortVersionString
        item.size = localURL.fileSize()
        item.developerName = info.rawValue["NSHumanReadableCopyright"] as? String

        item.subtitle = "SUBTITLE"
        item.localizedDescription = "DESCRIPTION" // maybe check for a README file in the .ipa?
        item.versionDescription = "VERSION DESCRIPTION" // maybe check for a CHANGELOG file in the .ipa

        // item.iconURL = … // if we were ambitious, we could try to extract the icon from the artifact and embed a data: url
        // item.tintColor = … // if we were ambitious, we could parse the assets and extract the tint color

        item.screenshotURLs = [] // maybe check for a folder in the .ipa?

        item.versionDate = localURL.creationDate

        var permissions: [AppPermission] = []
        for (key, value) in info.usageDescriptions {
            permissions.append(AppPermission(AppUsagePermission(usage: UsageDescriptionKeys(key), usageDescription: value)))
        }

        for backgroundMode in info.backgroundModes ?? [] {
            permissions.append(AppPermission(AppBackgroundModePermission(backgroundMode: AppBackgroundMode(backgroundMode), usageDescription: "USAGE DESCRIPTION")))
        }

        for (key, value) in entitlements?.first?.values ?? [:] {
            if ((value as? Bool) ?? true) != false {
                let entitlement = AppEntitlement(key)
                // we don't need to document harmless entitlements
                if !entitlement.categories.contains(.harmless) {
                    permissions.append(AppPermission(AppEntitlementPermission(entitlement: entitlement, usageDescription: "USAGE DESCRIPTION")))
                }
            }
        }

        item.permissions = permissions.isEmpty ? nil : permissions

        item.sha256 = try Data(contentsOf: localURL, options: .mappedIfSafe).sha256().hex() // without alwaysMapped or mappedIfSafe, memory seems to grow

        return item

        // return apps.mapAsync({ try await verifyAppItem(app: $0, catalogURL: catalogURL) })

    }

}

public protocol AppCatalogVerificationAction {
    func addFailure(to failures: inout [AppCatalogVerifyFailure], app: AppCatalogItem, _ failure: AppCatalogVerifyFailure)
}

public extension AppCatalogVerificationAction {
    func verifyAppItem(app: AppCatalogItem, catalogURL: URL?) async throws -> AppCatalogVerifyResult {
        var failures: [AppCatalogVerifyFailure] = []

        if app.sha256 == nil {
            addFailure(to: &failures, app: app, AppCatalogVerifyFailure(type: "missing_checksum", message: "App missing sha256 checksum property"))
        }
        if (app.size ?? 0) <= 0 {
            addFailure(to: &failures, app: app, AppCatalogVerifyFailure(type: "invalid_size", message: "App size property unset or invalid"))
        }

        var url = app.downloadURL
        if url.scheme == nil {
            // permit URLs relative to the catalog URL
            url = catalogURL?.deletingLastPathComponent().appendingPathComponent(url.path) ?? url
        }
        do {
            dbg("downloading app from URL:", url.absoluteString)
            let (file, _) = try await URLSession.shared.downloadFile(for: URLRequest(url: url))
            failures.append(contentsOf: await validateArtifact(app: app, file: file))
        } catch {
            addFailure(to: &failures, app: app, AppCatalogVerifyFailure(type: "download_failed", message: "Failed to download app from: \(url.absoluteString)"))
        }
        return AppCatalogVerifyResult(app: app, failures: failures.isEmpty ? nil : failures)
    }

    func validateArtifact(app: AppCatalogItem, file: URL) async -> [AppCatalogVerifyFailure] {
        var failures: [AppCatalogVerifyFailure] = []

        if !file.isFileURL || !FileManager.default.isReadableFile(atPath: file.path) {
            addFailure(to: &failures, app: app, AppCatalogVerifyFailure(type: "missing_file", message: "Download file \(file.path) does not exist for: \(app.downloadURL.absoluteString)"))
            return failures
        }

        if let size = app.size {
            if let fileSize = file.fileSize() {
                if size != fileSize {
                    addFailure(to: &failures, app: app, AppCatalogVerifyFailure(type: "size_mismatch", message: "Download size mismatch (\(size) vs. \(fileSize)) from: \(app.downloadURL.absoluteString)"))
                }
            }
        }

        if let sha256 = app.sha256,
            let fileData = try? Data(contentsOf: file) {
            let fileChecksum = fileData.sha256()
            if sha256 != fileChecksum.hex() {
                addFailure(to: &failures, app: app, AppCatalogVerifyFailure(type: "checksum_failed", message: "Checksum mismatch (\(sha256) vs. \(fileChecksum.hex())) from: \(app.downloadURL.absoluteString)"))
            }
        }

        func verifyInfoUsageDescriptions(_ info: Plist) {
            let usagePermissions: [String: AppUsagePermission] = (app.permissions ?? []).compactMap({ $0.infer()?.infer()?.infer() }).dictionary(keyedBy: \.usage.rawValue)

            for (permissionKey, permissionValue) in info.usageDescriptions {
                guard let catalogPermissionValue = usagePermissions[permissionKey] else {
                    addFailure(to: &failures, app: app, AppCatalogVerifyFailure(type: "usage_description_missing", message: "Missing a permission entry for usage key “\(permissionKey)”"))
                    continue
                }

                if catalogPermissionValue.usageDescription != permissionValue {
                    addFailure(to: &failures, app: app, AppCatalogVerifyFailure(type: "usage_description_mismatch", message: "The usage key “\(permissionKey)” defined in Info.plist does not have a matching value in the catalog metadata"))
                }
            }
        }

        func verifyBackgroundModes(_ info: Plist) {
            guard let backgroundModes = info.backgroundModes else {
                return // no background modes
            }

            let backgroundPermissions: [AppBackgroundMode: AppBackgroundModePermission] = (app.permissions ?? []).compactMap({ $0.infer()?.infer()?.infer() }).dictionary(keyedBy: \.backgroundMode)

            for backgroundMode in backgroundModes {
                if backgroundPermissions[AppBackgroundMode(backgroundMode)] == nil {
                    addFailure(to: &failures, app: app, AppCatalogVerifyFailure(type: "missing_background_mode", message: "Missing a permission entry for background mode “\(backgroundMode)”"))
                }
            }
        }

        func verifyEntitlements(_ entitlements: AppEntitlements) {
            let entitlementPermissions: [AppEntitlement: AppEntitlementPermission] = (app.permissions ?? []).compactMap({ $0.infer() }).dictionary(keyedBy: \.entitlement)

            for (entitlementKey, entitlementValue) in entitlements.values {
                if (entitlementValue as? Bool) == false {
                    continue // an entitlement value of `false` generally signifies that it is disabled, and so does not need a usage description
                }
                let entitlement = AppEntitlement(entitlementKey)
                if entitlement.categories.contains(.harmless) {
                    // skip over entitlements that are deemed "harmless" (e.g., application-identifier, com.apple.developer.team-identifier)
                    continue
                }
                if !entitlementPermissions.keys.contains(entitlement) {
                    addFailure(to: &failures, app: app, AppCatalogVerifyFailure(type: "missing_entitlement_permission", message: "Missing a permission entry for entitlement key “\(entitlementKey)”"))
                }
            }
        }

        do {
            let (info, entitlementss) = try AppBundleLoader.loadInfo(fromAppBundle: file)

            // ensure each *UsageDescription Info.plist property is also surfaced in the catalog metadata permissions
            verifyInfoUsageDescriptions(info)

            // ensure each of the background modes are documented
            verifyBackgroundModes(info)

            if entitlementss == nil {
                addFailure(to: &failures, app: app, AppCatalogVerifyFailure(type: "entitlements_missing", message: "No entitlements found in \(app.downloadURL.absoluteString)"))
            } else {
                for entitlements in entitlementss ?? [] {
                    verifyEntitlements(entitlements)
                }
            }
        } catch {
            addFailure(to: &failures, app: app, AppCatalogVerifyFailure(type: "bundle_load_failed", message: "Could not load bundle information for \(app.downloadURL.absoluteString): \(error)"))
        }

        return failures
    }

}


extension Plist {
    /// A map of all the "*UsageDescription*" properties that have string values
    var usageDescriptions: [String: String] {
        // gather the list of all "*UsageDescription" keys with string values
        // to ensure that they are all listed in the app's permissions
        self.rawValue
            .compactMap { key, value in
                (key as? String).flatMap { key in
                    (value as? String).flatMap { value in
                        (key, value)
                    }
                }
            }
            .filter { key, value in
                key.hasSuffix("UsageDescription")
            }
            .dictionary(keyedBy: \.0)
            .compactMapValues(\.1)
    }

    var backgroundModes: [String]? {
        (self.rawValue["UIBackgroundModes"] as? NSArray)?.compactMap({ $0 as? String })
    }
}

public struct FairCommand : AsyncParsableCommand {
    public static let experimental = false
    public static var configuration = CommandConfiguration(commandName: "fair",
        abstract: "Fairground app utility commands.",
        shouldDisplay: !experimental,
        subcommands: [
            ValidateCommand.self,
            CatalogCommand.self,
            MergeCommand.self,
            ]
        + Self.iconCommand
        + Self.fairsealCommand)

    private static var fairsealCommand: [AsyncParsableCommand.Type] {
        #if canImport(Compression)
        [FairsealCommand.self]
        #else
        []
        #endif
    }

    private static var iconCommand: [AsyncParsableCommand.Type] {
        #if canImport(SwiftUI)
        [IconCommand.self]
        #else
        []
        #endif
    }

    public init() {
    }

    public struct ValidateCommand: FairParsableCommand {
        public static let experimental = false
        public typealias Output = Never
        public static var configuration = CommandConfiguration(commandName: "validate",
            abstract: "Validate the project.",
            shouldDisplay: !experimental)
        @OptionGroup public var msgOptions: MsgOptions
        @OptionGroup public var hubOptions: HubOptions
        @OptionGroup public var validateOptions: ValidateOptions
        @OptionGroup public var orgOptions: OrgOptions
        @OptionGroup public var projectOptions: ProjectOptions

        public init() { }

        public mutating func run() async throws {
            msg(.info, "Validating project:", projectOptions.projectPathURL(path: "").path)
            //msg(.debug, "flags:", flags)

            let orgName = orgOptions.org

            // check whether we are validating as the upstream origin or
            let isFork = try orgName != hubOptions.fairHub().org
            //dbg("isFork", isFork, "hubFlag", hubFlag, "orgName", orgName, "fairHub().org", try! fairHub().org)

            /// Verifies that the given plist contains the specified value
            func check(_ plist: Plist, key: String, in expected: [String], empty: Bool = false, url: URL) throws {
                if plist.rawValue[key] == nil && empty == true {
                    return // permit empty values
                }

                guard let actual = plist.rawValue[key] as? NSObject else {
                    throw FairToolCommand.Errors.invalidPlistValue(key, expected, nil, url)
                }

                if !expected.isEmpty && !expected.map({ $0 as NSObject }).contains(actual) {
                    throw FairToolCommand.Errors.invalidPlistValue(key, expected, actual, url)
                }
            }

            /// Checks that the contents at the given path match the
            /// contents of the local resources at the same path
            /// - Parameters:
            ///   - path: the relative path of the resource
            ///   - partial: whether to validate partially based on the guard line
            ///   - warn: whether to warn rather than raise an error
            ///   - guardLine: the string to use to split the valiation string into prefix/suffix parts
            /// - Throws: a validation error
            @discardableResult func compareContents(of path: String, partial: Bool, warn: Bool = false, guardLine: String? = nil) throws -> Bool {
                msg(.debug, "  comparing \(partial ? "partial" : "exact") match:", path)
                let projectURL = projectOptions.projectPathURL(path: path)
                let projectSource = try String(contentsOf: projectURL, encoding: .utf8)

                // when this is not a fork (i.e., it is the root fairground), we always validate
                do {
                    try compareScaffold(project: projectSource, path: path, afterLine: !isFork ? nil : partial ? guardLine : nil)
                } catch {
                    if warn {
                        msg(.warn, "  failed \(partial ? "partial" : "exact") match:", path)
                        return false // we failed validation
                    } else {
                        throw error
                    }
                }
                return true
            }

            /// Loads the data for the project file at the given relative path
            func basePathURL(path: String) -> URL? {
                guard let basePathFlag = validateOptions.base else { return nil }
                return URL(fileURLWithPath: path, isDirectory: false, relativeTo: URL(fileURLWithPath: basePathFlag, isDirectory: true))
            }

            /// Validates that the given project source matches the given scaffold source
            func compareScaffold(project projectSource: String, path: String, afterLine guardLine: String? = nil) throws {
                msg(.debug, "checking:", path, "against base path:", validateOptions.base)
                guard let scaffoldURL = basePathURL(path: path) else {
                    throw CocoaError(.fileReadNoSuchFile)
                }

                let scaffoldSource = try String(contentsOf: scaffoldURL, encoding: .utf8)

                if scaffoldSource != projectSource {
                    // check for partial matches, which means that we only compare the header parts of the files
                    if let guardLine = guardLine {
                        let scaffoldParts = scaffoldSource.components(separatedBy: guardLine)
                        let projectParts = projectSource.components(separatedBy: guardLine)
                        if scaffoldParts.count < 2
                            || projectParts.count < 2
                            || scaffoldParts.last != projectParts.last {
                            throw FairToolCommand.Errors.invalidContents(scaffoldParts.last, projectParts.last, path, Self.firstDifferentLine(scaffoldParts.last ?? "", projectParts.last ?? ""))
                        }
                    } else {
                        throw FairToolCommand.Errors.invalidContents(scaffoldSource, projectSource, path, Self.firstDifferentLine(scaffoldSource, projectSource))
                    }
                }
            }

            // the generic term for the base folder is "App-Name"
            let appOrgName = !isFork ? "App-Name" : orgName

            // 1. Check Info.plist
            let infoProperties: Plist
            do {
                let path = "Info.plist"
                msg(.debug, "comparing metadata:", path)
                let infoPlistURL = projectOptions.projectPathURL(path: path)
                let plist_dict = try Plist(url: infoPlistURL)

                infoProperties = plist_dict

                func checkStr(key: InfoPlistKey, in strings: [String]) throws {
                    try check(plist_dict, key: key.plistKey, in: strings, url: infoPlistURL)
                }

                // check that the Info.plist contains the correct values for certain keys

                // ensure the Info.plist uses the correct constants
                try checkStr(key: InfoPlistKey.CFBundleName, in: ["$(PRODUCT_NAME)"])
                try checkStr(key: InfoPlistKey.CFBundleIdentifier, in: ["$(PRODUCT_BUNDLE_IDENTIFIER)"])
                try checkStr(key: InfoPlistKey.CFBundleExecutable, in: ["$(EXECUTABLE_NAME)"])
                try checkStr(key: InfoPlistKey.CFBundlePackageType, in: ["$(PRODUCT_BUNDLE_PACKAGE_TYPE)"])
                try checkStr(key: InfoPlistKey.CFBundleVersion, in: ["$(CURRENT_PROJECT_VERSION)"])
                try checkStr(key: InfoPlistKey.CFBundleShortVersionString, in: ["$(MARKETING_VERSION)"])
                try checkStr(key: InfoPlistKey.LSApplicationCategoryType, in: ["$(APP_CATEGORY)"])

                let licenseFlag = self.hubOptions.license
                if !licenseFlag.isEmpty {
                    try checkStr(key: InfoPlistKey.NSHumanReadableCopyright, in: licenseFlag)
                }
            }

            // 2. Check AppFairApp.xcconfig
            do {
                let appOrgNameSpace = appOrgName.dehyphenated()
                //let appID = "app." + appOrgName

                guard let appName = try projectOptions.buildSettings()?["PRODUCT_NAME"] else {
                    throw AppError("Missing PRODUCT_NAME in AppFairApp.xcconfig")
                }

                if appName != appOrgNameSpace {
                    throw AppError("Expectede PRODUCT_NAME in AppFairApp.xcconfig (“\(appName)”) to match the organization name (“\(appOrgNameSpace)”)")
                }

                guard let appVersion = try projectOptions.buildSettings()?["MARKETING_VERSION"] else {
                    throw AppError("Missing MARKETING_VERSION in AppFairApp.xcconfig")
                }

                let expectedIntegrationTitle = appName + " " + appVersion

                if let integrationTitle = self.validateOptions.integrationTitle,
                   integrationTitle != expectedIntegrationTitle {
                    throw FairToolCommand.Errors.invalidIntegrationTitle(integrationTitle, expectedIntegrationTitle)
                }

                //let buildVersion = try FairHub.AppBuildVersion(plistURL: infoPlistURL)
                //msg(.info, "Version", buildVersion.version.versionDescription, "(\(buildVersion.build))")
            }

            // 3. Check Sandbox.entitlements
            do {
                let path = "Sandbox.entitlements"
                msg(.debug, "comparing entitlements:", path)
                let entitlementsURL = projectOptions.projectPathURL(path: path)
                try orgOptions.checkEntitlements(entitlementsURL: entitlementsURL, infoProperties: infoProperties)
            }

            // 4. Check LICENSE.txt
            try compareContents(of: "LICENSE.txt", partial: false)

            // 5. Check Package.swift; we only warn, because the `merge` process will append the authoratative checks to the Package.swift file
            try compareContents(of: "Package.swift", partial: true, warn: true, guardLine: Self.packageValidationLine)

            // 6. Check Sources/
            try compareContents(of: "Sources/App/AppMain.swift", partial: false)
            try compareContents(of: "Sources/App/Bundle/LICENSE.txt", partial: false)

            // 7. Check Package.resolved if it exists and we've specified the hub to validate
            if let packageResolvedData = try? load(url: projectOptions.projectPathURL(path: "Package.resolved")) {
                msg(.debug, "validating Package.resolved")
                let packageResolved = try JSONDecoder().decode(ResolvedPackage.self, from: packageResolvedData)
                if let httpHost = URL(string: "https://\(hubOptions.hub)")?.host, let hubURL = URL(string: "https://\(httpHost)") {
                    // all dependencies must reside at the same fairground
                    // TODO: add include-hub/exclude-hub flags to permit cross-fairground dependency networks
                    // e.g., permit GitLab apps depending on projects in GitHub repos
                    let host = hubURL.deletingLastPathComponent().deletingLastPathComponent()
                    //dbg("verifying hub host:", host)
                    for pin in packageResolved.object.pins {
                        if !pin.repositoryURL.hasPrefix(host.absoluteString) && !pin.repositoryURL.hasPrefix("https://fair-ground.org/") {
                            throw FairToolCommand.Errors.badRepository(host.absoluteString, pin.repositoryURL)
                        }
                    }
                }
            }

            // also verify the hub if we have specified it in the arguments
            if hubOptions.hub != "" {
                try await verify(org: orgName, repo: appName, hub: hubOptions.fairHub())
            }

            msg(.info, "Successfully validated project:", projectOptions.projectPathURL(path: "").path)


            // validate the reference
            if let refFlag = validateOptions.ref {
                try await validateCommit(ref: refFlag, hub: hubOptions.fairHub())
            }
        }

        func verify(org: String, repo repoName: String, hub: FairHub) async throws {
            // when the app we are validating is the actual hub's root organization, use special validation rules (such as not requiring issues)
            msg(.info, "Validating App-Name:", org)

            let response = try await hub.request(FairHub.RepositoryQuery(owner: org, name: repoName)).get().data
            let organization = response.organization
            let repo = organization.repository

            msg(.debug, "  name:", organization.name)
            msg(.debug, "  isInOrganization:", repo.isInOrganization)
            msg(.debug, "  has_issues:", repo.hasIssuesEnabled)
            msg(.debug, "  discussion categories:", repo.discussionCategories.totalCount)

            let invalid = hub.validate(org: organization)
            if !invalid.isEmpty {
                throw FairHub.Errors.repoInvalid(invalid, org, repoName)
            }
        }
    }

    public struct MergeCommand: FairParsableCommand {
        public static let experimental = false
        public typealias Output = Never
        public static var configuration = CommandConfiguration(commandName: "merge",
            abstract: "Merge base fair-ground updates into the project.",
            shouldDisplay: !experimental)
        @OptionGroup public var msgOptions: MsgOptions
        @OptionGroup public var outputOptions: OutputOptions
        @OptionGroup public var projectOptions: ProjectOptions
        @OptionGroup public var validateOptions: ValidateOptions
        @OptionGroup public var orgOptions: OrgOptions
        @OptionGroup public var hubOptions: HubOptions

        public init() { }

        public mutating func run() async throws {
            msg(.info, "merge")

            if outputOptions.outputDirectoryFlag == projectOptions.projectPathFlag {
                throw FairToolCommand.Errors.sameOutputAndProjectPath(outputOptions.outputDirectoryFlag, projectOptions.projectPathFlag)
            }

            let outputURL = URL(fileURLWithPath: outputOptions.outputDirectoryFlag)
            let projectURL = URL(fileURLWithPath: projectOptions.projectPathFlag)
            if outputURL.absoluteString == projectURL.absoluteString {
                throw FairToolCommand.Errors.sameOutputAndProjectPath(outputOptions.outputDirectoryFlag, projectOptions.projectPathFlag)
            }

            // try await validate() // always validate first

            var vc = ValidateCommand()
            vc.msgOptions = self.msgOptions
            vc.hubOptions = self.hubOptions
            vc.validateOptions = self.validateOptions
            vc.orgOptions = self.orgOptions
            vc.projectOptions = self.projectOptions
            try await vc.run()

            /// Attempt to copy the path from the projectPath to the outputPath,
            /// thereby selectively merging parts of the PR with a customizable transform
            @discardableResult func pull(_ path: String, transform: ((Data) throws -> Data)? = nil) throws -> URL {
                msg(.info, "copying", path, "from", projectURL.path, "to", outputURL.path)
                let outputSrc = outputURL.appendingPathComponent(path)
                msg(.debug, "outputSrc", outputSrc)
                if fm.isDirectory(url: outputSrc) != nil {
                    try fm.trash(url: outputSrc) // clobber the existing path if it exists
                }

                let projectSrc = projectURL.appendingPathComponent(path)
                if let transform = transform { // only peform the transform if the closure is specified…
                    let sourceData = try Data(contentsOf: projectSrc)
                    try transform(sourceData).write(to: outputSrc) // transform the data and write it back out
                } else { // …otherwise simply copy the resource
                    try fm.copyItem(at: projectSrc, to: outputSrc)
                }

                return outputSrc
            }

            // if validation passes, we can copy up the output sources
            try pull("Sandbox.entitlements")

            // copy up the assets, sources, and other metadata
            try pull("AppFairApp.xcconfig")
            try pull("Info.plist")
            try pull("Assets.xcassets")
            try pull("README.md")
            try pull("Sources")
            try pull("Tests")

            try pull("Package.swift") { data in
                // We manually copy over the package validations so that we do not require that the user always keep the validations current

                // try compareContents(of: "Package.swift", partial: true, warn: true, guardLine: Self.packageValidationLine)

    //            guard let packageURL = self.basePathURL(path: "Package.swift") else {
    //                throw CocoaError(.fileReadNoSuchFile)
    //            }
    //
    //            let packageTemplate = try String(contentsOf: packageURL, encoding: .utf8).components(separatedBy: Self.packageValidationLine)
    //            if packageTemplate.count != 2 {
    //                throw CocoaError(.fileReadNoSuchFile)
    //            }
    //
    //            let str1 = String(data: data, encoding: .utf8) ?? ""
    //            let str2 = packageTemplate[1]
    //            return (str1 + str2).utf8Data

                return data
            }
        }
    }

    public struct CatalogCommand: FairParsableCommand {
        public static let experimental = false
        public typealias Output = Never
        public static var configuration = CommandConfiguration(commandName: "catalog",
            abstract: "Build the app catalog.",
            shouldDisplay: !experimental)
        @OptionGroup public var msgOptions: MsgOptions
        @OptionGroup public var hubOptions: HubOptions
        @OptionGroup public var catalogOptions: CatalogOptions
        @OptionGroup public var retryOptions: RetryOptions
        @OptionGroup public var outputOptions: OutputOptions

        public init() { }

        public mutating func run() async throws {
            try await self.catalog()
        }

        func catalog() async throws {
            msg(.info, "Catalog")
            try await retryOptions.retrying() {
                try await createCatalog()
            }
        }

        private func createCatalog() async throws {
            let hub = try hubOptions.fairHub()

            // whether to enforce a fairseal check before the app will be listed in the catalog
            let fairsealCheck = true // options.fairseal.contains("skip") != true

            let artifactTarget: ArtifactTarget
            switch catalogOptions.artifactExtension.first ?? "zip" {
            case "ipa":
                artifactTarget = ArtifactTarget(artifactType: "ipa", devices: ["iphone", "ipad"])
            case "zip", _:
                artifactTarget = ArtifactTarget(artifactType: "zip", devices: ["mac"])
            }

            // build the catalog filtering on specific artifact extensions
            let catalog = try await hub.buildCatalog(title: catalogOptions.catalogTitle, owner: appfairName, fairsealCheck: fairsealCheck, artifactTarget: artifactTarget, requestLimit: self.catalogOptions.requestLimit)

            msg(.debug, "releases:", catalog.apps.count) // , "valid:", catalog.count)
            for apprel in catalog.apps {
                msg(.debug, "  app:", apprel.name) // , "valid:", validate(apprel: apprel))
            }

            let json = try catalog.json(outputFormatting: [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes], dateEncodingStrategy: .iso8601, dataEncodingStrategy: .base64)
            try outputOptions.write(json)
            msg(.info, "Wrote catalog to", json.count.localizedByteCount())

            if let caskFolderFlag = catalogOptions.caskFolder {
                msg(.info, "Writing casks to: \(caskFolderFlag)")
                for app in catalog.apps {
                    try saveCask(app, to: caskFolderFlag, prereleaseSuffix: "-prerelease")
                }
            }

            if let indexFlag = catalogOptions.index {
                // #warning("TODO: outputOptions.write(data)")
                func output(_ data: Data, to path: String) throws {
                    if path == "-" {
                        print(data.utf8String!)
                    } else {
                        let file = URL(fileURLWithPath: path)
                        try data.write(to: file)
                    }
                }

                let md = try buildAppCatalogMarkdown(catalog: catalog)
                try output(md.utf8Data, to: indexFlag)
                msg(.info, "Wrote index to", indexFlag, md.count.localizedByteCount())
            }
        }
    }

    #if !os(Windows) // no ZipArchive yet
    public struct FairsealCommand: FairParsableCommand {
        public static let experimental = false
        public typealias Output = Never
        public static var configuration = CommandConfiguration(commandName: "fairseal",
            abstract: "Generates fairseal from trusted artifact.",
            shouldDisplay: !experimental)
        @OptionGroup public var msgOptions: MsgOptions
        @OptionGroup public var hubOptions: HubOptions
        @OptionGroup public var sealOptions: SealOptions
        @OptionGroup public var retryOptions: RetryOptions
        @OptionGroup public var iconOptions: IconOptions
        @OptionGroup public var orgOptions: OrgOptions
        @OptionGroup public var projectOptions: ProjectOptions

        public init() { }

        public mutating func run() async throws {
            msg(.info, "Fairseal")

            // When "--fairseal-match" is a number, we use it as a threshold beyond which differences in elements will fail the build
            let permittedDiffs = sealOptions.permittedDiffs

            guard let trustedArtifactFlag = sealOptions.trustedArtifact else {
                throw FairToolCommand.Errors.missingFlag("-trusted-artifact")
            }

            let trustedArtifactURL = URL(fileURLWithPath: trustedArtifactFlag)
            guard let trustedArchive = ZipArchive(url: trustedArtifactURL, accessMode: .read, preferredEncoding: .utf8) else {
                throw AppError("Error opening trusted archive: \(trustedArtifactURL.absoluteString)")
            }

            let untrustedArtifactLocalURL = try await fetchUntrustedArtifact()

            guard let untrustedArchive = ZipArchive(url: untrustedArtifactLocalURL, accessMode: .read, preferredEncoding: .utf8) else {
                throw AppError("Error opening untrusted archive: \(untrustedArtifactLocalURL.absoluteString)")
            }

            if untrustedArtifactLocalURL == trustedArtifactURL {
                throw AppError("Trusted and untrusted artifacts may not be the same")
            }

            // Load the zip entries, skipping over signature entries we are exlcuding from the comparison
            func readEntries(_ archive: ZipArchive) -> [ZipArchive.Entry] {
                Array(archive.makeIterator())
                    .filter { entry in
                        // these can be in either _CodeSignature or Contents
                        !entry.path.hasSuffix("/CodeSignature")
                        && !entry.path.hasSuffix("/CodeResources")
                        && !entry.path.hasSuffix("/CodeDirectory")
                        && !entry.path.hasSuffix("/CodeRequirements-1")
                    }
            }

            let trustedEntries = readEntries(trustedArchive)
            let untrustedEntries = readEntries(untrustedArchive)

            if trustedEntries.count != untrustedEntries.count {
                throw AppError("Trusted and untrusted artifact content counts do not match (\(trustedEntries.count) vs. \(untrustedEntries.count))")
            }

            let rootPaths = Set(trustedEntries.compactMap({
                $0.path.split(separator: "/")
                    .drop(while: { $0 == "Payload" }) // .ipa archives store Payload/App Name.app/Info.plist
                    .first
            }))

            guard rootPaths.count == 1, let rootPath = rootPaths.first, rootPath.hasSuffix(Self.appSuffix) else {
                throw AppError("Invalid root path in archive: \(rootPaths)")
            }

            let appName = rootPath.dropLast(Self.appSuffix.count)

            // TODO: we should instead check the `CFBundleExecutable` key for the executable name

            let macOSExecutable = "\(appName).app/Contents/MacOS/\(appName)" // macOS: e.g., Photo Box.app/Contents/MacOS/Photo Box
            let macOSInfo = "\(appName).app/Contents/Info.plist" // macOS: e.g., Photo Box.app/Contents/MacOS/Photo Box

            let iOSExecutable = "Payload/\(appName).app/\(appName)" // iOS: e.g., Photo Box.app/Photo Box
            let iOSInfo = "Payload/\(appName).app/Info.plist"

            let executablePaths = [
                macOSExecutable,
                iOSExecutable,
            ]

            var infoPlist: Plist? = nil

            var coreSize: UInt64 = 0 // the size of the executable itself

            for (trustedEntry, untrustedEntry) in zip(trustedEntries, untrustedEntries) {
                if trustedEntry.path != untrustedEntry.path {
                    throw AppError("Trusted and untrusted artifact content paths do not match: \(trustedEntry.path) vs. \(untrustedEntry.path)")
                }

                let entryIsMainBinary = executablePaths.contains(trustedEntry.path)
                let entryIsInfo = trustedEntry.path == macOSInfo || trustedEntry.path == iOSInfo

                if entryIsMainBinary {
                    coreSize = trustedEntry.uncompressedSize // the "core" size is just the size of the main binary itself
                }

                if entryIsInfo {
                    // parse the compiled Info.plist for processing
                    infoPlist = try withErrorContext("parsing plist entry: \(trustedEntry.path)") {
                        try Plist(data: trustedArchive.extractData(from: trustedEntry))
                    }
                }

                if trustedEntry.checksum == untrustedEntry.checksum {
                    continue
                }

                // checksum mismatch: check the actual binary contents so we can summarize the differences
                msg(.info, "checking mismached entry: \(trustedEntry.path)")

                let pathParts = trustedEntry.path.split(separator: "/")

                if pathParts.last == "Assets.car" {
                    // assets are not deterministically compiled; we let these pass
                    continue
                }

                if trustedEntry.path.hasSuffix(".nib") {
                    // nibs sometimes get compiled differently as well
                    continue
                }

                if pathParts.dropLast().last?.hasSuffix(".storyboardc") == true {
                    // Storyboard files sometimes get compiled differently (e.g., differences in the date in Info.plist)
                    continue
                }


                //msg(.debug, "checking", trustedEntry.path)

                var trustedPayload = try trustedArchive.extractData(from: trustedEntry)
                var untrustedPayload = try untrustedArchive.extractData(from: untrustedEntry)

                // handles the dynamic library at: Payload/App Name.app/Frameworks/App.framework/App
                let isExecutable = trustedPayload.starts(with: [0xfe, 0xed, 0xfa, 0xce]) // 32-bit magic
                || trustedPayload.starts(with: [0xfe, 0xed, 0xfa, 0xcf]) // 64-bit magic
                || trustedPayload.starts(with: [0xca, 0xfe, 0xba, 0xbe]) // universal magic
                || trustedPayload.starts(with: [0xcf, 0xfa, 0xed, 0xfe, 0x0c, 0x00, 0x00, 0x01]) // dylib

                let isAppBinary = entryIsMainBinary || isExecutable

                // the code signature is embedded in executables, but since since the trusted and un-trusted versions can be signed with different certificates (ad-hoc or otherwise), the code signature section in the compiled binary will be different; ideally we would figure out how to strip the signature from the data block itself, but for now just save to a temporary location, strip the signature using `codesign --remove-signature`, and then check the binaries again
#if os(macOS) // we can only launch `codesign` on macOS
                // TODO: handle plug-ins like: Lottie Motion.app/Contents/PlugIns/Lottie Motion Quicklook.appex/Contents/MacOS/Lottie Motion Quicklook
                if isAppBinary && trustedPayload != untrustedPayload {
                    func stripSignature(from data: Data) throws -> Data {
                        let tmpFile = URL.tmpdir.appendingPathComponent("fairbinary-" + UUID().uuidString)
                        try data.write(to: tmpFile)
                        try Process.codesignStrip(url: tmpFile)
                        return try Data(contentsOf: tmpFile) // read it back in
                    }

                    msg(.info, "stripping code signatures: \(trustedEntry.path)")
                    trustedPayload = try stripSignature(from: trustedPayload)
                    untrustedPayload = try stripSignature(from: untrustedPayload)
                }
#endif

                // the signature can change the binary size
                //            if trustedEntry.uncompressedSize != untrustedEntry.uncompressedSize {
                //                throw AppError("Trusted and untrusted artifact content size mismatch at \(trustedEntry.path): \(trustedEntry.uncompressedSize) vs. \(untrustedEntry.uncompressedSize)")
                //            }

                if trustedPayload != untrustedPayload {
                    msg(.info, " scanning payload differences")
                    let diff: CollectionDifference<UInt8> = trustedPayload.difference(from: untrustedPayload) // .inferringMoves()

                    msg(.info, " checking mismached entry: \(trustedEntry.path) SHA256 trusted: \(trustedPayload.sha256().hex()) untrusted: \(untrustedPayload.sha256().hex()) differences: \(diff.count)")
                    func offsets<T>(in changeSet: [CollectionDifference<T>.Change]) -> IndexSet {
                        IndexSet(changeSet.map({
                            switch $0 {
                            case .insert(let offset, _, _): return offset
                            case .remove(let offset, _, _): return offset
                            }
                        }))
                    }

                    let insertionRanges = offsets(in: diff.insertions)
                    let insertionRangeDesc = insertionRanges
                        .rangeView
                        .prefix(10)
                        .map({ $0.description })

                    let removalRanges = offsets(in: diff.removals)
                    let removalRangeDesc = removalRanges
                        .rangeView
                        .prefix(10)
                        .map({ $0.description })

                    let totalChanges = diff.insertions.count + diff.removals.count
                    if totalChanges > 0 {
                        let error = AppError("Trusted and untrusted artifact content mismatch at \(trustedEntry.path): \(diff.insertions.count) insertions in \(insertionRanges.rangeView.count) ranges \(insertionRangeDesc) and \(diff.removals.count) removals in \(removalRanges.rangeView.count) ranges \(removalRangeDesc) and totalChanges \(totalChanges) beyond permitted threshold: \(permittedDiffs ?? 0)")

                        if isAppBinary {
                            if let permittedDiffs = permittedDiffs, totalChanges < permittedDiffs {
                                // when we are analyzing the app binary itself we need to tolerate some minor differences that seem to result from non-reproducible builds
                                msg(.info, "tolerating \(totalChanges) differences for: \(error)")
                            } else {
                                throw error
                            }
                        } else {
                            throw error
                        }
                    }
                }
            }

            var assets: [FairSeal.Asset] = []

            // publish the hash for the artifact binary URL
            if let artifactURLFlag = self.sealOptions.artifactURL, let artifactURL = URL(string: artifactURLFlag) {

                // the staging folder contains raw assets (e.g., screenshots and README.md) that are included in a release
                for stagingFolder in sealOptions.artifactStaging {
                    let artifactAssets = try FileManager.default.contentsOfDirectory(at: projectOptions.projectPathURL(path: stagingFolder), includingPropertiesForKeys: [.fileSizeKey], options: [.skipsPackageDescendants])
                        .sorting(by: \.lastPathComponent)
                    msg(.info, "scanning assets:", artifactAssets.map(\.relativePath))

                    for localURL in artifactAssets {
                        guard let assetSize = localURL.fileSize() else {
                            continue
                        }

                        // the published asset URL is the name of the local path relative to the download URL for the artifact
                        let assetURL = artifactURL.deletingLastPathComponent().appendingPathComponent(localURL.lastPathComponent, isDirectory: false)
                        if assetURL.lastPathComponent == artifactURL.lastPathComponent {
                            let assetHash = try Data(contentsOf: untrustedArtifactLocalURL, options: .mappedIfSafe).sha256().hex()
                            // the primary asset uses the special hash handling
                            msg(.info, "hash for artifact:", assetURL.lastPathComponent, assetHash)
                            assets.append(FairSeal.Asset(url: assetURL, size: assetSize, sha256: assetHash))
                        } else {
                            let assetHash = try Data(contentsOf: localURL, options: .mappedIfSafe).sha256().hex()
                            // all other artifacts are hashed directly from their local counterparts
                            assets.append(FairSeal.Asset(url: assetURL, size: assetSize, sha256: assetHash))
                        }
                    }
                }
            }

            guard let plist = infoPlist else {
                throw AppError("Missing property list")
            }

            let entitlementsURL = projectOptions.projectPathURL(path: "Sandbox.entitlements")
            let permissions = try orgOptions.checkEntitlements(entitlementsURL: entitlementsURL, infoProperties: plist)
            for permission in permissions {
                msg(.info, "entitlement:", permission.type.rawValue, "usage:", permission.usageDescription)
            }

            let tint = try? parseTintColor()
            let fairseal = FairSeal(assets: assets, permissions: permissions.map(AppPermission.init), coreSize: Int(coreSize), tint: tint)

            msg(.info, "generated fairseal:", fairseal.debugJSON.count.localizedByteCount())

            // if we specify a hub, then attempt to post the fairseal to the first open PR for that project
            msg(.info, "posting fairseal for artifact:", assets.first?.url.absoluteString, "JSON:", fairseal.debugJSON)
            if let postURL = try await hubOptions.fairHub().postFairseal(fairseal) {
                msg(.info, "posted fairseal to:", postURL.absoluteString)
            } else {
                msg(.warn, "unable to post fairseal")
            }

        }

        func parseTintColor() throws -> String? {
            // first check the `AppFairApp.xcconfig` file for customization
            if let tint = try projectOptions.buildSettings()?["ICON_TINT"] {
                if let hexColor = HexColor(hexString: tint) {
                    return hexColor.colorString(hashPrefix: false)
                }
            }

            // fall back to the asset catalog, if any
            if let accentColorFlag = iconOptions.accentColor {
                let accentColorPath = projectOptions.projectPathURL(path: accentColorFlag)
                if let rgba = try parseColorContents(url: accentColorPath) {
                    let tintColor = String(format:"%02X%02X%02X", Int(rgba.r * 255), Int(rgba.g * 255), Int(rgba.b * 255))
                    dbg("parsed tint color: \(rgba): \(tintColor)")
                    return tintColor
                }
            }

            return nil
        }

        private func fetchUntrustedArtifact() async throws -> URL {
            // if we specified the artifact as a local file, just use it directly
            if let untrustedArtifactFlag = sealOptions.untrustedArtifact {
                return URL(fileURLWithPath: untrustedArtifactFlag)
            }

            guard let artifactURLFlag = self.sealOptions.artifactURL,
                let artifactURL = URL(string: artifactURLFlag) else {
                throw FairToolCommand.Errors.missingFlag("-artifact-url")
            }

            return try await fetchArtifact(url: artifactURL)
        }

        private func fetchArtifact(url artifactURL: URL) async throws -> URL {
            try await retryOptions.retrying() {
                var request = URLRequest(url: artifactURL)
                request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
                let (downloadedURL, response) = try URLSession.shared.downloadSync(request)
                if let response = response as? HTTPURLResponse,
                   (200..<300).contains(response.statusCode) { // e.g., 404
                    msg(.info, "downloaded:", artifactURL.absoluteString, "to:", downloadedURL, "response:", response)
                    return downloadedURL
                } else {
                    msg(.info, "failed to download:", artifactURL.absoluteString, "code:", (response as? HTTPURLResponse)?.statusCode)
                    throw AppError("Unable to download: \(artifactURL.absoluteString) code: \((response as? HTTPURLResponse)?.statusCode ?? 0)")
                }
            }
        }

    }
    #endif

    #if canImport(SwiftUI)
    public struct IconCommand: FairParsableCommand {
        public static let experimental = false
        public typealias Output = Never
        public static var configuration = CommandConfiguration(commandName: "icon",
            abstract: "Create an icon for the given project.",
            shouldDisplay: !experimental)
        @OptionGroup public var iconOptions: IconOptions
        @OptionGroup public var msgOptions: MsgOptions
        @OptionGroup public var orgOptions: OrgOptions
        @OptionGroup public var projectOptions: ProjectOptions

        public init() { }

        public mutating func run() async throws {
            try await runOnMain()
        }

        @MainActor mutating func runOnMain() async throws {
            msg(.info, "icon")

            assert(Thread.isMainThread, "SwiftUI can only be used from main thread")

            guard let appIconPath = iconOptions.appIcon else {
                throw FairToolCommand.Errors.missingFlag("-app-icon")
            }

            let appIconURL = projectOptions.projectPathURL(path: appIconPath)

            // load the specified `Assets.xcassets/AppIcon.appiconset/Contents.json` and fill in any of the essential missing icons
            let iconSet = try AppIconSet(json: Data(contentsOf: appIconURL))

            let appName = try orgOptions.appNameSpace()
            let iconColor = try parseTintIconColor()

            var symbolNames = iconOptions.iconSymbol
            if let symbolName = try projectOptions.buildSettings()?["ICON_SYMBOL"] {
                symbolNames.append(symbolName)
            }

            // the minimal required icons for macOS + iOS
            let icons = [
                iconSet.images(idiom: "mac", scale: "2x", size: "16x16"),
                iconSet.images(idiom: "mac", scale: "2x", size: "128x128"),
                iconSet.images(idiom: "mac", scale: "2x", size: "256x256"),
                iconSet.images(idiom: "mac", scale: "2x", size: "512x512"),
                iconSet.images(idiom: "iphone", scale: "2x", size: "60x60"),
                iconSet.images(idiom: "iphone", scale: "3x", size: "60x60"),
                iconSet.images(idiom: "ipad", scale: "1x", size: "76x76"),
                iconSet.images(idiom: "ipad", scale: "2x", size: "76x76"),
                iconSet.images(idiom: "ipad", scale: "2x", size: "83.5x83.5"),
                iconSet.images(idiom: "ios-marketing", scale: "1x", size: "1024x1024"),
            ].joined()

            var appIconSet = iconSet

            for imageSet in icons {
                let iconView = FairIconView(appName, subtitle: nil, paths: symbolNames, iconColor: iconColor, cornerRadiusFactor: imageSet.idiom == "ios-marketing" ? 0.0 : nil) // App Store icon must not have any transparency

                if imageSet.filename != nil {
                    continue // skip any elements that have a file path specified already
                }

                // an un-specified filename will be filled in with the default app icon

                let iconFile = URL(fileURLWithPath: "appicon-" + imageSet.standardPath + ".png", relativeTo: appIconURL)

                let assetName = try AssetName(string: iconFile.lastPathComponent)

                let size = max(assetName.width, assetName.height)
                var scale = Double(assetName.scale ?? 1)
                #if os(macOS)
                if let screen = NSScreen.main, screen.backingScaleFactor > 0.0 {
                    // there should be a better way to do this, but rendering a view seems to use the main screens scale, which on the build host seems to be 1.0 and on a macBook is 2.0; we need to alter the scale in order to generate the correctly-sized images on each host
                    scale /= screen.backingScaleFactor
                }
                #endif

                let span = CGFloat(size) * CGFloat(scale) // default content scale
                let bounds = CGRect(origin: CGPoint(x: -span/2, y: -span/2), size: CGSize(width: CGFloat(span), height: CGFloat(span)))
                let iconInset = imageSet.idiom?.hasPrefix("mac") == true ? 0.10 : 0.00 // mac icons are inset by 10%

                guard let pngData = iconView.padding(span * iconInset).png(bounds: bounds), pngData.count > 1024 else {
                    throw AppError("Unable to generate PNG data")
                }
                try pngData.write(to: iconFile)
                msg(.info, "output icon to: \(iconFile.path)")

                appIconSet.images = appIconSet.images.map { image in
                    var img = image
                    if img.idiom == imageSet.idiom
                        && img.size == imageSet.size
                        && img.scale == imageSet.scale
                        && img.role == imageSet.role
                        && img.subtype == imageSet.subtype
                        && img.filename == nil {
                        img.filename = iconFile.lastPathComponent // update the image to have the given file name
                    }
                    return img
                }
            }

            if appIconSet != iconSet {
                // when we have changed the icon set from the origional, save it back to the asset catalog
                msg(.info, "saving changed assets to: \(appIconURL.path)")
                try appIconSet.json(outputFormatting: [.prettyPrinted, .withoutEscapingSlashes, .sortedKeys]).write(to: appIconURL)
            }
        }

        func parseTintIconColor() throws -> Color? {
            if let tint = try projectOptions.buildSettings()?["ICON_TINT"] {
                if let hexColor = HexColor(hexString: tint) {
                    return hexColor.sRGBColor()
                }
            }

            // fall back to the asset catalog, if specified
            if let accentColorFlag = iconOptions.accentColor {
                let accentColorPath = projectOptions.projectPathURL(path: accentColorFlag)
                if let rgba = try parseColorContents(url: accentColorPath) {
                    return Color(.sRGB, red: rgba.r, green: rgba.g, blue: rgba.b, opacity: rgba.a)
                }
            }

            return nil
        }

    }
    #endif


    public struct CatalogOptions: ParsableArguments {
        @Option(name: [.long], help: ArgumentHelp("title of the generated catalog.", valueName: "title"))
        public var catalogTitle: String = "App Sources"

        @Option(name: [.long], help: ArgumentHelp("catalog index markdown."))
        public var index: String?

        @Option(name: [.long], help: ArgumentHelp("the output folder for the app casks.", valueName: "dir"))
        public var caskFolder: String?

        @Option(name: [.long], help: ArgumentHelp("the artifact extensions."))
        public var artifactExtension: [String] = []

        @Option(name: [.long], help: ArgumentHelp("maximum number of Hub API requests per session."))
        public var requestLimit: Int?

        public init() { }
    }

    public struct ValidateOptions: ParsableArguments {
        @Option(name: [.long], help: ArgumentHelp("the IR title"))
        public var integrationTitle: String?

        @Option(name: [.long, .customShort("b")], help: ArgumentHelp("the base path."))
        public var base: String?

        @Option(name: [.long], help: ArgumentHelp("commit ref to validate."))
        public var ref: String?

        public init() { }
    }

    public struct SealOptions: ParsableArguments {
        @Option(name: [.long], help: ArgumentHelp("resource for the artifact that will be generated."))
        public var artifactURL: String?

        @Option(name: [.long], help: ArgumentHelp("the artifact created in a trusted environment."))
        public var trustedArtifact: String?

        @Option(name: [.long], help: ArgumentHelp("the artifact created in an untrusted environment."))
        public var untrustedArtifact: String?

        @Option(name: [.long], help: ArgumentHelp("the artifact staging folder."))
        public var artifactStaging: [String] = []

        @Option(name: [.long], help: ArgumentHelp("the number of diffs for a build to be reproducible.", valueName: "count"))
        public var permittedDiffs: Int?

        public init() { }
    }

    public struct IconOptions: ParsableArguments {
        @Option(name: [.long], help: ArgumentHelp("path to appiconset/Contents.json."))
        public var appIcon: String?

        @Option(name: [.long], help: ArgumentHelp("path or symbol name to place in the icon.", valueName: "symbol"))
        public var iconSymbol: [String] = []

        @Option(name: [.long], help: ArgumentHelp("the accent color file.", valueName: "color"))
        public var accentColor: String?

        public init() { }
    }

    public struct ProjectOptions: ParsableArguments {
        @Option(name: [.long, .customShort("p")], help: ArgumentHelp("the project to use."))
        public var project: String?

        @Option(name: [.long], help: ArgumentHelp("the path to the xcconfig containing metadata.", valueName: "xc"))
        public var fairProperties: String?

        public init() { }

        /// The flag for the project folder
        public var projectPathFlag: String {
            self.project ?? FileManager.default.currentDirectoryPath
        }

        /// Loads the data for the project file at the given relative path
        func projectPathURL(path: String) -> URL {
            URL(fileURLWithPath: path, isDirectory: false, relativeTo: URL(fileURLWithPath: projectPathFlag, isDirectory: true))
        }

        /// If the `--fair-properties` flag was specified, tries to parse the build settings
        func buildSettings() throws -> BuildSettings? {
            guard let fairProperties = self.fairProperties else { return nil }
            return try BuildSettings(url: projectPathURL(path: fairProperties))
        }
    }

    public struct OrgOptions: ParsableArguments {
        @Option(name: [.long, .customShort("g")], help: ArgumentHelp("the repository to use."))
        public var org: String

        public init() { }

        var isCatalogApp: Bool {
            self.org == Bundle.catalogBrowserAppOrg
        }

        /// Returns `App Name`
        func appNameSpace() throws -> String {
            self.org.dehyphenated()
        }

        /// Loads all the entitlements and matches them to corresponding UsageDescription entires in the app's Info.plist file.
        @discardableResult
        func checkEntitlements(entitlementsURL: URL, infoProperties: Plist) throws -> Array<AppLegacyPermission> {
            let entitlements_dict = try Plist(url: entitlementsURL)

            if entitlements_dict.rawValue[AppEntitlement.app_sandbox.entitlementKey] as? NSNumber != true {
                // despite having LSFileQuarantineEnabled=false and `com.apple.security.files.user-selected.executable`, apps that the catalog browser app writes cannot be launched; the only solution seems to be to disable sandboxing, which is a pity…
                if !self.isCatalogApp {
                    throw FairToolCommand.Errors.sandboxRequired
                }
            }

            var permissions: [AppLegacyPermission] = []

            // Check that the given entitlement is permitted, and that entitlements that require a usage description are specified in the app's Info.plist `FairUsage` dictionary
            func check(_ entitlement: AppEntitlement) throws -> (usage: String, value: Any)? {
                guard let entitlementValue = entitlements_dict.rawValue[entitlement.entitlementKey] else {
                    return nil // no entitlement set
                }

                if (entitlementValue as? NSNumber) == false {
                    return nil // false entitlements are treated as unset
                }

                // a nil usage description means the property is explicitely forbidden (e.g., "files-all")
                guard let props = entitlement.usageDescriptionProperties else {
                    throw FairToolCommand.Errors.forbiddenEntitlement(entitlement.entitlementKey)
                }

                // on the other hand, an empty array means we don't require any explanation for the entitlemnent's usage (e.g., enabling JIT)
                if props.isEmpty {
                    return nil
                }

                guard let usageDescription = props.compactMap({
                    // the usage is contained in the `FairUsage` dictionary of the Info.plist; the key is simply the entitlement name
                    infoProperties.FairUsage?[$0] as? String

                    // TODO: perhaps also permit the sub-set of top-level usage description properties like "NSDesktopFolderUsageDescription", "NSDocumentsFolderUsageDescription", and "NSLocalNetworkUsageDescription"
                    // ?? infoProperties[$0] as? String
                }).first else {
                    throw FairToolCommand.Errors.missingUsageDescription(entitlement)
                }

                if usageDescription.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    throw FairToolCommand.Errors.missingUsageDescription(entitlement)
                }

                return (usageDescription, entitlementValue)
            }

            for entitlement in AppEntitlement.allCases {
                if let (usage, _) = try check(entitlement) {
                    permissions.append(AppLegacyPermission(type: entitlement, usageDescription: usage))
                }
            }

            return permissions
        }
    }
}

public struct BrewCommand : AsyncParsableCommand {
    public static let experimental = true
    public static var configuration = CommandConfiguration(commandName: "brew",
        abstract: "Homebrew appcask configuration commands.",
        shouldDisplay: !experimental,
        subcommands: [
            AppCasksCommand.self,
        ])

    public init() {
    }

    public struct AppCasksCommand: FairParsableCommand {
        public static let experimental = false
        public typealias Output = Never
        public static var configuration = CommandConfiguration(commandName: "appcasks",
            abstract: "Build the enhanced appcasks catalog.",
            shouldDisplay: !experimental)
        @OptionGroup public var msgOptions: MsgOptions
        @OptionGroup public var hubOptions: HubOptions
        @OptionGroup public var casksOptions: CasksOptions
        @OptionGroup public var retryOptions: RetryOptions
        @OptionGroup public var outputOptions: OutputOptions

        public init() { }

        public mutating func run() async throws {
            msg(.info, "AppCasks")
            try await retryOptions.retrying() {
                try await createAppCasks()
            }
        }

        private func createAppCasks() async throws {
            let hub = try hubOptions.fairHub()

            // build the catalog filtering on specific artifact extensions
            let catalog = try await hub.buildAppCasks(boostFactor: casksOptions.boostFactor ?? 100_000)

            msg(.debug, "appcasks:", catalog.apps.count) // , "valid:", catalog.count)
            for apprel in catalog.apps {
                msg(.debug, "  app:", apprel.name) // , "valid:", validate(apprel: apprel))
            }

            let json = try catalog.json(outputFormatting: [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes], dateEncodingStrategy: .iso8601, dataEncodingStrategy: .base64)
            try outputOptions.write(json)
            msg(.info, "Wrote appcasks to", outputOptions.output, json.count.localizedByteCount())
        }
    }

    public struct CasksOptions: ParsableArguments {
        @Option(name: [.long], help: ArgumentHelp("multiplier for how much metadata ranking boost."))
        public var boostFactor: Int64?

        public init() { }
    }
}

public protocol FairCommandOutput : Encodable {
    // TODO: an output form of this instance that displays plain text information for when people don't want to see JSON output
    //func outputText() throws -> [String]
}

extension Array : FairCommandOutput where Element : FairCommandOutput {
}

extension AppCatalog : FairCommandOutput {
}

public struct OutputOptions: ParsableArguments {
    @Option(name: [.long, .customShort("o")], help: ArgumentHelp("the output path."))
    public var output: String = "-"

    public init() { }

    /// The flag for the output folder or the current director
    var outputDirectoryFlag: String {
        self.output
    }

    func write(_ data: Data) throws {
        if output == "-" {
            print(data.utf8String ?? "")
        } else {
            try data.write(to: URL(fileURLWithPath: output))
        }
    }
}

public struct MsgOptions: ParsableArguments {
    @Flag(name: [.long, .customShort("v")], help: ArgumentHelp("whether to display verbose messages."))
    public var verbose: Bool = false

    @Flag(name: [.long, .customShort("q")], help: ArgumentHelp("whether to be suppress output."))
    public var quiet: Bool = false

    @Flag(name: [.long], help: ArgumentHelp("exclude root JSON array from output."))
    public var promoteJSON: Bool = false

    public var messages: MessageBuffer? = nil

    public init() {
    }

    /// Write the given message to standard out, unless the output buffer is set, in which case output is sent to the buffer
    public func write(_ value: String) {
        if let messages = messages {
            messages.output.append(value)
        } else {
            print(value)
        }
    }

    /// The output that comes at the beginning of a sequence of elements; an opening bracket, for JSON arrays
    public func writeOutputStart() {
        if !promoteJSON { write("[") }
    }

    /// The output that comes at the end of a sequence of elements; a closing bracket, for JSON arrays
    public func writeOutputEnd() {
        if !promoteJSON { write("]") }
    }

    /// The output that separates elements; a comma, for JSON arrays
    public func writeOutputSeparator() {
        if !promoteJSON { write(",") }
    }

    func writeOutput<T: FairCommandOutput>(_ item: T) throws {
        try write(item.json(outputFormatting: [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes], dateEncodingStrategy: .iso8601).utf8String ?? "")
    }

    /// Iterates over each of the given arguments and executes the block against the arg, outputting the JSON result as it goes.
    fileprivate func executeStream<T, U: FairCommandOutput>(_ arguments: [T], block: @escaping (T) async throws -> U) -> AsyncThrowingStream<U, Error> {
        arguments.mapAsync(block)
    }

    /// Iterates over each of the given arguments and executes the block against the arg, outputting the result as it goes.
    fileprivate func executeStreamJoined<T, U: FairCommandOutput>(_ arguments: [T], block: @escaping (T) async throws -> AsyncThrowingStream<U, Error>) -> AsyncThrowingStream<U, Error> {
        return AsyncThrowingStream<U, Error>(U.self) { c in
            Task {
                do {
                    for arg in arguments {
                        for try await item in try await block(arg) {
                            c.yield(item)
                        }
                    }
                    c.finish()
                } catch {
                    c.finish(throwing: error)
                }
            }
        }
    }
}

public struct HubOptions: ParsableArguments {
    @Option(name: [.long, .customShort("h")], help: ArgumentHelp("the hub to use.", valueName: "host/org"))
    public var hub: String

    @Option(name: [.long, .customShort("k")], help: ArgumentHelp("the token used for the hub's authentication."))
    public var token: String?

    @Option(name: [.long], help: ArgumentHelp("name of the login that issues the fairseal.", valueName: "usr"))
    public var fairsealIssuer: String?

    @Option(name: [.long], help: ArgumentHelp("allow patterns for integrate PR names.", valueName: "pattern"))
    public var allowName: [String] = []

    @Option(name: [.long], help: ArgumentHelp("disallow patterns for integrate PR names.", valueName: "pattern"))
    public var denyName: [String] = []

    @Option(name: [.long], help: ArgumentHelp("allow patterns for integrate PR users", valueName: "pattern"))
    public var allowFrom: [String] = []

    @Option(name: [.long], help: ArgumentHelp("disallow patterns for integrate PR users", valueName: "pattern"))
    public var denyFrom: [String] = []

    @Option(name: [.long], help: ArgumentHelp("permitted license IDs.", valueName: "id"))
    public var allowLicense: [String] = []

    @Option(name: [.long], help: ArgumentHelp("permitted license titles"))
    public var license: [String] = []

    public init() { }

    /// The hub service we should use for this tool
    public func fairHub() throws -> FairHub {
        try FairHub(hostOrg: self.hub, authToken: self.token ?? ProcessInfo.processInfo.environment["GITHUB_TOKEN"], fairsealIssuer: self.fairsealIssuer, allowName: joinWhitespaceSeparated(self.allowName), denyName: joinWhitespaceSeparated(self.denyFrom), allowFrom: joinWhitespaceSeparated(self.allowFrom), denyFrom: joinWhitespaceSeparated(self.denyFrom), allowLicense: joinWhitespaceSeparated(self.allowLicense))
    }

}

fileprivate extension FairParsableCommand {

    /// Output the given message to standard error
    func msg(_ kind: MessageKind = .info, _ message: Any?...) {
        if msgOptions.quiet == true {
            return
        }

        let msg = message.map({ $0.flatMap(String.init(describing:)) ?? "nil" }).joined(separator: " ")

        if kind == .debug && msgOptions.verbose != true {
            return // skip debug output unless we are running verbose
        }


        if msgOptions.messages != nil {
            msgOptions.messages!.messages.append((kind, message))
        } else {

            // let (checkMark, failMark) = ("✓", "X")
            if kind == .info {
                // info just gets printed directly
                print(msg, to: &StandardErrorOutputStream.shared)
            } else {
                print(kind.name, msg, to: &StandardErrorOutputStream.shared)
            }
        }
    }
}

private struct StandardErrorOutputStream: TextOutputStream {
    static var shared = StandardErrorOutputStream()
    let stderr = FileHandle.standardError

    func write(_ string: String) {
        stderr.write(string.utf8Data)
    }
}

extension FairToolCommand {
    enum Errors : LocalizedError {
        case missingCommand
        case unknownCommand(_ cmd: String)
        case badArgument(_ arg: String)
        case badOperation(_ op: String?)
        case missingSDK
        case dumpPackageError
        case invalidAppSourceHeader(_ url: URL)
        case cannotInitNonEmptyFolder(_ url: URL)
        case sameOutputAndProjectPath(_ output: String, _ project: String)
        case cannotOverwriteAlteredFile(_ url: URL)
        case invalidData(_ url: URL)
        case invalidPlistValue(_ key: String, _ expected: [String], _ actual: NSObject?, _ url: URL)
        case invalidContents(_ scaffoldSource: String?, _ projectSource: String?, _ path: String, _ line: Int)
        case invalidHub(_ host: String?)
        case badRepository(_ expectedHost: String, _ repository: String)
        case missingArguments
        case downloadMissing(_ url: URL)
        case missingAppPath
        case badApplicationsPath(_ url: URL)
        case installAppMissing(_ appName: String, _ url: URL)
        case installedAppExists(_ appURL: URL)
        case processCommandUnavailable(_ command: String)
        case matchFailed(_ arg: String)
        case noBundleID(_ url: URL)
        case mismatchedBundleID(_ url: URL, _ sourceID: String, _ destID: String)
        case sandboxRequired
        case forbiddenEntitlement(_ entitlement: String)
        case missingUsageDescription(_ entitlement: AppEntitlement)
        case missingFlag(_ flag: String)
        case invalidIntegrationTitle(_ integrationName: String, _ expectedName: String)

        public var errorDescription: String? {
            switch self {
            case .missingCommand: return "Missing command"
            case .unknownCommand(let cmd): return "Unknown command \"\(cmd)\""
            case .badArgument(let arg): return "Bad argument: \"\(arg)\""
            case .badOperation(let op): return "Bad operation: \"\(op ?? "none")\"."
            case .missingSDK: return "Missing SDK"
            case .dumpPackageError: return "Error reading Package.swift"
            case .invalidAppSourceHeader(let url): return "Invalid modification of source header at \(url.lastPathComponent)."
            case .cannotInitNonEmptyFolder(let url): return "Folder is not empty: \(url.path)."
            case .sameOutputAndProjectPath(let output, let project): return "The output path specified by -o (\(output)) may not be the same as the project path specified by -p (\(project))."
            case .cannotOverwriteAlteredFile(let url): return "Cannot overwrite path \(url.relativePath) with changed contents."
            case .invalidData(let url): return "The data at \(url.path) is invalid."
            case .invalidPlistValue(let key, let expected, let actual, let url): return "The key \"\(key)\" at \(url.path) is invalid: expected one of \"\(expected)\" but found \"\(actual ?? ("nil" as NSString))\"."
            case .invalidContents(_, _, let path, let line): return "The contents at \"\(path)\" does not match the contents of the original source starting at line \(line + 1)."
            case .invalidHub(let host): return "The hub (\"\(host ?? "null")\") specified by the -h/--hub flag is invalid"
            case .badRepository(let expectedHost, let repository): return "The pinned repository \"\(repository)\" does not match the hub (\"\(expectedHost)\") specified by the -h/--hub flag"
            case .missingArguments: return "The operation requires at least one argument"
            case .downloadMissing(let url): return "The download file could not be found: \(url.path)"
            case .missingAppPath: return "The applications install path (-a/--appPath) is required"
            case .badApplicationsPath(let url): return "The applications install path (-a/--appPath) did not exist and could not be created: \(url.path)"
            case .installAppMissing(let appName, let url): return "The install archive was missing a root \"\(appName)\" at: \(url.path)"
            case .installedAppExists(let appURL): return "Cannot install over existing app without update: \(appURL.path)"
            case .processCommandUnavailable(let command): return "Platform does not support Process and therefore cannot run: \(command)"
            case .matchFailed(let arg): return "Found no match for: \"\(arg)\""
            case .noBundleID(let url): return "No bundle ID found for app: \"\(url.path)\""
            case .mismatchedBundleID(let url, let sourceID, let destID): return "Update cannot change bundle ID from \"\(sourceID)\" to \"\(destID)\" in app: \(url.path)"
            case .sandboxRequired: return "The Sandbox.entitlements must activate sandboxing with the \"com.apple.security.app-sandbox\" property"
            case .forbiddenEntitlement(let entitlement): return "The entitlement \"\(entitlement)\" is not permitted."
            case .missingUsageDescription(let entitlement): return "The entitlement \"\(entitlement.entitlementKey)\" requires a corresponding usage description property in the Info.plist FairUsage dictionary"
            case .missingFlag(let flag): return "The operation requires the -\(flag) flag"
            case .invalidIntegrationTitle(let title, let expectedName): return "The title of the integration pull request \"\(title)\" must match the product name and version in the AppFairApp.xcconfig file (expected: \"\(expectedName)\")"
            }
        }
    }
}

/// Options for how downloading remote files should work.
public struct DownloadOptions: ParsableArguments {
    @Option(name: [.long], help: ArgumentHelp("location of folder for downloaded artifacts.", valueName: "dir"))
    public var cacheFolder: String?

    public init() { }

    /// Downloads a remote URL, or else returns the fule URL unadorned
    func acquire(path: String, onDownload: (URL) -> (URL) = { $0 }) async throws -> (from: URL, local: URL) {
        if let url = URL(string: path), ["http", "https"].contains(url.scheme) {
            let url = onDownload(url)
            return (url, try await self.download(url: url))
        } else {
            return (URL(fileURLWithPath: path), URL(fileURLWithPath: path))
        }
    }

    func download(url: URL) async throws -> URL {
        let (downloadedURL, response) = try await URLSession.shared.downloadFile(for: URLRequest(url: url))
        guard let status = (response as? HTTPURLResponse)?.statusCode,
              (200..<300).contains(status) else {
            throw URLError(.badServerResponse)
        }
        if let cacheFolder = cacheFolder.flatMap(URL.init(fileURLWithPath:)),
            FileManager.default.isDirectory(url: cacheFolder) == true {
            let cacheName = url.cachePathName // the full URL download
            let localURL = URL(fileURLWithPath: cacheName, relativeTo: cacheFolder)
            let _ = try? FileManager.default.trash(url: localURL) // in case it exists
            try FileManager.default.moveItem(at: downloadedURL, to: localURL)
            return localURL
        }
        return downloadedURL
    }
}

public struct RetryOptions: ParsableArguments {
    @Option(name: [.long], help: ArgumentHelp("amount of time to continue re-trying downloading a resource."))
    public var retryDuration: TimeInterval?

    @Option(name: [.long], help: ArgumentHelp("backoff time for waiting to retry."))
    public var retryWait: TimeInterval = 30

    public init() { }

    /// Retries the given operation until the `retry-duration` flag as been exceeded
    public func retrying<T>(operation: () async throws -> T) async throws -> T {
        let timeoutDate = Date().addingTimeInterval(self.retryDuration ?? 0)
        while true {
            do {
                return try await operation()
            } catch {
                // TODO: schedule on a queue rather than blocking on Thread.sleep
                if try backoff(timeoutDate, error: error) == false {
                    throw error
                }
            }
        }

        /// Backs off until the given timeout date
        @discardableResult func backoff(_ timeoutDate: Date, error: Error?) throws -> Bool {
            // we we are timed out, or if we don't want to retry, then simply re-download
            if (self.retryDuration ?? 0) <= 0 || self.retryWait <= 0 || Date() >= timeoutDate {
                return false
            } else {
                //msg(.info, "retrying operation in \(self.retryWait) seconds from \(Date()) due to error:", error)
                Thread.sleep(forTimeInterval: self.retryWait)
                return true
            }
        }
    }

}


fileprivate extension FairParsableCommand {
    var fm: FileManager { .default }

    static var appSuffix: String { ".app" }

    /// The name of the App & the repository; defaults to "App"
    var appName: String { Bundle.appfairDefaultAppName }

    var environment: [String: String] { ProcessInfo.processInfo.environment }

    /// Fail the command and exit the tool
    func fail<E: Error>(_ error: E) -> E {
        return error
    }

    func load(url: URL) throws -> Data {
        try Data(contentsOf: url)
    }

    func validateCommit(ref: String, hub: FairHub) async throws {
        msg(.info, "Validating commit ref:", ref)
        let response = try await hub.request(FairHub.GetCommitQuery(owner: hub.org, name: appName, ref: ref)).get().data
        let author: Void = try hub.authorize(commit: response)
        let _ = author
        //msg(.info, "Validated commit author:", author)
    }

    /// Perform update checks before copying the app into the destination
    private func validateUpdate(from sourceApp: URL, to destApp: URL) throws {
        let sourceInfo = try Plist(url: sourceApp.appendingPathComponent("Contents/Info.plist"))
        let destInfo = try Plist(url: destApp.appendingPathComponent("Contents/Info.plist"))

        guard let sourceBundleID = sourceInfo.CFBundleIdentifier else {
            throw FairToolCommand.Errors.noBundleID(sourceApp)
        }

        guard let destBundleID = destInfo.CFBundleIdentifier else {
            throw FairToolCommand.Errors.noBundleID(destApp)
        }

        if sourceBundleID != destBundleID {
            throw FairToolCommand.Errors.mismatchedBundleID(destApp, sourceBundleID, destBundleID)
        }
    }

    /// Parses the `AccentColor.colorset/Contents.json` file and returns the first color item
    func parseColorContents(url: URL) throws -> (r: Double, g: Double, b: Double, a: Double)? {
        try AccentColorList(json: Data(contentsOf: url)).firstRGBAColor
    }

    func buildAppCatalogMarkdown(catalog: AppCatalog) throws -> String {
        let format = ISO8601DateFormatter()
        func fmt(_ date: Date) -> String {
            //date.localizedDate(dateStyle: .short, timeStyle: .short)
            format.string(from: date)
        }

        func pre(_ string: String) -> String {
            "`" + string + "`"
        }

        var md = """
            ---
            layout: catalog
            ---

            <style>
            table {
                border-collapse: collapse;
            }

            td, th {
                border: 1px solid black;
                white-space: nowrap;
            }

            th, td {
                padding: 5px;
            }

            tr:nth-child(even) {
                background-color: Lightgreen;
            }
            </style>

            | name | version | imps | views | dls | size | stars | issues | date | category |
            | ---: | :------ | ---: | ----: | --: | :--- | -----:| -----: | ---- | :------- |

            """

        for app in catalog.apps.sorting(by: \.versionDate, ascending: false) {
            let landingPage = "https://\(app.name.rehyphenated()).github.io/App/"

            let v = app.version ?? ""
            var version = v
            if app.beta == true {
                version += "β"
            }

            md += "| "
            md += "[`\(app.name)`](\(landingPage))"

            md += " | "
            if let relURL = URL(string: v, relativeTo: app.releasesURL) {
                md += "[`\(pre(version))`](\(relURL.absoluteString))"
            } else {
                md += "`\(pre(version))`"
            }

            md += " | "
            md += pre((app.impressionCount ?? 0).description)

            md += " | "
            md += pre((app.viewCount ?? 0).description)

            md += " | "
            md += pre((app.downloadCount ?? 0).description)

            md += " | "
            md += pre((app.size ?? 0).localizedByteCount())

            md += " | "
            md += pre((app.starCount ?? 0).description)

            md += " | "
            let issueCount = (app.issueCount ?? 0)
            if issueCount > 0, let issuesURL = app.issuesURL {
                md += "[`\(pre(issueCount.description))`](\(issuesURL.absoluteString))"
            } else {
                md += pre(issueCount.description)
            }

            md += " | "
            md += pre(fmt(app.versionDate ?? .distantPast))

            md += " | "
            if let category = app.appCategories.first {
                md += "[\(pre(category.rawValue))](https://github.com/topics/appfair-\(category.rawValue)) "
            }

            md += " |\n"
        }

        md += """

            <center><small>`{{ site.time | date_to_xmlschema }}`</small></center>

            """

        return md
    }

    @discardableResult func saveCask(_ app: AppCatalogItem, to caskFolderFlag: String, prereleaseSuffix: String?) throws -> Bool {
        let appNameSpace = app.name
        let appNameHyphen = app.name.rehyphenated()

        let appBundle = "app." + appNameHyphen

        guard let version = app.version else {
            msg(.info, "no version for app: \(appNameHyphen)")
            return false
        }

        guard let sha256 = app.sha256 else {
            msg(.info, "no hash for app: \(appNameHyphen)")
            return false
        }

        let fairground = Bundle.catalogBrowserAppOrg // e.g., App-Fair

        let isCatalogAppCask = appNameHyphen == fairground

        var caskName = appNameHyphen.lowercased()

        if app.beta == true {
            guard let prereleaseSuffix = prereleaseSuffix else {
                return false // we've speficied not to generate casks for pre-releases
            }
            caskName = caskName + prereleaseSuffix
        }

        let caskPath = caskName + ".rb"

        // apps other than "Catalog Name.app" are installed att "/Applications/Catalog Name/App Name.app"
        let installPrefix = isCatalogAppCask ? "" : (fairground.dehyphenated() + "/")

        // depending on the fair-ground's catalog app becomes difficult when the catalog app updates itself; homebrew won't overwrite the self-updated app even with the force flag, which means that a user may need to manually delete and re-install the app;
        // let fairgroundCask = fairground.lowercased() // e.g., app-fair
        let dependency = "" // isCatalogAppCask ? "" : "depends_on cask: \"\(fairgroundCask)\""

        let appDesc = (app.subtitle ?? appNameSpace).replacingOccurrences(of: "\"", with: "'")
        var downloadURL = app.downloadURL.absoluteString

        // all apps other than the catalog browser are
        let appStanza = "app \"\(appNameSpace).app\", target: \"\(installPrefix)\(appNameSpace).app\""

        // this helper stanza will make an executable symlink from the app binary to the cask name
        // it will allow the running of "Super App.app" CLI with /usr/local/bin/super-app
        let appHelper = /* !isCatalogAppCask ? "" : */ "binary \"#{appdir}/\(installPrefix)\(appNameSpace).app/Contents/MacOS/\(appNameSpace)\", target: \"\(caskName)\""

        // change the hardcoded version string to a "#{version}" token, which minimizes the number of source changes when the app is upgraded
        downloadURL = downloadURL.replacingOccurrences(of: "/\(version)/", with: "/#{version}/")

        let repobase = "github.com/\(appNameHyphen)/"

        let caskSpec = """
cask "\(caskName)" do
  version "\(version)"
  sha256 "\(sha256)"

  url "\(downloadURL)",
      verified: "\(repobase)"
  name "\(appNameSpace)"
  desc "\(appDesc)"
  homepage "https://\(repobase)App/"

  depends_on macos: ">= :monterey"
  \(dependency)

  \(appStanza)
  \(appHelper)

  postflight do
    system "xattr", "-r", "-d", "com.apple.quarantine", "#{appdir}/\(installPrefix)\(app.name).app"
  end

  zap trash: [
    "~/Library/Caches/\(appBundle)",
    "~/Library/Containers/\(appBundle)",
    "~/Library/Preferences/\(appBundle).plist",
    "~/Library/Application Scripts/\(appBundle)",
    "~/Library/Saved Application State/\(appBundle).savedState",
  ]
end
"""

        let caskFile = URL(fileURLWithPath: caskFolderFlag).appendingPathComponent(caskPath)
        try caskSpec.write(to: caskFile, atomically: false, encoding: .utf8)
        return true
    }

    static var packageValidationLine: String { "// MARK: fair-ground package validation" }

    /// Splits the two strings by newlines and returns the first non-matching line
    static func firstDifferentLine(_ source1: String, _ source2: String) -> Int {
        func split(_ source: String) -> [Substring] {
            source.split(separator: "\n", omittingEmptySubsequences: false)
        }
        let s1 = split(source1)
        let s2 = split(source2)
        for (index, (l1, l2)) in zip(s1 + s1, s2 + s2).enumerated() {
            if l1 != l2 { return index }
        }
        return -1
    }
}

/// A build configuration file, used to parse `AppFairApp.xcconfig`.
/// The format is a line-based key/value pair separate with an equals. Key and values are always unquoted, and have no terminating character.
public struct BuildSettings : RawRepresentable, Hashable {
    public var rawValue: [String: String]

    public init(rawValue: [String : String]) {
        self.rawValue = rawValue
    }

    public init() {
        self.rawValue = [:]
    }

    public init(data: Data) throws {
        guard let string = String(data: data, encoding: .utf8) else {
            throw CocoaError(.coderInvalidValue)
        }

        self.rawValue = [:]
        for (index, line) in string.split(separator: "\n").enumerated() {
            let nocomment = (line.components(separatedBy: "//").first ?? .init(line)).trimmed()
            if nocomment.isEmpty { continue } // blank & comment-only lines are permitted

            let parts = nocomment.components(separatedBy: " = ")
            if parts.count != 2 {
                throw AppError("Error parsing line \(index): key value pairs must be separated by ' = '")
            }
            guard let key = parts.first?.trimmed(), !key.isEmpty else {
                throw AppError("Error parsing line \(index): no key")
            }
            guard let value = parts.last?.trimmed(), !key.isEmpty else {
                throw AppError("Error parsing line \(index): no value")
            }
            self.rawValue[key] = value
        }
    }

    public init(url: URL) throws {
//        do {
            let data = try Data(contentsOf: url)
            try self.init(data: data)
//        } catch {
//            throw error.withInfo(for: NSLocalizedFailureReasonErrorKey, "Error loading from: \(url.absoluteString)")
//        }
    }

    public subscript(path: String) -> String? {
        rawValue[path]
    }
}

/// Allow multiple newline separated elements for a single value, which
/// permits us to pass multiple e-mail addresses in a single
/// `--allow-from` or `--deny-from` setting.
private func joinWhitespaceSeparated(_ addresses: [String]) -> [String] {
    addresses
        .flatMap { $0.components(separatedBy: .whitespacesAndNewlines) }
        .map { $0.trimmingCharacters(in: .whitespaces) }
        .filter { !$0.isEmpty }
}

extension Sequence {
    /// Creates a new Task with the specified priority and returns an `AsyncThrowingStream` mapping over each element.
    public func mapAsync<T>(priority: TaskPriority? = nil, _ block: @escaping (Element) async throws -> T) -> AsyncThrowingStream<T, Error> {
        AsyncThrowingStream { c in
            Task(priority: priority) {
                do {
                    for item in self {
                        c.yield(try await block(item))
                    }
                    c.finish()
                } catch {
                    c.finish(throwing: error)
                }
            }
        }
    }
}
