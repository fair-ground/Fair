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
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// We need an upper bound for the number of forks we can process
/// GitHub defaults to a rate limit of 5,000 requests per hour, so
/// this permits 5,000 requests as 100/per, but doesn't leave any
/// margin for multiple catalog runs in an hour, which can cause
/// fairseal generation to fail if the rate limit is exhausted
public let appfairMaxApps = 250_000

/// The organization name of the fair-ground: `"appfair"`
/// @available(*, deprecated, message: "move to hub configuration")
public let appfairName = "appfair"

public let appfairRoot = URL(string: "https://www.appfair.net")!

/// The canonical location of the catalog for the Fair Ground
public let appfairCatalogURLMacOS = URL(string: "fairapps-macos.json", relativeTo: appfairRoot)!

/// The canonical location of the iOS catalog for the Fair Ground
public let appfairCatalogURLIOS = URL(string: "fairapps-ios.json", relativeTo: appfairRoot)!

/// The canonical location of the enhanced cask app metadata
public let appfairCaskAppsURL = URL(string: "appcasks.json", relativeTo: appfairRoot)!

public let appfairCaskAppsName = "App Fair AppCasks"
public let appfairCaskAppsIdentifier = "net.appfair.appcasks"

/// A `GraphQL` endpoint
public protocol GraphQLEndpointService : EndpointService {
    /// The default headers that will be sent with a request
    var requestHeaders: [String: String] { get }
}

/// A Fair Ground based on an online git service such as GitHub or GitLab.
public struct FairHub : GraphQLEndpointService {
    /// The root of the FairGround-compatible service
    public var baseURL: URL

    /// The organization in the hub
    public var org: String

    /// The authorization token for this request, if any
    public var authToken: String?

    /// The username of the issuer of the fairseal, user for querying purposes
    public var fairsealIssuer: String?

    /// The signing key for the seal data, used to authenticate payloads
    public var fairsealKey: Data?

    public typealias BaseFork = FairHub.CatalogForksQuery.QueryResponse.BaseRepository.Repository
    public typealias AppCaskFork = AppCasksQuery.QueryResponse.BaseRepository.Repository

    /// The FairHub is initialized with a host identifier (e.g., "github.com/appfair") that corresponds to the hub being used.
    public init(hostOrg: String, authToken: String? = nil, fairsealIssuer: String?, fairsealKey: Data?) throws {
        guard let url = URL(string: "https://api." + hostOrg) else {
            throw Errors.badHostOrg(hostOrg)
        }

        self.org = url.lastPathComponent
        self.baseURL = url.deletingLastPathComponent()
        self.authToken = authToken
        self.fairsealIssuer = fairsealIssuer
        self.fairsealKey = fairsealKey

        if org.isEmpty {
            throw Errors.emptyOrganization(url)
        }
        if self.baseURL.path != "/" {
            throw Errors.notTopLevelURL(url)
        }
        if self.baseURL.scheme != "https" {
            throw Errors.badURLScheme(url)
        }
        if let authToken = authToken {
            if authToken.isEmpty {
                throw Errors.emptyAuthToken
            }
        }
    }

    /// The hardwired code that returns an HTTP error but contains information about backing off
    /// 403 is just retry
    /// 502 sometimes happens with large responses
    public static var backoffCodes: IndexSet { IndexSet([403, 502]) }
}

public struct ArtifactTarget : Codable, Hashable {
    public let artifactType: String
    public let devices: Array<String>

    public init(artifactType: String, devices: Array<String>) {
        self.artifactType = artifactType
        self.devices = devices
    }
}

extension FairHub {
    struct ProjectConfiguration {
        /// The regular expression patterns of allowed app names
        var allowName: [NSRegularExpression]

        /// The regular expression patterns of disallowed app names
        var denyName: [NSRegularExpression]

        /// The regular expression patterns of allowed e-mail addresses
        var allowFrom: [NSRegularExpression]

        /// The regular expression patterns of disallowed e-mail addresses
        var denyFrom: [NSRegularExpression]

        /// The license (SPDX IDs) of permitted licenses, such as: "AGPL-3.0"
        var allowLicense: [String]

        init(allowName: [String] = [], denyName: [String] = [], allowFrom: [String] = [], denyFrom: [String] = [], allowLicense: [String] = []) throws {
            let regexs = { try NSRegularExpression(pattern: $0, options: [.caseInsensitive]) }
            self.allowFrom = try allowFrom.map(regexs)
            self.denyFrom = try denyFrom.map(regexs)
            self.allowName = try allowName.map(regexs)
            self.denyName = try denyName.map(regexs)

            self.allowLicense = allowLicense
        }

        /// Validates that the app name is included in the `allow-name` patterns and not included in the `deny-name` list of expressions.
        func validateAppName(_ name: String?) throws {
            guard let name = name, try permitted(value: name, allow: allowName, deny: denyName) == true else {
                throw FairHub.Errors.invalidName(name)
            }
        }

        private func permitted(value: String, allow: [NSRegularExpression], deny: [NSRegularExpression]) throws -> Bool {
            func matches(pattern: NSRegularExpression) -> Bool {
                pattern.firstMatch(in: value, options: [], range: value.span) != nil
            }

            // if we specified an allow list, then at least one of the patterns must match the email
            if !allow.isEmpty {
                guard let _ = allow.first(where: matches) else {
                    throw FairHub.Errors.valueNotAllowed(value)
                }
            }

            // conversely, if we specified a deny list, then all the addresses must not match
            if !deny.isEmpty {
                if let _ = deny.first(where: matches) {
                    throw FairHub.Errors.valueDenied(value)
                }
            }

            return true
        }

        /// Validates that the e-mail address is included in the `allow-from` patterns and not included in the `deny-from` list of expressions.
        func validateEmailAddress(_ email: String?) throws {
    //        guard let email = email, try permitted(value: email, allow: allowFrom, deny: denyFrom) == true else {
    //            throw Errors.invalidEmail(email)
    //        }
        }

    }

    /// Generates the catalog by fetching all the valid forks of the base fair-ground and associating them with the fairseals published by the fairsealIssuer.
    func buildCatalog(title: String, owner: String, baseRepository: String, fairsealCheck: Bool, artifactTarget: ArtifactTarget, configuration: ProjectConfiguration, requestLimit: Int?) async throws -> AppCatalog {
        // all the seal hashes we will look up to validate releases
        dbg("fetching fairseals")

        var apps: [AppCatalogItem] = []
        for try await app in createAppCatalogItemsFromForks(title: title, owner: owner, baseRepository: baseRepository, fairsealCheck: fairsealCheck, artifactTarget: artifactTarget, configuration: configuration, requestLimit: requestLimit) {
            apps.append(contentsOf: app)
        }
        let news: [AppNewsPost]? = nil

        // in order to minimize catalog changes, always sort by the bundle name
        apps.sort { $0.bundleIdentifier < $1.bundleIdentifier }

        let catalogURL = artifactTarget.devices.contains("mac") ? appfairCatalogURLMacOS : appfairCatalogURLIOS
        let catalog = AppCatalog(name: title, identifier: org, sourceURL: catalogURL, apps: apps, news: news)
        return catalog
    }

    func createAppCatalogItemsFromForks(title: String, owner: String, baseRepository: String, fairsealCheck: Bool, artifactTarget: ArtifactTarget, configuration: ProjectConfiguration, requestLimit: Int?) -> AsyncThrowingMapSequence<AsyncThrowingStream<CatalogForksQuery.Response, Error>, [AppCatalogItem]> {
        sendCursoredRequest(CatalogForksQuery(owner: owner, name: baseRepository))
            .map { forks in try deriveCatalogItems(forks, artifactTarget: artifactTarget, fairsealCheck: fairsealCheck, configuration: configuration) }
    }

    private func deriveCatalogItems(_ forks: CatalogForksQuery.Response, artifactTarget: ArtifactTarget, fairsealCheck: Bool, configuration: ProjectConfiguration) throws -> [AppCatalogItem] {
        guard let fairsealIssuer = fairsealIssuer else {
            throw Errors.missingFairsealIssuer
        }

        let forkNodes = try forks.result.get().data.repository.forks.nodes
        //print(wip("#####"), forkNodes.map(\.nameWithOwner))
        var apps: [AppCatalogItem] = []

        for fork in forkNodes {
            dbg("checking app fork:", fork.owner.appNameWithSpace, fork.name)
            // #warning("TODO validation")
            //            let invalid = validate(org: fork.owner)
            //            if !invalid.isEmpty {
            //                throw Errors.repoInvalid(invalid, org, fork.name)
            //            }
            let appTitle = fork.owner.appNameWithSpace // un-hyphenated name
            let appid = fork.owner.appNameWithHyphen

            let bundleIdentifier = "app." + appid
            let subtitle = fork.description ?? ""
            let localizedDescription = fork.description ?? "" // these should be different; perhaps extract the first paragraph from the README?

            let starCount = fork.stargazerCount
            let watcherCount = fork.watchers.totalCount
            let issueCount = fork.issues.totalCount

            // get the "appfair-utilities" topic and convert it to the standard "public.app-category.utilities"
            let categories = (fork.repositoryTopics.nodes ?? []).map(\.topic.name).compactMap({
                AppCategory.topics[$0]?.metadataIdentifier
            })

            var fairsealBetaFound = false
            var fairsealFound = false
            for release in (fork.releases.nodes ?? []) {
                guard let appVersion = AppVersion(string: release.tag.name, prerelease: release.isPrerelease) else {
                    dbg("invalid release tag:", release.tag.name)
                    continue
                }
                dbg("  checking release:", fork.nameWithOwner, appVersion.versionString)

                // commite in the web will be "GitHub Web Flow" and either empty e-mail or "noreply@github.com"
                //let developerEmail = release.tagCommit.signature?.signer.email
                //let developerName = release.tagCommit.signature?.signer.name

                let devName = release.tagCommit.author?.name

                // if there is no homepage explicitly set, use the standard github page
                let page = fork.homepageUrl ?? "https://\(appid).github.io/App"
                let homepage = URL(string: page)

                guard let devEmail = release.tagCommit.author?.email else {
                    dbg(fork.nameWithOwner, "no email for commit")
                    continue
                }

                do {
                    try configuration.validateEmailAddress(devEmail)
                } catch {
                    // skip packages whose e-mail addresses are not valid
                    dbg(fork.nameWithOwner, "invalid committer email:", error)
                    continue
                }

//                guard let orgEmail = fork.owner.email else {
//                    dbg(fork.nameWithOwner, "missing org email")
//                    continue
//                }
//                do {
//                    try validateEmailAddress(orgEmail)
//                } catch {
//                    // skip packages whose e-mail addresses are not valid
//                    dbg(fork.nameWithOwner, "invalid owner email:", error)
//                    continue
//                }
//
//                if orgEmail != devEmail {
//                    dbg(fork.nameWithOwner, "org email must match commit email")
//                    continue
//                }

                let appName = fork.owner.login

                do {
                    try configuration.validateAppName(appName)
                } catch {
                    // skip packages whose names are not valid
                    dbg(fork.nameWithOwner, "invalid app name:", error)
                    continue
                }

                let developerInfo: String

                if let devName = devName, !devName.isEmpty {
                    developerInfo = "\(devName) <\(devEmail)>"
                } else {
                    developerInfo = devEmail
                }
                let versionDate = release.createdAt
                let versionDescription = release.description
                let iconURL = release.releaseAssets.nodes.first { asset in
                    asset.name == "\(appid).png" // e.g. "Fair-Skies.png"
                }?.downloadUrl

                let beta: Bool = release.isPrerelease

                func releaseAsset(named name: String) -> ReleaseAsset? {
                    release.releaseAssets.nodes.first(where: { node in
                        node.name == name
                    })
                }

                for artifactTarget in [artifactTarget] {
                    let artifactType = artifactTarget.artifactType
                    dbg("checking target:", appName, fork.name, appVersion.versionString, "type:", artifactType, "files:", release.releaseAssets.nodes.map(\.name))
                    guard let appArtifact = release.releaseAssets.nodes.first(where: { node in
                        node.name.hasSuffix(artifactType)
                    }) else {
                        dbg("missing app artifact from release")
                        continue
                    }

                    guard let appMetadata = releaseAsset(named: "Info.plist") else {
                        dbg("missing app artifact from release")
                        continue
                    }

                    guard let appREADME = releaseAsset(named: "README.md") else {
                        dbg("missing app metadata from release")
                        continue
                    }

                    let appRELEASENOTES = releaseAsset(named: "RELEASE_NOTES.md")

                    guard let appIcon = releaseAsset(named: appName + ".png") else {
                        dbg("missing appIcon from release")
                        continue
                    }

                    var seal: FairSeal? = nil

                    // scan the comments for the base ref for the matching url seal
                    var urlSeals: [URL: Set<String>] = [:]
                    let comments = (fork.defaultBranchRef.associatedPullRequests.nodes ?? []).compactMap(\.comments.nodes)
                    //print(wip("#### COMMENTS:"), comments)

                    let fairsealComments = comments.joined().filter({ $0.author.login == fairsealIssuer })
                    for comment in fairsealComments {
                        do {
                            let body = comment.bodyText
                                .trimmed(CharacterSet(charactersIn: "`").union(.whitespacesAndNewlines))
                            seal = try FairSeal(json: body.utf8Data, dateDecodingStrategy: .iso8601)
                            for asset in seal?.assets ?? [] {
                                urlSeals[asset.url, default: []].insert(asset.sha256)
                            }
                        } catch {
                            // comments can be anything, so tolerate JSON decoding failures
                            dbg("error parsing seal:", error)
                        }
                    }

                    let artifactURL = appArtifact.downloadUrl
                    guard let artifactChecksum = urlSeals[artifactURL]?.first else {
                        dbg("missing checksum for artifact url:", artifactURL.absoluteString)
                        continue
                    }
                    dbg("checking artifact url:", artifactURL.absoluteString, "fairseal:", artifactChecksum)

                    let metadataURL = appMetadata.downloadUrl
                    guard let metadataChecksum = urlSeals[metadataURL]?.first else {
                        dbg("missing checksum for metadata url:", metadataURL.absoluteString)
                        continue
                    }

                    let readmeURL = appREADME.downloadUrl
                    guard let readmeChecksum = urlSeals[readmeURL]?.first else {
                        dbg("missing checksum for readme url:", readmeURL.absoluteString)
                        continue
                    }

                    let releaseNotesURL = appRELEASENOTES?.downloadUrl

                    let screenshotURLs = release.releaseAssets.nodes.filter { node in
                        if !(node.name.hasSuffix(".png") || node.name.hasSuffix(".jpg")) {
                            return false
                        }
                        return artifactTarget.devices.contains { device in
                            node.name.hasPrefix("screenshot") && node.name.contains("-" + device + "-")
                        }
                    }
                    .compactMap { node in
                        node.downloadUrl.appendingHash(urlSeals[node.downloadUrl]?.first)
                    }

                    let downloadCount = appArtifact.downloadCount
                    let impressionCount = appIcon.downloadCount
                    let viewCount = appREADME.downloadCount

                    let size = appArtifact.size

                    //let app = AppCatalogItem(name: appTitle, bundleIdentifier: bundleIdentifier, subtitle: subtitle, developerName: developerInfo, localizedDescription: localizedDescription, size: size, version: appVersion.versionString, versionDate: versionDate, downloadURL: artifactURL, iconURL: iconURL, screenshotURLs: screenshotURLs.isEmpty ? nil : screenshotURLs, versionDescription: versionDescription, tintColor: seal?.tint, beta: beta, categories: categories, downloadCount: downloadCount, impressionCount: impressionCount, viewCount: viewCount, starCount: starCount, watcherCount: watcherCount, issueCount: issueCount, coreSize: seal?.coreSize, sha256: artifactChecksum, permissions: seal?.permissions, metadataURL: metadataURL.appendingHash(metadataChecksum), readmeURL: readmeURL.appendingHash(readmeChecksum), releaseNotesURL: releaseNotesURL, homepage: homepage)

                    // derive a source from the sealed info.plist, overriding properties as needed
                    var app = seal?.appSource ?? AppCatalogItem(name: appTitle, bundleIdentifier: bundleIdentifier, downloadURL: artifactURL)

                    app.name = appTitle
                    app.bundleIdentifier = bundleIdentifier
                    app.subtitle = subtitle
                    app.developerName = developerInfo
                    app.localizedDescription = localizedDescription
                    app.size = size
                    app.version = appVersion.versionString
                    app.versionDate = versionDate
                    app.downloadURL = artifactURL
                    app.iconURL = iconURL
                    app.screenshotURLs = screenshotURLs.isEmpty ? nil : screenshotURLs
                    app.versionDescription = versionDescription
                    app.tintColor = seal?.tint
                    app.beta = beta
                    app.categories = categories
                    app.downloadCount = downloadCount
                    app.impressionCount = impressionCount
                    app.viewCount = viewCount
                    app.starCount = starCount
                    app.watcherCount = watcherCount
                    app.issueCount = issueCount
                    app.coreSize = seal?.coreSize
                    app.sha256 = artifactChecksum
                    app.permissions = seal?.permissions
                    app.metadataURL = metadataURL.appendingHash(metadataChecksum)
                    app.readmeURL = readmeURL.appendingHash(readmeChecksum)
                    app.releaseNotesURL = releaseNotesURL
                    app.homepage = homepage


                    // walk through the recent releases until we find one that has a fairseal on it
                    if beta == true {
                        if !fairsealBetaFound {
                            apps.append(app)
                        }
                        fairsealBetaFound = true
                    } else {
                        if !fairsealFound {
                            apps.append(app)
                        }
                        fairsealFound = true
                    }
                }

                if fairsealFound {
                    // only add the single most recent valid release for any given fork
                    // this will also ignore any betas earlier than the most recent non-prerelease
                    break
                }
            }

            if !fairsealFound {
                dbg("WARNING: no fairseal found for:", fork.nameWithOwner)
            }
        }

        return apps
    }

    /// Generates the appcasks enhanced catalog for Homebrew Casks
    func buildAppCasks(owner: String, baseRepository: String, excludeEmptyCasks: Bool = true, maxApps: Int? = nil, mergeCasksURL: URL? = nil, caskStatsURL: URL? = nil, boostMap: [String: Int]? = nil, boostFactor: Int64?, caskQueryCount: Int = 25) async throws -> AppCatalog {

        // all the seal hashes we will look up to validate releases
        let boost = boostFactor ?? 10_000

        dbg("building appcasks with maxApps:", maxApps, "boost:", boost)

        struct CaskCatalog {
            let casks: [String: CaskItem]
            init(_ casks: [CaskItem]) {
                self.casks = casks.dictionary(keyedBy: \.token)
            }
        }

        let api = HomebrewAPI(caskAPIEndpoint: mergeCasksURL ?? HomebrewAPI.defaultEndpoint)

        // if we specified catalog metadata to merge in, start fetching it now
        async let casks = CaskCatalog(mergeCasksURL == nil ? [] : api.fetchCasks().casks)
        async let stats = caskStatsURL == nil ? nil : api.fetchCaskStats(url: caskStatsURL!)

        var apps: [AppCatalogItem] = []

        for try await forks in sendCursoredRequest(AppCasksQuery(owner: owner, name: baseRepository, count: caskQueryCount, releaseCount: caskQueryCount)) {
            let forkNodes = try forks.result.get().data.repository.forks.nodes
            dbg("fetched appcasks forks:", forkNodes.count)
            for fork in forkNodes {
                try await addAppForkReleases(fork, caskCatalog: await casks, stats: await stats)
            }

            if let maxApps = maxApps, apps.count >= maxApps {
                dbg("stopping due to maxapps:", maxApps)
                break
            }
        }

        func addAppForkReleases(_ fork: AppCaskFork, caskCatalog: CaskCatalog?, stats: CaskStats?) async throws {
            if apps.count >= maxApps ?? .max {
                return dbg("not adding app beyond max:", maxApps)
            }

            dbg("checking app fork:", fork.owner.appNameWithSpace, fork.name)

            guard let _ = fork.owner.websiteUrl else {
                return dbg("skipping un-set hostname for owner:", fork.nameWithOwner)
            }

            if fork.owner.isVerified != true {
                return dbg("skipping un-verified owner:", fork.nameWithOwner)
            }

            dbg("received release names:", fork.releases.nodes.compactMap(\.name))
            if addReleases(fork: fork, fork.releases.nodes, casks: caskCatalog, stats: stats) == true {
                if fork.releases.pageInfo?.hasNextPage == true,
                    let releaseCursor = fork.releases.pageInfo?.endCursor {
                    dbg("traversing release cursor:", releaseCursor)
                    for try await moreReleasesNode in self.sendCursoredRequest(AppCaskReleasesQuery(repositoryNodeID: fork.id, releaseCount: caskQueryCount, cursor: releaseCursor)) {
                        let moreReleaseNodes = try moreReleasesNode.get().data.node.releases.nodes
                        dbg("received more release names:", moreReleaseNodes.compactMap(\.name))
                        if addReleases(fork: fork, moreReleaseNodes, casks: caskCatalog, stats: stats) == false {
                            return
                        }
                    }
                }
            }
        }

        /// Adds the given cask result to the list of app catalog items
        func addReleases(fork: AppCaskFork, _ releaseNodes: [AppCaskFork.Release], casks: CaskCatalog?, stats: CaskStats?) -> Bool {
            for release in releaseNodes {
                let caskPrefix = "cask-"
                if !release.tag.name.hasPrefix(caskPrefix) {
                    dbg("tag name", release.tag.name.enquote(), "does not begin with expected prefix", caskPrefix.enquote())
                    continue
                }

                let token = release.tag.name.dropFirst(caskPrefix.count).description
                let cask = casks?.casks[token]
                if casks != nil && cask == nil {
                    dbg("  filtering app missing from casks:", token)
                    continue
                }

                if let app = createApp(token: token, release: release, fork: fork, cask: cask, stats: stats) {
                    // only add the cask if it has any supplemental information defined
                    if excludeEmptyCasks == false
                        || (app.downloadCount ?? 0) > 0
                        || app.readmeURL != nil
                        || app.releaseNotesURL != nil
                        || app.iconURL != nil
                        || app.tintColor != nil
                        || app.categories?.isEmpty == false
                        || app.screenshotURLs?.isEmpty == false
                    {
                        apps.append(app)
                        if let maxApps = maxApps, apps.count >= maxApps {
                            dbg("stopping due to maxapps:", maxApps)
                            return false
                        }
                    }
                }
            }

            return true
        }

        // apps are ranked based on how much metadata is provided, and then their download count
        func rank(for item: AppCatalogItem) -> Int64 {
            var ranking: Int64 = 0

            // the base ranking is the number of downloads
            ranking += Int64(item.downloadCount ?? 0)

            // each bit of metadata for a cask boosts its position in the rankings
            if item.readmeURL != nil { ranking += boost }
            if item.iconURL != nil { ranking += boost }
            // if item.tintColor != nil { ranking += boost }
            if item.categories?.isEmpty == false { ranking += boost }
            if item.screenshotURLs?.isEmpty == false { ranking += boost }

            // add in explicit boosts
            if let boostMap = boostMap,
                let boostCount = boostMap[item.bundleIdentifier] {
                ranking += .init(boostCount) * boost
            }

            return ranking
        }

        // now check for any items that are in the casks list but do not have an appcasks fork
        let forkedApps = apps.map(\.bundleIdentifier).set()
        let caskMap = try await casks.casks
        let caskStats = try await stats
        if !caskMap.isEmpty {
            for (token, cask) in caskMap.sorting(by: \.0).filter({ !forkedApps.contains($0.key) }) {
                if let maxApps = maxApps, apps.count >= maxApps {
                    continue
                }
                let app = createApp(token: token, release: nil, fork: nil, cask: cask, stats: caskStats)
                dbg("created app:", app)
            }
        }

        apps.sort { rank(for: $0) > rank(for: $1) }

        let catalog = AppCatalog(name: appfairCaskAppsName, identifier: appfairCaskAppsIdentifier, sourceURL: appfairCaskAppsURL, apps: apps, news: nil)
        return catalog
    }

    private func createApp(token: String, release: AppCaskFork.Release?, fork: AppCaskFork?, cask: CaskItem?, stats: CaskStats?) -> AppCatalogItem? {
        let caskName = cask?.name.first ?? release?.name ?? release?.tag.name ?? token
        let homepage = (cask?.homepage ?? fork?.homepageUrl).flatMap(URL.init(string:))
        let downloadURL = (cask?.url ?? cask?.homepage).flatMap(URL.init(string:))
        let checksum = cask?.checksum?.count == 64 ? cask?.checksum : nil
        let version = cask?.version
        let subtitle = cask?.desc
        let localizedDescription = release?.description ?? cask?.desc
        let versionDate: Date? = nil // release.createdAt // not the right thing
        let versionDescription = release?.description
        let beta: Bool = release?.isPrerelease == true

        func releaseAsset(named name: String) -> ReleaseAsset? {
            release?.releaseAssets.nodes.first(where: { node in
                node.name == name
            })
        }

        dbg("checking target token:", token, "name:", caskName, "files:", release?.releaseAssets.nodes.map(\.name))

        /// Returns all the asset names with the given prefix trimmed off
        func prefixedAssetTag(_ prefix: String) -> [String]? {
            release?.releaseAssets.nodes.filter {
                $0.name.hasPrefix(prefix)
            }
            .map {
                $0.name.dropFirst(prefix.count).description
            }
        }

        // get the "appfair-utilities" topic and convert it to the standard "public.app-category.utilities"
        let categories = prefixedAssetTag("category-")?
            .compactMap(AppCategory.init(rawValue:))

        let tintColor = prefixedAssetTag("tint-")?
            .filter({ $0.count == 6 }) // needs to be a 6-digit hex code
            .first

        let appREADME = releaseAsset(named: "README.md")
        let readmeURL = appREADME?.downloadUrl
        let viewCount = appREADME?.downloadCount

        let appRELEASENOTES = releaseAsset(named: "RELEASE_NOTES.md")
        let releaseNotesURL = appRELEASENOTES?.downloadUrl

        let appIcon = releaseAsset(named: "AppIcon.png")
        let impressionCount = appIcon?.downloadCount

        let caskInstalls = releaseAsset(named: "cask-install")
        var downloadCount = caskInstalls?.downloadCount ?? 0
        if let stats = stats {
            if let count = stats.formulae?[token]?.first?.count {
                downloadCount += count
            }
        }

        let screenshotURLs = release?.releaseAssets.nodes.filter { node in
            if !(node.name.hasSuffix(".png") || node.name.hasSuffix(".jpg")) {
                return false
            }
            return node.name.hasPrefix("screenshot") && node.name.contains("-mac-")
        }

        let app = AppCatalogItem(name: caskName, bundleIdentifier: token, subtitle: subtitle, developerName: nil, localizedDescription: localizedDescription, size: nil, version: version, versionDate: versionDate, downloadURL: downloadURL ?? appfairRoot, iconURL: appIcon?.downloadUrl, screenshotURLs: screenshotURLs?.isEmpty != false ? nil : screenshotURLs?.map(\.downloadUrl), versionDescription: versionDescription, tintColor: tintColor, beta: beta, categories: categories?.isEmpty != false ? nil : categories?.map(\.metadataIdentifier), downloadCount: downloadCount, impressionCount: impressionCount, viewCount: viewCount, starCount: nil, watcherCount: nil, issueCount: nil, coreSize: nil, sha256: checksum, permissions: nil, metadataURL: nil, readmeURL: readmeURL, releaseNotesURL: releaseNotesURL, homepage: homepage)
        return app
    }


    internal func validate(org: RepositoryQuery.QueryResponse.Organization, configuration: ProjectConfiguration) -> AppOrgValidationFailure {
        let repo = org.repository
        let isOrigin = org.login == appfairName
        var invalid: AppOrgValidationFailure = []

        if !isOrigin {
            do {
                try AppNameValidation.standard.validate(name: org.login) 
                try configuration.validateAppName(org.login)
            } catch {
                invalid.insert(.invalidName)
            }
        }

        if org.isVerified != true {
            // invalid.insert(.notVerified)
            // we do not currently require that organizations be verified
        }

        if !org.isOrganization {
            invalid.insert(.ownerNotOrganization)
        }

        if !repo.isInOrganization {
            invalid.insert(.ownerNotOrganization)
        }

        if !isOrigin {
            do {
                try configuration.validateEmailAddress(org.email)
            } catch {
                invalid.insert(.invalidEmail)
            }
        }

        if repo.isArchived {
            invalid.insert(.isArchived)
        }

        if repo.isDisabled {
            invalid.insert(.isDisabled)
        }

        if repo.isPrivate {
            invalid.insert(.isPrivate)
        }

        if !isOrigin && !repo.hasIssuesEnabled {
            invalid.insert(.noIssues)
        }

        // there's no "hasDiscussionsEnabled" key, but the count of categories will be zero if discussions are not enabled
        if !isOrigin && repo.discussionCategories.totalCount <= 0 {
           invalid.insert(.noDiscussions)
        }

        if !configuration.allowLicense.isEmpty && !configuration.allowLicense.contains(repo.licenseInfo.spdxId ?? "none") {
            //dbg(allowLicense)
            invalid.insert(.invalidLicense)
        }

        return invalid
    }

    /// The varios reasons why an organization or repository might be invalid
    struct AppOrgValidationFailure : OptionSet, CustomStringConvertible {
        public let rawValue: Int
        public init(rawValue: Int) { self.rawValue = rawValue }
        public static let isPrivate = AppOrgValidationFailure(rawValue: 1 << 0)
        public static let isArchived = AppOrgValidationFailure(rawValue: 1 << 1)
        public static let noIssues = AppOrgValidationFailure(rawValue: 1 << 2)
        public static let noDiscussions = AppOrgValidationFailure(rawValue: 1 << 3)
        public static let invalidLicense = AppOrgValidationFailure(rawValue: 1 << 4)
        public static let isDisabled = AppOrgValidationFailure(rawValue: 1 << 5)
        public static let notVerified = AppOrgValidationFailure(rawValue: 1 << 6)
        public static let invalidEmail = AppOrgValidationFailure(rawValue: 1 << 7)
        public static let invalidName = AppOrgValidationFailure(rawValue: 1 << 8)
        public static let ownerNotOrganization = AppOrgValidationFailure(rawValue: 1 << 9)
        public static let mismatchedEmail = AppOrgValidationFailure(rawValue: 1 << 10)

        public var description: String {
            [
                contains(.isPrivate) ? "Repository must be public" : nil,
                contains(.isArchived) ? "Repository must not be archived" : nil,
                contains(.noIssues) ? "Repository must have issues enabled" : nil,
                contains(.noDiscussions) ? "Repository must have discussions enabled" : nil,
                contains(.invalidLicense) ? "Repository must use an approved license" : nil,
                contains(.isDisabled) ? "Repository must not be disabled" : nil,
                contains(.notVerified) ? "Organization must be verified" : nil,
                contains(.invalidEmail) ? "The e-mail for the organization must be public and match the approved list" : nil,
                contains(.invalidName) ? "The name of the organization is not valid" : nil,
                contains(.ownerNotOrganization) ? "The owner of the repository must be an organization and not an individual user" : nil,
                contains(.mismatchedEmail) ? "The e-mail for the commit must match the public e-mail of the organization" : nil,
            ].compactMap({ $0 }).joined(separator: ", ")
        }
    }

    /// Posts the fairseal to the most recent open PR that matches the download URL's appOrg
    func postFairseal(_ fairseal: FairSeal, owner: String, baseRepository: String) async throws -> URL? {
        guard let appOrg = fairseal.appOrg else {
            dbg("no app org for seal:", fairseal)
            return nil
        }

        let nameWithOwner = appOrg + "/" + baseRepository

        let lookupPRsRequest = FindPullRequests(owner: owner, name: baseRepository, state: .OPEN)
        let appPR = try await self.requestBatches(lookupPRsRequest) { resultIndex, urlResponse, batch in
            try batch.result.get().data.repository.pullRequests.nodes.first { edge in
                edge.state == .OPEN
                //&& edge.mergeable != "CONFLICTING"
                && edge.headRepository?.nameWithOwner == (nameWithOwner)
            }
        }

        guard let appPR = appPR else {
            dbg("no PRs found for \(appOrg)")
            return nil
        }

        var signedSeal = fairseal
        if let key = self.fairsealKey {
            // sign the key if we have specified one
            try signedSeal.embedSignature(key: key)
        }

        let sealJSON = try signedSeal.json(outputFormatting: [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes])
        let sealComment = "```\n" + (sealJSON.utf8String ?? "") + "\n```"
        let postResponse = try await self.request(PostCommentQuery(id: appPR.id, comment: sealComment)).get()
        let sealCommentURL = postResponse.data.addComment.commentEdge.node.url // e.g.: https://github.com/appfair/App/pull/72#issuecomment-924952591

        dbg("posted fairseal for:", fairseal.assets?.first?.url.absoluteString, "to:", sealCommentURL.absoluteString)

        return sealCommentURL
    }

    /// Checks the commit info to ensure that it is verified, and if so, returns the author information
    func authorize(commit: CommitInfo) throws {
        let info = commit.repository.object
        //guard let verification = info.signature else {
            //throw Errors.noVerification(commit)
        //}

//        if verification.state != .VALID || verification.isValid == false {
//            throw Errors.invalidVerification(commit)
//        }

        guard let name = info.author?.name, !name.isEmpty else {
            throw Errors.noAuthor(commit)
        }

//        guard let email = info.author?.email, !email.isEmpty else {
//            throw Errors.invalidEmail(info.author?.email)
//        }

        // TODO: email isn't sent as part of owner; will need to match org-email and commit-email using a separate request
//        if email != info.owner.email {
//            throw Errors.mismatchedEmail(info.author?.email, info.owner.email)
//        }

//        try validateEmailAddress(email)
    }


    enum Errors : LocalizedError {
        case emptyAuthToken
        case badHostOrg(String)
        case emptyOrganization(URL)
        case notTopLevelURL(URL)
        case badURLScheme(URL)
        case noVerification(CommitInfo)
        case invalidVerification(CommitInfo)
        case noAuthor(CommitInfo)
        case invalidEmail(String?)
        case invalidName(String?)
        case valueNotAllowed(String?)
        case valueDenied(String?)
        case mismatchedEmail(String?, String?)
        case invalidSealHash(String?)
        case repoInvalid(_ reasons: AppOrgValidationFailure, _ org: String, _ repo: String)
        case missingFairsealIssuer

        public var errorDescription: String? {
            switch self {
            case .emptyAuthToken: return "No authorization token specified"
            case .badHostOrg(let string): return "Invalid fairground host/org: \(string)"
            case .emptyOrganization(let url): return "Missing organization name in URL: \"\(url.absoluteString)\""
            case .notTopLevelURL(let url): return "Not a top-level URL: \"\(url.absoluteString)\""
            case .badURLScheme(let url): return "Bad URL scheme: \"\(url.absoluteString)\""
            case .noVerification(let info): return "No verification information for commit ref: \"\(info.repository.object.oid.rawValue)\". Release tag commits must be marked 'verified', which means either performing the tag via the web interface, or else GPG signing the release tag."
            case .invalidVerification(let info): return "Commit ref must be verified as valid, but was: \"\(info.repository.object.signature?.state.rawValue ?? "empty")\". Release tag commits must be marked 'verified', which means either performing the tag via the web interface, or else GPG signing the release tag."
            case .noAuthor(let info): return "The author was empty for the commit: \"\(info.repository.object.oid.rawValue)\""
            case .invalidEmail(let email): return "The email address \"\(email ?? "")\" is not accepted"
            case .invalidName(let name): return "The app name \"\(name ?? "")\" is not accepted"
            case .valueNotAllowed(let value): return "The value \"\(value ?? "")\" is not allowed"
            case .valueDenied(let value): return "The value \"\(value ?? "")\" is not permitted"
            case .mismatchedEmail(let repoEmail, let orgEmail): return "The email address \"\(repoEmail ?? "")\" for the commit must match the public e-mail for the organization \"\(orgEmail ?? "")\""
            case .invalidSealHash(let hash): return "The fair seal hash has an invalid number of characters: \(hash?.count ?? 0)"
            case .repoInvalid(let reasons, let org, let repo): return "The repository \"\(org)/\(repo)\" is invalid because: \(reasons)"
            case .missingFairsealIssuer: return "Missing fairseal-issuer flag"
            }
        }
    }

    public struct RepositoryOwner : Pure {
        public enum TypeName : String, Pure { case User, Organization }
        public let __typename: TypeName
        public var login: String

        // these can all be null for an app forked by a user due to the `... on Organization { }` clause

        ///  The organization's public email.
        public let email: String?
        /// Whether the organization has verified its profile email and website.
        public let isVerified: Bool?
        /// The organization's public profile URL.
        public let websiteUrl: URL?
        /// Identifies the date and time when the object was created.
        public let createdAt: Date?
        /// True if this user/organization has a GitHub Sponsors listing.
        public let hasSponsorsListing: Bool?
        /// The estimated monthly GitHub Sponsors income for this user/organization in cents (USD).
        public let monthlyEstimatedSponsorsIncomeInCents: Double?

        public var isOrganization: Bool { __typename == .Organization }

        /// The app name is simply the "Org-Name" without dashes: "Org Name"
        public var appNameWithSpace: String {
            login.dehyphenated()
        }

        /// The app name is simply the "Org-Name"
        public var appNameWithHyphen: String {
            login // .rehyphenated()
        }
    }
}


extension FairHub {
    /// The HTTP headers that should be attached to all API requests
    public var requestHeaders: [String: String] {
        var headers: [String: String] = [:]
        headers["Accept"] = "application/vnd.github.v3+json"
        // apply auth headers if we have one set
        if let authToken = authToken {
            headers["Authorization"] = "token " + authToken
        }

        return headers
    }

    public func endpoint(action: [String], _ params: [String: String?]) -> URL {
        var comps = URLComponents()
        comps.path = action.joined(separator: "/")
        comps.queryItems = params.map(URLQueryItem.init(name:value:))
        return comps.url(relativeTo: baseURL) ?? baseURL
    }


    /// An object ID
    public struct OID : RawDecodable, Hashable {
        public let rawValue: String
        public init(rawValue: String) {
            self.rawValue = rawValue
        }
    }

    /// Generic placeholder for a related collection that only has a `totalCount` property requested
    public struct NodeCount : Codable {
        public let totalCount: Int
    }

    public struct NodeList<T: Decodable>: Decodable {
        let nodes: [T]?
    }

    public struct EdgeList<T: Decodable>: Decodable {
        let totalCount: Int?
        let pageInfo: PageInfo?
        let edges: [EdgeNode<T>]

        /// Maps through to the edge's node
        var nodes: [T] {
            edges.map(\.node)
        }

        struct EdgeNode<T: Decodable>: Decodable {
            let cursor: String?
            let node: T
        }

        /// The info for a page of results, which includes a cursor to traverse
        struct PageInfo : Decodable {
            let endCursor: GraphQLCursor?
            let hasNextPage: Bool?
            let hasPreviousPage: Bool?
            let startCursor: GraphQLCursor?
        }
    }

    /// Utility for including an optional string parameter or `null` if it is `.none`
    @available(*, deprecated, message: "user variables instead")
    private static func quotedOrNull(_ string: String?) -> String {
        string?.escapedGraphQLString.enquote(with: "\"") ?? "null"
    }

    public struct GetCommitQuery : GraphQLAPIRequest {
        public var owner: String
        public var name: String
        public var ref: String

        public init(owner: String, name: String, ref: String) {
            self.owner = owner
            self.name = name
            self.ref = ref
        }

        public func postData() throws -> Data? {
            try executeGraphQL(Self.query, variables: [
                "owner": .str(owner),
                "name": .str(name),
                "ref": .str(ref),
            ])
        }

        private static let query = """
            query GetCommitQuery($owner:String!, $name:String!, $ref:GitObjectID!) {
               __typename
               repository(owner: $owner, name: $name) {
                object(oid: $ref) {
                  ... on Commit {
                    oid
                    abbreviatedOid
                    author {
                      name
                      email
                      date
                    }
                    signature {
                      email
                      isValid
                      state
                      wasSignedByGitHub
                      signer {
                        email
                        name
                        createdAt
                        status {
                          emoji
                        }
                      }
                    }
                  }
                }
              }
            }
            """

        public typealias Response = GraphQLResponse<QueryResponse>

        public struct QueryResponse : Decodable {
            public enum TypeName : String, Decodable, Hashable { case Query }
            public let __typename: TypeName
            public let repository: Repository
            public struct Repository : Decodable {
                public let object: Object
                public struct Object : Decodable {
                    public let oid: OID
                    public let abbreviatedOid: String
                    public let author: Author?
                    public let signature: Signature?

                    public struct Author : Decodable {
                        let name: String?
                        let email: String?
                        let date: Date
                    }

                    public struct Signature : Decodable {
                        let email: String?
                        let isValid: Bool
                        let state: GitSignatureState
                        let wasSignedByGitHub: Bool
                        let signer: Signer
                        public struct Signer : Decodable {
                            let name: String?
                            let email: String
                            let createdAt: Date
                            let status: String?
                        }
                    }
                }
            }
        }
    }

    public struct RepositoryQuery : GraphQLAPIRequest {
        public var owner: String
        public var name: String

        public init(owner: String, name: String) {
            self.owner = owner
            self.name = name
        }

        public func postData() throws -> Data? {
            try executeGraphQL(Self.query, variables: [
                "owner": .str(owner),
                "name": .str(name),
            ])
        }

        private static let query = """
            query RepositoryQuery($owner:String!, $name:String!) {
               __typename
               organization(login: $owner) {
                __typename
                name
                login
                email
                isVerified
                websiteUrl
                url
                createdAt
                repository(name: $name) {
                  __typename
                  visibility
                  createdAt
                  updatedAt
                  homepageUrl
                  isFork
                  isEmpty
                  isLocked
                  isMirror
                  isPrivate
                  isArchived
                  isDisabled
                  forkCount
                  stargazerCount
                  watchers { totalCount }
                  isInOrganization
                  hasIssuesEnabled
                  discussionCategories { totalCount }
                  issues { totalCount }
                  licenseInfo {
                    __typename
                    spdxId
                  }
                }
              }
            }
            """

        public typealias Response = GraphQLResponse<QueryResponse>

        public struct QueryResponse : Decodable {
            public enum TypeName : String, Decodable, Hashable { case Query }
            public let __typename: TypeName
            public let organization: Organization
            public struct Organization : Decodable {
                public enum TypeName : String, Decodable, Hashable { case User, Organization }
                public let __typename: TypeName
                public let name: String? // the string title, falling back to the login name
                public let login: String
                public let email: String?
                public let isVerified: Bool?
                public let websiteUrl: URL?
                public let url: URL?
                public let createdAt: Date?

                public var isOrganization: Bool { __typename == .Organization }

                public let repository: Repository
                public struct Repository : Decodable {
                    public enum TypeName : String, Decodable, Hashable { case Repository }
                    public let __typename: TypeName
                    public let visibility: RepositoryVisibility // e.g., "PUBLIC",
                    public let createdAt: Date
                    public let updatedAt: Date
                    public let homepageUrl: String?
                    public let isFork: Bool
                    public let isEmpty: Bool
                    public let isLocked: Bool
                    public let isMirror: Bool
                    public let isPrivate: Bool
                    public let isArchived: Bool
                    public let isDisabled: Bool
                    public let isInOrganization: Bool
                    public let hasIssuesEnabled: Bool
                    public let discussionCategories: NodeCount
                    public let forkCount: Int
                    public let stargazerCount: Int
                    public let issues: NodeCount
                    public let licenseInfo: License
                    public struct License : Decodable {
                        public enum TypeName : String, Decodable, Hashable { case License }
                        public let __typename: TypeName
                        public let spdxId: String?
                    }
                }
            }
        }
    }

    /**
     ```
     query {
       repository(owner: "appfair", name: "appcasks") {
         __typename
         forks(first: 100) {
           __typename
           nodes {
             __typename
             nameWithOwner
             owner {
               __typename
               url
               ... on Organization {
                 email
                 isVerified
                 websiteUrl
                 email
                 createdAt
               }
             }
             releases(last: 100) {
               nodes {
                 name
                 tagName
                 description
                   createdAt
                   releaseAssets(first: 25) {
                     nodes {
                       name
                       size
                       downloadUrl
                       downloadCount
                     }
                 }
               }
             }
           }
         }
       }
     }
     ```
     */

    /// The query to generate a catalog of enhanced cask metadata
    public struct AppCasksQuery : GraphQLAPIRequest & CursoredAPIRequest {
        public typealias Service = FairHub

        public var owner: String
        public var name: String

        /// the number of forks to return per batch
        public var count: Int

        /// the number of releases to scan
        public var releaseCount: Int

        /// the number of release assets to process
        public var assetCount: Int = 25

        public var cursor: GraphQLCursor? = nil

        public func postData() throws -> Data? {
            try executeGraphQL(Self.query, variables: [
                "owner": .str(owner),
                "name": .str(name),
                "count": .num(.init(count)),
                "releaseCount": .num(.init(releaseCount)),
                "assetCount": .num(.init(assetCount)),
                "cursor": cursor.flatMap({ .str($0.rawValue) })
            ])
        }

        private static let query = """
            query AppCasksQuery($owner:String!, $name:String!, $count:Int!, $releaseCount:Int!, $assetCount:Int!, $cursor:String) {
               __typename
               repository(owner: $owner, name: $name) {
                __typename
                forks(after: $cursor, first: $count, isLocked: false, privacy: PUBLIC, orderBy: { field: CREATED_AT, direction: DESC }) {
                  __typename
                  totalCount
                  pageInfo {
                    endCursor
                    hasNextPage
                    hasPreviousPage
                    startCursor
                  }
                  edges {
                    node {
                      __typename
                      id
                      name
                      nameWithOwner
                      owner {
                        __typename
                        login
                        ... on Organization {
                          email
                          isVerified
                          websiteUrl
                          createdAt
                        }
                      }
                      description
                      visibility
                      homepageUrl
                      releases(first: $releaseCount) {
                        pageInfo {
                          endCursor
                          hasNextPage
                          hasPreviousPage
                          startCursor
                        }
                        edges {
                          node {
                            __typename
                            name
                            createdAt
                            updatedAt
                            isPrerelease
                            isDraft
                            description
                            releaseAssets(first: $assetCount) {
                              __typename
                              edges {
                                node {
                                  __typename
                                  contentType
                                  downloadCount
                                  downloadUrl
                                  name
                                  size
                                  updatedAt
                                  createdAt
                                }
                              }
                            }
                            tag {
                              name
                            }
                          }
                        }
                      }
                    }
                  }
                }
              }
            }
            """

        public typealias Response = GraphQLResponse<QueryResponse>

        public struct QueryResponse : Decodable, CursoredAPIResponse {
            public var endCursor: GraphQLCursor? {
                repository.forks.pageInfo?.endCursor
            }

            public var elementCount: Int {
                repository.forks.nodes.count
            }

            public enum TypeName : String, Decodable, Hashable { case Query }
            public let __typename: TypeName
            public let repository: BaseRepository
            public struct BaseRepository : Decodable {
                public enum TypeName : String, Decodable, Hashable { case Repository }
                public let __typename: TypeName
                public let forks: EdgeList<Repository>
                public struct Repository : Decodable {
                    public enum TypeName : String, Decodable, Hashable { case Repository }
                    public let __typename: TypeName
                    public let id: String // used as a base for paginaton
                    public let name: String
                    public let nameWithOwner: String
                    public let owner: RepositoryOwner
                    public let description: String?
                    public let visibility: String // e.g. "PUBLIC"
                    public let homepageUrl: String?
                    public let releases: EdgeList<Release>

                    public struct Release : Decodable {
                        public enum TypeName : String, Decodable, Hashable { case Release }
                        public let __typename: TypeName
                        public let tag: Tag
                        public let createdAt: Date
                        public let updatedAt: Date
                        public let isPrerelease: Bool
                        public let isDraft: Bool
                        public let name: String?
                        public let description: String?
                        public let releaseAssets: EdgeList<ReleaseAsset>

                        public struct Tag: Decodable, Hashable {
                            public let name: String
                        }

                    }
                }
            }
        }
    }

    /// The query to get additional pages of releases for `AppCasksQuery` when a fork has many releases
    public struct AppCaskReleasesQuery : GraphQLAPIRequest & CursoredAPIRequest {
        public typealias Service = FairHub

        /// The opaque ID of the fork repository
        public let repositoryNodeID: String

        /// the number of releases to get per batch
        public var releaseCount: Int

        /// the number of release assets to process
        public var assetCount: Int = 25

        public var cursor: GraphQLCursor?

        public func postData() throws -> Data? {
            try executeGraphQL(Self.query, variables: [
                "repositoryNodeID": .str(repositoryNodeID),
                "releaseCount": .num(.init(releaseCount)),
                "assetCount": .num(.init(assetCount)),
                "cursor": cursor.flatMap({ .str($0.rawValue) })
            ])
        }

        private static let query = """
            query AppCaskReleasesQuery($repositoryNodeID:ID!, $releaseCount:Int!, $assetCount:Int!, $cursor:String) {
              __typename
              node(id: $repositoryNodeID) {
                id
                __typename
                ... on Repository {
                  releases(after: $cursor, first: $releaseCount) {
                    pageInfo {
                      endCursor
                    hasNextPage
                      hasPreviousPage
                      startCursor
                    }
                    edges {
                      node {
                        __typename
                        name
                        createdAt
                        updatedAt
                        isPrerelease
                        isDraft
                        description
                        releaseAssets(first: $assetCount) {
                          __typename
                          edges {
                            node {
                              __typename
                              contentType
                              downloadCount
                              downloadUrl
                              name
                              size
                              updatedAt
                              createdAt
                            }
                          }
                        }
                        tag {
                          name
                        }
                      }
                    }
                  }
                }
              }
            }
            """

        public typealias Response = GraphQLResponse<QueryResponse>

        public struct QueryResponse : Decodable, CursoredAPIResponse {
            public var endCursor: GraphQLCursor? {
                node.releases.pageInfo?.endCursor
            }

            public var elementCount: Int {
                node.releases.nodes.count
            }

            public let node: Repository
            public struct Repository : Decodable {
                public enum TypeName : String, Decodable, Hashable { case Repository }
                public let __typename: TypeName
                public let id: String // used as a base for paginaton

                /// We re-use the same release structure between the parent query and the cursored release query
                public let releases: EdgeList<AppCaskFork.Release>
            }
        }
    }


    /// The query to generate a fair-ground catalog
    public struct CatalogForksQuery : GraphQLAPIRequest & CursoredAPIRequest {
        public typealias Service = FairHub

        public var owner: String
        public var name: String

        /// the number of forks to return per batch
        public var count: Int = 10 // any higher can trigger timeout errors like: “Something went wrong while executing your query. This may be the result of a timeout, or it could be a GitHub bug. Please include `AF94:6EB8:23D7BE:65794E:61DDA32D` when reporting this issue.”

        /// the number of releases to scan
        public var releaseCount: Int = 10
        /// the number of release assets to process
        public var assetCount: Int = 25
        /// the number of recent PRs to scan for a fairseal
        public var prCount: Int = 10
        /// the number of initial comments to scan for a fairseal
        public var commentCount: Int = 10

        public var cursor: GraphQLCursor? = nil

        public func postData() throws -> Data? {
            try executeGraphQL(Self.query, variables: [
                "owner": .str(owner),
                "name": .str(name),
                "count": .num(.init(count)),
                "releaseCount": .num(.init(releaseCount)),
                "assetCount": .num(.init(assetCount)),
                "prCount": .num(.init(prCount)),
                "commentCount": .num(.init(count)),
                "cursor": cursor.flatMap({ .str($0.rawValue) })
            ])
        }

        private static let query = """
            query CatalogForksQuery($owner:String!, $name:String!, $count:Int!, $releaseCount:Int!, $assetCount:Int!, $prCount:Int!, $commentCount:Int!, $cursor:String) {
               __typename
               repository(owner: $owner, name: $name) {
                __typename
                forks(after: $cursor, first: $count, isLocked: false, privacy: PUBLIC, orderBy: {field: PUSHED_AT, direction: DESC}) {
                  __typename
                  totalCount
                  pageInfo {
                    endCursor
                    hasNextPage
                    hasPreviousPage
                    startCursor
                  }
                  edges {
                    node {
                      __typename
                      name
                      nameWithOwner
                      owner {
                        __typename
                        login
                        ... on Organization {
                          email
                          isVerified
                          websiteUrl
                          createdAt
                        }
                      }
                      description
                      visibility
                      forkCount
                      stargazerCount
                      hasIssuesEnabled
                      discussionCategories { totalCount }
                      issues { totalCount }
                      stargazers { totalCount }
                      watchers { totalCount }
                      isInOrganization
                      homepageUrl
                      repositoryTopics(first: 1) {
                        nodes {
                          __typename
                          topic {
                            __typename
                            name
                          }
                        }
                      }
                      releases(first: $releaseCount, orderBy: {field: CREATED_AT, direction: DESC}) {
                        nodes {
                          __typename
                          name
                          createdAt
                          updatedAt
                          isPrerelease
                          isDraft
                          description
                          releaseAssets(first: $assetCount) {
                            __typename
                            edges {
                              node {
                                __typename
                                contentType
                                downloadCount
                                downloadUrl
                                name
                                size
                                updatedAt
                                createdAt
                              }
                            }
                          }
                          tag {
                            name
                          }
                          tagCommit {
                            __typename
                            authoredByCommitter
                            author {
                              name
                              email
                              date
                            }
                            signature {
                              __typename
                              isValid
                              signer {
                                __typename
                                name
                                email
                              }
                            }
                          }
                        }
                      }

                      defaultBranchRef {
                        __typename
                        associatedPullRequests(states: [CLOSED], last: $prCount) {
                          nodes {
                            __typename
                            author {
                              __typename
                              login
                              ... on User {
                                name
                                email
                              }
                            }
                            baseRef {
                              __typename
                              name
                              repository {
                                nameWithOwner
                              }
                            }
                            # scan the first few PR comments for the fairseal issuer's signature
                            comments(first: $commentCount) {
                              totalCount
                              nodes {
                                __typename
                                author {
                                  login
                                }
                                bodyText # fairseal JSON
                              }
                            }
                          }
                        }
                      }
                    }
                  }
                }
              }
            }
            """

        public typealias Response = GraphQLResponse<QueryResponse>

        public struct QueryResponse : Decodable, CursoredAPIResponse {
            public var endCursor: GraphQLCursor? {
                repository.forks.pageInfo?.endCursor
            }

            public var elementCount: Int {
                repository.forks.nodes.count
            }

            public enum TypeName : String, Decodable, Hashable { case Query }
            public let __typename: TypeName
            public let repository: BaseRepository
            public struct BaseRepository : Decodable {
                public enum TypeName : String, Decodable, Hashable { case Repository }
                public let __typename: TypeName
                public let forks: EdgeList<Repository>
                public struct Repository : Decodable {
                    public enum TypeName : String, Decodable, Hashable { case Repository }
                    public let __typename: TypeName
                    public let name: String
                    public let nameWithOwner: String
                    public let owner: RepositoryOwner
                    public let description: String?
                    public let visibility: String // e.g. "PUBLIC"
                    public let forkCount: Int
                    public let stargazerCount: Int
                    public let hasIssuesEnabled: Bool
                    public let discussionCategories: NodeCount
                    public let issues: NodeCount
                    public let stargazers: NodeCount
                    public let watchers: NodeCount
                    public let isInOrganization: Bool
                    public let homepageUrl: String?
                    public var repositoryTopics: NodeList<RepositoryTopic>
                    public let releases: NodeList<Release>
                    public let defaultBranchRef: Ref

                    public struct Ref : Decodable {
                        public enum TypeName : String, Decodable, Hashable { case Ref }
                        public let __typename: TypeName
                        public let associatedPullRequests: NodeList<PullRequest>

                        public struct PullRequest : Decodable {
                            public enum TypeName : String, Decodable, Hashable { case PullRequest }
                            public let __typename: TypeName
                            public let author: Author
                            public let baseRef: Ref
                            public let comments: NodeList<IssueComment>

                            public struct Author : Decodable {
                                public let login: String
                                public let name: String?
                                public let email: String?
                            }

                            public struct Ref : Decodable {
                                public enum TypeName : String, Decodable, Hashable { case Ref }
                                public let name: String?
                                public let repository: Repository

                                public struct Repository : Decodable {
                                    public let nameWithOwner: String
                                }
                            }

                            public struct IssueComment : Decodable {
                                public enum TypeName : String, Decodable, Hashable { case IssueComment }
                                public let __typename: TypeName
                                public let bodyText: String
                                public let author: Author
                                public struct Author : Decodable {
                                    public let login: String
                                }
                            }
                        }
                    }

                    public struct Release : Decodable {
                        public enum TypeName : String, Decodable, Hashable { case Release }
                        public let __typename: TypeName
                        public let tag: Tag
                        public let tagCommit: Commit
                        public let createdAt: Date
                        public let updatedAt: Date
                        public let isPrerelease: Bool
                        public let isDraft: Bool
                        public let name: String?
                        public let description: String?
                        public let releaseAssets: EdgeList<ReleaseAsset>

                        public struct Tag: Decodable, Hashable {
                            public let name: String
                        }

                        public struct Commit: Decodable {
                            public enum TypeName : String, Decodable, Hashable { case Commit }
                            public let __typename: TypeName
                            public let authoredByCommitter: Bool
                            public let author: Author?
                            public let signature: Signature?

                            public struct Author : Decodable {
                                let name: String?
                                let email: String?
                                let date: Date
                            }

                            public struct Signature : Decodable {
                                public enum TypeName : String, Decodable, Hashable { case Signature, GpgSignature }
                                public let __typename: TypeName
                                public let isValid: Bool
                                public let signer: User

                                public struct User : Decodable {
                                    public enum TypeName : String, Decodable, Hashable { case User }
                                    public let __typename: TypeName
                                    public let name: String?
                                    public let email: String?
                                }
                            }
                        }
                    }

                    public struct RepositoryTopic : Decodable {
                        public enum TypeName : String, Decodable, Hashable { case RepositoryTopic }
                        public let __typename: TypeName
                        public let topic: Topic
                        public struct Topic : Decodable {
                            public enum TypeName : String, Decodable, Hashable { case Topic }
                            public let __typename: TypeName
                            public let name: String // TODO: this will be the appfair- app category
                        }
                    }
                }
            }
        }
    }

    public struct LookupPRNumberQuery : GraphQLAPIRequest {
        let owner: String
        let name: String
        let prid: Int

        public func postData() throws -> Data? {
            try executeGraphQL(Self.query, variables: [
                "owner": .str(owner),
                "name": .str(name),
                "prid": .num(.init(prid)),
            ])
        }

        private static let query = "query LookupPRNumberQuery($owner:String!, $name:String!, $prid:Int!) { __typename, repository(owner: $owner, name: $name) { pullRequest(number: $prid) { id, number } } }"

        public typealias Response = GraphQLResponse<QueryResponse>

        public struct QueryResponse : Decodable {
            public enum TypeName : String, Decodable, Hashable { case Query }
            public let __typename: TypeName
            let repository: Repository
            struct Repository : Decodable {
                let pullRequest: PullRequest
                struct PullRequest : Decodable, Hashable {
                    let id: OID
                    let number: Int
                }
            }
        }
    }

    public struct PostCommentQuery : GraphQLAPIRequest {
        /// The issue or pull request ID
        let id: OID
        let comment: String?

        public func postData() throws -> Data? {
            try executeGraphQL(Self.mutation, variables: [
                "id": .str(id.rawValue),
                "comment": comment.flatMap(JSum.str),
            ])
        }

        private static let mutation = """
            mutation AddComment($id:String!, $comment:String!) {
              __typename
              addComment(input: {subjectId: $id, body: $comment}) {
                commentEdge {
                  node {
                    body
                    url
                  }
                }
              }
            }
            """

        public typealias Response = GraphQLResponse<QueryResponse>

        public struct QueryResponse : Decodable {
            public enum TypeName : String, Decodable, Hashable { case Mutation }
            public let __typename: TypeName
            let addComment: AddComment
            struct AddComment : Decodable {
                let commentEdge: CommentEdge
                struct CommentEdge : Decodable {
                    let node: Node
                    struct Node : Decodable {
                        let body: String
                        let url: URL
                    }
                }
            }
        }
    }

    public struct FindPullRequests : GraphQLAPIRequest & CursoredAPIRequest {
        /// The owner organization for the PR
        public var owner: String
        /// The base repository name for the PR
        public var name: String
        /// The state of the PR
        public var state: PullRequestState
        public var count: Int = 100
        public var cursor: GraphQLCursor? = nil

        public func postData() throws -> Data? {
            try executeGraphQL(Self.query, variables: [
                "owner": .str(owner),
                "name": .str(name),
                "state": .str(state.rawValue),
                "count": .num(.init(count)),
                "cursor": cursor.flatMap({ .str($0.rawValue) })
            ])
        }

        private static let query = """
            query FindPullRequests($owner:String!, $name:String!, $state:PullRequestState!, $count:Int!, $cursor:String) {
               __typename
               repository(owner: $owner, name: $name) {
                 __typename
                 pullRequests(states: [$state], orderBy: { field: UPDATED_AT, direction: DESC }, first: $count, after: $cursor) {
                    totalCount
                    pageInfo {
                      hasNextPage
                      endCursor
                    }
                    edges {
                      node {
                        id
                        number
                        url
                        state
                        mergeable
                        headRefName
                        headRepository {
                          nameWithOwner
                          visibility
                        }
                     }
                   }
                 }
               }
             }
            """

        public typealias Response = GraphQLResponse<QueryResponse>

        public struct QueryResponse : Decodable, CursoredAPIResponse {
            public var endCursor: GraphQLCursor? {
                repository.pullRequests.pageInfo?.endCursor
            }

            public var elementCount: Int {
                repository.pullRequests.nodes.count
            }

            public enum TypeName : String, Decodable, Hashable { case Query }
            public let __typename: TypeName
            public var repository: Repository
            public struct Repository : Decodable {
                public enum Repository : String, Decodable, Hashable { case Repository }
                public let __typename: Repository
                public var pullRequests: EdgeList<PullRequest>
                public struct PullRequest : Decodable {
                    public var id: OID
                    public var number: Int
                    public var url: URL?
                    public var state: PullRequestState
                    public var mergeable: String // e.g., "CONFLICTING" or "UNKNOWN"
                    public var headRefName: String // e.g., "main"
                    public var headRepository: HeadRepository?
                    public struct HeadRepository : Decodable {
                        public var nameWithOwner: String
                        public var visibility: RepositoryVisibility // e.g., "PUBLIC"
                    }
                }
            }
        }
    }

    public struct GetSponsorsQuery : GraphQLAPIRequest & CursoredAPIRequest {
        /// The owner organization for the PR
        public var owner: String
        /// The base repository name for the PR
        public var name: String

        /// the number of forks to return per batch
        public var count: Int = 100

        public var cursor: GraphQLCursor? = nil

        public func postData() throws -> Data? {
            try executeGraphQL(Self.query, variables: [
                "owner": .str(owner),
                "name": .str(name),
                "count": .num(.init(count)),
                "cursor": cursor.flatMap({ .str($0.rawValue) })
            ])
        }

        private static let query = """
            query GetSponsorsQuery($owner:String!, $name:String!, $count:Int!, $cursor:String) {
               __typename
               repository(owner: $owner, name: $name) {
                 __typename
                 owner {
                   login
                   url
                   ... on Organization {
                     __typename
                     name
                     sponsorsListing {
                       __typename
                       name
                       isPublic
                       activeGoal {
                         __typename
                         title
                         kind
                         percentComplete
                         targetValue
                         description
                       }
                     }
                   }
                 }
                 forks(first: $count, after: $cursor) {
                  edges {
                    node {
                     __typename
                     nameWithOwner
                     owner {
                       login
                       url
                       ... on Organization {
                         __typename
                         name
                         sponsorsListing {
                           __typename
                           name
                           isPublic
                           activeGoal {
                             __typename
                             title
                             kind
                             percentComplete
                             targetValue
                             description
                            }
                          }
                        }
                      }
                    }
                  }
                }
              }
            }
            """

        public typealias Response = GraphQLResponse<QueryResponse>

        public struct QueryResponse : Decodable, CursoredAPIResponse {
            public var endCursor: GraphQLCursor? {
                repository.forks.pageInfo?.endCursor
            }

            public var elementCount: Int {
                repository.forks.nodes.count
            }

            public enum TypeName : String, Decodable, Hashable { case Query }
            public let __typename: TypeName
            public var repository: Repository
            public struct Repository : Decodable {
                public enum Repository : String, Decodable, Hashable { case Repository }
                public let __typename: Repository

                public var owner: Owner

                public struct Owner : Decodable {
                    var login: String
                    var url: String

                    // ... on Organization fields
                    
                    var name: String?
                    var sponsorsListing: SponsorsListing?

                    public struct SponsorsListing : Decodable {
                        public enum TypeName : String, Decodable, Hashable { case SponsorsListing }
                        public let __typename: TypeName
                        var name: String
                        var isPublic: Bool
                        var activeGoal: SponsorsGoal?

                        public struct SponsorsGoal : Decodable {
                            public enum TypeName : String, Decodable, Hashable { case SponsorsGoal }
                            public let __typename: TypeName
                            var kind: KindName? // e.g. TOTAL_SPONSORS_COUNT or MONTHLY_SPONSORSHIP_AMOUNT
                            var title: String?
                            var description: String?
                            var percentComplete: Double?
                            var targetValue: Double?

                            public struct KindName : RawDecodable, Hashable {
                                public static let TOTAL_SPONSORS_COUNT = KindName(rawValue: "TOTAL_SPONSORS_COUNT")
                                public static let MONTHLY_SPONSORSHIP_AMOUNT = KindName(rawValue: "MONTHLY_SPONSORSHIP_AMOUNT")
                                public let rawValue: String
                                public init(rawValue: String) {
                                    self.rawValue = rawValue
                                }
                            }
                        }
                    }
                }


                public var forks: EdgeList<Fork>
                public struct Fork : Decodable {
//                    public var id: OID
                    public var nameWithOwner: String
                    public var owner: Owner
                }
            }
        }
    }

    /// An asset returned from an API query
    public struct ReleaseAsset : Decodable {
        public var name: String
        public var size: Int
        public var contentType: String
        public var downloadCount: Int
        public var downloadUrl: URL
        public var createdAt: Date
        public var updatedAt: Date
    }

    public struct User : Decodable {
        public var name: String
        public var email: String
        public var date: Date?
    }



    /// [PullRequestState](https://docs.github.com/en/graphql/reference/enums#pullrequeststate)
    public struct PullRequestState : RawDecodable, Hashable {
        /// A pull request that has been closed without being merged.
        public static let CLOSED = Self(rawValue: "CLOSED")
        /// A pull request that has been closed by being merged.
        public static let MERGED = Self(rawValue: "MERGED")
        /// A pull request that is still open.
        public static let OPEN = Self(rawValue: "OPEN")

        public let rawValue: String
        public init(rawValue: String) {
            self.rawValue = rawValue
        }
    }

    /// [RepositoryVisibility](https://docs.github.com/en/graphql/reference/enums#repositoryvisibility)
    public struct RepositoryVisibility : RawDecodable, Hashable {
        /// The repository is visible only to users in the same business.
        public static let INTERNAL = Self(rawValue: "INTERNAL")
        /// The repository is visible only to those with explicit access.
        public static let PRIVATE = Self(rawValue: "PRIVATE")
        /// The repository is visible to everyone.
        public static let PUBLIC = Self(rawValue: "PUBLIC")

        public let rawValue: String
        public init(rawValue: String) {
            self.rawValue = rawValue
        }
    }


    /// [GitSignatureState](https://docs.github.com/en/graphql/reference/enums#gitsignaturestate)
    public struct GitSignatureState : RawDecodable, Hashable {
        /// The signing certificate or its chain could not be verified.
        public static let BAD_CERT = Self(rawValue: "BAD_CERT")
        /// Invalid email used for signing.
        public static let BAD_EMAIL = Self(rawValue: "BAD_EMAIL")
        /// Signing key expired.
        public static let EXPIRED_KEY = Self(rawValue: "EXPIRED_KEY")
        /// Internal error - the GPG verification service misbehaved.
        public static let GPGVERIFY_ERROR = Self(rawValue: "GPGVERIFY_ERROR")
        /// Internal error - the GPG verification service is unavailable at the moment.
        public static let GPGVERIFY_UNAVAILABLE = Self(rawValue: "GPGVERIFY_UNAVAILABLE")
        /// Invalid signature.
        public static let INVALID = Self(rawValue: "INVALID")
        /// Malformed signature.
        public static let MALFORMED_SIG = Self(rawValue: "MALFORMED_SIG")
        /// The usage flags for the key that signed this don't allow signing.
        public static let NOT_SIGNING_KEY = Self(rawValue: "NOT_SIGNING_KEY")
        /// Email used for signing not known to GitHub.
        public static let NO_USER = Self(rawValue: "NO_USER")
        /// Valid signature, though certificate revocation check failed.
        public static let OCSP_ERROR = Self(rawValue: "OCSP_ERROR")
        /// Valid signature, pending certificate revocation checking.
        public static let OCSP_PENDING = Self(rawValue: "OCSP_PENDING")
        /// One or more certificates in chain has been revoked.
        public static let OCSP_REVOKED = Self(rawValue: "OCSP_REVOKED")
        /// Key used for signing not known to GitHub.
        public static let UNKNOWN_KEY = Self(rawValue: "UNKNOWN_KEY")
        /// Unknown signature type.
        public static let UNKNOWN_SIG_TYPE = Self(rawValue: "UNKNOWN_SIG_TYPE")
        /// Unsigned.
        public static let UNSIGNED = Self(rawValue: "UNSIGNED")
        /// Email used for signing unverified on GitHub.
        public static let UNVERIFIED_EMAIL = Self(rawValue: "UNVERIFIED_EMAIL")
        /// Valid signature and verified by GitHub.
        public static let VALID = Self(rawValue: "VALID")

        public let rawValue: String
        public init(rawValue: String) {
            self.rawValue = rawValue
        }
    }

    /// The commit instance
    typealias CommitInfo = GetCommitQuery.QueryResponse
}

fileprivate extension Dictionary {
    func percentEncoded() -> Data? {
        return map { key, value in
            let escapedKey = "\(key)".escapedURLTerm
            let escapedValue = "\(value)".escapedURLTerm
            return escapedKey + "=" + escapedValue
        }
        .joined(separator: "&")
        .data(using: .utf8)
    }
}

/// An API request that is expected to use GraphQL `POST` requests.
public protocol GraphQLAPIRequest : APIRequest where Service == FairHub {
}

public extension GraphQLAPIRequest {
    /// GraphQL requests all use the same query endpoint
    func queryURL(for service: Service) -> URL {
        URL(string: "https://api.github.com/graphql")!
    }

    /// Creates a GraphQL query with a variable mapping.
    func executeGraphQL(_ body: String, variables: [String: JSum?] = [:]) throws -> Data {
        var req = JObj()
        req["variables"] = .obj(variables.mapValues({ $0 ?? JSum.nul }))
        req["query"] = .str(body)
        return try req.json()
    }
}

private extension String {
    /// http://spec.graphql.org/draft/#sec-String-Value
    var escapedGraphQLString: String {
        let scalars = self.unicodeScalars

        var output = ""
        output.reserveCapacity(scalars.count)
        for scalar in scalars {
            switch scalar {
            case "\u{8}": output.append("\\b")
            case "\u{c}": output.append("\\f")
            case "\"": output.append("\\\"")
            case "\\": output.append("\\\\")
            case "\n": output.append("\\n")
            case "\r": output.append("\\r")
            case "\t": output.append("\\t")
            case UnicodeScalar(0x0)...UnicodeScalar(0xf), UnicodeScalar(0x10)...UnicodeScalar(0x1f): output.append(String(format: "\\u%04x", scalar.value))
            default: output.append(Character(scalar))
            }
        }

        return output
    }
}


extension AppCatalogItem {
    public struct Diff {
        public let new: AppCatalogItem
        public let old: AppCatalogItem?
    }
}

extension AppCatalog {

    /// Transfers version date information from the source catalog to this catalog for each bundle identifier
    public mutating func importVersionDates(from sourceCatalog: AppCatalog) {
        let srcMap = sourceCatalog.apps.dictionary(keyedBy: \.bundleIdentifier)

        for (index, item) in self.apps.enumerated() {
            if let oldApp = srcMap[item.bundleIdentifier] {
                self.apps[index].versionDate = oldApp.versionDate
            }
        }

    }

    /// Update the version date to the current date for each item that has changed
    public mutating func updateVersionDates(for diffs: [AppCatalogItem.Diff], with date: Date) {
        let diffMap = diffs.dictionary(keyedBy: \.new.bundleIdentifier)
        for (index, item) in self.apps.enumerated() {
            if let diff = diffMap[item.bundleIdentifier] {
                if diff.new.version != diff.old?.version {
                    dbg("updating version date for diff of:", diff.new.bundleIdentifier)
                    self.apps[index].versionDate = date
                }
            }
        }
    }

    /// Compare two catalogs and report the changes that indicate version changes between catalog entries with the same bundle identifier
    static func newReleases(from oldcat: AppCatalog, to newcat: AppCatalog, comparator: (_ new: AppCatalogItem, _ old: AppCatalogItem?) -> Bool = { $0.version != $1?.version }) -> [AppCatalogItem.Diff] {
        let oldapps = oldcat.apps.filter { $0.beta != true }
        let newapps = newcat.apps.filter { $0.beta != true }

        let oldids = oldapps.map(\.bundleIdentifier)
        let newids = newapps.map(\.bundleIdentifier)

        let oldmap = oldapps.dictionary(keyedBy: \.bundleIdentifier)
        let newmap = newapps.dictionary(keyedBy: \.bundleIdentifier)

        var diffs: [AppCatalogItem.Diff] = []
        for appid in (oldids + newids).distinct() {
            guard let newapp = newmap[appid] else {
                // the app has been removed; not newsworthy
                continue
            }

            let oldapp: AppCatalogItem? = oldmap[appid]
            if comparator(newapp, oldapp) {
                diffs.append(AppCatalogItem.Diff(new: newapp, old: oldapp))
            }
        }

        return diffs
    }
}
