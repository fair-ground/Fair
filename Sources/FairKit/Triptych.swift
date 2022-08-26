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
