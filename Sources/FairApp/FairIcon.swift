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
#if canImport(SwiftUI)
import SwiftUI
import FairCore

/// A view that generates the default icon for a FairApp, which is a squircle filled in with either the app's path if it exists, or else the name of the app.
public struct FairIconView : View, Equatable {
    /// The first word of the app's name
    var name: String
    /// A string to appear below the monogram
    let subtitle: String?
    /// System symbol names or SVG paths to emboss behind the monogram
    let paths: [String]
    /// The base color for the icon
    let iconColor: Color?
    /// Whether a raised border should be rendered
    let borderRatio: CGFloat
    /// The span factor for the corner radius
    let cornerRadiusFactor: CGFloat

    public init(_ name: String, subtitle: String?, paths: [String] = [], iconColor: Color? = nil, borderRatio: CGFloat = 0.00, cornerRadiusFactor: CGFloat? = nil) {
        self.name = name
        self.subtitle = subtitle
        self.paths = paths
        self.iconColor = iconColor
        self.borderRatio = borderRatio
        self.cornerRadiusFactor = cornerRadiusFactor ?? (100.0/22.5)
    }

    public var body: some View {
        GeometryReader { proxy in
            iconView(for: min(proxy.size.width, proxy.size.height))
        }
    }

    /// Returns the default icon color for the given app name, separated into two parts
    public static func iconColor(name: String) -> Color {
        return renderColor(name: name)
    }
    
    /// The default icon color for the two parts
    /// - Parameters:
    ///   - word1: the first word
    ///   - word2: the second word
    ///   - saturation: the color saturation
    ///   - brightness: the color brightness
    ///   - base: a base color to use rather than the word's seeded random
    /// - Returns: the color to use for rendering
    static func renderColor(name: String, saturation: CGFloat = 0.99, brightness: CGFloat = 0.8, base: Color? = nil) -> Color {
        let wordHue = name.derivedComponent
        var hue = wordHue

        // if we have specified a base color, use the hue as the basis for our app
        if let base = base, let cgColor = base.cgColor {
            if let rgbColor = cgColor.converted(to: CGColorSpaceCreateDeviceRGB(), intent: .defaultIntent, options: nil) {
                #if canImport(AppKit)
                if let uxColor = (NSColor(cgColor: rgbColor) as NSColor?) {
                    uxColor.getHue(&hue, saturation: nil, brightness: nil, alpha: nil)
                }
                #endif
                #if canImport(UIKit)
                if let uxColor = (UIColor(cgColor: rgbColor) as UIColor?) {
                    uxColor.getHue(&hue, saturation: nil, brightness: nil, alpha: nil)
                }
                #endif
            }
        }
        let color = Color(hue: hue, saturation: saturation, brightness: brightness)
        return color
    }
    
    func iconFont(size: CGFloat) -> Font {
        Font.system(size: size, design: Font.Design.rounded)
            .weight(.bold)
//            .smallCaps()
        //Font.system(size: size).smallCaps()
    }

    func iconView(for span: CGFloat) -> some View {
        let parts = name.components(separatedBy: CharacterSet.alphanumerics.inverted)
        let monogram = String(parts.map(\.first).compacted()).uppercased()

        // create a top-down gradient of the brighter color
        func clr(s: CGFloat, b: CGFloat) -> Color {
            Self.renderColor(name: name, saturation: s, brightness: b, base: iconColor)
        }

        let c1 = clr(s: 0.5, b: 0.9)
        let c2 = clr(s: 0.9, b: 0.5)
        let c3 = clr(s: 0.7, b: 0.75)

        let gradient = Gradient(colors: [c1, c2])

        let fillStyle = LinearGradient(gradient: gradient, startPoint: .top, endPoint: .bottom)
        //let fillStyle = RadialGradient(gradient: gradient, center: .center, startRadius: 0, endRadius: span*0.6)

        let textColor = Color.white

        let rect = CGRect(origin: .zero, size: CGSize(width: span, height: span))

        let squircle = RoundedRectangle(cornerRadius: cornerRadiusFactor == 0.0 ? 0 : (span / cornerRadiusFactor), style: .continuous)
        func borderMask(borderRatio: CGFloat) -> some Shape {
            //var shape = Circle().path(in: rect)
            var shape = squircle.path(in: rect)
            shape.addPath(squircle.inset(by: span * borderRatio).path(in: rect))
            return shape
        }

        let iconPath = paths.first
        let svgPath = iconPath.flatMap { try? SVGPath($0) }
        let isSymbolPath = svgPath == nil // iconPath.flatMap(FairSymbol.allNames.keys.contains)

        return ZStack(alignment: .center) {
            squircle
                .fill(fillStyle)
                .frame(width: span, height: span, alignment: .center)
                //.mask(maskPath().fill(style: FillStyle(eoFill: true)))

            ZStack {
                if let iconPath = iconPath {
                    if isSymbolPath == false, let svgPath = svgPath {
                        svgPath
                            .inset(by: span / 7)
                            .aspectRatio(contentMode: .fit)
                    } else {
                        Text(Image(systemName: iconPath))
                            .font(iconFont(size: span * 0.5))
                            .opacity(0.95)
                            //.opacity(monogram.isEmpty ? 1.0 : 0.5)
                    }
                } else {
                    VStack {
                        let baseFontSize = (span * 0.75) / .init(max(1, parts.count))
                        Text(monogram)
                            .font(iconFont(size: baseFontSize))
                        if let subtitle = subtitle {
                            Text(subtitle)
                                .font(Font.system(size: baseFontSize / 2, weight: .semibold, design: .rounded))
                        }
                    }
                }
            }
            .foregroundColor(textColor)
            .lineLimit(1)
            .multilineTextAlignment(.center)
            .shadow(color: Color.black.opacity(0.9), radius: span * 0.010, x: 0, y: (isSymbolPath == false ? -1.0 : 1.0) * span / 75.0) // for some reason, path shadows are rendered above instead of below (see https://stackoverflow.com/a/58470832)

            if borderRatio > 0.0 {
                squircle
                    .fill(c3)
                    .mask(borderMask(borderRatio: borderRatio).fill(style: FillStyle(eoFill: true)))
                    .shadow(color: Color.black.opacity(1.0), radius: span * 0.01, x: 0, y: 0) // double interior shadow for raised effect
            }

        }
    }
}

extension LinearGradient {
    init(_ colors: Color...) {
        self.init(gradient: Gradient(colors: colors), startPoint: .topLeading, endPoint: .bottomTrailing)
    }
}

private extension String {
    /// Returns a pseudo-random value from 0.0-1.0 based on the word's SHA hash
    var derivedComponent: CGFloat {
        let i: UInt8 = self.utf8Data.sha256().last ?? 0
        return CGFloat(i) / CGFloat(UInt8.max)
    }
}

private struct CharSeqSizeKey: PreferenceKey {
    static var defaultValue: [CGSize] { [] }
    static func reduce(value: inout [CGSize], nextValue: () -> [CGSize]) {
        value.append(contentsOf: nextValue())
    }
}

private struct PropagateSize<V: View>: View {
    var content: () -> V
    var body: some View {
        content()
            .background(GeometryReader { proxy in
                Color.clear.preference(key: CharSeqSizeKey.self, value: [proxy.size])
            })
    }
}

private struct IndexedChar: Hashable, Identifiable {
    let index: Int
    let character: Character

    var id: Self { self }

    var string: String { "\(character)" }
}

struct FairIconView_Previews: PreviewProvider {
    static var previews: some View {
        preview(count: 56, span: 50)
            .frame(width: 450, height: 500, alignment: .center)
            .previewLayout(.sizeThatFits)
    }

    static func preview(seed: UUID = UUID(), count: Int, span: CGFloat, borderRatio: CGFloat = 0.06) -> some View {
//        var rndgen = SeededRandomNumberGenerator(uuids: seed)

//        var symbolNames = FairSymbol.allCases
//            .filter({ !$0.rawValue.hasPrefix("N") })
//            .shuffled(using: &rndgen).map(\.symbolName)

        var symbolNames: [String] = [] // [FairSymbol.pc.rawValue]

        // the first icon should be a 1/2 circle
        symbolNames.insert("M 0 0 A 25 25 0 1 0 0 50Z", at: 0)

        let appNames = (1...count).map { _ in UUID().uuidString }
        let appSymbols: [(appName: String, symbolName: String)] = Array(zip(appNames, symbolNames))

        let grid = LazyHGrid(rows: [
            GridItem(.adaptive(minimum: span, maximum: span)),
            //GridItem(.adaptive(minimum: 100, maximum: 200)),
        ]) {
            ForEach(appSymbols, id: \.appName) { appName, path in
                FairIconView(appName, subtitle: "", paths: [path], borderRatio: borderRatio)
                    .symbolVariant(.none)
                    .frame(width: span, height: span)
            }
        }

        // try? grid.png(bounds: nil)?.write(to: URL(fileURLWithPath: ("~/Desktop/previews.png" as NSString).expandingTildeInPath))

        return grid
    }
}

#endif
