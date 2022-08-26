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
import FairCore

#if canImport(SwiftUI)
import SwiftUI

public enum FairContentType {
    case placeholder
}

/// The `FairContentView` offers pre-defined functionality for an fair-ground App.
/// The default `.placeholder` content is the initial content for a new
/// app, and provides guidance for the developer on how to get started.
public struct FairContentView: View {
    let issuesURL = URL.fairHubURL("issues")!
    let discussionsURL = URL.fairHubURL("discussions")!
    let actionsURL = URL.fairHubURL("actions")!
    let compareURL = URL.fairHubURL("compare")!

    public init(_ type: FairContentType = .placeholder) {
    }

    public var body: some View {
        VStack(spacing: 20) {
            Text("Welcome to \(Bundle.mainBundleName)!", bundle: .module, comment: "welcome text headline")
                .font(.largeTitle)
                .symbolRenderingMode(.multicolor)
            HStack {
                Text("version \(Bundle.main.bundleVersionString ?? "")", bundle: .module, comment: "app version localized text")
                Text("build \(Bundle.main.bundleVersionCounter ?? 0)", bundle: .module, comment: "app build number localized text")
            }

            Spacer()

            ScrollView {
                Text(LocalizedStringKey(stringLiteral: """
    This is a *[Fair Ground](https://www.appfair.net)* app.

    If you are seeing this message, you are probably the developer.
    **Congratulations!** This is your app, ready to go. Now you just need to code it!

    Follow these steps to create a release of this app that can be included in the [Fair Ground catalog](https://www.appfair.net):

    1. Edit the `Info.plist` *CFBundleName*: `\(Bundle.mainBundleName)`
    2. Edit the `Info.plist` *CFBundleIdentifier*: `\(Bundle.mainBundleID)`
    3. Enable issues: [\(issuesURL.absoluteString)](\(issuesURL.absoluteString))
    4. Enable discussions: [\(discussionsURL.absoluteString)](\(discussionsURL.absoluteString))
    5. Enable actions: [\(actionsURL.absoluteString)](\(actionsURL.absoluteString))
    6. Edit the semver release in `Info.plist` *CFBundleShortVersionString*: `\(Bundle.main.bundleVersionString ?? "")`
    7. Commit and tag with semantic version
    8. Create an integration Pull Request: [\(compareURL.absoluteString)](\(compareURL.absoluteString))
    """))
                    .font(.title2)
                    .multilineTextAlignment(.leading)
            }

            Spacer()

            Text("[Free & Fair, Forever](https://www.appfair.net)", bundle: .module, comment: "footer link for template App Fair app")
                .font(.footnote)
                .lineLimit(1)
                .multilineTextAlignment(.center)
                .padding()
        }
        .multilineTextAlignment(.center)
        .allowsTightening(true)
        .textSelection(.enabled)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
#endif

#if canImport(SwiftUI)
import SwiftUI

struct SVGPathView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack(alignment: .center) {
            Circle()
                .fill(Color.red)

            // 200x400
            try! SVGPath("M0 0 L-200 200 L200 200 Z")
                .fill(Color.blue.opacity(0.50))

            // 200x200
            try! SVGPath("M200 0 L100 200 L300 200 Z")
                .inset(by: 70)
                .fill(Color.yellow.opacity(0.50))

            // 100x600
            try! SVGPath("M100 0 L0 600 L200 600 Z")
                .inset(by: 99)
                .fill(Color.green.opacity(0.50))

            //try? SVGPath("M 0 0 A 25 25 0 1 0 0 50Z")
                //.offset(x: 300, y: 0)
                //.inset(by: 100)
                //.offset(x: 100, y: 0)
                //.fill(Color.red.opacity(0.50))
        }
        .previewLayout(PreviewLayout.fixed(width: 300, height: 220))
    }
}
#endif
