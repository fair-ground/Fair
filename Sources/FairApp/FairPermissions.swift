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
#if canImport(CoreFoundation)
import CoreFoundation
#endif

public typealias AppPermission = XOr<AppEntitlementPermission>
    .Or<AppUsagePermission>
    .Or<AppBackgroundModePermission>
    .Or<AppLegacyPermission>

/// A permission is a specific entitlement coupled with a description of its usage
public struct AppUsagePermission : Pure {
    public enum PermissionType : String, Pure { case usage }
    public var type: PermissionType = .usage

    /// The type of the permission, which maps to a `NS**UsageDescription` key in the Info.plist
    public var usage: UsageDescriptionKeys

    /// A description of the reason for needing the permission
    public var usageDescription: String

    public init(usage: UsageDescriptionKeys, usageDescription: String) {
        self.usage = usage
        self.usageDescription = usageDescription
    }
}

/// A permission is a specific entitlement coupled with a description of its usage
public struct AppBackgroundModePermission : Pure {
    public enum PermissionType : String, Pure { case backgroundMode = "background-mode" }
    public var type: PermissionType = .backgroundMode

    /// The type of the permission, which maps to a `NS**UsageDescription` key in the Info.plist
    public var backgroundMode: AppBackgroundMode

    /// A description of the reason for needing the permission
    public var usageDescription: String

    public init(backgroundMode: AppBackgroundMode, usageDescription: String) {
        self.backgroundMode = backgroundMode
        self.usageDescription = usageDescription
    }

    public enum CodingKeys : String, CodingKey {
        case type
        case backgroundMode = "background-mode"
        case usageDescription
    }
}

/// An element of the "background-mode" permission type
public struct AppBackgroundMode : RawRepresentable, Pure {
    public let rawValue: String

    public init(_ name: String) {
        self.rawValue = name
    }

    public init(rawValue name: String) {
        self.rawValue = name
    }

}

/// A permission is a specific entitlement coupled with a description of its usage
/// TODO: @available(*, deprecated, renamed: "AppEntitlementPermission")
public struct AppLegacyPermission : Pure {
    /// The type of the permission, which maps to an entitement key
    public var type: AppEntitlement

    /// A description of the reason for needing the permission
    public var usageDescription: String

    public init(type: AppEntitlement, usageDescription: String) {
        self.type = type
        self.usageDescription = usageDescription
    }
}

/// A permission is a specific entitlement coupled with a description of its usage
public struct AppEntitlementPermission : Pure {
    public enum PermissionType : String, Pure { case entitlement }
    public var type: PermissionType = .entitlement

    /// The type of the permission, which maps to an entitement key
    public var entitlement: AppEntitlement

    /// A description of the reason for needing the permission
    public var usageDescription: String

    public init(entitlement: AppEntitlement, usageDescription: String) {
        self.entitlement = entitlement
        self.usageDescription = usageDescription
    }
}

public struct AppEntitlement : RawRepresentable, Pure {
    public let rawValue: String

    public init(_ name: String) {
        self.rawValue = name
    }

    public init(rawValue name: String) {
        self.rawValue = name
    }

    /// The key for specifying the permission in an entitlements plist
    public var entitlementKey: String {
        // "com.apple." + rawValue
        rawValue
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

        default:
            return []
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
        case .cs_allow_unsigned_executable_memory:
            return nil // never allowed
        case .cs_allow_dyld_environment_variables:
            return nil // never allowed
        case .cs_disable_executable_page_protection:
            return nil // never allowed

        case .cs_disable_library_validation:
            return [] // always allowed (and required in order to support loading embedded frameworks for an ad-hoc signed app)

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

extension AppEntitlement : CaseIterable {
    public static let allCases: Set<Self> = developerEntitlements.union(securityEntitlements)
}

/// secutiry-specific keys
public extension AppEntitlement {

    /// The key begins with "secutiry."
    var isSecurityEntitlement: Bool {
        entitlementKey.hasPrefix("com.apple.security.")
    }

    /// All the known security-related entitlements (typically for macOS)
    static let securityEntitlements = Set<Self>([
        .app_sandbox,
        .get_task_allow,
        .network_client,
        .network_server,
        .device_camera,
        .device_microphone,
        .device_usb,
        .print,
        .device_bluetooth,
        .device_audio_video_bridging,
        .device_firewire,
        .device_serial,
        .device_audio_input,
        .personal_information_addressbook,
        .personal_information_location,
        .personal_information_calendars,
        .files_user_selected_read_only,
        .files_user_selected_read_write,
        .files_user_selected_executable,
        .files_downloads_read_only,
        .files_downloads_read_write,
        .assets_pictures_read_only,
        .assets_pictures_read_write,
        .assets_music_read_only,
        .assets_music_read_write,
        .assets_movies_read_only,
        .assets_movies_read_write,
        .files_all,
        .cs_allow_jit,
        .cs_debugger,
        .cs_allow_unsigned_executable_memory,
        .cs_allow_dyld_environment_variables,
        .cs_disable_library_validation,
        .cs_disable_executable_page_protection,
        .scripting_targets,
        .application_groups,
        .files_bookmarks_app_scope,
        .files_bookmarks_document_scope,
        .files_home_relative_path_read_only,
        .files_home_relative_path_read_write,
        .files_absolute_path_read_only,
        .files_absolute_path_read_write,
        .apple_events,
        .audio_unit_host,
        .iokit_user_client_class,
        .mach_lookup_global_name,
        .mach_register_global_name,
        .shared_preference_read_only,
        .shared_preference_read_write,
    ])


    // MARK: Essentials

    /// A Boolean value that indicates whether the app may use access control technology to contain damage to the system and user data if an app is compromised.
    static let app_sandbox = AppEntitlement("com.apple.security.app-sandbox")

    static let get_task_allow = AppEntitlement("com.apple.security.get-task-allow")

    // MARK: Network

    /// A Boolean value indicating whether your app may open outgoing network connections.
    /// - See: https://developer.apple.com/documentation/bundleresources/entitlements/com_apple_security_network_client
    static let network_client = AppEntitlement("com.apple.security.network.client")

    /// A Boolean value indicating whether your app may listen for incoming network connections.
    /// - See: https://developer.apple.com/documentation/bundleresources/entitlements/com_apple_security_network_server
    static let network_server = AppEntitlement("com.apple.security.network.server")

    // MARK: Hardware

    /// A Boolean value that indicates whether the app may interact with the built-in and external cameras, and capture movies and still images.
    /// - See: https://developer.apple.com/documentation/bundleresources/entitlements/com_apple_security_device_camera
    static let device_camera = AppEntitlement("com.apple.security.device.camera")

    /// A Boolean value that indicates whether the app may use the microphone.
    /// - See: https://developer.apple.com/documentation/bundleresources/entitlements/com_apple_security_device_microphone
    static let device_microphone = AppEntitlement("com.apple.security.device.microphone")

    /// A Boolean value indicating whether your app may interact with USB devices.
    /// - See: https://developer.apple.com/documentation/bundleresources/entitlements/com_apple_security_device_usb
    static let device_usb = AppEntitlement("com.apple.security.device.usb")

    /// A Boolean value indicating whether your app may print a document.
    /// - See: https://developer.apple.com/documentation/bundleresources/entitlements/com_apple_security_print
    static let print = AppEntitlement("com.apple.security.print")

    /// A Boolean value indicating whether your app may interact with Bluetooth devices.
    /// see: https://developer.apple.com/library/archive/documentation/Miscellaneous/Reference/EntitlementKeyReference/Chapters/EnablingAppSandbox.html#//apple_ref/doc/uid/TP40011195-CH4-SW21
    static let device_bluetooth = AppEntitlement("com.apple.security.device.bluetooth")

    /// Interaction with AVB devices by using the Audio Video Bridging framework
    /// see: https://developer.apple.com/library/archive/documentation/Miscellaneous/Reference/EntitlementKeyReference/Chapters/EnablingAppSandbox.html#//apple_ref/doc/uid/TP40011195-CH4-SW21
    static let device_audio_video_bridging = AppEntitlement("com.apple.security.device.audio-video-bridging")

    /// Interaction with FireWire devices (currently, does not support interaction with audio/video devices such as DV cameras)
    /// see: https://developer.apple.com/library/archive/documentation/Miscellaneous/Reference/EntitlementKeyReference/Chapters/EnablingAppSandbox.html#//apple_ref/doc/uid/TP40011195-CH4-SW21
    static let device_firewire = AppEntitlement("com.apple.security.device.firewire")

    /// Interaction with serial devices
    /// see: https://developer.apple.com/library/archive/documentation/Miscellaneous/Reference/EntitlementKeyReference/Chapters/EnablingAppSandbox.html#//apple_ref/doc/uid/TP40011195-CH4-SW21
    static let device_serial = AppEntitlement("com.apple.security.device.serial")

    /// Recording of audio using the built-in microphone, if available, along with access to audio input using any Core Audio API that supports audio input
    static let device_audio_input = AppEntitlement("com.apple.security.device.audio-input")

    // MARK: App Data

    /// A Boolean value that indicates whether the app may have read-write access to contacts in the user's address book.
    /// - See: https://developer.apple.com/documentation/bundleresources/entitlements/com_apple_security_personal-information_addressbook
    static let personal_information_addressbook = AppEntitlement("com.apple.security.personal-information.addressbook")
    /// A Boolean value that indicates whether the app may access location information from Location Services.
    /// - See: https://developer.apple.com/documentation/bundleresources/entitlements/com_apple_security_personal-information_location
    static let personal_information_location = AppEntitlement("com.apple.security.personal-information.location")

    /// A Boolean value that indicates whether the app may have read-write access to the user's calendar.
    /// - See: https://developer.apple.com/documentation/bundleresources/entitlements/com_apple_security_personal-information_calendars
    static let personal_information_calendars = AppEntitlement("com.apple.security.personal-information.calendars")

    // MARK: File Access

    /// A Boolean value that indicates whether the app may have read-only access to files the user has selected using an Open or Save dialog.
    /// - See: https://developer.apple.com/documentation/bundleresources/entitlements/com_apple_security_files_user-selected_read-only
    static let files_user_selected_read_only = AppEntitlement("com.apple.security.files.user-selected.read-only")

    /// A Boolean value that indicates whether the app may have read-write access to files the user has selected using an Open or Save dialog.
    /// - See: https://developer.apple.com/documentation/bundleresources/entitlements/com_apple_security_files_user-selected_read-write
    static let files_user_selected_read_write = AppEntitlement("com.apple.security.files.user-selected.read-write")

    /// Allows apps to write executable files
    /// - See: https://developer.apple.com/library/archive/documentation/Miscellaneous/Reference/EntitlementKeyReference/Chapters/EnablingAppSandbox.html#//apple_ref/doc/uid/TP40011195-CH4-SW6
    static let files_user_selected_executable = AppEntitlement("com.apple.security.files.user-selected.executable")

    /// A Boolean value that indicates whether the app may have read-only access to the Downloads folder.
    /// - See: https://developer.apple.com/documentation/bundleresources/entitlements/com_apple_security_files_downloads_read-only
    static let files_downloads_read_only = AppEntitlement("com.apple.security.files.downloads.read-only")

    /// A Boolean value that indicates whether the app may have read-write access to the Downloads folder.
    /// - See: https://developer.apple.com/documentation/bundleresources/entitlements/com_apple_security_files_downloads_read-write
    static let files_downloads_read_write = AppEntitlement("com.apple.security.files.downloads.read-write")

    /// A Boolean value that indicates whether the app may have read-only access to the Pictures folder.
    /// - See: https://developer.apple.com/documentation/bundleresources/entitlements/com_apple_security_assets_pictures_read-only
    static let assets_pictures_read_only = AppEntitlement("com.apple.security.assets.pictures.read-only")

    /// A Boolean value that indicates whether the app may have read-write access to the Pictures folder.
    /// - See: https://developer.apple.com/documentation/bundleresources/entitlements/com_apple_security_assets_pictures_read-write
    static let assets_pictures_read_write = AppEntitlement("com.apple.security.assets.pictures.read-write")

    /// A Boolean value that indicates whether the app may have read-only access to the Music folder.
    /// - See: https://developer.apple.com/documentation/bundleresources/entitlements/com_apple_security_assets_music_read-only
    static let assets_music_read_only = AppEntitlement("com.apple.security.assets.music.read-only")

    /// A Boolean value that indicates whether the app may have read-write access to the Music folder.
    /// - See: https://developer.apple.com/documentation/bundleresources/entitlements/com_apple_security_assets_music_read-write
    static let assets_music_read_write = AppEntitlement("com.apple.security.assets.music.read-write")

    /// A Boolean value that indicates whether the app may have read-only access to the Movies folder.
    /// - See: https://developer.apple.com/documentation/bundleresources/entitlements/com_apple_security_assets_movies_read-only
    static let assets_movies_read_only = AppEntitlement("com.apple.security.assets.movies.read-only")

    /// A Boolean value that indicates whether the app may have read-write access to the Movies folder.
    /// - See: https://developer.apple.com/documentation/bundleresources/entitlements/com_apple_security_assets_movies_read-write
    static let assets_movies_read_write = AppEntitlement("com.apple.security.assets.movies.read-write")

    /// A Boolean value that indicates whether the app may have access to all files
    /// - See: https://developer.apple.com/documentation/bundleresources/entitlements/com_apple_security_files_all
    static let files_all = AppEntitlement("com.apple.security.files.all")

    // MARK: Other

    /// Allow Execution of JIT-compiled Code Entitlement
    static let cs_allow_jit = AppEntitlement("com.apple.security.cs.allow-jit")
    /// Debugging Tool Entitlement
    static let cs_debugger = AppEntitlement("com.apple.security.cs.debugger")

    /// Allow Unsigned Executable Memory Entitlement (Forbidden)
    static let cs_allow_unsigned_executable_memory = AppEntitlement("com.apple.security.cs.allow-unsigned-executable-memory")

    /// Allow DYLD Environment Variables Entitlement (Forbidden)
    static let cs_allow_dyld_environment_variables = AppEntitlement("com.apple.security.cs.allow-dyld-environment-variables")

    /// A Boolean value that indicates whether the app loads arbitrary plug-ins or frameworks, without requiring code signing.
    /// https://developer.apple.com/documentation/bundleresources/entitlements/com_apple_security_cs_disable-library-validation
    static let cs_disable_library_validation = AppEntitlement("com.apple.security.cs.disable-library-validation")

    /// Disable Executable Memory Protection Entitlement (Forbidden)
    static let cs_disable_executable_page_protection = AppEntitlement("com.apple.security.cs.disable-executable-page-protection")


    /// Ability to use specific AppleScript scripting access groups within a specific scriptable app
    /// - See: https://developer.apple.com/library/archive/documentation/Miscellaneous/Reference/EntitlementKeyReference/Chapters/EnablingAppSandbox.html#//apple_ref/doc/uid/TP40011195-CH4-SW25
    static let scripting_targets = AppEntitlement("com.apple.security.scripting-targets")

    /// Allows access to group containers that are shared among multiple apps produced by a single development team, and allows certain additional interprocess communication between the apps
    static let application_groups = AppEntitlement("com.apple.security.application-groups")

    static let files_bookmarks_app_scope = AppEntitlement("com.apple.security.files.bookmarks.app-scope")
    static let files_bookmarks_document_scope = AppEntitlement("com.apple.security.files.bookmarks.document-scope")

    // MARK: Temporary Exceptions

    /// This is an array of paths relative to the user-directory, but must begin with a slash
    static let files_home_relative_path_read_only = AppEntitlement("com.apple.security.temporary-exception.files.home-relative-path.read-only")
    /// This is an array of paths relative to the user-directory, but must begin with a slash
    static let files_home_relative_path_read_write = AppEntitlement("com.apple.security.temporary-exception.files.home-relative-path.read-write")
    /// This is an array of absolute paths beginning with a slash
    static let files_absolute_path_read_only = AppEntitlement("com.apple.security.temporary-exception.files.absolute-path.read-only")
    /// This is an array of absolute paths beginning with a slash
    static let files_absolute_path_read_write = AppEntitlement("com.apple.security.temporary-exception.files.absolute-path.read-write")

    static let apple_events = AppEntitlement("com.apple.security.temporary-exception.apple-events")
    static let audio_unit_host = AppEntitlement("com.apple.security.temporary-exception.audio-unit-host")
    static let iokit_user_client_class = AppEntitlement("com.apple.security.temporary-exception.iokit-user-client-class")
    static let mach_lookup_global_name = AppEntitlement("com.apple.security.temporary-exception.mach-lookup.global-name")
    static let mach_register_global_name = AppEntitlement("com.apple.security.temporary-exception.mach-register.global-name")
    static let shared_preference_read_only = AppEntitlement("com.apple.security.temporary-exception.shared-preference.read-only")
    static let shared_preference_read_write = AppEntitlement("com.apple.security.temporary-exception.shared-preference.read-write")
}

/// developer-specific keys
/// https://developer.apple.com/documentation/bundleresources/entitlements
public extension AppEntitlement {
    /// The key begins with "developer."
    var isDeveloperEntitlement: Bool {
        entitlementKey.hasPrefix("com.apple.developer.")
    }

    /// All the known developer-related entitlements (typically for iOS)
    static let developerEntitlements = Set<Self>([
        .mailClient,
        .webBrowser,
        .autofillCredentialProvider,
        .signWithApple,
        .contacts,
        .classKit,
        .automaticAssesmentConfiguration,
        .gameCenter,
        .healthKit,
        .healthKitCapabilities,
        .homeKit,
        .iCloudDevelopmentContainersIdentifiers,
        .iCloudContainersEnvironment,
        .iCloudContainerIdentifiers,
        .iCloudServices,
        .iCloudKeyValueStore,
        .interAppAudio,
        .networkExtensions,
        .personalVPN,
        .apsEnvironment,
        .keychainAccessGroups,
        .dataProtection,
        .siri,
        .passTypeIDs,
        .merchantIDs,
        .wifiInfo,
        .externalAccessoryConfiguration,
        .multipath,
        .hotspotConfiguration,
        .nfcTagReaderSessionFormats,
        .associatedDomains,
        .maps,
        .driverKit,
    ])

    /// https://developer.apple.com/documentation/bundleresources/entitlements/com_apple_developer_mail-client
    static let mailClient = AppEntitlement("com.apple.developer.mail-client")

    /// https://developer.apple.com/documentation/bundleresources/entitlements/com_apple_developer_web-browser
    static let webBrowser = AppEntitlement("com.apple.developer.web-browser")

    static let autofillCredentialProvider = AppEntitlement("com.apple.developer.authentication-services.autofill-credential-provider")
    static let signWithApple = AppEntitlement("com.apple.developer.applesignin")
    static let contacts = AppEntitlement("com.apple.developer.contacts.notes")
    static let classKit = AppEntitlement("com.apple.developer.ClassKit-environment")
    static let automaticAssesmentConfiguration = AppEntitlement("com.apple.developer.automatic-assessment-configuration")
    static let gameCenter = AppEntitlement("com.apple.developer.game-center")
    static let healthKit = AppEntitlement("com.apple.developer.healthkit")
    static let healthKitCapabilities = AppEntitlement("com.apple.developer.healthkit.access")
    static let homeKit = AppEntitlement("com.apple.developer.homekit")
    static let iCloudDevelopmentContainersIdentifiers = AppEntitlement("com.apple.developer.icloud-container-development-container-identifiers")
    static let iCloudContainersEnvironment = AppEntitlement("com.apple.developer.icloud-container-environment")
    static let iCloudContainerIdentifiers = AppEntitlement("com.apple.developer.icloud-container-identifiers")
    static let iCloudServices = AppEntitlement("com.apple.developer.icloud-services")
    static let iCloudKeyValueStore = AppEntitlement("com.apple.developer.ubiquity-kvstore-identifier")
    /// Deprecated: Inter-App Audio is deprecated in iOS 13 and is unavailable when running iPad apps in macOS.
    static let interAppAudio = AppEntitlement("inter-app-audio")
    static let networkExtensions = AppEntitlement("com.apple.developer.networking.networkextension")
    static let personalVPN = AppEntitlement("com.apple.developer.networking.vpn.api")
    static let apsEnvironment = AppEntitlement("aps-environment")
    static let keychainAccessGroups = AppEntitlement("keychain-access-groups")
    static let dataProtection = AppEntitlement("com.apple.developer.default-data-protection")
    static let siri = AppEntitlement("com.apple.developer.siri")
    static let passTypeIDs = AppEntitlement("com.apple.developer.pass-type-identifiers")
    static let merchantIDs = AppEntitlement("com.apple.developer.in-app-payments")
    static let wifiInfo = AppEntitlement("com.apple.developer.networking.wifi-info")
    static let externalAccessoryConfiguration = AppEntitlement("com.apple.external-accessory.wireless-configuration")
    static let multipath = AppEntitlement("com.apple.developer.networking.multipath")
    static let hotspotConfiguration = AppEntitlement("com.apple.developer.networking.HotspotConfiguration")
    static let nfcTagReaderSessionFormats = AppEntitlement("com.apple.developer.nfc.readersession.formats")
    static let associatedDomains = AppEntitlement("com.apple.developer.associated-domains")
    /// Deprecated: Using Maps no longer requires an entitlement.
    static let maps = AppEntitlement("com.apple.developer.maps")
    static let driverKit = AppEntitlement("com.apple.developer.driverkit.transport.pci")
}


public enum UsageDescriptionKeys : String, CaseIterable, Pure {

    // MARK: tracking
    case NSUserTrackingUsageDescription

    // MARK: location

    case NSLocationUsageDescription
    case NSLocationDefaultAccuracyReduced
    case NSLocationAlwaysUsageDescription
    case NSLocationTemporaryUsageDescriptionDictionary
    case NSLocationWhenInUseUsageDescription
    case NSLocationAlwaysAndWhenInUseUsageDescription
    case NSWidgetWantsLocation

    // MARK: network

    case NSVoIPUsageDescription
    case NSNearbyInteractionUsageDescription
    case NSNearbyInteractionAllowOnceUsageDescription

    // MARK: voice

    case NSSiriUsageDescription
    case NSSpeechRecognitionUsageDescription

    // MARK: hardware

    case NSSensorKitUsageDescription
    case NSMicrophoneUsageDescription
    case NSCameraUsageDescription
    case NSBluetoothUsageDescription
    case NSBluetoothAlwaysUsageDescription
    case NSBluetoothPeripheralUsageDescription
    case NSBluetoothWhileInUseUsageDescription

    case NFCReaderUsageDescription

    // MARK: motion

    case NSMotionUsageDescription
    case NSFallDetectionUsageDescription

    // MARK: databases

    case NSRemindersUsageDescription
    case NSContactsUsageDescription
    case NSCalendarsUsageDescription
    case NSPhotoLibraryAddUsageDescription
    case NSPhotoLibraryUsageDescription

    // MARK: services

    case NSAppleMusicUsageDescription
    case NSHomeKitUsageDescription
    case NSVideoSubscriberAccountUsageDescription

    // MARK: games

    case NSGKFriendListUsageDescription

    // MARK: health

    case NSHealthShareUsageDescription
    case NSHealthUpdateUsageDescription
    case NSHealthClinicalHealthRecordsShareUsageDescription

    // MARK: misc

    case NSAppleEventsUsageDescription
    case NSFocusStatusUsageDescription
    case NSLocalNetworkUsageDescription
    case NSFaceIDUsageDescription

    // MARK: standard locations (macOS)
    case NSDesktopFolderUsageDescription
    case NSDocumentsFolderUsageDescription
    case NSDownloadsFolderUsageDescription

    // MARK: misc (macOS)
    case NSSystemExtensionUsageDescription
    case NSSystemAdministrationUsageDescription
    case NSFileProviderDomainUsageDescription
    case NSFileProviderPresenceUsageDescription
    case NSNetworkVolumesUsageDescription
    case NSRemovableVolumesUsageDescription
}

/// The `LSApplicationCategoryType` for an app
public enum AppCategory : String, CaseIterable, Identifiable, Pure {
    case business = "business"
    case developertools = "developer-tools"
    case education = "education"
    case entertainment = "entertainment"
    case finance = "finance"
    case games = "games"
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

    // MARK: Game Sub-types
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

    public var id: Self { self }

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
    var baseURL: URL! {
        URL(string: "https://github.com/\(appNameHyphenated)/App/")
    }

    /// The e-mail address for contacting the developer
    var developerEmail: String? {
        developerName // TODO: parse out
    }

    /// Returns the URL to this app's home page
    var sourceURL: URL! {
        baseURL.appendingPathExtension("git")
    }

    var issuesURL: URL! {
        URL(string: "issues", relativeTo: baseURL)
    }

    var discussionsURL: URL! {
        URL(string: "discussions", relativeTo: baseURL)
    }

    var releasesURL: URL! {
        URL(string: "releases/", relativeTo: baseURL)
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

public struct AppEntitlements {
    static let empty: AppEntitlements = AppEntitlements([:])

    private let values: [String: Any]

    init(_ values: [String: Any]) {
        self.values = values
    }

    public var count: Int {
        values.count
    }

    /// Returns the entitlement values as a codable JSum struct.
    public func jsum() throws -> JSum {
        try Plist(rawValue: values as NSDictionary).jsum()
    }

    public func value(forKey key: AppEntitlement) -> Any? {
        values[key.rawValue]
    }

    static func readEntitlements(from data: Data) -> AppEntitlements {
        guard let rawValues = try? PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? [String: Any] else {
            return .empty
        }
        return AppEntitlements(rawValues)
    }
}

public extension AppEntitlements {
    /// Loads the entitlements from an app bundle (either a ipa zip or an expanded binary package).
    /// Multiple entitlements will be returned when an executable is a fat binary, although they are likely to all be equal.
    static func loadInfo(fromAppBundle url: URL) throws -> (info: Plist, entitlements: [AppEntitlements]?) {
        if FileManager.default.isDirectory(url: url) == true {
            return try AppBundle(folderAt: url).loadInfo()
        } else {
            return try AppBundle(zipArchiveAt: url).loadInfo()
        }
    }
}

extension AppBundle {
    func loadInfo() throws -> (info: Plist, entitlements: [AppEntitlements]?) {
        return try (infoDictionary, entitlements())
    }
}

// MARK: AppBundle

/// A structure that contains an app, whether as an expanded folder or a zip archive.
public class AppBundle<Source: DataWrapper> {
    let source: Source
    let infoDictionary: Plist
    let infoParentNode: Source.Path
    let infoNode: Source.Path

    /// Cache of entitlements once loaded
    private var _entitlements: [AppEntitlements]??

    public func entitlements() throws -> [AppEntitlements]? {
        if let entitlements = _entitlements {
            return entitlements
        }
        let ent = try self.loadEntitlements()
        self._entitlements = .some(ent)
        return ent
    }

    public func isSandboxed() throws -> Bool? {
        try entitlement(for: .app_sandbox)
    }

    public func appGroups() throws -> [String]? {
        try entitlement(for: .application_groups)
    }

    public init(source: Source) throws {
        self.source = source
        guard let (info, parent, node) = try Self.readInfo(source: source) else {
            throw AppBundleErrors.missingInfo
        }
        self.infoDictionary = info
        self.infoParentNode = parent
        self.infoNode = node
    }

    public func entitlement<T>(for key: AppEntitlement) throws -> T? {
        try self.entitlements()?.compactMap({ $0.value(forKey: key) as? T }).first
    }
}

public enum AppBundleErrors : Error {
    /// The Info.plist is missing from the archive
    case missingInfo
}

public extension AppBundle {

    var appType: AppType {
        self.infoDictionary.DTPlatformName == "iphoneos" ? .ios : .macos // not necessarily reliable
    }

    enum AppType {
        /// A macOS .app folder containing the app
        case macos
        /// An iOS .ipa file, which is a zip containing an .app folder
        case ios
    }

    private func loadEntitlements() throws -> [AppEntitlements]? {
        guard let executable = try self.loadExecutableData() else {
            return nil
        }
        return try MachOBinary(binary: executable).readEntitlements()
    }

    func loadExecutableData() throws -> SeekableData? {
        guard let executableName = infoDictionary.CFBundleExecutable else {
            return nil
        }
        // check first for macOS convention executable "AppName.app/Contents/MacOS/CFBundleExecutable"
        let folder = try self.source.nodes(at: infoParentNode).first(where: { $0.pathIsDirectory && $0.pathName == "MacOS" }) ?? infoParentNode

        guard let execNode = try self.source.nodes(at: folder).first(where: { $0.pathName == executableName }) else {
            return nil
        }

        return try self.source.seekableData(at: execNode)
    }

    private static func readInfo(source: Source) throws -> (Plist, parent: Source.Path, node: Source.Path)? {
        // dbg("reading info node from:", fs.containerURL.path)
        let rootNodes = try source.nodes(at: nil)
        // dbg("rootNodes:", rootNodes.map(\.pathName))

        func loadInfoPlist(from node: Source.Path) throws -> (Plist, parent: Source.Path, node: Source.Path)? {
            dbg("attempting to load Info.plist from:", node.pathName)
            let contents = try source.nodes(at: node)
            guard let infoNode = contents.first(where: { $0.pathName == "Info.plist" }) else {
                // dbg("missing Info.plist node from:", contents.map(\.pathName))
                return nil
            }
            // dbg("found Info.plist node:", infoNode.pathName, "from:", contents.map(\.pathName))

            return try (Plist(data: source.seekableData(at: infoNode).readData(ofLength: nil)), parent: node, node: infoNode)
        }

        if let contentsNode = rootNodes.first(where: {
            $0.pathIsDirectory && $0.pathName == "Contents"
        }) {
            // dbg("contentsNode", contentsNode)
            // check the "Contents/Info.plist" convention (macOS)
            return try loadInfoPlist(from: contentsNode)
        }

        for payloadNode in rootNodes.filter({
            $0.pathIsDirectory && ($0.pathName == "Payload" || $0.pathName == "Wrapper")
        }) {
            // dbg("payloadNode", payloadNode)
            // check the "Payload/App Name.app/Info.plist" convention
            let payloadContents = try source.nodes(at: payloadNode)
            guard let appNode = payloadContents.first(where: {
                $0.pathIsDirectory && $0.pathName.hasSuffix(".app")
            }) else {
                continue
            }

            return try loadInfoPlist(from: appNode)
        }

        // finally, check for root-level .app files; this handles both the case where a macOS app is distributed in a .zip, as well as .ipa files that are missing a root "Payload/" folder
        for appNode in rootNodes.filter({
            $0.pathIsDirectory && $0.pathName.hasSuffix(".app")
        }) {
            dbg("appNode", appNode)
            // check the "App Name.app/Info.plist" convention
            let appContents = try source.nodes(at: appNode)

            if let contentsNode = appContents.first(where: {
                $0.pathIsDirectory && $0.pathName == "Contents"
            }) {
                // dbg("contentsNode", contentsNode)
                // check the "AppName.app/Contents/Info.plist" convention (macOS)
                return try loadInfoPlist(from: contentsNode)
            }

            // fall back to "AppName.app/Info.plist" convention (iOS)
            return try loadInfoPlist(from: appNode)
        }

        dbg("returning nil")
        return nil
    }
}


/// A collection of data resources, such as a file system hierarchy or a zip archive of files.
public protocol DataWrapper : AnyObject {
    associatedtype Path : DataWrapperPath
    /// The root URL of this data wrapper
    var containerURL: URL { get }
    func nodes(at path: Path?) throws -> [Path]
    /// A pointer to the data at the given path; this could be either an in-memory structure (in the case if zip archives) or a wrapper around a FilePointer (in the case of a file system hierarchy)
    func seekableData(at path: Path) throws -> SeekableData

    /// All the paths contained in this wrapper
    var paths: [Path] { get }

    func find(pathsMatching: NSRegularExpression) -> [Path]
}

public protocol DataWrapperPath {
    /// The name of this path relative to the root of the file system
    var pathName: String { get }
    /// The size of the element represented by this path
    var pathSize: UInt64 { get }
    /// True if the path is a directory
    var pathIsDirectory: Bool { get }
}

public extension DataWrapper {
    /// All non-directory paths in this wrapper
    var filePaths: [Path] {
        paths.filter({ $0.pathIsDirectory == false })
    }
}

// MARK: FileSystemDataWrapper

public class FileSystemDataWrapper : DataWrapper {
    public typealias Path = URL
    let root: Path
    let fm: FileManager
    public let paths: [URL]

    public init(root: Path, fileManager: FileManager = .default) throws {
        self.root = root
        self.fm = fileManager
        self.paths = try fileManager.deepContents(of: root, includeFolders: true, relativePath: true)
    }

    public var containerURL: URL {
        root
    }

    public func parent(of path: Path) throws -> Path? {
        path.deletingLastPathComponent()
    }

    public func nodes(at path: Path?) throws -> [Path] {
        #if os(Linux) || os(Windows)
        try fm.contentsOfDirectory(at: path ?? root, includingPropertiesForKeys: [.fileSizeKey, .isDirectoryKey], options: []) // .producesRelativePathURLs unavailable
        #else
        try fm.contentsOfDirectory(at: path ?? root, includingPropertiesForKeys: [.fileSizeKey, .isDirectoryKey], options: [.producesRelativePathURLs])
        #endif
    }

    public func seekableData(at path: Path) throws -> SeekableData {
        // try URLSession.shared.fetch(request: URLRequest(url: path)).data
        // SeekableDataHandle(try Data(contentsOf: path), bigEndian: bigEndian)
        try SeekableFileHandle(FileHandle(forReadingFrom: path))
    }

    public func find(pathsMatching expression: NSRegularExpression) -> [Path] {
        paths.filter { path in
            expression.firstMatch(in: path.relativePath, range: path.relativePath.span) != nil
        }
    }
}

extension AppBundle where Source == FileSystemDataWrapper {
    convenience init(folderAt url: URL) throws {
        try self.init(source: FileSystemDataWrapper(root: url))
    }
}


extension FileSystemDataWrapper.Path : DataWrapperPath {
    public var pathName: String {
        self.relativePath
    }

    public var pathSize: UInt64 {
        (try? self.resourceValues(forKeys: [.fileSizeKey]).fileSize).flatMap({ .init($0) }) ?? 0
    }

    public var pathIsDirectory: Bool {
        (try? self.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) ?? false
    }
}

// MARK: ZipArchiveDataWrapper

public class ZipArchiveDataWrapper : DataWrapper {
    public typealias Path = ZipArchive.Entry
    let archive: ZipArchive
    public let paths: [ZipArchive.Entry]

    public init(archive: ZipArchive) {
        self.archive = archive
        self.paths = archive.array()
    }

    public var containerURL: URL {
        archive.url
    }

    public func parent(of path: Path) throws -> Path? {
        let pathParts = path.path.split(separator: "/")
        return self.paths.first(where: {
            $0.pathIsDirectory && path.path.hasPrefix($0.path) && $0.path.split(separator: "/").count == pathParts.count - 1
        })
    }

    public func nodes(at path: Path?) throws -> [Path] {
        if let parentPath = path {
            let pathParts = parentPath.path.split(separator: "/")

            // brute-force scan all the entries; this should be made into a tree
            return paths.filter({
                $0.path.hasPrefix(parentPath.path) && $0.path.split(separator: "/").count == pathParts.count + 1
            })
        } else {
            // there isn't always a separate root "Payload/" directory entry; a valid zip might instead contain just a root-level "Payload/MyApp.app/" entry
            let minPath = paths.map({ $0.path.split(separator: "/").count }).min()

            let rootEntries = paths.filter({
                $0.path.split(separator: "/").count == minPath // all top-level entries
            })

            //dbg("root entries:", rootEntries.map(\.path))
            return rootEntries
        }
    }

    public func seekableData(at path: Path) throws -> SeekableData {
        SeekableDataHandle(try archive.extractData(from: path))
    }


    public func find(pathsMatching expression: NSRegularExpression) -> [Path] {
        paths.filter { path in
            expression.firstMatch(in: path.path, range: path.path.span) != nil
        }
    }
}

extension AppBundle where Source == ZipArchiveDataWrapper {
    convenience init(zipArchiveAt url: URL) throws {
        guard let zip = ZipArchive(url: url, accessMode: .read) else {
            throw URLError(.badURL)
        }
        try self.init(source: ZipArchiveDataWrapper(archive: zip))
    }
}

extension ZipArchiveDataWrapper.Path : DataWrapperPath {
    public var pathName: String {
        // Zip archive paths are always the full name
        self.path.split(separator: "/").last.flatMap(String.init) ?? self.path
    }

    public var pathSize: UInt64 {
        self.uncompressedSize
    }

    public var pathIsDirectory: Bool {
        self.type == .directory
    }
}

// MARK: Internal Mach-O structures

class MachOBinary {
    enum Error: Swift.Error {
        case binaryOpeningError
        case unknownBinaryFormat
        case codeSignatureCommandMissing
        case signatureReadingError
        case badMagicInSignature
        case unsupportedFatBinary

        var localizedDescription: String {
            switch self {
            case .binaryOpeningError:
                return "Error while opening application binary for reading"
            case .unknownBinaryFormat:
                return "The binary format is not supported"
            case .codeSignatureCommandMissing:
                return "Unable to find code signature load command"
            case .signatureReadingError:
                return "Signature reading error occurred"
            case .unsupportedFatBinary:
                return "Fat application binaries are unsupported"
            case .badMagicInSignature:
                return "The code page magic was incorrect"
            }
        }
    }

    private enum BinaryType {
        struct HeaderData {
            let headerSize: Int
            let commandCount: Int
        }
        case singleArch(headerInfo: HeaderData)
        case fat(header: MachOFatHeader)
    }

    private let binary: SeekableData

    init(binary: SeekableData) throws {
        self.binary = binary.reversedEndian()
    }

    private func getBinaryType(fromSliceStartingAt offset: SeekableData.Offset) throws -> BinaryType? {
        try binary.seek(to: offset)
        let header: MachOHeader = try binary.readBinary()
        let commandCount = Int(header.ncmds)
        switch header.magic {
        case MachOMagic.MH_MAGIC:
            let data = BinaryType.HeaderData(headerSize: MemoryLayout<MachOHeader>.size,
                                             commandCount: commandCount)
            return .singleArch(headerInfo: data)
        case MachOMagic.MH_MAGIC_64:
            let data = BinaryType.HeaderData(headerSize: MemoryLayout<MachOHeader64>.size,
                                             commandCount: commandCount)
            return .singleArch(headerInfo: data)
        default:
            try binary.seek(to: 0)
            let fatHeader: MachOFatHeader = try binary.readBinary()
            return CFSwapInt32(fatHeader.magic) == MachOMagic.FAT_MAGIC ? .fat(header: fatHeader) : nil
        }
    }

    func readEntitlements(fromSliceStartingAt offset: SeekableData.Offset = 0) throws -> [AppEntitlements] {
        switch try getBinaryType(fromSliceStartingAt: offset) {
        case .singleArch(let headerInfo):
            let headerSize = headerInfo.headerSize
            let commandCount = headerInfo.commandCount
            //dbg("singleArch:", "offset:", offset, "headerSize:", headerSize, "commandCount:", commandCount)
            return try readEntitlementsFromBinarySlice(startingAt: offset + .init(headerSize), cmdCount: commandCount)
        case .fat(header: let header):
            return try readEntitlementsFromFatBinary(header)
        case .none:
            throw Error.unknownBinaryFormat
        }
    }

    private func readEntitlementsFromBinarySlice(startingAt offset: SeekableData.Offset, cmdCount: Int) throws -> [AppEntitlements] {
        try binary.seek(to: offset)
        var entitlements: [AppEntitlements] = []
        for _ in 0..<cmdCount {
            //dbg("checking for entitlements in offset:", offset, "index:", index, "count:", cmdCount)
            let command: LoadCommand = try binary.readBinary()
            if command.cmd == MachOMagic.LC_CODE_SIGNATURE {
                let signatureOffset: UInt32 = try binary.readUInt32()
                //dbg("checking for sig in signatureOffset:", signatureOffset, "offset:", offset, "index:", index, "count:", cmdCount)
                if let ent = try readEntitlementsFromSignature(startingAt: signatureOffset) {
                    entitlements.append(ent)
                }
            }
            try binary.seek(to: binary.offset() + .init(command.cmdsize - UInt32(MemoryLayout<LoadCommand>.size)))
        }

        return entitlements
    }

    private func readEntitlementsFromFatBinary(_ header: MachOFatHeader) throws -> [AppEntitlements] {
        let archCount = CFSwapInt32(header.nfat_arch)
        //dbg("readEntitlementsFromFatBinary:", header, "archCount:", archCount)

        if archCount <= 0 {
            throw Error.unsupportedFatBinary
        }

//        let arches: [FatArch] = try (0..<archCount).map { _ in
//            try binary.readBinary()
//        }
        var arches: [FatArch] = []
        for _ in 0..<archCount {
            arches.append(try binary.readBinary())
        }

        var entitlementList: [AppEntitlements] = []

        for arch in arches {
            let offset = CFSwapInt32(arch.offset)
            let size = CFSwapInt32(arch.size)
            //dbg("arch:", "offset:", offset, "size:", size)

            let entitlements: [AppEntitlements]

//            if false {
//                // this should work, but it fails at readEntitlementsFromSignature
//                entitlements = try readEntitlements(fromSliceStartingAt: .init(offset))
//            } else {
                try binary.seek(to: .init(offset))
                let slice = try binary.readData(ofLength: .init(size))
                entitlements = try MachOBinary(binary: SeekableDataHandle(slice)).readEntitlements(fromSliceStartingAt: 0)
//            }

            //dbg("fat binary entitlements:", entitlements)
            entitlementList.append(contentsOf: entitlements)
        }

        return entitlementList

    }

    private func readEntitlementsFromSignature(startingAt offset: UInt32) throws -> AppEntitlements? {
        try binary.seek(to: .init(offset))
        let metaBlob: CSSuperBlob = try binary.readBinary()
        //dbg("checking for magic in superblob at:", offset, ":", CFSwapInt32(metaBlob.magic))
        if CFSwapInt32(metaBlob.magic) != CSMagic.embeddedSignature {
            throw Error.badMagicInSignature
        }

        let metaBlobSize = UInt32(MemoryLayout<CSSuperBlob>.size)
        let blobSize = UInt32(MemoryLayout<CSBlob>.size)
        let itemCount = CFSwapInt32(metaBlob.count)
        //dbg("itemCount:", itemCount)
        for index in 0..<itemCount {
            //dbg("checking code index:", index, "/", itemCount)
            let readOffset = Int(offset + metaBlobSize + index * blobSize)
            try binary.seek(to: SeekableData.Offset(readOffset))
            let blob: CSBlob = try binary.readBinary()
            try binary.seek(to: SeekableData.Offset(offset + CFSwapInt32(blob.offset)))
            let blobMagic = CFSwapInt32(try binary.readUInt32())
            if blobMagic == CSMagic.embededEntitlements {
                let signatureLength = CFSwapInt32(try binary.readUInt32())
                let signatureData = try binary.readData(ofLength: .init(signatureLength) - 8)
                return AppEntitlements.readEntitlements(from: signatureData)
            }
        }

        // no entitlements
        return nil
    }
}

enum MachOMagic {
    static let LC_SEGMENT = UInt32(0x01)
    static let LC_SYMTAB = UInt32(0x02)
    static let LC_DYSYMTAB = UInt32(0x0b)
    static let LC_LOAD_DYLIB = UInt32(0x0c)
    static let LC_ID_DYLIB = UInt32(0x0d)
    static let LC_SEGMENT_64 = UInt32(0x19)
    static let LC_UUID = UInt32(0x1b)
    static let LC_CODE_SIGNATURE = UInt32(0x1d) // MachO.LC_CODE_SIGNATURE
    static let LC_SEGMENT_SPLIT_INFO = UInt32(0x1e)
    //static let LC_REEXPORT_DYLIB = UInt32(0x1f | LC_REQ_DYLD)
    static let LC_ENCRYPTION_INFO = UInt32(0x21)
    static let LC_DYLD_INFO = UInt32(0x22)
    //static let LC_DYLD_INFO_ONLY = UInt32(0x22 | LC_REQ_DYLD)
    static let LC_ENCRYPTION_INFO_64 = UInt32(0x2c)

    static var MH_MAGIC: UInt32 {
        0xfeedface /* MachO.MH_MAGIC */
    }

    static var MH_MAGIC_64: UInt32 {
        0xfeedfacf /* MachO.MH_MAGIC_64 */
    }

    static var FAT_MAGIC: UInt32 {
        0xcafebabe /* MachO.FAT_MAGIC */
    }
}

private extension SeekableData {
    func readBinary<T: BinaryReadable>() throws -> T {
        try T(data: self)
    }
}

private protocol BinaryReadable {
    init(data: SeekableData) throws
}

extension UInt32 : BinaryReadable {
    init(data: SeekableData) throws {
        self = try data.readUInt32()
    }
}

struct CSSuperBlob {
    var magic: UInt32
    var length: UInt32
    var count: UInt32
}

extension CSSuperBlob : BinaryReadable {
    init(data: SeekableData) throws {
        self = try CSSuperBlob(magic: data.readUIntX(), length: data.readUIntX(), count: data.readUIntX())
    }
}

struct CSBlob {
    var type: UInt32
    var offset: UInt32
}

extension CSBlob : BinaryReadable {
    init(data: SeekableData) throws {
        self = try CSBlob(type: data.readUIntX(), offset: data.readUIntX())
    }
}

struct CSMagic {
    static let embeddedSignature: UInt32 = 0xfade0cc0
    static let embededEntitlements: UInt32 = 0xfade7171
}

//const cpuType = {
//  0x00000003: 'i386',
//  0x80000003: 'x86_64',
//  0x00000009: 'arm',
//  0x80000009: 'arm64',
//  0x00000000: 'arm64',
//  0x0000000a: 'ppc_32',
//  0x8000000a: 'ppc_64'
//};

typealias cpu_type_t = Int32
typealias cpu_subtype_t = Int32
typealias cpu_threadtype_t = Int32

struct MachOHeader {
    var magic: UInt32 /* mach magic number identifier */
    var cputype: cpu_type_t /* cpu specifier */
    var cpusubtype: cpu_subtype_t /* machine specifier */
    var filetype: UInt32 /* type of file */
    var ncmds: UInt32 /* number of load commands */
    var sizeofcmds: UInt32 /* the size of all the load commands */
    var flags: UInt32 /* flags */
}

extension MachOHeader : BinaryReadable {
    init(data: SeekableData) throws {
        self = try MachOHeader(magic: data.readUIntX(), cputype: data.readInt32(), cpusubtype: data.readInt32(), filetype: data.readUIntX(), ncmds: data.readUIntX(), sizeofcmds: data.readUIntX(), flags: data.readUIntX())
    }
}

/*
 * The 64-bit mach header appears at the very beginning of object files for
 * 64-bit architectures.
 */
struct MachOHeader64 {
    var magic: UInt32 /* mach magic number identifier */
    var cputype: cpu_type_t /* cpu specifier */
    var cpusubtype: cpu_subtype_t /* machine specifier */
    var filetype: UInt32 /* type of file */
    var ncmds: UInt32 /* number of load commands */
    var sizeofcmds: UInt32 /* the size of all the load commands */
    var flags: UInt32 /* flags */
    var reserved: UInt32 /* reserved */
}

struct MachOFatHeader {
    var magic: UInt32 /* FAT_MAGIC or FAT_MAGIC_64 */
    var nfat_arch: UInt32 /* number of structs that follow */
}

extension MachOFatHeader : BinaryReadable {
    init(data: SeekableData) throws {
        self = try MachOFatHeader(magic: data.readUIntX(), nfat_arch: data.readUIntX())
    }
}

// mach-o loader.h `load_command`
struct LoadCommand {
    public var cmd: UInt32 /* type of load command */
    public var cmdsize: UInt32 /* total size of command in bytes */
}

extension LoadCommand : BinaryReadable {
    init(data: SeekableData) throws {
        self = try LoadCommand(cmd: data.readUIntX(), cmdsize: data.readUIntX())
    }
}

/// From mach-o fat.h: `struct fat_arch`222
struct FatArch {
    var cputype: cpu_type_t /* cpu specifier (int) */
    var cpusubtype: cpu_subtype_t /* machine specifier (int) */
    var offset: UInt32 /* file offset to this object file */
    var size: UInt32 /* size of this object file */
    var align: UInt32 /* alignment as a power of 2 */
}

extension FatArch : BinaryReadable {
    init(data: SeekableData) throws {
        self = try FatArch(cputype: data.readInt32(), cpusubtype: data.readInt32(), offset: data.readUIntX(), size: data.readUIntX(), align: data.readUIntX())
    }
}
