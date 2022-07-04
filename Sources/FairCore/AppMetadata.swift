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
/// https://developer.apple.com/documentation/bundleresources/information_property_list/bundle_configuration
public enum InfoPlistKey : String, CaseIterable, Hashable {
    case CFBundleIdentifier // e.g., "app.My-App"
    case CFBundleExecutable // e.g., "My App"
    case CFBundleName // e.g., "My App"
    case CFBundleDisplayName // e.g., "My App"
    case CFBundleVersion // e.g., 699162671
    case CFBundleShortVersionString

    case CFBundlePackageType // e.g., "APPL"
    case CFBundleSupportedPlatforms // e.g., ["iPhoneOS"]
    case CFBundleInfoDictionaryVersion // e.g., 6.0

    case CFBundleIconName // e.g., "AppIcon"
    case CFBundleIcons
    case CFBundlePrimaryIcon
    case CFBundleIconFiles

    case NSHumanReadableCopyright

    case DTSDKName // e.g., "iphoneos15.0" or "macosx12.0"
    case DTSDKBuild // e.g., 19A5297f

    case DTPlatformBuild // e.g., 19A5297f
    case DTPlatformVersion // e.g., 15.0 or 12.0
    case DTPlatformName // e.g., "iphoneos" or "macosx"
    case DTCompiler // e.g., "com.apple.compilers.llvm.clang.1_0"

    case DTXcode // e.g., 1300
    case DTXcodeBuild // e.g., "13A5192j"

    case LSMinimumSystemVersion
    case LSApplicationCategoryType
    case LSFileQuarantineEnabled
    case LSBackgroundOnly
    case LSUIElement
    case LSUIPresentationMode

    case MinimumOSVersion
    case BuildMachineOSBuild // e.g., 20G71

    case UIDeviceFamily // e.g., [1,2]
    case UIRequiredDeviceCapabilities
    case UISupportedInterfaceOrientations // e.g., [UIInterfaceOrientationPortrait, UIInterfaceOrientationPortraitUpsideDown, UIInterfaceOrientationLandscapeLeft, UIInterfaceOrientationLandscapeRight]

    /// Returns the key for the plist
    public var plistKey: String {
        rawValue
    }
}

/// A version of an app with a `major`, `minor`, and `patch` component.
public struct AppVersion : Pure, Comparable {
    /// The lowest possible version that can exist
    public static let min = AppVersion(major: .min, minor: .min, patch: .min, prerelease: true)
    /// The highest possible version that can exist
    public static let max = AppVersion(major: .max, minor: .max, patch: .max, prerelease: false)

    public let major, minor, patch: UInt
    public let prerelease: Bool

    public init(major: UInt, minor: UInt, patch: UInt, prerelease: Bool) {
        self.major = major
        self.minor = minor
        self.patch = patch
        self.prerelease = prerelease
    }

    /// Initialize the version by parsing the string
    public init?(string versionString: String, prerelease: Bool) {
        guard let version = Self.parse(string: versionString, prerelease: prerelease) else {
            return nil
        }
        self = version
    }

    private static func parse(string versionString: String, prerelease: Bool) -> Self? {
        let versionElements = versionString.split(separator: ".", omittingEmptySubsequences: false).map({ UInt(String($0)) })
        if versionElements.count != 3 { return nil }
        let versionNumbers = versionElements.compactMap({ $0 })
        if versionNumbers.count != 3 { return nil }


        let major = versionNumbers[0]
        let minor = versionNumbers[1]
        let patch = versionNumbers[2]
        let prerelease = prerelease

        let version = Self(major: major, minor: minor, patch: patch, prerelease: prerelease)

        // this is what prevents us from successfully parsing ".1.2.3"
        if !version.versionString.hasPrefix("\(version.major)") { return nil }
        if !version.versionString.hasSuffix("\(version.patch)") { return nil }

        return version
    }

    public static func < (lhs: AppVersion, rhs: AppVersion) -> Bool {
        lhs.major < rhs.major
            || (lhs.major == rhs.major && lhs.minor < rhs.minor)
            || (lhs.major == rhs.major && lhs.minor == rhs.minor && lhs.patch < rhs.patch)
        || (lhs.major == rhs.major && lhs.minor == rhs.minor && lhs.patch == rhs.patch && (lhs.prerelease ? 0 : 1) < (rhs.prerelease ? 0 : 1))

    }

    /// The version string in the form `major`.`minor`.`patch`
    public var versionString: String {
        "\(major).\(minor).\(patch)"
    }

    /// The version string in the form `major`.`minor`.`patch` with a "β" character appended if this is a pre-release
    public var versionStringExtended: String {
        versionString + (prerelease == true ? "β" : "")
    }

    public func encode(to encoder: Encoder) throws {
        try versionStringExtended.encode(to: encoder)
    }

    public init(from decoder: Decoder) throws {
        let str = try decoder.singleValueContainer().decode(String.self)
        let version = Self.init(string: str, prerelease: false)
        guard let version = version else {
            throw Errors.cannotParseVersionString(str)
        }
        self = version
    }

    public enum Errors : Error {
        case cannotParseVersionString(String)
    }
}
