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

final class FairNetTests: XCTestCase {
    func testFairDownload() async throws {
        try await testDownload(sliceable: true)
    }

    func testSliceableDownload() async throws {
        try await testDownload(sliceable: true, range: 100...999)
    }

    func testSystemDownload() async throws {
        try await testDownload(sliceable: false)
    }

    private func testDownload(sliceable: Bool, range: ClosedRange<Int>? = nil) async throws {
        if ({ true }()) { throw XCTSkip("used for local testing") }
        
        let url = URL(string: "http://localhost:8080/movie101MB.mov")!
        var req = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalAndRemoteCacheData, timeoutInterval: 60.0)
        var headers = req.allHTTPHeaderFields ?? [:]
        if let start = range?.lowerBound, let end = range?.upperBound, end > start {
            headers["Range"] = "bytes=\(start)-\(end)"
        }
        req.allHTTPHeaderFields = headers

        let progress = Progress(totalUnitCount: 100)

        let loadURL: URL
        var response: URLResponse?

        if sliceable == true {
            (loadURL, response) = try await req.download(consumer: nil, parentProgress: progress, responseVerifier: { response in
                dbg("received response:", response)
                return true
            })

        } else {
            (loadURL, response) = try await req.download()
        }

        if let range = range {
            XCTAssertEqual(range.count, loadURL.fileSize())
        } else {
            XCTAssertEqual(105776347, loadURL.fileSize())
        }
        XCTAssertEqual(range == nil ? 200 : 206, (response as? HTTPURLResponse)?.statusCode)
    }
}
