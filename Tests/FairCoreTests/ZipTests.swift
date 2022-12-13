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

final class ZipTests: XCTestCase {
    func testDeflate() throws {
        let data = "blob 16\u{0000}what is up, doc?".utf8Data
        do {
            let deflated = try data.deflate(level: -1, checksum: false, wrap: false).data
            XCTAssertEqual("4bcac94f5230346328cf482c51c82c56282dd05148c94fb60700", deflated.hex())
            let deflated0 = try data.deflate(level: 0, checksum: false, wrap: false).data
            XCTAssertEqual("011800e7ff626c6f6220313600776861742069732075702c20646f633f", deflated0.hex())
            for level in 1...9 {
                let deflatedx = try data.deflate(level: level, checksum: false, wrap: false).data
                XCTAssertEqual("4bcac94f5230346328cf482c51c82c56282dd05148c94fb60700", deflatedx.hex())
            }
        }

        do {
            let pad = " xxx ".utf8Data
            let data2 = data + pad + data + pad + pad + data + pad + pad + pad + data + data + data + data

            let deflated = try data2.deflate(level: -1, checksum: false, wrap: false).data
            XCTAssertEqual("4bcac94f5230346328cf482c51c82c56282dd05148c94fb657a8a8a85048c22749a40abccaa8250e00", deflated.hex())

            let deflated0 = try data2.deflate(level: 0, checksum: false, wrap: false).data
            XCTAssertEqual("01c60039ff626c6f6220313600776861742069732075702c20646f633f2078787820626c6f6220313600776861742069732075702c20646f633f20787878202078787820626c6f6220313600776861742069732075702c20646f633f207878782020787878202078787820626c6f6220313600776861742069732075702c20646f633f626c6f6220313600776861742069732075702c20646f633f626c6f6220313600776861742069732075702c20646f633f626c6f6220313600776861742069732075702c20646f633f", deflated0.hex())

            for level in 1...3 {
                let deflatedx = try data2.deflate(level: level, checksum: false, wrap: false).data
                XCTAssertEqual("4bcac94f5230346328cf482c51c82c56282dd05148c94fb657a8a8a85048c22749a40abcca705940aa3800", deflatedx.hex())
            }

            for level in 4...9 {
                let deflatedx = try data2.deflate(level: level, checksum: false, wrap: false).data
                XCTAssertEqual("4bcac94f5230346328cf482c51c82c56282dd05148c94fb657a8a8a85048c22749a40abccaa8250e00", deflatedx.hex())
            }
        }
    }

    func testZipFiles() async throws {
        for url in [
            URL(fileOrScheme: "~/Documents/Books/epub"),
            URL(fileURLWithPath: "/opt/src/github/apache/tika"),
        ] {
            if url.pathIsDirectory == false {
                dbg("skipping missing folder:", url.path)
                continue
            }
            for try await result in FileManager.default.enumeratorAsync(at: url) {
                let url = try result.get()
                dbg("url:", url.path)
                if ["zip", "epub"].contains(url.pathExtension) {
                    try await checkZip(url: url)
                }
            }
        }
    }

    func checkZip(url: URL) async throws {
        dbg("checking:", url.path)
        let archive = try ZipArchiveDataWrapper(archive: ZipArchive(url: url, accessMode: .read))
        for path in archive.paths {
            dbg(" - ", path.pathName)
        }
    }

    func testCompression() throws {
        let compress = {
            try ($0 as Data).zipZlib(level: $1, checksum: true).data.hex()
        }

        let simple1 = "abcabcabcabcabcabcabcabcabcabcabc"
        XCTAssertEqual("012100deff616263616263616263616263616263616263616263616263616263616263616263", try compress(simple1.utf8Data, 0))
        XCTAssertEqual("4b4c4a4ec48b00", try compress(simple1.utf8Data, 1))
        XCTAssertEqual("4b4c4a4ec48b00", try compress(simple1.utf8Data, 5))
        XCTAssertEqual("4b4c4a4ec48b00", try compress(simple1.utf8Data, 9))

        #if canImport(XXXCompression)
        XCTAssertEqual("4b4c4a4ec48b00", try simple1.utf8Data.zipCompression(checksum: true).data.hex())
        #endif

        let simple2 = "01234567890"

        let complex = simple1 + simple2 + simple2 + simple2 + simple1 + simple2
        let complexRaw = complex.utf8Data.hex() // the uncompressed data
        XCTAssertEqual("016e0091ff" + complexRaw, try compress(complex.utf8Data, 0))

        XCTAssertEqual("4b4c4a4ec48b0c0c8d8c4d4ccdcc2d2c0db033f16b07ca22690300", try compress(complex.utf8Data, 1))
        XCTAssertEqual("4b4c4a4ec48b0c0c8d8c4d4ccdcc2d2c0db033f16b07ca22690300", try compress(complex.utf8Data, 2))
        XCTAssertEqual("4b4c4a4ec48b0c0c8d8c4d4ccdcc2d2c0db033f16b07ca22690300", try compress(complex.utf8Data, 3))

        XCTAssertEqual("4b4c4a4ec48b0c0c8d8c4d4ccdcc2d2c0db03331b5e0360100", try compress(complex.utf8Data, 4))

        XCTAssertEqual("4b4c4a4ec48b0c0c8d8c4d4ccdcc2d2c0db033f16b47350100", try compress(complex.utf8Data, -1))
        XCTAssertEqual("4b4c4a4ec48b0c0c8d8c4d4ccdcc2d2c0db033f16b47350100", try compress(complex.utf8Data, 5))
        XCTAssertEqual("4b4c4a4ec48b0c0c8d8c4d4ccdcc2d2c0db033f16b47350100", try compress(complex.utf8Data, 6))

        XCTAssertEqual("4b4c4a4ec48b0c0c8d8c4d4ccdcc2d2c0db0331349300100", try compress(complex.utf8Data, 7))
        XCTAssertEqual("4b4c4a4ec48b0c0c8d8c4d4ccdcc2d2c0db0331349300100", try compress(complex.utf8Data, 8))
        XCTAssertEqual("4b4c4a4ec48b0c0c8d8c4d4ccdcc2d2c0db0331349300100", try compress(complex.utf8Data, 9))

        #if canImport(XXXCompression)
        // Compression is equivalent to level 5 zlib compression (but sometimes differs slightly)
        XCTAssertEqual("4b4c4a4ec48b0c0c8d8c4d4ccdcc2d2c0db033f16b47350100", try complex.utf8Data.zipCompression(checksum: true).data.hex())
        #endif

    }

    func testCreateArchive() throws {
        let zip = try XCTUnwrap(ZipArchive(data: Data(), accessMode: .create, preferredEncoding: .utf8))
        let _ = zip // TODO: add support for adding in-memory files
    }

    #if canImport(CZlib)
    #if canImport(Compression)
    func testArchiveCompression() throws {
//        var rng = SeededRandomNumberGenerator(seed: [0])
        var rng = SystemRandomNumberGenerator()

        let sizes = (1...10).map({ _ in Int.random(in: 1...1_000_000, using: &rng) })

        for size in sizes {
            dbg("testing size:", size)
            let randomData = Data((1...size).map({ _ in UInt8.random(in: (.min)...(.max), using: &rng) }))
            let data = randomData

            // compare compression between the two implementations

            #if canImport(XXXCompression)
            let zip1 = try data.zipCompression(checksum: true).data
            #else
            let zip1 = try data.zipZlib(level: 5, checksum: true).data
            #endif
            let unzip1 = try zip1.unzipZlib(checksum: true).data

            let zip2 = try data.zipZlib(level: 5, checksum: true).data
            #if canImport(XXXCompression)
            let unzip2 = try zip2.unzipCompression(checksum: true).data
            #else
            let unzip2 = try zip2.unzipZlib(checksum: true).data
            #endif

            // XCTAssertEqual(zip1, zip2) // sadly, even with specifying compression level, the zipped artifacts of the two types are not the same

            //XCTAssertEqual(unzip1.hex(), unzip2.hex())
            XCTAssertEqual(unzip1, data)
            XCTAssertEqual(unzip2, data)
        }
    }
    #endif
    #endif
}
