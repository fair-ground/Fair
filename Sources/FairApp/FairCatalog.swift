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
import FairCore
import Foundation

// MARK: Serializable Structures

/// A catalog of apps, consisting of a ``name``, ``identifier``,
/// individual ``AppCatalogItem`` instances for each app indexed by this catalog,
/// as well as optional ``AppNewsPost`` items.
public struct AppCatalog : Codable {
    /// The name of the catalog (e.g., "App Name")
    public var name: String
    /// The identifier for the catalog (e.g., "app.App-Name")
    public var identifier: String
    /// The canonical location of the catalog
    public var sourceURL: URL?
    /// The apps that are currently available
    public var apps: [AppCatalogItem]
    /// Any news items for the catalog
    public var news: [AppNewsPost]?
    /// The sources of funding that are available to apps in this catalog
    public var fundingSources: [AppFundingSource]?

    public init(name: String, identifier: String, sourceURL: URL? = nil, apps: [AppCatalogItem], news: [AppNewsPost]? = nil, fundingSources: [AppFundingSource]? = nil) {
        self.name = name
        self.identifier = identifier
        self.sourceURL = sourceURL
        self.apps = apps
        self.news = news
        self.fundingSources = fundingSources
    }
}

public extension AppCatalog {
    /// Parses the `AppCatalog` with the expected parameters (i.e., date encoding as iso8601).
    static func parse(jsonData: Data) throws -> Self {
        try AppCatalog(json: jsonData, dateDecodingStrategy: .iso8601)
    }
}

/// An individual App Source Catalog item, defining the name, identifier, and downloadURL of an application archive.
public struct AppCatalogItem : Codable {
    /// The name of the app (e.g., "Cloud Cuckoo")
    public var name: String
    /// The identifier for the app (e.g., "app.Cloud-Cuckoo")
    public var bundleIdentifier: String
    /// A subtitle
    public var subtitle: String?
    /// The real name and e-mail address of the developer of the app
    public var developerName: String?
    /// A localized description of the app, such as markdown
    public var localizedDescription: String?
    /// The size of the app's primary download url
    public var size: Int?
    /// The current version of the app
    public var version: String?
    /// The date the version was released
    public var versionDate: Date?
    /// The primary URL for the app download
    public var downloadURL: URL
    /// The URL for the app's icons
    public var iconURL: URL?
    /// The primary screenshot URLs for the app
    public var screenshotURLs: [URL]?
    /// A summary of the version
    public var versionDescription: String?
    /// The custom tint color for the app
    public var tintColor: String?
    /// Whether to app is beta or not
    public var beta: Bool?

    /// The categories assigned to this app
    public var categories: [String]?
    /// The number of downloads for this asset
    public var downloadCount: Int?
    /// The number of views for the catalog item
    public var viewCount: Int?
    /// The number of impression for the catalog item
    public var impressionCount: Int?
    /// The number of stargazers for this project
    public var starCount: Int?
    /// The number of followers for this project
    public var watcherCount: Int?
    /// The number of forks for this project
    public var forkCount: Int?
    /// The number of issues for this project
    public var issueCount: Int?

    /// The size of the core code
    public var coreSize: Int?

    /// The expected hash of the downloadURL
    public var sha256: String?

    /// The summary of the entitlements that are enabled for this app
    public var permissions: [AppPermission]?

    /// The URL for the app's metadata
    public var metadataURL: URL?

    /// The URL for the app's README
    public var readmeURL: URL?

    /// The URL for the app's `RELEASE_NOTES`
    public var releaseNotesURL: URL?

    /// The URL for the app's homepage
    public var homepage: URL?

    /// The summary of the entitlements that are enabled for this app
    public var fundingLinks: [AppFundingLink]?

    public init(name: String, bundleIdentifier: String, subtitle: String? = nil, developerName: String? = nil, localizedDescription: String? = nil, size: Int? = nil, version: String? = nil, versionDate: Date? = nil, downloadURL: URL, iconURL: URL? = nil, screenshotURLs: [URL]? = nil, versionDescription: String? = nil, tintColor: String? = nil, beta: Bool? = nil, categories: [String]? = nil, downloadCount: Int? = nil, impressionCount: Int? = nil, viewCount: Int? = nil, starCount: Int? = nil, watcherCount: Int? = nil, issueCount: Int? = nil, coreSize: Int? = nil, sha256: String? = nil, permissions: [AppPermission]? = nil, metadataURL: URL? = nil, readmeURL: URL? = nil, releaseNotesURL: URL? = nil, homepage: URL? = nil, fundingLinks: [AppFundingLink]? = nil) {
        self.name = name
        self.bundleIdentifier = bundleIdentifier
        self.subtitle = subtitle
        self.developerName = developerName
        self.localizedDescription = localizedDescription
        self.size = size
        self.version = version
        self.versionDate = versionDate
        self.downloadURL = downloadURL
        self.iconURL = iconURL
        self.screenshotURLs = screenshotURLs
        self.versionDescription = versionDescription
        self.tintColor = tintColor
        self.beta = beta
        self.categories = categories
        self.downloadCount = downloadCount
        self.impressionCount = impressionCount
        self.viewCount = viewCount
        self.starCount = starCount
        self.watcherCount = watcherCount
        self.issueCount = issueCount
        self.coreSize = coreSize
        self.sha256 = sha256
        self.permissions = permissions
        self.metadataURL = metadataURL
        self.readmeURL = readmeURL
        self.releaseNotesURL = releaseNotesURL
        self.homepage = homepage
        self.fundingLinks = fundingLinks
    }
}

/// A link to a particular funding platform.
public struct AppFundingLink : Codable {
    /// E.g., "GITHUB" or "PATREON"
    ///
    /// This list should be harmonized with the funding platforms defined in [FundingPlatform](https://docs.github.com/en/graphql/reference/enums#fundingplatform)
    public var platform: AppFundingPlatform
    /// E.g., https://patreon.com/SomeCreator or https://github.com/Some-App-Org
    public var url: URL
    /// The title of this funding, such as "Support this Creator on Patreon" or "Sponsor the Developer on GitHub".
    public var localizedTitle: String?
    /// The description
    public var localizedDescription: String?

    public init(platform: AppFundingPlatform, url: URL, localizedTitle: String? = nil, localizedDescription: String? = nil) {
        self.platform = platform
        self.url = url
        self.localizedTitle = localizedTitle
        self.localizedDescription = localizedDescription
    }
}

/// A link to a particular funding platform.
public struct AppFundingSource : Codable {
    /// E.g., "GITHUB" or "PATREON"
    ///
    /// This list should be harmonized with the funding platforms defined in [FundingPlatform](https://docs.github.com/en/graphql/reference/enums#fundingplatform)
    public var platform: AppFundingPlatform
    /// E.g., https://patreon.com/SomeCreator or https://github.com/Some-App-Org
    public var url: URL
    /// The currently active goals that can be funded
    public let goals: [FundingGoal]

    public init(platform: AppFundingPlatform, url: URL, goals: [AppFundingSource.FundingGoal]) {
        self.platform = platform
        self.url = url
        self.goals = goals
    }

    /// A funding goal, such as reaching a certain monthly donation amount or sponsorship count.
    public struct FundingGoal : Codable {
        public var kind: String // e.g. TOTAL_SPONSORS_COUNT or MONTHLY_SPONSORSHIP_AMOUNT
        public var title: String?
        public var description: String?
        public var percentComplete: Double?
        public var targetValue: Double?

        public init(kind: String, title: String? = nil, description: String? = nil, percentComplete: Double? = nil, targetValue: Double? = nil) {
            self.kind = kind
            self.title = title
            self.description = description
            self.percentComplete = percentComplete
            self.targetValue = targetValue
        }
    }
}


/// A funding platform, which is represented by a raw string.
///
/// Known platforms can be accessed with ``allCases``.
public struct AppFundingPlatform : RawCodable, Hashable {
    public var rawValue: String
    public init(rawValue: String) { self.rawValue = rawValue }
}


/// An individual item of news, consiting of a unique identifier, a date, title, caption, and optional additional properties.
public struct AppNewsPost : Codable {
    /// A unique identifer for the news posting
    public var identifier: String
    /// The date of the news
    public var date: String // can be either "2022-05-05" or "2020-04-10T13:30:00-07:00"
    /// The title for the news
    public var title: String
    /// A news caption
    public var caption: String
    /// Whether the news item should trigger a notification by default
    public var notify: Bool?
    /// The tint color for the news item
    public var tintColor: String?
    /// A URL with more details
    public var url: String?
    /// An image summarizing the news item
    public var imageURL: String?
    /// An app-id to which the news item refers
    public var appID: String?

    public init(identifier: String, date: String, title: String, caption: String, notify: Bool? = nil, tintColor: String? = nil, url: String? = nil, imageURL: String? = nil, appID: String? = nil) {
        self.identifier = identifier
        self.date = date
        self.title = title
        self.caption = caption
        self.notify = notify
        self.tintColor = tintColor
        self.url = url
        self.imageURL = imageURL
        self.appID = appID
    }
}


// MARK: Extensions


extension AppFundingPlatform : CaseIterable {
    /// All the known funding platforms, both supported and unsupported.
    ///
    /// - See: ``isSupported``
    public static let allCases: [AppFundingPlatform] = [
        .COMMUNITY_BRIDGE,
        .GITHUB,
        .ISSUEHUNT,
        .KO_FI,
        .LIBERAPAY,
        .OPEN_COLLECTIVE,
        .OTECHIE,
        .PATREON,
        .TIDELIFT,
        //.CUSTOM
    ]

    /// GitHub funding platform. [https://github.com/](https://github.com/)
    public static let GITHUB = AppFundingPlatform(rawValue: "GITHUB")

    /// Patreon funding platform. [https://patreon.com](https://patreon.com)
    public static let PATREON = AppFundingPlatform(rawValue: "PATREON")

    /// Community Bridge funding platform: [https://funding.communitybridge.org](https://funding.communitybridge.org)
    public static let COMMUNITY_BRIDGE = AppFundingPlatform(rawValue: "COMMUNITY_BRIDGE")

    /// IssueHunt funding platform. [https://issuehunt.io](https://issuehunt.io)
    public static let ISSUEHUNT = AppFundingPlatform(rawValue: "ISSUEHUNT")

    /// Ko-fi funding platform. [https://ko-fi.com](https://ko-fi.com)
    public static let KO_FI = AppFundingPlatform(rawValue: "KO_FI")

    /// Liberapay funding platform. [https://liberapay.com](https://liberapay.com)
    public static let LIBERAPAY = AppFundingPlatform(rawValue: "LIBERAPAY")

    /// Open Collective funding platform. [https://opencollective.com](https://opencollective.com)
    public static let OPEN_COLLECTIVE = AppFundingPlatform(rawValue: "OPEN_COLLECTIVE")

    /// Otechie funding platform. [https://otechie.com](https://otechie.com)
    public static let OTECHIE = AppFundingPlatform(rawValue: "OTECHIE")

    /// Tidelift funding platform. [https://tidelift.com](https://tidelift.com)
    public static let TIDELIFT = AppFundingPlatform(rawValue: "TIDELIFT")

    /// Custom funding platform. Not supported
    @available(*, unavailable, message: "custom funding sources are not supported")
    static let CUSTOM = AppFundingPlatform(rawValue: "CUSTOM")

    /// Returns `true` if the funding platform is known and supported.
    public var isSupported: Bool {
        switch self {
        case .GITHUB: return true
        case .PATREON: return true

        case .KO_FI: return false
        case .OTECHIE: return false
        case .TIDELIFT: return false
        case .ISSUEHUNT: return false
        case .LIBERAPAY: return false
        case .OPEN_COLLECTIVE: return false
        case .COMMUNITY_BRIDGE: return false

        case _: return false
        }
    }

    /// The localized name of the funding platform
    public var platformName: String? {
        switch self {
        case .GITHUB: return NSLocalizedString("GitHub", bundle: .module, comment: "funding platform name for GitHub")
        case .COMMUNITY_BRIDGE: return NSLocalizedString("Community Bridge", bundle: .module, comment: "funding platform name for Community Bridge")
        case .ISSUEHUNT: return NSLocalizedString("IssueHunt", bundle: .module, comment: "funding platform name for IssueHunt")
        case .KO_FI: return NSLocalizedString("Ko-fi", bundle: .module, comment: "funding platform name for Ko-fi")
        case .LIBERAPAY: return NSLocalizedString("Liberapay", bundle: .module, comment: "funding platform name for Liberapay")
        case .OPEN_COLLECTIVE: return NSLocalizedString("Open Collective", bundle: .module, comment: "funding platform name for Open Collective")
        case .OTECHIE: return NSLocalizedString("Otechie", bundle: .module, comment: "funding platform name for Otechie")
        case .PATREON: return NSLocalizedString("Patreon", bundle: .module, comment: "funding platform name for Patreon")
        case .TIDELIFT: return NSLocalizedString("Tidelift", bundle: .module, comment: "funding platform name for Tidelift")
        case _: return nil
        }
    }

    /// Checks that the given link is valid for the known funding platform
    public func serviceIdentifier(from url: URL) -> String? {
        func trimming(_ source: String) -> String? {
            let urlString = url.absoluteString
            if !urlString.hasPrefix(source) { return nil }
            return urlString.dropFirst(source.count).description
        }

        switch self {
        case .GITHUB: return trimming("https://github.com/") // USERNAME
        case .COMMUNITY_BRIDGE: return trimming("https://funding.communitybridge.org/projects/") // PROJECT-NAME
        case .ISSUEHUNT: return trimming("https://issuehunt.io/r/") // USERNAME
        case .KO_FI: return trimming("https://ko-fi.com/") // USERNAME
        case .LIBERAPAY: return trimming("https://liberapay.com/") // USERNAME
        case .OPEN_COLLECTIVE: return trimming("https://opencollective.com/") // USERNAME
        case .OTECHIE: return trimming("https://otechie.com/") // USERNAME
        case .PATREON: return trimming("https://patreon.com/") // USERNAME
        case .TIDELIFT: return trimming("https://tidelift.com/funding/") // github/PLATFORM-NAME/PACKAGE-NAME
        case _: return nil // unknown platform is never valid
        }
    }

    /// A URL is valid for a specific funding source if it matches a known pattern and the platform is supported
    public func isValidURL(_ url: URL) -> Bool {
        isSupported && (serviceIdentifier(from: url) != nil)
    }
}

extension AppFundingLink {
    /// Checks that the given link is valid for the known funding platform
    public func isValidFundingURL() -> Bool {
        self.platform.isValidURL(self.url)
    }

    public var fundingURL: URL? {
        guard let id = self.platform.serviceIdentifier(from: self.url) else {
            return nil // not a supported platform
        }

        switch self.platform {
        case .GITHUB: return URL(string: "http://github.com/sponsors/\(id)")
        default: return self.url // default platform just uses the identifier link directly
        }
    }
}

extension AppCatalogItem {
    var fundingLinksValidated: [AppFundingLink]? {
        self.fundingLinks?.filter({ $0.isValidFundingURL() })
    }
}


public extension AppCatalogItem {

    /// The hyphenated form of this app's name
    var appNameHyphenated: String {
        self.name.rehyphenated()
    }

    /// The official landing page for the app
    var landingPage: URL! {
        URL(string: "https://\(appNameHyphenated).github.io/App/")
    }

    /// Returns the URL to this app's home page
    var projectURL: URL! {
        URL(string: "https://github.com/\(appNameHyphenated)/App/")
    }

    /// The e-mail address for contacting the developer
    var developerEmail: String? {
        developerName // TODO: parse out
    }

    /// Returns the URL to this app's home page
    var sourceURL: URL! {
        projectURL.appendingPathExtension("git")
    }

    var issuesURL: URL! {
        URL(string: "issues", relativeTo: projectURL)
    }

    var discussionsURL: URL! {
        URL(string: "discussions", relativeTo: projectURL)
    }

    var stargazersURL: URL! {
        URL(string: "stargazers", relativeTo: projectURL)
    }

    var sponsorsURL: URL? {
        self.fundingLinks?.first?.fundingURL
        //wip(nil)
        //URL(string: wip("sponsors"), relativeTo: projectURL)
    }

    var releasesURL: URL! {
        URL(string: "releases/", relativeTo: projectURL)
    }

    var developerURL: URL! {
        queryURL(type: "users", term: developerEmail ?? "")
    }

    var fairsealURL: URL! {
        queryURL(type: "issues", term: sha256 ?? "")
    }

    /// Builds a general query
    private func queryURL(type: String, term: String) -> URL! {
        URL(string: "https://github.com/search?type=" + type.escapedURLTerm + "&q=" + term.escapedURLTerm)
    }

    var fileSize: Int? {
        size
    }

    var appCategories: [AppCategory] {
        self.categories?.compactMap(AppCategory.init(metadataID:)) ?? []
    }
}



// MARK: Utilities

/// The strategy for validating an app's name
public struct AppNameValidation {
    /// The default app name validation strategy
    public static var standard: Self = AppNameValidation()

    /// The characters that are permitted in an app's name
    public var permittedCharacters: CharacterSet? = CharacterSet.alphanumerics.subtracting(CharacterSet.decimalDigits)

    /// The lengths of the words that are permitted
    public var wordLengths: [ClosedRange<Int>]? = [3...12, 3...12, 3...12, 3...12]

    /// Validates that the given name satisfies the name validation algorithm
    public func validate(name: String) throws {
        let words = name.split(separator: "-", omittingEmptySubsequences: false)

        if let wordLengths = wordLengths {
            if words.count > wordLengths.count {
                throw Errors.badWordCount(name, words.count, wordLengths.count)
            }

            if Set(words).count != words.count {
                //throw Errors.nonUniqueWords(name)
            }

            for (word, lengthRange) in zip(words, wordLengths) {
                if !lengthRange.contains(word.count) {
                    throw Errors.badWordLength(name, String(word), lengthRange)
                }

                if let permittedCharacters = permittedCharacters {
                    for c in word {
                        for s in c.unicodeScalars {
                            if !permittedCharacters.contains(s) {
                                throw Errors.badCharacter(name, c)
                            }
                        }
                    }
                }
            }
        }
    }

    public enum Errors : LocalizedError {
        case badWordCount(String, Int, Int)
        case badWordLength(String, String, ClosedRange<Int>)
        case badCharacter(String, Character)
        case nonUniqueWords(String)

        public var errorDescription: String? {
            switch self {
            case .badWordCount(let appName, let min, _):
                return "Invalid number of words in name that requires \(min) words separated by a hyphen: \"\(appName)\""
            case .badWordLength(let appName, _, _):
                return "Bad word length in name: \"\(appName)\""
            case .badCharacter(let appName, _):
                return "Invalid or unsafe character in name: \"\(appName)\""
            case .nonUniqueWords(let appName):
                return "Words must be distinct in name: \"\(appName)\""
            }
        }
    }
}
