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

/// A Fair Ground is a platform for app distribution
public enum FairGround {
    /// A fairground that uses hosted git repository with a REST API,
    /// such as github.com
    case hub(FairHub)

    /// The `FairHub` for repositories that use that model
    public var hub: FairHub? {
        switch self {
        case .hub(let x): return x
        }
    }
}
