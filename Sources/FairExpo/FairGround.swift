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
import FairApp

/// A Fair Ground is a platform for app distribution
public enum FairGround {
    /// A fairground that uses hosted git repository with a REST API,
    /// such as github.com
    case hub(FairHub)

    /// The `FairHub` for repositories that use that model
    public var hub: FairHub? {
        switch self {
        case .hub(let x): return x
        }
    }
}

/// The seal of the given URL, summarizing its cryptographic hash, entitlements,
/// and other build-time information
public struct FairSeal : Codable, Hashable, JSONSignable {
    // legacy fields that have been removed:
    /// The version of the fairseal JSON
    // public private(set) var fairsealVersion: Version?
    // public enum Version : Int, Pure, CaseIterable { case v1 = 1 }

    /// The version of the fairtool library that initially created this seal
    public internal(set) var generatorVersion: AppVersion?

    /// The permission for this app
    public var permissions: [AppPermission]?
    /// The size of the artifact's executable binary
    public var coreSize: Int?
    /// The tint color as an RGBA hex string
    public var tint: String?
    /// The sealed assets
    public var assets: [Asset]?
    /// The AppSource metadata from the Info.plist
    public var appSource: AppCatalogItem?
    /// The signature for this payload, authenticating the fairseal issuer with HMAC-256
    public var signature: Data?

    public struct Asset : Pure {
        /// The asset's URL
        public var url: URL
        /// The asset's size in bytes
        public var size: Int
        /// The validated sha256 checksum for the asset contents
        public var sha256: String

        public init(url: URL, size: Int, sha256: String) {
            self.url = url
            self.size = size
            self.sha256 = sha256
        }
    }

    public var signatureData: Data? {
        get { signature }
        set { signature = newValue }
    }

    public init(assets: [Asset]? = nil, permissions: [AppPermission]? = nil, appSource: AppCatalogItem? = nil, coreSize: Int? = nil, tint: String? = nil) {
        self.generatorVersion = Bundle.fairCoreVersion
        //self.fairsealVersion = Version.allCases.last!

        self.assets = assets
        self.permissions = permissions
        self.appSource = appSource
        self.coreSize = coreSize
        self.tint = tint
    }

    /// The app org associated with this seal; this will be the first component of the first URL's path
    public var appOrg: String? {
        assets?.first?.url.path.split(separator: "/").first?.description
    }
}

extension URL {
    /// Adds a hash with the given string to the end of the URL
    func appendingHash(_ hashString: String?) -> URL {
        guard let hashString = hashString else { return self }
        return URL(string: self.absoluteString + "#" + hashString) ?? self
    }
}
