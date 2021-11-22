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

#if canImport(SwiftUI)
#if canImport(WebKit)
import WebKit


@available(macOS 11, iOS 14, *)
public struct FairBrowser : View {
    @Binding var url: URL
    @StateObject var web = WebController()

    public init(url: Binding<URL>) {
        self._url = url
    }

    var urlString: Binding<String> {
        Binding {
            self.url.absoluteString
        } set: { newValue in
            self.url = URL(string: newValue) ?? self.url
        }
    }

    public var body: some View {
        UXWebView(webView: web.webView)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    TextField("URL", text: urlString)
                        //.keyboardShortcut("L") // it would be nice to focus on the URL bar
                        .frame(maxWidth: .infinity)
                }

                ToolbarItemGroup(placement: .automatic) {
                    Button(action: goBack) {
                        FairSymbol.chevron_left
                            .imageScale(.large)
                            .aspectRatio(contentMode: .fit)
                    }
                    .disabled(!web.canGoBack)
                    .keyboardShortcut("[")
                    Button(action: goForward) {
                        FairSymbol.chevron_right
                            .imageScale(.large)
                            .aspectRatio(contentMode: .fit)
                    }
                    .disabled(!web.canGoForward)
                    .keyboardShortcut("]")
                }
            }
            .onAppear {
                self.web.webView.load(URLRequest(url: url))
            }
            .onChange(of: url) { url in
                self.web.webView.load(URLRequest(url: url))
            }
    }

    func goBack() {
        web.webView.goBack()
    }

    func goForward() {
        web.webView.goForward()
    }
}

public extension WKWebView {
    /// Evaluates the given JavaScript synchronously in the WebView
    func eval(js: String, timeout: DispatchTime = .distantFuture) throws -> NSObject? {
        var result: Any?
        var error: Error?
        var done = false
        self.evaluateJavaScript(js) {
            (result, error) = ($0, $1)
            done = true
        }

        while !done {
            RunLoop.current.run(mode: RunLoop.Mode.default, before: .distantFuture)
        }

        if let error = error {
            throw error
        } else {
            return result as? NSObject
        }
    }

    enum Errors : Error {
        case timedOut
    }
}

@dynamicMemberLookup
public class WebController: ObservableObject {
    private var propertyObservers: [NSKeyValueObservation] = []

    @Published public var webView: WKWebView {
        didSet {
            observeProperties()
        }
    }

    public init(webView: WKWebView = WKWebView()) {
        self.webView = webView
        observeProperties()
    }

    private func observeProperties() {
        func sub<Value>(_ keyPath: KeyPath<WKWebView, Value>) -> NSKeyValueObservation {
            return webView.observe(keyPath, options: [.prior]) { _, change in
                if change.isPrior {
                    self.objectWillChange.send()
                }
            }
        }

        propertyObservers = [
            sub(\.url),
            sub(\.isLoading),
            sub(\.canGoBack),
            sub(\.canGoForward),
            sub(\.estimatedProgress),
            sub(\.title),
            sub(\.hasOnlySecureContent),
            sub(\.serverTrust),
        ]
    }

    public subscript<T>(dynamicMember keyPath: KeyPath<WKWebView, T>) -> T {
        webView[keyPath: keyPath]
    }
}

private struct UXWebView : UXViewRepresentable {
    let webView: WKWebView

    func makeUXView(context: Context) -> WKWebView {
        webView
    }

    func updateUXView(_ view: WKWebView, context: Context) {
    }

    static func dismantleUXView(_ view: UXViewType, coordinator: ()) {
        view.stopLoading()
    }
}


#endif // canImport(WebKit)
#endif // canImport(SwiftUI)

