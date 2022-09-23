/**
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
import XCTest
#if canImport(SwiftUI)
import WebKit
@testable import FairApp

final class FairAppTests: XCTestCase {

    @available(macOS 11, iOS 14, *)
    func testFairBrowser() throws {
        //let url = URL(string: "https://www.appfair.net")!
        //let browser = FairBrowser(url: .constant(url))
        //XCTAssertEqual(nil, browser.web.url)
    }

    @available(macOS 12, iOS 15, *)
    func XXXtestLocalizable() throws {
        //let xyz = "XYZ"
        XCTAssertEqual("Cancel", loc("Cancel"))

        XCTAssertEqual("Cancel", loc("Cancel"))
        XCTAssertEqual("Abbrechen", loc("Cancel", locale: Locale(identifier: "de")))
        XCTAssertEqual("キャンセルする", loc("Cancel", locale: Locale(identifier: "ja")))
        XCTAssertEqual("Отменить", loc("Cancel", locale: Locale(identifier: "ru")))
    }

    func testCatalogLocalizations() async throws {
        var localizations: [String: AppCatalogSource] = [:]
        do {
            let cat_fr = AppCatalog(name: "Le App Catalog", identifier: "net.cat_fr", homepage: URL(string: "https://apps.example.fr"), apps: [])
            localizations["fr_FR"] = AppCatalogSource(catalog: cat_fr)
        }

        do {
            let cat_es = AppCatalog(name: "El App Catalog", identifier: "net.cat_es", homepage: URL(string: "https://apps.example.es"), apps: [])
            localizations["es"] = AppCatalogSource(catalog: cat_es)
        }

        let cat = AppCatalog(name: "The App Catalog", identifier: "net.cat1", homepage: URL(string: "https://apps.example.com"), tintColor: "AA66BB", apps: [], localizations: localizations)

        do {
            let fr = Locale(identifier: "fr_FR")
            XCTAssertEqual("fr_FR", fr.identifier)
            XCTAssertEqual("fr", fr.languageCode)
            XCTAssertEqual("FR", fr.regionCode)

            let cat_fr = try await cat.localized(into: fr)
            XCTAssertEqual("Le App Catalog", cat_fr.name)
            XCTAssertEqual("net.cat_fr", cat_fr.identifier)
            XCTAssertEqual("https://apps.example.fr", cat_fr.homepage?.absoluteString)
            XCTAssertEqual("AA66BB", cat_fr.tintColor)
        }

        do {
            let cat_es = try await cat.localized(into: Locale(identifier: "es_ES"))
            XCTAssertEqual("El App Catalog", cat_es.name)
            XCTAssertEqual("net.cat_es", cat_es.identifier)
            XCTAssertEqual("https://apps.example.es", cat_es.homepage?.absoluteString)
            XCTAssertEqual("AA66BB", cat_es.tintColor)
        }


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

    func testHexColor() throws {
        XCTAssertEqual(HexColor(hexString: "ABCDEF"), HexColor(r: 0xAB, g: 0xCD, b: 0xEF, a: nil))
        XCTAssertEqual(HexColor(hexString: "ABCDEF00"), HexColor(r: 0xAB, g: 0xCD, b: 0xEF, a: 0))
        XCTAssertEqual(HexColor(hexString: "ABCDEFFF"), HexColor(r: 0xAB, g: 0xCD, b: 0xEF, a: 255))

        XCTAssertEqual(HexColor(hexString: "#ABCDEF"), HexColor(r: 0xAB, g: 0xCD, b: 0xEF, a: nil))
        XCTAssertEqual(HexColor(hexString: "#ABCDEF00"), HexColor(r: 0xAB, g: 0xCD, b: 0xEF, a: 0))
        XCTAssertEqual(HexColor(hexString: "#ABCDEFFF"), HexColor(r: 0xAB, g: 0xCD, b: 0xEF, a: 255))

        XCTAssertEqual(HexColor(hexString: "ABCDEF")?.colorString(hashPrefix: true), "#ABCDEF")
        XCTAssertEqual(HexColor(hexString: "ABCDEF00")?.colorString(hashPrefix: true), "#ABCDEF00")
        XCTAssertEqual(HexColor(hexString: "ABCDEF99")?.colorString(hashPrefix: false), "ABCDEF99")

    }

    /// Ensure that all the variants of `Assets.xcassets/AppIcon.appiconset/Contents.json` can be parsed into the same color value
    func testAssetIconSetParsing() throws {
        let contents = """
{
  "images" : [
    {
      "idiom" : "iphone",
      "scale" : "2x",
      "size" : "20x20"
    },
    {
      "idiom" : "iphone",
      "scale" : "3x",
      "size" : "20x20"
    },
    {
      "idiom" : "iphone",
      "scale" : "2x",
      "size" : "29x29"
    },
    {
      "idiom" : "iphone",
      "scale" : "3x",
      "size" : "29x29"
    },
    {
      "idiom" : "iphone",
      "scale" : "2x",
      "size" : "40x40"
    },
    {
      "idiom" : "iphone",
      "scale" : "3x",
      "size" : "40x40"
    },
    {
      "filename" : "appicon-iphone-60x60@2x.png",
      "idiom" : "iphone",
      "scale" : "2x",
      "size" : "60x60"
    },
    {
      "filename" : "appicon-iphone-60x60@3x.png",
      "idiom" : "iphone",
      "scale" : "3x",
      "size" : "60x60"
    },
    {
      "idiom" : "ipad",
      "scale" : "1x",
      "size" : "20x20"
    },
    {
      "idiom" : "ipad",
      "scale" : "2x",
      "size" : "20x20"
    },
    {
      "idiom" : "ipad",
      "scale" : "1x",
      "size" : "29x29"
    },
    {
      "idiom" : "ipad",
      "scale" : "2x",
      "size" : "29x29"
    },
    {
      "idiom" : "ipad",
      "scale" : "1x",
      "size" : "40x40"
    },
    {
      "idiom" : "ipad",
      "scale" : "2x",
      "size" : "40x40"
    },
    {
      "filename" : "appicon-ipad-76x76@1x.png",
      "idiom" : "ipad",
      "scale" : "1x",
      "size" : "76x76"
    },
    {
      "filename" : "appicon-ipad-76x76@2x.png",
      "idiom" : "ipad",
      "scale" : "2x",
      "size" : "76x76"
    },
    {
      "filename" : "appicon-ipad-83.5x83.5@2x.png",
      "idiom" : "ipad",
      "scale" : "2x",
      "size" : "83.5x83.5"
    },
    {
      "filename" : "appicon-ios-marketing-1024x1024@1x.png",
      "idiom" : "ios-marketing",
      "scale" : "1x",
      "size" : "1024x1024"
    },
    {
      "idiom" : "mac",
      "scale" : "1x",
      "size" : "16x16"
    },
    {
      "filename" : "appicon-mac-16x16@2x.png",
      "idiom" : "mac",
      "scale" : "2x",
      "size" : "16x16"
    },
    {
      "idiom" : "mac",
      "scale" : "1x",
      "size" : "32x32"
    },
    {
      "idiom" : "mac",
      "scale" : "2x",
      "size" : "32x32"
    },
    {
      "idiom" : "mac",
      "scale" : "1x",
      "size" : "128x128"
    },
    {
      "filename" : "appicon-mac-128x128@2x.png",
      "idiom" : "mac",
      "scale" : "2x",
      "size" : "128x128"
    },
    {
      "idiom" : "mac",
      "scale" : "1x",
      "size" : "256x256"
    },
    {
      "filename" : "appicon-mac-256x256@2x.png",
      "idiom" : "mac",
      "scale" : "2x",
      "size" : "256x256"
    },
    {
      "idiom" : "mac",
      "scale" : "1x",
      "size" : "512x512"
    },
    {
      "filename" : "appicon-mac-512x512@2x.png",
      "idiom" : "mac",
      "scale" : "2x",
      "size" : "512x512"
    }
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
"""

        let iconSet = try AppIconSet(json: contents.utf8Data)
        let json = try iconSet.json(outputFormatting: [.prettyPrinted, .sortedKeys]).utf8String
        XCTAssertEqual(contents, json)

        XCTAssertEqual("appicon-iphone-60x60@2x.png", iconSet.images(idiom: "iphone", scale: "2x", size: "60x60").first?.filename)
        XCTAssertEqual("appicon-iphone-60x60@3x.png", iconSet.images(idiom: "iphone", scale: "3x", size: "60x60").first?.filename)
        XCTAssertEqual("appicon-ipad-76x76@1x.png", iconSet.images(idiom: "ipad", scale: "1x", size: "76x76").first?.filename)
        XCTAssertEqual("appicon-ipad-76x76@2x.png", iconSet.images(idiom: "ipad", scale: "2x", size: "76x76").first?.filename)
        XCTAssertEqual("appicon-ipad-83.5x83.5@2x.png", iconSet.images(idiom: "ipad", scale: "2x", size: "83.5x83.5").first?.filename)
        XCTAssertEqual("appicon-ios-marketing-1024x1024@1x.png", iconSet.images(idiom: "ios-marketing", scale: "1x", size: "1024x1024").first?.filename)
        XCTAssertEqual("appicon-mac-16x16@2x.png", iconSet.images(idiom: "mac", scale: "2x", size: "16x16").first?.filename)
        XCTAssertEqual("appicon-mac-128x128@2x.png", iconSet.images(idiom: "mac", scale: "2x", size: "128x128").first?.filename)
        XCTAssertEqual("appicon-mac-256x256@2x.png", iconSet.images(idiom: "mac", scale: "2x", size: "256x256").first?.filename)
        XCTAssertEqual("appicon-mac-512x512@2x.png", iconSet.images(idiom: "mac", scale: "2x", size: "512x512").first?.filename)

    }

    func testSVGPath() throws {
        for p1 in [
            try SVGPath("M200 0 L100 200 L300 200 Z"),
            try SVGPath("m200 0 l-100 200 l200 0 z"),
        ] {
            XCTAssertEqual(p1.cgPath.boundingBoxOfPath, p1.cgPath.boundingBox)
            XCTAssertEqual(p1.cgPath.boundingBoxOfPath, CGRect(x: 100, y: 0, width: 200, height: 200))
            XCTAssertEqual("m200,0l-100,200h200z", p1.cgPath.svgPath())
        }

        let p2 = try SVGPath("M100 0 L0 200 L200 200 Z")
        XCTAssertEqual(p2.cgPath.boundingBoxOfPath, CGRect(x: 0, y: 0, width: 200, height: 200))

        let p3 = try SVGPath("M0 0 L-100 200 L100 200 Z")
        XCTAssertEqual(p3.cgPath.boundingBoxOfPath, CGRect(x: -100, y: 0, width: 200, height: 200))

        XCTAssertNotEqual(p2.cgPath, p3.cgPath)
        XCTAssertEqual(p2.cgPath.boundingBox.size, p3.cgPath.boundingBox.size)

        let complexShape = "M380.5 105.906C380.1 105.906 379.813 106.194 379.812 106.594L379.812 111.406C379.812 111.706 379.613 111.906 379.312 111.906C370.012 112.806 360.987 114.394 352.188 116.594C351.788 116.694 351.406 116.812 350.906 116.812L321.812 116.812C321.312 116.812 320.906 117.188 320.906 117.688L320.906 127.312C320.906 127.713 320.712 128.112 320.312 128.312C310.312 133.113 300.8 138.906 292 145.406C291.6 145.706 291.187 145.812 290.688 145.812L272.094 145.812C271.594 145.812 271.188 146.188 271.188 146.688L271.188 162.594C271.188 163.194 270.994 163.694 270.594 164.094C262.594 172.294 255.388 181.3 249.188 191C248.988 191.4 248.587 191.594 248.188 191.594L234.5 191.594C234 191.594 233.5 191.994 233.5 192.594L233.5 215.094C233.5 216.494 233.7 217.888 234 219.188C234.1 219.588 234.106 220.006 233.906 220.406C230.706 228.206 228.094 236.294 226.094 244.594C225.994 244.994 225.588 245.313 225.188 245.312L214.5 245.312C214.1 245.312 213.812 245.6 213.812 246L213.812 268.812C213.812 274.212 216.487 279.006 220.688 281.906C220.988 282.106 221.187 282.512 221.188 282.812C221.188 283.812 221.188 284.688 221.188 285.688C221.188 291.587 221.494 297.388 222.094 303.188C222.094 303.688 221.813 304.094 221.312 304.094L215.5 304.094C215 304.094 214.688 304.506 214.688 304.906L214.688 327.594C214.688 336.094 221.506 343.106 229.906 343.406C230.006 343.406 230.294 343.406 230.594 343.406C230.894 343.406 231.213 343.606 231.312 343.906C233.113 348.906 235.112 353.794 237.312 358.594C237.412 358.894 237.206 359.313 236.906 359.312L234.688 359.312C234.287 359.312 234 359.6 234 360L234 382.312C234 390.812 240.506 398 248.906 398.5C252.806 398.7 256.506 397.512 259.406 395.312C259.706 395.113 260.106 395.106 260.406 395.406C264.306 400.206 268.412 404.794 272.812 409.094C273.113 409.394 273.187 409.694 273.188 410.094L273.188 427.188C273.188 435.788 279.806 443.106 288.406 443.406C295.106 443.706 300.906 439.794 303.406 434.094C303.506 433.794 303.887 433.706 304.188 433.906C310.288 437.706 316.594 441.094 323.094 444.094C323.394 444.294 323.594 444.6 323.594 445L323.594 455.312C323.594 455.613 323.594 455.887 323.594 456.188C323.594 456.887 323.513 457.494 323.312 458.094L312.594 487.188C312.294 487.988 311.613 488.5 310.812 488.5L284.094 488.5C283.494 488.5 283 488.994 283 489.594L283 506L358.688 506L358.688 489.594C358.688 488.994 358.194 488.5 357.594 488.5L331.812 488.5C331.312 488.5 330.894 488 331.094 487.5L337 471.5C337.1 471.2 337.512 471 337.812 471C338.312 471.1 338.906 471.094 339.406 471.094C347.806 471.094 354.687 464.487 355.188 456.188C355.188 455.688 355.694 455.4 356.094 455.5C363.594 457.3 371.287 458.513 379.188 459.312C379.587 459.312 379.906 459.6 379.906 460L379.906 467.5C379.906 476 387.206 483.687 395.906 483.688C404.606 483.688 411.906 476 411.906 467.5L411.906 460C411.906 459.6 412.194 459.313 412.594 459.312C420.494 458.613 428.187 457.3 435.688 455.5C436.188 455.4 436.594 455.687 436.594 456.188C437.094 464.488 444.006 471.094 452.406 471.094C453.006 471.094 453.5 471.1 454 471C454.4 471 454.713 471.2 454.812 471.5L460.688 487.5C460.887 488 460.5 488.5 460 488.5L434.188 488.5C433.587 488.5 433.094 488.994 433.094 489.594L433.094 506L508.812 506L508.812 489.594C508.812 488.994 508.287 488.5 507.688 488.5L481 488.5C480.2 488.5 479.387 487.987 479.188 487.188L468.5 458.094C468.3 457.494 468.088 456.787 468.188 456.188C468.188 455.887 468.188 455.613 468.188 455.312L468.188 445C468.188 444.6 468.387 444.294 468.688 444.094C475.188 441.094 481.494 437.706 487.594 433.906C487.894 433.706 488.206 433.794 488.406 434.094C491.006 439.794 496.806 443.606 503.406 443.406C512.006 443.106 518.594 435.687 518.594 427.188L518.594 410.094C518.594 409.694 518.8 409.294 519 409.094C523.4 404.794 527.506 400.206 531.406 395.406C531.606 395.106 532.106 395.112 532.406 395.312C535.306 397.512 538.906 398.7 542.906 398.5C551.306 398 557.813 390.813 557.812 382.312L557.812 360C557.812 359.6 557.494 359.313 557.094 359.312L554.906 359.312C554.606 359.312 554.3 358.894 554.5 358.594C556.7 353.794 558.7 348.906 560.5 343.906C560.6 343.606 560.887 343.406 561.188 343.406C561.487 343.406 561.806 343.406 561.906 343.406C570.406 343.106 577.094 336.094 577.094 327.594L577.094 305C577.094 304.5 576.713 304.188 576.312 304.188L570.5 304.188C570 304.188 569.587 303.812 569.688 303.312C570.288 297.512 570.594 291.713 570.594 285.812C570.594 284.812 570.594 283.906 570.594 282.906C570.394 282.506 570.606 282.106 570.906 281.906C575.106 279.106 577.813 274.312 577.812 268.812L577.812 246C577.812 245.6 577.494 245.312 577.094 245.312L566.406 245.312C566.006 245.312 565.6 244.994 565.5 244.594C563.5 236.294 560.887 228.206 557.688 220.406C557.487 220.006 557.494 219.587 557.594 219.188C557.894 217.887 558.094 216.494 558.094 215.094L558.094 192.594C558.094 192.094 557.694 191.594 557.094 191.594L543.406 191.594C543.006 191.594 542.606 191.4 542.406 191C536.106 181.4 529 172.394 521 164.094C520.6 163.694 520.406 163.194 520.406 162.594L520.406 146.688C520.406 146.188 520 145.812 519.5 145.812L500.906 145.812C500.406 145.812 499.994 145.706 499.594 145.406C490.794 138.806 481.313 133.112 471.312 128.312C470.913 128.113 470.687 127.812 470.688 127.312L470.688 117.688C470.688 117.188 470.313 116.812 469.812 116.812L440.688 116.812C440.288 116.812 439.806 116.694 439.406 116.594C430.606 114.294 421.612 112.706 412.312 111.906C412.012 111.906 411.812 111.706 411.812 111.406L411.812 106.594C411.812 106.194 411.494 105.906 411.094 105.906L395.812 105.906L380.5 105.906ZM379.312 122.906C379.613 122.906 379.906 123.106 379.906 123.406L379.906 129.406C379.906 136.906 385.1 143.112 392 144.812C392.3 144.912 392.594 145.2 392.594 145.5L392.594 202.906L392.688 202.906C392.688 203.706 392.113 204.312 391.312 204.312C384.812 204.713 378.506 205.794 372.406 207.594C371.706 207.794 370.894 207.388 370.594 206.688L350 150C349.9 149.7 349.894 149.394 350.094 149.094C351.794 146.594 352.687 143.606 352.688 140.406L352.688 128.5C352.688 128.1 352.913 127.788 353.312 127.688C361.712 125.388 370.412 123.806 379.312 122.906ZM412.5 123C421.4 123.9 430.1 125.512 438.5 127.812C438.9 127.912 439.094 128.194 439.094 128.594L439.094 140.5C439.094 143.7 440.088 146.688 441.688 149.188C441.887 149.488 441.913 149.794 441.812 150.094L421.188 206.812C420.887 207.512 420.206 207.888 419.406 207.688C413.406 205.887 407.1 204.806 400.5 204.406C399.7 204.406 399.094 203.7 399.094 203L399.094 145.594L399.188 145.594C399.188 145.194 399.513 144.906 399.812 144.906C406.812 143.206 411.906 137 411.906 129.5L411.906 123.5C411.906 123.2 412.2 123 412.5 123ZM471.312 140.688C476.913 143.588 483.087 147.194 488.188 150.594C488.587 150.794 488.813 151.188 488.812 151.688L488.812 166.5C488.812 166.6 488.812 168.194 488.812 169.094C488.812 169.594 488.613 170.006 488.312 170.406L446.594 220.094C446.094 220.694 445.194 220.812 444.594 220.312C439.494 216.512 434 213.288 428 210.688C427.3 210.387 426.887 209.606 427.188 208.906L446.906 154.688C447.206 154.488 447.513 154.4 447.812 154.5C451.212 156.2 455.3 156.7 459.5 155.5C465.9 153.7 470.287 147.794 470.688 141.094C470.688 140.794 471.013 140.588 471.312 140.688ZM320.594 140.812C320.894 140.613 321.188 140.888 321.188 141.188C321.488 147.787 325.906 153.694 332.406 155.594C336.706 156.794 340.694 156.294 344.094 154.594C344.394 154.494 344.713 154.606 344.812 154.906L364.5 209.094C364.8 209.794 364.387 210.606 363.688 210.906C357.788 213.506 352.194 216.7 347.094 220.5C346.494 221 345.594 220.912 345.094 220.312L303.406 170.594C303.106 170.194 302.906 169.812 302.906 169.312C302.906 168.412 302.906 166.788 302.906 166.688L303.094 151.812C303.094 151.412 303.288 150.988 303.688 150.688C308.788 147.287 314.994 143.712 320.594 140.812ZM518.812 177.812C522.513 182.113 526.106 186.494 529.406 191.094C529.506 191.294 529.387 191.594 529.188 191.594L527.312 191.594C526.913 191.594 526.594 191.913 526.594 192.312L526.594 205.688C526.594 206.188 526.306 206.606 525.906 206.906L466 241.5C465.3 241.9 464.494 241.7 464.094 241C460.594 235.6 456.513 230.712 451.812 226.312C451.212 225.812 451.187 224.912 451.688 224.312L490.594 178C490.794 177.8 491.206 177.794 491.406 178.094C494.206 182.394 499.094 185.188 504.594 185.188C510.194 185.188 515.106 182.306 517.906 177.906C518.106 177.606 518.513 177.512 518.812 177.812ZM273.094 177.906C273.294 177.606 273.8 177.7 274 178C276.8 182.4 281.712 185.313 287.312 185.312C292.812 185.312 297.7 182.487 300.5 178.188C300.7 177.887 301.106 177.894 301.406 178.094L340.312 224.406C340.812 225.006 340.688 225.806 340.188 226.406C335.488 230.806 331.406 235.694 327.906 241.094C327.506 241.694 326.6 241.894 326 241.594L266 206.906C265.6 206.706 265.312 206.187 265.312 205.688L265.312 192.312C265.312 191.912 264.994 191.594 264.594 191.594L262.688 191.594C262.488 191.694 262.4 191.388 262.5 191.188C265.8 186.588 269.294 182.106 273.094 177.906ZM400.312 210.812C406.212 211.113 411.906 212.212 417.406 213.812C418.006 214.012 418.294 214.588 418.094 215.188L401.188 261.594C400.988 262.094 400.594 262.288 400.094 262.188C399.594 262.087 399.187 261.688 399.188 261.188L399.188 211.906C399.188 211.306 399.713 210.812 400.312 210.812ZM391.594 210.906C392.194 210.906 392.687 211.4 392.688 212L392.688 261.312C392.688 261.812 392.313 262.213 391.812 262.312C391.312 262.413 390.787 262.087 390.688 261.688L373.812 215.312C373.613 214.713 373.9 214.106 374.5 213.906C380 212.306 385.694 211.206 391.594 210.906ZM266 214.406L322.688 247.094C323.387 247.494 323.613 248.3 323.312 249C320.413 254.7 318.187 260.7 316.688 267C316.488 267.7 315.8 268.194 315 268.094L246.812 256.094C246.213 255.994 245.813 255.506 245.812 254.906L245.812 246C245.812 245.6 245.494 245.312 245.094 245.312L238.312 245.312C237.812 245.412 237.494 244.9 237.594 244.5C238.894 239.6 240.394 234.7 242.094 230C242.194 229.6 242.694 229.394 243.094 229.594C245.794 230.794 249.013 231.288 252.312 230.688C259.913 229.387 265.406 222.487 265.406 214.688C265.406 214.387 265.7 214.206 266 214.406ZM526 214.406C526.3 214.306 526.594 214.388 526.594 214.688C526.494 222.488 531.894 229.388 539.594 230.688C542.894 231.287 546.013 230.794 548.812 229.594C549.212 229.394 549.712 229.6 549.812 230C551.513 234.7 553.012 239.6 554.312 244.5C554.413 244.9 554.087 245.313 553.688 245.312L546.906 245.312C546.506 245.312 546.187 245.6 546.188 246L546.188 254.906C546.188 255.506 545.788 255.994 545.188 256.094L477 268.094C476.2 268.194 475.512 267.7 475.312 267C473.812 260.7 471.587 254.7 468.688 249C468.387 248.3 468.613 247.494 469.312 247.094L526 214.406ZM366.188 216.812C366.788 216.613 367.387 216.806 367.688 217.406L384.594 263.812C384.794 264.312 384.594 264.8 384.094 265C383.694 265.2 383.113 265.213 382.812 264.812L351 227.094C350.6 226.594 350.687 225.9 351.188 225.5C355.788 222.1 360.787 219.112 366.188 216.812ZM424.812 216.875C425.087 216.762 425.388 216.756 425.688 216.906C430.988 219.206 436.088 222.094 440.688 225.594C441.188 225.994 441.306 226.688 440.906 227.188L409.094 264.906C408.794 265.306 408.213 265.394 407.812 265.094C407.413 264.894 407.213 264.306 407.312 263.906L424.188 217.5C424.288 217.2 424.538 216.988 424.812 216.875ZM345.25 230.906C345.538 230.919 345.8 231.062 346 231.312L377.688 269.094C378.087 269.494 378.088 270.106 377.688 270.406C377.387 270.806 376.806 270.887 376.406 270.688L333.688 246C333.188 245.7 333.012 245 333.312 244.5C336.512 239.7 340.206 235.188 344.406 231.188C344.656 230.988 344.962 230.894 345.25 230.906ZM446.562 230.906C446.85 230.894 447.156 230.988 447.406 231.188C451.606 235.188 455.3 239.6 458.5 244.5C458.8 245 458.694 245.7 458.094 246L415.312 270.688C414.913 270.887 414.3 270.8 414 270.5C413.8 270.1 413.794 269.494 414.094 269.094L445.812 231.312C446.012 231.062 446.275 230.919 446.562 230.906ZM329.562 251.531C329.838 251.456 330.156 251.488 330.406 251.688L373.188 276.406C373.587 276.606 373.794 277.194 373.594 277.594C373.394 278.094 373 278.313 372.5 278.312L323.906 269.688C323.206 269.587 322.8 269.006 323 268.406C324.4 262.706 326.406 257.294 328.906 252.094C329.056 251.794 329.287 251.606 329.562 251.531ZM462.219 251.594C462.494 251.669 462.756 251.844 462.906 252.094C465.506 257.194 467.512 262.706 468.812 268.406C468.913 269.006 468.506 269.587 467.906 269.688L419.312 278.312C418.812 278.413 418.287 278.094 418.188 277.594C417.988 277.094 418.194 276.606 418.594 276.406L461.406 251.688C461.656 251.537 461.944 251.519 462.219 251.594ZM246.5 262.594L313.906 274.5C314.706 274.6 315.194 275.294 315.094 276.094C314.694 279.194 314.5 282.387 314.5 285.688C314.5 288.988 314.694 292.113 315.094 295.312C315.194 296.113 314.706 296.806 313.906 296.906L247.406 308.594C247.006 308.694 246.594 308.406 246.594 307.906L246.594 304.906C246.594 304.406 246.213 304.094 245.812 304.094L234.188 304.094C233.787 304.094 233.406 303.813 233.406 303.312C232.806 297.312 232.406 291.194 232.406 285.094C232.406 284.694 232.694 284.413 233.094 284.312C240.294 282.913 245.813 276.512 245.812 268.812L245.812 263.094C245.812 262.794 246.1 262.494 246.5 262.594ZM545.594 262.688C545.894 262.587 546.313 262.888 546.312 263.188L546.312 268.906C546.312 276.606 551.8 282.906 559 284.406C559.4 284.506 559.687 284.787 559.688 285.188C559.487 291.288 559.194 297.406 558.594 303.406C558.594 303.806 558.213 304.187 557.812 304.188L546.312 304.188C545.812 304.188 545.5 304.6 545.5 305L545.5 308C545.5 308.4 545.087 308.688 544.688 308.688L478.188 297C477.387 296.9 476.9 296.206 477 295.406C477.4 292.306 477.594 289.113 477.594 285.812C477.594 282.512 477.4 279.387 477 276.188C476.9 275.387 477.387 274.694 478.188 274.594L545.594 262.688ZM322.688 276.094L371.312 284.688C371.812 284.788 372.187 285.187 372.188 285.688C372.188 286.188 371.813 286.588 371.312 286.688L322.688 295.312C322.087 295.413 321.506 295.006 321.406 294.406C321.106 291.606 320.906 288.687 320.906 285.688C320.906 282.788 321.106 279.9 321.406 277C321.506 276.4 322.087 275.994 322.688 276.094ZM469.094 276.094C469.694 275.994 470.306 276.4 470.406 277C470.706 279.8 470.906 282.687 470.906 285.688C470.906 288.587 470.706 291.506 470.406 294.406C470.306 295.006 469.694 295.412 469.094 295.312L420.5 286.688C420 286.587 419.594 286.188 419.594 285.688C419.594 285.188 420 284.787 420.5 284.688L469.094 276.094ZM372.406 293.094C372.906 292.994 373.4 293.313 373.5 293.812C373.7 294.312 373.494 294.8 373.094 295L330.312 319.688C329.812 319.988 329.113 319.812 328.812 319.312C326.212 314.212 324.206 308.7 322.906 303C322.806 302.5 323.212 301.887 323.812 301.688L372.406 293.094ZM419.406 293.188L468 301.812C468.6 301.913 469.006 302.494 468.906 303.094C467.506 308.794 465.5 314.206 463 319.406C462.7 320.006 462 320.212 461.5 319.812L418.688 295.094C418.288 294.894 418.113 294.306 418.312 293.906C418.512 293.406 418.906 293.187 419.406 293.188ZM414.719 300.625C414.956 300.587 415.206 300.662 415.406 300.812L458.188 325.5C458.688 325.8 458.894 326.5 458.594 327C455.394 331.8 451.7 336.312 447.5 340.312C447 340.712 446.306 340.688 445.906 340.188L414.094 302.312C413.794 301.913 413.794 301.4 414.094 301C414.244 300.8 414.481 300.663 414.719 300.625ZM376.5 300.688C376.9 300.488 377.513 300.606 377.812 300.906C378.113 301.306 378.113 301.787 377.812 302.188L346 340.094C345.6 340.594 344.906 340.588 344.406 340.188C340.206 336.188 336.512 331.806 333.312 326.906C333.012 326.406 333.088 325.706 333.688 325.406L376.5 300.688ZM314.812 303.188C315.613 303.087 316.3 303.613 316.5 304.312C318 310.613 320.194 316.613 323.094 322.312C323.394 323.012 323.2 323.788 322.5 324.188L262.5 359C262.1 359.2 261.712 359.313 261.312 359.312L250.312 359.312C250.012 359.312 249.794 359.106 249.594 358.906C246.494 352.806 243.8 346.412 241.5 339.812C241.4 339.512 241.488 339.113 241.688 338.812C244.588 335.913 246.406 331.994 246.406 327.594L246.406 316C246.406 315.6 246.7 315.287 247 315.188L314.812 303.188ZM476.906 303.312L544.688 315.312C545.087 315.413 545.313 315.694 545.312 316.094L545.312 327.688C545.312 332.087 547.1 336.006 550 338.906C550.3 339.106 550.413 339.512 550.312 339.812C548.013 346.413 545.287 352.706 542.188 358.906C542.087 359.206 541.8 359.313 541.5 359.312L530.5 359.312C530.1 359.312 529.713 359.2 529.312 359L469.188 324.312C468.488 323.913 468.294 323.106 468.594 322.406C471.494 316.706 473.687 310.706 475.188 304.406C475.387 303.706 476.106 303.212 476.906 303.312ZM374.781 316.719C374.981 316.844 375.1 317.106 375 317.406L362.5 351.5C362.3 352.1 361.6 352.394 361 352.094C357.6 350.294 354.287 348.206 351.188 345.906C350.688 345.506 350.6 344.813 351 344.312L374.094 316.812C374.294 316.613 374.581 316.594 374.781 316.719ZM417.125 316.75C417.325 316.637 417.613 316.656 417.812 316.906L440.906 344.406C441.206 344.806 441.187 345.506 440.688 345.906C437.587 348.206 434.306 350.294 430.906 352.094C430.306 352.394 429.606 352.1 429.406 351.5L416.906 317.406C416.806 317.106 416.925 316.863 417.125 316.75ZM399.688 322.344C399.937 322.294 400.213 322.387 400.312 322.688L413 357.406C413.2 358.006 412.887 358.713 412.188 358.812C408.288 359.712 404.413 360.2 400.312 360.5C399.712 360.5 399.187 360.006 399.188 359.406L399.188 322.906C399.188 322.606 399.438 322.394 399.688 322.344ZM392.219 322.438C392.469 322.488 392.687 322.7 392.688 323L392.688 359.5C392.688 360.1 392.194 360.594 391.594 360.594C387.494 360.394 383.588 359.806 379.688 358.906C379.087 358.806 378.706 358.1 378.906 357.5L391.594 322.812C391.694 322.512 391.969 322.387 392.219 322.438ZM326.875 329.844C327.213 329.931 327.488 330.15 327.688 330.5C331.188 335.9 335.3 340.787 340 345.188C340.6 345.688 340.594 346.588 340.094 347.188L292.5 404C292.3 404.2 292.113 404.313 291.812 404.312L283.812 404.312C283.613 404.312 283.294 404.2 283.094 404C276.894 398.1 271.2 391.706 266 384.906C265.8 384.606 265.587 384.213 265.688 383.812C265.688 383.512 265.688 383.112 265.688 382.812L265.688 365.312C265.688 364.913 265.887 364.606 266.188 364.406L325.812 330C326.163 329.8 326.537 329.756 326.875 329.844ZM464.969 329.906C465.319 329.819 465.7 329.85 466 330L525.594 364.406C525.894 364.606 526.094 365.012 526.094 365.312L526.094 382.812C526.094 383.113 526.094 383.513 526.094 383.812C526.194 384.212 526.106 384.7 525.906 385C520.706 391.8 515.013 398.194 508.812 404.094C508.613 404.294 508.394 404.406 508.094 404.406L500.094 404.406C499.794 404.406 499.606 404.294 499.406 404.094L451.688 347.188C451.188 346.587 451.313 345.787 451.812 345.188C456.512 340.788 460.594 335.9 464.094 330.5C464.294 330.2 464.619 329.994 464.969 329.906ZM346.156 350.688C346.519 350.65 346.888 350.75 347.188 351C350.788 353.7 354.687 356.087 358.688 358.188C359.288 358.488 359.706 359.3 359.406 360L333.188 431.406C333.087 431.706 332.8 431.906 332.5 431.906L323.094 431.906C322.794 431.906 322.394 431.787 322.094 431.688C316.294 428.788 310.806 425.5 305.406 422C305.106 421.8 304.906 421.4 304.906 421L304.906 404.906C304.906 404.606 304.612 404.312 304.312 404.312L301.312 404.312C301.012 404.312 300.894 404.012 301.094 403.812L345.188 351.188C345.438 350.887 345.794 350.725 346.156 350.688ZM445.75 350.688C446.113 350.725 446.437 350.888 446.688 351.188L490.812 403.812C490.913 404.012 490.8 404.312 490.5 404.312L487.5 404.312C487.2 404.312 486.906 404.606 486.906 404.906L486.906 421C486.906 421.4 486.706 421.8 486.406 422C481.106 425.6 475.487 428.787 469.688 431.688C469.387 431.887 469.088 431.906 468.688 431.906L459.312 431.906C459.012 431.906 458.694 431.706 458.594 431.406L432.5 360C432.2 359.3 432.587 358.588 433.188 358.188C437.188 356.087 441.088 353.7 444.688 351C444.988 350.75 445.387 350.65 445.75 350.688ZM377.594 365.094C382.094 366.094 386.7 366.794 391.5 367.094C392.3 367.094 392.906 367.8 392.906 368.5L392.906 443.688L392.688 443.688C392.688 444.188 392.306 444.5 391.906 444.5L380.906 444.5C380.406 444.5 380.094 444.912 380.094 445.312L380.094 447.594C380.094 448.094 379.687 448.406 379.188 448.406C371.288 447.606 363.594 446.213 356.094 444.312C355.694 444.212 355.5 443.9 355.5 443.5L355.5 432.688C355.5 432.188 355.088 431.906 354.688 431.906L352.406 431.906C352.106 431.906 351.9 431.613 352 431.312L375.906 366C376.206 365.3 376.894 364.894 377.594 365.094ZM414.594 365.094C415.294 364.894 416.013 365.3 416.312 366L440.188 431.312C440.188 431.613 439.894 431.906 439.594 431.906L437.312 431.906C436.812 431.906 436.5 432.287 436.5 432.688L436.5 443.5C436.5 443.9 436.206 444.213 435.906 444.312C428.406 446.212 420.713 447.606 412.812 448.406C412.312 448.406 411.906 448.094 411.906 447.594L411.906 445.312C411.906 444.812 411.494 444.5 411.094 444.5L400.094 444.5C399.594 444.5 399.313 444.088 399.312 443.688L399.312 368.5C399.312 367.7 399.887 367.094 400.688 367.094C405.387 366.794 410.094 366.194 414.594 365.094ZM414.594 365.094"

        let complexPath = try SVGPath(complexShape)

        XCTAssertEqual(complexShape, complexPath.cgPath.svgPath([.absolute, .spaces]))

        XCTAssertNotEqual(complexShape, complexPath.cgPath.svgPath([.absolute]))
        XCTAssertNotEqual(complexShape, complexPath.cgPath.svgPath([.spaces]))
        XCTAssertNotEqual(complexShape, complexPath.cgPath.svgPath([]))

        let tint = Color(hue: Double.random(in: 0.0...1.0), saturation: 1.0, brightness: 1.0).opacity(0.8)
        let path = complexPath.fill(tint)

        #if os(macOS)

        let _ = ZStack(alignment: .center) {
            Circle()
                .stroke(tint, lineWidth: 30)

//            try! SVGPath("M200 0 L100 200 L300 200 Z")
//                .fill(Color.yellow.opacity(0.50))
//
//            try! SVGPath("M100 0 L0 200 L200 200 Z")
//                .fill(Color.green.opacity(0.50))
//
//            try! SVGPath("M0 0 L-100 200 L100 200 Z")
//                .fill(Color.blue.opacity(0.50))

            try! SVGPath("M0 0 L-200 200 L200 200 Z")
                .fill(Color.blue.opacity(0.50))

            try! SVGPath("M200 0 L100 200 L300 200 Z")
                .inset(by: 70)
                .fill(Color.yellow.opacity(0.50))

            try! SVGPath("M100 0 L0 600 L200 600 Z")
                .inset(by: 140)
                .fill(Color.green.opacity(0.50))

        }

        try path
            .png(bounds: CGRect(x: 0, y: 0, width: 250, height: 250))?
            .write(to: URL(fileURLWithPath: "\(NSTemporaryDirectory())/testSVGPath.png"))
        #endif
    }

    func testParsePackageResolved() throws {
        let resolved = """
        {
          "object": {
            "pins": [
              {
                "package": "Clang_C",
                "repositoryURL": "https://github.com/something/Clang_C.git",
                "state": {
                  "branch": null,
                  "revision": "90a9574276f0fd17f02f58979423c3fd4d73b59e",
                  "version": "1.0.2",
                }
              },
              {
                "package": "Commandant",
                "repositoryURL": "https://github.com/something/Commandant.git",
                "state": {
                  "branch": null,
                  "revision": "c281992c31c3f41c48b5036c5a38185eaec32626",
                  "version": "0.12.0"
                }
              }
            ]
          },
          "version": 1
        }
        """

        let pm = try JSONDecoder().decode(ResolvedPackage.self, from: resolved.utf8Data)
        XCTAssertEqual(2, pm.object?.pins.count ?? 0)
    }

    /// Ensures that a bare-bones minimal catalog can be loaded
    func testParseCatalog() throws {
        let catalog = try AppCatalog.parse(jsonData: """
        {
          "name": "My Catalog",
          "identifier": "a.b.c",
          "apps": [
            {
              "name": "My App",
              "bundleIdentifier": "x.y.z",
              "downloadURL": "https://www.example.com/MyApp.ipa"
            }
          ]
        }
        """.utf8Data)

        XCTAssertEqual("My App", catalog.apps.first?.name)
    }
}

#endif
