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

#if canImport(SwiftUI)

/// Whether to display the items as a sidebar list or a table
public enum TriptychOrient: String, CaseIterable {
    /// A three-column orientation with a leading outline, a secondard selction lisst, and then a central content view.
    case list
    #if os(macOS)
    /// A side-by-side leading outline next to a vertical split with a table view at the top and a detail view below.
    case table
    #endif
}

extension TriptychOrient : Identifiable {
    public var id: Self { self }
}

@available(macOS 12.0, iOS 15.0, *)
public struct TriptychView<Outline: View, ListSelection: View, TableSelection: View, Content: View> : View {
    @Binding var orient: TriptychOrient
    var outline: () -> Outline
    var list: () -> ListSelection
    var table: () -> TableSelection
    var content: () -> Content

    public init(orient: Binding<TriptychOrient>,
                @ViewBuilder outline: @escaping () -> Outline,
                @ViewBuilder list: @escaping () -> ListSelection,
                @ViewBuilder table: @escaping () -> TableSelection,
                @ViewBuilder content: @escaping () -> Content) {
        self._orient = orient
        self.outline = outline
        self.list = list
        self.table = table
        self.content = content
    }

    @ViewBuilder public var body: some View {
        NavigationView {
            switch orient {
            case .list:
                outline()
                list()
                content()
            #if os(macOS)
            case .table:
                outline()
                VSplitView {
                    table()
                    content()
                }
            #endif
            }
        }
    }
}

#endif
