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
import XCTest
@testable import FairCore
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

final class FairHubTests: XCTestCase {

    /// Our test org
    static let org = appfairName

    override class func setUp() {
        if ProcessInfo.processInfo.environment["GITHUB_TOKEN"] == nil
            && ProcessInfo.processInfo.environment["GH_TOKEN"] == nil {
            XCTFail("Missing GITHUB_TOKEN and GH_TOKEN in environment")
        }
    }

    /// The hub that we use for testing, the so-called "git"-hub.
    static func hub() throws -> FairHub {
        try FairHub(hostOrg: "github.com/" + org, authToken: authToken, fairsealIssuer: "appfairbot", allowName: [], denyName: [], allowFrom: [".*@.*.EDU", ".*@appfair.net"], denyFrom: [], allowLicense: ["AGPL-3.0"])
    }

    /// if the environment uses the "GH_TOKEN" or "GITHUB_TOKEN" (e.g., in an Action), then pass it along to the API requests
    static let authToken: String? = ProcessInfo.processInfo.environment["GH_TOKEN"] ?? ProcessInfo.processInfo.environment["GITHUB_TOKEN"]

    /// Issue a request against the hub for the given request type
    func request<A: APIRequest>(_ request: A) throws -> A.Response? where A.Service == FairHub {
        try Self.hub().requestSync(request)
    }

    func testQueryError() throws {
        let hub = try Self.hub()
        do {
            let response = try hub.requestSync(FairHub.LookupPRNumberQuery(owner: nil, name: nil, prid: -1))
            XCTAssertEqual("Argument 'owner' on Field 'repository' has an invalid value (null). Expected type 'String!'.", response.result.failureValue?.infer()?.errors.first?.message)
        }
        do {
            let response = try hub.requestSync(FairHub.LookupPRNumberQuery(owner: "", name: "", prid: 1))
            XCTAssertEqual("Could not resolve to a Repository with the name '/'.", response.result.failureValue?.infer()?.errors.first?.message)
        }
    }

    func testFetchRepositoryQuery() throws {
        let hub = try Self.hub()
        let response = try hub.requestSync(FairHub.RepositoryQuery(owner: "fair-ground", name: "Fair")).get().data

        let org = response.organization
        let repo = org.repository

        XCTAssertEqual(nil, org.email)
        XCTAssertEqual("fair-ground", org.login)

        XCTAssertEqual(false, repo.hasIssuesEnabled)
        XCTAssertEqual(false, repo.hasWikiEnabled)
        XCTAssertEqual(false, repo.isFork)
        XCTAssertEqual(false, repo.isEmpty)
        XCTAssertEqual(false, repo.isLocked)
        XCTAssertEqual(false, repo.isMirror)
        XCTAssertEqual(false, repo.isPrivate)
        XCTAssertEqual(false, repo.isArchived)
        XCTAssertEqual(false, repo.isDisabled)
        XCTAssertEqual(nil, repo.homepageUrl)

        XCTAssertEqual("AGPL-3.0", repo.licenseInfo.spdxId)
    }

    func testFetchCommitQuery() throws {
        let hub = try Self.hub()
        let response = try hub.requestSync(FairHub.GetCommitQuery(owner: "fair-ground", name: "Fair", ref: "93d86ba5884772c8ef189bead1ca131bb11b90f2")).get().data

        guard let sig = response.repository.object.signature else {
            return XCTFail("no signature in response")
        }

        XCTAssertNotNil(response.repository.object.author?.name)
        XCTAssertNotNil(sig.signer.email)
        XCTAssertEqual("VALID", sig.state)
        XCTAssertEqual(true, sig.isValid)
        XCTAssertEqual(false, sig.wasSignedByGitHub)
    }

    func testPostFairsealPRComment() throws {
        let hub = try Self.hub()
        let fairseal = FairHub.FairSeal(url: URL(string: "https://github.com/Fair-Skies/App/releases/download/0.0.0/Fair-Skies-macOS.zip")!, sha256: "b5bb9d8014a0f9b1d61e21e796d78dccdf1352f23cd32812f4850b878ae4944c", permissions: AppEntitlement.bitsetRepresentation(for: Set(AppEntitlement.allCases)), coreSize: 0, tint: "aabbcc")

        if ({ true })() { // only execute this manually
            throw XCTSkip("skipping demo fairseal posting")
        } else {
            let commentURL = try hub.postFairseal(fairseal)

            // XCTAssertEqual("/appfair/App/pull/\(appPR.number)", postResponse.data.addComment.commentEdge.node.url.path)

            // let seal = try FairHub.FairSeal(json: postResponse.data.addComment.commentEdge.node.body.utf8Data)
            // XCTAssertEqual(body, seal)
            XCTAssertNotNil(commentURL)
        }
    }

    func testCatalogQuery() throws {
        let hub = try Self.hub()

        /// tests that paginated queries work and return consistent results
        var resultResults: [[FairHub.CatalogQuery.QueryResponse.BaseRepository.Repository]] = []
        for _ in 1...3 {
            let results = try hub.requestBatches(FairHub.CatalogQuery(owner: appfairName, name: "App", count: Int.random(in: 2...22)), maxBatches: 1_000)
            let forks = results
                .compactMap(\.result.successValue)
                .flatMap(\.data.repository.forks.nodes)
            resultResults.append(forks)
        }

        XCTAssertEqual(resultResults[0].count, resultResults[1].count)
        XCTAssertEqual(resultResults[0].count, resultResults[2].count)
    }

    func testBuildMacOSCatalog() throws {
        let catalog = try Self.hub().buildCatalog(fairsealCheck: true, artifactExtensions: ["macOS.zip"], requestLimit: nil)
        let names = Set(catalog.apps.map({ $0.name })) // + " " + ($0.version ?? "") }))
        dbg("catalog", names.sorted())

        XCTAssertFalse(names.contains("App"))

        XCTAssertTrue(names.contains("App Fair"))
        XCTAssertTrue(names.contains("Tune Out"))
        XCTAssertGreaterThanOrEqual(names.count, 3)

        dbg("created macOS catalog count:", names.count, "size:", catalog.prettyJSON.count.localizedByteCount())
    }

    func testBuildIOSCatalog() throws {
        let catalog = try Self.hub().buildCatalog(fairsealCheck: false, artifactExtensions: ["iOS.ipa"], requestLimit: nil)
        let names = Set(catalog.apps.map({ $0.name })) // + " " + ($0.version ?? "") }))
        dbg("catalog", names.sorted())

        XCTAssertFalse(names.contains("App"))

        XCTAssertTrue(names.contains("App Fair"))
        XCTAssertTrue(names.contains("Tune Out"))
        XCTAssertGreaterThanOrEqual(names.count, 3)

        dbg("created iOS catalog count:", names.count, "size:", catalog.prettyJSON.count.localizedByteCount())
    }

    func testFetchCatalog() throws {
        guard let url = appfairCatalogURL else {
            return XCTFail("could not load catalog URL")
        }

        let (data, response) = try URLSession.shared.fetchSync(URLRequest(url: url, cachePolicy: .reloadIgnoringLocalAndRemoteCacheData, timeoutInterval: 10.0))
        XCTAssertEqual(200, (response as? HTTPURLResponse)?.statusCode)

        let catalog = try FairAppCatalog(json: data, dateDecodingStrategy: .iso8601)
        XCTAssertEqual(appfairName, catalog.name)
        dbg("loaded catalog apps:", catalog.apps.count)
    }

//    func testFairHubAllowDenyPatterns() throws {
//        func check(success successEmail: String? = nil, failure failureEmail: String? = nil, verification reason: String = "valid", allow: [String] = [], deny: [String] = []) throws {
//            var hub = try Self.hub()
//            hub.allowFrom = allow
//            hub.denyFrom = deny
//
//            let mkcommit = { (email: String) in
//                FairHub.CommitInfo(sha: "", node_id: "", url: nil, html_url: nil, comments_url: nil, commit: FairHub.CommitInfo.Commit(author: FairHub.User(name: "Some Name", email: email, date: nil), committer: FairHub.User(name: "Some Name", email: email, date: nil), message: "message", url: .tmpdir, comment_count: nil, verification: FairHub.CommitInfo.Verification(verified: true, reason: reason, signature: "", payload: "")))
//            }
//
//            if let successEmail = successEmail {
//                XCTAssertNoThrow(try hub.authorize(commit: mkcommit(successEmail)))
//            }
//
//            if let failureEmail = failureEmail {
//                XCTAssertThrowsError(try hub.authorize(commit: mkcommit(failureEmail)))
//            }
//        }
//
//        try check(success: "abc@QiZ.edu", allow: [".*@QIZ.EDU"])
//        try check(failure: "abc@AQiZ.edu", allow: [".*@QIZ.EDU"])
//
//        try check(success: "abc@qiz.edu", allow: [".*@QIZ.EDU", ".*@ZIQ.EDU"])
//        try check(success: "abc@ziq.edu", allow: [".*@QIZ.EDU", ".*@ZIQ.EDU"])
//        try check(failure: "abc@ziz.edu", allow: [".*@QIZ.EDU", ".*@ZIQ.EDU"])
//        try check(failure: "abc@qiq.edu", allow: [".*@QIZ.EDU", ".*@ZIQ.EDU"])
//
//        try check(failure: "abc@badbadbad.edu", deny: [".*@badbadbad.edu"])
//        try check(failure: "abc@badbadbad.edu", allow: ["abc@badbadbad.edu"], deny: [".*@badbadbad.edu"]) // deny trumps allow
//        try check(success: "abc@badbad.edu", deny: [".*@badbadbad.edu"])
//
//    }

}
