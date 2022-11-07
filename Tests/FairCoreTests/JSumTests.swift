/**
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

final class JSumTests : XCTestCase {
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
            try JSum.parse(plist: value)
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

    /// Create a seeded random JSum for deserialization performance testing.
    /// - Parameters:
    ///   - depth: how deep to make the graph
    ///   - breadth: how many elements each object/array level of the graph should contain
    ///   - seed: the random seed
    /// - Returns: a JSum object full of random junk
    func createSampleJSON(depth: Int, breadth: Int, rng: inout some RandomNumberGenerator) -> JSum {
        func coinFlip() -> Bool {
            .random(using: &rng)
        }

        /// Creates a UUID with the given generator
        func uuid() -> UUID {
            UUID(rnd: &rng)
        }

        var values: [JSum] = []
        for _ in 0..<breadth {
            if depth > 1 && coinFlip() {
                // create an object child
                let child = createSampleJSON(depth: depth - 1, breadth: breadth, rng: &rng)
                values.append(child)
            } else {
                // create a primitive child
                switch Int.random(in: 0...3, using: &rng) {
                case 0: values.append(JSum.bol(.random(using: &rng)))
                case 1: values.append(JSum.num(Double.random(in: -999999...999999, using: &rng)))
                case 2: values.append(JSum.str(uuid().uuidString))
                default: values.append(.nul)
                }
            }
        }


        if coinFlip() { // make the element an object
            var obj = JObj()
            for value in values {
                obj[uuid().uuidString] = value
            }
            return .obj(obj)
        } else { // !coinFlip: make the elements an array
            return .arr(values)
        }

    }

    /// Compare the parsing of YAML to JSON with a randomly created blob
    func measureParsing(yaml: Bool) {
        var rng = SeededRandomNumberGenerator(uuids: UUID(uuidString: "A2735FD6-9AA2-4D4C-A38C-204032777FB0")!)

        let jsonString = createSampleJSON(depth: 4, breadth: 8, rng: &rng).prettyJSON // 135K of JSON
        let jsonData = jsonString.utf8Data
        dbg("parsing", yaml ? "YAML" : "JSON", "size:", jsonData.count) // , jsonString)
        measure {
            do {
                if yaml {
                    let _ = try JSum.parse(yaml: jsonString)
                } else {
                    let _ = try JSum.parse(json: jsonData)
                }
            } catch {
                dbg("error parsing", yaml ? "YAML" : "JSON", error)
            }
        }
    }

    func testJSumPerformance() {
        // DEBUG: measured [Time, seconds] average: 0.027, relative standard deviation: 17.855%, values: [0.041431, 0.029785, 0.026326, 0.025420, 0.025128, 0.025061, 0.025044, 0.025029, 0.025122, 0.025348]
        // RELEASE: measured [Time, seconds] average: 0.027, relative standard deviation: 7.668%, values: [0.032428, 0.027311, 0.025933, 0.026352, 0.025509, 0.025922, 0.025220, 0.025139, 0.025720, 0.026276]
        measureParsing(yaml: false)
    }

    func testYamlPerformance() throws {
        // DEBUG: measured [Time, seconds] average: 4.046, relative standard deviation: 1.153%, values: [4.017945, 4.027974, 4.121748, 4.068883, 4.119683, 4.083788, 4.009897, 4.011217, 3.984456, 4.011185]
        // RELEASE: measured [Time, seconds] average: 3.915, relative standard deviation: 0.736%, values: [3.929669, 3.981362, 3.914365, 3.944234, 3.912913, 3.876745, 3.901432, 3.895805, 3.892070, 3.898265]
        measureParsing(yaml: true)
    }

}

