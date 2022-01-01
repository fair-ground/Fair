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
import struct Foundation.URL
import struct Foundation.Date

/// A curated collection of projects
public enum FairCuration {
    public struct Platform: Pure {
        public let name: String
    }

    public struct PlatformVersion: Pure {
        public let name: String
        public let version: String
    }

    public struct Target: Pure {
        public let name: String
        public let moduleName: String?
    }

    public struct Product: Pure {
        public let name: String
        public let type: ProductType
        public let targets: [String]
    }

    public struct Compatibility: Pure {
        public let platform: Platform
        public let swiftVersion: String
    }

    public struct License: Pure {
        public let name: String?
        public let url: URL
    }

    public struct PackageCollection: Pure {
        public let name: String
        public let overview: String?
        public let keywords: [String]?
        public let packages: [PackageCollection.Package]
        public let formatVersion: Version
        public let revision: Int?
        public let generatedAt: Date
        public let generatedBy: Author?
        public let signature: Signature?

        public struct Author: Pure {
            public let name: String
        }

        public struct Package: Pure {
            public let url: URL
            public let summary: String?
            public let keywords: [String]?
            public let versions: [PackageCollection.Package.Version]
            public let readmeURL: URL?
            public let license: License?

            public struct Version: Pure {
                public let version: String
                public let summary: String?
                public let manifests: [String: Manifest]
                public let defaultToolsVersion: String
                public let verifiedCompatibility: [Compatibility]?
                public let license: License?
                public let createdAt: Date?

                public struct Manifest: Pure {
                    public let toolsVersion: String
                    public let packageName: String
                    public let targets: [Target]
                    public let products: [Product]
                    public let minimumPlatformVersions: [PlatformVersion]?
                }
            }
        }
    }

    public enum ProductType: Pure {
        public enum LibraryType: String, Pure {
            case `static`
            case dynamic
            case automatic
        }

        case library(LibraryType)
        case executable
        case plugin
        case test

        private enum CodingKeys: String, CodingKey {
            case library, executable, plugin, test
        }

        public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            switch self {
            case .executable:
                try container.encodeNil(forKey: .executable)
            case .plugin:
                try container.encodeNil(forKey: .plugin)
            case .test:
                try container.encodeNil(forKey: .test)
            case .library(let x):
                var unkeyedContainer = container.nestedUnkeyedContainer(forKey: .library)
                try unkeyedContainer.encode(x)
            }
        }

        public init(from decoder: Decoder) throws {
            let values = try decoder.container(keyedBy: CodingKeys.self)
            guard let key = values.allKeys.first(where: values.contains) else {
                throw DecodingError.dataCorrupted(.init(codingPath: decoder.codingPath, debugDescription: "No matching key"))
            }
            switch key {
            case .test:
                self = .test
            case .executable:
                self = .executable
            case .plugin:
                self = .plugin
            case .library:
                var vals = try values.nestedUnkeyedContainer(forKey: key)
                self = .library(try vals.decode(ProductType.LibraryType.self))
            }
        }
    }

    public struct Signature: Pure {
        public let signature: String
        public let certificate: Certificate

        public struct Certificate: Pure {
            public let subject: Name
            public let issuer: Name

            public struct Name: Pure {
                public let userID: String?
                public let commonName: String?
                public let organizationalUnit: String?
                public let organization: String?
            }
        }
    }

    public enum Version: String, Pure {
        case v1_0 = "1.0"
    }
}
