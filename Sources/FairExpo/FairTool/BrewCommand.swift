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

public struct BrewCommand : AsyncParsableCommand {
    public static let experimental = true
    public static var configuration = CommandConfiguration(commandName: "brew",
                                                           abstract: "Homebrew appcask configuration commands.",
                                                           shouldDisplay: !experimental,
                                                           subcommands: [
                                                            AppCasksCommand.self,
                                                           ])

    public init() {
    }

    public struct AppCasksCommand: FairParsableCommand {
        public static let experimental = false
        public typealias Output = Never
        public static var configuration = CommandConfiguration(commandName: "appcasks",
                                                               abstract: "Build the enhanced appcasks catalog.",
                                                               shouldDisplay: !experimental)
        @OptionGroup public var msgOptions: MsgOptions
        @OptionGroup public var hubOptions: HubOptions
        @OptionGroup public var retryOptions: RetryOptions
        @OptionGroup public var outputOptions: OutputOptions
        @OptionGroup public var sourceOptions: SourceOptions

        @Option(name: [.long, .customShort("C")], help: ArgumentHelp("The name of the hub's base casks repository.", valueName: "repo"))
        public var casksRepo: String = "appcasks"

        @Option(name: [.long], help: ArgumentHelp("The maximum number of apps to include.", valueName: "count"))
        public var maxApps: Int?

        @Option(name: [.long], help: ArgumentHelp("The cask query size for the request.", valueName: "count"))
        public var caskQueryCount: Int = 10

        @Option(name: [.long], help: ArgumentHelp("The release query size for the request.", valueName: "count"))
        public var releaseQueryCount: Int = 10

        @Option(name: [.long], help: ArgumentHelp("The asset query size for the request.", valueName: "count"))
        public var assetQueryCount: Int = 10

        @Option(name: [.long], help: ArgumentHelp("The endpoint containing additional metadata.", valueName: "url"))
        public var mergeCaskInfo: String?

        @Option(name: [.long], help: ArgumentHelp("The endpoint containing cask stats.", valueName: "url"))
        public var mergeCaskStats: String?

        @Option(name: [.long], help: ArgumentHelp("App ids to boost in catalog.", valueName: "apps"))
        public var boostApps: [String] = [] // each string can also delimit multiple apps with a "|" separator

        @Option(name: [.long], help: ArgumentHelp("Ranking increase for boosted apps.", valueName: "factor"))
        public var boostFactor: Int64?

        @Flag(name: [.long], help: ArgumentHelp("Whether to include funding source info.", valueName: "funding"))
        public var fundingSources: Bool = false

        @Option(name: [.long], help: ArgumentHelp("The topic whose tagged repos will be indexed.", valueName: "topic"))
        public var topicName: String?

        @Option(name: [.long], help: ArgumentHelp("The user whose starred repos will be indexed.", valueName: "user"))
        public var starrerName: String?

        public init() { }

        public mutating func run() async throws {
            warnExperimental(Self.experimental)
            msg(.info, "Generating appcasks app source catalog")
            try await retryOptions.retrying() {
                try await createAppCasks()
            }
        }

        private func createAppCasks() async throws {
            let hub = try hubOptions.fairHub()

            let appids = boostApps
                .map { $0.split(separator: "|") }
                .joined()
                .map { (String($0), 1) }

            // sum up duplicate boosts to get the count
            let boostMap: [String : Int] = Dictionary(appids) { $0 + $1 }

            let catalogName = sourceOptions.catalogName ?? "appcasks"
            let catalogIdentifier = sourceOptions.catalogIdentifier ?? "identifier"
            let mergeCasksURL = mergeCaskInfo.flatMap(URL.init(string:))
            let caskStatsURL = mergeCaskStats.flatMap(URL.init(string:))

            // build the catalog filtering on specific artifact extensions
            var catalog = try await hub.buildAppCasks(owner: hubOptions.organizationName, catalogName: catalogName, catalogIdentifier: catalogIdentifier,  baseRepository: self.casksRepo, topicName: topicName, starrerName: starrerName, maxApps: maxApps, mergeCasksURL: mergeCasksURL, caskStatsURL: caskStatsURL, boostMap: boostMap, boostFactor: boostFactor, caskQueryCount: caskQueryCount, releaseQueryCount: releaseQueryCount, assetQueryCount: assetQueryCount, msg: {
                self.msg(.debug, $0, $1, $2, $3, $4, $5, $6, $7, $8, $9)
            })

            if fundingSources {
                catalog.fundingSources = try await hub.buildFundingSources(owner: hubOptions.organizationName, baseRepository: self.casksRepo)
            }
            let json = try outputOptions.writeCatalog(catalog)
            msg(.info, "Wrote", catalog.apps.count, "appcasks to", outputOptions.output, json.count)
        }
    }
}

