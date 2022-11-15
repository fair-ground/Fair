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
import FairApp

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
    associatedtype Response : Decodable
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
        //dbg(wip("### decoding response:"), try! JSum(json: data).prettyJSON) // debugging for failures

        return try decoder.decode(T.self, from: data)
    }

    public func request<A: APIRequest>(_ request: A) async throws -> A.Response where A.Service == Self {
        try await decode(data: try session.fetch(request: buildRequest(for: request, cache: nil)).data)
    }

    /// Fetches the web service for the given request, following the cursor until the `batchHandler` returns a non-`nil` response; the first response element will be returned
    @discardableResult public func requestBatches<T, A: CursoredAPIRequest>(_ request: A, cache: URLRequest.CachePolicy? = nil, interleaveDelay: TimeInterval? = 1.5, batchHandler: (_ requestIndex: Int, _ urlResponse: URLResponse?, _ batch: A.Response) throws -> T?) async throws -> T? where A.Service == Self {
        var request = request
        for requestIndex in 0... {
            if requestIndex > 0, let interleaveDelay = interleaveDelay {
                // rest between requests
                try await Task.sleep(interval: interleaveDelay)
            }

            let (data, urlResponse) = try await fetchBatch(buildRequest(for: request, cache: cache))
            let batch: A.Response = try decode(data: data)

            if let stopValue = try batchHandler(requestIndex, urlResponse, batch) {
                // handler found what it wants
                return stopValue
            }
            guard batch.hasNextPage, let endCursor = batch.endCursor else {
                // no more elements
                return nil
            }

            dbg("requesting next cursor:", requestIndex, endCursor)
            request.endCursor = endCursor // make another request with the new cursor
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
        var seenCodes: [Int] = []

        // perform any re-tryable attempts
        while retryCount > 0 {
            retryCount -= 1

            let (data, response) = try await session.fetch(request: request, validate: IndexSet(codes))
            dbg("batch response:", response)
            //dbg("batch data:", data.utf8String)

            // rate limit exceeded will have a 403 error, a RetryDuration header, and a payload like:
            // { "documentation_url": "https://docs.github.com/en/free-pro-team@latest/rest/overview/resources-in-the-rest-api#secondary-rate-limits", "message": "You have exceeded a secondary rate limit. Please wait a few minutes before you try again." }

            // from https://docs.github.com/en/rest/guides/best-practices-for-integrators#dealing-with-secondary-rate-limits: “When you have been limited, use the Retry-After response header to slow down. The value of the Retry-After header will always be an integer, representing the number of seconds you should wait before making requests again. For example, Retry-After: 30 means you should wait 30 seconds before sending more requests.”
            if let response = response as? HTTPURLResponse,
               Self.backoffCodes.contains(response.statusCode),
               let retryAfter = response.value(forHTTPHeaderField: "Retry-After"),
               let retryAfterSeconds = Double(retryAfter) {
                seenCodes.append(response.statusCode)
                dbg("backing off for \(retryAfterSeconds) seconds and re-trying \(retryCount) more times due to response status \(response.statusCode)")
                try await Task.sleep(interval: retryAfterSeconds)
            } else {
                return (data, response)
            }
        }

        codes.subtract(Self.backoffCodes) // remove the backoff codes and just throw any failures
        return try await session.fetch(request: request, validate: IndexSet(codes))
    }

    /// Fetches the web service for the given request, returning an `AsyncThrowingStream` that yields batches until they are no longer available or they have passed the max batch limit.
    ///
    /// Note that this function does not initiate any requests itself; rather, the `AsyncThrowingStream` will issue a request for each element individually as it is iterated.
    public func cursoredStream<A: CursoredAPIRequest>(_ request: A, cache: URLRequest.CachePolicy? = nil, interleaveDelay: TimeInterval? = 1.5) -> AsyncThrowingStream<A.Response, Error> where A.Service == Self {
        return AsyncThrowingStream { c in
            Task {
                do {
                    let _: Never? = try await self.requestBatches(request, cache: cache, interleaveDelay: interleaveDelay) { resultIndex, urlResponse, batch in
                        c.yield(batch)
                        return nil
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
public struct GraphQLCursor : RawRepresentable, Decodable {
    public let rawValue: String
    public init(rawValue: String) {
        self.rawValue = rawValue
    }
}

/// A response that returns results in batches with a cursor
public protocol CursoredAPIResponse {
    /// Whether there are more pages to fetch or not
    var hasNextPage: Bool { get }
    /// The cursor to use to continue pagination
    var endCursor: GraphQLCursor? { get }
    /// The number of elements in this response batch
    var elementCount: Int { get }
}

/// In the common case of a result type that is in `XOr<Error>.Or<Result>`, use the success value as the success
extension XOr.Or : CursoredAPIResponse where P : Error, Q : CursoredAPIResponse {
    public var elementCount: Int {
        result.successValue?.elementCount ?? 0
    }

    public var hasNextPage: Bool {
        result.successValue?.hasNextPage == true
    }

    /// Passes the cursor check through to the success value
    public var endCursor: GraphQLCursor? {
        result.successValue?.endCursor
    }
}

/// A response from an API that incudes the ability to move through pages.
public protocol CursoredAPIRequest : APIRequest where Response : CursoredAPIResponse {
    /// The optional `endCursor` for the paginated request.
    ///
    /// This property matches the ability of `gh api graphql --paginate` to
    /// automatically traverse multiple pages as long as there is a `endCursor` variable.
    var endCursor: GraphQLCursor? { get set }
}


/// The payload of a successful `GraphQL` query.
public struct GraphQLPayload<T : Decodable> : Decodable {
    public var data: T
}

/// Pass-through cursor support.
extension GraphQLPayload : CursoredAPIResponse where T : CursoredAPIResponse {
    public var hasNextPage: Bool {
        data.hasNextPage
    }

    public var endCursor: GraphQLCursor? {
        data.endCursor
    }

    public var elementCount: Int {
        data.elementCount
    }
}

// MARK: GraphQL Request & Response


public struct GraphQLError : Decodable, LocalizedError {
    public var message: String // e.g., "Could not resolve to a Repository with the name '/App'."
    public var type: String? // e.g., "NOT_FOUND", "INSUFFICIENT_SCOPES"
    public var path: [String]? // e.g., ["repository"] or ["query FindPullRequests","repository","pullRequests","states"]
    public var documentation_url: URL?

    public var failureReason: String? { message }
}

/// A set of one or more errors returned by the GraphQL API.
public struct GraphQLErrorList : Decodable, Error {
    public var errors: [GraphQLError]
}

/// Either a single error or a list of errors

public struct GraphQLRequestFailure : Error, RawDecodable {
    public typealias ErrorTypes = XOr<GraphQLError>.Or<GraphQLErrorList>
    public let rawValue: ErrorTypes
    public init(rawValue: ErrorTypes) {
        self.rawValue = rawValue
    }

    public init(from decoder: Decoder) throws {
        try self.init(rawValue: RawValue(from: decoder))
    }
}

extension GraphQLRequestFailure : LocalizedError {
    public var failureReason: String? {
        firstFailureReason
    }

    /// The first error message for the failure
    public var firstFailureReason: String? {
        rawValue.infer()?.failureReason ?? rawValue.infer()?.errors.first?.message
    }

    /// Returns `true` if the error is due to a rate limitation
    public var isRateLimitError: Bool {
        // TODO: check for error code rather than message
        self.firstFailureReason == "You have exceeded a secondary rate limit. Please wait a few minutes before you try again."
    }
}

public extension GraphQLEndpointService {
    /// A failure can be either a single error (typically for syntax errors), or a list of errors (typically for structural issues)

    /// A response can contain either a successful value or an error instance
    typealias GraphQLResponse<T: Decodable> = XResult<GraphQLPayload<T>, GraphQLRequestFailure>

    func buildRequest<A: APIRequest>(for request: A, cache: URLRequest.CachePolicy? = nil) throws -> URLRequest where A.Service == Self {
        let url = request.queryURL(for: self)
        var req = URLRequest(url: url)

        req.allHTTPHeaderFields = requestHeaders

        let postData = try request.postData()
        if let postData = postData {
            req.httpMethod = "POST"
            req.httpBody = postData
        }

        if let cache = cache {
            req.cachePolicy = cache
        }

        // un-comment to view raw GraphQL for running in https://docs.github.com/en/graphql/overview/explorer
        //dbg(wip("### POSTING to \(url.absoluteString):"), (postData?.utf8String ?? "").replacingOccurrences(of: "\\n", with: "\n").replacingOccurrences(of: "\\", with: "")) // for debugging post data

        dbg("\(A.self) request:", req, req.httpMethod ?? "GET", url.absoluteString, postData?.utf8String?.count.localizedByteCount()) // , (postData?.utf8String ?? "").replacingOccurrences(of: "\\n", with: "\n").replacingOccurrences(of: "\\\"", with: "\""))
        return req
    }
}


