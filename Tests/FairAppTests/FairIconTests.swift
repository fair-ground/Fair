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
import Swift
import XCTest
#if canImport(SwiftUI)
import WebKit
@testable import FairApp

final class FairIconTests: XCTestCase {
    /// Crashes on GH CI
    @available(macOS 12.0, iOS 15.0, *)
    func XXXtestFairIcons() throws {
        let width = 1600.0, height = 400.0

        for i in 1...20 {
            try FairIconView_Previews.preview(count: 300, span: height/5)
                .frame(width: width, height: height, alignment: .center)
                .offset(x: width/2, y: height/2)
                .previewLayout(.sizeThatFits)
                .png(bounds: CGRect(x: 0, y: 0, width: width, height: height))?
                .write(to: URL(fileURLWithPath: "FairIcon_\(i).png", relativeTo: NSURL(fileURLWithPath: NSTemporaryDirectory())))
        }
    }
}
#endif

