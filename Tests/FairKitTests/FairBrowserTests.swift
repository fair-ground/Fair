import Swift
import XCTest
import FairKit

#if canImport(WebKit)
open class FairBrowserTests: XCTestCase {
    let wv = WebDriver()

    @available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 8.0, *)
    open func testWebState() async throws {
        func titleTest(inlineTitle: String = UUID().uuidString) async throws {
            _ = try await wv.load(request: URLRequest(url: URL(string: "data:text/html," + "<html><head><title>\(inlineTitle)</title></head><body></body></html>".escapedURLTerm)!))
            let title = try await wv.webView.evalJS("document.title")
            XCTAssertEqual(inlineTitle as NSString, title as? NSString)
        }

        do {
            _ = try await wv.load(request: URLRequest(url: URL(string: "https://www.example.org")!))
            let title = try await wv.webView.evalJS("document.title")
            XCTAssertEqual("Example Domain", title as? NSString)
        }

        for _ in 1...10 {
            try await titleTest()
        }

        do {
            _ = try await wv.load(request: URLRequest(url: URL(string: "https://www.example.com")!))
            let title = try await wv.webView.evalJS("document.title")
            XCTAssertEqual("Example Domain", title as? NSString)
        }

        for _ in 1...10 {
            try await titleTest()
        }

//        do {
//            try await wv.load(request: URLRequest(url: URL(string: "https://www.economist.com")!))
//            let title = try await wv.webView.evalJS("document.title")
//            XCTAssertEqual("The Economist - World News, Politics, Economics, Business & Finance", title as? NSString)
//        }

        // TODO: error handling in navigation delegate; will require delaying before the observer callback
//        do {
//            try await wv.load(request: URLRequest(url: URL(string: "https://efwnfnefwknfkwjn.erj")!))
//            let title = try await wv.webView.evalJS("document.title")
//            XCTAssertEqual("Page not found · GitHub · GitHub", title as? NSString)
//        }

        for _ in 1...10 {
            try await titleTest()
        }

        do {
            _ = try await wv.load(request: URLRequest(url: URL(string: "https://www.example.edu")!))
            let title = try await wv.webView.evalJS("document.title")
            XCTAssertEqual("Example Domain", title as? NSString)
        }

        for _ in 1...10 {
            try await titleTest()
        }

        do {
            _ = try await wv.load(request: URLRequest(url: URL(string: "https://www.webkit.org")!))
            let title = try await wv.webView.evalJS("document.title")
            XCTAssertEqual("WebKit", title as? NSString)
        }

        do {
            _ = try await wv.load(request: URLRequest(url: URL(string: "https://www.example.net")!))
            let title = try await wv.webView.evalJS("document.title")
            XCTAssertEqual("Example Domain", title as? NSString)
        }
    }
}
#endif

