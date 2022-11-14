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
import Foundation
import FairApp

extension FairCommand {

    public struct MetadataCommand: FairStructuredCommand {
        public typealias Output = AppMetadata
        public static let experimental = false
        public static var configuration = CommandConfiguration(commandName: "metadata",
                                                               abstract: "Output metadata for the given app.",
                                                               shouldDisplay: !experimental)
        @OptionGroup public var msgOptions: MsgOptions
        @OptionGroup public var outputOptions: OutputOptions

        @Option(name: [.long, .customShort("x")], help: ArgumentHelp("Export deliver metadata folder.", valueName: "dir"))
        public var export: String?

        @Option(name: [.long, .customShort("k")], help: ArgumentHelp("The root key containg the app metadata.", valueName: "key"))
        public var key: String = "app"

        @Argument(help: ArgumentHelp("Path to the metadata file", valueName: "App.yml", visibility: .default))
        public var yaml: [String] = ["App.yml"]

        public init() { }

        public func executeCommand() async throws -> AsyncThrowingStream<AppMetadata, Error> {
            warnExperimental(Self.experimental)
            return executeSeries(yaml, initialValue: nil) { yaml, prev in
                msg(.info, "parsing metadata:", yaml)
                let json = try JSum.parse(yaml: String(contentsOf: URL(fileOrScheme: yaml), encoding: .utf8))
                guard let appJSON = json[key]?.obj else {
                    throw AppError(String(format: NSLocalizedString("Could not find key in YAML: %@", bundle: .module, comment: "error message"), arguments: [key]))
                }

                let appMeta = try AppMetadata(json: appJSON.json())

                if let export = export {
                    let exportURL = URL(fileURLWithPath: export, isDirectory: true)

                    func saveMetadata(locale: String?, meta: AppMetadata) throws {
                        func save(_ value: String?, review: Bool = false, _ key: AppMetadata.CodingKeys) throws {
                            guard let value = value else {
                                return
                            }

                            var outputURL = exportURL
                            if let locale = locale {
                                outputURL = URL(fileURLWithPath: locale, isDirectory: true, relativeTo: outputURL)
                            }
                            if review {
                                outputURL = URL(fileURLWithPath: "review_information", isDirectory: true, relativeTo: outputURL)
                            }

                            try FileManager.default.createDirectory(at: outputURL, withIntermediateDirectories: true)

                            let path = URL(fileURLWithPath: key.rawValue, relativeTo: outputURL)
                            let file = path.appendingPathExtension("txt")
                            try value.write(to: file, atomically: false, encoding: .utf8)
                        }

                        for key in AppMetadata.CodingKeys.allCases {
                            switch key {
                            case .copyright: try save(meta.copyright, .copyright)
                            case .primary_category: try save(meta.primary_category, .primary_category)
                            case .secondary_category: try save(meta.secondary_category, .secondary_category)
                            case .primary_first_sub_category: try save(meta.primary_first_sub_category, .primary_first_sub_category)
                            case .primary_second_sub_category: try save(meta.primary_second_sub_category, .primary_second_sub_category)
                            case .secondary_first_sub_category: try save(meta.secondary_first_sub_category, .secondary_first_sub_category)
                            case .secondary_second_sub_category: try save(meta.secondary_second_sub_category, .secondary_second_sub_category)

                            case .name: try save(meta.name, .name)
                            case .subtitle: try save(meta.subtitle, .subtitle)
                            case .privacy_url: try save(meta.privacy_url, .privacy_url)
                            case .apple_tv_privacy_policy: try save(meta.apple_tv_privacy_policy, .apple_tv_privacy_policy)
                            case .description: try save(meta.description, .description)
                            case .keywords: try save(meta.keywords, .keywords)
                            case .release_notes: try save(meta.release_notes, .release_notes)
                            case .support_url: try save(meta.support_url, .support_url)
                            case .marketing_url: try save(meta.marketing_url, .marketing_url)
                            case .promotional_text: try save(meta.promotional_text, .promotional_text)

                            case .first_name: try save(meta.first_name, review: true, .first_name)
                            case .last_name: try save(meta.last_name, review: true, .last_name)
                            case .phone_number: try save(meta.phone_number, review: true, .phone_number)
                            case .email_address: try save(meta.email_address, review: true, .email_address)
                            case .demo_user: try save(meta.demo_user, review: true, .demo_user)
                            case .demo_password: try save(meta.demo_password, review: true, .demo_password)
                            case .notes: try save(meta.notes, review: true, .notes)

                            case .locales: break
                            }
                        }
                    }

                    // save the root metadatum
                    try saveMetadata(locale: nil, meta: appMeta)

                    // save the localized app metadatas
                    for (localeName, localizedAppMeta) in appMeta.locales ?? [:] {
                        try saveMetadata(locale: localeName, meta: localizedAppMeta)
                    }
                }
                return appMeta
            }
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
        public var locales: [String: AppMetadata]?

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

            case locales
        }
    }

}

