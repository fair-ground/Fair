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
import Swift
import XCTest
import FairCore
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

final class FairCoreTests: XCTestCase {
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

        XCTAssertEqual("[123]", try [XOr<Int>(123)].debugJSON)
        XCTAssertEqual("[false]", try [XOr<String>.Or<Bool>(false)].debugJSON)
        XCTAssertEqual("[[]]", try [XOr<String>.Or<[String]>([])].debugJSON)
        XCTAssertEqual("[{}]", try [XOr<String>.Or<[String: String]>([:])].debugJSON)
        XCTAssertEqual("[{\"X\":1}]", try [XOr<String>.Or<[String: Int]>(["X":1])].debugJSON)
        XCTAssertEqual("[\"ABC\"]", try [XOr<String>.Or<Bool>("ABC")].debugJSON)

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

    func testProjectFormat() throws {
        let valid = { PropertyListSerialization.propertyList($0, isValidFor: PropertyListSerialization.PropertyListFormat.openStep) }

        let _ = valid

        var fmt: PropertyListSerialization.PropertyListFormat = .binary
        let parse = { (x: Data) in try PropertyListSerialization.propertyList(from: x, options: [], format: &fmt) }

        let _ = parse
    }

    func testAppVersionParsing() {
        // TODO: test semantic version sorting
        // https://semver.org/#spec-item-11

        let parse = { AppVersion(string: $0, prerelease: false)?.versionString }

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

        XCTAssertGreaterThan(AppVersion(major: 1, minor: 0, patch: 0, prerelease: false), AppVersion(major: 1, minor: 0, patch: 0, prerelease: true), "a pre-release should be sorted below a non-pre-release version with the same numbers")
        XCTAssertLessThan(AppVersion(major: 1, minor: 0, patch: 0, prerelease: true), AppVersion(major: 1, minor: 0, patch: 0, prerelease: false), "a pre-release should be sorted below a non-pre-release version with the same numbers")
        XCTAssertGreaterThan(AppVersion(major: 1, minor: 0, patch: 1, prerelease: true), AppVersion(major: 1, minor: 0, patch: 0, prerelease: false), "a pre-release should be sorted above other non-prerelease lower versions")
        XCTAssertGreaterThan(AppVersion(major: 1, minor: 0, patch: 1, prerelease: true), AppVersion(major: 1, minor: 0, patch: 0, prerelease: true), "a pre-release should be sorted above other lower versions")
    }

    func testParsePlist() throws {
        for plist in [
            try Plist(data: """
                <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
                <plist version="1.0">
                <dict>
                    <key>arrayOfStrings</key>
                    <array>
                        <string>abc</string>
                        <string>def</string>
                    </array>
                    <key>stringKey</key>
                    <string>xyz</string>
                    <key>intKey</key>
                    <integer>2</integer>
                </dict>
                </plist>
                """.utf8Data),

            // result of converting the above XML with: plutil -convert binary1 -o pl.bplist pl.plist
            try Plist(data: Data(base64Encoded: "YnBsaXN0MDDTAQIDBAUGWXN0cmluZ0tleVZpbnRLZXleYXJyYXlPZlN0cmluZ3NTeHl6EAKiBwhTYWJjU2RlZggPGSAvMzU4PAAAAAAAAAEBAAAAAAAAAAkAAAAAAAAAAAAAAAAAAABA") ?? .init()),

            // result of converting the above XML with: plutil -convert json -o pl.jplist pl.plist
            // seems to not work…
            // try Plist(data: #"{"stringKey":"xyz","intKey":2,"arrayOfStrings":["abc","def"]}"#.utf8Data),

        ] {
            XCTAssertEqual("xyz", plist.rawValue["stringKey"] as? String)
            XCTAssertEqual(["abc", "def"], plist.rawValue["arrayOfStrings"] as? [String])
            XCTAssertEqual(2, plist.rawValue["intKey"] as? Int)
        }
    }

    func testParseXML() throws {
        let parsed = try XMLNode.parse(data: """
        <root>
            <element attr="value">
                <child1>
                    Value
                </child1>
                <child2/>
            </element>
        </root>
        """.utf8Data)

        XCTAssertEqual("", parsed.elementName) // root element
        XCTAssertEqual("root", parsed.elementChildren.first?.elementName)
        XCTAssertEqual(1, parsed.elementChildren.count)
        XCTAssertEqual(1, parsed.elementChildren.first?.elementChildren.count)
        XCTAssertEqual(2, parsed.elementChildren.first?.elementChildren.first?.elementChildren.count)
        XCTAssertEqual("Value", parsed.elementChildren.first?.elementChildren.first?.elementChildren.first?.childContentTrimmed)
    }

    func testParseXMLNamespaced() throws {
        let doc1 = try XMLNode.parse(data: """
        <foo:root xmlns:foo="http://main/ns" xmlns:bar="http://secondary/ns">
          <foo:child bar:attr="1234">some data</foo:child>
        </foo:root>
        """.utf8Data)

        let doc2 = try XMLNode.parse(data: """
        <bar:root xmlns:bar="http://main/ns" xmlns:foo="http://secondary/ns">
          <bar:child foo:attr="1234">some data</bar:child>
        </bar:root>
        """.utf8Data)

        let doc3 = try XMLNode.parse(data: """
        <root xmlns="http://main/ns" xmlns:baz="http://secondary/ns">
          <child baz:attr="1234">some data</child>
        </root>
        """.utf8Data)

        guard let e1 = doc1.elementChildren.first else { return XCTFail("no root") }
        guard let c1 = e1.elementChildren.first else { return XCTFail("no child") }
        guard let e2 = doc2.elementChildren.first else { return XCTFail("no root") }
        guard let c2 = e2.elementChildren.first else { return XCTFail("no child") }
        guard let e3 = doc3.elementChildren.first else { return XCTFail("no root") }
        guard let c3 = e3.elementChildren.first else { return XCTFail("no child") }

        XCTAssertEqual(["bar": "http://secondary/ns", "foo": "http://main/ns"], e1.namespaces)
        XCTAssertEqual(["foo": "http://secondary/ns", "bar": "http://main/ns"], e2.namespaces)
        XCTAssertEqual(["baz": "http://secondary/ns", "": "http://main/ns"], e3.namespaces)

        XCTAssertEqual("root", e1.elementName)
        XCTAssertEqual("http://main/ns", e1.namespaceURI)
        XCTAssertEqual("child", c1.elementName)
        XCTAssertEqual("http://main/ns", c1.namespaceURI)
        XCTAssertEqual("1234", c1.attributeValue(key: "attr", namespaceURI: "http://secondary/ns"))

        XCTAssertEqual("root", e2.elementName)
        XCTAssertEqual("http://main/ns", e2.namespaceURI)
        XCTAssertEqual("child", c2.elementName)
        XCTAssertEqual("http://main/ns", c2.namespaceURI)
        XCTAssertEqual("1234", c2.attributeValue(key: "attr", namespaceURI: "http://secondary/ns"))

        XCTAssertEqual("root", e3.elementName)
        XCTAssertEqual("http://main/ns", e3.namespaceURI)
        XCTAssertEqual("child", c3.elementName)
        XCTAssertEqual("http://main/ns", c3.namespaceURI)
        XCTAssertEqual("1234", c3.attributeValue(key: "attr", namespaceURI: "http://secondary/ns"))

    }

    func testTidyHTML() throws {
        #if os(iOS) || os(tvOS) || os(watchOS) // XMLDocument unavailable on iOS…
        //XCTAssertThrowsError(try tidyHTML()) // …so the `.tidyHTML` flag should throw an error
        #elseif os(Windows)
        // Windows XML parsing doesn't seem to handle whitespace the same
        // try tidyHTML(preservesWhitespace: false) // actually, tidying doesn't seem to work at all
        #elseif !os(Linux) && !os(Android) // these pass on Linux, but the whitespace in the output is different, so it fails the exact equality tests; I'll need to implement XCTAssertEqualDisgrgardingWhitespace() to test on Linux
        try tidyHTML()
        #endif
    }

    func tidyHTML(preservesWhitespace: Bool = true) throws {
        func trim(_ string: String) -> String {
            if preservesWhitespace {
                return string
            } else {
                return string
                    .replacingOccurrences(of: " ", with: "")
                    .replacingOccurrences(of: "\n", with: "")
                    .replacingOccurrences(of: "\r", with: "")
            }
        }

        XCTAssertEqual(trim("""
        <?xml version="1.0" encoding="UTF-8"?><html xmlns="http://www.w3.org/1999/xhtml"><head><title>My Page</title></head><body><h1>Header
        </h1><p>Body Text
        </p></body></html>
        """), trim(try XMLNode.parse(data: """
        <html>
            <head>
                <title>My Page</title>
            </head>
            <body>
                <h1>
                    Header
                </h1>
                <p>
                    Body Text
                </p>
            </body>
        </html>
        """.utf8Data, options: [.tidyHTML]).xmlString()))

        // tag capitalization mismatch
        XCTAssertEqual(trim("""
        <?xml version="1.0" encoding="UTF-8"?><html xmlns="http://www.w3.org/1999/xhtml"><head><title>My Page</title></head><body><h1>Header
        </h1><p>Body Text
        </p></body></html>
        """), trim(try XMLNode.parse(data: """
        <hTmL>
            <head>
                <title>My Page</title>
            </head>
            <BODY>
                <h1>
                    Header
                </H1>
                <p>
                    Body Text
                </p>
            </body>
        </HTML>
        """.utf8Data, options: [.tidyHTML]).xmlString()))

        // tag mismatch
        XCTAssertEqual(trim("""
        <?xml version="1.0" encoding="UTF-8"?><html xmlns="http://www.w3.org/1999/xhtml"><head><title>My Page</title></head><body><h1>Header
        </h1>Body Text<p></p></body></html>
        """), trim(try XMLNode.parse(data: """
        <html>
            <head>
                <title>My Page</title>
            </head>
            <body>
                <h1>
                    Header
                </h2
                <p>
                    Body Text
                </p>
            </body>
        </html>
        """.utf8Data, options: [.tidyHTML]).xmlString()))

        // unclosed tags
        XCTAssertEqual(trim("""
        <?xml version="1.0" encoding="UTF-8"?><html xmlns="http://www.w3.org/1999/xhtml"><head><title>My Page</title></head><body><h1>Header
        </h1><p>Body Text
        </p></body></html>
        """), trim(try XMLNode.parse(data: """
        <html>
            <head>
                <title>My Page</title>
            </head>
            <body>
                <h1>
                    Header
                <p>
                    Body Text
        """.utf8Data, options: [.tidyHTML]).xmlString()))



        XCTAssertEqual(trim("""
        <?xml version="1.0" encoding="UTF-8"?><html xmlns="http://www.w3.org/1999/xhtml"><head><title></title></head><body>Value</body></html>
        """), try XMLNode.parse(data: """
        <root>
            <element attr="value">
                <child1>
                    Value
                </CHILD1>
                <child2>
            </element>
        </root>
        """.utf8Data, options: [.tidyHTML]).xmlString())
    }

    func testSorting() {
        do {
            let ints = [0, 1, 2, 3]
            XCTAssertEqual(ints, ints.sorting(by: \.self, ascending: true))
            XCTAssertEqual(ints.reversed(), ints.sorting(by: \.self, ascending: false))
        }

        do {
            let ints = [0, 1, 2, 2, 3]
            XCTAssertEqual(ints, ints.sorting(by: \.self, ascending: true))
            XCTAssertEqual(ints.reversed(), ints.sorting(by: \.self, ascending: false))
        }

        do {
            let intsNoneFirst = [Optional.none, 0, 1, 2, 2, 2, 3]
            let intsNoneLast = [0, 1, 2, 2, 2, 3, Optional.none]

            XCTAssertEqual(intsNoneFirst, intsNoneFirst.sorting(by: \.self))
            XCTAssertEqual(intsNoneFirst, intsNoneFirst.sorting(by: \.self, ascending: true))
            XCTAssertEqual(intsNoneFirst, intsNoneFirst.sorting(by: \.self, ascending: true, noneFirst: true))

            XCTAssertEqual(intsNoneLast, intsNoneFirst.sorting(by: \.self, noneFirst: false))
            XCTAssertEqual(intsNoneLast, intsNoneFirst.sorting(by: \.self, ascending: true, noneFirst: false))
            XCTAssertEqual(intsNoneLast.reversed(), intsNoneFirst.sorting(by: \.self, ascending: false, noneFirst: false))

            XCTAssertEqual(intsNoneFirst, intsNoneFirst.sorting(by: \.self, noneFirst: true))
            XCTAssertEqual(intsNoneFirst, intsNoneFirst.sorting(by: \.self, ascending: true, noneFirst: true))
            XCTAssertEqual(intsNoneFirst.reversed(), intsNoneFirst.sorting(by: \.self, ascending: false, noneFirst: true))
        }
    }

    func testFairCoreVersion() throws {
        let version = try XCTUnwrap(Bundle.fairCoreVersion)
        dbg("loaded fairCoreVersion:", version.versionStringExtended)
        XCTAssertGreaterThan(version, AppVersion(major: 0, minor: 1, patch: 0, prerelease: false))

        // shows the difference between the auto-generated bundle's infoDictionary and the FairCore.plist
        // XCTAssertEqual("Fair-FairCore-resources", Bundle.fairCore.infoDictionary?["CFBundleIdentifier"] as? String) // this doesn't seem to happen on CI
        XCTAssertEqual("org.fair-ground.Fair", Bundle.fairCoreInfo.CFBundleIdentifier)

    }

    func testBinaryReadable() async throws {
        let bytes: [UInt8] = [ 32, 232, 52, 41, 4, 0, 0, 0, 0, 1, 0, 0, 0, 33]

        /// Wrapper around XCTAssertEqual to bypass lack of support for async
        func xeq<T: Equatable>(_ expect: T, _ actual: T) {
            XCTAssertEqual(expect, actual)
        }

        do { // SeekableDataHandle
            let data = SeekableDataHandle(Data(bytes))
            await xeq(32, try data.readUInt8())
            await xeq(3895732484, try data.readUInt32())
            await xeq(16777216, try data.readInt64())
            await xeq(33, try data.readUInt8())
//            XCTAssertThrowsError(try await data.readData(ofLength: 1))
        }

        do { // SeekableDataHandle & ReverseEndianSeekableData
            let data = await SeekableDataHandle(Data(bytes)).reversedEndian()
            await xeq(32, try data.readUInt8())
            await xeq(69809384, try data.readUInt32())
            await xeq(4294967296, try data.readInt64())
            await xeq(33, try data.readUInt8())
//            XCTAssertThrowsError(try await data.readData(ofLength: 1))
        }

        do { // SeekableDataHandle & ReverseEndianSeekableData & ReverseEndianSeekableData
            let data = await SeekableDataHandle(Data(bytes)).reversedEndian().reversedEndian()
            await xeq(32, try data.readUInt8())
            await xeq(3895732484, try data.readUInt32())
            await xeq(16777216, try data.readInt64())
            await xeq(33, try data.readUInt8())
//            XCTAssertThrowsError(try await data.readData(ofLength: 1))
        }

        do { // SeekableFileHandle
            let file = URL(fileURLWithPath: UUID().uuidString, isDirectory: false, relativeTo: .tmpdir)
            try Data(bytes).write(to: file)
            let data = try SeekableFileHandle(FileHandle(forReadingFrom: file))
            await xeq(32, try data.readUInt8())
            await xeq(3895732484, try data.readUInt32())
            await xeq(16777216, try data.readInt64())
            await xeq(33, try data.readUInt8())
//            XCTAssertThrowsError(try await data.readData(ofLength: 1))
        }
    }

    func testFileHandleBytesAsync() async throws {
        let fh = try FileHandle(forReadingFrom: URL(fileURLWithPath: "/dev/urandom"))
        let xpc = expectation(description: "asyncRead")

        let _ = Task.detached {
            var reads = 0
            do {
                for try await b in fh.bytesAsync {
                    //dbg("read /dev/random chunk:", b)
                    let _ = b
                    reads += 1
                    if reads == 999 {
                        xpc.fulfill()
                        break
                    }
                }
            } catch {
                XCTFail("\(error)")
                xpc.fulfill()
            }
        }

        try await Task.sleep(interval: 0.0) // seems to be needed on iOS to start the bytes
        wait(for: [xpc], timeout: 2)
    }

    func testURLSessionDataAsync() async throws {
        // try await readURLAsync(url: URL(fileURLWithPath: "/dev/urandom")) // works on Darwin but not on Linux

        try await readURLAsync(url: URL(string: "https://www.example.org")!, expectRedirect: 0)

        try await readURLAsync(url: URL(string: "https://github.com/fair-ground/Fair")!, expectRedirect: 0)
        try await readURLAsync(url: URL(string: "https://github.com/fair-ground/Fair.git")!, expectRedirect: 1)

        // two separate redirects: www.github.com -> github.com and Fair.git to Fair/
        try await readURLAsync(url: URL(string: "https://www.github.com/fair-ground/Fair.git")!, expectRedirect: 2, expectChallenge: 2)

        try await readURLAsync(url: URL(string: "https://github.com/fair-ground/UNKNOWN_REPO")!, expectRedirect: 0, expectChallenge: 1) // unknown repositories response with a challenge
    }
    
    func readURLAsync(url: URL, expectRedirect: Int? = nil, expectChallenge: Int? = nil) async throws {
        var redirectReceived: Int = 0
        var challengeReceived: Int = 0
    out:
        for try await event in try URLRequest(url: url).openStream() {
            switch event {
            case .response(let response):
                dbg("response:", response.expectedContentLength, response.mimeType, response.suggestedFilename)
            case .data(let data):
                dbg("data:", data)
                break out
            case .redirect(let redirectResponse, let newRequest, _):
                dbg("redirect:", redirectResponse, newRequest)
                redirectReceived += 1
            case .challenge(let challenge):
                dbg("challenge:", challenge)
                challengeReceived += 1
            default:
                dbg("unhandled event:", event)
            }
        }

        if let expectRedirect = expectRedirect {
            XCTAssertEqual(expectRedirect, redirectReceived, "expected to receive a redirect for: \(url.absoluteString)")
        }

        if let expectChallenge = expectChallenge {
            //XCTAssertEqual(expectChallenge, challengeReceived, "expected to receive a challenge: \(url.absoluteString)")
        }
    }

    func testTemplating() throws {
        XCTAssertEqual("XXX", "XXX".replacing(variables: [:]))
        XCTAssertEqual("Abc XXX 123", "Abc #(var) 123".replacing(variables: ["var": "XXX"]))
        XCTAssertEqual("result", "#(v3#(v2#(v1)))".replacing(variables: ["v1": "P", "v2P": "Q", "v3Q": "result"]))
    }

    func XXXtestReplaceRegex() throws {
        do {
            let exp = try NSRegularExpression(pattern: #"^#+ (?<text>.*)$"#, options: [.anchorsMatchLines])
            XCTAssertEqual("123", "# ABC".replacing(expression: exp, captureGroups: ["text"], replacing: { paramName, paramValue in
                paramName == "text" && paramValue == "ABC" ? "123" : nil
            }))
        }

        do {
            let exp = try NSRegularExpression(pattern: #"\[(?<title>.*)\]\((?<url>.*)\)"#)
            let demo = "[TITLE](URL)"
            // not working; need to re-think multiple capture group handling
            XCTAssertEqual("", demo.replacing(expression: exp, captureGroups: ["title", "url"], replacing: { paramName, paramValue in
                paramName == "url" ? "https://whatever.com" : paramName == "title" ? "some title" : nil
            }))
        }
    }

    func testIndexedCollection() {
        struct Value {
            let name: String
            let value: Int
        }

        var array = IndexedCollection(indexKeyPath: \Value.name)
        array.append(Value(name: "a", value: 0))
        array.append(Value(name: "b", value: 1))
        XCTAssertEqual(array.map(\.name), ["a", "b"])

        array.append(Value(name: "a", value: 2))
        XCTAssertEqual(array.map(\.name), ["b", "a"])
        XCTAssertEqual(array.map(\.value), [1, 2])

        array.append(Value(name: "c", value: 3))
        array.append(Value(name: "b", value: 4))
        array.append(Value(name: "d", value: 5))

        XCTAssertEqual(array.map(\.name), ["a", "c", "b", "d"])
        XCTAssertEqual(array.map(\.value), [2, 3, 4, 5])

        array.removeLast()
        XCTAssertEqual(array.map(\.name), ["a", "c", "b"])

        array.remove(at: 1)
        XCTAssertEqual(array.map(\.name), ["a", "b"])
        XCTAssertEqual(array.map(\.value), [2, 4])

        array.swapAt(0, 1)
        XCTAssertEqual(array.map(\.name), ["b", "a"])
        XCTAssertEqual(array.map(\.value), [4, 2])

        XCTAssertEqual(2, array.count)
        XCTAssertFalse(array.isEmpty)

        array.removeAll()

        XCTAssertTrue(array.isEmpty)
        XCTAssertEqual(0, array.count)
    }

    /// Tests the formatting of `ISO8601Format`, which is absent on Linux and so it implemented via a formatter.
    func testISO8601Format() {
        XCTAssertEqual("1970-01-01T00:00:00Z", Date(timeIntervalSince1970: 0).ISO8601Format())
        XCTAssertEqual("2001-01-01T00:00:00Z", Date(timeIntervalSinceReferenceDate: 0).ISO8601Format())
        XCTAssertEqual("4001-01-01T00:00:00Z", Date.distantFuture.ISO8601Format())

        #if os(Linux)
        XCTAssertEqual(-62135769600.0, Date.distantPast.timeIntervalSince1970)
        XCTAssertEqual("0001-12-30T00:00:00Z", Date.distantPast.ISO8601Format()) // formatting bug?
        #else
        XCTAssertEqual(-62135769600.0, Date.distantPast.timeIntervalSince1970)
        XCTAssertEqual("0001-01-01T00:00:00Z", Date.distantPast.ISO8601Format())
        #endif
    }

    #if !os(Linux) && !os(Android) && !os(Windows)
    func testDispatchSource() async throws {
//        let url = URL(fileOrScheme: "~/Library/Mobile Documents/com~apple~CloudDocs/testDispatchSource.txt")
        //        let url = URL(fileOrScheme: "~/Desktop/testDispatchSource.txt")
        let url = URL(fileURLWithPath: UUID().uuidString, isDirectory: false, relativeTo: .tmpdir)
        try "ABC".write(to: url, atomically: true, encoding: .utf8)
        guard FileManager.default.fileExists(atPath: url.path) == true else {
            return XCTFail("no local file for \(url.path)")
        }

        var changes = 0
        let obs = FileSystemObserver(URL: url) {
            dbg("file change: \(url.path)")
            changes += 1
        }
        XCTAssertEqual(changes, 0)
        try await Task.sleep(interval: 0.1)
        dbg("writing to URL")
        try "XYZ".write(to: url, atomically: true, encoding: .utf8)
        try await Task.sleep(interval: 0.1)
        XCTAssertEqual(changes, 1)
        let _ = obs // need to retain
    }
    #endif
}

extension String {
    public func replacing(expression: NSRegularExpression, options: NSRegularExpression.MatchingOptions = [], captureGroups: [String], replacing: (_ captureGroupName: String, _ captureGroupValue: String) throws -> String?) rethrows -> String {
        var str = self
        for match in expression.matches(in: self, options: options, range: self.span).reversed() {
            for valueName in captureGroups {
                let textRange = match.range(withName: valueName)
                if textRange.location == NSNotFound {
                    continue
                }
                let existingValue = (self as NSString).substring(with: textRange)

                //dbg("replacing header range:", match.range, " with bold text:", text)
                if let newValue = try replacing(valueName, existingValue) {
                    str = (str as NSString).replacingCharacters(in: match.range, with: newValue)
                }
            }
        }
        return str
    }
}

