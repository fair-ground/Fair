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

final class FairAppTests: XCTestCase {

    @available(macOS 11, iOS 14, *)
    func testCLIHelp() throws {
        try FairCLI(arguments: ["fairtool", "help"], environment: [:]).runCLI(operation: .help)
    }

    @available(macOS 11, iOS 14, *)
    func testCLICatalog() throws {
        try FairCLI(arguments: ["fairtool", "catalog", "--org", "App-Fair", "--fairseal-issuer", "appfairbot", "--hub", "github.com/appfair", "--token", ProcessInfo.processInfo.environment["GH_TOKEN"] ?? ProcessInfo.processInfo.environment["GITHUB_TOKEN"] ?? "", "--output", "/tmp/fairapps-\(UUID().uuidString).json"], environment: [:]).runCLI(operation: .catalog)
    }

    @available(macOS 11, iOS 14, *)
    func testFairBrowser() throws {
        //let url = URL(string: "https://www.appfair.net")!
        //let browser = FairBrowser(url: .constant(url))
        //XCTAssertEqual(nil, browser.web.url)
    }

    @available(macOS 12, iOS 15, *)
    func testLocalizable() throws {
        //let xyz = "XYZ"
        XCTAssertEqual("Cancel", loc("Cancel"))

        XCTAssertEqual("Cancel", String.localizedString(for: "Cancel"))
        XCTAssertEqual("Abbrechen", String.localizedString(for: "Cancel", locale: Locale(identifier: "de")))

        // Seems to not yet be working…

        // XCTAssertEqual("Cancel", String(localized: "Cancel", bundle: Bundle.fairApp, locale: Locale(identifier: "en")))
        // XCTAssertEqual("Abbrechen", String(localized: "Cancel", bundle: Bundle.fairApp, locale: Locale(identifier: "de")))
        // XCTAssertEqual("Cancelar", String(localized: "Cancel", bundle: Bundle.fairApp, locale: Locale(identifier: "es")))
        // XCTAssertEqual("Annuler", String(localized: "Cancel", bundle: Bundle.fairApp, locale: Locale(identifier: "fr")))
        // XCTAssertEqual("Annulla", String(localized: "Cancel", bundle: Bundle.fairApp, locale: Locale(identifier: "it")))
        // XCTAssertEqual("キャンセルする", String(localized: "Cancel", bundle: Bundle.fairApp, locale: Locale(identifier: "ja")))
    }

    func testJavaScript() throws {
        let wv = WKWebView()

        func checkJS() {
            XCTAssertEqual(3 as NSNumber, try wv.eval(js: "1+2"))
        }

        // warm up (~0.030 seconds)
        checkJS()

        measure(checkJS) // measured [Time, seconds] average: 0.000, relative standard deviation: 28.129%, values: [0.000374, 0.000208, 0.000206, 0.000183, 0.000181, 0.000173, 0.000201, 0.000247, 0.000172, 0.000162]

        XCTAssertThrowsError(try wv.eval(js: "x.y.z"))
        XCTAssertEqual(Double.infinity as NSNumber, try wv.eval(js: "1/0") as? NSNumber)
        XCTAssertEqual(Double.nan as NSNumber, try wv.eval(js: "Math.sqrt(-1)") as? NSNumber)
        XCTAssertEqual(Double.nan as NSNumber, try wv.eval(js: "{} + {}") as? NSNumber)

        XCTAssertEqual("[object Object]", try wv.eval(js: "[] + {}") as? NSString)
    }

    func testNameSuggestions() throws {
        print(try AppNameValidation.standard.suggestNames(count: 10))
    }
}
#endif
