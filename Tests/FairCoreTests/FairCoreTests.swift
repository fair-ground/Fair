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

final class FairCoreTests: XCTestCase {
    func testFairBundle() throws {
        let readme = try Bundle.fairCore.loadResource(named: "README.md")
        XCTAssertGreaterThan(readme.count, 50)
    }

    func testXOrOr() throws {
        typealias StringOrInt = XOr<String>.Or<Int>
        let str = StringOrInt("ABC")
        let int = StringOrInt(12)
        XCTAssertNotEqual(str, int)
        XCTAssertEqual("[\"ABC\"]", try String(data: JSONEncoder().encode([str]), encoding: .utf8))
        XCTAssertEqual("[12]", try String(data: JSONEncoder().encode([int]), encoding: .utf8))

        func rt<T: Codable & Equatable>(_ value: T, equal: Bool = true, line: UInt = #line) throws {
            let roundTripped = try T(json: value.debugJSON.utf8Data)
            if equal {
                XCTAssertEqual(value, roundTripped, line: line)
            } else {
                XCTAssertNotEqual(value, roundTripped, line: line)
            }
        }

        let _: XOr<String>.Or<XOr<Int>.Or<Double>> = XOr<String>.Or<Int>.Or<Double>("")

        // check that `infer()` works on nested XOrs
        let nested: XOr<String>.Or<XOr<XOr<Int>.Or<Double>>.Or<Bool>> = XOr<String>.Or<Int>.Or<Double>.Or<Bool>("")
        let _: String? = nested.infer()
        let _: Int? = nested.infer()
        let _: Double? = nested.infer()
        let _: Bool? = nested.infer()
        XCTAssertEqual("", nested.infer())

        let _: XOr<String>.Or<XOr<XOr<XOr<Int>.Or<Double>>.Or<Bool>>.Or<Float>> = XOr<String>.Or<Int>.Or<Double>.Or<Bool>.Or<Float>("")

        //        let _: XOr<String>.Or<XOr<Int>.Or<XOr<Double>.Or<Float>>> = XOr<String>.Or<Int>.Or<Double>.Or<Float>("")

        XCTAssertEqual("[123]", [XOr<Int>(123)].debugJSON)
        XCTAssertEqual("[false]", [XOr<String>.Or<Bool>(false)].debugJSON)
        XCTAssertEqual("[[]]", [XOr<String>.Or<[String]>([])].debugJSON)
        XCTAssertEqual("[{}]", [XOr<String>.Or<[String: String]>([:])].debugJSON)
        XCTAssertEqual("[{\"X\":1}]", [XOr<String>.Or<[String: Int]>(["X":1])].debugJSON)
        XCTAssertEqual("[\"ABC\"]", [XOr<String>.Or<Bool>("ABC")].debugJSON)

        try rt(XOr<Int>(123))
        try rt(XOr<String>("ABC"))

        try rt(XOr<Int>.Or<String>("ABC"))
        try rt(XOr<Int>.Or<String>(12))

        try rt(XOr<Int>.Or<String>.Or<Bool>(12))
        try rt(XOr<Int>.Or<String>.Or<Bool>(.init("ABC")))
        try rt(XOr<Int>.Or<String>.Or<Bool>(.init(true)))
        try rt(XOr<Int>.Or<String>.Or<Bool>(.init(false)))

        try rt(XOr<UInt8>.Or<UInt16>(UInt8.max))
        try rt(XOr<UInt8>.Or<UInt16>(UInt16.max))
        try rt(XOr<UInt16>.Or<UInt8>(UInt16.max))
        // since UInt8.max can be decoded into UInt16, this test will fail because the UInt8 side is encoded, but the UInt16 side is decoded
        try rt(XOr<UInt16>.Or<UInt8>(UInt8.max), equal: false)

        try rt(XOr<Int>.Or<Double>(123.4))

        // should fail because round numbers are indistinguishable beteen Int and Double in JSON, so the Double side will be encoded, but the Int side will be the one that will be decoded (simply because it is first in the list)
        try rt(XOr<Int>.Or<Double>(123.0), equal: false)
    }

    @available(*, deprecated, message: "uses sha1(), which is deprecated")
    func testSHAHash() throws {
        // echo -n abc | shasum -a 1 hash.txt
        XCTAssertEqual("03cfd743661f07975fa2f1220c5194cbaff48451", "abc\n".utf8Data.sha1().hex())

        // echo -n abc | shasum -a 256 hash.txt
        XCTAssertEqual("edeaaff3f1774ad2888673770c6d64097e391bc362d7d6fb34982ddf0efd18cb", "abc\n".utf8Data.sha256().hex())

        // echo -n abc | shasum -a 512 hash.txt
        XCTAssertEqual("4f285d0c0cc77286d8731798b7aae2639e28270d4166f40d769cbbdca5230714d848483d364e2f39fe6cb9083c15229b39a33615ebc6d57605f7c43f6906739d", "abc\n".utf8Data.sha512().hex())
    }

    /// Tests modeling JSON types using `XOr.Or`
    func testJSON() throws {
        typealias JSONPrimitive = XOr<String>.Or<Double>.Or<Bool>?
        typealias JSON1<T> = XOr<JSONPrimitive>.Or<T>
        typealias JSON2<T> = JSON1<JSON1<T>>
        typealias JSON3<T> = JSON2<JSON1<T>>
        typealias JSON = JSON3<JSONPrimitive>
        typealias JSONArray = Array<JSON>
        typealias JSONObject = Dictionary<String, JSON>
        typealias JSONComplex = XOr<JSONObject>.Or<JSONArray>

        // let json1 = try JSON(json: "abc".utf8Data)
    }

    /// Our test org
    static let org = appfairName

    /// The hub that we use for testing, the so-called "git"-hub.
    static func hub() throws -> FairHub {
        try FairHub(hostOrg: "github.com/" + org, authToken: authToken, allowFrom: [".*EDU"])
    }

    /// if the environment uses the "GITHUB_TOKEN" (e.g., in an Action), then pass it along to the API requests
    static let authToken: String? = ProcessInfo.processInfo.environment["GITHUB_TOKEN"]

    /// Issue a request against the hub for the given request type
    func request<A: APIRequest>(_ request: A) throws -> A.Response? where A.Service == FairHub {
        try Self.hub().requestSync(request)
    }

    func testFetchIssueCommentsQuery() throws {
        let hub = try FairCoreTests.hub()
        let response = try hub.requestBatches(FairHub.IssueCommentsQuery(user: appfairBot, count: Int.random(in: 30...99)), maxBatches: Int.random(in: 101...999))

        let comments = response
            .compactMap(\.result.successValue)
            .flatMap(\.data.user.issueComments.nodes)


        // make sure we got at least one batch
        XCTAssertGreaterThan(comments.count, 100, "should have gone past the end of the batch")
    }

    func testQueryError() throws {
        let hub = try FairCoreTests.hub()
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
        let hub = try FairCoreTests.hub()
        let response = try hub.requestSync(FairHub.RepositoryQuery(owner: "fairapp", name: "Fair")).get().data

        let org = response.organization
        let repo = org.repository

        XCTAssertEqual(nil, org.email)
        XCTAssertEqual("fairapp", org.login)

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
        let hub = try FairCoreTests.hub()
        let response = try hub.requestSync(FairHub.GetCommitQuery(owner: appfairName, name: "App", ref: "feeb3d5974ccb518addb774c3d033fec1615fba5")).get().data

        guard let sig = response.repository.object.signature else {
            return XCTFail("no signature in response")
        }

        XCTAssertEqual("fairapps", response.repository.object.author?.name)
        XCTAssertEqual("fairapps@appfair.net", response.repository.object.author?.email)
        XCTAssertEqual(nil, sig.signer.name)
        XCTAssertEqual("fairapps@appfair.net", sig.signer.email)
        XCTAssertEqual("VALID", sig.state)
        XCTAssertEqual(true, sig.isValid)
        XCTAssertEqual(false, sig.wasSignedByGitHub)
    }

    func testPostFairsealPRComment() throws {
        let hub = try FairCoreTests.hub()
        let fairseal = FairHub.FairSeal(url: URL(string: "https://github.com/Fair-Skies/App/releases/download/0.0.0/Fair-Skies-macOS.zip")!, sha256: "b5bb9d8014a0f9b1d61e21e796d78dccdf1352f23cd32812f4850b878ae4944c", permissions: AppEntitlement.bitsetRepresentation(for: Set(AppEntitlement.allCases)), coreSize: 0)

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

    func testRepositoryForkQuery() throws {
        let hub = try FairCoreTests.hub()

        /// tests that paginated queries work and return consistent results
        var resultResults: [[FairHub.RepositoryForkQuery.QueryResponse.BaseRepository.Repository]] = []
        for _ in 1...3 {
            let results = try hub.requestBatches(FairHub.RepositoryForkQuery(owner: appfairName, name: "App", count: Int.random(in: 2...22)), maxBatches: 1_000)
            let forks = results
                .compactMap(\.result.successValue)
                .flatMap(\.data.repository.forks.nodes)
            resultResults.append(forks)
        }

        XCTAssertEqual(resultResults[0].count, resultResults[1].count)
        XCTAssertEqual(resultResults[0].count, resultResults[2].count)
    }

    func testBuildCatalog() throws {
        let catalog = try FairCoreTests.hub().buildCatalog(requestLimit: nil)
        let names = Set(catalog.apps.map({ $0.name })) // + " " + ($0.version ?? "") }))
        dbg("catalog", names.sorted())
        XCTAssertTrue(names.contains("Yankee Swap"))
        XCTAssertTrue(names.contains("Cloud Cuckoo"))
        //XCTAssertTrue(names.contains("Tune Out"))
        XCTAssertFalse(names.contains("App"))
        XCTAssertGreaterThanOrEqual(names.count, 10)
        dbg("created catalog count:", names.count, "size:", catalog.prettyJSON.count.localizedByteCount())
    }

    func testFetchCatalog() throws {
        let url = URL(string: "https://www.appfair.net/fairapps.json")!

        let (data, response) = try URLSession.shared.fetchSync(URLRequest(url: url, cachePolicy: .reloadIgnoringLocalAndRemoteCacheData, timeoutInterval: 10.0))
        XCTAssertEqual(200, (response as? HTTPURLResponse)?.statusCode)

        let catalog = try FairAppCatalog(json: data.gunzip() ?? data, dateDecodingStrategy: .iso8601)
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

    func testProjectFormat() throws {
        let valid = { PropertyListSerialization.propertyList($0, isValidFor: PropertyListSerialization.PropertyListFormat.openStep) }

        let _ = valid

        var fmt: PropertyListSerialization.PropertyListFormat = .binary
        let parse = { (x: Data) in try PropertyListSerialization.propertyList(from: x, options: [], format: &fmt) }

        let _ = parse
    }

    /// Verifies the default name validation strategy
    func testNameValidation() throws {
        let validate = { try AppNameValidation.standard.validate(name: $0) }

        XCTAssertNoThrow(try validate("Fair-App"))
        XCTAssertNoThrow(try validate("Awesome-Town"))
        XCTAssertNoThrow(try validate("Fair-App"))
        XCTAssertNoThrow(try validate("Fair-Awesome"))

        XCTAssertNoThrow(try validate("ABCDEFGHIJKL-LKJIHGFEDCBA"))

        XCTAssertThrowsError(try validate("ABCDEFGHIJKLM-LKJIHGFEDCBA"), "word too long")
        XCTAssertThrowsError(try validate("ABCDEFGHIJKL-MLKJIHGFEDCBA"), "word too long")

        XCTAssertThrowsError(try validate("Fair App"), "spaces are not allowed")
        XCTAssertThrowsError(try validate("Awesome Town"), "spaces are not allowed")
        XCTAssertThrowsError(try validate("Fair App"), "spaces are not allowed")
        XCTAssertThrowsError(try validate("Fair Awesome"), "spaces are not allowed")

        XCTAssertThrowsError(try validate("One"), "fewer than two words are not allowed")
        XCTAssertThrowsError(try validate("One-Two-Three"), "more than two words are not allowed")
        XCTAssertThrowsError(try validate("App-App"), "duplicate words are not allowed")

        XCTAssertThrowsError(try validate("Fair-App2"), "digits in names should be not allowed")
        XCTAssertThrowsError(try validate("Fair-1App"), "digits in names should be not allowed")
        XCTAssertThrowsError(try validate("Lucky-App4U"), "digits in names should be not allowed")
    }

    func testAppVersionParsing() {
        // TODO: test semantic version sorting
        // https://semver.org/#spec-item-11

        let parse = { AppVersion(string: $0)?.versionDescription }

        XCTAssertEqual(nil, parse(""))
        XCTAssertEqual(nil, parse(" "))
        XCTAssertEqual(nil, parse("1.2. 3"))
        XCTAssertEqual(nil, parse("1.2..3"))
        XCTAssertEqual(nil, parse(".1.2.3"))
        XCTAssertEqual(nil, parse("1.2.3."))
        XCTAssertEqual(nil, parse("1_1.2.3."))
        XCTAssertEqual(nil, parse("-1.2.3"))
        XCTAssertEqual(nil, parse("1.-2.3"))
        XCTAssertEqual(nil, parse("1.2.-3"))

        XCTAssertEqual("1.2.3", parse("1.2.3"))
        XCTAssertEqual("0.2.3", parse("0.2.3"))
        XCTAssertEqual("999.9999.99999", parse("999.9999.99999"))
    }

    func testParsePackageResolved() throws {
        let resolved = """
        {
          "object": {
            "pins": [
              {
                "package": "Clang_C",
                "repositoryURL": "https://github.com/something/Clang_C.git",
                "state": {
                  "branch": null,
                  "revision": "90a9574276f0fd17f02f58979423c3fd4d73b59e",
                  "version": "1.0.2",
                }
              },
              {
                "package": "Commandant",
                "repositoryURL": "https://github.com/something/Commandant.git",
                "state": {
                  "branch": null,
                  "revision": "c281992c31c3f41c48b5036c5a38185eaec32626",
                  "version": "0.12.0"
                }
              }
            ]
          },
          "version": 1
        }
        """

        let pm = try JSONDecoder().decode(ResolvedPackage.self, from: resolved.utf8Data)
        XCTAssertEqual(2, pm.object.pins.count)
    }

    func testEntitlementBitset() {
        let allbits: UInt64 = 1125899906842620
        let bitset = { AppEntitlement.bitsetRepresentation(for: $0) }

        XCTAssertEqual(4, bitset([.app_sandbox]))
        XCTAssertEqual([.app_sandbox], AppEntitlement.fromBitsetRepresentation(from: 4))

        XCTAssertEqual(12, bitset([.app_sandbox, .network_client]))
        XCTAssertEqual([.network_client, .app_sandbox], AppEntitlement.fromBitsetRepresentation(from: 12))

        XCTAssertEqual(262156, bitset([.app_sandbox, .network_client, .files_user_selected_read_write]))
        XCTAssertEqual([.app_sandbox, .network_client, .files_user_selected_read_write], AppEntitlement.fromBitsetRepresentation(from: 262156))

        XCTAssertEqual(allbits, bitset(Set(AppEntitlement.allCases)))
        XCTAssertEqual(Set(AppEntitlement.allCases), AppEntitlement.fromBitsetRepresentation(from: allbits))
    }

#if os(macOS)
    func testCodesignVerify() throws {
        let textEdit = "/System/Applications/TextEdit.app"
        let (stdout, stderr) = try Process.codesignVerify(appURL: URL(fileURLWithPath: textEdit))
        let verified = stdout + stderr

        // ["Executable=/System/Applications/TextEdit.app/Contents/MacOS/TextEdit", "Identifier=com.apple.TextEdit", "Format=app bundle with Mach-O universal (x86_64 arm64e)", "CodeDirectory v=20400 size=1899 flags=0x0(none) hashes=49+7 location=embedded", "Platform identifier=13", "Signature size=4442", "Authority=Software Signing", "Authority=Apple Code Signing Certification Authority", "Authority=Apple Root CA", "Signed Time=Jul 31, 2021 at 08:16:31", "Info.plist entries=34", "TeamIdentifier=not set", "Sealed Resources version=2 rules=2 files=0", "Internal requirements count=1 size=68"]
        // print(verified)

        XCTAssertTrue(verified.contains("Identifier=com.apple.TextEdit"))
        XCTAssertTrue(verified.contains("Authority=Apple Root CA"))
    }

#endif //os(macOS)
}
