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
import FairApp

public final class AppCatalogAPI {
    public static let shared = AppCatalogAPI()

    private init() {
    }

    //    /// Create a catalog of multiple artifacts.
    //    public func catalogApps(urls: [URL], options: SourceOptions? = nil, clearDownload: Bool = true) async throws -> AppCatalog {
    //        var items: [AppCatalogItem] = []
    //        for url in urls {
    //            items.append(try await catalogApp(url: url, options: options, clearDownload: clearDownload))
    //        }
    //        return AppCatalog(name: options?.catalogName ?? "CATALOG", identifier: options?.catalogIdentifier ?? "IDENTIFIER", apps: items)
    //    }

    /// Create a catalog item for an individual artifact.
    public func catalogApp(url: URL, options: SourceOptions? = nil, clearDownload: Bool = true) async throws -> AppCatalogItem {
        dbg("url:", url)
        let (downloaded, localURL) = url.isFileURL ? (false, url) : (true, try await URLSession.shared.downloadFile(for: URLRequest(url: url)).localURL)
        dbg("localURL:", localURL)
        if !FileManager.default.isReadableFile(atPath: localURL.path) {
            throw AppError(String(format: NSLocalizedString("Cannot read file at %@", bundle: .module, comment: "error message"), arguments: [localURL.path]))
        }

        defer {
            // if we downloaded the IPA in order to scan it, remove it once we are done
            if clearDownload && downloaded {
                dbg("removing temporary download file: \(localURL.path)")
                try? FileManager.default.removeItem(at: localURL)
            }
        }

        let (info, entitlements) = try await AppBundleLoader.loadInfo(fromAppBundle: localURL)

        //var item = AppCatalogItem(name: bundleName, bundleIdentifier: bundleID, downloadURL: url)
        guard var item = try info.appCatalogInfo(downloadURL: url) else {
            throw AppError(NSLocalizedString("Cannot build catalog from Info.plist", bundle: .module, comment: "error message"))
        }

        item.version = info.CFBundleShortVersionString
        item.size = localURL.fileSize()

        let defvalue = { options?.defaultValue(from: $0, bundleIdentifier: item.bundleIdentifier) }

        item.downloadURL = defvalue(\.appDownloadURL).flatMap(URL.init(string:)) ?? url

        // fill in some placeholders, defaulting in information from the `AppSource` dictionary if it is present
        item.subtitle = item.subtitle ?? defvalue(\.appSubtitle) ?? "SUBTITLE"
        item.developerName = item.developerName ?? defvalue(\.appDeveloperName) ?? "DEVELOPER_NAME"
        item.localizedDescription = item.localizedDescription ?? defvalue(\.appLocalizedDescription) ?? "LOCALIZED_DESCRIPTION" // maybe check for a README file in the .ipa?
        item.versionDescription = item.versionDescription ?? defvalue(\.appVersionDescription) ?? "VERSION_DESCRIPTION" // maybe check for a CHANGELOG file in the .ipa

        var cats = item.categories ?? []
        if let appCategory = info.stringValue(for: .LSApplicationCategoryType) {
            let cat = AppCategoryType(rawValue: appCategory)
            if AppCategoryType.allCases.contains(cat) { // app category needs to exist to add
                cats.append(cat)
            }
        }
        if let secondaryAppCategory = info.stringValue(for: .LSApplicationSecondaryCategoryType) {
            let cat2 = AppCategoryType(rawValue: secondaryAppCategory)
            if AppCategoryType.allCases.contains(cat2) { // app category needs to exist to add
                cats.append(cat2)
            }
        }
        item.categories = cats

        // item.iconURL = … // if we were ambitious, we could try to extract the icon from the artifact and embed a data: url
        // item.tintColor = … // if we were ambitious, we could parse the assets and extract the tint color

        item.screenshotURLs = [] // maybe check for a folder in the .ipa?

        item.versionDate = localURL.creationDate

        var permissions: [AppPermission] = []
        for (key, value) in info.usageDescriptions {
            permissions.append(AppPermission(AppUsagePermission(usage: UsageDescriptionKey(key), usageDescription: value)))
        }

        for backgroundMode in info.backgroundModes ?? [] {
            permissions.append(AppPermission(AppBackgroundModePermission(backgroundMode: AppBackgroundMode(backgroundMode), usageDescription: "USAGE DESCRIPTION"))) // TODO: extract usage description
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

        // benchmarking a catalog of 88 apps: 17.9 seconds without any hashing, 35.48 seconds with Data(contentsOfURL:).sha256() hashing, 1,492.87 seconds (release config) with async URLSession.shared.sha256(for:) hashing
        //item.sha256 = try await URLSession.shared.sha256(for: localURL).hex() // 42 times slower!
        item.sha256 = try Data(contentsOf: localURL, options: .mappedIfSafe).sha256().hex() // without alwaysMapped or mappedIfSafe, memory seems to grow

        return item

        // return apps.mapAsync({ try await verifyAppItem(app: $0, catalogURL: catalogURL) })

    }

    private func addFailure(to failures: inout [AppCatalogVerifyFailure], app: AppCatalogItem, _ failure: AppCatalogVerifyFailure, msg: ((MessagePayload) -> ())?) {
        msg?((.warn, ["app verify failure for \(app.downloadURL?.absoluteString ?? "nourl"): \(failure.type) \(failure.message)"]))
        failures.append(failure)
    }


    /// Verified that the information in the given ``AppCatalogItem`` is valid for
    /// the resource at the given URL.
    public func verifyAppItem(app: AppCatalogItem, catalogURL: URL?, msg: ((MessagePayload) -> ())? = nil) async throws -> AppCatalogVerifyResult {
        var failures: [AppCatalogVerifyFailure] = []

        if app.sha256 == nil {
            addFailure(to: &failures, app: app, AppCatalogVerifyFailure(type: "missing_checksum", message: "App missing sha256 checksum property"), msg: msg)
        }
        if (app.size ?? 0) <= 0 {
            addFailure(to: &failures, app: app, AppCatalogVerifyFailure(type: "invalid_size", message: "App size property unset or invalid"), msg: msg)
        }

        if var url = app.downloadURL {
            if url.scheme == nil {
                // permit URLs relative to the catalog URL
                url = catalogURL?.deletingLastPathComponent().appendingPathComponent(url.path) ?? url
            }
            do {
                dbg("verifying app at URL:", url.absoluteString)
                let (file, _) = url.isFileURL ? (url, nil) : try await URLSession.shared.downloadFile(for: URLRequest(url: url))
                failures.append(contentsOf: await validateArtifact(app: app, file: file))
            } catch {
                addFailure(to: &failures, app: app, AppCatalogVerifyFailure(type: "download_failed", message: "Failed to download app from: \(url.absoluteString)"), msg: msg)
            }
        } else {
            addFailure(to: &failures, app: app, AppCatalogVerifyFailure(type: "missing_url", message: "No download URL"), msg: msg)
        }
        return AppCatalogVerifyResult(app: app, failures: failures.isEmpty ? nil : failures)
    }

    func validateArtifact(app: AppCatalogItem, file: URL, msg: ((MessagePayload) -> ())? = nil) async -> [AppCatalogVerifyFailure] {
        var failures: [AppCatalogVerifyFailure] = []

        if !file.isFileURL || !FileManager.default.isReadableFile(atPath: file.path) {
            addFailure(to: &failures, app: app, AppCatalogVerifyFailure(type: "missing_file", message: "Download file \(file.path) does not exist for: \(app.downloadURL?.absoluteString ?? "nourl")"), msg: msg)
            return failures
        }

        if let size = app.size {
            if let fileSize = file.fileSize() {
                if size != fileSize {
                    addFailure(to: &failures, app: app, AppCatalogVerifyFailure(type: "size_mismatch", message: "Download size mismatch (\(size) vs. \(fileSize)) from: \(app.downloadURL?.absoluteString ?? "nourl")"), msg: msg)
                }
            }
        }

        if let sha256 = app.sha256,
           let fileData = try? await Data(contentsOf: file) {
            let fileChecksum = fileData.sha256()
            if sha256 != fileChecksum.hex() {
                addFailure(to: &failures, app: app, AppCatalogVerifyFailure(type: "checksum_failed", message: "Checksum mismatch (\(sha256) vs. \(fileChecksum.hex())) from: \(app.downloadURL?.absoluteString ?? "nourl")"), msg: msg)
            }
        }

        func verifyInfoUsageDescriptions(_ info: Plist) {
            let usagePermissions: [UsageDescriptionKey: AppUsagePermission] = (app.permissions ?? []).compactMap({ $0.infer()?.infer()?.infer() }).dictionary(keyedBy: \.identifier)

            for (permissionKey, permissionValue) in info.usageDescriptions {
                guard let catalogPermissionValue = usagePermissions[.init(permissionKey)] else {
                    addFailure(to: &failures, app: app, AppCatalogVerifyFailure(type: "usage_description_missing", message: "Missing a permission entry for usage key “\(permissionKey)”"), msg: msg)
                    continue
                }

                if catalogPermissionValue.usageDescription != permissionValue {
                    addFailure(to: &failures, app: app, AppCatalogVerifyFailure(type: "usage_description_mismatch", message: "The usage key “\(permissionKey)” defined in Info.plist does not have a matching value in the catalog metadata"), msg: msg)
                }
            }
        }

        func verifyBackgroundModes(_ info: Plist) {
            guard let backgroundModes = info.backgroundModes else {
                return // no background modes
            }

            let backgroundPermissions: [AppBackgroundMode: AppBackgroundModePermission] = (app.permissions ?? []).compactMap({ $0.infer()?.infer()?.infer() }).dictionary(keyedBy: \.identifier)

            for backgroundMode in backgroundModes {
                if backgroundPermissions[AppBackgroundMode(backgroundMode)] == nil {
                    addFailure(to: &failures, app: app, AppCatalogVerifyFailure(type: "missing_background_mode", message: "Missing a permission entry for background mode “\(backgroundMode)”"), msg: msg)
                }
            }
        }

        func verifyEntitlements(_ entitlements: AppEntitlements) {
            let entitlementPermissions: [AppEntitlement: AppEntitlementPermission] = (app.permissions ?? []).compactMap({ $0.infer() }).dictionary(keyedBy: \.identifier)

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
                    addFailure(to: &failures, app: app, AppCatalogVerifyFailure(type: "missing_entitlement_permission", message: "Missing a permission entry for entitlement key “\(entitlementKey)”"), msg: msg)
                }
            }
        }

        do {
            let (info, entitlementss) = try await AppBundleLoader.loadInfo(fromAppBundle: file)

            // ensure each *UsageDescription Info.plist property is also surfaced in the catalog metadata permissions
            verifyInfoUsageDescriptions(info)

            // ensure each of the background modes are documented
            verifyBackgroundModes(info)

            if entitlementss == nil {
                addFailure(to: &failures, app: app, AppCatalogVerifyFailure(type: "entitlements_missing", message: "No entitlements found in \(app.downloadURL?.absoluteString ?? "nourl")"), msg: msg)
            } else {
                for entitlements in entitlementss ?? [] {
                    verifyEntitlements(entitlements)
                }
            }
        } catch {
            addFailure(to: &failures, app: app, AppCatalogVerifyFailure(type: "bundle_load_failed", message: "Could not load bundle information for \(app.downloadURL?.absoluteString ?? "nourl"): \(error)"), msg: msg)
        }

        return failures
    }

    /// A single `AppCatalogItem` entry from a catalog along with a list of validation failures
    public struct AppCatalogVerifyResult : FairCommandOutput, Decodable {
        public var app: AppCatalogItem
        public var failures: [AppCatalogVerifyFailure]?
    }

    //@available(*, deprecated, message: "move into central validation code")
    public struct AppCatalogVerifyFailure : FairCommandOutput, Decodable {
        /// The type of failure
        public var type: String

        /// A string describing the verification failure
        public var message: String
    }


}

/// https://docs.fastlane.tools/actions/deliver/#available-metadata-folder-options
public struct AppMetadata : Codable {
    // Non-Localized Metadata
    public var copyright: String? // copyright.txt
    public var primary_category: String? // primary_category.txt
    public var secondary_category: String? // secondary_category.txt
    public var primary_first_sub_category: String? // primary_first_sub_category.txt
    public var primary_second_sub_category: String? // primary_second_sub_category.txt
    public var secondary_first_sub_category: String? // secondary_first_sub_category.txt
    public var secondary_second_sub_category: String? // secondary_second_sub_category.txt

    // Localized Metadata
    public var name: String? // <lang>/name.txt
    public var subtitle: String? // <lang>/subtitle.txt
    public var privacy_url: String? // <lang>/privacy_url.txt
    public var apple_tv_privacy_policy: String? // <lang>/apple_tv_privacy_policy.txt
    public var description: String? // <lang>/description.txt
    public var keywords: String? // <lang>/keywords.txt
    public var release_notes: String? // <lang>/release_notes.txt
    public var support_url: String? // <lang>/support_url.txt
    public var marketing_url: String? // <lang>/marketing_url.txt
    public var promotional_text: String? // <lang>/promotional_text.txt

    // Review Information
    public var first_name: String? // review_information/first_name.txt
    public var last_name: String? // review_information/last_name.txt
    public var phone_number: String? // review_information/phone_number.txt
    public var email_address: String? // review_information/email_address.txt
    public var demo_user: String? // review_information/demo_user.txt
    public var demo_password: String? // review_information/demo_password.txt
    public var notes: String? // review_information/notes.txt

    // Locale-specific metadata
    public var localizations: [String: AppMetadata]?

    public enum CodingKeys : String, CodingKey, CaseIterable {
        case copyright
        case primary_category
        case secondary_category
        case primary_first_sub_category
        case primary_second_sub_category
        case secondary_first_sub_category
        case secondary_second_sub_category

        case name
        case subtitle
        case privacy_url
        case apple_tv_privacy_policy
        case description
        case keywords
        case release_notes
        case support_url
        case marketing_url
        case promotional_text

        case first_name
        case last_name
        case phone_number
        case email_address
        case demo_user
        case demo_password
        case notes

        case localizations
    }
}

