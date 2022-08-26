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

