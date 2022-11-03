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
import Foundation

/// A ``FacetManager`` defines the top-level and settings-level ``Facet``s for an app.
public protocol FacetManager {
    /// The top-level facets for this app.
    associatedtype AppFacets : Facet

    /// The settings-level facets for this app. These will be merged with standard app settings when showing a settings facet.
    associatedtype ConfigFacets : Facet

    /// The bundle associated with this manager
    var bundle: Bundle { get }
}

/// A facet is a logical section of an app, either a top-level navigation feature (tabs on iOS, outline list items on macOS along with menus),
/// or a secondary-level feature (navigation items on iOS, settings tabs on macOS).
///
/// By convention, the initial element of the `CaseIterable` list will be a welcome view that will be initially displayed by the app.
///
/// The final tab will be the settings tab, which is shown as a tab on iOS and is included in the standard settings window on macOS.
public protocol Facet : Hashable {
    /// Accesses the given facets for the specified scene manager.
    static func facets<Manager: FacetManager>(for manager: Manager) -> [Self]
}


extension Facet {
    /// Composition of one facet with another
    public typealias With<F: Facet> = MultiFacet<Self, F>
}

/// A multi-facet is a composition of multiple facets.
///
/// The implementation of `facets` will go through all the available facets.
public struct MultiFacet<P : Facet, Q : Facet> : Facet {
    public typealias Choice = XOr<P>.Or<Q>
    public let choice: Choice

    public init(choice: XOr<P>.Or<Q>) {
        self.choice = choice
    }

    public static func facets<Manager: FacetManager>(for manager: Manager) -> [Self] {
        (P.facets(for: manager).map(Choice.p) + Q.facets(for: manager).map(Choice.q)).map(MultiFacet.init)
    }

}

extension MultiFacet : RawRepresentable where P : RawRepresentable, Q : RawRepresentable, P.RawValue == Q.RawValue {
    public typealias RawValue = P.RawValue

    public init?(rawValue: RawValue) {
        if let p = P(rawValue: rawValue) {
            self.choice = .init(p)
        } else if let q = Q(rawValue: rawValue) {
            self.choice = .init(q)
        } else {
            return nil
        }
    }

    public var rawValue: RawValue {
        switch choice {
        case .p(let p): return p.rawValue
        case .q(let q): return q.rawValue
        }
    }
}

#if canImport(SwiftUI)
import SwiftUI


//extension Never : FacetView {
//    public func facetView(for store: FacetStore) -> Never {
//        fatalError()
//    }
//}

public protocol FacetUI : Facet {
    /// Metadata for the facet
    typealias FacetInfo = (title: Text, symbol: FairSymbol?, tint: Color?)

    /// The title, icon, and tint color for the facet
    var facetInfo: FacetInfo { get }
}

extension MultiFacet : FacetUI where P : FacetUI, Q : FacetUI {
    public var facetInfo: FacetInfo {
        choice.map(\.facetInfo, \.facetInfo).pvalue
    }
}

/// A Facet of Never is how a non-faceted store can
extension Never : FacetUI {
    public init?(rawValue: String) {
        return nil
    }

    public var rawValue: String {
        fatalError("Never instance never exists")
    }

    public var facetInfo: FacetInfo {
        fatalError("Never instance never exists")
    }

    public static func facets<Manager>(for manager: Manager) -> [Never] where Manager : FacetManager {
        Array()
    }
}


/// A `FacetView` is an app `Facet` that knows how to create a view for itself.
public protocol FacetView : FacetUI {
    associatedtype FacetStore : FacetManager
    associatedtype FacetViewType : View
    @ViewBuilder func facetView(for store: FacetStore) -> FacetViewType
}

/// A union of views is also a view.
extension XOr.Or : View where P : View, Q : View {
    public var body: some View {
        switch self {
        case .p(let pv): pv
        case .q(let qv): qv
        }
    }
}

extension MultiFacet : View where P : View, Q : View {
    @ViewBuilder public var body: some View {
        choice
    }
}

extension MultiFacet : FacetView where P : FacetView, Q : FacetView, P.FacetStore == Q.FacetStore {
    /// Delegates the `FacetView` implementation to the underlying choice.
    @ViewBuilder public func facetView(for store: P.FacetStore) -> some View {
        choice.map {
            $0.facetView(for: store)
        } _: {
            $0.facetView(for: store)
        }
    }
}

extension MultiFacet : CaseIterable where P : CaseIterable, Q : CaseIterable {
    /// A `MultiFacet` will iterator through all its choice cases.
    public static var allCases: [MultiFacet<P, Q>] {
        P.allCases.map(Choice.p).map(MultiFacet.init) +
        Q.allCases.map(Choice.q).map(MultiFacet.init)
    }
}

/// A RawRepresentable that can handle an optional String.
///
/// This exists in order to enable a `SceneStorage` or `AppStorage` property that can accept a nil value (which will be serialized as a blank string).
public struct OptionalStringStorage<T: RawRepresentable> : RawRepresentable where T.RawValue == String {
    public typealias RawValue = String
    public var value: T?

    public init(value: T? = nil) {
        self.value = value
    }

    public init(rawValue: String) {
        self.value = .init(rawValue: rawValue)
    }

    public var rawValue: String {
        get { value?.rawValue ?? "" }
    }
}

/// A wrapper around a `Codable` that stores its contents via encoding it to the String value.
public struct StringCodableRepresentable<T: Codable> : RawRepresentable {
    public typealias RawValue = String
    public var value: T?

    public init(value: T?) {
        self.value = value
    }

    public init(rawValue: String) {
        do {
            self.value = try T(json: rawValue.utf8Data)
        } catch {
            dbg("error decoding string codable:", error)
            self.value = nil
            //return nil
        }
    }

    public var rawValue: String {
        get {
            value.canonicalJSON
        }
    }
}

/// FacetHostingView: a top-level browser fo an app's `Facet`s,
/// represented as either an outline list on desktop platforms and a tabbed interface on mobile.
public struct FacetHostingView<Manager: SceneManager> : View where Manager.AppFacets : RawRepresentable, Manager.AppFacets.RawValue == String, Manager.AppFacets.FacetStore == Manager {
    /// The currently selected facet, which is stored in `SceneStorage` to restore the selection on re-lauch.
    /// This is wrapped in a `OptionalStringStorage` to support nil values.
    @SceneStorage("facetSelection") private var facetSelection = OptionalStringStorage<Manager.AppFacets>()
    @ObservedObject var manager: Manager

    public init(store manager: Manager) {
        self.manager = manager
    }

    public var body: some View {
        FacetHostingContainerView<Manager>(facetSelection: $facetSelection.value)
            .environmentObject(manager)
    }
}

struct FacetHostingContainerView<Manager: SceneManager> : View where Manager.AppFacets : RawRepresentable, Manager.AppFacets.RawValue == String, Manager.AppFacets.FacetStore == Manager {
    @Binding var facetSelection: Manager.AppFacets?

    public var body: some View {
        FacetBrowserView<Manager, Manager.AppFacets>(nested: false, selection: $facetSelection)
            .withAppearanceSetting()
            .withLocaleSetting()
            .focusedSceneValue(\.[focusedBinding: Manager.AppFacets?.none], $facetSelection)
    }
}

extension FocusedValues {
    /// The underlying value of the currently-selected binding to a given type.
    subscript<T>(focusedBinding defaultValue: T?) -> Binding<T?>? {
        get { self[FocusedValueBindingKey.self] }
        set { self[FocusedValueBindingKey.self] = newValue }
    }

    private struct FocusedValueBindingKey<T> : FocusedValueKey {
        typealias Value = Binding<T?>
    }
}

fileprivate extension KeyEquivalent {
    /// Returns a `KeyEquivalent` for the given number
    static func indexed(_ itemIndex: Int) -> KeyEquivalent? {
        switch itemIndex {
        case 0: return KeyEquivalent("0")
        case 1: return KeyEquivalent("1")
        case 2: return KeyEquivalent("2")
        case 3: return KeyEquivalent("3")
        case 4: return KeyEquivalent("4")
        case 5: return KeyEquivalent("5")
        case 6: return KeyEquivalent("6")
        case 7: return KeyEquivalent("7")
        case 8: return KeyEquivalent("8")
        case 9: return KeyEquivalent("9")
        default: return nil
        }
    }
}

/// Commands for selecting the facet using menus and keyboard shortcuts
public struct FacetCommands<Store: SceneManager> : Commands {
    @FocusedBinding(\.[focusedBinding: Store.AppFacets?.none]) private var facetSelection
    let store: Store

    public init(store: Store) {
        self.store = store
    }
    
    public var body: some Commands {
        CommandGroup(before: .toolbar) {
            ForEach(Store.AppFacets.facets(for: store).dropLast().enumerated().array(), id: \.element) { index, facet in
                let menu = facet.facetInfo.title
                    .label(image: facet.facetInfo.symbol)
                    .tint(facet.facetInfo.tint)
                    .button {
                        self.facetSelection = facet
                    }
                    .accessibilityLabel(Text("Select facet view for \(facet.facetInfo.title)", bundle: .module, comment: "accessibility label for facet menu"))
                    .disabled(facetSelection == nil)

                if let key = KeyEquivalent.indexed(index) {
                    menu.keyboardShortcut(key) // 0-9 have automatic shortcuts assigned
                } else {
                    menu
                }
            }
        }
    }
}

extension Facet {
    /// The tab's tag for the facet, which needs to be `Optional` to match the optional selection
    var facetTag: Self? { self }
}

/// The style of facet representation.
public struct FacetStyle : RawRepresentable, Hashable {
    public var rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }
}

extension FacetStyle {
    /// A style will be automatically chosen based on the platform and the nested status of the browser.
    public static let automatic = FacetStyle(rawValue: "automatic")

    /// Facets will be arranged in an `OutlineView` and use `NavigationLink`s to traverse to their views.
    public static let outline = FacetStyle(rawValue: "outline")

    /// Facets will be displayed in the platforms native tabbing interface.
    public static let tabs = FacetStyle(rawValue: "tabs")
}

/// A view that can browse facets in either a tabbed or outline view configuration, depending on a combination of the current platform and the value if the `nested` setting.
public struct FacetBrowserView<Manager: FacetManager & ObservableObject, F: Facet> : View where F : FacetView, F.FacetStore == Manager {
    /// Whether the browser is at the top level or a lower level. This will affect whether it is rendered as a navigation hierarchy or a tabbed interface.
    public let nested: Bool
    var style: FacetStyle = .automatic

    @Binding var selection: F?
    @EnvironmentObject var manager: Manager

    public init(nested: Bool, selection: Binding<F?>) {
        self.nested = nested
        self._selection = selection
    }

    /// Changes the style of this facet browser to the speified style.
    public func facetStyle(_ style: FacetStyle) -> Self {
        var browser = self
        browser.style = style
        return browser
    }

    /// We decide whether to display in tabs based on the style of the facet browser.
    private var displayInTabs: Bool {
        if style == .automatic {
#if os(macOS)
            return nested
#else
            return !nested
#endif
        } else if style == .tabs {
            return true
        } else {
            return false
        }
    }

    var facets: [F] {
        F.facets(for: manager)
    }

    // TODO: this is where we might be able to inject things like toolbars that need to fit between the parent TabView/ForEach or NavigationView/List
    private func decorate<V: View>(_ forEach: ForEach<[F], F?, V>) -> some View {
        forEach
    }

    public var body: some View {
        if displayInTabs {
            bodyTabs
        } else {
            bodyNavigation
        }
    }

    var bodyTabs: some View {
        TabView(selection: $selection) {
            decorate(ForEach(self.facets, id: \.facetTag) { facet in
                facet
                    .facetView(for: manager)
                    .navigationTitle(facet.facetInfo.title)
#if os(iOS)
                    .navigationBarTitleDisplayMode(.inline)
#endif
                    .tabItem {
                        facet.facetInfo.title.label(image: facet.facetInfo.symbol)
                            .symbolVariant(.fill)
                    }
                    .tint(facet.facetInfo.tint)
            })
        }
    }

    /// A navigation view of the facets. When unnested, this will ignore the first facet (Welcome) and the final facet (Settings), since those are handled separately by top-level naviation views.
    var bodyNavigation: some View {
        NavigationView {
            List {
                decorate(ForEach(self.facets.dropFirst(nested ? 0 : 1).dropLast(nested ? 0 : 1).array(), id: \.facetTag) { facet in
                    NavigationLink(tag: facet, selection: $selection) {
                        facet
                            .facetView(for: manager)
                            .navigationTitle(facet.facetInfo.title)
                    } label: {
                        facet.facetInfo.title.label(image: facet.facetInfo.symbol
                            .foregroundStyle(facet.facetInfo.tint ?? .accentColor)) // makes the label tint color stand out
                    }
                })
            }
            .navigation(title: Text(Bundle.localizedAppName), subtitle: nil)

            if !nested && !self.facets.isEmpty {
                // the default placeholder view is the welcome screen
                self.facets.first.unsafelyUnwrapped
                    .facetView(for: manager)
            }
        }
    }
}

public extension FacetUI {

    /// Facet metadata convenience builder.
    ///
    /// - Parameters:
    ///   - title: the localized title of the facet
    ///   - symbol: the symbol to represent the facet
    ///   - tint: the tint of the facet
    /// - Returns: a tuple with the metadata needed to show the facet
    func info(title: Text, symbol: FairSymbol? = nil, tint: Color? = nil) -> FacetInfo {
        (title, symbol, tint)
    }
}


extension FairContainer where AppManager.AppFacets : View, AppManager.AppFacets == SettingsBody {
    /// The app-wide settings view, which, by convention, is the final element of the app's facets.
    @ViewBuilder public static func settingsView(store: AppManager) -> some View {
        AppManager.AppFacets.facets(for: store).last.unsafelyUnwrapped
            .environmentObject(store)
    }
}

// MARK: Standard Facets

extension FacetView {
    /// Adds on the standard settings to the end of the app-specific facets.
    public typealias WithStandardSettings<Store: FacetManager> = Self
        .With<AppearanceSetting<Store>>
        .With<LanguageSetting<Store>>
        .With<SupportSetting<Store>>
}

extension Facet where Self : CaseIterable {
    /// The default implementation of ``facets`` for a ``CaseIterable`` (e.g., an enum) will simply return the cases of the enum.
    ///
    /// This is useful for a single static facet that doesn't use any of the properties of the manager.
    public static func facets<Manager: FacetManager>(for manager: Manager) -> AllCases {
        allCases
    }
}

// TODO: remove facet implementation if we keep licenses embedded in the support view
// extension LicenseSetting : Facet { }
private let licenseTexts: [Bundle : [URL]] = {
    var licenseTexts: [Bundle : [URL]] = [:]
    for bundle in Bundle.allBundles {
        dbg("bundle", bundle.bundleName)
        for url in (try? bundle.resourceURL?.fileChildren(deep: false)) ?? [] {
            // check for:
            // LICENSE
            // LICENSE.AGPL
            // LICENSE.GPL.txt
            // LICENSE.txt
            // LICENSE.md
            // COPYING
            // COPYING.txt
            // COPYING.md
            if ["LICENSE", "COPYING"].contains(url.deletingPathExtension().deletingPathExtension().deletingPathExtension().lastPathComponent)
            //&& ["", "txt", "md"].contains(url.pathExtension) { // we need to be able to match things like "LICENSE.GPL"
            {
                dbg("found license in bundle", bundle.bundleName, url.path)
                licenseTexts[bundle, default: []].append(url)
            }
        }
    }
    return licenseTexts
}()

/// A setting that simply displays the text of the license(s) included in the app.
///
/// License files are text files that begin with "LICENSE".
public enum LicenseSetting<Store: FacetManager> : String, FacetView, CaseIterable {

    case license

    public var facetInfo: FacetInfo {
        switch self {
        case .license:
            return info(title: Text("Licenses", bundle: .module, comment: "licenses settings facet title"), symbol: "doc.text.magnifyingglass", tint: .brown)
        }
    }

    public func facetView(for store: Store) -> some View {
        List {
            Section {
                licensesList
            } footer: {
                Text("These are the software licenses used by this App Fair app.", bundle: .module, comment: "footer text for licenses setting screen")
            }
        }
    }

    var licensesList: some View {
        ForEach(licenseTexts.array(), id: \.key) { bundle, licenseURLs in
            NavigationLink {
                // when there is only a single license, just display it
                if licenseURLs.count <= 1, let licenseURL = licenseURLs.first {
                    textView(url: licenseURL)
                } else {
                    List {
                        ForEach(licenseURLs.uniquing(by: \.self).array(), id: \.self) { licenseURL in
                            NavigationLink {
                                textView(url: licenseURL)
                            } label: {
                                Text(licenseURL.lastPathComponent)
                            }
                        }
                    }
                }
            } label: {
                Text(bundle.bundleName == "App_App" ? Bundle.localizedAppName : bundle.bundleDisplayName ?? bundle.bundleName ?? "bundle")
            }
        }

    }

    func textView(url: URL) -> some View {
        TextEditor(text: .constant((try? String(contentsOf: url, encoding: .utf8)) ?? ""))
            .font(Font.caption.monospaced())
            .textSelection(.enabled)
    }
}


/// A setting that simply displays the support options as a series of link buttons.
public enum SupportSetting<Store: FacetManager> : String, FacetView, CaseIterable {
    /// Links to support resources: issues, discussions, source code, "fork this app", "Report this App (to the App Fair Council)"), log accessor, and software BOM
    case support

    public var facetInfo: FacetInfo {
        switch self {
        case .support:
            return info(title: Text.SupportText, symbol: "questionmark.app", tint: .red)
        }
    }

    public func facetView(for store: Store) -> some View {
        SupportSettingsView<Store>()
    }
}

private struct SupportSettingsView<Store: FacetManager> : View {
    var body: some View {
        List {
            Section {
                SupportCommands(builder: {
                    $0.link(to: $1)
                })
            } footer: {
                Text("This section contains links for seeking help or reporting issues with this app.", bundle: .module, comment: "footer text for support setting screen")
            }

            Section {
                LicenseSetting<Store>.license.licensesList
            } header: {
                Text("Software Licenses", bundle: .module, comment: "header text for licenses section")
            }
        }
    }
}

//    .preferredColorScheme(store.themeStyle.colorScheme)


/// A setting that simply displays the support options as a series of link buttons.
public enum AppearanceSetting<Store: FacetManager> : String, FacetView, CaseIterable {
    case appearance

    public var facetInfo: FacetInfo {
        switch self {
        case .appearance:
            return info(title: Text("Appearance", bundle: .module, comment: "appearance settings facet title"), symbol: "paintpalette", tint: .cyan)
        }
    }

    public func facetView(for store: Store) -> some View {
        AppearanceSettingsView()
    }
}

@MainActor class AppearanceManager : ObservableObject {
    static let shared = AppearanceManager()
    @AppStorage("themeStyle") var themeStyle = ThemeStyle.system

    private init() {
    }
}

struct AppearanceSettingsView : View {
    @EnvironmentObject var manager: AppearanceManager

    var body: some View {
        Form {
            ThemeStylePicker(style: manager.$themeStyle)
        }
    }
}

extension View {
    /// Applies the user's appearance settings preferences from ``AppearanceSetting`` into this view hierarchy.
    ///
    /// This function should be invoked as high as possible in the view hierarchy.
    public func withAppearanceSetting() -> some View {
        AppearanceManagerView(content: self)
            .environmentObject(AppearanceManager.shared)
    }
}

private struct AppearanceManagerView<V: View> : View {
    @EnvironmentObject var appearanceManager: AppearanceManager
    let content: V

    var body: some View {
        content
            .preferredColorScheme(appearanceManager.themeStyle.colorScheme)
    }
}


/// A shared manager for overriding the current locale from within an app (as opposed to chaning it system-wide from the settings).
@MainActor public class LocaleManager : ObservableObject {
    public static let shared = LocaleManager()
    /// The overridden locale identifier; a blank string signifies being un-set
    @AppStorage("localeOverride") var localeOverride = ""

    private init() {
    }

    /// The overidden locale for this manager, or else nil if it is un-set
    public var locale: Locale? {
        get {
            localeOverride.isEmpty ? nil : Locale(identifier: localeOverride)
        }

        set {
            localeOverride = newValue?.identifier ?? ""
        }
    }

    var layoutDirection: LayoutDirection? {
        // TODO: get a complete list of RTL: Arabic, Aramaic, Azeri, Divehi, Fula, Hebrew, Kurdish, N'ko, Persian, Rohingya, Syriac, Urdu
        ["ar", "arc", "az", "he", "ku", "fa", "ur"].contains(localeOverride) ? .rightToLeft : nil
    }
}


extension View {
    /// Applies the user's language settings preferences from ``LanguageSetting`` into this view hierarchy.
    ///
    /// This function should be invoked as high as possible in the view hierarchy.
    public func withLocaleSetting() -> some View {
        LocaleManagerView(content: self)
            .environmentObject(LocaleManager.shared)
    }
}

private struct LocaleManagerView<V: View> : View {
    @EnvironmentObject var localeManager: LocaleManager
    @Environment(\.locale) var currentLocale: Locale
    @Environment(\.layoutDirection) var currentLayoutDirection: LayoutDirection
    let content: V

    var body: some View {
        content
            .environment(\.locale, localeManager.locale ?? currentLocale)
            .environment(\.layoutDirection, localeManager.layoutDirection ?? currentLayoutDirection)
    }
}

/// A view that selects from the available themes
struct ThemeStylePicker: View {
    @Binding var style: ThemeStyle

    var body: some View {
        Picker(selection: $style) {
            ForEach(ThemeStyle.allCases) { themeStyle in
                themeStyle.label
            }
        } label: {
            Text.ThemesText
        }
        .pickerStyle(.inline)
        //.radioPickerStyle()
    }
}

/// The preferred theme style for the app
enum ThemeStyle: String, CaseIterable {
    case system
    case light
    case dark
}

extension ThemeStyle : Identifiable {
    var id: Self { self }

    var label: Text {
        switch self {
        case .system: return Text("System", comment: "general preference for theme style in popup menu")
        case .light: return Text("Light", comment: "general preference for theme style in popup menu")
        case .dark: return Text("Dark", comment: "general preference for theme style in popup menu")
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}

public enum LanguageSetting<Store: FacetManager> : String, FacetView, CaseIterable {
    case language

    public var facetInfo: FacetInfo {
        FacetInfo(title: .LanguageText, symbol: "flag", tint: .green)
    }

    public func facetView(for store: Store) -> some View {
        LocalesList(bundle: store.bundle)
    }
}

struct LocalesList : View {
    let bundle: Bundle
    @Environment(\.locale) var currentLocale
    @EnvironmentObject var localeManager: LocaleManager

    // TODO: show overridden language setting with option to clear
    
    var body: some View {
        List {
            let preferredLocales = bundle.locales(preferred: true, for: currentLocale)
            Section {
                ForEach(preferredLocales, id: \.self, content: localeSettingView)
            } header: {
                preferredLocales.count == 1
                ? Text("Current Language", bundle: .module, comment: "header text for language setting screen")
                : Text("Current Languages", bundle: .module, comment: "header text for language setting screen")
            }

            Section {
                ForEach(bundle.locales(preferred: false, for: currentLocale), id: \.self, content: localeSettingView)
            } header: {
                Text("All Languages", bundle: .module, comment: "header text for language setting screen")
            } footer: {
                Text("This list contains all the languages this app can be translated into. Help contribute a translation by tapping on the language.", bundle: .module, comment: "footer text for language setting screen")
            }
        }
    }

    @ViewBuilder func localeSettingView(locale: Locale) -> some View {
        NavigationLink {
            let localLanguageName = currentLocale.localizedString(forIdentifier: locale.identifier) ?? locale.identifier
            let nativeLanguageName = locale.localizedString(forIdentifier: locale.identifier) ?? locale.identifier

            Form {
                Section {
                    Button {
                        localeManager.localeOverride = locale.identifier
                    } label: {
                        Text("Set Language to \(localLanguageName)", bundle: .module, comment: "button title for overriding the current locale")
                    }
                } header: {
                    let percentComplete = (try? bundle.checkTranslationPercent(locale: locale)) ?? 0.0
                    Text("Translation Status: \(percentComplete, format: .percent.rounded(rule: .towardZero, increment: 1))", bundle: .module, comment: "header text for localization section")
                }

                Section {
                    Text(localLanguageName).link(to: .localeLink(for: locale), embedded: true)
                } header: {
                    Text.HelpPlease
                } footer: {
                    Text("Help translate this app into \(localLanguageName) by following the link to fork and edit the translation strings (signup required).", bundle: .module, comment: "header text for translation help plea")
                }
            }
            .navigation(title: Text(localLanguageName), subtitle: Text(nativeLanguageName))
        } label: {
            LocaleSummaryListItemView(locale: locale, bundle: bundle)
        }

    }
}

extension Bundle {
    /// The locals from the list of bundle localizations
    public func locales(preferred: Bool, for locale: Locale) -> [Locale] {
        (preferred ? preferredLocalizations : localizations)
            .compactMap(Locale.init(identifier:))
            .sorted { a, b in
                locale.localizedString(forIdentifier: a.identifier)?.localizedStandardCompare(locale.localizedString(forIdentifier: b.identifier) ?? "") == .orderedAscending
            }
    }
}

extension Locale {
    func languageDescription(for locale: Locale) -> (native: String?, foreign: String?) {
        (locale.localizedString(forIdentifier: self.identifier), self.localizedString(forIdentifier: locale.identifier))
    }
}

struct LocaleSummaryListItemView : View {
    let locale: Locale
    let bundle: Bundle
    @Environment(\.locale) var currentLocale
    @State var translationPercent: Double? = nil

    var body: some View {
        let localLanguageName = currentLocale.localizedString(forIdentifier: locale.identifier) ?? locale.identifier
        let nativeLanguageName = locale.localizedString(forIdentifier: locale.identifier) ?? locale.identifier

        HStack(alignment: .center) {
            VStack(alignment: .leading) {
                Text(nativeLanguageName) // e.g., “Deutsch”
                Text(localLanguageName) // e.g., “German”
                    .font(.caption)
            }
            Spacer()
            VStack(alignment: .trailing) {
                if let translationPercent = translationPercent {
                    Text(translationPercent, format: .percent.rounded(rule: .towardZero, increment: 1))
                        .font(.callout.monospacedDigit())
                        .foregroundColor(.secondary)
                } else {
                    ProgressView()
                }
            }
        }
        .task(id: self.locale, priority: .high) {
            if translationPercent == nil {
                do {
                    dbg("checking translation percent for:", locale.identifier)
                    self.translationPercent = try bundle.checkTranslationPercent(locale: locale)
                    dbg("done translation percent for:", locale.identifier, self.translationPercent)
                } catch {
                    dbg("error calculating translation percent:", error)
                }
            }
        }
    }

}

extension URL {
    /// A link to the translation page for the given locale.
    /// - Parameter locale: the locale the link to
    /// - Returns: the URL to the localization link, if it exists
    static func localeLink(for locale: Locale) -> URL? {
        URL.fairHubURL("blob/main")?.appendingPathComponent("Sources/App/Resources/\(locale.identifier).lproj/Localizable.strings")
    }

}

extension Bundle {
    /// Checks the percentage of the `Localized.strings` file for the locale in this bundle that have been translated.
    ///
    /// - Parameter locale: the locale the check for
    /// - Returns: the percentage of strings that have values that differ from the base localization
    func checkTranslationPercent(locale: Locale) throws -> Double? {
        func checkStrings(for localeIdentifier: String?) -> URL? {
            self.urls(forResourcesWithExtension: "strings", subdirectory: nil, localization: localeIdentifier)?.first(where: { $0.lastPathComponent == "Localizable.strings" })
        }

        guard let localeURL = checkStrings(for: locale.identifier) else {
            dbg("no localizable strings for locale:", locale.identifier)
            return nil
        }

        guard let devLocaleURL = checkStrings(for: self.developmentLocalization) else {
            dbg("no localizable strings for developer locale:", self.developmentLocalization)
            return nil
        }

        return try Self.checkLocalization(locale: locale, url: localeURL, base: devLocaleURL)
    }

    static func checkLocalization(locale: Locale, url: URL, base: URL) throws -> Double {
        let basePlist = try Plist(url: base)
        let plist = try Plist(url: url)
        dbg("loaded plist for:", locale.identifier, "keys", plist.rawValue.count, "base", basePlist.rawValue.count)
        if base == url {
            return 1.0 // the development locale is, by definition, 100% translated
        }

        // translation percent is simply the count of keys whose values differ from their root
        var keyCount = 0, translationCount = 0
        for keyValue in basePlist.rawValue {
            guard let key = keyValue.key as? String else {
                continue
            }
            keyCount += 1
            if plist.rawValue[key] as? String != keyValue.value as? String {
                translationCount += 1
            }
        }
        return Double(translationCount) / Double(keyCount)
    }

}
#endif // canImport(SwiftUI)
