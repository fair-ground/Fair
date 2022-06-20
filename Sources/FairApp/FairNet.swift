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

 You should have received a copy of the GNU Affero General Public License
 along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */
import Swift
import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// A service that converts actions and parameters into an endpoint URL
public protocol EndpointService {
    /// The session that will be used to connect to a service
    var session: URLSession { get }

    /// Creates a request for the given `APIRequest`
    func buildRequest<A: APIRequest>(for request: A, cache: URLRequest.CachePolicy?) throws -> URLRequest where A.Service == Self

    /// The codes that returns an HTTP error but contains information about backing off and re-trying an operation
    static var backoffCodes: IndexSet { get }
}

/// An API request that can be either a REST GET or a POST like GraphQL.
///
/// Each request has a specific associated `Response`, which
/// can be an `Xor` when multiple response types should be expected, such as:
///
/// ```
/// typealias Response = XOr<FailureResponse>.Or<SuccessResponse>
/// ```
public protocol APIRequest {
    associatedtype Response : Pure
    associatedtype Service : EndpointService

    /// The URL for connecting to the service
    func queryURL(for service: Service) -> URL

    /// Post data if this is a `POST` request, `nil` if it is a `GET`
    func postData() throws -> Data?
}

public extension EndpointService {
    /// The default endpoint implementation uses `URLSession.shared`
    var session: URLSession { .shared }
}

extension EndpointService {
#if swift(>=5.5)
    @available(macOS 12.0, iOS 15.0, *)
    public func requestAsync<A: APIRequest>(_ request: A, cache: URLRequest.CachePolicy? = nil, retry: Bool = true) async throws -> A.Response where A.Service == Self {
        let (data, response) = try await session.data(for: buildRequest(for: request, cache: cache), delegate: nil)

        // check response headers for rate-limiting
        if let response = response as? HTTPURLResponse {
            let headers = response.allHeaderFields
            // let limitResource = headers["x-ratelimit-resource"]
            let limit = headers[AnyHashable("x-ratelimit-limit")] as? String
            let used = headers[AnyHashable("x-ratelimit-used")] as? String
            let remaining = headers[AnyHashable("x-ratelimit-remaining")] as? String
            let reset = headers[AnyHashable("x-ratelimit-reset")] as? String

            // dbg("limit:", limit, type(of: limit), "used:", used, "remaing:", remaining, "reset:", reset)

            if let limit = limit.flatMap(Int.init),
               let used = used.flatMap(Int.init),
               let remaining = remaining.flatMap(Int.init),
               let reset = reset.flatMap(TimeInterval.init) {
                let resetTime = Date(timeIntervalSince1970: reset)
                dbg("rate limit: \(used)/\(limit) (\(remaining) remaining) resets:", resetTime)
            }
        }
        return try decode(data: data)
    }
#endif
}

extension EndpointService {

    /// Decodes the given response, first checking for a `ResponseError` error
    func decode<T: Decodable>(data: Data) throws -> T {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        //dbg("decoding:", String(data: data, encoding: .utf8) ?? "") // debugging for failures

        return try decoder.decode(T.self, from: data)
    }

    public func request<A: APIRequest>(_ request: A) async throws -> A.Response where A.Service == Self {
        try await decode(data: try session.fetch(request: buildRequest(for: request, cache: nil)).data)
    }

    /// Fetches the web service for the given request, following the cursor until the `batchHandler` returns a non-`nil` response; the first response element will be returned
    public func requestBatches<T, A: CursoredAPIRequest>(_ request: A, cache: URLRequest.CachePolicy? = nil, interleaveDelay: TimeInterval? = 1.0, batchHandler: (_ requestIndex: Int, _ urlResponse: URLResponse?, _ batch: A.Response) throws -> T?) async throws -> T? where A.Service == Self {
        var request = request
        for requestIndex in 0... {
            if requestIndex > 0, let interleaveDelay = interleaveDelay {
                // rest between requests
                try await Task.sleep(nanoseconds: .init(interleaveDelay * 1_000_000_000))
            }

            let (data, urlResponse) = try await fetchBatch(buildRequest(for: request, cache: cache))
            let batch: A.Response = try decode(data: data)

            if let stopValue = try batchHandler(requestIndex, urlResponse, batch) {
                // handler found what it wants
                return stopValue
            }
            guard let cursor = batch.endCursor else {
                // no more elements
                return nil
            }
            dbg("requesting next cursor:", requestIndex) // , cursor)
            request.cursor = cursor // make another request with the new cursor
        }

        return nil
    }

    /// Fetches the given batch, optionally retrying when a failure response contains one of the retry codes.
    /// - Parameters:
    ///   - request: the request to fetch
    ///   - retryCount: the number of times we should attempt to fetch the resource
    ///
    /// - Note: the retry mechanism only works with the generic "Retry-After" header. Custom endpoint-specific
    ///         rate limit handling (like GitHub's `x-ratelimit-limit`, `x-ratelimit-limit-remaining`, `x-ratelimit-limit-reset` headers)
    ///         are not yet supported.
    private func fetchBatch(_ request: URLRequest, retryCount: Int = 10) async throws -> (Data, URLResponse?) {
        var codes = IndexSet(200..<300)
        codes.formUnion(Self.backoffCodes)
        var retryCount = max(retryCount, 1)
        var seenCodes: Set<Int> = []
        while retryCount > 0 {
            retryCount -= 1

            let (data, response) = try await session.fetch(request: request, validate: .init(codes))
            dbg("batch response:", response)
            dbg("batch data:", data.utf8String)

            // rate limit exceeded will have a 403 error, a RetryDuration header, and a payload like:
            // { "documentation_url": "https://docs.github.com/en/free-pro-team@latest/rest/overview/resources-in-the-rest-api#secondary-rate-limits", "message": "You have exceeded a secondary rate limit. Please wait a few minutes before you try again." }

            // from https://docs.github.com/en/rest/guides/best-practices-for-integrators#dealing-with-secondary-rate-limits: “When you have been limited, use the Retry-After response header to slow down. The value of the Retry-After header will always be an integer, representing the number of seconds you should wait before making requests again. For example, Retry-After: 30 means you should wait 30 seconds before sending more requests.”
            if let response = response as? HTTPURLResponse,
               Self.backoffCodes.contains(response.statusCode),
               let retryAfter = response.value(forHTTPHeaderField: "Retry-After"),
               let retryAfterSeconds = Double(retryAfter) {
                seenCodes.insert(response.statusCode)
                dbg("backing off for \(retryAfterSeconds) seconds and re-trying \(retryCount) more times…")
                try await Task.sleep(nanoseconds: .init(retryAfterSeconds * 1_000_000_000))
            } else {
                return (data, response)
            }
        }

        throw AppError("Resource at returned code: \(seenCodes.sorted())")
    }

    /// Fetches the web service for the given request, returning an `AsyncThrowingStream` that yields batches until they are no longer available or they have passed the max batch limit.
    public func requestBatchStream<A: CursoredAPIRequest>(_ request: A, maxBatches: Int, cache: URLRequest.CachePolicy? = nil, interleaveDelay: TimeInterval? = 1.0) -> AsyncThrowingStream<A.Response, Error> where A.Service == Self {
        return AsyncThrowingStream { c in
            Task {
                do {
                    var count = 0
                    let _: Void? = try await self.requestBatches(request, cache: cache, interleaveDelay: interleaveDelay) { resultIndex, urlResponse, batch in
                        c.yield(batch)
                        count += 1
                        return count < maxBatches ? nil : () // keep going until we have all the batches
                    }
                    c.finish()
                } catch {
                    c.finish(throwing: error)
                }
            }
        }
    }
}

/// A cursor that represents a pointer to a page in a set of GraphQL results.
/// It is an opaque (base-64 encoded) string.
public struct GraphQLCursor : RawRepresentable, Pure {
    public let rawValue: String
    public init(rawValue: String) {
        self.rawValue = rawValue
    }
}

/// A response that returns results in batches with a cursor
public protocol CursoredAPIResponse {
    var endCursor: GraphQLCursor? { get }
    /// The number of elements in this response batch
    var elementCount: Int { get }
}

/// In the common case of a result type that is in `XOr<Error>.Or<Result>`, use the success value as the success
extension XOr.Or : CursoredAPIResponse where P : Error, Q : CursoredAPIResponse {
    public var elementCount: Int {
        result.successValue?.elementCount ?? 0
    }

    /// Passes the cursor check through to the success value
    public var endCursor: GraphQLCursor? {
        result.successValue?.endCursor
    }
}

/// A response from an API that incudes the ability to move through pages.
public protocol CursoredAPIRequest : APIRequest where Response : CursoredAPIResponse {
    /// The cursor for the request
    var cursor: GraphQLCursor? { get set }
}

public extension URLResponse {
    func validateHTTPCode(inRange: Range<Int> = 200..<300) throws {
        guard let httpResponse = self as? HTTPURLResponse else {
            throw AppError("URL response was not HTTP for \(self.url?.absoluteString ?? "")")
        }

        if !inRange.contains(httpResponse.statusCode) {
            throw AppError("Bad HTTP response \(httpResponse.statusCode) for \(self.url?.absoluteString ?? "")")
        }
    }
}

public extension URLRequest {
    #if swift(>=5.5)
    /// Downloads the URL and verifies the HTTP success code and, optionally, the validity of the
    /// SHA-256 hash included as the URL's fragment.
    ///
    /// - Parameters:
    ///   - session: the URLSession to use, defaulting to `URLSession.shared`
    ///   - validateFragmentHash: if `true`, validate that the contents of the data match a SHA256 hash in the URL
    /// - Returns: the `Data` if it downloaded and validated
    func fetch(session: URLSession = .shared, validateFragmentHash: Bool = false) async throws -> Data {
        let (data, response) = try await session.fetch(request: self)
        try response?.validateHTTPCode() // ensure the code in within the expected range

        #if canImport(CommonCrypto)
        if validateFragmentHash == true,
            let fragmentHash = self.url?.fragment {
            let dataHash = data.sha256().hex()
            if dataHash != fragmentHash {
                throw AppError("Hash mismatch for \(self.url?.absoluteString ?? ""): \(fragmentHash) vs. \(dataHash)")
            }
        }
        #endif

        return data
    }
    #endif
}

extension URLResponse {
    public struct InvalidHTTPCode : Error {
        public let code: Int
        //public let response: HTTPURLResponse
    }

    /// Attempts to validate the status code in the given range and throws an error if they fail.
    func validating(codes: IndexSet?) throws -> Self {
        guard let codes = codes else {
            return self // no validation
        }

        guard let httpResponse = self as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }

        if !codes.contains(httpResponse.statusCode) {
            throw InvalidHTTPCode(code: httpResponse.statusCode)
        }

        return self // the response is valid
    }
}

extension URLSession {
    /// Fetches the given request asynchronously, optionally validating that the response code is within the given range of HTTP codes.
    public func fetch(request: URLRequest, validate codes: IndexSet? = IndexSet(200..<300)) async throws -> (data: Data, response: URLResponse?) {
        if let url = request.url, url.isFileURL == true {
            return (data: try Data(contentsOf: url), response: nil)
        } else {
            return try await fetchTask(request: request, validate: codes)
        }
    }

    /// A shim for async URL download for back-ported async/await without corresponding URLSession API support
    private func fetchTask(request: URLRequest, validate codes: IndexSet?) async throws -> (data: Data, response: URLResponse) {
        return try await withCheckedThrowingContinuation { continuation in
            dataTask(with: request) { data, response, error in
                if let data = data, let response = response, error == nil {
                    do {
                        let validResponse = try response.validating(codes: codes)
                        continuation.resume(returning: (data, validResponse))
                    } catch {
                        continuation.resume(throwing: error)
                    }
                } else {
                    continuation.resume(throwing: error ?? CocoaError(.fileNoSuchFile))
                }
            }.resume()
        }

    }
}

// TODO: @available(*, deprecated, message: "migrate to async")
public extension URLSession {
    #if os(Linux) || os(Windows)
    /// Stub for missing async data support on Linux & Windows
    func data(for request: URLRequest, delegate: Void?) async throws -> (data: Data, response: URLResponse) {
        let (data, response) = try await fetch(request: request)
        return (data, response ?? URLResponse(url: request.url ?? URL(string: "about:blank")!, mimeType: nil, expectedContentLength: 0, textEncodingName: nil))
    }
    #endif

    /// Downloads the given URL request in the current session
    func downloadSync(_ request: URLRequest, timeout: DispatchTime = .distantFuture) throws -> (url: URL, response: URLResponse) {
        try sync(request: request, timeout: timeout) { request, handler in
            downloadTaskCopy(with: request, completionHandler: handler)
        }
    }

    /// Initiates the given task (either `dataTask` or `downloadTask`) and waits for completion.
    /// Swift 5.5 applications should avoid using this in favor of the async/await versions of the API.
    private func sync<T>(request: URLRequest, timeout: DispatchTime, createTask: (_ with: URLRequest, _ completionHandler: @escaping (T?, URLResponse?, Error?) -> ()) -> URLSessionTask) throws -> (T, response: URLResponse) {

        let done = DispatchSemaphore(value: 0)
        var data: T?
        var response: URLResponse?
        var error: Error?
        createTask(request) {
            (data, response, error) = ($0, $1, $2)
            done.signal()
        }.resume()
        switch done.wait(timeout: timeout) {
        case .success:
            if let error = error {
                throw error
            } else if let response = response, let data = data {
                return (data, response)
            } else {
                throw URLError(.unknown)
            }
        case .timedOut:
            throw URLError(.timedOut)
        }
    }
}

extension URLResponse {
    private static let gmtDateFormatter: DateFormatter = {
        let fmt = DateFormatter()
        fmt.dateFormat = "EEEE, dd LLL yyyy HH:mm:ss zzz"
        return fmt
    }()

    /// Returns the last modified date for this response
    public var lastModifiedDate: Date? {
        guard let headers = (self as? HTTPURLResponse)?.allHeaderFields else {
            return nil
        }
        guard let modDate = headers["Last-Modified"] as? String else {
            return nil
        }
        return Self.gmtDateFormatter.date(from: modDate)
    }
}

#if swift(>=5.5)
extension URLSession {
    /// Issues a `HEAD` request for the given URL and returns the response
    public func fetchHEAD(url: URL, cachePolicy: URLRequest.CachePolicy) async throws -> URLResponse? {
        var request = URLRequest(url: url, cachePolicy: cachePolicy)
        request.httpMethod = "HEAD"
        let (_, response) = try await fetch(request: request)
        return response
    }

    /// the number of progress segments for the download part; the remainder will be the zip decompression
    public static let progressUnitCount: Int64 = 4

    #if !os(Linux) && !os(Windows) // bytes not available
    /// Downloads the given request to a cached file location.
    ///
    /// - Parameters:
    ///   - request: the request containing the URL to download
    ///   - memoryBufferSize: the buffer size
    ///   - consumer: a consumer for the data, such as  to update a hashing function
    ///   - parentProgress: the progress to attach to
    ///
    /// - Returns: the downloaded file URL along with the request's response
    ///
    /// Note: this operation downloads directly into memory instead of the potentially-more-efficient download task.
    /// We would like to use a download task to save directly to a file and have progress callbacks go through DownloadDelegate, but it is not working with async/await (see https://stackoverflow.com/questions/68276940/how-to-get-the-download-progress-with-the-new-try-await-urlsession-shared-downlo)
    /// However, an advantage of using streaming bytes is that we can maintain a running sha256 hash for the download without have to load the whole data chunk into memory after the download has completed
    @available(macOS 12.0, iOS 15.0, *)
    public func download(request: URLRequest, memoryBufferSize: Int = 1024 * 64, consumer: DataConsumer? = nil, parentProgress: Progress? = nil, responseVerifier: (URLResponse) throws -> Bool = { (200..<300).contains(($0 as? HTTPURLResponse)?.statusCode ?? 200) }) async throws -> (URL, URLResponse) {
        let downloadedArtifact: URL
        let (asyncBytes, response) = try await self.bytes(for: request)
        if try responseVerifier(response) == false {
            throw CocoaError(.fileNoSuchFile)
        }
        let length = response.expectedContentLength
        let progress1 = Progress(totalUnitCount: length)
        parentProgress?.addChild(progress1, withPendingUnitCount: Self.progressUnitCount - 1)

        try Task.checkCancellation()

        // create a temporary zip file in the caches directory from which we will extract the data
        downloadedArtifact = try FileManager.default.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            .appendingPathComponent(UUID().uuidString)
            .appendingPathComponent(request.url?.lastPathComponent ?? "download")

        dbg("downloading to temporary path:", downloadedArtifact.path)

        // ensure parent path exists
        try FileManager.default.createDirectory(at: downloadedArtifact.deletingLastPathComponent(), withIntermediateDirectories: true, attributes: nil)

        try Task.checkCancellation()

        // the file must exist before we can open the file handle
        FileManager.default.createFile(atPath: downloadedArtifact.path, contents: nil, attributes: nil)

        let fh = try FileHandle(forWritingTo: downloadedArtifact)

        var success = false

        defer {
            // if any errors occur, close the delete the temporary artifact;
            // this is expected to fail unless we have successfully moved the file
            if success == false {
                do {
                    try fh.close()
                    try FileManager.default.removeItem(at: downloadedArtifact)
                } catch {
                    dbg("error when cleaning up failed download:", error)
                }
            }
        }

        var bytes = Data()
        bytes.reserveCapacity(memoryBufferSize)

        func flushBuffer(_ bytesCount: Int64) async throws {
            try Task.checkCancellation()

            try fh.write(contentsOf: bytes) // write out the buffer
            await consumer?.update(data: bytes) // update the running hash
            bytes.removeAll(keepingCapacity: true) // clear the buffer

            if let parentProgress = parentProgress {
                if parentProgress.isCancelled == true {
                    throw CocoaError(.userCancelled)
                }
                progress1.completedUnitCount = bytesCount
            }
        }

        var bytesCount: Int64 = 0
        for try await byte in asyncBytes {
            bytesCount += 1
            bytes.append(byte)
            if bytes.count == memoryBufferSize {
                try await flushBuffer(bytesCount)
            }
        }
        if !bytes.isEmpty {
            try await flushBuffer(bytesCount)
        }

        success = true // prevent the cleanup
        try fh.close()
        return (downloadedArtifact, response)
    }
    #endif // !os(Linux) && !os(Windows) 

    /// Downloads the given file. It should behave the same as the async URLSession.download function (which is missing from linux).
    public func downloadFile(for request: URLRequest) async throws -> (URL, URLResponse) {
        return try await withCheckedThrowingContinuation { continuation in
            downloadTaskCopy(with: request) { url, response, error in
                if let url = url, let response = response, error == nil {
                    continuation.resume(returning: (url, response))
                } else {
                    continuation.resume(throwing: error ?? URLError(.badServerResponse))
                }
            }
            .resume()
        }
    }

    /// If the download from `downloadTask` is successful, the completion handler receives a URL indicating the location of the downloaded file on the local filesystem. This storage is temporary. To preserve the file, this will move it from the temporary location before returning from the completion handler.
    /// In practice, macOS seems to be inconsistent in when it ever cleans up these files, so a failure here will manifest itself in occasional missing files.
    /// This is needed for running an async operation that will still have access to the resulting file.
    /// - Parameters:
    ///   - request: the request for the download
    ///   - useContentDispositionFileName: whether to attempt to rename the file based on the file name specified in the `Content-Disposition` header, if present.
    ///   - completionHandler: the handler to invoke when the download is complete
    /// - Returns: the task that was initiated
    func downloadTaskCopy(with request: URLRequest, useContentDispositionFileName: Bool = true, completionHandler: @escaping (URL?, URLResponse?, Error?) -> Void) -> URLSessionDownloadTask {
        self.downloadTask(with: request) { url, response, error in
            /// Files are generally placed somewhere like: file:///var/folders/24/8k48jl6d249_n_qfxwsl6xvm0000gn/T/CFNetworkDownload_q0k6gM.tmp
            do {
                /// We'll copy it to a temporary replacement directory with the base name matching the URL's name
                if let temporaryLocalURL = url,
                   temporaryLocalURL.isFileURL {
                    var pathName = temporaryLocalURL.lastPathComponent

                    if useContentDispositionFileName == true,
                       let disposition = (response as? HTTPURLResponse)?.allHeaderFields["Content-Disposition"] as? String,
                       disposition.hasPrefix("attachment; filename="),
                       let contentDispositionFileName = disposition.components(separatedBy: "filename=").last,
                       contentDispositionFileName.unicodeScalars.filter(CharacterSet.urlPathAllowed.inverted.contains).isEmpty,
                       contentDispositionFileName.contains("/") == false {
                        pathName = contentDispositionFileName
                    }

                   let tempDir = try FileManager.default.url(for: .itemReplacementDirectory, in: .userDomainMask, appropriateFor: temporaryLocalURL, create: true)
                    let destinationURL = tempDir.appendingPathComponent(pathName)
                    try FileManager.default.moveItem(at: temporaryLocalURL, to: destinationURL)
                    dbg("replace download file for:", response?.url, "local:", temporaryLocalURL.path, "moved:", destinationURL.path, destinationURL.pathSize?.localizedByteCount())
                    return completionHandler(destinationURL, response, error)
                }
            } catch {
                dbg("ignoring file move error and falling back to un-copied file:", error)
            }

            // fall-back to the completion handler
            return completionHandler(url, response, error)
        }
    }
}
#endif // swift(>=5.5)
