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
import Foundation
#if canImport(SwiftUI)
import SwiftUI
import FairCore

/// A view that generates the default icon for a FairApp.
/// The icon consists of the app name laid out on a circular path.
public struct FairIconView : View, Equatable {
    var word1: String
    var word2: String
    let subtitle: String?
    let iconColor: Color?

    public init(_ name: String, subtitle: String?, iconColor: Color? = nil) {
        let parts = name.components(separatedBy: CharacterSet.letters.inverted)
        self.word1 = parts.first ?? "Invalid"
        self.word2 = parts.last ?? "Name"
        self.subtitle = subtitle
        self.iconColor = iconColor
    }

    public var body: some View {
        GeometryReader { proxy in
            iconView(for: min(proxy.size.width, proxy.size.height))
        }
    }

    /// Returns the default icon color for the given app name, separated into two parts
    public static func iconColor(name: String) -> Color {
        let parts = name.components(separatedBy: CharacterSet.letters.inverted)
        let word1 = parts.first ?? "Invalid"
        let word2 = parts.last ?? "Name"
        return renderColor(word1: word1, word2: word2)
    }
    
    /// The default icon color for the two parts
    /// - Parameters:
    ///   - word1: the first word
    ///   - word2: the second word
    ///   - saturation: the color saturation
    ///   - brightness: the color brightness
    ///   - base: a base color to use rather than the word's seeded random
    /// - Returns: the color to use for rendering
    static func renderColor(word1: String, word2: String, saturation: CGFloat = 0.99, brightness: CGFloat = 0.8, base: Color? = nil) -> Color {
        let wordHue = (word1.derivedComponent + word2.derivedComponent) / 2.0
        var hue = wordHue

        // if we have specified a base color, use the hue as the basis for our app
        if let base = base {
            UXColor(base).getHue(&hue, saturation: nil, brightness: nil, alpha: nil)
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
        let monogram = String([word1.first, word2.first].compacted()).uppercased()

        // create a top-down gradient of the brighter color
        func clr(s: CGFloat, b: CGFloat) -> Color {
            Self.renderColor(word1: word1, word2: word2, saturation: s, brightness: b, base: iconColor)
        }

        let c1 = clr(s: 0.5, b: 0.9)
        let c2 = clr(s: 0.9, b: 0.5)
        let c3 = clr(s: 0.7, b: 0.75)

        let gradient = Gradient(colors: [c1, c2])

        let fillStyle = LinearGradient(gradient: gradient, startPoint: .top, endPoint: .bottom)
        //let fillStyle = RadialGradient(gradient: gradient, center: .center, startRadius: 0, endRadius: span*0.6)

        let textColor = Color.white

        let rect = CGRect(origin: .zero, size: CGSize(width: span, height: span))

        let squircle = RoundedRectangle(cornerRadius: span / 4.3, style: .continuous)
        func maskPath() -> some Shape {
            //var shape = Circle().path(in: rect)
            var shape = Rectangle().path(in: rect)
            shape.addPath(Circle().inset(by: span * 0.24).path(in: rect))
            return shape
        }

        func borderMask() -> some Shape {
            //var shape = Circle().path(in: rect)
            var shape = squircle.path(in: rect)
            shape.addPath(squircle.inset(by: span * 0.04).path(in: rect))
            return shape
        }

        return ZStack(alignment: .center) {
            squircle
                .fill(fillStyle)
                .frame(width: span, height: span, alignment: .center)
                //.mask(maskPath().fill(style: FillStyle(eoFill: true)))

            squircle
                .fill(c3)
                //.mask(RoundedRectangle(cornerRadius: span / 4.3, style: .continuous).path(in: rect).fill(style: FillStyle(eoFill: true)))
                .mask(borderMask().fill(style: FillStyle(eoFill: true)))
                .shadow(color: Color.black.opacity(1.0), radius: span * 0.010, x: 0, y: 0) // double interior shadow for raised effect

            VStack {
                Text(monogram)
                    .font(iconFont(size: span * 0.5))
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(Font.system(size: span * 0.16, weight: .semibold, design: .rounded))
                }
            }
            .shadow(color: Color.black.opacity(0.9), radius: span * 0.010, x: 0, y: 1)
            .foregroundColor(textColor)
            .lineLimit(1)
            .multilineTextAlignment(.center)
        }
    }
}

extension LinearGradient {
    init(_ colors: Color...) {
        self.init(gradient: Gradient(colors: colors), startPoint: .topLeading, endPoint: .bottomTrailing)
    }
}

public struct CircularTextView: View {
    public var text: String
    public var radius: CGFloat
    public var reverse: Bool = false
    internal var textModifier: (Text) -> Text = { $0 }
    internal var spacing: CGFloat = 0
    @State private var sizes: [CGSize] = []

    private func textRadius(at index: Int) -> CGFloat {
        radius - size(at: index).height / 2
    }

    public var body: some View {

        return VStack {
            ZStack {
                ForEach(textAsCharacters()) { item in
                    PropagateSize {
                        self.charView(char: item)
                    }
                    .frame(width: self.size(at: item.index).width,
                           height: self.size(at: item.index).height)
                    .offset(x: 0,
                            y: -self.textRadius(at: item.index))
                    .rotationEffect(self.angle(at: item.index))
                }
            }
            .frame(width: radius * 2, height: radius * 2)
            .onPreferenceChange(CharSeqSizeKey.self) { sizes in
                self.sizes = sizes
            }
        }
        .accessibility(label: Text(text))
    }

    private func textAsCharacters() -> [IndexedChar] {
        String(reverse ? Array(text) : text.reversed()).enumerated().map(IndexedChar.init)
    }

    private func charView(char: IndexedChar) -> some View {
        textModifier(Text(char.string))
            .rotationEffect(.degrees(reverse ? 0 : 180), anchor: .center)
    }

    private func size(at index: Int) -> CGSize {
        index < sizes.count ? sizes[index] : CGSize(width: 1000000, height: 0)
    }

    private func angle(at index: Int) -> Angle {
        let arcSpace = Double(spacing / radius)
        let charWidths = sizes.map { $0.width }
        let prevWidth =
            index < charWidths.count ?
        charWidths.dropLast(charWidths.count - index).reduce(0, +) :
            0

        let prevArcWidth = Double(prevWidth / radius)
        let totalArcWidth = Double(charWidths.reduce(0, +) / radius)
        let prevArcSpaceWidth = arcSpace * Double(index)

        let arcSpaceOffset = -arcSpace * Double(charWidths.count - 1) / 2
        let charWidth = index < charWidths.count ? charWidths[index] : 0
        let charOffset = Double(charWidth / 2 / radius)

        let arcCenterOffset = -totalArcWidth / 2
        let charArcOffset = prevArcWidth + charOffset + arcCenterOffset + arcSpaceOffset + prevArcSpaceWidth

        return Angle(radians: charArcOffset)
    }
}

extension CircularTextView {
    public func kerning(_ kerning: CGFloat) -> CircularTextView {
        var copy = self
        copy.spacing = kerning
        return copy
    }

    public func italic() -> CircularTextView {
        var copy = self
        copy.textModifier = {
            self.textModifier($0)
                .italic()
        }
        return copy
    }

    public func bold() -> CircularTextView {
        fontWeight(.bold)
    }

    public func fontWeight(_ weight: Font.Weight?) -> CircularTextView {
        var copy = self
        copy.textModifier = {
            self.textModifier($0)
                .fontWeight(weight)
        }
        return copy
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
        let span: CGFloat = 80
        var rndgen = SeededRandomNumberGenerator(uuids: UUID(uuidString: "C3C3FF68-AF95-4BF4-BE53-EC88EE097552")!)

        return LazyHGrid(rows: [
            GridItem(.adaptive(minimum: span, maximum: span)),
            //GridItem(.adaptive(minimum: 100, maximum: 200)),
        ]) {
            ForEach(
                try! AppNameValidation.standard.suggestNames(count: 24, rnd: &rndgen),
                id: \.self) { appName in
                FairIconView(appName, subtitle: "App Fair")
                    .frame(width: span, height: span)
            }
        }
        .frame(width: 400, height: 600)
        .previewLayout(.sizeThatFits)
    }
}
#endif
