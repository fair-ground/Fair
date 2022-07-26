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

final class FairCoreTests: XCTestCase {
    func testFairBundle() throws {
        let readme = try Bundle.fairCore.loadBundleResource(named: "README.md")
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

    func testSHAHash() throws {
        // echo -n abc | shasum -a 256 hash.txt
        XCTAssertEqual("edeaaff3f1774ad2888673770c6d64097e391bc362d7d6fb34982ddf0efd18cb", "abc\n".utf8Data.sha256().hex())
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
        #if os(iOS) // XMLDocument unavailable on iOS…
        XCTAssertThrowsError(try tidyHTML()) // …so the `.tidyHTML` flag should throw an error
        #elseif os(Windows)
        // Windows XML parsing doesn't seem to handle whitespace the same
        // try tidyHTML(preservesWhitespace: false) // actually, tidying doesn't seem to work at all
        #elseif !os(Linux) // these pass on Linux, but the whitespace in the output is different, so it fails the exact equality tests; I'll need to implement XCTAssertEqualDisgrgardingWhitespace() to test on Linux
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

    func testSeededRandom() throws {
        let uuid = try XCTUnwrap(UUID(uuidString: "A2735FD6-9AA2-4D4C-A38C-204032777FB0"))
        var rnd = SeededRandomNumberGenerator(uuids: uuid, uuid, uuid, uuid, uuid, uuid, uuid, uuid, uuid, uuid, uuid, uuid, uuid, uuid, uuid, uuid, uuid, uuid)
        XCTAssertEqual(59, Int.random(in: 0...100, using: &rnd))
        XCTAssertEqual(3, Int.random(in: 0...100, using: &rnd))
        XCTAssertEqual(53, Int.random(in: 0...100, using: &rnd))
        XCTAssertEqual(44, Int.random(in: 0...100, using: &rnd))
        XCTAssertEqual(7, Int.random(in: 0...100, using: &rnd))

        // ensure that two randomly-seeded generators generate distinct elements
        var rndA = SeededRandomNumberGenerator()
        var rndB = SeededRandomNumberGenerator()
        for _ in 0...999 {
            XCTAssertNotEqual(Int64.random(in: .min...(.max), using: &rndA), Int64.random(in: .min...(.max), using: &rndB))
        }
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

    func testJSum() throws {
        let js: JSum = [
               "string": "hello",
               "number": 1.23,
               "null": nil,
               "array": [1, nil, "foo"],
               "object": [
                   "x": "a",
                   "y": 5,
                   "z": [:]
               ]
            ]

        XCTAssertEqual(js["string"], "hello")
        XCTAssertEqual(js["string"]?.str, "hello")

        XCTAssertEqual(js["number"], 1.23)
        XCTAssertEqual(js["number"]?.num, 1.23)

        XCTAssertEqual(js["null"], JSum.nul)
        XCTAssertNotNil(js["null"]?.nul)

        XCTAssertEqual(js["array"], [1, nil, "foo"])
        XCTAssertEqual(js["array"]?.arr, [1, nil, "foo"])

        XCTAssertEqual(js["object"]?["x"], "a")
        XCTAssertEqual(js["object"]?["x"]?.str, "a")

        XCTAssertEqual(js["array"]?[0], 1)
        XCTAssertEqual(js["array"]?[1], .nul)
        XCTAssertEqual(js["array"]?[2], "foo")
        XCTAssertNil(js["array"]?[3])

        let data = try js.json()
        XCTAssertEqual(data.utf8String, """
        {"array":[1,null,"foo"],"null":null,"number":1.23,"object":{"x":"a","y":5,"z":{}},"string":"hello"}
        """)

        let js2 = try JSum(json: data)
        XCTAssertEqual(js, js2)
    }

    func testJSumDictionary() throws {
        do {
            let dict = NSDictionary(dictionary: [
                "t": NSDate(timeIntervalSinceReferenceDate: 0)
            ])
            XCTAssertEqual(["t": "2001-01-01T00:00:00Z"], try dict.jsum())
        }

        do {
            let dict = NSDictionary(dictionary: [
                "s": "a"
            ])
            XCTAssertEqual(["s": "a"], try dict.jsum())
        }

        do {
            let dict = NSDictionary(dictionary: [
                "i": 1
            ])
            XCTAssertEqual(["i": 1], try dict.jsum())
        }

        do {
            let dict = NSDictionary(dictionary: [
                "d": 1.2
            ])
            XCTAssertEqual(["d": 1.2], try dict.jsum())
        }

        do {
            let dict = NSDictionary(dictionary: [
                "n": NSNull()
            ])
            XCTAssertEqual(["n": nil], try dict.jsum())
        }

        do {
            for b in [true, false] {
                let dict = NSDictionary(dictionary: [
                    "b": NSNumber(booleanLiteral: b)
                ])
                XCTAssertEqual(["b": .bol(b)], try dict.jsum())
            }
        }

        do {
            let dict = NSDictionary(dictionary: [
                "x": "y",
                "y": true,
                "z": 1.2,
            ])
            XCTAssertEqual(["x": "y", "y": true, "z": 1.2], try dict.jsum())
        }

        do {
            let dict = NSDictionary(dictionary: [
                "a": [true, false, "x", [], [:]]
            ])
            XCTAssertEqual(["a": [true, false, "x", [], [:]]], try dict.jsum())
        }

        do {
            let dict = NSDictionary(dictionary: [
                "a": []
            ])
            XCTAssertEqual(["a": []], try dict.jsum())
        }

        do {
            let dict = NSDictionary(dictionary: [
                "a": [[]]
            ])
            XCTAssertEqual(["a": [[]]], try dict.jsum())
        }

        do {
            let dict = NSDictionary(dictionary: [
                "a": [[[:]]]
            ])
            XCTAssertEqual(["a": [[[:]]]], try dict.jsum())
        }

        do {
            let dict = NSDictionary(dictionary: [
                "data": NSData(base64Encoded: "YnBsaXN0MDDTAQIDBAUGWXN0cmluZ0tleVZpbnRLZXleYXJyYXlPZlN0cmluZ3NTeHl6EAKiBwhTYWJjU2RlZggPGSAvMzU4PAAAAAAAAAEBAAAAAAAAAAkAAAAAAAAAAAAAAAAAAABA")!
            ])
            XCTAssertEqual(["data": "YnBsaXN0MDDTAQIDBAUGWXN0cmluZ0tleVZpbnRLZXleYXJyYXlPZlN0cmluZ3NTeHl6EAKiBwhTYWJjU2RlZggPGSAvMzU4PAAAAAAAAAEBAAAAAAAAAAkAAAAAAAAAAAAAAAAAAABA"], try dict.jsum())
        }

        do {
            let dict = NSDictionary(dictionary: [
                "q": [true, NSUUID(), 3.14159]
            ])
            XCTAssertThrowsError(try dict.jsum(), "expected cannotEncode error")
            XCTAssertEqual(["q": [true, 3.14159]], try dict.jsum(options: [.ignoreNonEncodable]))
        }
    }

    func testJSumPropertyLists() throws {
        func plist(_ value: Data) throws -> JSum {
            try Plist(data: value).jsum()
        }

        // Old-school NeXTSTEP property list text format
        XCTAssertEqual(["key": "value"], try plist(#"{ "key" = "value"; }"#.utf8Data))
        XCTAssertEqual(["key": ["1"]], try plist(#"{ "key" = ( "1" ); }"#.utf8Data))
        // XCTAssertEqual(["key": [2.0]], try plist(#"{ "key" = ( 2 ); }"#.utf8Data))

        XCTAssertEqual(["key": ["1"]], try plist("""
            <?xml version="1.0" encoding="UTF-8"?>
            <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
            <plist version="1.0">
            <dict>
                <key>key</key>
                <array>
                    <string>1</string>
                </array>
            </dict>
            </plist>
            """.utf8Data))


        // binary bplist00… data
        XCTAssertEqual(["key": ["1"]], try plist(XCTUnwrap(Data(base64Encoded: "YnBsaXN0MDDRAQJTa2V5oQNRMQgLDxEAAAAAAAABAQAAAAAAAAAEAAAAAAAAAAAAAAAAAAAAEw=="))))
    }

    func testFairCoreVersion() throws {
        let version = try XCTUnwrap(Bundle.fairCoreVersion)
        dbg("loaded fairCoreVersion:", version.versionStringExtended)
        XCTAssertGreaterThan(version, AppVersion(major: 0, minor: 1, patch: 0, prerelease: false))

        // shows the difference between the auto-generated bundle's infoDictionary and the FairCore.plist
        // XCTAssertEqual("Fair-FairCore-resources", Bundle.fairCore.infoDictionary?["CFBundleIdentifier"] as? String) // this doesn't seem to happen on CI
        XCTAssertEqual("org.fair-ground.Fair", Bundle.fairCoreInfo.CFBundleIdentifier)

    }

    func testBinaryReadable() throws {
        let bytes: [UInt8] = [ 32, 232, 52, 41, 4, 0, 0, 0, 0, 1, 0, 0, 0, 33]

        do { // SeekableDataHandle
            let data = SeekableDataHandle(Data(bytes))
            XCTAssertEqual(32, try data.readUInt8())
            XCTAssertEqual(3895732484, try data.readUInt32())
            XCTAssertEqual(16777216, try data.readInt64())
            XCTAssertEqual(33, try data.readUInt8())
            XCTAssertThrowsError(try data.readData(ofLength: 1))
        }

        do { // SeekableDataHandle & ReverseEndianSeekableData
            let data = SeekableDataHandle(Data(bytes)).reversedEndian()
            XCTAssertEqual(32, try data.readUInt8())
            XCTAssertEqual(69809384, try data.readUInt32())
            XCTAssertEqual(4294967296, try data.readInt64())
            XCTAssertEqual(33, try data.readUInt8())
            XCTAssertThrowsError(try data.readData(ofLength: 1))
        }

        do { // SeekableDataHandle & ReverseEndianSeekableData & ReverseEndianSeekableData
            let data = SeekableDataHandle(Data(bytes)).reversedEndian().reversedEndian()
            XCTAssertEqual(32, try data.readUInt8())
            XCTAssertEqual(3895732484, try data.readUInt32())
            XCTAssertEqual(16777216, try data.readInt64())
            XCTAssertEqual(33, try data.readUInt8())
            XCTAssertThrowsError(try data.readData(ofLength: 1))
        }

        do { // SeekableFileHandle
            let file = URL(fileURLWithPath: UUID().uuidString, isDirectory: false, relativeTo: .tmpdir)
            try Data(bytes).write(to: file)
            let data = try SeekableFileHandle(FileHandle(forReadingFrom: file))
            XCTAssertEqual(32, try data.readUInt8())
            XCTAssertEqual(3895732484, try data.readUInt32())
            XCTAssertEqual(16777216, try data.readInt64())
            XCTAssertEqual(33, try data.readUInt8())
            XCTAssertThrowsError(try data.readData(ofLength: 1))
        }
    }

    func testFileHandleAsync() async throws {
        let fh = try FileHandle(forReadingFrom: URL(fileURLWithPath: "/dev/random"))
        let xpc = expectation(description: "asyncRead")

        let queue = OperationQueue.current

        let mode: RunLoop.Mode = .common
        RunLoop.current.run(mode: mode, before: .distantFuture)

        let _ = Task.detached {
            var reads = 0
            for try await chunk in fh.readDataAsync(queue: queue, forModes: [mode]) {
                dbg("read /dev/random chunk:", chunk.count)
                reads += 1
                if reads > 100 {
                    xpc.fulfill()
                    break
                }
            }
        }

//        while true {
//            RunLoop.current.run(mode: .common, before: .distantFuture)
//        }

        // wait(for: [xpc], timeout: 2) // not working
    }

    func testTemplating() throws {
        XCTAssertEqual("XXX", "XXX".replacing(variables: [:]))
        XCTAssertEqual("Abc XXX 123", "Abc #(var) 123".replacing(variables: ["var": "XXX"]))
        XCTAssertEqual("result", "#(v3#(v2#(v1)))".replacing(variables: ["v1": "P", "v2P": "Q", "v3Q": "result"]))
    }

    private func randomData(count: Int) -> Data {
        Data((1...count).map({ _ in UInt8.random(in: (.min)...(.max)) }))
    }

    /// Checks that the SHA1 hex from random data matches between the internal implementation and the CommonCrypto one
    func testSHA1Implementation() {
        for _ in 1...100 {
            let data = randomData(count: Int.random(in: 1...10000))
            let sha1a = data.sha1()
            let sha1b = data.sha1Internal()
            XCTAssertEqual(sha1a.hex(), sha1b.hex())
        }
    }

    /// Checks that the SHA256 hex from random data matches between the internal implementation and the CommonCrypto one
    func testSHA256Implementation() {
        for _ in 1...100 {
            let data = randomData(count: Int.random(in: 1...10000))
            let sha256a = data.sha256()
            let sha256b = data.sha256Internal()
            XCTAssertEqual(sha256a.hex(), sha256b.hex())
        }
    }

    /// Checks that the HMAC hex from random data matches between the internal implementation and the CommonCrypto one
    func testHMACSHA1Implementation() {
        for _ in 1...100 {
            let data = randomData(count: Int.random(in: 1...100_000))
            let kdata = randomData(count: Int.random(in: 1...1_000))
            let hmac1 = data.hmacSHA(key: kdata, hash: .sha1)
            let hmac2 = data.hmacSHAInternal(key: kdata, hash: .sha1)
            XCTAssertEqual(hmac1.hex(), hmac2.hex())
        }
    }

    /// Checks that the HMAC hex from random data matches between the internal implementation and the CommonCrypto one
    func testHMACSHA256Implementation() {
        for _ in 1...100 {
            let data = randomData(count: Int.random(in: 1...100_000))
            let kdata = randomData(count: Int.random(in: 1...1_000))
            let hmac1 = data.hmacSHA(key: kdata, hash: .sha256)
            let hmac2 = data.hmacSHAInternal(key: kdata, hash: .sha256)
            XCTAssertEqual(hmac1.hex(), hmac2.hex())
        }
    }

    /// https://en.wikipedia.org/wiki/HMAC#Examples
    func testHMACSSHA1() {
        let msg = "The quick brown fox jumps over the lazy dog"
        let key = "key"
        let sha1 = msg.utf8Data.hmacSHA(key: key.utf8Data, hash: .sha1)
        XCTAssertEqual("3nybhbi3iqa8ino29wqQcBydtNk=", sha1.base64EncodedString())
    }

    func testHMACCompat() throws {
        // echo -n "value-to-digest" | openssl dgst -sha256 -hmac "secret-key-here" -binary | openssl enc -base64 -A
        // G73zFnFYggHRpmwuRFPgch6ctqEfyhZu33j5PQWYm+4=

        let msg = "value-to-digest"
        let key = "secret-key-here"
        let sha1 = msg.utf8Data.hmacSHA(key: key.utf8Data, hash: .sha256)
        XCTAssertEqual("G73zFnFYggHRpmwuRFPgch6ctqEfyhZu33j5PQWYm+4=", sha1.base64EncodedString())

    }

    /// https://jwt.io/introduction/
    /// https://en.wikipedia.org/wiki/JSON_Web_Token#Structure
    func testHMACSSHA256JWT() throws {
        struct JWTHeader : Encodable {
            var alg: String
            var typ: String
        }

        struct JWTPayload : Encodable {
            var sub: String
            var name: String
            var iat: Int
        }

        // note that field ordering matters, since the serialized JSON is signed
        let header = try JWTHeader(alg: "HS256", typ: "JWT").json(outputFormatting: [.sortedKeys, .withoutEscapingSlashes])
        let payload = try JWTPayload(sub: "1234567890", name: "John Doe", iat: 1516239022).json(outputFormatting: [.sortedKeys, .withoutEscapingSlashes])

        func encode(_ data: Data) -> String {
            data.base64EncodedString()
                .replacingOccurrences(of: "/", with: "_")
                .replacingOccurrences(of: "+", with: "-")
                .trimmingCharacters(in: CharacterSet(charactersIn: "="))
        }

        let message = encode(header) + "." + encode(payload)

        let key = "secretkey" // verify at https://jwt.io/#debugger-io

        let signature = message.utf8Data.hmacSHA(key: key.utf8Data, hash: .sha256)

        let jwt = message + "." + encode(signature)

        XCTAssertEqual(jwt, "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpYXQiOjE1MTYyMzkwMjIsIm5hbWUiOiJKb2huIERvZSIsInN1YiI6IjEyMzQ1Njc4OTAifQ.bKB04O-OWqZhSxdzOhf2RdM_5nb-fWZgpkKpzoa35ks")
    }

    func testJSONSignable() throws {
        struct SigDemo : Codable, JSONSignable {
            var name: String
            var date: Date
            var valid: Bool
            var signatureData: Data?
        }

        let key = "This is my key of arbitrary length."

        let referenceDate = Date(timeIntervalSinceReferenceDate: 1234)
        var ob = SigDemo(name: "Marc", date: referenceDate, valid: true)
        try ob.embedSignature(key: key.utf8Data)
        XCTAssertEqual("rLHGHKe3VGoI3iP5vEg0ytPwaouSFdMq+xl1MYMKsoc=", ob.signatureData?.base64EncodedString())

        try ob.authenticateSignature(key: key.utf8Data)

        ob.date = Date()
        XCTAssertThrowsError(try ob.authenticateSignature(key: key.utf8Data), "altered payload should invalidate signature")

        ob.date = referenceDate
        try ob.authenticateSignature(key: key.utf8Data)


        let key2 = "But now my key is wrong!"
        XCTAssertThrowsError(try ob.authenticateSignature(key: key2.utf8Data), "bad key should not have authenticated the signature")

        // make a new key and re-embed the signature
        try ob.embedSignature(key: key2.utf8Data)
        XCTAssertEqual("90e00sczi/6eraYMF4NXZEOq9QGyFzni5q8O4SGH3b0=", ob.signatureData?.base64EncodedString())

    }

    /// Verifies example case in ``JSONSignable`` header.
    func testJSONSignableCompat() throws {
        struct Inst : Encodable, SigningContainer {
            let b: String
            let d: Bool?
            let a: Int
            let e: [E]
            struct E: Encodable {
                let f: Double?
                let g: String?
            }
        }

        // echo '{ "b": "C", "d": false, "a":2, "e": [{ "f": 1.2 }] }' | jq -cjS | openssl dgst -sha256 -hmac "secret-key-here" -binary | openssl enc -base64 -A
        let inst = Inst(b: "C", d: false, a: 2, e: [Inst.E(f: 1.2, g: nil)])

        XCTAssertEqual(inst.debugJSON, #"{"a":2,"b":"C","d":false,"e":[{"f":1.2}]}"#)

        /// the normalized data to be signed is: `{"a":2,"b":"C","d":false,"e":[{"f":1.2}]}`
        XCTAssertEqual("8JKugJUa41Uaf+lG1q6ndFpqGPxTPkLU9V17kkRBXB4=", try inst.sign(key: "secret-key-here".utf8Data).base64EncodedString())
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

