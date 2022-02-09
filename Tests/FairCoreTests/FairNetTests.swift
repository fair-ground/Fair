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

final class FairNetTests: XCTestCase {
    @available(macOS 12.0, iOS 15.0, *)
    func testFairDownload() async throws {
        try await testDownload(sliceable: true)
    }

    @available(macOS 12.0, iOS 15.0, *)
    func testSliceableDownload() async throws {
        try await testDownload(sliceable: true, range: 100...999)
    }

    @available(macOS 12.0, iOS 15.0, *)
    func testSystemDownload() async throws {
        try await testDownload(sliceable: false)
    }

    @available(macOS 12.0, iOS 15.0, *)
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
        let response: URLResponse

        if sliceable == true {
            (loadURL, response) = try await URLSession.shared.download(request: req, memoryBufferSize: 1024, consumer: nil, parentProgress: progress, responseVerifier: { response in
                dbg("received response:", response)
                return true
            })

        } else {
            (loadURL, response) = try await URLSession.shared.download(for: req, delegate: nil)
        }

        if let range = range {
            XCTAssertEqual(range.count, loadURL.fileSize())
        } else {
            XCTAssertEqual(105776347, loadURL.fileSize())
        }
        XCTAssertEqual(range == nil ? 200 : 206, (response as? HTTPURLResponse)?.statusCode)
    }
}
