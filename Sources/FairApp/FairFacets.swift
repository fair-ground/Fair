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

/// A facet is a logical section of an app, either a top-level navigation feature (tabs on iOS, outline list items on macOS along with menus),
/// or a secondary-level feature (navigation items on iOS, settings tabs on macOS).
///
/// By convention, the initial element of the `CaseIterable` list will be a welcome view that will be initially displayed by the app.
///
/// The final tab will be the settings tab, which is shown as a tab on iOS and is included in the standard settings window on macOS.
public protocol Facet : CaseIterable, Hashable, RawRepresentable where RawValue == String, AllCases : RandomAccessCollection, AllCases.Index == Int {

    /// Metadata for the facet
    typealias FacetInfo = (title: Text, symbol: FairSymbol?, tint: Color?)

    /// The title, icon, and tint color for the facet
    var facetInfo: FacetInfo { get }
}


public struct MultiFacet<P : CaseIterable & Facet, Q : CaseIterable & Facet> : Facet {
    public typealias Choice = XOr<P>.Or<Q>
    public let choice: Choice

    public init?(rawValue: String) {
        guard let choice = P(rawValue: rawValue).flatMap(Choice.p) ?? Q(rawValue: rawValue).flatMap(Choice.q) else {
            return nil
        }
        self.choice = choice
    }

    public var rawValue: String {
        switch choice {
        case .p(let p): return p.rawValue
        case .q(let q): return q.rawValue
        }
    }

    public init(choice: XOr<P>.Or<Q>) {
        self.choice = choice
    }

    public static var allCases: [MultiFacet<P, Q>] {
        (P.allCases.map(Choice.p) + Q.allCases.map(Choice.q)).map(MultiFacet.init)
    }

    public var facetInfo: FacetInfo {
        choice.map(\.facetInfo, \.facetInfo).pvalue
    }

}

#if canImport(SwiftUI)
import SwiftUI


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
/// represented as either an outline on macOS or tabs on iOS.
///
/// macOS: OutlineView w/ top-level Settings
///   iOS: TabView: Welcome, Settings
public struct FacetHostingView<AF: Facet & View> : View {
    @SceneStorage("facetSelection") private var facetSelection: AF.RawValue = .init()

    public init() {
    }
    
    public var body: some View {
        FacetBrowserView(nested: false, selection: selectionBinding)
            .focusedSceneValue(\.facetSelection, selectionOptionalBinding)
    }


    /// The current selection is stored as the underlying Raw Value string, which enables us to easily store it if need be.
    private var selectionBinding: Binding<AF?> {
        Binding(get: { AF(rawValue: facetSelection) }, set: { facetSelection = $0?.rawValue ?? .init() })
    }

    /// The current selection is stored as the underlying Raw Value string, which enables us to easily store it if need be.
    private var selectionOptionalBinding: Binding<AF.RawValue?> {
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
public struct FacetCommands<AF: Facet> : Commands {
    @FocusedBinding(\.facetSelection) private var facetSelection: AF.RawValue??

    public init() {
    }
    
    public var body: some Commands {
        CommandGroup(before: .toolbar) {
            ForEach(AF.allCases.dropLast().enumerated().array(), id: \.element) { index, facet in
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

/// A view that can browse facets in either a tabbed or outline view configuration, depending on a combination of the current platform and the value if the `nested` setting.
public struct FacetBrowserView<F: Facet> : View where F : View {
    /// Whether the browser is at the top level or a lower level. This will affect whether it is rendered as a navigation hierarchy or a tabbed interface.
    public let nested: Bool
    @Binding var selection: F?

    public init(nested: Bool = true, selection: Binding<F?>) {
        self.nested = nested
        self._selection = selection
    }

    private var displayInTabs: Bool {
        #if os(macOS)
        nested
        #else
        !nested
        #endif
    }

    public var body: some View {
        if displayInTabs {
            TabView(selection: $selection) {
                ForEach(F.allCases, id: \.facetTag) { facet in
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
                    ForEach(F.allCases.dropFirst(nested ? 0 : 1).dropLast(nested ? 0 : 1), id: \.self) { facet in
                        NavigationLink(tag: facet, selection: $selection) {
                            facet
                                .navigationTitle(facet.facetInfo.title)
                        } label: {
                            facet.facetInfo.title.label(image: facet.facetInfo.symbol) // .foregroundStyle(facet.facetInfo.tint!)) // makes the label tint color stand out

                        }
                    }
                }
                #if os(iOS)
                .navigationBarTitleDisplayMode(.inline)
                #endif

                if !nested {
                    // the default placeholder view is the welcome screen
                    F.allCases.first.unsafelyUnwrapped
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


extension Facet {
    /// Composition of one facet with another
    public typealias With<F: Facet> = MultiFacet<Self, F>
}


// MARK: Standard Facets


/// A setting that simply displays the text of the license(s) included in the app.
public enum LicenseSetting : String, Facet, View {
    case license

    public var facetInfo: FacetInfo {
        switch self {
        case .license:
            return info(title: Text("License", bundle: .module, comment: "license settings facet title"), symbol: .init(rawValue: "doc.text.magnifyingglass"), tint: .mint)
        }
    }

    public var body: some View {
        TextEditor(text: .constant(wip("LICENSE")))
    }
}


#endif

