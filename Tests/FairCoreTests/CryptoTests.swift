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

final class CryptoTests: XCTestCase {
    func testSeededRandom() throws {
        do {
            var rng = SeededRandomNumberGenerator(seed: [0])
            XCTAssertEqual(87, Int.random(in: 0...100, using: &rng))
        }

        do {
            var rng = SeededRandomNumberGenerator(seed: [1])
            XCTAssertEqual(2, Int.random(in: 0...100, using: &rng))
        }

        do {
            var rng = SeededRandomNumberGenerator(seed: [2])
            XCTAssertEqual(64, Int.random(in: 0...100, using: &rng))
        }

        do {
            let uuid = try XCTUnwrap(UUID(uuidString: "A2735FD6-9AA2-4D4C-A38C-204032777FB0"))
            var rng = SeededRandomNumberGenerator(uuids: uuid, uuid, uuid, uuid, uuid, uuid, uuid, uuid, uuid, uuid, uuid, uuid, uuid, uuid, uuid, uuid, uuid, uuid)
            XCTAssertEqual(59, Int.random(in: 0...100, using: &rng))
            XCTAssertEqual(3, Int.random(in: 0...100, using: &rng))
            XCTAssertEqual(53, Int.random(in: 0...100, using: &rng))
            XCTAssertEqual(44, Int.random(in: 0...100, using: &rng))
            XCTAssertEqual(7, Int.random(in: 0...100, using: &rng))
        }

        do {
            // ensure that two randomly-seeded generators generate distinct elements
            var rngA = SeededRandomNumberGenerator()
            var rngB = SeededRandomNumberGenerator()
            for _ in 0...999 {
                XCTAssertNotEqual(Int64.random(in: .min...(.max), using: &rngA), Int64.random(in: .min...(.max), using: &rngB))
            }
        }

        XCTAssertEqual([58, 109, 151], UInt8.randomSequence(seed: [0]).prefix(3).array())
        XCTAssertEqual([58, 109, 151], UInt8.randomSequence(seed: [0, 0]).prefix(3).array())
        XCTAssertEqual([58, 109, 151], UInt8.randomSequence(seed: Array(repeating: 0, count: 256)).prefix(3).array())

        XCTAssertEqual([41, 131, 124], UInt8.randomSequence(seed: [1]).prefix(3).array())
        XCTAssertEqual([86, 193, 50], UInt8.randomSequence(seed: [1, 2]).prefix(3).array())
        XCTAssertEqual([180, 176, 90], UInt8.randomSequence(seed: [1, 2, 3]).prefix(3).array())
        XCTAssertEqual([223, 104, 112], UInt8.randomSequence(seed: [1, 2, 3, 0]).prefix(3).array())
        XCTAssertEqual([77, 149, 52], UInt8.randomSequence(seed: [1, 2, 3, 4]).prefix(3).array())

        XCTAssertEqual([251, 161, 11], UInt8.randomSequence(seed: [1, 2, 3, 9, 99]).prefix(3).array())
        XCTAssertEqual([14, 113, 168], UInt8.randomSequence(seed: [1, 2, 3, 9, 99, 0]).prefix(3).array())
    }

    private func randomData(count: Int) -> Data {
        Data((1...count).map({ _ in UInt8.random(in: (.min)...(.max)) }))
    }

    func testSHAHash() throws {
        // echo -n abc | shasum -a 256 hash.txt
        XCTAssertEqual("edeaaff3f1774ad2888673770c6d64097e391bc362d7d6fb34982ddf0efd18cb", "abc\n".utf8Data.sha256().hex())
    }

    /// Checks that the SHA1 hex from random data matches between the internal implementation and the CommonCrypto one
    func testSHA1Implementation() {
        for _ in 1...100 {
            let data = randomData(count: Int.random(in: 1...10000))
            let sha1a = data.sha1()
            let sha1b = data.sha1Uncommon()
            XCTAssertEqual(sha1a.hex(), sha1b.hex())
        }
    }

    /// Checks that the SHA256 hex from random data matches between the internal implementation and the CommonCrypto one
    func testSHA256Implementation() {
        for _ in 1...100 {
            let data = randomData(count: Int.random(in: 1...10000))
            let sha256a = data.sha256()
            let sha256b = data.sha256Uncommon()
            XCTAssertEqual(sha256a.hex(), sha256b.hex())
        }
    }

    /// Checks that the HMAC hex from random data matches between the internal implementation and the CommonCrypto one
    func testHMACSHA1Implementation() {
        for _ in 1...100 {
            let data = randomData(count: Int.random(in: 1...100_000))
            let kdata = randomData(count: Int.random(in: 1...1_000))
            let hmac1 = data.hmacSHA(key: kdata, hash: .sha1)
            let hmac2 = data.hmacSHAUncommon(key: kdata, hash: .sha1)
            XCTAssertEqual(hmac1.hex(), hmac2.hex())
        }
    }

    /// Checks that the HMAC hex from random data matches between the internal implementation and the CommonCrypto one
    func testHMACSHA256Implementation() {
        for _ in 1...100 {
            let data = randomData(count: Int.random(in: 1...100_000))
            let kdata = randomData(count: Int.random(in: 1...1_000))
            let hmac1 = data.hmacSHA(key: kdata, hash: .sha256)
            let hmac2 = data.hmacSHAUncommon(key: kdata, hash: .sha256)
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

    /// Tests [3.2.3. Sorting of Object Properties](https://tools.ietf.org/id/draft-rundgren-json-canonicalization-scheme-05.html#json.sorting.properties)
    func testJSONCanonicalForm() throws {
        // check the JSON canonical form
        let source = """
        {
          "numbers": [333333333.33333329, 1E30, 4.50,
                      2e-3, 0.000000000000000000000000001],
          "string": "\\u20ac$\\u000F\\u000aA'\\u0042\\u0022\\u005c\\\\\\"\\/",
          "literals": [null, true, false]
        }
        """

        let expectedResult = #"{"literals":[null,true,false],"numbers":[333333333.3333333,1e+30,4.5,0.002,1e-27],"string":"€$\u000f\nA'B\"\\\\\"/"}"#

        struct ExampleObject : Codable {
            let numbers: [Double]
            let string: String
            let literals: [Bool?]
        }

        let ob = try JSONDecoder().decode(ExampleObject.self, from: source.utf8Data)
        let json = ob.canonicalJSON
        var correctedJSON = json.replacingOccurrences(of: "1.0000000000000002e-27", with: "1e-27") // rounding
        correctedJSON = correctedJSON.replacingOccurrences(of: "333333333.33333331,", with: "333333333.3333333,") // rounding

        XCTAssertEqual(expectedResult, correctedJSON)
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
}
