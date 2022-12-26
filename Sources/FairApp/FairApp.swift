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
import Swift
@_exported import Foundation
@_exported import FairCore

#if canImport(SwiftUI)
@_exported import SwiftUI
#endif

#if canImport(Security)
import Security
#endif 

public extension Bundle {
    /// The org name of the catalog browser app itself
    static let catalogBrowserAppOrg = "App-Fair"

    /// e.g: `appfair://update/app.Abc-Xyz`
    static let catalogBrowserAppScheme = catalogBrowserAppOrg.replacingOccurrences(of: "-", with: "").lowercased()

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

    /// Returns the localized name of this app from the bundle information.
    static var localizedAppName: String {
        Bundle.module[info: .CFBundleDisplayName, localized: true]
            ?? Bundle.main[info: .CFBundleDisplayName, localized: true]
            ?? Bundle.main[info: .CFBundleName, localized: false]
            ?? Bundle.module[info: .CFBundleName, localized: false]
            ?? "App"
    }

    /// Whether this is the fair-ground catalog browser app itself
    var isCatalogBrowserApp: Bool {
        bundleIdentifier == "app.\(Self.catalogBrowserAppOrg)"
    }

    /// Returns the URL for referencing the current app from within the app fair app
    static func appFairURL(for bundle: Bundle) -> URL? {
        URL(string: catalogBrowserAppScheme + "://" + (bundle.bundleID ?? "").replacingOccurrences(of: ".", with: "/"))
    }

    /// Returns the URL for the home of this App Fair app. This will open a link to the (required) GitHub pages page for the app, automatically re-directing to any custom domain that may have been configured..
    static func appHomeURL(for bundle: Bundle) -> URL? {
        guard let appOrgName = bundle.appOrgName else {
            return nil
        }
        return URL(string: "https://\(appOrgName).github.io/App/")
    }

    static func isAppFairInstalled() -> Bool {
        appFairURL(for: .main)?.canLaunchScheme() == true
    }

    func appCatalogInfo() throws -> AppCatalogItem? {
        guard let downloadURL = Self.appFairURL(for: self)?.absoluteString else { return nil }
        guard let downloadURL = URL(string: downloadURL) else { return nil }
        guard let dict = self.infoDictionary as? NSDictionary else { return nil }
        return try Plist(rawValue: dict).appCatalogInfo(downloadURL: downloadURL)
    }
}


extension PropertyListKey {
    /// A dictionary encoding of the contents of the App Source catalog.
    ///
    /// The dictionary can contain keys like "subtitle" and "localizedDescription".
    public static let AppSource = Self("AppSource")
}

extension Plist {
    /// Derives an ``AppCatalogItem`` from the contents of the ``Plist`` item,
    /// which is stored in the top-level "AppSource" dictionary in an app's main `Info.plist`.
    /// - Parameter downloadURL: the download URL for this app, which is arequirted property of an app catalog item.
    /// - Returns: nil if critical information (like the bundle name) is empty; otherwise, the catalog item that is contained in this property list node
    public func appCatalogInfo(appSourceKey: PropertyListKey = .AppSource, downloadURL: URL) throws -> AppCatalogItem? {
        guard let appName = self.CFBundleName ?? self.CFBundleDisplayName else {
            return nil
        }

        guard let bundleID = self.CFBundleIdentifier else {
            return nil
        }

        let appSource = (self.plistValue(for: appSourceKey) as? NSDictionary) ?? [:]

        // the rest of the properties will be inherited by
        let plist = Plist(rawValue: appSource)

        do {
            let item = try plist.createCatalogInfo(appName: appName, bundleID: bundleID, downloadURL: downloadURL)
            dbg("parsed AppCatalogItem from Info.plist:", try? item.debugJSON)
            return item
        } catch {
            dbg("error creating AppCatalogItem:", error)
            throw error
        }
    }

    private func createCatalogInfo(appName: String, bundleID: String, downloadURL: URL) throws -> AppCatalogItem {
        var dict: [String : Any] = [:]

        for (key, value) in self.rawValue {
            if let key = key as? String {
                dict[key] = value
            }
        }

        // inject the mandatory properties
        dict["name"] = appName
        dict["bundleIdentifier"] = bundleID
        dict["downloadURL"] = downloadURL.absoluteString

        // FIXME: this is slow because we are converting the Plist to JSON and then parsing it back into an AppCatalogItem
        var item = try AppCatalogItem(jsum: Plist(rawValue: NSDictionary(dictionary: dict, copyItems: true)).jsum())

        // clear items that should not be imported from the info plist
        item.sha256 = nil
        item.size = nil
        item.stats = nil

        return item
    }
}

public extension URL {
    /// Returns true if the given URL scheme can be opened on the current system
    ///
    /// Note: on iOS, the app's Info.plist must contain the requested scheme in the key: [LSApplicationQueriesSchemes](https://developer.apple.com/library/archive/documentation/General/Reference/InfoPlistKeyReference/Articles/LaunchServicesKeys.html#//apple_ref/doc/plist/info/LSApplicationQueriesSchemes)
    func canLaunchScheme() -> Bool {
        #if os(macOS)
        if #available(macOS 12.0, *) {
            return !NSWorkspace.shared.urlsForApplications(toOpen: self).isEmpty
        } else {
            return false // could use `LSCopyApplicationURLsForURL`
        }
        #elseif os(iOS)
        return UIApplication.shared.canOpenURL(self)
        #else
        return false
        #endif
    }
}

/// The repository name for the base fairground. It is "App".
public let baseFairgroundRepoName = "App"

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
            .appendingPathComponent(baseFairgroundRepoName)
            .appendingPathComponent(path ?? "")
    }
}

#if canImport(SwiftUI)

/// A container for an app, which manages a single app-wide state and provides views for the `rootScene` and `settingsView`.
@MainActor public protocol FairContainer {
    /// The store for this instance
    associatedtype AppManager : SceneManager

    associatedtype SceneBody : SwiftUI.Scene

    /// The root scene for new windows
    @SceneBuilder static func rootScene(store: AppManager) -> Self.SceneBody

    associatedtype SettingsBody : View
    /// The settings associated with this app
    @ViewBuilder static func settingsView(store: AppManager) -> Self.SettingsBody


    /// Launch the app, either in GUI or CLI form
    static func main() async throws

    /// Invokes the command-line form of the application when the app is run from a terminal
    static func cli(args: [String]) throws -> Bool
}

public extension FairContainer {
    /// The default cli is a no-op
    static func cli(args: [String]) throws -> Bool {
        false
    }
}

extension FairContainer where Self : SceneManager {
    public typealias ConfigFacets = Never
}

extension FairContainer where Self : SceneManager {
    public typealias AppFacets = Never
}

/// The `SceneManager` is an app-wide singleton that will be used at the root of each scene hierarchy.
///
/// A `SceneManager` is a `FacetManager` with the ability to create views
/// for the given
@MainActor public protocol SceneManager: FacetManager, ObservableObject where AppFacets : FacetView, ConfigFacets : FacetView  {
    /// Creates a new scene manager from scratch.
    init()

    /// The bundle this manager is associated with.
    var bundle: Bundle { get }
}

public extension SceneManager {
    /// The shared static configuration for the bundle of this instance, which is stored in the `App.yml` resource.
    ///
    /// The `config` property can be any `Decodable` type, such as `JSum` or a custom type that can be decoded from the contents of the YAML.
    ///
    /// - Parameter bundle: the bundle from which to load the resource (typically `.module`)
    /// - Returns: the decoded type parsed from the YAML file
    static func configuration<T: Decodable>(name: String, for bundle: Bundle) throws -> T {
        guard let url = bundle.url(forResource: name, withExtension: "yml", subdirectory: nil) else {
            throw AppError(String(format: NSLocalizedString("Unable to load resource named: “%@”", bundle: .module, comment: "error message"), name))
        }
        if try url.resourceValues(forKeys: [.isSymbolicLinkKey]).isSymbolicLink == true {
            dbg("configuration isSymbolicLink for:", name)
        }
        let source = try String(contentsOf: url, encoding: .utf8)
        let jsum = try JSum.parse(yaml: source)
        if T.self == JSum.self {
            return jsum as! T // optimization: no need to re-parse T if it is just a JSum
        } else {
            return try T(jsum: jsum, options: .init(dateDecodingStrategy: .iso8601, dataDecodingStrategy: .base64))
        }
    }
}

/// A action that is available from an app's icon, either the dock icon in macOS or the app's icon in iOS
public final class QuickAction: Identifiable {
    public let id: String
    public let localizedTitle: String
    public let localizedSubtitle: String?
    public let iconSymbol: String?
    public let block: (_ callback: @escaping (Bool) -> Void) -> ()

    public init(id: String, localizedTitle: String, localizedSubtitle: String? = nil, iconSymbol: String? = nil, block: @escaping (_ callback: @escaping (Bool) -> Void) -> ()) {
        self.id = id
        self.localizedTitle = localizedTitle
        self.localizedSubtitle = localizedSubtitle
        self.iconSymbol = iconSymbol
        self.block = block
    }
}

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

extension FairContainer {
    /// Check for CLI flags then launch as a `SwiftUI.App` app.
    @MainActor public static func launch(bundle: Bundle, sourceFile: StaticString = #file) async throws {
        // fileno(stdin) will be set only for tty launch or the debugger; the env "_" is additionally set to permit launching in Xcode debugger (where stdin is set)
        let isCLI = isatty(fileno(stdin)) == 1
            && ProcessInfo.processInfo.environment["_"] != "/usr/bin/open"
            && ProcessInfo.processInfo.environment["OS_ACTIVITY_DT_MODE"] != "YES"
        
        //var stderr = HandleStream(stream: .standardError)
        var stdout = HandleStream(stream: .standardOutput)

//        let args = Array(CommandLine.arguments.dropFirst())
//        if args.first == "fairtool" && isCLI {
//            FairTool.main(args)
//        } else {
            if FairCore.assertionsEnabled { // raise a warning if our app container is invalid
                validateEntitlements()
            }

            if isCLI == false { // launch the app itself
                dumpProcessInfo(bundle: bundle, &stdout) // always log the app info
                assert(Thread.isMainThread)
                FairContainerApp<Self>.main()
            } else { // invoke the command-line interface to the app
                if try Self.cli(args: CommandLine.arguments) == false {
                    // if the command-line interface fails, show the process info
                    dumpProcessInfo(bundle: bundle, &stdout)
                }
            }
//        }
    }

    public static func main() async throws {
        do {
            try await launch(bundle: Bundle.module)
        } catch {
            // we don't want to re-throw the exception here, since it will cause a crash report when run from AppContainer.main
            error.dumpError()

            // don't re-throw the error, since from the console since it can result in a confusing hardware fault message
            // throw error // re-throw
        }
    }

    private static func dumpProcessInfo<O: TextOutputStream>(bundle: Bundle, _ out: inout O) {
        //print("main.infoDictionary:", Bundle.main.infoDictionary)
        //print("bundle.infoDictionary:", bundle.infoDictionary)

        func infoValue<T>(_ key: PropertyListKey) -> T? {
            (Bundle.main.localizedInfoDictionary?[key.plistKey] as? T)
                ?? (Bundle.main.infoDictionary?[key.plistKey] as? T)
                ?? (bundle.localizedInfoDictionary?[key.plistKey] as? T)
                ?? (bundle.infoDictionary?[key.plistKey] as? T)
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
//        for entitlement in AppEntitlement.allCases {
//            if entitlement != AppEntitlement.app_sandbox {
//                if let entitlementValue = entitlement.entitlementValue(), entitlementValue != false as NSNumber {
//                    print(" Entitlement: " + entitlement.rawValue + "=" + entitlementValue.description, to: &out)
//                }
//            }
//        }
        #endif

        do {
            let packageResolved = try ResolvedPackage(json: bundle.loadResource(named: "Package.resolved"))
            for dep in packageResolved.rawValue.q?.pins ?? [] {
                let packageVersion = dep.state.version ?? dep.state.branch ?? "none"
                print("  Dependency: " + (dep.identity) + " " + packageVersion, to: &out)
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
}

public extension Error {
    func dumpError() {
        var out = HandleStream(stream: .standardOutput)
        dumpError(out: &out)
    }
}

private let mainAppCatalogInfo = Result { try Bundle.main.appCatalogInfo() }

/// Standard command list for Help / Issues / Discussions
public struct SupportCommands<LinkButton: View> : View {
    let builder: (Text, URL) -> LinkButton

    public init(builder: @escaping (Text, URL) -> LinkButton) {
        self.builder = builder
    }

    public var body: some View {
        supportCommandGroupView()
    }

    @ViewBuilder public func supportCommandGroupView() -> some View {
        if let home = Bundle.appHomeURL(for: Bundle.main) {
            builder(Text("Home", bundle: .module, comment: "command name for going to the app's home page"), home)
        }

        if let discussions = URL.fairHubURL("discussions") {
            builder(Text("Discussions", bundle: .module, comment: "command name for opening app discussions page"), discussions)
        }

        if let issues = URL.fairHubURL("issues") {
            builder(Text("Issues", bundle: .module, comment: "command name for opening app issues page"), issues)
        }
    }
}

fileprivate let checkForUpdatesURL: URL? = {
    if let url = Bundle.appFairURL(for: Bundle.main),
       url.canLaunchScheme() == true,
       Bundle.main.isCatalogBrowserApp == false {
        return url
    } else {
        return nil
    }
}()


// The top-level container in which the `SwiftUI.App` is implemented.
public struct FairContainerApp<Container: FairContainer> : SwiftUI.App {
    @UXApplicationDelegateAdaptor(AppDelegate.self) fileprivate var delegate
    @Environment(\.openURL) var openURL
    @Environment(\.scenePhase) var scenePhase
    @StateObject public var store = Container.AppManager()

    public init() {
    }

    @SceneBuilder public var body: some SwiftUI.Scene {
        let commands = Group {
            CommandGroup(after: CommandGroupPlacement.appSettings) {
                if let url = checkForUpdatesURL {
                    Link(destination: url) {
                        Text("Check for Updates", bundle: .module, comment: "text for command group to check for app updates")
                            .help(Text("Check for updates on the App Fair", bundle: .module, comment: "tooltip for command group to check for updates"))
                    }
                }
            }

            CommandGroup(replacing: CommandGroupPlacement.help) {
                SupportCommands(builder: { $0.link(to: $1) })

                #if os(macOS)
                Divider()

                Button {
                    NSPasteboard.general.clearContents()

                    if let window = NSApp.keyWindow ?? NSApp.mainWindow ?? NSApp.windows.first {
                        if let screenshot = window.takeSnapshot() {
                            dbg("created screenshot dimensions:", screenshot.size)
                            NSPasteboard.general.writeObjects([screenshot])
                        }
                    }
                } label: {
                    Text("Copy Screenshot to Clipboard", bundle: .module, comment: "help menu label for command to take a screenshot of the frontmost window")
                }
                #endif
            }
        }

        Group {
            Container.rootScene(store: store)
//                .onChange(of: scenePhase) { phase in
//                    switch phase {
//                    case .background:
//                        break;
//                    case .inactive:
//                        break;
//                    case .active:
//                        break;
//                    @unknown default:
//                        break;
//                    }
//                }
            #if os(macOS) // on
            Settings {
                Container.settingsView(store: store)
                    .withAppearanceSetting()
                    .withLocaleSetting()
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

}

private final class AppDelegate: NSObject, UXApplicationDelegate {
    /// The global quick actions installed on the app
    fileprivate static var quickActions: [QuickAction]? = nil

    #if canImport(AppKit)
    @objc func performQuickAction(_ sender: Any?) {
        dbg(sender)
        if let sender = sender as? NSMenuItem {
            guard let id = sender.identifier?.rawValue else {
                return dbg("no identifier for sender:", sender)
            }
            Self.invokeQuickAction(id: id) { success in
                dbg("invoked action \(id) with success:", success)
            }
        }
    }
    
    func applicationWillFinishLaunching(_ notification: Notification) {
        //dbg("applicationWillFinishLaunching")
        let info = Bundle.main.infoDictionary ?? [:]
        // if there is no icon set (e.g., while we are developing locally), auto-generate the icon that would be generated by the fair-ground
        if info["CFBundleIcons"] == nil && info["CFBundleIconFile"] == nil && info["CFBundleIconName"] == nil {
            let iconSpan = 512.0
            let appIconView = Bundle.fairIconView().iconView(for: iconSpan).padding(iconSpan / 10.0) // macOS icons are inset by 10%
            if let pngData = appIconView.png(bounds: nil) {
                NSApp.applicationIconImage = NSImage(data: pngData)
            }

            // alternatively, we can set the live view, which might allow us to perform animations and other effects
            // NSApp.dockTile.contentView = appIconView.viewWrapper()
            // NSApp.dockTile.display()
        }
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        //dbg("applicationDidFinishLaunching")
    }
    
    fileprivate static let dockMenu = NSMenu()
    
    func applicationDockMenu(_ sender: NSApplication) -> NSMenu? {
        Self.dockMenu
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
            
    fileprivate static var shortcutItem: UIApplicationShortcutItem?

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        if let shortcutItem = options.shortcutItem {
            AppDelegate.shortcutItem = shortcutItem
        }
        
        let sceneConfiguration = UISceneConfiguration(name: "Scene Configuration", sessionRole: connectingSceneSession.role)
        
        sceneConfiguration.delegateClass = SceneDelegate.self
        
        return sceneConfiguration
    }
    #endif
    
    static func invokeQuickAction(id: String, completionHandler: @escaping (Bool) -> Void) {
        guard let action = AppDelegate.quickActions?.first(where: { $0.id == id }) else {
            dbg("no QuickAction found for shortcutItem:", id)
            return completionHandler(false)
        }
        
        action.block(completionHandler)
    }
}

public extension Bundle {
    /// The icon embedded in this bundle's info
    static func fairIconView(color: Color? = Color.accentColor) -> FairIconView {
        FairIconView(paths: [Bundle.main.infoDictionary?["AppFairIconSymbol"] as? String].compactMap({ $0 }), iconColor: color)
    }
}

#if canImport(UIKit)
@available(iOS 15.0, *)
private final class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    func windowScene(_ windowScene: UIWindowScene, performActionFor shortcutItem: UIApplicationShortcutItem, completionHandler: @escaping (Bool) -> Void) {
        AppDelegate.invokeQuickAction(id: shortcutItem.type, completionHandler: completionHandler)
    }
}
#endif

/// Command to select the search bar using the CMD-F keyboard shortcut
/// The command will be installed in the `CommandGroupPlacement.textEditing` menu on macOS.
public struct SearchBarCommands: Commands {
    public init() {
    }

    public var body: some Commands {
        CommandGroup(after: CommandGroupPlacement.textEditing) {
            Section {
                #if os(macOS)
                Text("Search", bundle: .module, comment: "search command text").button {
                    dbg("activating search field")
                    // there's no official way to do this, so search the NSToolbar for the item and make it the first responder
                    if let window = UXApplication.shared.currentEvent?.window,
                       let toolbar = window.toolbar,
                       let searchField = toolbar.visibleItems?.compactMap({ $0 as? NSSearchToolbarItem }).first {
                        // <SwiftUI.AppKitSearchToolbarItem: 0x13a8721a0> identifier = "com.apple.SwiftUI.search"]
                        dbg("searchField:", searchField)
                        window.makeFirstResponder(searchField.searchField)
                    }
                }
                .keyboardShortcut("F")
                #endif
            }
        }
    }
}


extension SwiftUI.Text {
    /// Creates a Text from the given attributed string, falling back to the unformatted string if it fails to parse.
    ///
    /// - Parameters:
    ///   - attributedText: the markdown text that will attempt to be parsed
    ///   - languageCode: the optional language code
    ///   - attributes: any attributes to set on the text. E.g., `[.textEffect: NSAttributedString.TextEffectStyle.letterpressStyle]`
    @inlinable public init(atx attributedText: String, languageCode: String? = nil, attributes: AttributeContainer = AttributeContainer()) {
        do {
            let attributedString = try attributedText.atx(languageCode: languageCode)
            self.init(attributedString.settingAttributes(attributes))
        } catch {
            dbg("error parsing attributed text", attributedText.count, error)
            self.init(attributedText) // failure to parse will just display the formatted string raw
        }
    }

    /// Labels the given text with the given system symbol.
    public func label(symbol symbolName: String? = nil, color: Color? = nil) -> some View { // Label<Text, Image?> {
        label(image: symbolName.flatMap(Image.init(systemName:))?.foregroundColor(color))
    }

    /// Labels the given text with the given image.
    public func label<V: View>(image: V) -> Label<Text, V> {
        Label(title: { self }, icon: { image })
    }
}

extension SwiftUI.View {
    /// Creates a `Link` to the given URL.
    @ViewBuilder public func link(to destination: URL?, embedded: Bool = true) -> some View {
        if let destination = destination {
            #if os(iOS)
            if embedded {
                NavigationLink(destination: EmbeddedBrowser(url: destination)) {
                    self
                }
            } else {
                Link(destination: destination) {
                    self
                }
            }
            #else
            Link(destination: destination) {
                self
            }
            #endif
        } else {
            self
        }
    }

    /// Creates a `Link` to the given URL, or the Text itself if the link is `.none`.
    @available(*, deprecated)
    func linkDraggable(to destination: URL?, draggable: Bool = true) -> some View {
        Group {
            if let destination = destination {
                Link(destination: destination) {
                    self
                }
                .help(Text("Open link in browser: \(Text(verbatim: destination.absoluteString))", bundle: .module, comment: "open link tooltip text"))
                .onDrag { NSItemProvider(object: destination as NSURL) } // sadly, doesn't seem to work
            } else {
                self
            }
        }
    }

    /// Creates a `Button` with the given `action`.
    public func button(action: @escaping () -> ()) -> Button<Self> {
        Button(action: action) {
            self
        }
    }
}
#endif // canImport(SwiftUI)


#if canImport(SwiftUI)
public struct SplitDividerView : View {
    public init() {

    }

    public var body: some View {
        VStack(spacing: 0) {
            div()
            #if canImport(AppKit)
            //SplitDividerDragView().frame(maxHeight: 0)
            #endif
            div()
        }
    }

    private func div(width: CGFloat? = nil, height: CGFloat? = nil) -> some View {
        Divider()
        //.background(Color.secondary)
            .frame(width: width, height: height)
            .padding(.top, 0.5)
            .padding(.bottom, 0.5)
    }
}
#endif // canImport(SwiftUI)

#if canImport(AppKit)
// This is an attempt to fix the broken split view divider persistence bug in SwiftUI.
// It does not work.

//private struct SplitDividerDragView : UXViewRepresentable {
//    typealias UXViewType = UXView
//
//    func makeUXView(context: Context) -> UXViewType {
//        UXView(frame: .zero)
//    }
//
//    func updateUXView(_ view:  UXViewType, context: Context) {
//        for v in sequence(first: view, next: \.superview) {
//            if let split = v as? NSSplitView {
//                print("split:", v, "AUTOSAVE:", split.autosaveName ?? "none")
//                split.autosaveName = wip("MySplitView")
//                break
//            } else {
//                print("superview:", v)
//            }
//        }
//    }
//
//    static func dismantleUXView(_ view:  UXViewType, coordinator: Coordinator) {
//
//    }
//}
#endif


#if canImport(AppKit)
public extension NSWindow {
    /// Grab a snapshot of the given window
    func takeSnapshot() -> NSImage? {
        guard windowNumber != -1 else {
            dbg("bad window number")
            return nil
        }

        guard let cgImage = CGWindowListCreateImage(.null, .optionIncludingWindow, CGWindowID(windowNumber), []) else {
            return nil
        }

        return NSImage(cgImage: cgImage, size: frame.size)
    }
}
#endif

extension AppError {
    @available(*, unavailable, message: "use AppError(String(format: NSLocalizedString(XXX, bundle: .module, comment: XXX), param))")
    public init(_ title: StringLiteralType) {
        fatalError("should not initialize with literal string")
    }
}

/// A generic error
public struct AppError : LocalizedError {
    /// A localized message describing what error occurred.
    public let errorDescription: String?

    /// A localized message describing the reason for the failure.
    public let failureReason: String?

    /// A localized message describing how one might recover from the failure.
    public let recoverySuggestion: String?

    /// A localized message providing "help" text if the user requests help.
    public let helpAnchor: String?

    /// An underlying error
    public let underlyingError: Error?

    @available(*, deprecated, message: "use error message constructor")
    public init(function: StaticString = #function, file: StaticString = #file, line: UInt = #line) {
        self.init("Error at \(function) in \(file):\(line)")
    }

    public init(_ errorDescription: String, failureReason: String? = nil, recoverySuggestion: String? = nil, helpAnchor: String? = nil, underlyingError: Error? = nil) {
        self.errorDescription = errorDescription
        self.failureReason = failureReason
        self.recoverySuggestion = recoverySuggestion
        self.helpAnchor = helpAnchor
        self.underlyingError = underlyingError
    }

    public init(_ error: Error) {
        if let error = error as? AppError {
            self.errorDescription = error.errorDescription
            self.failureReason = error.failureReason
            self.recoverySuggestion = error.recoverySuggestion
            self.helpAnchor = error.helpAnchor
            self.underlyingError = error.underlyingError
        } else {
            #if canImport(AppKit) || canImport(UIKit)
            let nsError = error as NSError
            self.errorDescription = nsError.localizedDescription
            self.failureReason = nsError.localizedFailureReason
            self.recoverySuggestion = nsError.localizedRecoverySuggestion
            self.helpAnchor = nsError.helpAnchor
            if #available(macOS 11.3, iOS 14.5, *) {
                self.underlyingError = nsError.underlyingErrors.first
            } else {
                self.underlyingError = nil
            }
            #else // NSError bridge on other platforms does not expose properties
            if let locError = error as? LocalizedError {
                self.errorDescription = locError.errorDescription
                self.failureReason = locError.failureReason
                self.recoverySuggestion = locError.recoverySuggestion
                self.helpAnchor = locError.helpAnchor
                self.underlyingError = nil
            } else {
                self.errorDescription = error.localizedDescription
                self.failureReason = nil
                self.recoverySuggestion = nil
                self.helpAnchor = nil
                self.underlyingError = nil
            }
            #endif
        }
    }
}

public struct ResolvedPackage : RawCodable, Codable {
    public var rawValue: XOr<ResolvedPackageV1>.Or<ResolvedPackageV2>

    public var version: Int { rawValue.map(\.version.rawValue, \.version.rawValue).value }

    public init(rawValue: XOr<ResolvedPackageV1>.Or<ResolvedPackageV2>) {
        self.rawValue = rawValue
    }

    /// The contents of a `Package.resolved` version 1 file
    public struct ResolvedPackageV1: Codable, Equatable {
        public enum Version : Int, Codable { case v1 = 1 }
        public var version: Version
        public var object: Pins

        public struct Pins: Codable, Equatable {
            public var pins: [SwiftPackage]
        }

        public struct SwiftPackage: Codable, Equatable {
            public var package: String
            public var repositoryURL: String
            public var state: PackageState
        }
    }

    /// The contents of a `Package.resolved` version 2 file
    public struct ResolvedPackageV2: Codable, Equatable {
        public enum Version : Int, Codable { case v2 = 2 }
        public var version: Version
        public var pins: [SwiftPackage]

        public struct SwiftPackage: Codable, Equatable {
            public var identity: String
            public var kind: String
            public var location: String
            public var state: PackageState

        }
    }

    public struct PackageState: Codable, Equatable {
        public var branch: String?
        public var revision: String
        public var version: String?
    }

}


/// An asset name is a convention for naming files based on the contents of the image file.
///
/// e.g.: `preview-iphone-800x600.mp4`
/// e.g.: `appicon-ipad-83.5x83.5@2x.png`
/// e.g.: `screenshot-mac-dark-1024x777.png`
public struct AssetName : Hashable {
    /// The base name of the application
    public let base: String
    /// The idiom of the image, which is context-dependent
    public let idiom: String?
    /// The width specified by the asset name
    public let width: Double
    /// The height specified by the asset name
    public let height: Double
    /// The scale, if specified in the asset name
    public let scale: Int?
    /// The file-type extension of the asset
    public let ext: String

    public init(base: String, idiom: String?, width: Double, height: Double, scale: Int?, ext: String) {
        self.base = base
        self.idiom = idiom
        self.width = width
        self.height = height
        self.scale = scale
        self.ext = ext
    }
}

extension AssetName {
    /// Initialized this asset name by parsing a string in the expected form.
    /// - Parameter string: the asset path name to interpret
    public init(string: String) throws {
        var str = string

        let fail = {
            AppError(NSLocalizedString("Unable to parse asset name in the expected format: image_name-IDIOM-WxH@SCALEx.EXT", bundle: .module, comment: "error message"))
        }

        func consume(segment char: Character, after: Bool = true) throws -> String {
            let parts = str.split(separator: char)
            guard let part = (after ? parts.last : parts.first), parts.count > 1 else {
                throw AppError(String(format: NSLocalizedString("Unable to parse character “%@” for asset name: “%@”", bundle: .module, comment: "error message"), char.description, string))
            }
            str = String(after ? str.dropLast(part.count + 1) : str.dropFirst(part.count + 1))
            return String(part)
        }

        let ext = try consume(segment: ".")
        if !(3...4).contains(ext.count) {
            throw fail() // extensions must be 3 or 4 characters
        }

        let scale: Int?
        // if it ends in "@
        if let trailing = try? consume(segment: "@") {
            guard let s = Int(trailing.dropLast(1)), s > 0, s <= 3 else {
                throw fail()
            }
            scale = s
        } else {
            scale = nil
        }

        guard let height = try Double(consume(segment: "x")) else {
            throw fail()
        }
        guard let width = try Double(consume(segment: "-")) else {
            throw fail()
        }

        if let imgname = try? String(consume(segment: "-", after: false)) {
            self.init(base: imgname, idiom: str, width: width, height: height, scale: scale, ext: ext)
        } else {
            self.init(base: str, idiom: nil, width: width, height: height, scale: scale, ext: ext)
        }
    }

    /// The size encoded in the asset name, applying a scaling factor if it is defined
    public var size: CGSize {
        if let scale = self.scale {
            return CGSize(width: width * .init(scale), height: height * .init(scale))
        } else {
            return CGSize(width: width, height: height)
        }

    }
}

/// The contents of an accent color definition.
/// Handles parsing the known variants of the `Assets.xcassets/AccentColor.colorset/Contents.json` file.
public struct AccentColorList : Decodable {
    public var info: Info
    public var colors: [ColorEntry]

    public struct Info: Decodable {
        public var author: String
        public var version: Int
    }

    public struct ColorEntry: Decodable {
        public var idiom: String
        public var color: ColorItem?
        public var appearances: [Appearance]?
    }

    public struct Appearance : Decodable {
        public var appearance: String // e.g., "luminosity"
        public var value: String? // e.g., "dark"
    }

    public struct ColorItem : Decodable {
        public var platform: String? // e.g., "universal"
        public var reference: String? // e.g., "systemGreenColor"
        public var colorspace: String?
        public var components: ColorComponents?

        public var rgba: (r: Double, g: Double, b: Double, a: Double)? {
            func coerce(_ numberString: String) -> Double? {
                if numberString.hasPrefix("0x") && numberString.count == 4 {
                    guard let hexInteger = Int(numberString.dropFirst(2), radix: 16) else {
                        return nil
                    }
                    return Double(hexInteger) / 255.0
                } else if numberString.contains(".") {
                    return Double(numberString) // 0.0-1.0
                } else { // otherwise it is just an integer
                    guard let numInteger = Int(numberString) else {
                        return nil
                    }
                    return Double(numInteger) / 255.0
                }
            }

            func parseColor(_ r: String, _ g: String, _ b: String, _ a: String = "0xFF") -> (Double, Double, Double, Double) {
                (coerce(r) ?? 0.5, coerce(g) ?? 0.5, coerce(b) ?? 0.5, coerce(a) ?? 1.0)
            }

            #if canImport(SwiftUI)
            // these system colors are (or, at least, can be) context-dependent and may change between OS verisons; we could try to grab the equivalent SwiftUI color and extract its RGB values here
            #endif

            switch reference {
            case "systemBlueColor": return parseColor("0x00", "0x7A", "0xFF")
            case "systemBrownColor": return parseColor("0xA2", "0x84", "0x5E")
            case "systemCyanColor": return parseColor("0x32", "0xAD", "0xE6")
            case "systemGrayColor": return parseColor("0x8E", "0x8E", "0x93")
            case "systemGreenColor": return parseColor("0x34", "0xC7", "0x59")
            case "systemIndigoColor": return parseColor("0x58", "0x56", "0xD6")
            case "systemMintColor": return parseColor("0x00", "0xC7", "0xBE")
            case "systemOrangeColor": return parseColor("0xFF", "0x95", "0x00")
            case "systemPinkColor": return parseColor("0xFF", "0x2D", "0x55")
            case "systemPurpleColor": return parseColor("0xAF", "0x52", "0xDE")
            case "systemRedColor": return parseColor("0xFF", "0x3B", "0x30")
            case "systemTealColor": return parseColor("0x30", "0xB0", "0xC7")
            case "systemYellowColor": return parseColor("0xFF", "0xCC", "0x00")
            default: break
            }

            if let components = components {
                return parseColor(components.red, components.green, components.blue, components.alpha)
            }

            return nil // no color constant or value found
        }

        public enum CodingKeys : String, CodingKey {
            case platform
            case reference
            case colorspace = "color-space"
            case components
        }
    }

    public struct ColorComponents : Decodable {
        public var alpha: String // e.g. "1.000"
        public var red: String // e.g., "0x34"
        public var green: String // e.g., "0xC7"
        public var blue: String // e.g. "0x59"
    }

    public var firstRGBHex: String? {
        firstRGBAColor.flatMap { rgba in
            String(format: "%02X%02X%02X", Int(rgba.r * 255.0), Int(rgba.g * 255.0), Int(rgba.b * 255.0))
        }
    }

    public var firstRGBAColor: (r: Double, g: Double, b: Double, a: Double)? {
        colors.compactMap(\.color?.rgba).first
    }
}

/// The contents of an icon set.
///
/// Handles parsing the known variants of the `Assets.xcassets/AppIcon.appiconset/Contents.json` file.
public struct AppIconSet : Equatable, Codable {
    public var info: Info
    public var images: [ImageEntry]

    public struct Info: Equatable, Codable {
        public var author: String
        public var version: Int
    }

    public struct ImageEntry: Equatable, Codable {
        public var idiom: String? // e.g., "watch"
        public var scale: String? // e.g., "2x"
        public var role: String? // e.g., "quickLook"
        public var size: String? // e.g., "50x50"
        public var subtype: String? // e.g. "38mm"
        public var filename: String? // e.g. "172.png"

        /// The path for the image, of the form: `idiom-size@scale`
        public var standardPath: String {
            var path = ""
            if let idiom = idiom {
                path += idiom + "-"
            }

            if let size = size {
                path += size
            }

            if let scale = scale {
                path += "@" + scale
            }


            return path
        }
    }
}

public extension AppIconSet {
    /// Images with the matching properties
    func images(idiom: String? = nil, scale: String? = nil, size: String? = nil) -> [ImageEntry] {
        images.filter { imageEntry in
            (idiom == nil || imageEntry.idiom == idiom)
            && (scale == nil || imageEntry.scale == scale)
            && (size == nil || imageEntry.size == size)
        }
    }
}


/// A representation of a hex color with integer red, green, blue, and alpha components.
public struct HexColor : Hashable {
    public let r, g, b: Int
    public let a: Int?

    public init(r: Int, g: Int, b: Int, a: Int? = nil) {
        self.r = r
        self.g = g
        self.b = b
        self.a = a
    }
}

public extension HexColor {
    /// Creates a `HexColor` by parsing the given hex string, which optionally may be preceeded by a "#".
    init?(hexString: String) {
        var str = hexString.dropFirst(0)
        if str.hasPrefix("#") {
            str = str.dropFirst()
        }

        let chars = Array(str)

        if str.count != 6 && str.count != 8 {
            return nil
        }

        guard let red = Int(String([chars[0], chars[1]]), radix: 16) else {
            return nil
        }
        self.r = red

        guard let green = Int(String([chars[2], chars[3]]), radix: 16) else {
            return nil
        }
        self.g = green

        guard let blue = Int(String([chars[4], chars[5]]), radix: 16) else {
            return nil
        }
        self.b = blue

        if str.count == 8 {
            guard let alpha = Int(String([chars[6], chars[7]]), radix: 16) else {
                return nil
            }
            self.a = alpha
        } else {
            self.a = nil
        }
    }

    func colorString(hashPrefix: Bool) -> String {
        let h = hashPrefix ? "#" : ""
        if let a = a {
            return h + String(format: "%02X%02X%02X%02X", r, g, b, a)
        } else {
            return h + String(format: "%02X%02X%02X", r, g, b)
        }
    }
}


/// An encodable color, which can use either a system color name (e.g. `accent` or `pink`) or a hex string.
public struct CodableColor : Codable, Hashable, Sendable {
    public typealias HexString = String
    public let color: XOr<SystemColor>.Or<HexString>

    public init(_ color: SystemColor) {
        self.color = .init(color)
    }

    #if canImport(SwiftUI)
    public var systemColor: SwiftUI.Color? {
        switch color {
        case .p(let color): return color.systemColor
        case .q(let hex): return HexColor(hexString: hex)?.sRGBColor()
        }
    }
    #endif

    /// The system accent color
    public static let accentColor = CodableColor(SystemColor.accent)

    /// The system colors, in the order they could be displayed in a picker
    public static var nominalColors = [
        .orange,
        .mint,
        .indigo,
        .cyan,
        .pink,
        .teal,
        .brown,
        .blue,
        .green,
        .red,
        .purple,
    ].map(CodableColor.init)

    /// Enumeration definit system UI colors
    public enum SystemColor : String, Codable, CaseIterable, Sendable {
        case red
        case orange
        case yellow
        case green
        case mint
        case teal
        case cyan
        case blue
        case indigo
        case purple
        case pink
        case brown
        case white
        case gray
        case black
        case clear
        case primary
        case secondary
        case accent

        #if canImport(SwiftUI)
        public var systemColor: SwiftUI.Color {
            switch self {
            case .red: return .red
            case .orange: return .orange
            case .yellow: return .yellow
            case .green: return .green
            case .mint: return .mint
            case .teal: return .teal
            case .cyan: return .cyan
            case .blue: return .blue
            case .indigo: return .indigo
            case .purple: return .purple
            case .pink: return .pink
            case .brown: return .brown
            case .white: return .white
            case .gray: return .gray
            case .black: return .black
            case .clear: return .clear
            case .primary: return .primary
            case .secondary: return .secondary
            case .accent: return .accentColor
            }
        }
        #endif
    }
}


#if canImport(SwiftUI)
extension ButtonStyle where Self == ZoomableButtonStyle {
    /// A button style that scales the button out when pressed
    public static var zoomable: ZoomableButtonStyle {
        ZoomableButtonStyle()
    }

    /// A button style that scales the button out when pressed
    public static func zoomable(level: Double = 0.98) -> ZoomableButtonStyle {
        ZoomableButtonStyle(zoomLevel: level)
    }
}

public struct ZoomableButtonStyle: ButtonStyle {
    var zoomLevel = 0.98

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? zoomLevel : 1, anchor: .center)
    }
}
#endif // canImport(SwiftUI)

extension String {
    /// Checks whether the string contains the given regular expression.
    /// - Parameters:
    ///   - regex: the expression to parse
    ///   - expressionOptions: options like `.caseInsensitive` and `.anchorsMatchLines`
    ///   - matchingOptions: options like `.anchored`
    /// - Returns: whether the string matches or not
    @inlinable public func matches(regex: String, expressionOptions: NSRegularExpression.Options? = nil, matchingOptions: NSRegularExpression.MatchingOptions = []) throws -> Bool {
        let regex = try NSRegularExpression(pattern: regex, options: expressionOptions ?? [])
        return regex.matches(in: self, options: matchingOptions, range: self.span).isEmpty == false
    }
}

#if canImport(NaturalLanguage)
import NaturalLanguage

extension String {
    /// An estimate of the number words in the given string.
    public var wordCount: Int {
        let tokenizer = NLTokenizer(unit: .word)
        tokenizer.string = self
        var wordCount = 0
        tokenizer.enumerateTokens(in: startIndex..<endIndex) { tokenRange, _ in
            wordCount += 1
            return true
        }
        return wordCount
    }
}
#else
extension String {
    /// An estimate of the number words in the given string.
    ///
    /// When NaturalLanguage is not available, this merely splits on whitespace and newlines and returns the count, with is a decent approximation for many Western languages.
    public var wordCount: Int {
        components(separatedBy: .whitespacesAndNewlines).count
    }
}
#endif

#if canImport(SwiftUI)
public extension HexColor {
    func sRGBColor() -> Color {
        if let alpha = self.a {
            return Color(.sRGB, red: Double(self.r) / 255.0, green: Double(self.g) / 255.0, blue: Double(self.b) / 255.0, opacity: Double(alpha) / 255.0)
        } else {
            return Color(.sRGB, red: Double(self.r) / 255.0, green: Double(self.g) / 255.0, blue: Double(self.b) / 255.0)
        }
    }
}
#endif


/// Shim to work around crash with accessing ``Bundle.module`` from a command-line tool.
///
/// Ideally, we could enable this only when compiling into a single tool
internal func NSLocalizedString(_ key: String, tableName: String? = nil, bundle: @autoclosure () -> Bundle, value: String = "", comment: String) -> String {

    if moduleBundle == nil {
        // No bundle was found, so we are missing our localized resources.
        // Simple
        return key
    }

    // Runtime crash: FairExpo/resource_bundle_accessor.swift:11: Fatal error: could not load resource bundle: from /usr/local/bin/Fair_FairExpo.bundle or /private/tmp/fairtool-20220720-3195-1rk1z7r/.build/x86_64-apple-macosx/release/Fair_FairExpo.bundle

    return Foundation.NSLocalizedString(key, tableName: tableName, bundle: bundle(), value: value, comment: comment)
}
/// #endif

/// The same logic as the generated `resource_bundle_accessor.swift`,
/// so we can check it without crashing with a `fataError`.
private let moduleBundle = Bundle(url: Bundle.main.bundleURL.appendingPathComponent("Fair_FairApp.bundle"))


/// Work-in-Progress marker.
///
/// This function returns the value of the parameter unmodified.
/// It merely serves to raise a warning that the given code should be re-visited.
@available(*, deprecated, message: "work in progress")
@inlinable public func wip<T>(_ value: T) -> T { value }

// MARK: Package-Specific Utilities

/// Returns the localized string for the current module.
///
/// - Note: This is boilerplate package-local code that could be copied
///  to any Swift package with localized strings, but cannot be used across modules since
///    `Bundle.module` won't resolve to the callers bundle.
internal func loc(_ key: StaticString, locale: Locale = .current, bundle: Bundle = .module, tableName: String? = nil, comment: StaticString = "") -> String {
    NSLocalizedString(key.description, bundle: bundle.path(forResource: locale.languageCode, ofType: "lproj").flatMap(Bundle.init(path:)) ?? bundle, comment: comment.description)

}
