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
#if canImport(QuartzCore)
import QuartzCore
#endif

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

    case DTSDKName // e.g., "iphoneos15.0" or "macosx12.0"
    case DTSDKBuild // e.g., 19A5297f

    case DTPlatformBuild // e.g., 19A5297f
    case DTPlatformVersion // e.g., 15.0 or 12.0
    case DTPlatformName // e.g., "iphoneos" or "macosx"
    case DTCompiler // e.g., "com.apple.compilers.llvm.clang.1_0"

    case DTXcode // e.g., 1300
    case DTXcodeBuild // e.g., "13A5192j"

    case LSMinimumSystemVersion
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
    public static let min = AppVersion(major: .min, minor: .min, patch: .min)
    /// The highest possible version that can exist
    public static let max = AppVersion(major: .max, minor: .max, patch: .max)

    public let major, minor, patch: UInt

    public init(major: UInt, minor: UInt, patch: UInt) {
        self.major = major
        self.minor = minor
        self.patch = patch
    }

    /// Initialize the version by parsing the string
    public init?(string versionString: String) {
        let versionElements = versionString.split(separator: ".", omittingEmptySubsequences: false).map({ UInt(String($0)) })
        if versionElements.count != 3 { return nil }
        let versionNumbers = versionElements.compactMap({ $0 })
        if versionNumbers.count != 3 { return nil }

        self.major = versionNumbers[0]
        self.minor = versionNumbers[1]
        self.patch = versionNumbers[2]

        // this is what prevents us from successfully parsing ".1.2.3"
        if !versionString.hasPrefix("\(self.major)") { return nil }
        if !versionString.hasSuffix("\(self.patch)") { return nil }
    }

    public static func < (lhs: AppVersion, rhs: AppVersion) -> Bool {
        lhs.major < rhs.major
            || (lhs.major == rhs.major && lhs.minor < rhs.minor)
            || (lhs.major == rhs.major && lhs.minor == rhs.minor && lhs.patch < rhs.patch)
    }

    /// The version string in the form `major`.`minor`.`patch`
    public var versionDescription: String {
        "\(major).\(minor).\(patch)"
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(versionDescription)
    }

    public init(from decoder: Decoder) throws {
        let string = try decoder.singleValueContainer().decode(String.self)
        guard let version = Self(string: string) else {
            struct BadAppVersionString : Error { let string: String }
            throw BadAppVersionString(string: string)
        }
        self = version
    }
}


public enum AppEntitlement : String, Pure, CaseIterable {
    // MARK: Essentials

    /// A Boolean value that indicates whether the app may use access control technology to contain damage to the system and user data if an app is compromised.
    case app_sandbox = "app-sandbox"

    // MARK: Network

    /// A Boolean value indicating whether your app may open outgoing network connections.
    /// - See: https://developer.apple.com/documentation/bundleresources/entitlements/com_apple_security_network_client
    case network_client = "network.client"

    /// A Boolean value indicating whether your app may listen for incoming network connections.
    /// - See: https://developer.apple.com/documentation/bundleresources/entitlements/com_apple_security_network_server
    case network_server = "network.server"

    // MARK: Hardware

    /// A Boolean value that indicates whether the app may interact with the built-in and external cameras, and capture movies and still images.
    /// - See: https://developer.apple.com/documentation/bundleresources/entitlements/com_apple_security_device_camera
    case device_camera = "device.camera"

    /// A Boolean value that indicates whether the app may use the microphone.
    /// - See: https://developer.apple.com/documentation/bundleresources/entitlements/com_apple_security_device_microphone
    case device_microphone = "device.microphone"

    /// A Boolean value indicating whether your app may interact with USB devices.
    /// - See: https://developer.apple.com/documentation/bundleresources/entitlements/com_apple_security_device_usb
    case device_usb = "device.usb"

    /// A Boolean value indicating whether your app may print a document.
    /// - See: https://developer.apple.com/documentation/bundleresources/entitlements/com_apple_security_print
    case print = "print"

    /// A Boolean value indicating whether your app may interact with Bluetooth devices.
    /// see: https://developer.apple.com/library/archive/documentation/Miscellaneous/Reference/EntitlementKeyReference/Chapters/EnablingAppSandbox.html#//apple_ref/doc/uid/TP40011195-CH4-SW21
    case device_bluetooth = "device.bluetooth"

    /// Interaction with AVB devices by using the Audio Video Bridging framework
    /// see: https://developer.apple.com/library/archive/documentation/Miscellaneous/Reference/EntitlementKeyReference/Chapters/EnablingAppSandbox.html#//apple_ref/doc/uid/TP40011195-CH4-SW21
    case device_audio_video_bridging = "device.audio-video-bridging"

    /// Interaction with FireWire devices (currently, does not support interaction with audio/video devices such as DV cameras)
    /// see: https://developer.apple.com/library/archive/documentation/Miscellaneous/Reference/EntitlementKeyReference/Chapters/EnablingAppSandbox.html#//apple_ref/doc/uid/TP40011195-CH4-SW21
    case device_firewire = "device.firewire"

    /// Interaction with serial devices
    /// see: https://developer.apple.com/library/archive/documentation/Miscellaneous/Reference/EntitlementKeyReference/Chapters/EnablingAppSandbox.html#//apple_ref/doc/uid/TP40011195-CH4-SW21
    case device_serial = "device.serial"

    /// Recording of audio using the built-in microphone, if available, along with access to audio input using any Core Audio API that supports audio input
    case device_audio_input = "device.audio-input"

    // MARK: App Data

    /// A Boolean value that indicates whether the app may have read-write access to contacts in the user's address book.
    /// - See: https://developer.apple.com/documentation/bundleresources/entitlements/com_apple_security_personal-information_addressbook
    case personal_information_addressbook = "personal-information.addressbook"
    /// A Boolean value that indicates whether the app may access location information from Location Services.
    /// - See: https://developer.apple.com/documentation/bundleresources/entitlements/com_apple_security_personal-information_location
    case personal_information_location = "personal-information.location"

    /// A Boolean value that indicates whether the app may have read-write access to the user's calendar.
    /// - See: https://developer.apple.com/documentation/bundleresources/entitlements/com_apple_security_personal-information_calendars
    case personal_information_calendars = "personal-information.calendars"

    // MARK: File Access

    /// A Boolean value that indicates whether the app may have read-only access to files the user has selected using an Open or Save dialog.
    /// - See: https://developer.apple.com/documentation/bundleresources/entitlements/com_apple_security_files_user-selected_read-only
    case files_user_selected_read_only = "files.user-selected.read-only"

    /// A Boolean value that indicates whether the app may have read-write access to files the user has selected using an Open or Save dialog.
    /// - See: https://developer.apple.com/documentation/bundleresources/entitlements/com_apple_security_files_user-selected_read-write
    case files_user_selected_read_write = "files.user-selected.read-write"

    /// Allows apps to write executable files
    /// - See: https://developer.apple.com/library/archive/documentation/Miscellaneous/Reference/EntitlementKeyReference/Chapters/EnablingAppSandbox.html#//apple_ref/doc/uid/TP40011195-CH4-SW6
    case files_user_selected_executable = "files.user-selected.executable"

    /// A Boolean value that indicates whether the app may have read-only access to the Downloads folder.
    /// - See: https://developer.apple.com/documentation/bundleresources/entitlements/com_apple_security_files_downloads_read-only
    case files_downloads_read_only = "files.downloads.read-only"

    /// A Boolean value that indicates whether the app may have read-write access to the Downloads folder.
    /// - See: https://developer.apple.com/documentation/bundleresources/entitlements/com_apple_security_files_downloads_read-write
    case files_downloads_read_write = "files.downloads.read-write"

    /// A Boolean value that indicates whether the app may have read-only access to the Pictures folder.
    /// - See: https://developer.apple.com/documentation/bundleresources/entitlements/com_apple_security_assets_pictures_read-only
    case assets_pictures_read_only = "assets.pictures.read-only"

    /// A Boolean value that indicates whether the app may have read-write access to the Pictures folder.
    /// - See: https://developer.apple.com/documentation/bundleresources/entitlements/com_apple_security_assets_pictures_read-write
    case assets_pictures_read_write = "assets.pictures.read-write"

    /// A Boolean value that indicates whether the app may have read-only access to the Music folder.
    /// - See: https://developer.apple.com/documentation/bundleresources/entitlements/com_apple_security_assets_music_read-only
    case assets_music_read_only = "assets.music.read-only"

    /// A Boolean value that indicates whether the app may have read-write access to the Music folder.
    /// - See: https://developer.apple.com/documentation/bundleresources/entitlements/com_apple_security_assets_music_read-write
    case assets_music_read_write = "assets.music.read-write"

    /// A Boolean value that indicates whether the app may have read-only access to the Movies folder.
    /// - See: https://developer.apple.com/documentation/bundleresources/entitlements/com_apple_security_assets_movies_read-only
    case assets_movies_read_only = "assets.movies.read-only"

    /// A Boolean value that indicates whether the app may have read-write access to the Movies folder.
    /// - See: https://developer.apple.com/documentation/bundleresources/entitlements/com_apple_security_assets_movies_read-write
    case assets_movies_read_write = "assets.movies.read-write"

    /// A Boolean value that indicates whether the app may have access to all files
    /// - See: https://developer.apple.com/documentation/bundleresources/entitlements/com_apple_security_files_all
    case files_all = "files.all"

    // MARK: Other

    /// Allow Execution of JIT-compiled Code Entitlement
    case cs_allow_jit = "cs.allow-jit"
    /// Debugging Tool Entitlement
    case cs_debugger = "cs.debugger"

    /// Allow Unsigned Executable Memory Entitlement (Forbidden)
    case cs_allow_unsigned_executable_memory = "cs.allow-unsigned-executable-memory"

    /// Allow DYLD Environment Variables Entitlement (Forbidden)
    case cs_allow_dyld_environment_variables = "cs.allow-dyld-environment-variables"

    /// A Boolean value that indicates whether the app loads arbitrary plug-ins or frameworks, without requiring code signing.
    /// https://developer.apple.com/documentation/bundleresources/entitlements/com_apple_security_cs_disable-library-validation
    case cs_disable_library_validation = "cs.disable-library-validation"

    /// Disable Executable Memory Protection Entitlement (Forbidden)
    case cs_disable_executable_page_protection = "cs.disable-executable-page-protection"


    /// Ability to use specific AppleScript scripting access groups within a specific scriptable app
    /// - See: https://developer.apple.com/library/archive/documentation/Miscellaneous/Reference/EntitlementKeyReference/Chapters/EnablingAppSandbox.html#//apple_ref/doc/uid/TP40011195-CH4-SW25
    case scripting_targets = "scripting-targets"

    /// Allows access to group containers that are shared among multiple apps produced by a single development team, and allows certain additional interprocess communication between the apps
    case application_groups = "application-groups"

    case files_bookmarks_app_scope = "files.bookmarks.app-scope"
    case files_bookmarks_document_scope = "files.bookmarks.document-scope"

    // MARK: Temporary Exceptions

    /// This is an array of paths relative to the user-directory, but must begin with a slash
    case files_home_relative_path_read_only = "temporary-exception.files.home-relative-path.read-only"
    /// This is an array of paths relative to the user-directory, but must begin with a slash
    case files_home_relative_path_read_write = "temporary-exception.files.home-relative-path.read-write"
    /// This is an array of absolute paths beginning with a slash
    case files_absolute_path_read_only = "temporary-exception.files.absolute-path.read-only"
    /// This is an array of absolute paths beginning with a slash
    case files_absolute_path_read_write = "temporary-exception.files.absolute-path.read-write"

    case apple_events = "temporary-exception.apple-events"
    case audio_unit_host = "temporary-exception.audio-unit-host"
    case iokit_user_client_class = "temporary-exception.iokit-user-client-class"
    case mach_lookup_global_name = "temporary-exception.mach-lookup.global-name"
    case mach_register_global_name = "temporary-exception.mach-register.global-name"
    case shared_preference_read_only = "temporary-exception.shared-preference.read-only"
    case shared_preference_read_write = "temporary-exception.shared-preference.read-write"

    /// The key for specifying the permission in an entitlements plist
    public var entitlementKey: String {
        "com.apple.security." + rawValue
    }

    /// The class of entitlement
    public enum Category : String, CaseIterable, Hashable {
        /// Required by all apps
        case prerequisite
        /// Low-risk
        case harmless
        /// Access to assets like media
        case assets
        /// Reading files
        case readFile
        /// Writing files
        case writeFile
        /// Network access
        case network
        /// Device access
        case device
        /// Miscellaneous access
        case misc
        /// Personal Information
        case personal_information
        /// Low-level system
        case volatile
    }

    public static func bitsetRepresentation(for entitlements: Set<Self>) -> UInt64 {
        var bitset: UInt64 = 0
        for entitlement in entitlements {
            bitset |= (2 << entitlement.bitsetOffset)
        }
        return bitset
    }

    public static func fromBitsetRepresentation(from bitset: UInt64) -> Set<Self> {
        var entitlements: Set<Self> = []
        for entitlement in Self.allCases {
            if (bitset & (2 << entitlement.bitsetOffset)) != 0 {
                entitlements.insert(entitlement)
            }
        }
        return entitlements
    }

    /// The representation of an entitlement in a bitfield.
    private var bitsetOffset: UInt64 {
        switch self {
        case .app_sandbox: return 1
        case .network_client: return 2
        case .network_server: return 3
        case .device_camera: return 4
        case .device_microphone: return 5
        case .device_usb: return 6
        case .print: return 7
        case .device_bluetooth: return 8
        case .device_audio_video_bridging: return 9
        case .device_firewire: return 10
        case .device_serial: return 11
        case .device_audio_input: return 12
        case .personal_information_addressbook: return 13
        case .personal_information_location: return 14
        case .personal_information_calendars: return 15
        case .files_user_selected_read_only: return 16
        case .files_user_selected_read_write: return 17
        case .files_user_selected_executable: return 18
        case .files_downloads_read_only: return 19
        case .files_downloads_read_write: return 20
        case .assets_pictures_read_only: return 21
        case .assets_pictures_read_write: return 22
        case .assets_music_read_only: return 23
        case .assets_music_read_write: return 24
        case .assets_movies_read_only: return 25
        case .assets_movies_read_write: return 26
        case .files_all: return 27
        case .cs_allow_jit: return 28
        case .cs_debugger: return 29
        case .cs_allow_unsigned_executable_memory: return 30
        case .cs_allow_dyld_environment_variables: return 31
        case .cs_disable_library_validation: return 32
        case .cs_disable_executable_page_protection: return 33
        case .scripting_targets: return 34
        case .application_groups: return 35
        case .files_bookmarks_app_scope: return 36
        case .files_bookmarks_document_scope: return 37
        case .files_home_relative_path_read_only: return 38
        case .files_home_relative_path_read_write: return 39
        case .files_absolute_path_read_only: return 40
        case .files_absolute_path_read_write: return 41
        case .apple_events: return 42
        case .audio_unit_host: return 43
        case .iokit_user_client_class: return 44
        case .mach_lookup_global_name: return 45
        case .mach_register_global_name: return 46
        case .shared_preference_read_only: return 47
        case .shared_preference_read_write: return 48
        }
    }

    /// Returns a value from 0-1 with the relative risk of this property
    public var relativeRisk: Double {
        func internalRisk(for entitlement: AppEntitlement) -> Int? {
            switch entitlement {
            case .app_sandbox: return nil
            case .cs_allow_jit: return nil

            case .network_client: return #line
            case .print: return #line
            case .device_camera: return #line
            case .device_microphone: return #line
            case .device_usb: return #line
            case .device_bluetooth: return #line
            case .device_audio_video_bridging: return #line
            case .device_firewire: return #line
            case .device_serial: return #line
            case .device_audio_input: return #line

            case .files_user_selected_read_only: return #line
            case .files_downloads_read_only: return #line

            case .files_downloads_read_write: return #line
            case .files_user_selected_read_write: return #line

            case .files_user_selected_executable: return #line

            case .network_server: return #line

            case .personal_information_addressbook: return #line
            case .personal_information_location: return #line
            case .personal_information_calendars: return #line

            case .scripting_targets: return #line
            case .application_groups: return #line
            case .apple_events: return #line

            case .audio_unit_host: return #line
            case .iokit_user_client_class: return #line

            case .mach_lookup_global_name: return #line
            case .mach_register_global_name: return #line

            case .shared_preference_read_only: return #line
            case .assets_pictures_read_only: return #line
            case .assets_music_read_only: return #line
            case .assets_movies_read_only: return #line

            case .shared_preference_read_write: return #line

            case .assets_pictures_read_write: return #line
            case .assets_music_read_write: return #line
            case .assets_movies_read_write: return #line

            case .files_bookmarks_app_scope: return #line
            case .files_bookmarks_document_scope: return #line

            case .files_home_relative_path_read_only: return #line
            case .files_absolute_path_read_only: return #line

            case .files_home_relative_path_read_write: return #line
            case .files_absolute_path_read_write: return #line

            case .cs_debugger: return #line
            case .cs_allow_unsigned_executable_memory: return #line
            case .cs_allow_dyld_environment_variables: return #line
            case .cs_disable_library_validation: return #line
            case .cs_disable_executable_page_protection: return #line

            case .files_all: return #line
            }
        }

        let allRisks = Set(AppEntitlement.allCases.compactMap({ internalRisk(for: $0) }))
        let riskRange = Double(allRisks.min() ?? 0)...Double(allRisks.max() ?? 0)

        // find where in the spectrum of arbitrary risk values (the line number) we lie…
        let risk = internalRisk(for: self).flatMap(Double.init) ?? riskRange.lowerBound // e.g., sandbox & JIT
        let riskLevel = (risk-riskRange.lowerBound)/(riskRange.upperBound-riskRange.lowerBound)
        return riskLevel
    }

    public var categories: Set<Category> {
        switch self {
        case .app_sandbox:
            return [.prerequisite]
        case .cs_allow_jit:
            return [.harmless]

        case .cs_debugger:
            return [.volatile]
        case .cs_allow_unsigned_executable_memory:
            return [.volatile]
        case .cs_allow_dyld_environment_variables:
            return [.volatile]
        case .cs_disable_library_validation:
            return [.volatile]
        case .cs_disable_executable_page_protection:
            return [.volatile]

        case .network_client:
            return [.network]
        case .network_server:
            return [.network]

        case .files_all:
            return [.readFile, .writeFile]
        case .files_user_selected_read_write:
            return [.readFile, .writeFile]
        case .files_user_selected_read_only:
            return [.readFile]
        case .files_user_selected_executable:
            return [.readFile, .writeFile]

        case .print:
            return [.device]
        case .scripting_targets:
            return [.harmless]
        case .application_groups:
            return [.harmless]

        case .files_downloads_read_only:
            return [.readFile]
        case .files_downloads_read_write:
            return [.readFile, .writeFile]
        case .files_bookmarks_app_scope:
            return [.harmless]
        case .files_bookmarks_document_scope:
            return [.harmless]
        case .files_home_relative_path_read_only:
            return [.readFile]
        case .files_home_relative_path_read_write:
            return [.readFile, .writeFile]
        case .files_absolute_path_read_only:
            return [.readFile]
        case .files_absolute_path_read_write:
            return [.readFile, .writeFile]

        case .assets_pictures_read_only:
            return [.assets, .readFile, .writeFile]
        case .assets_pictures_read_write:
            return [.assets, .readFile, .writeFile]
        case .assets_music_read_only:
            return [.assets, .readFile, .writeFile]
        case .assets_music_read_write:
            return [.assets, .readFile, .writeFile]
        case .assets_movies_read_only:
            return [.assets, .readFile, .writeFile]
        case .assets_movies_read_write:
            return [.assets, .readFile, .writeFile]

        case .personal_information_location:
            return [.personal_information]
        case .personal_information_addressbook:
            return [.personal_information]
        case .personal_information_calendars:
            return [.personal_information]

        case .device_camera:
            return [.device]
        case .device_microphone:
            return [.device]
        case .device_usb:
            return [.device]
        case .device_serial:
            return [.device]
        case .device_firewire:
            return [.device]
        case .device_bluetooth:
            return [.device]
        case .device_audio_input:
            return [.device]
        case .device_audio_video_bridging:
            return [.device]

        case .apple_events:
            return [.misc]
        case .audio_unit_host:
            return [.misc]
        case .iokit_user_client_class:
            return [.misc]
        case .mach_lookup_global_name:
            return [.misc]
        case .mach_register_global_name:
            return [.misc]

        case .shared_preference_read_only:
            return [.readFile, .writeFile]
        case .shared_preference_read_write:
            return [.readFile, .writeFile]
        }
    }

    /// The Info.plist properties that are used to explain to end-users the reason for the requested entitlement.
    /// In order to pass integration, each entitlement added to the `Sandbox.entitlements` file must have a corresponding usage description in the `Info.plist`'s `FairUsage` dictionary that explains in plain language the reason the app will need to request that permission.
    ///
    /// An empty returned array indicates that the entitlement may be used without needing any description (such as `cs_allow_jit`).
    /// A `nil` return value indicates that the property is always forbidden altogether (such as `files_all`)
    public var usageDescriptionProperties: [String]? {
        switch self {
        case .files_all:
            return nil // never allowed; use files_user_selected_read_write instead
        case .files_home_relative_path_read_only:
            return nil // never allowed; use files_user_selected_read_write instead
        case .files_home_relative_path_read_write:
            return nil // never allowed; use files_user_selected_read_write instead
        case .files_absolute_path_read_only:
            return nil // never allowed; use files_user_selected_read_write instead
        case .files_absolute_path_read_write:
            return nil // never allowed; use files_user_selected_read_write instead

        case .cs_allow_unsigned_executable_memory:
            return nil // never allowed
        case .cs_allow_dyld_environment_variables:
            return nil // never allowed
        case .cs_disable_library_validation:
            return nil // never allowed
        case .cs_disable_executable_page_protection:
            return nil // never allowed

        case .app_sandbox:
            return [] // no description required; ["CSAllowJITUsageDescription"]

        case .cs_allow_jit:
            return [] // permitted, with no description required

        default:
            // all other entitlements require that their usage description is included in the Info.plist's FairUsage section
            return [entitlementKey]
        }

        // TODO: also permit using the system-defined `*UsageDescription` properties when they apply, such as "NSDesktopFolderUsageDescription", "NSDocumentsFolderUsageDescription", and "NSLocalNetworkUsageDescription"
    }
}

/// The `LSApplicationCategoryType` for an app
public enum AppCategory : String, CaseIterable, Pure {
    case business = "business"
    case developertools = "developer-tools"
    case education = "education"
    case entertainment = "entertainment"
    case finance = "finance"
    case graphicsdesign = "graphics-design"
    case healthcarefitness = "healthcare-fitness"
    case lifestyle = "lifestyle"
    case medical = "medical"
    case music = "music"
    case news = "news"
    case photography = "photography"
    case productivity = "productivity"
    case reference = "reference"
    case socialnetworking = "social-networking"
    case sports = "sports"
    case travel = "travel"
    case utilities = "utilities"
    case video = "video"
    case weather = "weather"

    // MARK: Games
    case games = "games"
    case actiongames = "action-games"
    case adventuregames = "adventure-games"
    case arcadegames = "arcade-games"
    case boardgames = "board-games"
    case cardgames = "card-games"
    case casinogames = "casino-games"
    case dicegames = "dice-games"
    case educationalgames = "educational-games"
    case familygames = "family-games"
    case kidsgames = "kids-games"
    case musicgames = "music-games"
    case puzzlegames = "puzzle-games"
    case racinggames = "racing-games"
    case roleplayinggames = "role-playing-games"
    case simulationgames = "simulation-games"
    case sportsgames = "sports-games"
    case strategygames = "strategy-games"
    case triviagames = "trivia-games"
    case wordgames = "word-games"

    public init?(topic: String) {
        guard let category = Self.topics[topic] else {
            return nil
        }
        self = category
    }

    public init?(metadataID: String) {
        guard let category = Self.metadatas[metadataID] else {
            return nil
        }
        self = category
    }

    /// The identifier for the `Info.plist` metadata in the form: `public.app-category.[rawValue]`
    public var metadataIdentifier: String {
        "public.app-category." + rawValue
    }

    /// The hub topic for the category in the form: `appfair-[rawValue]`.
    public var topicIdentifier: String {
        "appfair-" + rawValue
    }


    /// A mapping from topic string to identifier
    public static let topics = Dictionary(grouping: Self.allCases, by: \.topicIdentifier).compactMapValues(\.first)

    /// A mapping from metadata to identifier
    public static let metadatas = Dictionary(grouping: Self.allCases, by: \.metadataIdentifier).compactMapValues(\.first)

}
