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

    /// Ensure that all the variants of `Assets.xcassets/AccentColor.colorset/Contents.json` can be parsed into the same color value
    func testColorParsing() throws {
        let contentsSystemGreen = """
{
  "colors" : [
    {
      "color" : {
        "platform" : "universal",
        "reference" : "systemGreenColor"
      },
      "idiom" : "universal"
    },
    {
      "appearances" : [
        {
          "appearance" : "luminosity",
          "value" : "dark"
        }
      ],
      "idiom" : "universal"
    }
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
"""

        let contentsFloatingPoint = """
{
  "colors" : [
    {
      "color" : {
        "color-space" : "srgb",
        "components" : {
          "alpha" : "1.000",
          "blue" : "0.351",
          "green" : "0.782",
          "red" : "0.206"
        }
      },
      "idiom" : "universal"
    },
    {
      "appearances" : [
        {
          "appearance" : "luminosity",
          "value" : "dark"
        }
      ],
      "idiom" : "universal"
    }
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
"""

        let contents8BitInteger = """
{
  "colors" : [
    {
      "color" : {
        "color-space" : "srgb",
        "components" : {
          "alpha" : "1.000",
          "blue" : "89",
          "green" : "199",
          "red" : "52"
        }
      },
      "idiom" : "universal"
    },
    {
      "appearances" : [
        {
          "appearance" : "luminosity",
          "value" : "dark"
        }
      ],
      "idiom" : "universal"
    }
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
"""

        let contents8BitHex = """
{
  "colors" : [
    {
      "color" : {
        "color-space" : "srgb",
        "components" : {
          "alpha" : "1.000",
          "blue" : "0x59",
          "green" : "0xC7",
          "red" : "0x34"
        }
      },
      "idiom" : "universal"
    },
    {
      "appearances" : [
        {
          "appearance" : "luminosity",
          "value" : "dark"
        }
      ],
      "idiom" : "universal"
    }
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
"""

        var colorValues: Array<String> = []

        for contents in [
            contentsSystemGreen,
            contentsFloatingPoint,
            contents8BitInteger,
            contents8BitHex
        ] {
            let colorList = try AccentColorList(json: contents.utf8Data)
            guard let colorValue = colorList.firstRGBHex else {
                return XCTFail("could not parse color list")
            }
            colorValues.append(colorValue)
        }

        XCTAssertEqual(4, colorValues.count)
        XCTAssertEqual(1, Set(colorValues).count, "color values should have all been the same value: \(colorValues)")

    }

    func testAssetNames() throws {
        try XCTAssertEqual(AssetName(string: "ani_gif-10x20.gif"), AssetName(base: "ani_gif", idiom: nil, width: 10, height: 20, scale: nil, ext: "gif"))

        try XCTAssertEqual(AssetName(string: "appicon-ipad-83.5x83.5@2x.png"), AssetName(base: "appicon", idiom: "ipad", width: 83.5, height: 83.5, scale: 2, ext: "png"))
        try XCTAssertEqual(AssetName(string: "appicon-ipad-83.5x83.5.png"), AssetName(base: "appicon", idiom: "ipad", width: 83.5, height: 83.5, scale: nil, ext: "png"))
        try XCTAssertEqual(AssetName(string: "appicon-iphone-60x60@2x.png"), AssetName(base: "appicon", idiom: "iphone", width: 60, height: 60, scale: 2, ext: "png"))
        try XCTAssertEqual(AssetName(string: "appicon-iphone-60x60@3x.png"), AssetName(base: "appicon", idiom: "iphone", width: 60, height: 60, scale: 3, ext: "png"))
        try XCTAssertEqual(AssetName(string: "appicon-ipad-76x76@1x.png"), AssetName(base: "appicon", idiom: "ipad", width: 76, height: 76, scale: 1, ext: "png"))
        try XCTAssertEqual(AssetName(string: "appicon-ipad-76x76@2x.png"), AssetName(base: "appicon", idiom: "ipad", width: 76, height: 76, scale: 2, ext: "png"))

        try XCTAssertEqual(AssetName(string: "appicon-mac-16x16@2x.png"), AssetName(base: "appicon", idiom: "mac", width: 16, height: 16, scale: 2, ext: "png"))
        try XCTAssertEqual(AssetName(string: "appicon-mac-128x128@2x.png"), AssetName(base: "appicon", idiom: "mac", width: 128, height: 128, scale: 2, ext: "png"))
        try XCTAssertEqual(AssetName(string: "appicon-mac-256x256@2x.png"), AssetName(base: "appicon", idiom: "mac", width: 256, height: 256, scale: 2, ext: "png"))
        try XCTAssertEqual(AssetName(string: "appicon-mac-512x512@2x.png"), AssetName(base: "appicon", idiom: "mac", width: 512, height: 512, scale: 2, ext: "png"))

        try XCTAssertEqual(AssetName(string: "appicon-ios-marketing-1024x1024@1x.png"), AssetName(base: "appicon", idiom: "ios-marketing", width: 1024, height: 1024, scale: 1, ext: "png"))

        XCTAssertNoThrow(try AssetName(string: "XXX-YYY-1024x1024@1x.png"))
        XCTAssertThrowsError(try AssetName(string: "XXX-YYY-1024x1024@1.png"))
        XCTAssertThrowsError(try AssetName(string: "XXX-YYY-1024x1024@-3x.png"))
        XCTAssertThrowsError(try AssetName(string: "XXX-YYY-1024x1024@5x.png"))
        XCTAssertThrowsError(try AssetName(string: "XXX-YYY-ZZZx1024@1x.png"))
        XCTAssertThrowsError(try AssetName(string: "XXX-YYY-1024xZZZ@1x.png"))
        XCTAssertThrowsError(try AssetName(string: "XXX-YYY-ZZZx1024.png"))
        XCTAssertThrowsError(try AssetName(string: "XXX-YYY-1024xZZZ.png"))

        XCTAssertThrowsError(try AssetName(string: "XXX-YYY-1024x1024x@1x.png"))
        XCTAssertThrowsError(try AssetName(string: "XXX-YYY-1024x1024x@1x.png"))
        XCTAssertThrowsError(try AssetName(string: "XXX-YYY-1024xx1024@1x.pngxxx"))
    }
}

#endif
