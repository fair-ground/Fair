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

/// A catalog of all the available apps on the fairground.
public struct FairAppCatalog : Pure {
    /// The name of the catalog (e.g., "App Name")
    public var name: String
    /// The identifier for the catalog (e.g., "app.App-Name")
    public var identifier: String
    /// The canonical location of the catalog
    public var sourceURL: URL?
    /// The apps that are currently available
    public var apps: [AppCatalogItem]
    /// Any news items for the catalog
    public var news: [NewsPost]?

    public struct NewsPost : Pure {
        /// A unique identifer for the news posting
        public var identifier: String
        /// The date of the news
        public var date: Date
        /// The title for the news
        public var title: String
        /// A news caption
        public var caption: String
        /// Whether the news item should trigger a notification by default
        public var notify: Bool?
        /// The tint color for the news item
        public var tintColor: String?
        /// A URL with more details
        public var url: URL?
        /// An image summarizing the news item
        public var imageURL: URL?
        /// An app-id to which the news item refers
        public var appID: String?
        /// The source identifier
        public var sourceIdentifier: String?
    }
}

public struct AppCatalogItem : Pure {
    /// The name of the app (e.g., "Cloud Cuckoo")
    public var name: String
    /// The identifier for the all (e.g., "app.Cloud-Cuckoo")
    public var bundleIdentifier: String
    /// A subtitle
    public var subtitle: String?
    /// The real name and e-mail address of the developer of the app
    public var developerName: String
    /// A localized description of the app, such as markdown
    public var localizedDescription: String
    /// The size of the app's primary download url
    public var size: Int
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
    /// The source identifier of the app
    public var sourceIdentifier: String?

    /// The categories assigned to this app
    public var categories: [String]?
    /// The number of downloads for this asset
    public var downloadCount: Int?
    /// The number of stargazers for this project
    public var starCount: Int?
    /// The number of followers for this project
    public var watcherCount: Int?
    /// The number of forks for this project
    public var forkCount: Int?
    /// The number of issues for this project
    public var issueCount: Int?
    /// The total size of the source assets for this project
    public var sourceSize: Int?
    /// The size of the core code
    public var coreSize: Int?

    /// The expected hash of the downloadURL
    public var sha256: String?

    /// The summary of the entitlements that are enabled for this app
    public var permissions: [AppPermission]?

    /// The URL for the app's metadata
    public var metadataURL: URL?

    /// The SHA256 checksum of the validated metadata
    public var sha256Metadata: String?

    public init(name: String, bundleIdentifier: String, subtitle: String?, developerName: String, localizedDescription: String, size: Int, version: String?, versionDate: Date?, downloadURL: URL, iconURL: URL?, screenshotURLs: [URL]?, versionDescription: String?, tintColor: String?, beta: Bool?, sourceIdentifier: String?, categories: [String]?, downloadCount: Int?, starCount: Int?, watcherCount: Int?, issueCount: Int?, sourceSize: Int?, coreSize: Int?, sha256: String?, permissions: [AppPermission]?, metadataURL: URL?, sha256Metadata: String?) {
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
        self.sourceIdentifier = sourceIdentifier
        self.categories = categories
        self.downloadCount = downloadCount
        self.starCount = starCount
        self.watcherCount = watcherCount
        self.issueCount = issueCount
        self.sourceSize = sourceSize
        self.coreSize = coreSize
        self.sha256 = sha256
        self.permissions = permissions
        self.metadataURL = metadataURL
        self.sha256Metadata = sha256Metadata
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

/// The strategy for validating an app's name
public struct AppNameValidation {
    /// The name of the default app framework
    public static let defaultAppName = "App"


    /// The default app name validation strategy
    public static var standard: Self = AppNameValidation()

    /// The characters that are permitted in an app's name
    public var permittedCharacters: CharacterSet? = CharacterSet.alphanumerics.subtracting(CharacterSet.decimalDigits)

    /// The lengths of the words that are permitted
    public var wordLengths: [ClosedRange<Int>]? = [3...12, 3...12]

    /// Validates that the given name satisfies the name validation algorithm
    public func validate(name: String) throws {
        let words = name.split(separator: "-", omittingEmptySubsequences: false)

        if let wordLengths = wordLengths {
            if words.count != wordLengths.count {
                throw Errors.badWordCount(name, words.count, wordLengths.count)
            }

            if Set(words).count != words.count {
                throw Errors.nonUniqueWords(name)
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

/// The contents of a `Package.resolved` file
public struct ResolvedPackage: Codable, Equatable {
    public var object: Pins
    public var version: Int

    public struct Pins: Codable, Equatable {
        public var pins: [SwiftPackage]
    }

    public struct SwiftPackage: Codable, Equatable {
        public var package: String
        public var repositoryURL: String
        public var state: State

        public struct State: Codable, Equatable {
            public var branch: String?
            public var revision: String?
            public var version: String?
        }
    }
}
