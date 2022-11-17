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
import Swift
import FairApp

/// The collection of URLs associated with an F-Droid API endpoint.
public struct FDroidEndpoint {
    /// The default base for the droid catalog API
    public static let defaultEndpoint = URL(string: "https://f-droid.org/repo/index-v2.json")!

    /// The base endpoint for casks
    public let endpoint: URL

    public init(endpoint: URL) {
        self.endpoint = endpoint
    }
}

/// Version 2 of the F-Droid index format.
///
/// Sample catalog at: [https://f-droid.org/repo/index-v2.json]()
///
/// Based on the Kotlin data classes at:
/// [https://gitlab.com/fdroid/fdroidclient/-/tree/master/libs/index/src/commonMain/kotlin/org/fdroid/index/v2]()
///
/// Python generation code at: [https://gitlab.com/fdroid/fdroidserver/-/blob/master/fdroidserver/index.py#L516]()
struct FDroidIndex : Codable, Equatable {
    var repo: Repo
    var packages: Dictionary<String, Package>

    /// A map of language code to the translated text. E.g.: `["en-US": "Name", "fr-FR": "Nom"]`
    typealias LocalizedText = Dictionary<String, String>

    /// A map of language code to the file resource. E.g.: `["en-US": "images/icon/english.svg", "fr-FR": "images/icon/french.svg"]`
    typealias LocalizedFile = Dictionary<String, File>

    /// A map of language code to a file resource set.
    ///
    /// E.g.:
    ///
    /// ```
    /// "en-US": [
    /// {
    ///   "name": "/app.id/en-US/phoneScreenshots/screen_1.png",
    ///   "sha256": "9bd71cbed1c2224d4d7a27e12f4ff6b5326605c11cc0ca9d2bb887b50949d110",
    ///   "size": 112122
    /// }
    /// ]
    /// ```
    ///
    typealias LocalizedFileList = Dictionary<String, Array<File>>

    /// A reference to a resource path
    struct File : Codable, Equatable {
        var name: String?
        var sha256: String?
        var size: Int64?
    }

    struct Entry : Codable, Equatable {
        var timestamp: Int64
        var version: Int64
        var maxAge: Int?
        var index: EntryFile
        var diffs: Dictionary<String, EntryFile>
    }

    struct EntryFile : Codable, Equatable {
        var name: String
        var sha256: String
        var size: Int64
        var numPackages: Int
    }

    struct Repo : Codable, Equatable {
        var name: LocalizedText
        var icon: LocalizedFile
        var address: String
        var webBaseUrl: String?
        var description: LocalizedText?
        var mirrors: Array<Mirror>
        var timestamp: Int64
        var antiFeatures: Dictionary<String, AntiFeature>?
        var categories: Dictionary<String, Category>?
        var releaseChannels: Dictionary<String, ReleaseChannel>?
    }

    struct Mirror : Codable, Equatable {
        var url: String
        var location: String?
        var isPrimary: Bool? // undocumented
    }

    struct AntiFeature : Codable, Equatable {
        // icon encoded wrong: https://gitlab.com/fdroid/fdroidclient/-/merge_requests/1139
        // var icon: File?
        var icon: LocalizedFile?
        var name: LocalizedText
        var description: LocalizedText?
    }

    struct Category : Codable, Equatable {
        // icon encoded wrong: https://gitlab.com/fdroid/fdroidclient/-/merge_requests/1139
        // var icon: File?
        var icon: LocalizedFile?
        var name: LocalizedText
        var description: LocalizedText?
    }

    struct ReleaseChannel : Codable, Equatable {
        var name: LocalizedText
        var description: LocalizedText?
    }

    struct Package : Codable, Equatable {
        var metadata: Metadata
        /// A of versions, keyed by the sha256 of the primary artifact.
        var versions: Dictionary<String, PackageVersion>

        struct Metadata : Codable, Equatable {
            var name: LocalizedText?
            var summary: LocalizedText?
            var description: LocalizedText?
            var added: Int64
            var lastUpdated: Int64
            var webSite: String?
            var changelog: String?
            var license: String?
            var sourceCode: String?
            var issueTracker: String?
            var translation: String?
            var preferredSigner: String?
            var categories: Array<String>?
            var authorName: String?
            var authorEmail: String?
            var authorWebSite: String?
            var authorPhone: String?
            var donate: Array<String>?
            var liberapayID: String?
            var liberapay: String?
            var openCollective: String?
            var bitcoin: String?
            var litecoin: String?
            var flattrID: String?
            var icon: LocalizedFile?
            var featureGraphic: LocalizedFile?
            var promoGraphic: LocalizedFile?
            var tvBanner: LocalizedFile?
            var video: LocalizedText?
            var screenshots: Screenshots?
        }

        struct Screenshots : Codable, Equatable {
            var phone: LocalizedFileList?
            var sevenInch: LocalizedFileList?
            var tenInch: LocalizedFileList?
            var wear: LocalizedFileList?
            var tv: LocalizedFileList?
        }

        // public interface PackageVersion {
        //     public val versionCode: Long
        //     public val signer: Signer?
        //     public val releaseChannels: List<String>?
        //     public val packageManifest: PackageManifest
        //     public val hasKnownVulnerability: Boolean
        // }

        struct PackageVersion : Codable, Equatable {
            var added: Int64
            var file: FileV1
            var src: File?
            var manifest: Manifest
            var releaseChannels: Array<String>?
            var antiFeatures: Dictionary<String, LocalizedText>?
            var whatsNew: LocalizedText?
        }

        struct FileV1 : Codable, Equatable {
            var name: String
            var sha256: String
            var size: Int64?
        }

        // public interface PackageManifest {
        //     public val minSdkVersion: Int?
        //     public val maxSdkVersion: Int?
        //     public val featureNames: List<String>?
        //     public val nativecode: List<String>?
        // }

        struct Manifest : Codable, Equatable {
            var versionName: String
            var versionCode: Int64
            var usesSdk: UsesSdk?
            var maxSdkVersion: Int?
            var signer: Signer?
            var usesPermission: Array<Permission>?
            var usesPermissionSdk23: Array<Permission>?
            var nativecode: Array<String>?
            var features: Array<Feature>?
        }

        struct UsesSdk : Codable, Equatable {
            var minSdkVersion: Int
            var targetSdkVersion: Int
        }

        struct Signer : Codable, Equatable {
            var sha256: Array<String>
            var hasMultipleSigners: Bool?
        }

        struct Permission : Codable, Equatable {
            var name: String
            var maxSdkVersion: Int?
        }

        struct Feature : Codable, Equatable {
            var name: String
        }
    }
}

