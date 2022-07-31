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

public struct DisplayModePicker: View {
    @Binding var mode: TriptychOrient

    public init(mode: Binding<TriptychOrient>) {
        self._mode = mode
    }

    public var body: some View {
        // only display the picker if there is more than one element (i.e., on macOS)
        if TriptychOrient.allCases.count > 1 {
            Picker(selection: $mode) {
                ForEach(TriptychOrient.allCases) { viewMode in
                    viewMode.label
                }
            } label: {
                Text("Display Mode", bundle: .module, comment: "picker title for whether to display a list view or a table view")
            }
            .pickerStyle(SegmentedPickerStyle())
        }
    }
}

public extension TriptychOrient {
    var labelContent: (title: Text, icon: FairSymbol) {
        switch self {
        case .list:
            return (Text("List", bundle: .module, comment: "display mode for three-panel triptych layout in list mode"), .list_bullet_rectangle)
        #if os(macOS)
        case .table:
            return (Text("Table", bundle: .module, comment: "display mode the three-panel triptych layout in table mode for macOS"), .tablecells)
        #endif
        }
    }

    var label: some View {
        Label {
            labelContent.title
        } icon: {
            labelContent.icon
        }
    }
}


#endif
