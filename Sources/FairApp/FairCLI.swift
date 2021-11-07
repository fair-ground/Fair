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
import Foundation
import FairCore
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

public class FairCLI {
    /// The name of the App & the repository; defaults to "App"
    public let appName = AppNameValidation.defaultAppName

    public var environment: [String: String]
    public var flags: [String: [String]]
    public var op: Operation
    public var trailingArguments: [String]

    let fm = FileManager.default

    public static let appSuffix = ".app"

    public init(arguments args: [String] = CommandLine.arguments, environment: [String: String] = ProcessInfo.processInfo.environment) throws {
        self.environment = environment
        self.flags = [:]

        let firstArg = args.dropFirst().first

        if firstArg == nil || firstArg == "-h" || firstArg == "--help" {
            self.op = .help
        } else {
            guard let op = firstArg.flatMap(Operation.init(rawValue:)) else {
                if firstArg?.hasPrefix("-") == true {
                    throw Errors.badOperation(nil)
                } else {
                    throw Errors.badOperation(firstArg)
                }
            }
            self.op = op
        }

        if args.count > 2 {
            for a in 1...(args.count/2) {
                let i = a * 2
                if i < args.count && args[i].hasPrefix("-") {
                    if i < args.count - 1 {
                        let flag = String(args[i].dropFirst())
                        self.flags[flag, default: []] += [args[i+1]]
                    } else {
                        // last parameter was a flag with no value
                        throw Errors.badArgument(args[i])
                    }
                } else {
                    self.trailingArguments = Array(args[i...])
                    return
                }
            }
        }
        self.trailingArguments = []
    }

    /// Fail the command and exit the tool
    func fail<E: Error>(_ error: E) -> E {
        return error
    }
}

/// A property list, which is simply a wrapper around an `NSDictionary` with some conveniences.
public final class Plist : RawRepresentable {
    public let rawValue: NSDictionary

    public init() {
        self.rawValue = NSDictionary()
    }

    public init(rawValue: NSDictionary) {
        self.rawValue = rawValue
    }

    /// Attempts to parse the given data as a property list
    /// - Parameters:
    ///   - data: the property list data to parse
    ///   - format: the format the data is expected to be in, or nil if empty
    public convenience init(data: Data) throws {
        guard let props = try PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? NSDictionary else {
            throw AppError("Invalid property list")
        }
        self.init(rawValue: props)
    }

    public convenience init(url: URL) throws {
        do {
            let data = try Data(contentsOf: url)
            try self.init(data: data)
        } catch {
            throw error.withInfo(for: NSLocalizedFailureReasonErrorKey, "Error loading from: \(url.absoluteString)")
        }
    }

    /// Serialize this property list to data
    public func serialize(as format: PropertyListSerialization.PropertyListFormat) throws -> Data {
        try PropertyListSerialization.data(fromPropertyList: rawValue, format: format, options: 0)
    }
}

public extension Plist {
    /// The usage description dictionary for the `"FairUsage"` key.
    var FairUsage: NSDictionary? {
        rawValue["FairUsage"] as? NSDictionary
    }

    var CFBundleIdentifier: String? {
        rawValue[InfoPlistKey.CFBundleIdentifier.plistKey] as? String
    }

    var CFBundleName: String? {
        rawValue[InfoPlistKey.CFBundleName.plistKey] as? String
    }

    var CFBundleVersion: String? {
        rawValue[InfoPlistKey.CFBundleVersion.plistKey] as? String
    }

    var CFBundleShortVersionString: String? {
        rawValue[InfoPlistKey.CFBundleShortVersionString.plistKey] as? String
    }

    var CFBundleDisplayName: String? {
        rawValue[InfoPlistKey.CFBundleDisplayName.plistKey] as? String
    }
}

extension FairHub.AppBuildVersion {
    /// Extracts and validates the `CFBundleVersion` and `CFBundleShortVersionString`
    /// from the given `Info.plist` URL
    init(plistURL: URL) throws {
        let plist_dict = try Plist(url: plistURL)
        // try checkStr(key: InfoPlistKey.CFBundleVersion, is: "$(CURRENT_PROJECT_VERSION)")
        let buildNumberKey = InfoPlistKey.CFBundleVersion.rawValue
        guard let buildNumberValue = plist_dict.CFBundleVersion else {
            throw FairCLI.Errors.invalidPlistValue(buildNumberKey, [], plist_dict.CFBundleVersion as NSObject?, plistURL)
        }

        guard let buildNumber = UInt(buildNumberValue) else {
            throw FairCLI.Errors.invalidPlistValue(buildNumberKey, [], plist_dict.CFBundleVersion as NSObject?, plistURL)
        }

        // try checkStr(key: InfoPlistKey.CFBundleShortVersionString, is: "$(MARKETING_VERSION)")
        guard let buildVersion = plist_dict.CFBundleShortVersionString else {
            throw FairCLI.Errors.invalidPlistValue(InfoPlistKey.CFBundleShortVersionString.rawValue, [], plist_dict.CFBundleShortVersionString as NSObject?, plistURL)
        }

        // a version number needs to be in the form 1.23.456
        guard let version = AppVersion(string: buildVersion) else {
            throw FairCLI.Errors.invalidPlistValue(InfoPlistKey.CFBundleShortVersionString.rawValue, [], buildVersion as NSString, plistURL)
        }

        self.init(build: buildNumber, version: version)
    }
}

public extension FairCLI {
    enum Operation: String, CaseIterable {
        case initialize = "init"
        case help
        case welcome
        case package
        case walkthrough
        case validate
        case merge
        case catalog
        #if canImport(Compression)
        case fairseal
        #endif
        #if canImport(SwiftUI)
        case icon
        #endif

        var operationSummary: String {
            switch self {
            case .initialize: return "generate a new app scaffold"
            case .walkthrough: return "walk-through new project steps"
            case .help: return "display a help message"
            case .welcome: return "perform an interactive guided walk-through"
            case .package: return "package up an app"
            case .validate: return "validate that the project can be successfully released"
            case .merge: return "merge base fair-ground updates into the project"
            case .catalog: return "build the catalog"
            #if canImport(Compression)
            case .fairseal: return "generates fairseal from trusted artifact"
            #endif
            #if canImport(SwiftUI)
            case .icon: return "create an icon for the given project"
            #endif
            }
        }
    }

    /// The flag for the hub we should use
    var appPathKey: String? {
        flags["a"]?.first ?? flags["-appPath"]?.first
    }

    /// The flag for the project folder
    var templateFlag: FairTemplate {
        FairTemplate(rawValue: flags["t"]?.first ?? flags["-template"]?.first ?? FairTemplate.default.rawValue) ?? FairTemplate.default
    }

    /// Shows the data for the project file at the given relative path
    func scaffoldURL(path: String? = nil) throws -> URL? {
        templateFlag.resourceURL(for: path)
    }

    /// The flag for the project folder
    var projectPathFlag: String {
        flags["p"]?.first ?? flags["-project"]?.first ?? fm.currentDirectoryPath
    }

    /// Loads the data for the project file at the given relative path
    func projectPathURL(path: String) -> URL {
        URL(fileURLWithPath: path, isDirectory: false, relativeTo: URL(fileURLWithPath: projectPathFlag, isDirectory: true))
    }

    /// The flag for the output folder or file
    var outputFlag: String? {
        flags["o"]?.first ?? flags["-output"]?.first
    }

    /// The flag for the output folders or files
    var outputFlags: [String] {
        (flags["o"] ?? []) + (flags["-output"] ?? [])
    }

    /// The flag for the `fairseal` command indicating the online resource for the artifact metadata
    var artifactStagingFolders: [String] {
        flags["-artifact-staging"] ?? []
    }

    /// The flag for the artifact extensions to filter
    var artifactExtensionFlag: [String]? {
        flags["-artifact-extension"]
    }

    /// The flag for fairseal validation
    var fairsealFlag: [String]? {
        flags["-fairseal"]
    }

    /// The flag the matching strategy for enforcing reproducible builds
    var fairsealMatchFlag: [String]? {
        flags["-fairseal-match"]
    }

    /// The flag for the output folder or the current director
    var outputDirectoryFlag: String {
        outputFlag ?? fm.currentDirectoryPath
    }

    /// The flag for the hub we should use
    var hubFlag: String? {
        flags["h"]?.first ?? flags["-hub"]?.first
    }

    /// The flag for the repository
    var orgName: String? {
        flags["g"]?.first ?? flags["-org"]?.first
    }

    /// The flag for the token used for the hub's authentication
    var hubToken: String? {
        flags["k"]?.first ?? flags["-token"]?.first ?? ProcessInfo.processInfo.environment["GITHUB_TOKEN"]
    }

    /// The flag for the commit ref to validate against the allow/deny list
    var refFlag: String? {
        flags["-ref"]?.first
    }

    /// The flag for the name of the login that issues the fairseal
    var fairsealIssuer: String? {
        flags["-fairseal-issuer"]?.first
    }

    /// The flag for the allow patterns for integrate PRs
    var allowName: [String]? {
        flags["-allow-name"].flatMap(joinWhitespaceSeparated)
    }

    /// The flag for the disallow patterns for integrate PRs
    var denyName: [String]? {
        flags["-deny-name"].flatMap(joinWhitespaceSeparated)
    }

    /// The flag for the allow patterns for integrate PRs
    var allowFrom: [String]? {
        flags["-allow-from"].flatMap(joinWhitespaceSeparated)
    }

    /// The flag for the disallow patterns for integrate PRs
    var denyFrom: [String]? {
        flags["-deny-from"].flatMap(joinWhitespaceSeparated)
    }

    /// The flag for the permitted license IDs
    var allowLicense: [String]? {
        flags["-allow-license"].flatMap(joinWhitespaceSeparated)
    }

    /// Allow multiple newline separated elements for a single value, which
    /// permits us to pass multiple e-mail addresses in a single
    /// `--allow-from` or `--deny-from` setting.
    func joinWhitespaceSeparated(_ addresses: [String]) -> [String] {
        addresses
            .flatMap { $0.components(separatedBy: .whitespacesAndNewlines) }
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
    }

    /// The flag for the folder into which the `merge` operation should write a version marker file
    var versionMarkerDirFlag: String? {
        flags["-version-marker-dir"]?.first
    }

    /// The flag whether to force the current operation
    var forceFlag: Bool {
        Bool(flags["f"]?.first ?? flags["-force"]?.first ?? "false") ?? false
    }

    /// The flag whether to display verbose messages
    var verboseFlag: Bool {
        Bool(flags["v"]?.first ?? flags["-verbose"]?.first ?? "false") ?? false
    }

    /// The flag whether validation should strictly check that the project exactly matches the template
    var strictFlag: Bool {
        Bool(flags["-strict"]?.first ?? "false") ?? false
    }

    /// The flag specifying the IR title, which must conform to "App-Name v1.2.3"
    var integrationTitleFlag: String? {
        flags["-integrationTitle"]?.first
    }

    /// The flag specifying the permitted license titles that must
    /// appear in the `NSHumanReadableCopyright` property, such as
    /// `"GNU Affero General Public License"`
    var licenseFlag: [String]? {
        flags["-license"]
    }

    /// The flag specifying the IR title, which must conform to "App-Name v1.2.3"
    var maxsizeFlag: Int? {
        flags["-maxsize"]?.first.flatMap({ Int($0) })
    }

    /// The maximum number of Hub API requests that can be made for a session
    var requestLimitFlag: Int? {
        flags["-requestLimit"]?.first.flatMap({ Int($0) })
    }

    /// The amount of time to continue re-trying downloading a resource
    var retryDurationFlag: TimeInterval? {
        flags["-retry-duration"]?.first.flatMap({ TimeInterval($0) })
    }

    /// The backoff time for waiting to retry; defaults to 30 seconds
    var retryWaitFlag: TimeInterval {
        flags["-retry-wait"]?.first.flatMap({ TimeInterval($0) }) ?? 30.0
    }

    /// The flag for the `fairseal` command indicating the artifact that was created in a trusted environment
    var trustedArtifactFlag: String? {
        flags["-trusted-artifact"]?.first
    }

    /// The flag for the `fairseal` command indicating the artifact that was created in an untrusted environment
    var untrustedArtifactFlag: String? {
        flags["-untrusted-artifact"]?.first
    }

    /// The flag for the `fairseal` command indicating the online resource for the artifact that will be generated
    var artifactURLFlag: String? {
        flags["-artifact-url"]?.first
    }

    /// The flag for the `fairseal` command indicating the output folder for the casks
    var caskFolderFlag: String? {
        flags["-cask-folder"]?.first
    }

    var interactiveFlag: Bool {
        Bool(flags["-interactive"]?.first ?? "true") ?? true
    }

    var ansiColorsFlag: Bool {
        Bool(flags["-ansi-colors"]?.first ?? "true") ?? true
    }

    func validateTrailingArguments() throws -> [String] {
        if trailingArguments.isEmpty {
            throw Errors.missingArguments(op)
        }
        return trailingArguments
    }

    /// The hub service we should use for this tool
    func fairHub() throws -> FairHub {
        guard let hubFlag = hubFlag else {
            throw Errors.invalidHub(nil)
        }

        return try FairHub(hostOrg: hubFlag, authToken: hubToken, fairsealIssuer: fairsealIssuer, allowName: allowName ?? [], denyName: denyName ?? [], allowFrom: allowFrom ?? [], denyFrom: denyFrom ?? [], allowLicense: allowLicense ?? [])
    }

    /// Loads the data for the output file at the given relative path
    func outputURL(path: String) throws -> URL {
        URL(fileURLWithPath: path, isDirectory: false, relativeTo: URL(fileURLWithPath: outputDirectoryFlag, isDirectory: true))
    }

    func load(url: URL) throws -> Data {
        try Data(contentsOf: url)
    }

    /// Returns the configured applications path, attempting to create it if it doesn't exist
    func applicationsPath() throws -> URL {
        guard let appPathKey = appPathKey else {
            throw Errors.missingAppPath
        }

        let appURL = URL(fileURLWithPath: appPathKey)
        if fm.isDirectory(url: appURL) != true {
            try fm.createDirectory(at: appURL, withIntermediateDirectories: true, attributes: [:])
        }

        if fm.isDirectory(url: appURL) != true {
            throw Errors.badApplicationsPath(appURL)
        }

        return appURL
    }

    /// A handler for messages that the tool outputs
    typealias MessageHandler = ((MessageKind, Any?...) -> ())

    /// Invokes the tool with the command-line interface
    func runCLI(operation: Operation? = nil, msg: MessageHandler? = nil) throws {
        let messenger = msg ?? { [weak self] in self?.printMessage(kind: $0, $1) }
        switch operation ?? op {
        case .initialize: try initialize(msg: messenger)
        case .help: try help(msg: messenger)
        case .welcome: try welcome(msg: messenger)
        case .walkthrough: try walkthrough(msg: messenger)
        case .package: try package(msg: messenger)
        case .validate: try validate(msg: messenger)
        case .merge: try merge(msg: messenger)
        case .catalog: try catalog(msg: messenger)
        #if canImport(Compression)
        case .fairseal: try fairseal(msg: messenger)
        #endif
        #if canImport(SwiftUI)
        case .icon: try icon(msg: messenger)
        #endif
        }
    }

    func create(msg: MessageHandler, template: FairTemplate = .default, overwrite: Bool) throws {
        func validateFolder(url: URL) throws -> URL {
            msg(.info, "initializing project at:", url.path)
            let contents = try fm.contentsOfDirectory(atPath: url.path)
            if overwrite == false && contents.isEmpty == false {
                throw Errors.cannotInitNonEmptyFolder(url)
            }
            let folderName = url.lastPathComponent
            if folderName != AppNameValidation.defaultAppName {
                try AppNameValidation.standard.validate(name: folderName)
            }
            let _ = folderName
            return url
        }

        let url = try validateFolder(url: URL(fileURLWithPath: outputDirectoryFlag))
        if fm.isDirectory(url: url) != true {
            throw CocoaError(.fileReadNoSuchFile)
        }

        if !fm.isWritableFile(atPath: url.path) {
            throw CocoaError(.fileWriteNoPermission)
        }

        func write(to path: String, _ source: String) throws {
            let url = url.appendingPathComponent(path)
            msg(.debug, "comparing path:", url.path)

            try fm.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
            if fm.fileExists(atPath: url.path) {
                // file already exists: verify that the contents are as expected, and overwrite if needed
                let contents = try String(contentsOf: url, encoding: .utf8)
                if contents == source {
                    // same contents; don't overwrite
                    msg(.debug, "identical contents at:", url.path)
                    return
                }

                if forceFlag == true {
                    msg(.debug, "trashing previous path:", url.path)
                    try fm.trash(url: url)
                } else {
                    msg(.error, "cannot overwrite with changed file:", url.path)
                    throw Errors.cannotOverwriteAlteredFile(url)
                }
            }

            try source.write(to: url, atomically: true, encoding: .utf8)
        }

        //let appNameParts = url.lastPathComponent.split(separator: "-")

        //let appNameDash = appNameParts.joined(separator: "-").description
        //let appNameCompact = appNameParts.joined(separator: "").description
        //let appNameSpace = appNameParts.joined(separator: " ").description

        // Fixed the name of the app
        func replaceAppName(in contents: String) -> String {
            // TODO: add an option for injecting an app name
            contents
                //.replacingOccurrences(of: "APPNAME", with: appNameCompact)
                //.replacingOccurrences(of: "APP-NAME", with: appNameDash)
                //.replacingOccurrences(of: "APP NAME", with: appNameSpace)
        }

        // copy over the contents of the FairTemplate into the folder, replacing any existing template patterns
        for templateFile in try template.templatePaths() {
            let relpath = replaceAppName(in: templateFile.relativePath)

            if relpath.hasSuffix(".swp") {
                continue
            }

            if relpath.hasSuffix(".DS_Store") {
                continue
            }

            if relpath.hasSuffix(".png") {
                // we permit copying PNGs without replacing strings
                let dest = url.appendingPathComponent(relpath)
                try? fm.createDirectory(at: dest.deletingLastPathComponent(), withIntermediateDirectories: true)
                try? fm.copyItem(at: templateFile, to: dest)
            } else {
                // everything else needs to be a string we can replace
                let contents = replaceAppName(in: try String(contentsOf: templateFile, encoding: .utf8))
                try write(to: relpath, contents)
            }
        }
    }

    func package(msg: MessageHandler) throws {
        msg(.info, "package")
    }

    func initialize(msg: MessageHandler) throws {
        msg(.info, "Initializing new Fair Ground project")
        try create(msg: msg, overwrite: true)
    }

    func walkthrough(msg: MessageHandler) throws {
        msg(.info, "Walk-through the creation of a new fairground project")

        func po(_ string: String) {
            print(string)
        }

        func read(_ key: String, prompt: String, info: String? = nil, defaultValue: String? = nil, prompSuffix: String = ">", validation: (String) -> (String?) = { _ in nil }) throws -> String {
            let flagKey = "-walkthrough-" + key
            var additionalInfo = info
            while true {
                if let value = flags[flagKey]?.first {
                    if let errorMessage = validation(value) {
                        throw AppError("Invalid value: \"\(flagKey)\" = \"\(value)\": \(errorMessage)")
                    } else {
                        return value
                    }
                }

                // next we prompt the user
                if interactiveFlag == false {
                    throw AppError("Non-interactive mode: key missing for \(flagKey)")
                }

                if let prefixInfo = additionalInfo {
                    print(prefixInfo)
                    print("")
                    additionalInfo = nil // only show the additional the first time around
                }
                print(prompt + prompSuffix + " ", terminator: "")
                guard let value = readLine(strippingNewline: true), !value.isEmpty else {
                    if let defaultValue = defaultValue {
                        return defaultValue
                    } else {
                        continue
                    }
                }

                if let errorMessage = validation(value) {
                    print("Error: " + errorMessage)
                } else {
                    return value
                }
            }
        }

        po("""
        Welcome to the fair-ground!

        This tool will guide you through the process of creating
        and publishing a new app on the App Fair.

        """)

        var appNameSuggestions: [String] = []
        appNameSuggestions += ["The first step in creating a new App Fair app is to choose a name."]
        appNameSuggestions += [""]
        appNameSuggestions += ["The name must be two words separated by a hyphen, such as:"]
        appNameSuggestions += [""]
        for suggestion in try AppNameValidation.standard.suggestNames(count: 5) {
            appNameSuggestions += ["   " + suggestion]
        }

        let appName = try read("app-name", prompt: "App Name", info: appNameSuggestions.joined(separator: "\n"), validation: { proposedName in
            do {
                try AppNameValidation.standard.validate(name: proposedName)
                return nil
            } catch {
                return error.localizedDescription
            }
        })

        let appNameSpace = appName.replacingOccurrences(of: "-", with: " ")
        let appBundleID = "app." + appName
        let appVersion = "0.0.1"
        let ghrepo = "https://www.github.com/\(appName)/App"

        po("Your app will be uniquely contained in a GitHub organization.")
        po("Create a new GitHub organization named: \(appName)")

        func showURL(key: String, url urlString: String) throws {
            if interactiveFlag == true {
                #if os(macOS)
                let response = try read(key, prompt: "Open \(urlString)", defaultValue: "Y", prompSuffix: " [Y/n]?")
                if response.lowercased().hasPrefix("y") {
                    if let url = URL(string: urlString) {
                        NSWorkspace.shared.open(url)
                    }
                }
                #else
                po("Open URL in browser: \(urlString)")
                #endif
            }
        }

        func ansi(_ string: String, _ code: ANSICode = .bold) -> String {
            if ansiColorsFlag == false {
                return string
            } else {
                return string.ansi(code)
            }
        }

        po("""

        Create a new \(ansi("free")) GitHub organization named: \(appName)

        """)
        try showURL(key: "create-org", url: "https://github.com/account/organizations/new?plan=free")

        po("""

        Next, we will configure the organization.

        Edit the organization's profile settings and set:

            \(ansi("Public e-mail")): same as your GitHub e-mail

        The e-mail address must be valid and public.

        """)
        try showURL(key: "set-email", url: "https://github.com/organizations/\(appName)/settings/profile")

        po("""

        Next, we will create your app's repository.

        Fork the base appfair/App repository into the \(appName) organization.

        NOTE: the fork must be in the organization, NOT your personal GitHub account.

        """)
        try showURL(key: "fork-base", url: "https://github.com/appfair/App/fork")

        po("""

        From the fork, click "About" and enter values for:

          \(ansi("Description")) (e.g., "Tool for ABC and XYZ")
          \(ansi("Topic")) (e.g., appfair-utilities)

        """)
        try showURL(key: "configure-project", url: "\(ghrepo)")

        po("""

        Edit the settings for the \(appName) fork:

          \(ansi("Enable Issues"))
          \(ansi("Enable Discussions"))

        """)
        try showURL(key: "enable-issues", url: "\(ghrepo)/settings")

        po("""

        Edit Info.plist and set:

          \(ansi("CFBundleName")): "\(appNameSpace)"
          \(ansi("CFBundleIdentifier")): "\(appBundleID)"
          \(ansi("CFBundleShortVersionString")): "\(appVersion)"

        """)
        try showURL(key: "update-appname", url: "\(ghrepo)/edit/main/Info.plist")

        po("""

        Edit your \(ansi("README.md")) to add your project's description and documentation.

        """)
        try showURL(key: "describe-project", url: "\(ghrepo)/edit/main/README.md")

        po("""

        Edit the SwiftUI container and code your app. E.g.,

          Text("Welcome to \(appNameSpace)!").font(.largeTitle)

        """)
        try showURL(key: "code-app", url: "\(ghrepo)/edit/main/Sources/App/AppContainer.swift")

        po("""

        Enable \(ansi("Actions")) for the fork.

        """)
        try showURL(key: "enable-actions", url: "\(ghrepo)/actions")

        po("""

        Draft a new release. Select "Coose a Tag" and specify: \(appVersion)
        Click "Create new tag: on publish"

        """)
        try showURL(key: "create-release", url: "\(ghrepo)/releases/new")

        po("""

        Wait for Fork-Apply action to complete.

        """)
        try showURL(key: "watch-actions", url: "\(ghrepo)/actions")

        po("""

        View the release artifacts for \(appNameSpace) \(appVersion)

        """)
        try showURL(key: "view-releases", url: "\(ghrepo)/releases/tag/\(appVersion)")

        po("""

        Create a Pull Request from your fork to the base appfair/App.git repository.

        Set the Pull Request title to:

          \(ansi("app.\(appName)"))

        Then select "Create Pull Request"
        """)
        try showURL(key: "create-pr", url: "\(ghrepo)/compare")

        po("""

        Open the "Checks" tab of the PR.
        Once the Integrate-Release checks pass, the app will be available in the App Fair app to install.

        """)
        try showURL(key: "open-appfair", url: "appfair:\(appBundleID)")
    }

    func welcome(msg: MessageHandler) throws {
        msg(.info, "Welcome to Fair Ground!")
    }

    func help(msg: MessageHandler) throws {
        var helpMsg = """
        Usage: fairtool <command> --flag1 value1 --package <package path> [file…]

        The fairtool is the command-line interface to a fair-ground platform.
        It enables validating, verifying, managing, and installing and updating apps.

        """

        print("Available commands:\n", to: &helpMsg)
        helpMsg += "Available commands:\n"
        for op in Operation.allCases {
            print("  ", op.rawValue, op.operationSummary, to: &helpMsg)
        }


        msg(.info, helpMsg)
    }

    func validate(msg: MessageHandler) throws {
        msg(.info, "Validating project:", projectPathURL(path: "").path)
        //msg(.debug, "flags:", flags)
        //msg(.debug, "arguments:", trailingArguments)

        guard let orgName = orgName else {
            throw Errors.badArgument("org")
        }

        // check whether we are validating as the upstream origin or
        let isFork = try hubFlag == nil || orgName != fairHub().org
        //dbg("isFork", isFork, "hubFlag", hubFlag, "orgName", orgName, "fairHub().org", try! fairHub().org)

        /// Verifies that the given plist contains the specified value
        func check(_ plist: Plist, key: String, in expected: [String], empty: Bool = false, url: URL) throws {
            if plist.rawValue[key] == nil && empty == true {
                return // permit empty values
            }

            guard let actual = plist.rawValue[key] as? NSObject else {
                throw Errors.invalidPlistValue(key, expected, nil, url)
            }

            if !expected.isEmpty && !expected.map({ $0 as NSObject }).contains(actual) {
                throw Errors.invalidPlistValue(key, expected, actual, url)
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
            let projectURL = projectPathURL(path: path)
            let projectSource = try String(contentsOf: projectURL, encoding: .utf8)

            // when this is not a fork (i.e., it is the root fairground), we always validate
            do {
                try templateFlag.compareScaffold(project: projectSource, path: path, afterLine: !isFork ? nil : partial ? guardLine : nil)
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

        // the generic term for the base folder is "App-Name"
        let appOrgName = !isFork ? "App-Name" : orgName

        // 1. Check Info.plist
        let infoProperties: Plist
        do {
            let path = "Info.plist"
            msg(.debug, "comparing metadata:", path)
            let infoPlistURL = projectPathURL(path: path)
            let plist_dict = try Plist(url: infoPlistURL)

            infoProperties = plist_dict

            func checkStr(key: InfoPlistKey, in strings: [String]) throws {
                try check(plist_dict, key: key.plistKey, in: strings, url: infoPlistURL)
            }

            // check that the Info.plist contains the correct values for certain keys

            let appName = appOrgName.replacingOccurrences(of: "-", with: " ")
            let appID = "app." + appOrgName

            // try checkStr(key: InfoPlistKey.CFBundleName, is: "$(PRODUCT_NAME)")
            try checkStr(key: InfoPlistKey.CFBundleName, in: [appName])

            try checkStr(key: InfoPlistKey.CFBundleIdentifier, in: [appID, "$(PRODUCT_BUNDLE_IDENTIFIER)"])

            try checkStr(key: InfoPlistKey.CFBundleExecutable, in: ["$(EXECUTABLE_NAME)"])
            try checkStr(key: InfoPlistKey.CFBundlePackageType, in: ["$(PRODUCT_BUNDLE_PACKAGE_TYPE)"])

            if let licenseFlag = self.licenseFlag, !licenseFlag.isEmpty {
                try checkStr(key: InfoPlistKey.NSHumanReadableCopyright, in: licenseFlag)
            }

            if let expectedIntegrationTitle = self.integrationTitleFlag,
                expectedIntegrationTitle != appID {
                throw Errors.invalidIntegrationTitle(expectedIntegrationTitle, appID)
            }

            let buildVersion = try FairHub.AppBuildVersion(plistURL: infoPlistURL)
            msg(.info, "Version", buildVersion.version.versionDescription, "(\(buildVersion.build))")
        }

        // 2. Check Sandbox.entitlements
        do {
            let path = "Sandbox.entitlements"
            msg(.debug, "comparing entitlements:", path)
            let entitlementsURL = projectPathURL(path: path)
            try checkEntitlements(entitlementsURL: entitlementsURL, infoProperties: infoProperties)
        }

        // 3. Check LICENSE.txt
        try compareContents(of: "LICENSE.txt", partial: false)

        // 4. Check Package.swift; we only warn, because the `merge` process will append the authoratative checks to the Package.swift file
        try compareContents(of: "Package.swift", partial: true, warn: true, guardLine: FairTemplate.packageValidationLine)

        // 5. Check Sources/
        try compareContents(of: "Sources/App/AppMain.swift", partial: false)
        try compareContents(of: "Sources/App/Bundle/LICENSE.txt", partial: false)

        // 6. Check Package.resolved if it exists and we've specified the hub to validate
        if let packageResolvedData = try? load(url: projectPathURL(path: "Package.resolved")), let hubFlag = hubFlag {
            msg(.debug, "validating Package.resolved")
            let packageResolved = try JSONDecoder().decode(ResolvedPackage.self, from: packageResolvedData)
            if let httpHost = URL(string: "https://\(hubFlag)")?.host, let hubURL = URL(string: "https://\(httpHost)") {
                // all dependencies must reside at the same fairground
                // TODO: add include-hub/exclude-hub flags to permit cross-fairground dependency networks
                // e.g., permit GitLab apps depending on projects in GitHub repos
                let host = hubURL.deletingLastPathComponent().deletingLastPathComponent()
                //dbg("verifying hub host:", host)
                for pin in packageResolved.object.pins {
                    if !pin.repositoryURL.hasPrefix(host.absoluteString) && !pin.repositoryURL.hasPrefix("https://fair-ground.org/") {
                        throw Errors.badRepository(host.absoluteString, pin.repositoryURL)
                    }
                }
            }
        }

        // the non-forked fairground origin also validates the other project files
        if !isFork {
            try compareContents(of: "Package.swift", partial: false)
            try compareContents(of: "Info.plist", partial: false)
            try compareContents(of: "Sources/App/AppMain.swift", partial: false)
            try compareContents(of: "Sources/App/AppContainer.swift", partial: false)
            try compareContents(of: "Tests/AppTests/AppTests.swift", partial: false)
            try compareContents(of: "App.xcworkspace/contents.xcworkspacedata", partial: false)
            try compareContents(of: "project.xcodeproj/project.pbxproj", partial: false)

            try compareContents(of: "README.md", partial: false)
            // try compareContents(of: ".gitignore", partial: false) // allow users to customize their own ignore file 
            try compareContents(of: "Sandbox.entitlements", partial: false)

            try compareContents(of: "Assets.xcassets/AppIcon.appiconset/Contents.json", partial: false)
            try compareContents(of: "Assets.xcassets/AccentColor.colorset/Contents.json", partial: false)
            try compareContents(of: "Assets.xcassets/Contents.json", partial: false)

            // diffs only work against text
            // try compareContents(of: "Assets.xcassets/AppIcon.appiconset/AppIcon-512.png", partial: false)
        }


        // for strict validation, we check to ensure that this project exactly matches each file in the template (although additional files are tolerated). This is useful for validating that a template project is up-to-date, and could someday be used to migrate projects from older versions to newer
        if strictFlag {
            for scaffoldURL in try templateFlag.templatePaths() {
                let projectURL = projectPathURL(path: scaffoldURL.relativePath)
                if fm.isReadableFile(atPath: projectURL.path) { // we permit missing files (for now)
                    msg(.debug, "  strict check of:", scaffoldURL.relativePath, "vs:", projectURL.relativePath)
                    let scaffoldData = try String(contentsOf: scaffoldURL)
                    let projectData = try String(contentsOf: projectURL)
                    if projectData != scaffoldData {
                        throw Errors.invalidContents(scaffoldData, projectData, projectURL.path, FairTemplate.firstDifferentLine(scaffoldData, projectData))
                    }
                }
            }
        }

        // also check the hub for the
        if hubFlag != nil {
            try verify(org: orgName, repo: appName, hub: fairHub(), msg: msg)
        }

        msg(.info, "Successfully validated project:", projectPathURL(path: "").path)


        // validate the reference
        if let refFlag = refFlag {
            try validateCommit(ref: refFlag, hub: fairHub(), msg: msg)
        }
    }

    /// Loads all the entitlements and matches them to corresponding UsageDescription entires in the app's Info.plist file.
    @discardableResult
    func checkEntitlements(entitlementsURL: URL, infoProperties: Plist) throws -> Array<AppPermission> {
        let entitlements_dict = try Plist(url: entitlementsURL)

        if entitlements_dict.rawValue[AppEntitlement.app_sandbox.entitlementKey] as? NSNumber != true {
            // despite having LSFileQuarantineEnabled=false and `com.apple.security.files.user-selected.executable`, apps that the catalog browser app writes cannot be launched; the only solution seems to be to disable sandboxing, which is a pity…
            if !isCatalogApp {
                throw Errors.sandboxRequired
            }
        }

        var permissions: [AppPermission] = []

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
                throw Errors.forbiddenEntitlement(entitlement.entitlementKey)
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
                throw Errors.missingUsageDescription(entitlement)
            }

            if usageDescription.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                throw Errors.missingUsageDescription(entitlement)
            }

            return (usageDescription, entitlementValue)
        }

        for entitlement in AppEntitlement.allCases {
            if let (usage, _) = try check(entitlement) {
                permissions.append(AppPermission(type: entitlement, usageDescription: usage))
            }
        }

        return permissions
    }

    func validateCommit(ref: String, hub: FairHub, msg: MessageHandler) throws {
        msg(.info, "Validating commit ref:", ref)
        let response = try hub.requestSync(FairHub.GetCommitQuery(owner: hub.org, name: appName, ref: ref)).get().data
        let author = try hub.authorize(commit: response)
        msg(.info, "Validated commit author:", author)
    }

    func verify(org: String, repo repoName: String, hub: FairHub, msg: MessageHandler) throws {
        // when the app we are validating is the actual hub's root organization, use special validation rules (such as not requiring issues)
        msg(.info, "Validating App-Name:", org)

        let response = try hub.requestSync(FairHub.RepositoryQuery(owner: org, name: repoName)).get().data
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

    /// Copies the resources from the project to the output
    func merge(msg: MessageHandler) throws {
        msg(.info, "merge")

        if outputDirectoryFlag == projectPathFlag {
            throw Errors.sameOutputAndProjectPath(outputDirectoryFlag, projectPathFlag)
        }

        let outputURL = URL(fileURLWithPath: outputDirectoryFlag)
        let projectURL = URL(fileURLWithPath: projectPathFlag)
        if outputURL.absoluteString == projectURL.absoluteString {
            throw Errors.sameOutputAndProjectPath(outputDirectoryFlag, projectPathFlag)
        }

        try validate(msg: msg) // always validate first

        /// Attempt to copy the path from the projectPath to the outputPath,
        /// thereby selectively merging parts of the PR with a customizable transform
        @discardableResult func pull(_ path: String, transform: ((Data) throws -> Data)? = nil) throws -> URL {
            msg(.info, "copying", path, "from", projectURL.path, "to", outputURL.path)
            let outputSrc = outputURL.appendingPathComponent(path)
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

        try pull("Package.swift") { data in
            // We manually copy over the package validations so that we do not require that the user always keep the validations current

            // try compareContents(of: "Package.swift", partial: true, warn: true, guardLine: FairTemplate.packageValidationLine)

            guard let packageURL = self.templateFlag.resourceURL(for: "Package.swift") else {
                throw CocoaError(.fileReadNoSuchFile)
            }

            let packageTemplate = try String(contentsOf: packageURL, encoding: .utf8).components(separatedBy: FairTemplate.packageValidationLine)
            if packageTemplate.count != 2 {
                throw CocoaError(.fileReadNoSuchFile)
            }

            let str1 = String(data: data, encoding: .utf8) ?? ""
            let str2 = packageTemplate[1]
            return (str1 + str2).utf8Data
        }

        // copy the user's asset catalogs
        try pull("Assets.xcassets")

        try pull("Sources")
        try pull("Tests")

        let plistURL = try pull("Info.plist")
        let version = try FairHub.AppBuildVersion(plistURL: plistURL)

        // create a version file if we have specified to do so;
        // this will output a file like: staging/version-1.2.3-456
        // this is used to communicate the version number to the catalog process
        // by including it in the metadata as a release asset name
        if let versionDir = versionMarkerDirFlag {
            let filePath = URL(fileURLWithPath: version.versionMarker, relativeTo: URL(fileURLWithPath: versionDir, isDirectory: true))
            // the file needs some content, so simply copy over the pre-processed Info.plist contents, which might be useful since the other plists that are included in the releases are the per-platform post-compiled lists
            try FileManager.default.copyItem(at: plistURL, to: filePath)
        }

        // we do not use the PR's project files; only the base fork's project files will be used
        // try pull(appName + ".xcodeproj")
        // try pull(appName + ".xcworkspace")
    }

    func unzip(from sourceURL: URL, to destURL: URL) throws {
        #if os(macOS)
        try Process.ditto(from: sourceURL, to: destURL)
        #else
        // TODO: add unzip for iOS support
        throw Errors.processCommandUnavailable("ditto")
        #endif
    }

    /// Returns `App-Name`
    func appOrgName() throws -> String {
        guard let orgName = orgName else {
            throw Errors.badArgument("org")
        }
        return orgName
    }

    var isCatalogApp: Bool {
        orgName == Bundle.catalogBrowserAppOrg
    }

    /// Returns `App Name`
    func appNameSpace() throws -> String {
        try appOrgName().replacingOccurrences(of: "-", with: " ")
    }

    #if canImport(SwiftUI)
    func icon(msg: MessageHandler) throws {
        msg(.info, "icon")

        // the list of hashes that represent the default AppIcon-1024.png; this is used to determine whether we should overwrite an existing default icon instead of leaving it untouched; this lets us auto-generate an icon when none has been set, but won't clobber a custom icon
        let defaultIconHashes = [
            "09e146883b712e71b3c5b904f72e09efb66e1137981b12083cd15c2fe8160810", // default icon
        ]

        let outputFiles = outputFlags
        guard !outputFiles.isEmpty else {
            throw Errors.missingFlag(self.op, "-output")
        }

        let appName = try appNameSpace()
        let iconView = FairIconView(appName).environment(\.displayScale, 1.0) // force 1.0 resolution so the output size doesn't change

        for path in outputFiles {
            let outputURL = URL(fileURLWithPath: path)
            if outputURL.pathExtension != "png" {
                throw AppError("output path was not a png: \(path)")
            }

            let parts = outputURL.deletingPathExtension().lastPathComponent.components(separatedBy: "-")
            if parts.count != 2 || parts[0] != "AppIcon" {
                throw AppError("output path must be named AppIcon-size.png, but was: \(path)")
            }

            var sizePart = parts[1]
            var scale = CGFloat(1.0)
            if sizePart.hasSuffix("x2") {
                sizePart = String(sizePart.dropLast().dropLast())
                scale = 2.0
            }

            guard let size = Int(sizePart) else {
                throw AppError("output path must be named AppIcon-size.png, but was: \(path)")
            }

            let iconFile = URL(fileURLWithPath: path)


            let span = CGFloat(size) * CGFloat(scale)
            let bounds = CGRect(origin: CGPoint(x: -span/2, y: -span/2), size: CGSize(width: CGFloat(span), height: CGFloat(span)))

            guard let pngData = iconView.png(bounds: bounds), pngData.count > 1024 else {
                throw AppError("Unable to generate PNG data")
            }

            if let existingFile = try? Data(contentsOf: iconFile), existingFile != pngData {
                let sha256 = existingFile.sha256().hex()
                msg(.info, "sha256 for icon: \(sha256)")
                if !defaultIconHashes.contains(sha256) {
                    msg(.error, "cannot overwrite with unknown hash:", sha256)
                    throw Errors.cannotOverwriteAlteredFile(iconFile)
                }
            }

            try pngData.write(to: iconFile)
            msg(.info, "output icon to: \(iconFile.path)")
        }
    }
    #endif

    /// Perform update checks before copying the app into the destination
    private func validateUpdate(from sourceApp: URL, to destApp: URL) throws {
        let sourceInfo = try Plist(url: sourceApp.appendingPathComponent("Contents/Info.plist"))
        let destInfo = try Plist(url: destApp.appendingPathComponent("Contents/Info.plist"))

        guard let sourceBundleID = sourceInfo.CFBundleIdentifier else {
            throw Errors.noBundleID(sourceApp)
        }

        guard let destBundleID = destInfo.CFBundleIdentifier else {
            throw Errors.noBundleID(destApp)
        }

        if sourceBundleID != destBundleID {
            throw Errors.mismatchedBundleID(destApp, sourceBundleID, destBundleID)
        }
    }

    private func fetchArtifact(msg: MessageHandler, url artifactURL: URL, retryDuration: TimeInterval, retryWait: TimeInterval) throws -> URL {
        let timeoutDate = Date().addingTimeInterval(retryDuration)
        while true {
            do {
                var request = URLRequest(url: artifactURL)
                request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
                let (downloadedURL, response) = try URLSession.shared.downloadSync(request)
                if let response = response as? HTTPURLResponse,
                   (200..<300).contains(response.statusCode) { // e.g., 404
                    msg(.info, "downloaded:", artifactURL.absoluteString, "to:", downloadedURL, "response:", response)
                    return downloadedURL
                } else {
                    msg(.info, "failed to download:", artifactURL.absoluteString, "code:", (response as? HTTPURLResponse)?.statusCode)
                    if try Date() >= timeoutDate || backoff(error: nil) == false {
                        throw AppError("Unable to download: \(artifactURL.absoluteString) code: \((response as? HTTPURLResponse)?.statusCode ?? 0)")
                    }
                }
            } catch {
                if try backoff(error: error) == false {
                    throw error
                }
            }
        }

        /// Backs off until the given timeout date
        @discardableResult func backoff(error: Error?) throws -> Bool {
            // we we are timed out, or if we don't want to retry, then simply re-download
            if retryDuration <= 0 || retryWait <= 0 || Date() >= timeoutDate {
                return false
            } else {
                msg(.info, "retrying download in \(retryWait) seconds due to error:", error)
                Thread.sleep(forTimeInterval: retryWait)
                return true
            }
        }
    }

    private func fetchUntrustedArtifact(msg: MessageHandler) throws -> URL {
        // if we specified the artifact as a local file, just use it directly
        if let untrustedArtifactFlag = untrustedArtifactFlag {
            return URL(fileURLWithPath: untrustedArtifactFlag)
        }

        guard let artifactURLFlag = self.artifactURLFlag,
            let artifactURL = URL(string: artifactURLFlag) else {
            throw Errors.missingFlag(self.op, "-artifact-url")
        }

        return try fetchArtifact(msg: msg, url: artifactURL, retryDuration: retryDurationFlag ?? 0, retryWait: retryWaitFlag)
    }

    #if canImport(Compression)
    func fairseal(msg: MessageHandler) throws {
        msg(.info, "Fairseal")

        // When "--fairseal-match" is a number, we use it as a threshold beyond which differences in elements will fail the build
        let fairsealThreshold = fairsealMatchFlag?.compactMap({ Int($0) }).first

        guard let trustedArtifactFlag = trustedArtifactFlag else {
            throw Errors.missingFlag(self.op, "-trusted-artifact")
        }

        let trustedArtifactURL = URL(fileURLWithPath: trustedArtifactFlag)
        guard let trustedArchive = ZipArchive(url: trustedArtifactURL, accessMode: .read, preferredEncoding: .utf8) else {
            throw AppError("Error opening trusted archive: \(trustedArtifactURL.absoluteString)")
        }

        let untrustedArtifactLocalURL = try fetchUntrustedArtifact(msg: msg)

        guard let untrustedArchive = ZipArchive(url: untrustedArtifactLocalURL, accessMode: .read, preferredEncoding: .utf8) else {
            throw AppError("Error opening untrusted archive: \(untrustedArtifactLocalURL.absoluteString)")
        }

        if untrustedArtifactLocalURL == trustedArtifactURL {
            throw AppError("Trusted and untrusted artifacts may not be the same")
        }

        let trustedEntries = Array(trustedArchive.makeIterator())
        let untrustedEntries = Array(untrustedArchive.makeIterator())

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

        let macOSExecutable = "\(appName).app/Contents/MacOS/\(appName)" // macOS: e.g., Photo Box.app/Contents/MacOS/Photo Box
        let macOSInfo = "\(appName).app/Contents/Info.plist" // macOS: e.g., Photo Box.app/Contents/MacOS/Photo Box

        let iOSExecutable = "Payload/\(appName).app/\(appName)" // iOS: e.g., Photo Box.app/Photo Box
        let iOSInfo = "Payload/\(appName).app/Info.plist"

        var infoPlist: Plist? = nil

        var coreSize = 0 // the size of the executable itself

        for (trustedEntry, untrustedEntry) in zip(trustedEntries, untrustedEntries) {
            if trustedEntry.path != untrustedEntry.path {
                throw AppError("Trusted and untrusted artifact content paths do not match: \(trustedEntry.path) vs. \(untrustedEntry.path)")
            }

            let entryIsAppBinary = trustedEntry.path == macOSExecutable || trustedEntry.path == iOSExecutable
            let entryIsInfo = trustedEntry.path == macOSInfo || trustedEntry.path == iOSInfo

            if entryIsAppBinary {
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

            if let lastPath = pathParts.last, pathParts.dropLast().last == "_CodeSignature" {
                if [
                    "CodeSignature",
                    "CodeResources",
                    "CodeDirectory",
                    "CodeRequirements-1",
                ].contains(lastPath) {
                    // we permit differences in code signatures in order to allow custom signing by the App fork
                    continue
                }
            }

            if trustedEntry.path.hasSuffix("Contents/Resources/Assets.car") {
                // assets sometimes get compiled differently; we let these pass
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

            if trustedEntry.uncompressedSize != untrustedEntry.uncompressedSize {
                throw AppError("Trusted and untrusted artifact content size mismatch at \(trustedEntry.path): \(trustedEntry.uncompressedSize) vs. \(untrustedEntry.uncompressedSize)")
            }

            let trustedPayload = try trustedArchive.extractData(from: trustedEntry)
            let untrustedPayload = try untrustedArchive.extractData(from: untrustedEntry)

            if trustedPayload != untrustedPayload {
                let diff: CollectionDifference<UInt8> = trustedPayload.difference(from: untrustedPayload).inferringMoves()

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
                    let error = AppError("Trusted and untrusted artifact content mismatch at \(trustedEntry.path): \(diff.insertions.count) insertions in \(insertionRanges.rangeView.count) ranges \(insertionRangeDesc) and \(diff.removals.count) removals in \(removalRanges.rangeView.count) ranges \(removalRangeDesc) and totalChanges \(totalChanges) beyond permitted threshold: \(fairsealThreshold ?? 0)")

                    if entryIsAppBinary {
                        if let fairsealThreshold = fairsealThreshold, totalChanges < fairsealThreshold {
                            // when we are analyzing the app binary itself we need to tolerate some minor differences that seem to result from non-reproducible builds
                            print("tolerating \(totalChanges) differences for:", error)
                        } else {
                            throw error
                        }
                    } else {
                        throw error
                    }
                }
            }
        }

        msg(.info, "finishing")

        let sha256 = try Data(contentsOf: untrustedArtifactLocalURL, options: .mappedIfSafe).sha256()
        let entitlementsURL = projectPathURL(path: "Sandbox.entitlements")


        var assets: [FairSeal.Asset] = []

        // publish the hash for the artifact binary URL
        if let artifactURLFlag = self.artifactURLFlag, let artifactURL = URL(string: artifactURLFlag) {

            // the staging folder contains raw assets (e.g., screenshots and README.md) that are included in a release
            for stagingFolder in artifactStagingFolders {
                for localURL in try FileManager.default.contentsOfDirectory(at: projectPathURL(path: stagingFolder), includingPropertiesForKeys: [.fileSizeKey], options: [.skipsSubdirectoryDescendants, .skipsSubdirectoryDescendants, .skipsPackageDescendants]) {
                    guard let assetSize = try localURL.fileSize() else {
                        continue
                    }

                    // the local hash of the asset URL
                    let assetHash = try Data(contentsOf: localURL).sha256().hex()

                    // the published asset URL is the name of the local path relative to the download URL for the artifact
                    let assetURL = artifactURL.deletingLastPathComponent().appendingPathComponent(localURL.lastPathComponent, isDirectory: false)
                    assets.append(FairSeal.Asset(url: assetURL, size: assetSize, sha256: assetHash))
                }
            }
        }

        guard let plist = infoPlist else {
            throw AppError("Missing property list")
        }

        let permissions = try checkEntitlements(entitlementsURL: entitlementsURL, infoProperties: plist)
        for permission in permissions {
            msg(.info, "entitlement:", permission.type.rawValue, "usage:", permission.usageDescription)
        }

        let fairseal = FairSeal(assets: assets, permissions: permissions, coreSize: coreSize, tint: nil)
        msg(.info, "generated fairseal:", fairseal.debugJSON.count.localizedByteCount())
        //try writeOutput(fairseal.debugJSON) // save the file

        // if we specify a hub, then attempt to post the fairseal to the first open PR for thay project
        msg(.info, "posting fairseal for artifact:", assets.first?.url.absoluteString, "JSON:", fairseal.debugJSON)
        if let postURL = try fairHub().postFairseal(fairseal) {
            msg(.info, "posted fairseal to:", postURL.absoluteString)
        } else {
            msg(.warn, "unable to post fairseal")
        }
    }
    #endif

    func catalog(msg: MessageHandler) throws {
        msg(.info, "Catalog")

        let hub = try fairHub()

        // whether to enforce a fairseal check before the app will be listed in the catalog
        let fairsealCheck = fairsealFlag?.contains("skip") != true

        // build the catalog filtering on specific artifact extensions
        let catalog = try hub.buildCatalog(owner: appfairName, fairsealCheck: fairsealCheck, artifactExtensions: self.artifactExtensionFlag ?? ["-macOS.zip", "-iOS.ipa"], requestLimit: self.requestLimitFlag)

        msg(.debug, "releases:", catalog.apps.count) // , "valid:", catalog.count)
        for apprel in catalog.apps {
            msg(.debug, "  app:", apprel.name) // , "valid:", validate(apprel: apprel))
        }

        let json = try catalog.json(outputFormatting: [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes], dateEncodingStrategy: .iso8601, dataEncodingStrategy: .base64)
        let success = try writeOutput(json.utf8String)
        msg(.info, success ? "Successfully wrote catalog to" : "Unable to write catalog to", outputFlag, json.utf8String?.count.localizedByteCount())

        if let caskFolderFlag = caskFolderFlag {
            msg(.info, "Writing casks to: \(caskFolderFlag)")
            for app in catalog.apps {
                try saveCask(app, to: caskFolderFlag, msg: msg)
            }
        }
    }

    @discardableResult func saveCask(_ app: AppCatalogItem, to caskFolderFlag: String, msg: MessageHandler) throws -> Bool {
        let appNameSpace = app.name
        let appNameHyphen = app.name.replacingOccurrences(of: " ", with: "-")

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
        let fairgroundCask = fairground.lowercased() // e.g., app-fair

        let isCatalogAppCask = appNameHyphen == fairground

        let caskName = appNameHyphen.lowercased()
        let caskPath = caskName + ".rb"

        // apps other than "Catalog Name.app" are installed att "/Applications/Catalog Name/App Name.app"
        let installPrefix = isCatalogAppCask ? "" : (fairground.replacingOccurrences(of: "-", with: " ") + "/")

        let dependency = isCatalogAppCask ? "" : "depends_on cask: \"\(fairgroundCask)\""
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

  uninstall quit: "\(appBundle)"
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


    @discardableResult
    func writeOutput(_ value: String?) throws -> Bool {
        guard let outputFile = outputFlag else {
            return false
        }

        if outputFile == "-" { // print to standard out
            print(value ?? "")
        } else {
            let file = URL(fileURLWithPath: outputFile)
            try value?.write(to: file, atomically: true, encoding: .utf8)
        }
        return true
    }

    @discardableResult func printMessage(kind: MessageKind = .info, _ message: [Any?]) -> String {
        let msg = message.map({ $0.flatMap(String.init(describing:)) ?? "nil" }).joined(separator: " ")

        if kind == .debug && verboseFlag == false {
            return msg // skip debug output unless we are running verbose
        }

        // let (checkMark, failMark) = ("✓", "X")
        print(kind.name, msg)

        return msg
    }

    enum MessageKind {
        case debug, info, warn, error

        var name: String {
            switch self {
            case .debug: return "DEBUG"
            case .info: return "INFO"
            case .warn: return "WARN"
            case .error: return "ERROR"
            }
        }
    }

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
        case missingArguments(_ op: Operation)
        case downloadMissing(_ url: URL)
        case missingAppPath
        case badApplicationsPath(_ url: URL)
        case installAppMissing(_ appName: String, _ url: URL)
        case installedAppExists(_ appURL: URL)
        case processCommandUnavailable(_ command: String)
        case matchFailed(_ op: Operation, _ arg: String)
        case noBundleID(_ url: URL)
        case mismatchedBundleID(_ url: URL, _ sourceID: String, _ destID: String)
        case sandboxRequired
        case forbiddenEntitlement(_ entitlement: String)
        case missingUsageDescription(_ entitlement: AppEntitlement)
        case missingFlag(_ op: Operation, _ flag: String)
        case invalidIntegrationTitle(_ integrationName: String, _ bundleID: String)

        public var errorDescription: String? {
            switch self {
            case .missingCommand: return "Missing command"
            case .unknownCommand(let cmd): return "Unknown command \"\(cmd)\""
            case .badArgument(let arg): return "Bad argument: \"\(arg)\""
            case .badOperation(let op): return "Bad operation: \"\(op ?? "none")\". Valid operations: \(Operation.allCases.map(\.rawValue).joined(separator: ", "))"
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
            case .missingArguments(let op): return "The operation \"\(op.rawValue)\" requires at least one argument"
            case .downloadMissing(let url): return "The download file could not be found: \(url.path)"
            case .missingAppPath: return "The applications install path (-a/--appPath) is required"
            case .badApplicationsPath(let url): return "The applications install path (-a/--appPath) did not exist and could not be created: \(url.path)"
            case .installAppMissing(let appName, let url): return "The install archive was missing a root \"\(appName)\" at: \(url.path)"
            case .installedAppExists(let appURL): return "Cannot install over existing app without update: \(appURL.path)"
            case .processCommandUnavailable(let command): return "Platform does not support Process and therefore cannot run: \(command)"
            case .matchFailed(let op, let arg): return "\(op.rawValue) found no match for: \"\(arg)\""
            case .noBundleID(let url): return "No bundle ID found for app: \"\(url.path)\""
            case .mismatchedBundleID(let url, let sourceID, let destID): return "Update cannot change bundle ID from \"\(sourceID)\" to \"\(destID)\" in app: \(url.path)"
            case .sandboxRequired: return "The Sandbox.entitlements must activate sandboxing with the \"com.apple.security.app-sandbox\" property"
            case .forbiddenEntitlement(let entitlement): return "The entitlement \"\(entitlement)\" is not permitted."
            case .missingUsageDescription(let entitlement): return "The entitlement \"\(entitlement.entitlementKey)\" requires a corresponding usage description property in the Info.plist FairUsage dictionary"
            case .missingFlag(let op, let flag): return "The operation \(op.rawValue) requires the -\(flag) flag"
            case .invalidIntegrationTitle(let title, let bundleID): return "The title of the integration pull request \"\(title)\" must match the bundle ID in the Info.plist of the app being built (found: \"\(bundleID)\")"
            }
        }
    }
}

public enum FairTemplate : String, CaseIterable {
    case `default`

    static let packageValidationLine = "// MARK: fair-ground package validation"

    /// the line that divides the package template from the validation section
    public static let packageParts = Result { try Self.default.resource(named: "Package.swift").components(separatedBy: packageValidationLine) }

    /// Returns the base URL for the given template name
    public func resourceURL(for name: String?) -> URL? {
        if name == nil {
            return Bundle.fairCore.url(forResource: self.rawValue, withExtension: nil, subdirectory: "Bundle/Scaffold")
        } else {
            return Bundle.fairCore.url(forResource: name, withExtension: nil, subdirectory: "Bundle/Scaffold/" + self.rawValue)
        }
    }

    public func resource(named name: String) throws -> String {
        guard let url = resourceURL(for: name) else {
            throw CocoaError(.fileReadNoSuchFile)
        }

        return try String(contentsOf: url, encoding: .utf8)
    }

    public func templatePaths() throws -> [URL] {
        try Bundle.fairCore.bundlePaths(in: "Scaffold/" + self.rawValue, includeFolders: false)
    }

    /// Validates that the given project source matches the given scaffold source
    public func compareScaffold(project projectSource: String, path: String, afterLine guardLine: String? = nil) throws {
        guard let scaffoldURL = resourceURL(for: path) else {
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
                    throw FairCLI.Errors.invalidContents(scaffoldParts.last, projectParts.last, path, Self.firstDifferentLine(scaffoldParts.last ?? "", projectParts.last ?? ""))
                }
            } else {
                throw FairCLI.Errors.invalidContents(scaffoldSource, projectSource, path, Self.firstDifferentLine(scaffoldSource, projectSource))
            }
        }
    }

    /// Splits the two strings by newlines and returns the first non-matching line
    public static func firstDifferentLine(_ source1: String, _ source2: String) -> Int {
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



struct ANSICode {
    let open: String
    let close: String

    init(_ open: String, _ close: String) {
        self.open = open
        self.close = close
    }

    static let reset = Self("\u{001B}[0m", "")
    static let dim = Self("\u{001B}[2m", "\u{001B}[22m")
    static let bold = Self("\u{001B}[1m", "\u{001B}[22m")
    static let blink = Self("\u{001B}[5m", "\u{001B}[25m")
    static let hidden = Self("\u{001B}[8m", "\u{001B}[28m")
    static let italic = Self("\u{001B}[3m", "\u{001B}[23m")
    static let reverse = Self("\u{001B}[7m", "\u{001B}[27m")
    static let underline = Self("\u{001B}[4m", "\u{001B}[24m")
    static let strikethrough = Self("\u{001B}[9m", "\u{001B}[29m")

    static let white = Self("\u{001B}[97m", "\u{001B}[0m")
    static let black = Self("\u{001B}[30m", "\u{001B}[0m")
    static let red = Self("\u{001B}[31m", "\u{001B}[0m")
    static let green = Self("\u{001B}[32m", "\u{001B}[0m")
    static let yellow = Self("\u{001B}[33m", "\u{001B}[0m")
    static let blue = Self("\u{001B}[34m", "\u{001B}[0m")
    static let magenta = Self("\u{001B}[35m", "\u{001B}[0m")
    static let cyan = Self("\u{001B}[36m", "\u{001B}[0m")
    static let lightGray = Self("\u{001B}[37m", "\u{001B}[0m")
    static let darkGray = Self("\u{001B}[90m", "\u{001B}[0m")
    static let lightRed = Self("\u{001B}[91m", "\u{001B}[0m")
    static let lightGreen = Self("\u{001B}[92m", "\u{001B}[0m")
    static let lightYellow = Self("\u{001B}[93m", "\u{001B}[0m")
    static let lightBlue = Self("\u{001B}[94m", "\u{001B}[0m")
    static let lightMagenta = Self("\u{001B}[95m", "\u{001B}[0m")
    static let lightCyan = Self("\u{001B}[96m", "\u{001B}[0m")

    static let whiteOn = Self("\u{001B}[107m", "\u{001B}[0m")
    static let blackOn = Self("\u{001B}[40m", "\u{001B}[0m")
    static let redOn = Self("\u{001B}[41m", "\u{001B}[0m")
    static let greenOn = Self("\u{001B}[42m", "\u{001B}[0m")
    static let yellowOn = Self("\u{001B}[43m", "\u{001B}[0m")
    static let blueOn = Self("\u{001B}[44m", "\u{001B}[0m")
    static let magentaOn = Self("\u{001B}[45m", "\u{001B}[0m")
    static let cyanOn = Self("\u{001B}[46m", "\u{001B}[0m")
    static let grayOn = Self("\u{001B}[47m", "\u{001B}[0m")
    static let darkGrayOn = Self("\u{001B}[100m", "\u{001B}[0m")
    static let lightRedOn = Self("\u{001B}[101m", "\u{001B}[0m")
    static let lightGreenOn = Self("\u{001B}[102m", "\u{001B}[0m")
    static let lightYellowOn = Self("\u{001B}[103m", "\u{001B}[0m")
    static let lightBlueOn = Self("\u{001B}[104m", "\u{001B}[0m")
    static let lightMagentaOn = Self("\u{001B}[105m", "\u{001B}[0m")
    static let lightCyanOn = Self("\u{001B}[106m", "\u{001B}[0m")
}

extension String {
    func ansi(_ codeStyle: ANSICode) -> String {
        codeStyle.open + self.replacingOccurrences(of: ANSICode.reset.open, with: ANSICode.reset.open + codeStyle.open) + ANSICode.reset.open
    }

    func bold() -> String { ansi(ANSICode.bold) }
    func dim() -> String { ansi(ANSICode.dim) }
    func italic() -> String { ansi(ANSICode.italic) }
    func underline() -> String { ansi(ANSICode.underline) }
    func blink() -> String { ansi(ANSICode.blink) }
    func reverse() -> String { ansi(ANSICode.reverse) }
    func hidden() -> String { ansi(ANSICode.hidden) }
    func strikethrough() -> String { ansi(ANSICode.strikethrough) }
    func reset() -> String { "\u{001B}[0m" + self }

    func white() -> String { ansi(ANSICode.white) }
    func black() -> String { ansi(ANSICode.black) }
    func red() -> String { ansi(ANSICode.red) }
    func green() -> String { ansi(ANSICode.green) }
    func yellow() -> String { ansi(ANSICode.yellow) }
    func blue() -> String { ansi(ANSICode.blue) }
    func magenta() -> String { ansi(ANSICode.magenta) }
    func cyan() -> String { ansi(ANSICode.cyan) }
    func lightGray() -> String { ansi(ANSICode.lightGray) }
    func darkGray() -> String { ansi(ANSICode.darkGray) }
    func lightRed() -> String { ansi(ANSICode.lightRed) }
    func lightGreen() -> String { ansi(ANSICode.lightGreen) }
    func lightYellow() -> String { ansi(ANSICode.lightYellow) }
    func lightBlue() -> String { ansi(ANSICode.lightBlue) }
    func lightMagenta() -> String { ansi(ANSICode.lightMagenta) }
    func lightCyan() -> String { ansi(ANSICode.lightCyan) }

    func whiteon() -> String { ansi(ANSICode.whiteOn) }
    func blackon() -> String { ansi(ANSICode.blackOn) }
    func redon() -> String { ansi(ANSICode.redOn) }
    func greenon() -> String { ansi(ANSICode.greenOn) }
    func yellowon() -> String { ansi(ANSICode.yellowOn) }
    func blueon() -> String { ansi(ANSICode.blueOn) }
    func magentaon() -> String { ansi(ANSICode.magentaOn) }
    func cyanon() -> String { ansi(ANSICode.cyanOn) }
    func grayon() -> String { ansi(ANSICode.grayOn) }
    func darkgrayon() -> String { ansi(ANSICode.darkGrayOn) }
    func lightredon() -> String { ansi(ANSICode.lightRedOn) }
    func lightgreenon() -> String { ansi(ANSICode.lightGreenOn) }
    func lightyellowon() -> String { ansi(ANSICode.lightYellowOn) }
    func lightblueon() -> String { ansi(ANSICode.lightBlueOn) }
    func lightmagentaon() -> String { ansi(ANSICode.lightMagentaOn) }
    func lightcyanon() -> String { ansi(ANSICode.lightCyanOn) }
}

extension AppNameValidation {
    /// Suggests one or more names for valid App Fair app
    public func suggestNames(count: Int = 1) throws -> [String] {
        guard let nameURL = Bundle.fairApp.url(forResource: "appnames", withExtension: "json") else {
            throw CocoaError(.fileNoSuchFile)
        }
        let names = try JSONDecoder().decode(Dictionary<String, [String]>.self, from: Data(contentsOf: nameURL))

        var proposals: [String] = []
        for _ in 1...count {
            guard let noun = names.keys.randomElement() else {
                continue
            }

            guard let adj = names[noun]?.randomElement() else {
                continue
            }

            let proposal = adj.capitalized + "-" + noun.capitalized
            try validate(name: proposal) // make sure it passes
            proposals.append(proposal)
        }

        return proposals
    }

}
