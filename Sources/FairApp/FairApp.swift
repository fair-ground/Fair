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
import Foundation
@_exported import FairCore
#if canImport(Security)
import Security
#endif 

public extension Bundle {
    /// The org name of the catalog browser app itself
    static let catalogBrowserAppOrg = "App-Fair"

    /// Returns the resources bundle for `FairApp`
    static var fairApp: Bundle { Bundle.module }

    /// The bundle for the app module itself. Note that since all the code resides in the App Swift Module,
    /// runtime resources will be included in the Bundle rather tha in `Bundle.main`.
    static var appBundle: Bundle? {
        Bundle.allFrameworks.first(where: { $0.bundleName == "App_App" })
    }

    /// The main bundle's identifier, falling back to `app.App-Name`
    static var mainBundleID: String {
        Bundle.main.bundleIdentifier ?? "app.App-Name"
    }

    /// The main bundle's bundleDisplayName, falling back to bundleName then `App Name`
    static var mainBundleName: String {
        Bundle.main.bundleDisplayName ?? Bundle.main.bundleName ?? "App Name"
    }

    /// Whether this is the fair-ground catalog browser app itself
    var isCatalogBrowserApp: Bool {
        bundleIdentifier == "app.\(Self.catalogBrowserAppOrg)"
    }

    /// Returns the URL for referencing the current app from within the app store
    static func appFairURL(_ action: String) -> URL? {
        URL(string: "appfair://\(action)/\(Bundle.mainBundleID)")
    }
}


#if canImport(SwiftUI)
/// A container for an app, which manages a single app-wide state and provides views for the `rootScene` and `settingsView`.
@available(macOS 12.0, iOS 15.0, *)
public protocol FairContainer {
    /// The store for this instance
    associatedtype AppStore : SceneManager

    associatedtype SceneBody : SwiftUI.Scene

    /// The root scene for new windows
    @SceneBuilder static func rootScene(store: Self.AppStore) -> Self.SceneBody

    associatedtype SettingsBody : View
    /// The settings associated with this app
    @ViewBuilder static func settingsView(store: Self.AppStore) -> Self.SettingsBody

    /// Launch the app, either in GUI or CLI form
    static func main() throws

    /// Invokes the command-line form of the application when the app is run from a terminal
    static func cli(args: [String]) throws -> Bool
}

@available(macOS 12.0, iOS 15.0, *)
public extension FairContainer {
    /// The default cli is a no-op
    static func cli(args: [String]) throws -> Bool {
        false
    }
}

#if swift(>=5.5)
@available(macOS 12.0, iOS 15.0, *)
@MainActor open class SceneManager: ObservableObject {
    /// Must have a no-arg initializer
    public required init() { }
}
#else
@available(macOS 11.0, iOS 14.0, *)
open class SceneManager: ObservableObject {
    /// Must have a no-arg initializer
    public required init() { }
}
#endif

#if canImport(Security)
import Security
import SwiftUI
public extension AppEntitlement {
    #if !os(iOS) // someday
    /// Returns true if the entitlement is enabled for the current process,
    /// or `nil` if the entitlement was not set
    func isEnabled(forTask: SecTask? = nil) -> Bool? {
        entitlementValue(forTask: forTask) as? NSNumber as? Bool // top-level entitlements should a Bool
    }

    /// Returns the value of the given entitlement for the specified task (defaulting to the current process)
    func entitlementValue(forTask: SecTask? = nil) -> NSObject? {
        let task = forTask ?? SecTaskCreateFromSelf(nil)!
        var error: Unmanaged<CFError>? = nil
        let signid = SecTaskCopySigningIdentifier(task, &error)
        precondition(error == nil)

        // TODO: optionally check if we are being run as an XPC connection
        //var tok: audit_token_t? = nil
        //xpc_connection_get_audit_token(conn, &tok)
        //let sectask: SecTask = SecTaskCreateWithAuditToken(nil, tok)
        let value = SecTaskCopyValueForEntitlement(task, self.entitlementKey as CFString, &error)

        // e.g.:  isEnabled: check signid: app.App-Name entitlement: com.apple.security.app-sandbox task: AppFair App[55734]/1#5 LF=0 value: 1 error:
        // dbg("check signid:", signid, "entitlement:", self.entitlementKey, "task:", task, "value:", value, "error:", error?.takeUnretainedValue())
        precondition(error == nil)
        //precondition(signid != nil, "code is not signed at all")
        if signid == nil {
            dbg("WARNING: code is not signed, and so will behave differently when run in the sandbox")
        }
        return value as? NSObject // CFTypeRef conversion
    }
    #endif // !os(iOS)
}
#endif // canImport(Security)

@available(macOS 12.0, iOS 15.0, *)
extension FairContainer {
    /// Check for CLI flags then launch as a `SwiftUI.App` app.
    public static func launch(bundle: Bundle, sourceFile: StaticString = #file) throws {
        // fileno(stdin) will be set only for tty launch or the debugger; the env "_" is additionally srt to permit launching in Xcode debugger (where stdin is set)
        let isCLI = isatty(fileno(stdin)) == 1 && ProcessInfo.processInfo.environment["_"] != "/usr/bin/open"

        //var stderr = HandleStream(stream: .standardError)
        var stdout = HandleStream(stream: .standardOutput)

        let args = Array(CommandLine.arguments.dropFirst())
        if args.first == "info" && isCLI {
            dumpProcessInfo(bundle: bundle, &stdout)
        } else if args.first == "fairtool" && isCLI {
            try FairCLI(arguments: args).runCLI()
        } else {
            if FairCore.assertionsEnabled { // raise a warning if our app container is invalid
                validateEntitlements()
                try? verifyAppMain(String(contentsOf: URL(fileURLWithPath: sourceFile.description)))
            }

            if isCLI == false { // launch the app itself
                dumpProcessInfo(bundle: bundle, &stdout) // always log the app info
                FairContainerApp<Self>.main()
            } else { // invoke the command-line interface to the app
                if try Self.cli(args: CommandLine.arguments) == false {
                    dumpProcessInfo(bundle: bundle, &stdout) // if the command-line interface fails, show the process info
                }
            }
        }
    }

    public static func main() throws {
        do {
            try launch(bundle: Bundle.module)
        } catch {
            // we don't want to re-throw the exception here, since it will cause a crash report when run from AppContainer.main
            // TODO: nicer error formatting; resolution suggestions
            print("Error:", error.localizedDescription)
            if let error = error as? LocalizedError {
                if let errorDescription = error.errorDescription, errorDescription != error.localizedDescription {
                    print("   Description:", errorDescription)
                }
                if let failureReason = error.failureReason {
                    print("   Reason:", failureReason)
                }
                if let helpAnchor = error.helpAnchor {
                    print("   Help:", helpAnchor)
                }
                if let recoverySuggestion = error.recoverySuggestion {
                    print("   Suggestion:", recoverySuggestion)
                }
            } else {
                print("   Raw:", error)
            }

            throw error // re-throw
        }
    }

    private static func dumpProcessInfo<O: TextOutputStream>(bundle: Bundle, _ out: inout O) {
        func infoValue<T>(_ key: InfoPlistKey) -> T? {
            (Bundle.main.localizedInfoDictionary?[key.plistKey] as? T)
                ?? (Bundle.main.infoDictionary?[key.plistKey] as? T)
        }

        print("App Fair App: " + (infoValue(.CFBundleDisplayName) as String? ?? infoValue(.CFBundleName) as String? ?? ""), to: &out)
        print("    App Name: " + (infoValue(.CFBundleName) as String? ?? ""), to: &out)
        print("   Bundle ID: " + (infoValue(.CFBundleIdentifier) as String? ?? ""), to: &out)
        print("     Version: " + (infoValue(.CFBundleShortVersionString) as String? ?? ""), to: &out)
        print("       Build: " + (infoValue(.CFBundleVersion) as String? ?? ""), to: &out)
        print("     License: " + (infoValue(.NSHumanReadableCopyright) as String? ?? ""), to: &out)
        print("    Category: " + (infoValue(.LSApplicationCategoryType) as String? ?? ""), to: &out)

        let presentation: String
        switch infoValue(.LSUIPresentationMode) as NSNumber? {
        case 1: presentation = "Content Suppressed"
        case 2: presentation = "Content Hidden"
        case 3: presentation = "All Hidden"
        case 4: presentation = "All Suppressed"
        case 0, _: presentation = "Normal"
        }

        print("Presentation: " + presentation)
        print("  Background: " + (infoValue(.LSBackgroundOnly) as Bool? ?? false).description, to: &out)
        print("       Agent: " + (infoValue(.LSUIElement) as Bool? ?? false).description, to: &out)
        print("  OS Version: " + (infoValue(.LSMinimumSystemVersion) as String? ?? "").description, to: &out)

        #if os(macOS)
        print("     Sandbox: " + (AppEntitlement.app_sandbox.isEnabled() ?? false).description, to: &out)
        for entitlement in AppEntitlement.allCases {
            if entitlement != AppEntitlement.app_sandbox {
                if let entitlementValue = entitlement.entitlementValue(), entitlementValue != false as NSNumber {
                    print(" Entitlement: " + entitlement.rawValue + "=" + entitlementValue.description, to: &out)
                }
            }
        }
        #endif

        do {
            let packageResolved = try JSONDecoder().decode(ResolvedPackage.self, from: bundle.loadResource(named: "Package.resolved"))
            for dep in packageResolved.object.pins {
                let packageVersion = dep.state.version ?? dep.state.branch ?? "none"
                print("  Dependency: " + dep.package + " " + packageVersion + " " + (dep.state.revision ?? ""), to: &out)
            }
        } catch {
            print("  Dependency: " + error.localizedDescription, to: &out)
        }
    }

    /// Checks the runtime entitlements to validate that sandboxing is enabled and and ensures that there are corresponding entries in the `FairUsage` section of the `Info.plist`
    private static func validateEntitlements() {
        #if !os(iOS) // someday
        if AppEntitlement.app_sandbox.isEnabled() != true
            && Bundle.main.isCatalogBrowserApp == false {
            let msg = "fair-ground apps are required to be sandboxed"
            if assertionsEnabled {
                dbg("WARNING:", msg) // re-running the app without building sometimes doesn't re-sign it, so we permit this when running but note that the sandbox entitlements will not be enforced
            } else {
                fatalError(msg) // for a release build, lack of sandboxing is a fatal error
            }
        }
        #endif
    }

    /// Verifies that the source that launches the app matches one of the available templates and issue a warning that the release build will fail unless the source matches the template.
    ///
    /// This only works in DEBUG mode and with the same source layout as the build machine,
    /// but it is a useful initial check that the app is valid.
    private static func verifyAppMain(_ source: String) {
        dbg("Verifying app main:", source.count.localizedByteCount())
        for template in FairTemplate.allCases {
            do {
                try template.compareScaffold(project: source, path: "Sources/App/AppMain.swift")
            } catch {
                dbg("Verify failed:", error.localizedDescription)
                dbg("Break in verifyAppMain to debug")
            }
        }
    }
}

/// A simple pass-through from `FileHandle` to `TextOutputStream`
struct HandleStream: TextOutputStream {
    let stream: FileHandle

    func write(_ string: String) {
        if let data = string.data(using: .utf8) {
            stream.write(data)
        }
    }
}

@available(macOS 12.0, iOS 15.0, *)
public struct FairContainerApp<Container: FairContainer> : SwiftUI.App {
    @UXApplicationDelegateAdaptor(AppDelegate.self) fileprivate var delegate
    @Environment(\.openURL) var openURL
    @StateObject public var store = Container.AppStore()

    public init() {
    }

    @SceneBuilder public var body: some SwiftUI.Scene {
        let commands = Group {
            CommandGroup(replacing: CommandGroupPlacement.help) {
                linkButton("Help", path: nil)
                linkButton("Discussions", path: "discussions")
                linkButton("Issues", path: "issues")

                if let url = Bundle.appFairURL("update") {
                    Link(destination: url) {
                        Text("Check for Updates", bundle: .module)
                    }
                }

                //linkButton("Wiki", path: "wiki")
                //linkButton("Pulse", path: "pulse")
            }
        }

        Group {
            Container.rootScene(store: store)
            #if os(macOS) // on
            Settings {
                Container.settingsView(store: store)
            }
            #endif
        }
        .commands(content: { commands })
    }

    func openURLAction(action: inout OpenURLAction) {
        dbg(#function)
        let parentAction = action
        action = OpenURLAction { url in
            parentAction(url) { completed in
                // TODO: throw up a sheet requesting permission to open the URL (and optionally remember the decision)
            }
            return OpenURLAction.Result.handled
        }
    }

    func linkButton(_ title: SwiftUI.LocalizedStringKey, path: String? = nil) -> some View {
        Group {
            if let url = URL.fairHubURL(path) {
                Text(title, bundle: .module).link(to: url)
            }
        }
    }
}

public extension URL {
    /// Returns the URL for this app's hub page
    static func fairHubURL(_ path: String? = nil) -> URL? {
        guard let appOrgName = Bundle.main.appOrgName else {
            return nil
        }

        guard let baseURL = URL(string: "https://www.github.com/") else {
            return nil
        }

        return baseURL
            .appendingPathComponent(appOrgName)
            .appendingPathComponent(AppNameValidation.defaultAppName)
            .appendingPathComponent(path ?? "")
    }
}


@available(macOS 12.0, iOS 15.0, *)
private final class AppDelegate: NSObject, UXApplicationDelegate {
    #if canImport(AppKit)
    func applicationWillFinishLaunching(_ notification: Notification) {
        //dbg("applicationWillFinishLaunching")
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        //dbg("applicationDidFinishLaunching")
    }
    #elseif canImport(UIKit)
    func application(_ application: UIApplication, willFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        //dbg("willFinishLaunchingWithOptions")
        return true
    }

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        //dbg("didFinishLaunchingWithOptions")
        return true
    }
    #endif

}


@available(macOS 12.0, iOS 15.0, *)
extension String {
    #if swift(>=5.5)
    /// Parses the attributed text string into an `AttributedString`
    public func atx(interpret: AttributedString.MarkdownParsingOptions.InterpretedSyntax = .inlineOnlyPreservingWhitespace, allowsExtendedAttributes: Bool = true, languageCode: String? = nil) throws -> AttributedString {
        try AttributedString(markdown: self, options: .init(allowsExtendedAttributes: allowsExtendedAttributes, interpretedSyntax: interpret, failurePolicy: .returnPartiallyParsedIfPossible, languageCode: languageCode))
    }
    #endif
}

@available(macOS 12.0, iOS 15.0, *)
extension SwiftUI.Text {
    /// Creates a Text from the given attributed string, falling back to the unformatted string if it fails to parse.
    public init(atx attributedText: String, languageCode: String? = nil) {
        if let attributedString = try? attributedText.atx(languageCode: languageCode) {
            self.init(attributedString)
        } else {
            self.init(attributedText) // failure to parse will just display the formatted string raw
        }
    }

    /// Labels the given text with the given system symbol.
    public func label(symbol symbolName: String? = nil, color: Color? = nil) -> some View { // Label<Text, Image?> {
        label(image: symbolName.flatMap(Image.init(systemName:))?.foregroundColor(color))
    }

    /// Labels the given text with the given optional image.
    public func label<V: View>(image: V? = nil) -> Label<Text, V?> {
        Label(title: { self }, icon: { image })
    }

    /// Creates a `Link` to the given URL.
    public func link(to destination: URL) -> Link<Text> {
        Link(destination: destination) {
            self
        }
    }

    /// Creates a `Link` to the given URL, or the Text itself if the link is `.none`.
    public func link(to destination: URL?) -> some View {
        Group {
            if let destination = destination {
                Link(destination: destination) {
                    self
                }
                .help(Text("Open link in browser: ") + Text(destination.absoluteString))
            } else {
                self
            }
        }
    }
}

@available(macOS 12.0, iOS 15.0, *)
extension SwiftUI.View {
    /// Creates a `Button` with the given `action`.
    public func button(action: @escaping () -> ()) -> Button<Self> {
        Button(action: action) {
            self
        }
    }
}

@available(macOS 12.0, iOS 15.0, *)
extension SwiftUI.TextField {
    /// Creates a `Link` to the given URL and overlays it over the trailing end of the field.
    public func overlink(to destination: URL?, image: Image = Image(systemName: "arrowshape.turn.up.right.circle.fill")) -> some View {
        self.overlay(alignment: .trailing) {
            if let destination = destination {
                Link(destination: destination) {
                    image
                }
                //.padding(.horizontal) // causes a crash
            }
        }
    }

}

#endif // canImport(SwiftUI)


/// A generic error
public struct AppError : Pure, LocalizedError {
    /// A localized message describing what error occurred.
    public let errorDescription: String?

    /// A localized message describing the reason for the failure.
    public let failureReason: String?

    /// A localized message describing how one might recover from the failure.
    public let recoverySuggestion: String?

    /// A localized message providing "help" text if the user requests help.
    public let helpAnchor: String?

    public init(function: StaticString = #function, file: StaticString = #file, line: UInt = #line) {
        self.init("Error at \(function) in \(file):\(line)")
    }

    public init(_ errorDescription: String, failureReason: String? = nil, recoverySuggestion: String? = nil, helpAnchor: String? = nil) {
        self.errorDescription = errorDescription
        self.failureReason = failureReason
        self.recoverySuggestion = recoverySuggestion
        self.helpAnchor = helpAnchor
    }

    public init(_ error: Error) {
        self.errorDescription = error.localizedDescription
        self.failureReason = nil
        self.recoverySuggestion = nil
        self.helpAnchor = nil
    }
}


// MARK: Package-Specific Utilities

/// Returns the localized string for the current module.
///
/// - Note: This is boilerplate package-local code that could be copied
///  to any Swift package with localized strings.
internal func loc(_ key: String, tableName: String? = nil, comment: String? = nil) -> String {
    // TODO: use StringLocalizationKey
    NSLocalizedString(key, tableName: tableName, bundle: .module, comment: comment ?? "")
}

/// Work-in-Progress marker
@available(*, deprecated, message: "work in progress")
internal func wip<T>(_ value: T) -> T { value }

extension String {
    static func localizedString(for key: String, locale: Locale = .current, comment: StaticString = "") -> String {
        NSLocalizedString(key, bundle: Bundle.module.path(forResource: locale.languageCode, ofType: "lproj").flatMap(Bundle.init(path:)) ?? Bundle.module, comment: comment.description)
    }
}

