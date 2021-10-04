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

    #if canImport(Compression)
    @available(*, deprecated, message: "uses sha1(), which is deprecated")
    func testSHAHash() throws {
        // echo -n abc | shasum -a 1 hash.txt
        XCTAssertEqual("03cfd743661f07975fa2f1220c5194cbaff48451", "abc\n".utf8Data.sha1().hex())

        // echo -n abc | shasum -a 256 hash.txt
        XCTAssertEqual("edeaaff3f1774ad2888673770c6d64097e391bc362d7d6fb34982ddf0efd18cb", "abc\n".utf8Data.sha256().hex())

        // echo -n abc | shasum -a 512 hash.txt
        XCTAssertEqual("4f285d0c0cc77286d8731798b7aae2639e28270d4166f40d769cbbdca5230714d848483d364e2f39fe6cb9083c15229b39a33615ebc6d57605f7c43f6906739d", "abc\n".utf8Data.sha512().hex())
    }
    #endif

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
}
