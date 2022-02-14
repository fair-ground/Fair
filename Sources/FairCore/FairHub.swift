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
public let appfairName = "appfair"

/// The canonical location of the catalog for the Fair Ground
public let appfairCatalogURLMacOS = URL(string: "https://www.appfair.net/fairapps-macos.json")!

/// The canonical location of the iOS catalog for the Fair Ground
public let appfairCatalogURLIOS = URL(string: "https://www.appfair.net/fairapps-ios.json")!

/// The canonical location of the enhanced cask app metadata
public let appfairCaskAppsURL = URL(string: "https://www.appfair.net/appcasks.json")!

/// A `GraphQL` endpoint
public protocol GraphQLEndpointService : EndpointService {
    /// The default headers that will be sent with a request
    var requestHeaders: [String: String] { get }
}

/// A Fair Ground based on an online git service such as GitHub or GitLab.
public struct FairHub : GraphQLEndpointService {
    public typealias ErrorType = HubEndpointFailure

    /// The root of the FairGround-compatible service
    public var baseURL: URL

    /// The organization in the hub
    public var org: String

    /// The authorization token for this request, if any
    public var authToken: String?

    /// The account that is accepted as the issuer of a valid fairseal
    public var fairsealIssuer: String?

    /// The regular expression patterns of allowed app names
    public var allowName: [NSRegularExpression]

    /// The regular expression patterns of disallowed app names
    public var denyName: [NSRegularExpression]

    /// The regular expression patterns of allowed e-mail addresses
    public var allowFrom: [NSRegularExpression]

    /// The regular expression patterns of disallowed e-mail addresses
    public var denyFrom: [NSRegularExpression]

    /// The license (SPDX IDs) of permitted licenses, such as: "AGPL-3.0"
    public var allowLicense: [String]

    /// The FairHub is initialized with a host identifier (e.g., "github.com/appfair") that corresponds to the hub being used.
    public init(hostOrg: String, authToken: String? = nil, fairsealIssuer: String?, allowName: [String], denyName: [String], allowFrom: [String], denyFrom: [String], allowLicense: [String]) throws {
        guard let url = URL(string: "https://api." + hostOrg) else {
            throw Errors.badHostOrg(hostOrg)
        }

        self.org = url.lastPathComponent
        self.baseURL = url.deletingLastPathComponent()
        self.authToken = authToken
        self.fairsealIssuer = fairsealIssuer

        let regexs = { try NSRegularExpression(pattern: $0, options: [.caseInsensitive]) }
        self.allowFrom = try allowFrom.map(regexs)
        self.denyFrom = try denyFrom.map(regexs)
        self.allowName = try allowName.map(regexs)
        self.denyName = try denyName.map(regexs)

        self.allowLicense = allowLicense

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
}

public struct ArtifactTarget : Pure {
    public let artifactType: String
    public let devices: Array<String>

    public init(artifactType: String, devices: Array<String>) {
        self.artifactType = artifactType
        self.devices = devices
    }
}

public extension FairHub {
    /// Generates the catalog by fetching all the valid forks of the base fair-ground and associating them with the fairseals published by the fairsealIssuer.
    func buildCatalog(title: String, owner: String = appfairName, fairsealCheck: Bool, artifactTarget: ArtifactTarget, requestLimit: Int?) async throws -> FairAppCatalog {
        // all the seal hashes we will look up to validate releases
        dbg("fetching fairseals")

        guard let fairsealIssuer = fairsealIssuer else {
            throw Errors.missingFairsealIssuer
        }

        let forksResponse = try await self.requestBatches(FairHub.CatalogQuery(owner: owner, name: "App"), maxBatches: appfairMaxApps / 200)
        if let error = forksResponse.compactMap(\.result.failureValue).first {
            throw error
        }
        let forks = forksResponse
            .compactMap(\.result.successValue)
            .flatMap(\.data.repository.forks.nodes)

        dbg("fetched forks:", forks.count)

        var apps: [AppCatalogItem] = []

        for fork in forks  {
            dbg("checking app fork:", fork.owner.appNameWithSpace, fork.name)
            // #warning("TODO validation")
            //            let invalid = validate(org: fork.owner)
            //            if !invalid.isEmpty {
            //                throw Errors.repoInvalid(invalid, org, fork.name)
            //            }
            let appTitle = fork.owner.appNameWithSpace // un-hyphenated name
            let appid = fork.owner.appNameWithHyphen

            let bundleIdentifier = BundleIdentifier("app." + appid)
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

                let homepage = fork.homepageUrl.flatMap(URL.init(string:))

                guard let devEmail = release.tagCommit.author?.email else {
                    dbg(fork.nameWithOwner, "no email for commit")
                    continue
                }

                do {
                    try validateEmailAddress(devEmail)
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
                    try validateAppName(appName)
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
                let sourceSize = release.releaseAssets.nodes.first { asset in
                    asset.downloadUrl.pathExtension == "tgz"
                }?.size
                let iconURL = release.releaseAssets.nodes.first { asset in
                    asset.name == "\(appid).png" // e.g. "Fair-Skies.png"
                }?.downloadUrl

                let beta: Bool = release.isPrerelease

                let sourceIdentifier: String? = nil

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

                    guard let appIcon = releaseAsset(named: appName + ".png") else {
                        dbg("missing appIcon from release")
                        continue
                    }

                    var seal: FairSeal? = nil

                    // scan the comments for the base ref for the matching url seal
                    var urlSeals: [URL: Set<String>] = [:]
                    let comments = (fork.defaultBranchRef.associatedPullRequests.nodes ?? []).compactMap(\.comments.nodes)
                    let fairsealComments = comments.joined().filter({ $0.author.login == fairsealIssuer })
                    for comment in fairsealComments {
                        do {
                            let body = comment.bodyText
                                .trimmed(CharacterSet(charactersIn: "`").union(.whitespacesAndNewlines))
                            seal = try FairSeal(json: body.utf8Data)
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

                    // walk through the recent releases until we find one that has a fairseal on it

                    let app = AppCatalogItem(name: appTitle, bundleIdentifier: bundleIdentifier, subtitle: subtitle, developerName: developerInfo, localizedDescription: localizedDescription, size: size, version: appVersion.versionString, versionDate: versionDate, downloadURL: artifactURL, iconURL: iconURL, screenshotURLs: screenshotURLs, versionDescription: versionDescription, tintColor: seal?.tint, beta: beta, sourceIdentifier: sourceIdentifier, categories: categories, downloadCount: downloadCount, impressionCount: impressionCount, viewCount: viewCount, starCount: starCount, watcherCount: watcherCount, issueCount: issueCount, sourceSize: sourceSize, coreSize: seal?.coreSize, sha256: artifactChecksum, permissions: seal?.permissions, metadataURL: metadataURL.appendingHash(metadataChecksum), readmeURL: readmeURL.appendingHash(readmeChecksum), homepage: homepage)


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

        let news: [AppNewsPost]? = nil

        // in order to minimize catalog changes, always sort by the bundle name
        apps.sort { $0.bundleIdentifier < $1.bundleIdentifier }

        let catalogURL = artifactTarget.devices.contains("mac") ? appfairCatalogURLMacOS : appfairCatalogURLIOS
        let catalog = FairAppCatalog(name: title, identifier: org, sourceURL: catalogURL, apps: apps, news: news)
        return catalog
    }

    /// Generates the appcasks enhanced catalog for Homebrew Casks
    func buildAppCasks(owner: String = appfairName, name: String = "appcasks", excludeEmptyCasks: Bool = true, boostFactor: Int64) async throws -> FairAppCatalog {
        // all the seal hashes we will look up to validate releases
        dbg("buildAppCasks")

        let forksResponse = try await self.requestBatches(FairHub.AppCasksQuery(owner: owner, name: name), maxBatches: appfairMaxApps / 200)
        if let error = forksResponse.compactMap(\.result.failureValue).first {
            throw error
        }
        let forks = forksResponse
            .compactMap(\.result.successValue)
            .flatMap(\.data.repository.forks.nodes)

        dbg("fetched appcasks forks:", forks.count)

        var apps: [AppCatalogItem] = []

        for fork in forks  {
            dbg("checking app fork:", fork.owner.appNameWithSpace, fork.name)

            guard let homepage = fork.owner.websiteUrl else {
                dbg("skipping un-set hostname for owner:", fork.nameWithOwner)
                continue
            }

            if fork.owner.isVerified != true {
                dbg("skipping un-verified owner:", fork.nameWithOwner)
                continue
            }

            let caskPrefix = "cask-"

            let releases = fork.releases
            var releaseNodes = releases.nodes
            dbg("received release names:", releaseNodes.compactMap(\.name))
            if releases.pageInfo?.hasNextPage == true, let releaseCursor = releases.pageInfo?.endCursor {
                dbg("traversing release cursor:", releaseCursor)
                let moreReleases = try await self.requestBatches(FairHub.AppCaskReleasesQuery(repositoryNodeID: fork.id, cursor: releaseCursor), maxBatches: appfairMaxApps / 200)
                let moreReleaseNodes = moreReleases.compactMap(\.result.successValue?.data.node.releases.nodes).joined()
                dbg("received more release names:", moreReleaseNodes.compactMap(\.name))
                releaseNodes.append(contentsOf: moreReleaseNodes)
            }

            for release in releaseNodes {
                let tagName = release.tag.name
                if !tagName.hasPrefix(caskPrefix) {
                    dbg("tag name", tagName.enquote(), "does not begin with expected prefix", caskPrefix.enquote())
                    continue
                }
                let appid = BundleIdentifier(release.tag.name.dropFirst(caskPrefix.count).description)
                let releaseName = release.name ?? release.tag.name

                let subtitle: String? = nil
                let localizedDescription = release.description

                dbg("  checking release tag:", appid, "name:", releaseName)

                let versionDate = release.createdAt
                let versionDescription = release.description

                let beta: Bool = release.isPrerelease

                let sourceIdentifier: String? = nil

                func releaseAsset(named name: String) -> ReleaseAsset? {
                    release.releaseAssets.nodes.first(where: { node in
                        node.name == name
                    })
                }

                dbg("checking target:", appid, "files:", release.releaseAssets.nodes.map(\.name))

                /// Returns all the asset names with the given prefix trimmed off
                func prefixedAssetTag(_ prefix: String) -> [String] {
                    release.releaseAssets.nodes.filter {
                        $0.name.hasPrefix(prefix)
                    }
                    .map {
                        $0.name.dropFirst(prefix.count).description
                    }
                }

                // get the "appfair-utilities" topic and convert it to the standard "public.app-category.utilities"
                let categories = prefixedAssetTag("category-")
                    .compactMap(AppCategory.init(rawValue:))

                let tintColor = prefixedAssetTag("tint-")
                    .filter({ $0.count == 6 }) // needs to be a 6-digit hex code
                    .first

                let appREADME = releaseAsset(named: "README.md")

                guard let caskInstalls = releaseAsset(named: "cask-install") else {
                    dbg("missing cask-install from release")
                    continue
                }

                let appIcon = releaseAsset(named: "AppIcon.png")

                let artifactURL = caskInstalls.downloadUrl // not the real artifact, but we need something for the download URL; it will be ignored when we merge this catalog with the main brew catalog

                let readmeURL = appREADME?.downloadUrl
                let screenshotURLs = release.releaseAssets.nodes.filter { node in
                    if !(node.name.hasSuffix(".png") || node.name.hasSuffix(".jpg")) {
                        return false
                    }
                    return node.name.hasPrefix("screenshot") && node.name.contains("-mac-")
                }

                let downloadCount = caskInstalls.downloadCount
                let impressionCount = appIcon?.downloadCount
                let viewCount = appREADME?.downloadCount

                // walk through the recent releases until we find one that has a fairseal on it

                let app = AppCatalogItem(name: releaseName, bundleIdentifier: appid, subtitle: subtitle, developerName: nil, localizedDescription: localizedDescription, size: nil, version: nil, versionDate: versionDate, downloadURL: artifactURL, iconURL: appIcon?.downloadUrl, screenshotURLs: screenshotURLs.map(\.downloadUrl), versionDescription: versionDescription, tintColor: tintColor, beta: beta, sourceIdentifier: sourceIdentifier, categories: categories.map(\.metadataIdentifier), downloadCount: downloadCount, impressionCount: impressionCount, viewCount: viewCount, starCount: nil, watcherCount: nil, issueCount: nil, sourceSize: nil, coreSize: nil, sha256: nil, permissions: nil, metadataURL: nil, readmeURL: readmeURL, homepage: homepage)

                // only add the cask if it has any supplemental information defined
                if excludeEmptyCasks == false
                    || (app.downloadCount ?? 0) > 0
                    || app.readmeURL != nil
                    || app.iconURL != nil
                    || app.tintColor != nil
                    || app.categories?.isEmpty == false
                    || app.screenshotURLs?.isEmpty == false
                {
                    apps.append(app)
                }
            }
        }


        // apps are ranked based on how much metadata is provided, and then their download count
        func rank(for item: AppCatalogItem) -> Int64 {
            // the base ranking is the number of downloads (represented by the number of times cask-install has been hit)
            var ranking = Int64(item.downloadCount ?? 0)

            // each bit of metadata for a cask boosts its position in the rankings
            if item.readmeURL != nil { ranking += boostFactor }
            if item.iconURL != nil { ranking += boostFactor }
            if item.tintColor != nil { ranking += boostFactor }
            if item.categories?.isEmpty == false { ranking += boostFactor }
            if item.screenshotURLs?.isEmpty == false { ranking += boostFactor }

            return ranking
        }

        apps.sort { rank(for: $0) > rank(for: $1) }

        let catalog = FairAppCatalog(name: "Cask enhanced metadata", identifier: "appcasks", sourceURL: appfairCaskAppsURL, apps: apps, news: nil)
        return catalog
    }

    func validate(org: FairHub.RepositoryQuery.QueryResponse.Organization) -> AppOrgValidationFailure {
        let repo = org.repository
        let isOrigin = org.login == appfairName
        var invalid: AppOrgValidationFailure = []

        if !isOrigin {
            do {
                try AppNameValidation.standard.validate(name: org.login) 
                try validateAppName(org.login)
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
                try validateEmailAddress(org.email)
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

        if !allowLicense.isEmpty && !allowLicense.contains(repo.licenseInfo.spdxId ?? "none") {
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
    func postFairseal(_ fairseal: FairSeal, owner: String = appfairName, name: String = "App") async throws -> URL? {
        guard let appOrg = fairseal.appOrg else {
            dbg("no app org for seal:", fairseal)
            return nil
        }

        let nameWithOwner = appOrg + "/" + name

        let lookupPRsRequest = FairHub.FindPullRequests(owner: owner, name: name)
        let appPR = try await self.requestNextBatch(lookupPRsRequest) { resultIndex, urlResponse, batch in
            try batch.result.get().data.repository.pullRequests.nodes.first { edge in
                edge.state == "OPEN"
                //&& edge.mergeable != "CONFLICTING"
                && edge.headRepository?.nameWithOwner == (nameWithOwner)
            }
        }

        guard let appPR = appPR else {
            dbg("no PRs found for \(appOrg)")
            return nil
        }

        let sealJSON = try fairseal.json(outputFormatting: [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes])
        let sealComment = "```\n" + (sealJSON.utf8String ?? "") + "\n```"
        let postResponse = try await self.request(FairHub.PostCommentQuery(id: appPR.id, comment: sealComment)).get()
        let sealCommentURL = postResponse.data.addComment.commentEdge.node.url // e.g.: https://github.com/appfair/App/pull/72#issuecomment-924952591

        dbg("posted fairseal for:", fairseal.assets.first?.url.absoluteString, "to:", sealCommentURL.absoluteString)

        return sealCommentURL
    }

    /// Checks the commit info to ensure that it is verified, and if so, returns the author information
    func authorize(commit: CommitInfo) throws {
        let info = commit.repository.object
        //guard let verification = info.signature else {
            //throw Errors.noVerification(commit)
        //}

        //if verification.state != "VALID" || verification.isValid == false {
            //throw Errors.invalidVerification(commit)
        //}

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

    private func permitted(value: String, allow: [NSRegularExpression], deny: [NSRegularExpression]) throws -> Bool {
        func matches(pattern: NSRegularExpression) -> Bool {
            pattern.firstMatch(in: value, options: [], range: value.span) != nil
        }

        // if we specified an allow list, then at least one of the patterns must match the email
        if !allow.isEmpty {
            guard let _ = allow.first(where: matches) else {
                throw Errors.valueNotAllowed(value)
            }
        }

        // conversely, if we specified a deny list, then all the addresses must not match
        if !deny.isEmpty {
            if let _ = deny.first(where: matches) {
                throw Errors.valueDenied(value)
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

    /// Validates that the app name is included in the `allow-name` patterns and not included in the `deny-name` list of expressions.
    func validateAppName(_ name: String?) throws {
        guard let name = name, try permitted(value: name, allow: allowName, deny: denyName) == true else {
            throw Errors.invalidName(name)
        }
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
        case repoInvalid(_ reasons: FairHub.AppOrgValidationFailure, _ org: String, _ repo: String)
        case missingFairsealIssuer

        public var errorDescription: String? {
            switch self {
            case .emptyAuthToken: return "No authorization token specified"
            case .badHostOrg(let string): return "Invalid fairground host/org: \(string)"
            case .emptyOrganization(let url): return "Missing organization name in URL: \"\(url.absoluteString)\""
            case .notTopLevelURL(let url): return "Not a top-level URL: \"\(url.absoluteString)\""
            case .badURLScheme(let url): return "Bad URL scheme: \"\(url.absoluteString)\""
            case .noVerification(let info): return "No verification information for commit ref: \"\(info.repository.object.oid.rawValue)\". Release tag commits must be marked 'verified', which means either performing the tag via the web interface, or else GPG signing the release tag."
            case .invalidVerification(let info): return "Commit ref must be verified as valid, but was: \"\(info.repository.object.signature?.state ?? "empty")\". Release tag commits must be marked 'verified', which means either performing the tag via the web interface, or else GPG signing the release tag."
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

    struct RepositoryOwner : Pure {
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

/// The seal of the given URL, summarizing its cryptographic hash, entitlements,
/// and other build-time information
public struct FairSeal : Pure {
    public enum Version : Int, Pure, CaseIterable {
        case v1 = 1
    }

    /// The version of the fairseal JSON
    public private(set) var fairsealVersion: Version?
    /// The permission for this app
    public var permissions: [AppPermission]
    /// The size of the artifact's executable binary
    public var coreSize: Int?
    /// The tint color as an RGBA hex string
    public var tint: String?
    /// The sealed assets
    public var assets: [Asset]

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

    public init(assets: [Asset], permissions: [AppPermission], coreSize: Int?, tint: String?) {
        self.assets = assets
        self.permissions = permissions
        self.coreSize = coreSize
        self.tint = tint
        self.fairsealVersion = Version.allCases.last
    }

    /// The app org associated with this seal; this will be the first component of the first URL's path
    public var appOrg: String? {
        assets.first?.url.path.split(separator: "/").first?.description
    }
}

extension URL {
    /// Adds a hash with the given string to the end of the URL
    func appendingHash(_ hashString: String?) -> URL {
        guard let hashString = hashString else { return self }
        return URL(string: self.absoluteString + "#" + hashString) ?? self
    }
}

// MARK: GraphQL Request & Response


public struct HubEndpointError : Pure, LocalizedError {
    public var message: String // e.g., "Could not resolve to a Repository with the name '/App'."
    public var type: String? // e.g., "NOT_FOUND", "INSUFFICIENT_SCOPES"
    public var path: [String]? // e.g., ["repository"]
    public var documentation_url: URL?

    public var failureReason: String? { message }
}

/// A set of one or more errors returned by the GraphQL API.
public struct HubEndpointErrorList : Pure, Error {
    public var errors: [HubEndpointError]
}

/// The payload of a successful `GraphQL` query.
public struct GraphQLPayload<T : Pure> : Pure {
    public var data: T
}

/// Pass-through cursor support.
extension GraphQLPayload : CursoredAPIResponse where T : CursoredAPIResponse {
    public var endCursor: GraphQLCursor? {
        data.endCursor
    }

    public var elementCount: Int {
        data.elementCount
    }
}

/// Either a single error or a list of errors
public typealias HubEndpointFailure = XOr<HubEndpointError>.Or<HubEndpointErrorList>

public extension HubEndpointFailure {
    /// The first error message for the failure
    var firstFailureReason: String? {
        infer()?.failureReason ?? infer()?.errors.first?.message
    }

    /// Returns `true` if the error is due to a rate limitation
    var isRateLimitError: Bool {
        // TODO: check for error code rather than message
        firstFailureReason == "You have exceeded a secondary rate limit. Please wait a few minutes before you try again."
    }
}

public extension GraphQLEndpointService {
    /// A failure can be either a single error (typically for syntax errors), or a list of errors (typically for structural issues)

    /// A response can contain either a successful value or an error instance
    typealias GraphQLResponse<T: Pure> = XResult<GraphQLPayload<T>, HubEndpointFailure>

    func buildRequest<A: APIRequest>(for request: A, cache: URLRequest.CachePolicy? = nil) throws -> URLRequest where A.Service == Self {
        let url = request.queryURL(for: self)
        var req = URLRequest(url: url)

        req.allHTTPHeaderFields = requestHeaders

        let postData = try request.postData()
        if let postData = postData {
            req.httpMethod = "POST"
            req.httpBody = postData
        }

        if let cache = cache {
            req.cachePolicy = cache
        }

        // un-comment to view raw GraphQL for running in https://docs.github.com/en/graphql/overview/explorer
        // print(wip(postData?.utf8String ?? "").replacingOccurrences(of: "\\n", with: "\n").replacingOccurrences(of: "\\", with: "")) // for debugging post data

        dbg("requesting:", req.httpMethod ?? "GET", url.absoluteString, postData?.utf8String?.count.localizedByteCount(), (postData?.utf8String ?? "").replacingOccurrences(of: "\\n", with: "\n").replacingOccurrences(of: "\\\"", with: "\""))
        return req
    }
}

public extension FairHub {
    /// The HTTP headers that should be attached to all API requests
    var requestHeaders: [String: String] {
        var headers: [String: String] = [:]
        headers["Accept"] = "application/vnd.github.v3+json"
        // apply auth headers if we have one set
        if let authToken = authToken {
            headers["Authorization"] = "token " + authToken
        }

        return headers
    }

    func endpoint(action: [String], _ params: [String: String?]) -> URL {
        var comps = URLComponents()
        comps.path = action.joined(separator: "/")
        comps.queryItems = params.map(URLQueryItem.init(name:value:))
        return comps.url(relativeTo: baseURL) ?? baseURL
    }


    /// An object ID
    struct OID : RawRepresentable, Pure {
        public let rawValue: String
        public init(rawValue: String) {
            self.rawValue = rawValue
        }
    }

    /// Generic placeholder for a related collection that only has a `totalCount` property requested
    struct NodeCount : Pure {
        public let totalCount: Int
    }

    struct NodeList<T: Pure>: Pure {
        let nodes: [T]?
    }

    struct EdgeList<T: Pure>: Pure {
        let totalCount: Int?
        let pageInfo: PageInfo?
        let edges: [EdgeNode<T>]

        /// Maps through to the edge's node
        var nodes: [T] {
            edges.map(\.node)
        }

        struct EdgeNode<T: Pure>: Pure {
            let cursor: String?
            let node: T
        }

        /// The info for a page of results, which includes a cursor to traverse
        struct PageInfo : Pure {
            let endCursor: GraphQLCursor?
            let hasNextPage: Bool?
            let hasPreviousPage: Bool?
            let startCursor: GraphQLCursor?
        }
    }

    /// Utility for including an optional string parameter or `null` if it is `.none`
    private static func quotedOrNull(_ string: String?) -> String {
        string?.escapedGraphQLString.enquote(with: "\"") ?? "null"
    }

    struct GetCommitQuery : GraphQLAPIRequest {
        let queryName: String = "GetCommitQuery"
        public var owner: String
        public var name: String
        public var ref: String

        public init(owner: String, name: String, ref: String) {
            self.owner = owner
            self.name = name
            self.ref = ref
        }

        public func postData() throws -> Data? {
            try ["query": """
             query \(queryName) {
             __typename
              repository(owner: "\(owner)", name: "\(name)") {
                object(oid: "\(ref)") {
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
            """].json()
        }

        public typealias Response = GraphQLResponse<QueryResponse>

        public struct QueryResponse : Pure {
            public enum TypeName : String, Pure { case Query }
            public let __typename: TypeName
            public let repository: Repository
            public struct Repository : Pure {
                public let object: Object
                public struct Object : Pure {
                    public let oid: OID
                    public let abbreviatedOid: String
                    public let author: Author?
                    public let signature: Signature?

                    public struct Author : Pure {
                        let name: String?
                        let email: String?
                        let date: Date
                    }

                    public struct Signature : Pure {
                        let email: String?
                        let isValid: Bool
                        let state: String // e.g.: "VALID"
                        let wasSignedByGitHub: Bool
                        let signer: Signer
                        public struct Signer : Pure {
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

    struct RepositoryQuery : GraphQLAPIRequest {
        let queryName: String = "RepositoryQuery"
        public var owner: String
        public var name: String

        public init(owner: String, name: String) {
            self.owner = owner
            self.name = name
        }

        public func postData() throws -> Data? {
            try ["query": """
             query \(queryName) {
              __typename
              organization(login: "\(owner)") {
                __typename
                name
                login
                email
                isVerified
                websiteUrl
                url
                createdAt
                repository(name: "\(name)") {
                  __typename
                  visibility
                  createdAt
                  updatedAt
                  homepageUrl
                  forkingAllowed
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
                  hasWikiEnabled
                  hasProjectsEnabled
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
            """].json()
        }

        public typealias Response = GraphQLResponse<QueryResponse>

        public struct QueryResponse : Pure {
            public enum TypeName : String, Pure { case Query }
            public let __typename: TypeName
            public let organization: Organization
            public struct Organization : Pure {
                public enum TypeName : String, Pure { case User, Organization }
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
                public struct Repository : Pure {
                    public enum TypeName : String, Pure { case Repository }
                    public let __typename: TypeName
                    public let visibility: String // e.g., "PUBLIC",
                    public let createdAt: Date
                    public let updatedAt: Date
                    public let homepageUrl: String?
                    public let forkingAllowed: Bool
                    public let isFork: Bool
                    public let isEmpty: Bool
                    public let isLocked: Bool
                    public let isMirror: Bool
                    public let isPrivate: Bool
                    public let isArchived: Bool
                    public let isDisabled: Bool
                    public let isInOrganization: Bool
                    public let hasWikiEnabled: Bool
                    public let hasProjectsEnabled: Bool
                    public let hasIssuesEnabled: Bool
                    public let discussionCategories: NodeCount
                    public let forkCount: Int
                    public let stargazerCount: Int
                    public let issues: NodeCount
                    public let licenseInfo: License
                    public struct License : Pure {
                        public enum TypeName : String, Pure { case License }
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
    struct AppCasksQuery : GraphQLAPIRequest & CursoredAPIRequest {
        public let queryName: String = "AppCasksQuery"
        public typealias Service = FairHub

        public var owner: String
        public var name: String

        /// the number of forks to return per batch
        public var count: Int = 100

        /// the number of releases to scan
        public var releaseCount: Int = 100

        /// the number of release assets to process
        public var assetCount: Int = 25

        public var cursor: GraphQLCursor? = nil

        public func postData() throws -> Data? {
            try ["query": """
             query \(queryName) {
             __typename
              repository(owner: "\(owner)", name: "\(name)") {
                __typename
                forks(after: \(quotedOrNull(cursor?.rawValue)), first: \(count), isLocked: false, privacy: PUBLIC) {
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
                      shortDescriptionHTML
                      forkCount
                      stargazerCount
                      hasIssuesEnabled
                      discussionCategories { totalCount }
                      issues { totalCount }
                      stargazers { totalCount }
                      watchers { totalCount }
                      isInOrganization
                      hasWikiEnabled
                      hasProjectsEnabled
                      homepageUrl
                      releases(first: \(releaseCount)) {
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
                            isLatest
                            isPrerelease
                            isDraft
                            description
                            releaseAssets(first: \(assetCount)) {
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
            """].json()
        }

        public typealias Response = GraphQLResponse<QueryResponse>

        public struct QueryResponse : Pure, CursoredAPIResponse {
            public var endCursor: GraphQLCursor? {
                repository.forks.pageInfo?.endCursor
            }

            public var elementCount: Int {
                repository.forks.nodes.count
            }

            public enum TypeName : String, Pure { case Query }
            public let __typename: TypeName
            public let repository: BaseRepository
            public struct BaseRepository : Pure {
                public enum TypeName : String, Pure { case Repository }
                public let __typename: TypeName
                public let forks: EdgeList<Repository>
                public struct Repository : Pure {
                    public enum TypeName : String, Pure { case Repository }
                    public let __typename: TypeName
                    public let id: String // used as a base for paginaton
                    public let name: String
                    public let nameWithOwner: String
                    public let owner: RepositoryOwner
                    public let description: String?
                    public let visibility: String // e.g. "PUBLIC"
                    public let shortDescriptionHTML: String
                    public let forkCount: Int
                    public let stargazerCount: Int
                    public let hasIssuesEnabled: Bool
                    public let discussionCategories: NodeCount
                    public let issues: NodeCount
                    public let stargazers: NodeCount
                    public let watchers: NodeCount
                    public let isInOrganization: Bool
                    public let hasWikiEnabled: Bool
                    public let hasProjectsEnabled: Bool
                    public let homepageUrl: String?
                    public let releases: EdgeList<Release>

                    public struct Release : Pure {
                        public enum TypeName : String, Pure { case Release }
                        public let __typename: TypeName
                        public let tag: Tag
                        public let createdAt: Date
                        public let updatedAt: Date
                        public let isLatest: Bool
                        public let isPrerelease: Bool
                        public let isDraft: Bool
                        public let name: String?
                        public let description: String?
                        public let releaseAssets: EdgeList<ReleaseAsset>

                        public struct Tag: Pure {
                            public let name: String
                        }

                    }
                }
            }
        }
    }

    /// The query to get additional pages of releases for `AppCasksQuery` when a fork has many releases
    struct AppCaskReleasesQuery : GraphQLAPIRequest & CursoredAPIRequest {
        public let queryName: String = "AppCaskReleasesQuery"
        public typealias Service = FairHub

        /// The opaque ID of the fork repository
        public let repositoryNodeID: String

        /// the number of releases to get per batch
        public var releaseCount: Int = 100

        /// the number of release assets to process
        public var assetCount: Int = 25

        public var cursor: GraphQLCursor?

        public func postData() throws -> Data? {
            try ["query": """
            query \(queryName) {
            node(id: "\(repositoryNodeID)") {
              id
              __typename
              ... on Repository {
                releases(after: \(quotedOrNull(cursor?.rawValue)), first: \(releaseCount)) {
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
                      isLatest
                      isPrerelease
                      isDraft
                      description
                      releaseAssets(first: \(assetCount)) {
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
        """].json()
        }

        public typealias Response = GraphQLResponse<QueryResponse>

        public struct QueryResponse : Pure, CursoredAPIResponse {
            public var endCursor: GraphQLCursor? {
                node.releases.pageInfo?.endCursor
            }

            public var elementCount: Int {
                node.releases.nodes.count
            }

            public let node: Repository
            public struct Repository : Pure {
                public enum TypeName : String, Pure { case Repository }
                public let __typename: TypeName
                public let id: String // used as a base for paginaton

                /// We re-use the same release structure between the parent query and the cursored release query
                public let releases: EdgeList<AppCasksQuery.QueryResponse.BaseRepository.Repository.Release>
            }
        }
    }

    /// The query to generate a fair-ground catalog
    struct CatalogQuery : GraphQLAPIRequest & CursoredAPIRequest {
        public let queryName: String = "CatalogQuery"
        public typealias Service = FairHub

        public var owner: String
        public var name: String

        /// the number of forks to return per batch
        public var count: Int = 5 // any higher can trigger timeout errors like: “Something went wrong while executing your query. This may be the result of a timeout, or it could be a GitHub bug. Please include `AF94:6EB8:23D7BE:65794E:61DDA32D` when reporting this issue.”

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
            try ["query": """
             query \(queryName) {
             __typename
              repository(owner: "\(owner)", name: "\(name)") {
                __typename
                forks(after: \(quotedOrNull(cursor?.rawValue)), first: \(count), isLocked: false, privacy: PUBLIC, orderBy: {field: PUSHED_AT, direction: DESC}) {
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
                      shortDescriptionHTML
                      forkCount
                      stargazerCount
                      hasIssuesEnabled
                      discussionCategories { totalCount }
                      issues { totalCount }
                      stargazers { totalCount }
                      watchers { totalCount }
                      isInOrganization
                      hasWikiEnabled
                      hasProjectsEnabled
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
                      releases(first: \(releaseCount), orderBy: {field: CREATED_AT, direction: DESC}) {
                        nodes {
                          __typename
                          name
                          createdAt
                          updatedAt
                          isLatest
                          isPrerelease
                          isDraft
                          description
                          releaseAssets(first: \(assetCount)) {
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
                        associatedPullRequests(states: [CLOSED], last: \(prCount)) {
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
                            comments(first: \(commentCount)) {
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
            """].json()
        }

        public typealias Response = GraphQLResponse<QueryResponse>

        public struct QueryResponse : Pure, CursoredAPIResponse {
            public var endCursor: GraphQLCursor? {
                repository.forks.pageInfo?.endCursor
            }

            public var elementCount: Int {
                repository.forks.nodes.count
            }

            public enum TypeName : String, Pure { case Query }
            public let __typename: TypeName
            public let repository: BaseRepository
            public struct BaseRepository : Pure {
                public enum TypeName : String, Pure { case Repository }
                public let __typename: TypeName
                public let forks: EdgeList<Repository>
                public struct Repository : Pure {
                    public enum TypeName : String, Pure { case Repository }
                    public let __typename: TypeName
                    public let name: String
                    public let nameWithOwner: String
                    public let owner: RepositoryOwner
                    public let description: String?
                    public let visibility: String // e.g. "PUBLIC"
                    public let shortDescriptionHTML: String
                    public let forkCount: Int
                    public let stargazerCount: Int
                    public let hasIssuesEnabled: Bool
                    public let discussionCategories: NodeCount
                    public let issues: NodeCount
                    public let stargazers: NodeCount
                    public let watchers: NodeCount
                    public let isInOrganization: Bool
                    public let hasWikiEnabled: Bool
                    public let hasProjectsEnabled: Bool
                    public let homepageUrl: String?
                    public var repositoryTopics: NodeList<RepositoryTopic>
                    public let releases: NodeList<Release>
                    public let defaultBranchRef: Ref

                    public struct Ref : Pure {
                        public enum TypeName : String, Pure { case Ref }
                        public let __typename: TypeName
                        public let associatedPullRequests: NodeList<PullRequest>

                        public struct PullRequest : Pure {
                            public enum TypeName : String, Pure { case PullRequest }
                            public let __typename: TypeName
                            public let author: Author
                            public let baseRef: Ref
                            public let comments: NodeList<IssueComment>

                            public struct Author : Pure {
                                public let login: String
                                public let name: String?
                                public let email: String?
                            }

                            public struct Ref : Pure {
                                public enum TypeName : String, Pure { case Ref }
                                public let name: String?
                                public let repository: Repository

                                public struct Repository : Pure {
                                    public let nameWithOwner: String
                                }
                            }

                            public struct IssueComment : Pure {
                                public enum TypeName : String, Pure { case IssueComment }
                                public let __typename: TypeName
                                public let bodyText: String
                                public let author: Author
                                public struct Author : Pure {
                                    public let login: String
                                }
                            }
                        }
                    }

                    public struct Release : Pure {
                        public enum TypeName : String, Pure { case Release }
                        public let __typename: TypeName
                        public let tag: Tag
                        public let tagCommit: Commit
                        public let createdAt: Date
                        public let updatedAt: Date
                        public let isLatest: Bool
                        public let isPrerelease: Bool
                        public let isDraft: Bool
                        public let name: String?
                        public let description: String?
                        public let releaseAssets: EdgeList<ReleaseAsset>

                        public struct Tag: Pure {
                            public let name: String
                        }

                        public struct Commit: Pure {
                            public enum TypeName : String, Pure { case Commit }
                            public let __typename: TypeName
                            public let authoredByCommitter: Bool
                            public let author: Author?
                            public let signature: Signature?

                            public struct Author : Pure {
                                let name: String?
                                let email: String?
                                let date: Date
                            }

                            public struct Signature : Pure {
                                public enum TypeName : String, Pure { case Signature, GpgSignature }
                                public let __typename: TypeName
                                public let isValid: Bool
                                public let signer: User

                                public struct User : Pure {
                                    public enum TypeName : String, Pure { case User }
                                    public let __typename: TypeName
                                    public let name: String?
                                    public let email: String?
                                }
                            }
                        }
                    }

                    public struct RepositoryTopic : Pure {
                        public enum TypeName : String, Pure { case RepositoryTopic }
                        public let __typename: TypeName
                        public let topic: Topic
                        public struct Topic : Pure {
                            public enum TypeName : String, Pure { case Topic }
                            public let __typename: TypeName
                            public let name: String // TODO: this will be the appfair- app category
                        }
                    }
                }
            }
        }
    }

    struct LookupPRNumberQuery : GraphQLAPIRequest {
        let queryName: String = "LookupPRNumberQuery"
        let owner: String?
        let name: String?
        let prid: Int

        public func postData() throws -> Data? {
            try ["query": "query \(queryName) { __typename, repository(owner: \(quotedOrNull(owner)), name: \(quotedOrNull(name))) { pullRequest(number: \(prid)) { id, number } } }"].json()
        }

        public typealias Response = GraphQLResponse<QueryResponse>

        public struct QueryResponse : Pure {
            public enum TypeName : String, Pure { case Query }
            public let __typename: TypeName
            let repository: Repository
            struct Repository : Pure {
                let pullRequest: PullRequest
                struct PullRequest : Pure {
                    let id: OID
                    let number: Int
                }
            }
        }
    }

    struct PostCommentQuery : GraphQLAPIRequest {
        let mutationName: String = "AddComment"
        /// The issue or pull request ID
        let id: OID
        let comment: String?

        public func postData() throws -> Data? {
            try ["query": """
                mutation \(mutationName) {
                  __typename
                  addComment(input: {subjectId: "\(id.rawValue)", body: \(quotedOrNull(comment))}) {
                    commentEdge {
                      node {
                        body
                        url
                      }
                    }
                  }
                }
                """].json()
        }

        public typealias Response = GraphQLResponse<QueryResponse>

        public struct QueryResponse : Pure {
            public enum TypeName : String, Pure { case Mutation }
            public let __typename: TypeName
            let addComment: AddComment
            struct AddComment : Pure {
                let commentEdge: CommentEdge
                struct CommentEdge : Pure {
                    let node: Node
                    struct Node : Pure {
                        let body: String
                        let url: URL
                    }
                }
            }
        }
    }

    struct FindPullRequests : GraphQLAPIRequest & CursoredAPIRequest {
        public let queryName: String = "FindPullRequests"
        /// The owner organization for the PR
        public var owner: String = appfairName
        /// The base repository name for the PR
        public var name: String = "App"
        /// The state of the PR
        public var state: String? = "OPEN"
        public var count: Int = 100
        public var cursor: GraphQLCursor? = nil


        public func postData() throws -> Data? {
            try ["query": """
             query \(queryName) {
             __typename
             repository(owner: "\(owner)", name: "\(name)") {
                __typename
               pullRequests(states: [\(state ?? "")], orderBy: { field: UPDATED_AT, direction: DESC }, first: \(count), after: \(quotedOrNull(cursor?.rawValue))) {
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
                          forkingAllowed
                        }
                     }
                   }
                 }
               }
             }
             """].json()
        }

        public typealias Response = GraphQLResponse<QueryResponse>

        public struct QueryResponse : Pure, CursoredAPIResponse {
            public var endCursor: GraphQLCursor? {
                repository.pullRequests.pageInfo?.endCursor
            }

            public var elementCount: Int {
                repository.pullRequests.nodes.count
            }

            public enum TypeName : String, Pure { case Query }
            public let __typename: TypeName
            public var repository: Repository
            public struct Repository : Pure {
                public enum Repository : String, Pure { case Repository }
                public let __typename: Repository
                public var pullRequests: EdgeList<PullRequest>
                public struct PullRequest : Pure {
                    public var id: OID
                    public var number: Int
                    public var url: URL?
                    public var state: String
                    public var mergeable: String // e.g., "CONFLICTING" or "UNKNOWN"
                    public var headRefName: String // e.g., "main"
                    public var headRepository: HeadRepository?
                    public struct HeadRepository : Pure {
                        public var nameWithOwner: String
                        public var visibility: String // e.g., "PUBLIC"
                        public var forkingAllowed: Bool
                    }
                }
            }
        }
    }

    /// An asset returned from an API query
    struct ReleaseAsset : Pure {
        public var name: String
        public var size: Int
        public var contentType: String
        public var downloadCount: Int
        public var downloadUrl: URL
        public var createdAt: Date
        public var updatedAt: Date
    }

    struct User : Pure {
        public var name: String
        public var email: String
        public var date: Date?
    }

    /// The commit instance
    typealias CommitInfo = FairHub.GetCommitQuery.QueryResponse
}

extension FairHub {
#if swift(>=5.5)
    /// Fetches the `FairAppCatalog`
    @available(macOS 12.0, iOS 15.0, *)
    public static func fetchCatalog(catalogURL: URL, cache: URLRequest.CachePolicy? = nil) async throws -> FairAppCatalog {
        dbg("fetching async", catalogURL)

        var req = URLRequest(url: catalogURL)
        if let cache = cache { req.cachePolicy = cache }
        let (data, response) = try await URLSession.shared.data(for: req, delegate: nil)

        let _ = response
        let catalog = try FairAppCatalog(json: data, dateDecodingStrategy: .iso8601)

        return catalog
    }
#endif // swift(>=5.5)
}

extension String {
    /// `addingPercentEncoding(withAllowedCharacters: .urlQueryValueAllowed)`
    public var escapedURLTerm: String {
        addingPercentEncoding(withAllowedCharacters: .urlQueryValueAllowed) ?? self
    }
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

fileprivate extension CharacterSet {
    static let urlQueryValueAllowed: CharacterSet = {
        let generalDelimitersToEncode = ":#[]@" // does not include "?" or "/" due to RFC 3986 - Section 3.4
        let subDelimitersToEncode = "!$&'()*+,;="

        var allowed = CharacterSet.urlQueryAllowed
        allowed.remove(charactersIn: "\(generalDelimitersToEncode)\(subDelimitersToEncode)")
        return allowed
    }()
}

/// An API request that is expected to use GraphQL `POST` requests.
public protocol GraphQLAPIRequest : APIRequest where Service == FairHub {
}

public extension GraphQLAPIRequest {
    /// GraphQL requests all use the same query endpoint
    func queryURL(for service: Service) -> URL {
        URL(string: "https://api.github.com/graphql")!
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

