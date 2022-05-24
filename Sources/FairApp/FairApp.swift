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

#if canImport(SwiftUI)
/// A container for an app, which manages a single app-wide state and provides views for the `rootScene` and `settingsView`.
@available(macOS 12.0, iOS 15.0, *)
@MainActor public protocol FairContainer {
    /// The store for this instance
    associatedtype AppStore : SceneManager

    associatedtype SceneBody : SwiftUI.Scene

    /// The root scene for new windows
    @SceneBuilder static func rootScene(store: Self.AppStore) -> Self.SceneBody

    associatedtype SettingsBody : View
    /// The settings associated with this app
    @ViewBuilder static func settingsView(store: Self.AppStore) -> Self.SettingsBody

    
    /// Launch the app, either in GUI or CLI form
    static func main() async throws

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
    
    /// The actions available globally to this scene
    open var quickActions: [QuickAction] = []
}
#else
@available(macOS 11.0, iOS 14.0, *)
open class SceneManager: ObservableObject {
    /// Must have a no-arg initializer
    public required init() { }

    /// The actions available globally to this scene
    open var quickActions: [QuickAction] = []
}
#endif

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

@available(macOS 12.0, iOS 15.0, *)
extension FairContainer {
    /// Check for CLI flags then launch as a `SwiftUI.App` app.
    public static func launch(bundle: Bundle, sourceFile: StaticString = #file) async throws {
        // fileno(stdin) will be set only for tty launch or the debugger; the env "_" is additionally set to permit launching in Xcode debugger (where stdin is set)
        let isCLI = isatty(fileno(stdin)) == 1
            && ProcessInfo.processInfo.environment["_"] != "/usr/bin/open"
            && ProcessInfo.processInfo.environment["OS_ACTIVITY_DT_MODE"] != "YES"
        
        //var stderr = HandleStream(stream: .standardError)
        var stdout = HandleStream(stream: .standardOutput)

        let args = Array(CommandLine.arguments.dropFirst())
        if args.first == "fairtool" && isCLI {
            try await FairTool(arguments: args).runCLI()
        } else {
            if FairCore.assertionsEnabled { // raise a warning if our app container is invalid
                validateEntitlements()
            }

            if isCLI == false { // launch the app itself
                dumpProcessInfo(bundle: bundle, &stdout) // always log the app info
                FairContainerApp<Self>.main()
            } else { // invoke the command-line interface to the app
                if try Self.cli(args: CommandLine.arguments) == false {
                    // if the command-line interface fails, show the process info
                    dumpProcessInfo(bundle: bundle, &stdout)
                }
            }
        }
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

        func infoValue<T>(_ key: InfoPlistKey) -> T? {
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
}

@available(macOS 12.0, iOS 15.0, *)
public struct FairContainerApp<Container: FairContainer> : SwiftUI.App {
    @UXApplicationDelegateAdaptor(AppDelegate.self) fileprivate var delegate
    @Environment(\.openURL) var openURL
    @Environment(\.scenePhase) var scenePhase
    @StateObject public var store: Container.AppStore

    public init() {
        self._store = .init(wrappedValue: Container.AppStore())
    }

    @SceneBuilder public var body: some SwiftUI.Scene {
        let commands = Group {
            CommandGroup(after: CommandGroupPlacement.appSettings) {
                if let url = Bundle.appFairURL(for: Bundle.main),
                    url.canLaunchScheme() == true,
                   Bundle.main.isCatalogBrowserApp == false {
                    Link(destination: url) {
                        Text("Check for Updates", bundle: .module, comment: "text for command group to check for app updates")
                            .help(Text("Check for updates on the App Fair", bundle: .module, comment: "tooltip for command group to check for updates"))
                    }
                }
            }

            CommandGroup(replacing: CommandGroupPlacement.help) {
                if let home = Bundle.appHomeURL(for: Bundle.main) {
                    Text("Home", bundle: .module).link(to: home)
                }
                linkButton(Text("Discussions", bundle: .module, comment: "command name for opening app discussions page"), path: "discussions")
                linkButton(Text("Issues", bundle: .module, comment: "command name for opening app issues page"), path: "issues")

                #if os(macOS)
                Divider()

                Button {
                    NSPasteboard.general.clearContents()

                    if let window = NSApp.keyWindow ?? NSApp.mainWindow ?? NSApp.windows.first {
                        if let screenshot = window.takeSnapshot() {
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
                .onChange(of: scenePhase) { phase in
                    // update the app delegate's quick actions if needed
                    AppDelegate.installQuickActions {
                        store.quickActions
                    }
                    
                    switch phase {
                    case .background:
                        break;
                    case .inactive:
                        break;
                    case .active:
                        break;
                    @unknown default:
                        break;
                    }
                }
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

    func linkButton(_ title: Text, path: String? = nil) -> some View {
        Group {
            if let url = URL.fairHubURL(path) {
                title.link(to: url)
            }
        }
    }
}

#if canImport(AppKit)
@available(macOS 11, *)
typealias UXApplicationDelegateAdaptor = NSApplicationDelegateAdaptor
typealias UXApplicationDelegate = NSApplicationDelegate
#elseif canImport(UIKit)
typealias UXApplicationDelegateAdaptor = UIApplicationDelegateAdaptor
typealias UXApplicationDelegate = UIApplicationDelegate
#endif

@available(macOS 12.0, iOS 15.0, *)
private final class AppDelegate: NSObject, UXApplicationDelegate {
    /// The global quick actions installed on the app
    fileprivate static var quickActions: [QuickAction]? = nil
    
    /// Adds the given `[QuickAction]` array to the list of available actions.
    static func installQuickActions(actions: () -> [QuickAction]) {
        if quickActions != nil {
            return
        }
        
        let acts = actions()
        self.quickActions = acts
        
        #if canImport(UIKit)
        // on iOS, quick actions are added as
        let items = acts.map { action in
            UIApplicationShortcutItem(type: action.id, localizedTitle: action.localizedTitle, localizedSubtitle: action.localizedSubtitle, icon: action.iconSymbol.flatMap(UIApplicationShortcutIcon.init(systemImageName:)), userInfo: [:])
        }

        UIApplication.shared.shortcutItems = items
        #endif
        
        #if canImport(AppKit)
        for action in acts {
            let menuItem = NSMenuItem(title: action.localizedTitle, action: #selector(performQuickAction), keyEquivalent: "")
            // the action's identifier is stored as the menu item's identifier
            menuItem.identifier = .init(rawValue: action.id)
            
            // the dock menu seems to ignore both the image and tooltip for items, so this doesn't seem to do anything
            if let symbol = action.iconSymbol {
                menuItem.image = NSImage(systemSymbolName: symbol, accessibilityDescription: action.localizedTitle)
            }
            if let subtitle = action.localizedSubtitle {
                menuItem.toolTip = subtitle
            }
            dockMenu.addItem(menuItem)
        }
        #endif
    }
    
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
            let appIconView = createAppIconView(span: iconSpan).padding(iconSpan / 10.0) // macOS icons are inset by 10%
            if let pngData = appIconView.png(bounds: nil) {
                NSApp.applicationIconImage = NSImage(data: pngData)
            }

            // alternatively, we can set the live view, which might allow us to perform animations and other effects
            // NSApp.dockTile.contentView = appIconView.viewWrapper()
            // NSApp.dockTile.display()
        }
    }

    private func createAppIconView(span: CGFloat) -> some View {
        var paths: [String] = []

        //let tint = Bundle.main.infoDictionary?["AppFairIconTint"] as? String

        if let symbol = Bundle.main.infoDictionary?["AppFairIconSymbol"] as? String {
            paths.append(symbol)
        }

        // TODO: Color.accentColor doesn't seem to work since we can't parse out the hue from a system color; we may need to parse the Assets directly
        return FairIconView(Bundle.main.bundleName ?? "", subtitle: "", paths: paths, iconColor: Color.accentColor).iconView(for: span)
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
@available(macOS 12.0, iOS 15.0, *)
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
                    if let window = NSApp.currentEvent?.window,
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

    /// Labels the given text with the given image.
    public func label<V: View>(image: V) -> Label<Text, V> {
        Label(title: { self }, icon: { image })
    }
}

@available(macOS 12.0, iOS 15.0, *)
extension SwiftUI.View {
    /// Creates a `Link` to the given URL.
    public func link(to destination: URL) -> Link<Self> {
        Link(destination: destination) {
            self
        }
    }

    /// Creates a `Link` to the given URL, or the Text itself if the link is `.none`.
    public func link(to destination: URL?, draggable: Bool = true) -> some View {
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

@available(macOS 12.0, iOS 15.0, *)
extension SwiftUI.TextField {
    /// Creates a `Link` to the given URL and overlays it over the trailing end of the field.
    public func overlink(to destination: URL?, image: Image = FairSymbol.arrowshape_turn_up_right_circle_fill.image) -> some View {
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


extension ObservableObject {
    /// Create a view based on changes to this `ObservableObject`.
    /// Ths is typically unnecessary when the instance itself if being observed,
    /// but when an observed object is being tracked by a `.focusedSceneVaule`,
    /// changes in the view's properties do not trigger a state refresh, which can result in
    /// command properties (e.g., disabled) not being updated until the scene itself re-evaluates.
    public func observing<V: View>(@ViewBuilder builder: @escaping (Self) -> V) -> some View {
        ObservedStateView(state: self, builder: builder)
    }
}

/// A pass-through view builder that tracks the given `ObservableObject`.
/// This is needed for creating `SwiftUI.Command` instances based on a `FocusedValue`,
/// because while the focused value will be updated when the instance itself changes (e.g.,
/// when a scene vanges the focused scene value), the value itself will not trigger a change.
private struct ObservedStateView<O: ObservableObject, V : View> : View {
    @ObservedObject var state: O
    var builder: (O) -> V

    public var body: some View {
        builder(state)
    }
}

#endif // canImport(SwiftUI)

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


public extension UsageDescriptionKeys {
    var description: LocalizedStringKey {
        switch self {
        case .NSSiriUsageDescription: return "Siri"
        case .NSSpeechRecognitionUsageDescription: return "Speech Recognition"
        case .NSMicrophoneUsageDescription: return "Microphone"
        case .NSCameraUsageDescription: return "Camera"
        case .NSMotionUsageDescription: return "Motion"
        case .NFCReaderUsageDescription: return "NFC Reader"
        case .NSBluetoothUsageDescription: return "Bluetooth"
        case .NSBluetoothAlwaysUsageDescription: return "Bluetooth (Always)"
        case .NSBluetoothPeripheralUsageDescription: return "Bluetooth (peripheral)"
        case .NSRemindersUsageDescription: return "Reminders"
        case .NSContactsUsageDescription: return "Contacts"
        case .NSCalendarsUsageDescription: return "Calendars"
        case .NSPhotoLibraryAddUsageDescription: return "Photo Library Add"
        case .NSPhotoLibraryUsageDescription: return "Photo Library"
        case .NSAppleMusicUsageDescription: return "Apple Music"
        case .NSHomeKitUsageDescription: return "HomeKit"
            //case .NSVideoSubscriberAccountUsageDescription: return "Video Subscriber Account Usage"
        case .NSHealthShareUsageDescription: return "Health Sharing"
        case .NSHealthUpdateUsageDescription: return "Health Update"
        case .NSAppleEventsUsageDescription: return "Apple Events"
        case .NSFocusStatusUsageDescription: return "Focus Status"
        case .NSLocalNetworkUsageDescription: return "Local Network"
        case .NSFaceIDUsageDescription: return "Face ID"
        case .NSLocationUsageDescription: return "Location"
        case .NSLocationAlwaysUsageDescription: return "Location (Always)"
        case .NSLocationTemporaryUsageDescriptionDictionary: return "Location (Temporary)"
        case .NSLocationWhenInUseUsageDescription: return "Location (When in use)"
        case .NSLocationAlwaysAndWhenInUseUsageDescription: return "Location (Always)"
        case .NSUserTrackingUsageDescription: return "User Tracking"
        case .NSNearbyInteractionAllowOnceUsageDescription:
            return "Nearby Interaction (Once)"
        }
    }

    var icon: FairSymbol {
        switch self {
        case .NSSiriUsageDescription: return .ear
        case .NSSpeechRecognitionUsageDescription: return .waveform
        case .NSMicrophoneUsageDescription: return .mic_circle
        case .NSCameraUsageDescription: return .camera
        case .NSMotionUsageDescription: return .gyroscope
        case .NFCReaderUsageDescription: return .barcode_viewfinder
        case .NSBluetoothUsageDescription: return .cable_connector
        case .NSBluetoothAlwaysUsageDescription: return .cable_connector_horizontal
        case .NSBluetoothPeripheralUsageDescription: return .printer
        case .NSRemindersUsageDescription: return .text_badge_checkmark
        case .NSContactsUsageDescription: return .person_text_rectangle
        case .NSCalendarsUsageDescription: return .calendar
        case .NSPhotoLibraryAddUsageDescription: return .text_below_photo_fill
        case .NSPhotoLibraryUsageDescription: return .photo
        case .NSAppleMusicUsageDescription: return .music_note
        case .NSHomeKitUsageDescription: return .house
            //case .NSVideoSubscriberAccountUsageDescription: return .sparkles_tv
        case .NSHealthShareUsageDescription: return .stethoscope
        case .NSHealthUpdateUsageDescription: return .stethoscope_circle
        case .NSAppleEventsUsageDescription: return .scroll
        case .NSFocusStatusUsageDescription: return .eyeglasses
        case .NSLocalNetworkUsageDescription: return .network
        case .NSFaceIDUsageDescription: return .viewfinder
        case .NSLocationUsageDescription: return .location_magnifyingglass
        case .NSLocationAlwaysUsageDescription: return .location_fill
        case .NSLocationTemporaryUsageDescriptionDictionary: return .location
        case .NSLocationWhenInUseUsageDescription: return .location_north
        case .NSLocationAlwaysAndWhenInUseUsageDescription: return .location_fill_viewfinder
        case .NSUserTrackingUsageDescription: return .eyes
        case .NSNearbyInteractionAllowOnceUsageDescription:
                return .person_badge_clock_fill
        }
    }
}

/// Work-in-Progress marker
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
