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
import Foundation

/// A symbol that can be interpreted graphically by the host system.
public struct FairSymbol : Pure, RawRepresentable {
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }
}

#if canImport(SwiftUI)
import SwiftUI

extension FairSymbol : View {
    public var body: SwiftUI.Image {
        self.image
    }

    public var image: SwiftUI.Image {
        SwiftUI.Image(self)
    }
}

public extension SwiftUI.Image {
    init(_ symbol: FairSymbol) {
        self.init(systemName: symbol.rawValue)
    }
}

#endif

