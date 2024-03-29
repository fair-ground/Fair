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
#if canImport(WebKit)
@_exported import WebKit

public extension WKWebView {
    /// Equivalent to the async form of `evaluateJavaScript`, except it doesn't crash when a nil is returned.
    ///
    /// - Parameters:
    ///   - js: the JavaScript to evaluate
    ///   - frame: the frame in which to evaluate the script
    ///   - contentWorld: the content world in which to perform the evaluation
    /// - Returns: the result from the JS execution
    @discardableResult func evalJS(_ js: String, in frame: WKFrameInfo? = nil, in contentWorld: WKContentWorld = .defaultClient) async throws -> Any {
        try await withCheckedThrowingContinuation { cnt in
            evaluateJavaScript(js, in: frame, in: contentWorld,completionHandler: cnt.resume)
        }
    }
}


/// A driver for web pages that can asynchronously wait for a load to complete.
public class WebDriver : NSObject, WKNavigationDelegate {
    public let webView: WKWebView

    /// The outstanding requests
    private var requests: [WKNavigation: AsyncThrowingStream<WebDriver.Event, any Error>.Continuation] = [:]

    public init(webView: WKWebView = WKWebView()) {
        self.webView = webView
        super.init()
        if self.webView.navigationDelegate === nil {
            self.webView.navigationDelegate = self
        }
    }

    deinit {
        if self.webView.navigationDelegate === self {
            self.webView.navigationDelegate = nil
        }
    }

    public func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        requests[navigation]?.yield(.commit)
    }

    public func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        requests[navigation]?.yield(.startProvisionalNavigation)
    }

    public func webView(_ webView: WKWebView, didReceiveServerRedirectForProvisionalNavigation navigation: WKNavigation!) {
        requests[navigation]?.yield(.receiveServerRedirectForProvisionalNavigation)
    }

    public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        if let cnt = requests.removeValue(forKey: navigation) {
            cnt.yield(.complete)
            cnt.finish()
        }
    }

    public func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        if let cnt = requests.removeValue(forKey: navigation) {
            cnt.finish(throwing: error)
        }
    }

    public func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        if let cnt = requests[navigation] {
            requests[navigation] = nil
            cnt.finish(throwing: error)
        }
    }

    /// Loads the given request and reutrns once the request is complete
    @MainActor @discardableResult public func load(request: URLRequest) async throws -> [Event] {
        var events: [Event] = []
        for try await event in loadStream(request: request) {
            events.append(event)
        }
        return events
    }

    /// Loads the given request and returns the stream of events that resulted from the naviation.
    @MainActor public func loadStream(request: URLRequest) -> AsyncThrowingStream<Event, Error> {
        self.webView.stopLoading()
        return AsyncThrowingStream { cnt in
            assert(Thread.isMainThread)
            if let nav = self.webView.load(request) {
                self.requests[nav] = cnt
            } else {
                cnt.finish(throwing: AppError(String(format: NSLocalizedString("Error navigating to: %@", bundle: .module, comment: "error message"), request.url?.absoluteString ?? "")))
            }
        }
    }

    public enum Event {
        case commit
        case startProvisionalNavigation
        case receiveServerRedirectForProvisionalNavigation
        case startLoading
        case complete
    }
}


#if canImport(SwiftUI)
import WebKit
import SwiftUI

/// A view that displays a web page.
@available(macOS 11, iOS 14, *)
public struct WebView : View {
    /// The state of the web view, which is created and held externally
    @ObservedObject var state: WebViewState
    @State private var defaultDialog: Dialog? = nil

    private var customDialog: Binding<Dialog?>? = nil
    fileprivate var dialog: Dialog? {
        get { (self.customDialog ?? self.$defaultDialog).wrappedValue }
        nonmutating set { (self.customDialog ?? self.$defaultDialog).wrappedValue = newValue }
    }
    private var useInternalDialogHandling = true

    public init(state: WebViewState, dialog: Binding<Dialog?>? = nil) {
        self.state = state
        self.customDialog = dialog
        self.useInternalDialogHandling = dialog == nil
    }

    public var body: some View {
        WebViewRepresentable(owner: self)
            .overlay(dialogView)
    }

    @ViewBuilder
    private var dialogView: some View {
        if useInternalDialogHandling, let configuration = dialog?.configuration {
            switch configuration {
            case let .javaScriptAlert(message, completion):
                JavaScriptAlert(message: message, completion: {
                    dialog = nil
                    completion()
                })
            case let .javaScriptConfirm(message, completion):
                JavaScriptConfirm(message: message, completion: {
                    dialog = nil
                    completion($0)
                })
            case let .javaScriptPrompt(message, defaultText, completion):
                JavaScriptPrompt(message: message, defaultText: defaultText, completion: {
                    dialog = nil
                    completion($0)
                })
            }
        } else {
            EmptyView().hidden()
        }
    }

    /// Checks whether or not WebView can handle the given URL by default.
    public static func canHandle(_ url: URL) -> Bool {
        return url.scheme.map(WKWebView.handlesURLScheme(_:)) ?? false
    }
}

private struct WebViewRepresentable {
    let owner: WebView

    @MainActor func makeView(coordinator: WebViewCoordinator, environment: EnvironmentValues) -> WebEngineView {
        let view = coordinator.owner.state.createWebView()

        view.navigationDelegate = coordinator
        view.uiDelegate = coordinator

        coordinator.webView = view
        coordinator.environment = environment

        return view
    }

    func updateView(_ view: WebEngineView, coordinator: WebViewCoordinator, environment: EnvironmentValues) {
        coordinator.environment = environment

        if let flag = environment.allowsBackForwardNavigationGestures {
            view.allowsBackForwardNavigationGestures = flag
        }
    }

    static func dismantleView(_ view: WKWebView, coordinator: WebViewCoordinator) {
        coordinator.webView = nil
    }

    func makeCoordinator() -> WebViewCoordinator {
        WebViewCoordinator(owner: owner)
    }
}

extension WebViewRepresentable : UXViewRepresentable {
    @MainActor func makeUXView(context: Context) -> WebEngineView {
        makeView(coordinator: context.coordinator, environment: context.environment)
    }

    @MainActor func updateUXView(_ uxView: WebEngineView, context: Context) {
        updateView(uxView, coordinator: context.coordinator, environment: context.environment)
    }

    @MainActor static func dismantleUXView(_ uxView: WebEngineView, coordinator: Coordinator) {
        dismantleView(uxView, coordinator: coordinator)
    }
}

@dynamicMemberLookup
private final class WebViewCoordinator : NSObject, WKNavigationDelegate, WKUIDelegate {
    var owner: WebView
    fileprivate var environment: EnvironmentValues?

    init(owner: WebView) {
        self.owner = owner
    }

    var webView: WKWebView? {
        get { owner.state.webView }
        set { owner.state.webView = newValue }
    }

    subscript<T>(dynamicMember keyPath: ReferenceWritableKeyPath<WebViewState, T>) -> T {
        get { owner.state[keyPath: keyPath] }
        set { owner.state[keyPath: keyPath] = newValue }
    }

    // MARK: Navigation

    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, preferences: WKWebpagePreferences, decisionHandler: @escaping (WKNavigationActionPolicy, WKWebpagePreferences) -> Void) {
        if let decider = environment?.navigationActionDecider {
            let action = NavigationAction(
                navigationAction, webpagePreferences: preferences, reply: decisionHandler)
            decider(action, owner.state)
        } else {
            decisionHandler(.allow, preferences)
        }
    }

    func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse, decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
        if let decider = environment?.navigationResponseDecider {
            let response = NavigationResponse(navigationResponse, reply: decisionHandler)
            decider(response, owner.state)
        } else {
            decisionHandler(.allow)
        }
    }

    func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
        owner.dialog = .javaScriptAlert(message, completion: completionHandler)
    }

    func webView(_ webView: WKWebView, runJavaScriptConfirmPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (Bool) -> Void) {
        owner.dialog = .javaScriptConfirm(message, completion: completionHandler)
    }

    func webView(_ webView: WKWebView, runJavaScriptTextInputPanelWithPrompt prompt: String, defaultText: String?, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (String?) -> Void) {
        owner.dialog = .javaScriptPrompt(
            prompt, defaultText: defaultText ?? "", completion: completionHandler)
    }

    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        owner.state.didCommit(navigation: navigation)
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        owner.state.didFinish(navigation: navigation)
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        owner.state.didFail(navigation: navigation, provisional: false, error: error)
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        owner.state.didFail(navigation: navigation, provisional: true, error: error)
    }

    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        owner.state.didStartProvisional(navigation: navigation)
    }

    func webView(_ webView: WKWebView, didReceiveServerRedirectForProvisionalNavigation navigation: WKNavigation!) {
        owner.state.didRedirectProvisional(navigation: navigation)
    }

    #if os(iOS)
    // TODO: context menus on iOS

//    func webView(_ webView: WKWebView, contextMenuConfigurationForElement elementInfo: WKContextMenuElementInfo, completionHandler: @escaping (UIContextMenuConfiguration?) -> Void) {
//        completionHandler(UIContextMenuConfiguration(identifier: nil, previewProvider: nil, actionProvider: { [weak self] elements in
//            self?.actionProvider(suggestedActions: elements)
//        }))
//    }
//
//    func actionProvider(suggestedActions: [UIMenuElement]) -> UIMenu? {
//        UIMenu(title: "", image: nil, identifier: nil, options: .displayInline, children: suggestedActions)
//    }
    #endif
}

public struct Dialog : Identifiable, Hashable {
    public var id = ID()

    public var configuration: Configuration

    public init(id: ID = ID(), _ configuration: Configuration) {
        self.id = id
        self.configuration = configuration
    }

    public static func javaScriptAlert(id: ID = ID(), _ message: String, completion: @escaping () -> Void) -> Self {
        Dialog(id: id, .javaScriptAlert(message, completion))
    }

    public static func javaScriptConfirm(id: ID = ID(), _ message: String, completion: @escaping (Bool) -> Void
    ) -> Self {
        Dialog(id: id, .javaScriptConfirm(message, completion))
    }

    public static func javaScriptPrompt(id: ID = ID(), _ message: String, defaultText: String = "", completion: @escaping (String?) -> Void) -> Self {
        Dialog(id: id, .javaScriptPrompt(message, defaultText: defaultText, completion))
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    public static func == (lhs: Dialog, rhs: Dialog) -> Bool {
        lhs.id == rhs.id
    }

    public struct ID : Hashable {
        private var rawValue = UUID()

        public init() {
        }
    }

    public enum Configuration {
        case javaScriptAlert(String, () -> Void)
        case javaScriptConfirm(String, (Bool) -> Void)
        case javaScriptPrompt(String, defaultText: String, (String?) -> Void)
    }
}

private struct DialogHost<Contents, Actions> : View where Contents : View, Actions : View {
    var contents: Contents
    var actions: Actions

    init(@ViewBuilder contents: () -> Contents, @ViewBuilder actions: () -> Actions) {
        self.contents = contents()
        self.actions = actions()
    }

    var body: some View {
        ZStack {
            Color(white: 0, opacity: 0.15)

            VStack(spacing: 0) {
                VStack(alignment: .leading) {
                    contents
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()

                Divider()

                HStack(spacing: 12) {
                    Spacer()
                    actions
                        .buttonStyle(_LinkButtonStyle())
                }
                .padding(.horizontal)
                .padding(.vertical, 12)
            }
            .frame(maxWidth: 300)
            .background(RoundedRectangle(cornerRadius: 10)
                            .foregroundColor(Color.platformBackground)
                            .shadow(radius: 12))
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.platformSeparator))
        }
    }
}

#if os(macOS)
private typealias _LinkButtonStyle = LinkButtonStyle
#else
private struct _LinkButtonStyle : ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(.blue)
    }
}
#endif

/// A view providing the WebKit-default UI for a JavaScript alert.
struct JavaScriptAlert : View {
    private var message: String
    private var completion: () -> Void

    init(message: String, completion: @escaping () -> Void) {
        self.message = message
        self.completion = completion
    }

    var body: some View {
        DialogHost {
            Text(message)
        } actions: {
            Button("OK", action: completion)
                .keyboardShortcut(.return)
        }
    }
}

/// A view providing the WebKit-default UI for a JavaScript alert.
struct JavaScriptConfirm : View {
    private var message: String
    private var completion: (Bool) -> Void

    init(message: String, completion: @escaping (Bool) -> Void) {
        self.message = message
        self.completion = completion
    }

    var body: some View {
        DialogHost {
            Text(message)
        } actions: {
            Button("Cancel", action: { completion(false) })
                .keyboardShortcut(".")
            Button("OK", action: { completion(true) })
                .keyboardShortcut(.return)
        }
    }
}

/// A view providing the WebKit-default UI for a JavaScript alert.
struct JavaScriptPrompt : View {
    private var message: String
    private var completion: (String?) -> Void
    @State private var text: String

    init(message: String, defaultText: String = "", completion: @escaping (String?) -> Void) {
        self.message = message
        self._text = State(wrappedValue: defaultText)
        self.completion = completion
    }

    var body: some View {
        DialogHost {
            Text(message)
            TextField("Your Response", text: $text, onCommit: { completion(text) })
        } actions: {
            Button(action: { completion(nil) }) {
                Text("Cancel", bundle: .module, comment: "cancel button label")
            }
                .keyboardShortcut(".")
            Button(action: { completion(text) }) {
                Text("OK", bundle: .module, comment: "OK button label")
            }
                .keyboardShortcut(.return)
        }
    }
}

extension View {
    /// An async block that will return whether a navigation action should be permitted
    public func webViewNavigationActionPolicy(decide actionDecider: @escaping (WKNavigationAction, WebViewState) async -> (WKNavigationActionPolicy, WKWebpagePreferences?)) -> some View {
        navigationPolicy(onAction: { action, state in
            Task {
                let (policy, prefs) = await actionDecider(action.action, state)
                action.decidePolicy(policy, webpagePreferences: prefs)
            }
        })
    }

    /// An async block that will return whether a navigation response should be permitted
    public func webViewNavigationResponsePolicy(decide responseDecider: @escaping (WKNavigationResponse, WebViewState) async -> WKNavigationResponsePolicy) -> some View {
        navigationPolicy(onResponse: { response, state in
            Task {
                let policy = await responseDecider(response.response, state)
                response.decidePolicy(policy)
            }
        })
    }

}

extension View {
    private func navigationPolicy(onAction actionDecider: @escaping (NavigationAction, WebViewState) -> Void) -> some View {
        environment(\.navigationActionDecider, actionDecider)
    }

    private func navigationPolicy(onResponse responseDecider: @escaping (NavigationResponse, WebViewState) -> Void) -> some View {
        environment(\.navigationResponseDecider, responseDecider)
    }

    private func navigationPolicy(onAction actionDecider: @escaping (NavigationAction, WebViewState) -> Void, onResponse responseDecider: @escaping (NavigationResponse, WebViewState) -> Void) -> some View {
        environment(\.navigationActionDecider, actionDecider)
            .environment(\.navigationResponseDecider, responseDecider)
    }
}

/// Contains information about an action that may cause a navigation, used for making
/// policy decisions.
@dynamicMemberLookup
fileprivate struct NavigationAction {
    typealias Policy = WKNavigationActionPolicy

    var action: WKNavigationAction
    var reply: (WKNavigationActionPolicy, WKWebpagePreferences) -> Void

    private(set) var webpagePreferences: WKWebpagePreferences

    init(_ action: WKNavigationAction, webpagePreferences: WKWebpagePreferences, reply: @escaping (WKNavigationActionPolicy, WKWebpagePreferences) -> Void) {
        self.action = action
        self.reply = reply
        self.webpagePreferences = webpagePreferences
    }

    func decidePolicy(_ policy: Policy, webpagePreferences: WKWebpagePreferences? = nil) {
        reply(policy, webpagePreferences ?? self.webpagePreferences)
    }

    subscript<T>(dynamicMember keyPath: KeyPath<WKNavigationAction, T>) -> T {
        action[keyPath: keyPath]
    }

    fileprivate struct DeciderKey : EnvironmentKey {
        static let defaultValue: ((NavigationAction, WebViewState) -> Void)? = nil
    }
}

@dynamicMemberLookup
fileprivate struct NavigationResponse {
    typealias Policy = WKNavigationResponsePolicy

    var response: WKNavigationResponse
    var reply: (Policy) -> Void

    init(_ response: WKNavigationResponse, reply: @escaping (Policy) -> Void) {
        self.response = response
        self.reply = reply
    }

    func decidePolicy(_ policy: Policy) {
        reply(policy)
    }

    subscript<T>(dynamicMember keyPath: KeyPath<WKNavigationResponse, T>) -> T {
        response[keyPath: keyPath]
    }

    fileprivate struct DeciderKey : EnvironmentKey {
        static let defaultValue: ((NavigationResponse, WebViewState) -> Void)? = nil
    }
}

private extension EnvironmentValues {
    var navigationActionDecider: ((NavigationAction, WebViewState) -> Void)? {
        get { self[NavigationAction.DeciderKey.self] }
        set { self[NavigationAction.DeciderKey.self] = newValue }
    }

    var navigationResponseDecider: ((NavigationResponse, WebViewState) -> Void)? {
        get { self[NavigationResponse.DeciderKey.self] }
        set { self[NavigationResponse.DeciderKey.self] = newValue }
    }
}

extension Color {
    public static var platformSeparator: Color {
#if os(macOS)
        return Color(NSColor.separatorColor)
#else
        return Color(UIColor.separator)
#endif
    }

    public static var platformBackground: Color {
#if os(macOS)
        return Color(NSColor.windowBackgroundColor)
#else
        return Color(UIColor.systemBackground)
#endif
    }
}

extension View {
    public func webViewAllowsBackForwardNavigationGestures(_ allowed: Bool) -> some View {
        environment(\.allowsBackForwardNavigationGestures, allowed)
    }
}

private struct WebViewAllowsBackForwardNavigationGesturesKey : EnvironmentKey {
    static let defaultValue: Bool? = nil
}

extension EnvironmentValues {
    var allowsBackForwardNavigationGestures: Bool? {
        get { self[WebViewAllowsBackForwardNavigationGesturesKey.self] }
        set { self[WebViewAllowsBackForwardNavigationGesturesKey.self] = newValue }
    }
}


/// The state of a WebView, which holds the `WKWebView` instance
open class WebViewState : ObservableObject {
    var configuration: WKWebViewConfiguration?
    @Published public var errors: [NSError] = []

    public fileprivate(set) var webView: WKWebView? {
        didSet {
            webViewObservations.forEach { $0.invalidate() }
            guard let webView = webView else {
                webViewObservations.removeAll()
                return
            }

            func register<T>(_ keyPath: KeyPath<WKWebView, T>) -> NSKeyValueObservation where T : Equatable {
                webView.observe(keyPath, options: [.prior, .old, .new], changeHandler: webView(_:didChangeKeyPath:))
            }

            webViewObservations = [
                register(\.canGoBack),
                register(\.canGoForward),
                register(\.title),
                register(\.url),
                register(\.isLoading),
                register(\.estimatedProgress),
                register(\.pageZoom),
            ]
        }
    }

    private var webViewObservations: [NSKeyValueObservation] = []

    public init(configuration: WKWebViewConfiguration? = nil) {
        self.configuration = configuration
    }

    @MainActor open func createWebView() -> WebEngineView {
        let view = WebEngineView(frame: .zero, configuration: configuration ?? .init())
        //view.setValue(UXColor.clear, forKey: "backgroundColor")

        // without this the web view will always flash white when first loading, even when dark mode is enabled
//        #if os(macOS)
//        view.setValue(false, forKey: "drawsBackground") // https://developer.apple.com/forums/thread/121139
//        #endif
        return view
    }

    open var canGoBack: Bool { webView?.canGoBack ?? false }
    open var canGoForward: Bool { webView?.canGoForward ?? false }
    open var title: String { webView?.title ?? "" }
    open var url: URL? { webView?.url }
    open var isLoading: Bool { webView?.isLoading ?? false }
    open var estimatedProgress: Double? { isLoading ? webView?.estimatedProgress : nil }
    open var hasOnlySecureContent: Bool { webView?.hasOnlySecureContent ?? false }

    /// Register that an error occurred with the app manager
    @MainActor open func reportError(_ error: Error) {
        dbg("error:", error)
        errors.append(error as NSError)
    }

    /// Attempts to perform the given action and adds any errors to the error list if they fail.
    open func trying(block: () async throws -> ()) async {
        do {
            try await block()
        } catch {
            await reportError(error)
        }
    }

    /// Sends an `objectWillChange` whenever an observed value changes
    func webView<Value>(_: WKWebView, didChangeKeyPath change: NSKeyValueObservedChange<Value>) where Value : Equatable {
        if change.isPrior && change.oldValue != change.newValue {
            objectWillChange.send()
        }
    }

    @discardableResult open func js(_ script: String) async throws -> Any? {
        try await webView?.evalJS(script)
    }

    @MainActor open func load(_ url: URL?) {
        if let url = url {
            load(URLRequest(url: url))
        }
    }

    @MainActor open func load(_ request: URLRequest) {
        _ = webView?.load(request)
    }

    @MainActor open func goBack() {
        _ = webView?.goBack()
    }

    @MainActor open func goForward() {
        _ = webView?.goForward()
    }

    @MainActor open func reload(fromOrigin: Bool = false) {
        if fromOrigin == true {
            _ = webView?.reloadFromOrigin()
        } else {
            _ = webView?.reload()
        }
    }

    @MainActor open func stopLoading() {
        webView?.stopLoading()
    }

    // extension points

    open func didCommit(navigation: WKNavigation) {
    }

    open func didFinish(navigation: WKNavigation) {
    }

    open func didFail(navigation: WKNavigation, provisional: Bool, error: Error) {
        dbg("failed", provisional ? "provisional" : "", navigation, error)
    }

    open func didStartProvisional(navigation: WKNavigation) {
    }

    open func didRedirectProvisional(navigation: WKNavigation) {
    }
}


/// The subclass for WKWebView that handles some basic browser operations
@MainActor open class WebEngineView : WKWebView {
    #if canImport(AppKit)
    // TODO: context menus on macOS
//    open override func willOpenMenu(_ menu: NSMenu, with event: NSEvent) {
//        dbg("### opening menu:", menu) // WKMenuItemIdentifierOpenLink, WKMenuItemIdentifierOpenLinkInNewWindow, WKMenuItemIdentifierDownloadLinkedFile, WKMenuItemIdentifierCopyLink, WKMenuItemIdentifierShareMenu
//        for item in menu.items {
//            dbg("### item id:", item.identifier, "rep:", item.representedObject)
//            if let picker = item.representedObject as? NSSharingServicePicker {
//            }
//        }
//        if let delegate = self.uiDelegate as? WebViewRepresentable {
//            //delegate.owner.state.contextMenuActions()
//        }
//        super.willOpenMenu(menu, with: event)
//    }
    #endif
}

// MARK: Command action support

extension WebViewState {
    @available(macOS 12, iOS 15, *)
    public func stopAction(brief: Bool = false) -> some View {
        (brief ? Text("Stop", bundle: .module, comment: "label for brief stop command") : Text("Stop Loading", bundle: .module, comment: "label for non-brief stop command"))
            .label(image: FairSymbol.xmark)
            .button {
                dbg("stopping load:", self.url)
                Task {
                    await self.stopLoading()
                }
            }
            .disabled(self.url == nil || self.isLoading != true)
    }

    @available(macOS 12, iOS 15, *)
    public func navigateAction(brief: Bool = false, amount: Int, symbol: Image? = nil) -> some View {
        (amount < 0 ? (brief ? Text("Back", bundle: .module, comment: "label for go back command") : Text("Go Back", bundle: .module, comment: "label for non-brief go back command")) : (brief ? Text("Forward", bundle: .module, comment: "label for go forward command") : Text("Go Forward", bundle: .module, comment: "label for non-brief go forward command")))
            .label(image: symbol ?? (amount < 0 ? FairSymbol.chevron_left.image : FairSymbol.chevron_right.image))
            .button {
                dbg("navigate:", amount, self.url)
                Task {
                    if amount < 0 {
                        await self.goBack()
                    } else {
                        await self.goForward()
                    }
                }
            }
            .disabled(amount < 0 ? self.canGoBack != true : self.canGoForward != true)
    }


    @available(macOS 12, iOS 15, *)
    public func reloadAction(brief: Bool = false) -> some View {
        (brief ? Text("Reload", bundle: .module, comment: "label for brief reload command") : Text("Reload Page", bundle: .module, comment: "label for non-brief reload command"))
            .label(image: FairSymbol.arrow_clockwise)
            .button {
                dbg("reloading:", self.url)
                Task {
                    await self.reload()
                }
            }
            .disabled(self.url == nil || self.isLoading != false)
    }

    /// The command for performing a zoom operation at the given amount.
    @available(macOS 12, iOS 15, *)
    public func zoomAction(brief: Bool = false, amount: Double?, minimumZoomLevel: Double = 0.05, maximumZoomLevel: Double = 100.0) -> some View {
        let disabled = (amount ?? 1.0) < 1.0 ? ((self.webView?.pageZoom ?? 0.0) < minimumZoomLevel) : ((amount ?? 1.0) > 1.0 ? ((self.webView?.pageZoom ?? 1.0) > maximumZoomLevel) : (self.webView?.pageZoom == 1.0))

        return (amount == nil ?
             (brief ? Text("Actual Size", bundle: .module, comment: "label for brief actual size command") : Text("Actual Size", bundle: .module, comment: "label for non-brief actual size command"))
             : (amount ?? 1.0) > 1.0 ? (brief ? Text("Bigger", bundle: .module, comment: "label for brief zoom in command") : Text("Zoom In", bundle: .module, comment: "label for non-brief zoom in command"))
                 : (brief ? Text("Smaller", bundle: .module, comment: "label for brief zoom out command") : Text("Zoom Out", bundle: .module, comment: "label for non-brief zoom out command")))
            .label(image: amount == nil ? FairSymbol.textformat_superscript : (amount ?? 1.0) > 1.0 ? FairSymbol.textformat_size_larger : FairSymbol.textformat_size_smaller)
                .button {
                    if let webView = self.webView {
                        if let amount = amount {
                            webView.pageZoom *= amount
                        } else { // reset to zero
                            webView.pageZoom = 1.0
                        }
                        dbg("zoomed by:", amount, "to:", webView.pageZoom)
                    } else {
                        dbg("no webView installed on:", self)
                    }
                }
                .disabled(disabled)
    }
}

// Note that some of these are redundant (reloadButton vs. reloadAction)

extension WebViewState {

    /// Creates a button whose action will copy the current URL to the clipboard
    public func copyURLButton(symbol: FairSymbol = .link_circle) -> some View {
        Text("Copy URL", bundle: .module, comment: "button title for copying embedded browser url to clipboard")
            .label(image: symbol)
            .button {
                if let url = self.url {
                    #if os(iOS)
                    UIPasteboard.general.urls = [url]
                    UIPasteboard.general.strings = [url.absoluteString]
                    #elseif os(macOS)
                    UXPasteboard.general.clearContents()
                    UXPasteboard.general.writeObjects([url as NSURL]) // doesn't seem to work by itself
                    UXPasteboard.general.writeObjects([url.absoluteString as NSString])
                    #endif
                }
            }
            .help(Text("Copies this URL to the clipboard: \(urlString)", bundle: .module, comment: "button tooltip for embedded browser reload the url"))
    }

    public func openInBrowserButton(symbol: FairSymbol = .square_and_arrow_up, action openURLAction: OpenURLAction) -> some View {
        Text("Open in Browser", bundle: .module, comment: "button title for opening embedded browser's url in the system browser")
            .label(image: symbol)
            .button {
                if let url = self.url {
                    openURLAction(url)
                }
            }
            .help(Text("Opens this URL in the system browser: \(urlString)", bundle: .module, comment: "button tooltip for embedded browser open in system browser"))

    }


    public func reloadButton(symbol: FairSymbol = .arrow_triangle_2_circlepath_circle, rotationBinding: Binding<Double>) -> some View {
        Text("Reload", bundle: .module, comment: "button title for reloading embedded browser")
            .label(image: loadingImageButton(rotationBinding: rotationBinding, symbol: symbol, loading: self.isLoading))
            .button {
                #if os(macOS)
                let cmdDown = UXApplication.shared.currentEvent?.modifierFlags.contains(.command) == true
                #else
                let cmdDown = false
                #endif
                dbg("reloading from", cmdDown ? "origin" : "cache", self.urlString)
                Task {
                    await self.reload(fromOrigin: cmdDown)
                }
            }
            .help(Text("Reloads this URL in the system browser: \(urlString)", bundle: .module, comment: "button tooltip for embedded browser reload the url"))

    }

    @ViewBuilder private func loadingImageButton(rotationBinding: Binding<Double>, symbol: FairSymbol, duration: TimeInterval = 0.75, loading: Bool) -> some View {
        // while the page is loading, rotate the loading indicator button
        ZStack {
            if loading {
                symbol
                    .rotationEffect(Angle.degrees(rotationBinding.wrappedValue), anchor: .center)
                    .animation(loading == false ? .none : Animation.linear(duration: duration).repeatForever(autoreverses: false), value: rotationBinding.wrappedValue)
            } else {
                symbol
            }
        }
            .onChange(of: loading) { loading in
                // this needs to happen without an animation or else the symbols sometimes move around in the button area
                withAnimation(.none) {
                    rotationBinding.wrappedValue = loading ? 360.0 : 0.0
                }
            }
    }


    private var urlString: String { self.url?.absoluteString ?? "" }
}


#endif
#endif
