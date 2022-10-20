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

#if canImport(SwiftUI)
import SwiftUI

/// A facet is a logical section of an app, either a top-level navigation feature (tabs on iOS, outline list items on macOS along with menus),
/// or a secondary-level feature (navigation items on iOS, settings tabs on macOS).
///
/// By convention, the initial element of the `CaseIterable` list will be a welcome view that will be initially displayed by the app.
///
/// The final tab will be the settings tab, which is shown as a tab on iOS and is included in the standard settings window on macOS.
public protocol Facet : Hashable {
    typealias RawValue = String

    /// The underlying encoded value for this facet
    var rawValue: RawValue { get }

    /// Metadata for the facet
    typealias FacetInfo = (title: Text, symbol: FairSymbol?, tint: Color?)

    /// The title, icon, and tint color for the facet
    var facetInfo: FacetInfo { get }

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

    public var rawValue: String {
        switch choice {
        case .p(let p): return p.rawValue
        case .q(let q): return q.rawValue
        }
    }

    public init(choice: XOr<P>.Or<Q>) {
        self.choice = choice
    }

    public static func facets<Manager: FacetManager>(for manager: Manager) -> [Self] {
        (P.facets(for: manager).map(Choice.p) + Q.facets(for: manager).map(Choice.q)).map(MultiFacet.init)
    }

    public var facetInfo: FacetInfo {
        choice.map(\.facetInfo, \.facetInfo).pvalue
    }
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

/// FacetHostingView: a top-level browser fo an app's `Facet`s,
/// represented as either an outline list on desktop platforms and a tabbed interface on mobile.
public struct FacetHostingView<Manager: SceneManager> : View where Manager.AppFacets : View {
    @SceneStorage("facetSelection") private var facetSelection: Manager.AppFacets.RawValue = .init()
    @ObservedObject var manager: Manager

    public init(store manager: Manager) {
        self.manager = manager
    }
    
    public var body: some View {
        FacetBrowserView<Manager, Manager.AppFacets>(nested: false, selection: selectionBinding)
            .withAppearanceSetting()
            .environmentObject(manager)
            .focusedSceneValue(\.facetSelection, selectionOptionalBinding)
    }

    /// The current selection is stored as the underlying Raw Value string, which enables us to easily store it if need be.
    private var selectionBinding: Binding<Manager.AppFacets?> {
        Binding(get: { Manager.AppFacets.facets(for: manager).first { $0.rawValue == facetSelection } }, set: { facetSelection = $0?.rawValue ?? .init() })
    }

    /// The current selection is stored as the underlying Raw Value string, which enables us to easily store it if need be.
    private var selectionOptionalBinding: Binding<Manager.AppFacets.RawValue?> {
        Binding(get: { facetSelection }, set: { newValue in self.facetSelection = newValue ?? .init() })
    }
}

extension FocusedValues {
    /// The underlying value of the currently-selected facet
    var facetSelection: Binding<String?>? {
        get { self[FacetSelectionKey.self] }
        set { self[FacetSelectionKey.self] = newValue }
    }

    private struct FacetSelectionKey : FocusedValueKey {
        typealias Value = Binding<String?>
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
    @FocusedBinding(\.facetSelection) private var facetSelection: Store.AppFacets.RawValue??
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
                        self.facetSelection = facet.rawValue
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

public struct FacetStyle : RawRepresentable, Hashable {
    public var rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }
}

extension FacetStyle {
    public static let automatic = FacetStyle(rawValue: "automatic")

    public static let outline = FacetStyle(rawValue: "outline")
    public static let tabs = FacetStyle(rawValue: "tabs")
}

/// A view that can browse facets in either a tabbed or outline view configuration, depending on a combination of the current platform and the value if the `nested` setting.
public struct FacetBrowserView<Manager: FacetManager & ObservableObject, FacetView: Facet> : View where FacetView : View {
    /// Whether the browser is at the top level or a lower level. This will affect whether it is rendered as a navigation hierarchy or a tabbed interface.
    public let nested: Bool
    var style: FacetStyle = .automatic

    @Binding var selection: FacetView?
    @EnvironmentObject var manager: Manager

    public init(nested: Bool = true, selection: Binding<FacetView?>) {
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

    var facets: [FacetView] {
        FacetView.facets(for: manager)
    }

    public var body: some View {
        if displayInTabs {
            TabView(selection: $selection) {
                ForEach(self.facets, id: \.facetTag) { facet in
                    facet
                        .navigationTitle(facet.facetInfo.title)
#if os(iOS)
                        .navigationBarTitleDisplayMode(.inline)
#endif
                        .tabItem {
                            facet.facetInfo.title.label(image: facet.facetInfo.symbol)
                                .symbolVariant(.fill)
                        }
                        .tint(facet.facetInfo.tint)
                }
            }
        } else {
            NavigationView {
                List {
                    ForEach(self.facets.dropFirst(nested ? 0 : 1).dropLast(nested ? 0 : 1), id: \.self) { facet in
                        NavigationLink(tag: facet, selection: $selection) {
                            facet
                                .navigationTitle(facet.facetInfo.title)
                        } label: {
                            facet.facetInfo.title.label(image: facet.facetInfo.symbol
                                .foregroundStyle(facet.facetInfo.tint ?? .accentColor)) // makes the label tint color stand out
                        }
                    }
                }
                .navigation(title: Text(Bundle.localizedAppName), subtitle: nil)

                if !nested {
                    // the default placeholder view is the welcome screen
                    self.facets.first.unsafelyUnwrapped
                }
            }
        }
    }
}

public extension Facet {

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


extension FairContainer where AppStore.AppFacets : View, AppStore.AppFacets == SettingsBody {
    /// The app-wide settings view, which, by convention, is the final element of the app's facets.
    @ViewBuilder public static func settingsView(store: AppStore) -> some View {
        AppStore.AppFacets.facets(for: store).last.unsafelyUnwrapped
            .environmentObject(store)
    }
}

// MARK: Standard Facets

extension Facet {
    /// Adds on the standard settings to the end of the app-specific facets.
    public typealias WithStandardSettings = Self
        .With<AppearanceSetting>
        .With<LanguageSetting>
        .With<SupportSetting>
        //.With<LicenseSetting>
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

/// A setting that simply displays the text of the license(s) included in the app.
///
/// License files are text files that begin with "LICENSE".
public enum LicenseSetting : String, Facet, CaseIterable, View {
    static let licenseTexts: [Bundle : [URL]] = {
        var licenseTexts: [Bundle : [URL]] = [:]
        for bundle in Bundle.allBundles {
            dbg("bundle", bundle.bundleName)
            for url in (try? bundle.resourceURL?.fileChildren(deep: false)) ?? [] {
                if url.lastPathComponent.hasPrefix("LICENSE") {
                    dbg("found license in bundle", bundle.bundleName, url.path)
                    licenseTexts[bundle, default: []].append(url)
                }
            }
        }
        return licenseTexts
    }()

    case license

    public var facetInfo: FacetInfo {
        switch self {
        case .license:
            return info(title: Text("Licenses", bundle: .module, comment: "licenses settings facet title"), symbol: "doc.text.magnifyingglass", tint: .brown)
        }
    }

    public var body: some View {
        List {
            Section {
                licensesList
            } footer: {
                Text("These are the software licenses used by this App Fair app.", bundle: .module, comment: "footer text for licenses setting screen")
            }
        }
    }

    var licensesList: some View {
        ForEach(Self.licenseTexts.array(), id: \.key) { bundle, licenseURLs in
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
public enum SupportSetting : String, Facet, CaseIterable, View {
    /// Links to support resources: issues, discussions, source code, "fork this app", "Report this App (to the App Fair Council)"), log accessor, and software BOM
    case support

    public var facetInfo: FacetInfo {
        switch self {
        case .support:
            return info(title: Text("Support", bundle: .module, comment: "license settings facet title"), symbol: "questionmark.app", tint: .red)
        }
    }

    public var body: some View {
        SupportSettingsView()
    }
}

private struct SupportSettingsView : View {
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
                LicenseSetting.license.licensesList
            } header: {
                Text("Software Licenses", bundle: .module, comment: "header text for licenses section")
            }
        }
    }
}

//    .preferredColorScheme(store.themeStyle.colorScheme)


/// A setting that simply displays the support options as a series of link buttons.
public enum AppearanceSetting : String, Facet, CaseIterable, View {
    case appearance

    public var facetInfo: FacetInfo {
        switch self {
        case .appearance:
            return info(title: Text("Appearance", bundle: .module, comment: "appearance settings facet title"), symbol: "paintpalette", tint: .cyan)
        }
    }

    public var body: some View {
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


/// A view that selects from the available themes
struct ThemeStylePicker: View {
    @Binding var style: ThemeStyle

    var body: some View {
        Picker(selection: $style) {
            ForEach(ThemeStyle.allCases) { themeStyle in
                themeStyle.label
            }
        } label: {
            Text("Theme", bundle: .module, comment: "picker title for general preference for theme style")
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


public struct LanguageSetting : Facet, View {
    let bundle: Bundle
    public let rawValue = "language"

    init(bundle: Bundle) {
        self.bundle = bundle
    }

    public var facetInfo: FacetInfo {
        FacetInfo(title: Text("Language", bundle: .module, comment: "language setting title"), symbol: "flag.badge.ellipsis", tint: .green)
    }

    public static func facets<Manager>(for manager: Manager) -> [LanguageSetting] where Manager : FacetManager {
        [LanguageSetting(bundle: manager.bundle)]
    }

    public var body: some View {
        LocalesList(bundle: bundle)
    }
}

struct LocalesList : View {
    let bundle: Bundle
    @Environment(\.locale) var currentLocale

    var body: some View {
        List {
            let preferredLocales = bundle.locales(preferred: true, for: currentLocale)
            Section {
                ForEach(preferredLocales, id: \.self) { loc in
                    LocaleLink(locale: loc, bundle: bundle)
                }
            } header: {
                preferredLocales.count == 1
                ? Text("Current Language", bundle: .module, comment: "header text for language setting screen")
                : Text("Current Languages", bundle: .module, comment: "header text for language setting screen")
            }

            Section {
                ForEach(bundle.locales(preferred: false, for: currentLocale), id: \.self) { loc in
                    LocaleLink(locale: loc, bundle: bundle)
                }
            } header: {
                Text("All Languages", bundle: .module, comment: "header text for language setting screen")
            } footer: {
                Text("This list contains all the languages this app can be translated into. Help contribute a translation by tapping on the language.", bundle: .module, comment: "footer text for language setting screen")
            }
        }
    }
}

extension Bundle {
    /// The locals from the list of bundle localizations
    func locales(preferred: Bool, for locale: Locale) -> [Locale] {
        (preferred ? preferredLocalizations : localizations)
            .compactMap(Locale.init(identifier:))
            .sorted { a, b in
                locale.localizedString(forIdentifier: a.identifier)?.localizedStandardCompare(locale.localizedString(forIdentifier: b.identifier) ?? "") == .orderedAscending
            }
    }
}

struct LocaleLink : View {
    let locale: Locale
    let bundle: Bundle
    @Environment(\.locale) var currentLocale
    @State var translationPercent: Double? = nil

    var body: some View {
        if let localLanguageName = currentLocale.localizedString(forIdentifier: locale.identifier),
           let nativeLanguageName = locale.localizedString(forIdentifier: locale.identifier),
           let url = localeLink {
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
            .link(to: url)
            .task {
                if translationPercent == nil {
                    await checkTranslationPercent()
                }
            }
        }
    }

    var localeLink: URL? {
        URL.fairHubURL("blob/main")?.appendingPathComponent("Sources/App/Resources/\(locale.identifier).lproj/Localizable.strings")
    }

    func checkTranslationPercent() async {
        func checkStrings(for localeIdentifier: String?) -> URL? {
            bundle.urls(forResourcesWithExtension: "strings", subdirectory: nil, localization: localeIdentifier)?.first(where: { $0.lastPathComponent == "Localizable.strings" })
        }

        guard let localeURL = checkStrings(for: locale.identifier) else {
            return dbg("no localizable strings for locale:", locale.identifier)
        }

        guard let devLocaleURL = checkStrings(for: bundle.developmentLocalization) else {
            return dbg("no localizable strings for developer locale:", bundle.developmentLocalization)
        }

        do {
            self.translationPercent = try Self.checkLocalization(locale: locale, url: localeURL, base: devLocaleURL)
        } catch {
            dbg("error loading language plist:", error)
        }
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
