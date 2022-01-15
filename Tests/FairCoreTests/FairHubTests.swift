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
        if authToken == nil {
            XCTFail("Missing GITHUB_TOKEN and GH_TOKEN in environment")
        }
    }

    /// The hub that we use for testing, the so-called "git"-hub.
    static func hub(skipNoAuth: Bool = false) throws -> FairHub {
        if skipNoAuth == true && Self.authToken == nil {
            throw XCTSkip("cannot run API tests without a token")
        }

        return try FairHub(hostOrg: "github.com/" + org, authToken: authToken, fairsealIssuer: "appfairbot", allowName: [], denyName: [], allowFrom: [".*@.*.EDU", ".*@appfair.net"], denyFrom: [], allowLicense: ["AGPL-3.0"])
    }

    /// if the environment uses the "GH_TOKEN" or "GITHUB_TOKEN" (e.g., in an Action), then pass it along to the API requests
    static let authToken: String? = ProcessInfo.processInfo.environment["GH_TOKEN"] ?? ProcessInfo.processInfo.environment["GITHUB_TOKEN"]

    /// Issue a request against the hub for the given request type
    func request<A: APIRequest>(_ request: A) throws -> A.Response? where A.Service == FairHub {
        try Self.hub().requestSync(request)
    }

    func testQueryError() throws {
        let hub = try Self.hub(skipNoAuth: true)
        do {
            let response = try hub.requestSync(FairHub.LookupPRNumberQuery(owner: nil, name: nil, prid: -1))
            XCTAssertNil(response.result.successValue, "request should not have succeeded")
            if response.result.failureValue?.isRateLimitError != true {
                let reason = response.result.failureValue?.firstFailureReason
                XCTAssertEqual("Argument 'owner' on Field 'repository' has an invalid value (null). Expected type 'String!'.", reason)
            }
        }
        do {
            let response = try hub.requestSync(FairHub.LookupPRNumberQuery(owner: "", name: "", prid: 1))
            XCTAssertNil(response.result.successValue, "request should not have succeeded")
            if response.result.failureValue?.isRateLimitError != true {
                let reason = response.result.failureValue?.firstFailureReason
                XCTAssertEqual("Could not resolve to a Repository with the name '/'.", reason)
            }
        }
    }

    func testFetchRepositoryQuery() throws {
        let hub = try Self.hub(skipNoAuth: true)
        let response = try hub.requestSync(FairHub.RepositoryQuery(owner: "appfair", name: "App"))
        do {
            let content = try response.get().data
            let org = content.organization
            let repo = org.repository

            XCTAssertEqual(nil, org.email)
            XCTAssertEqual("appfair", org.login)

            XCTAssertEqual(0, repo.discussionCategories.totalCount)
            XCTAssertEqual(false, repo.hasIssuesEnabled)
            XCTAssertEqual(false, repo.hasWikiEnabled)
            XCTAssertEqual(false, repo.isFork)
            XCTAssertEqual(false, repo.isEmpty)
            XCTAssertEqual(false, repo.isLocked)
            XCTAssertEqual(false, repo.isMirror)
            XCTAssertEqual(false, repo.isPrivate)
            XCTAssertEqual(false, repo.isArchived)
            XCTAssertEqual(false, repo.isDisabled)

            XCTAssertEqual("AGPL-3.0", repo.licenseInfo.spdxId)
        } catch {
            if response.result.failureValue?.isRateLimitError == true {
                throw XCTSkip("Skipping due to rate limit error")
            } else {
                throw error
            }
        }
    }

    func testFetchCommitQuery() throws {
        let hub = try Self.hub(skipNoAuth: true)
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

    func testCatalogQuery() throws {
        if ({ true }()) {
            throw XCTSkip("disabled to reduce API load")
        }
        
        let hub = try Self.hub(skipNoAuth: true)

        // tests that paginated queries work and return consistent results
        // Note that this can fail when a catalog update occurs during the sequence of runs
        var resultResults: [[FairHub.CatalogQuery.QueryResponse.BaseRepository.Repository]] = []
        for _ in 1...3 {
            let results = try hub.requestBatches(FairHub.CatalogQuery(owner: appfairName, name: "App", count: Int.random(in: 10...80)), maxBatches: 1_000)
            let forks = results
                .compactMap(\.result.successValue)
                .flatMap(\.data.repository.forks.nodes)
            resultResults.append(forks)
        }

        XCTAssertEqual(resultResults[0].count, resultResults[1].count)
        XCTAssertEqual(resultResults[0].count, resultResults[2].count)
    }

    func testBuildMacOSCatalog() throws {
        if ({ true }()) {
            throw XCTSkip("disabled to reduce API load")
        }

        //for _ in 1...3 {
        //    do {
        //        return try buildCatalog()
        //    } catch {
        //        dbg("retrying error:", error)
        //    }
        //}
        try buildCatalog() // fail for real this time

        func buildCatalog() throws {
            let target = ArtifactTarget(artifactType: "macOS.zip", devices: ["mac"])
            let catalog = try Self.hub(skipNoAuth: true).buildCatalog(title: "The App Fair macOS Catalog", fairsealCheck: true, artifactTarget: target, requestLimit: nil)
            let names = Set(catalog.apps.map({ $0.name })) // + " " + ($0.version ?? "") }))
            dbg("catalog", names.sorted())

            XCTAssertFalse(names.contains("App"))

            XCTAssertTrue(names.contains("App Fair"))
            XCTAssertTrue(names.contains("Tune Out"))
            XCTAssertGreaterThanOrEqual(names.count, 3)

            dbg("created macOS catalog count:", names.count, "size:", catalog.prettyJSON.count.localizedByteCount())
        }
    }

    func testBuildIOSCatalog() throws {
        if ({ true }()) {
            throw XCTSkip("disabled to reduce API load")
        }

        //for _ in 1...3 {
        //    do {
        //        return try buildCatalog()
        //    } catch {
        //        dbg("retrying error:", error)
        //    }
        //}
        try buildCatalog() // fail for real this time

        func buildCatalog() throws {
            let target = ArtifactTarget(artifactType: "iOS.ipa", devices: ["iphone", "ipad"])
            let catalog = try Self.hub(skipNoAuth: true).buildCatalog(title: "The App Fair iOS Catalog", fairsealCheck: false, artifactTarget: target, requestLimit: nil)
            let names = Set(catalog.apps.map({ $0.name })) // + " " + ($0.version ?? "") }))
            dbg("catalog", names.sorted())

            XCTAssertFalse(names.contains("App"))

            //XCTAssertFalse(names.contains("App Fair")) // App Fair should not be in iOS cataloa
            XCTAssertTrue(names.contains("Tune Out"))
            XCTAssertGreaterThanOrEqual(names.count, 3)

            dbg("created iOS catalog count:", names.count, "size:", catalog.prettyJSON.count.localizedByteCount())
        }
    }

    func testFetchCatalog() throws {
        guard let url = appfairCatalogURL else {
            return XCTFail("could not load catalog URL")
        }

        let (data, response) = try URLSession.shared.fetchSync(URLRequest(url: url, cachePolicy: .reloadIgnoringLocalAndRemoteCacheData, timeoutInterval: 10.0))
        XCTAssertEqual(200, (response as? HTTPURLResponse)?.statusCode)

        let catalog = try FairAppCatalog(json: data, dateDecodingStrategy: .iso8601)
        XCTAssertEqual("The App Fair", catalog.name)
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
