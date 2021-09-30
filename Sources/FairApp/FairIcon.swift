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

/// A view that generates the default icon for a FairApp.
/// The icon consists of the app name laid out on a circular path.
public struct FairIconView : View, Equatable {
    var word1: String
    var word2: String

    public init(_ name: String) {
        let parts = name.components(separatedBy: CharacterSet.letters.inverted)
        self.word1 = parts.first ?? "Invalid"
        self.word2 = parts.last ?? "Name"
    }

    /// Returns a pseudo-random value from 0-1 seeded on the word's SHA hash
    static func hue(for word: String) -> Double {
        let checksum: UInt8 = word.utf8Data.sha256().last ?? 0
        return Double(checksum) / Double(UInt8.max)
    }

    public var body: some View {
        GeometryReader { proxy in
            iconView(for: min(proxy.size.width, proxy.size.height))
        }
    }

    func iconFont(size: CGFloat) -> Font {
        return Font.system(size: size, weight: .heavy, design: Font.Design.rounded).smallCaps()
    }

    func iconView(for span: CGFloat) -> some View {
        let kernFactor: CGFloat = 1
        //let lineWidth: CGFloat = span/40

        let radius: CGFloat = span / 2
        func fontSize(for word: String) -> CGFloat {
            (CGFloat(span) / ((word.count < 8 ? 5.0 : CGFloat(word.count) * 0.6)))
        }

        let fontSize1 = fontSize(for: word1)
        let fontSize2 = fontSize(for: word2)

        // create a top-down gradient of the brighter color a
        let outerColorLight = Color(hue: (Self.hue(for: word1) + Self.hue(for: word2)) / 2.0, saturation: 0.99, brightness: 0.8)
        let outerColorDark = Color(hue: (Self.hue(for: word1) + Self.hue(for: word2)) / 2.0, saturation: 0.99, brightness: 0.8)

        let fillColor = LinearGradient(colors: [outerColorLight, outerColorDark], startPoint: .top, endPoint: .bottom)
        let textColor = Color.white

        let rect = CGRect(origin: .zero, size: CGSize(width: span, height: span))
        func maskPath() -> some Shape {
            var shape = Circle().path(in: rect)
            shape.addPath(Circle().inset(by: span*0.28).path(in: rect))
            return shape

        }

        return ZStack(alignment: .center) {
            Circle()
                .fill(fillColor)
                .frame(width: span, height: span, alignment: .center)
                .mask(maskPath().fill(style: FillStyle(eoFill: true)))

            CircularTextView(text: word1, radius: radius, reverse: true)
                .kerning((fontSize1/3) + (.init(word1.count) * kernFactor))
                .foregroundColor(textColor)
                .font(iconFont(size: fontSize1))

            CircularTextView(text: word2, radius: radius - (fontSize2 / 10))
                .kerning((fontSize2/3) + (.init(word2.count) * kernFactor))
                .rotationEffect(.degrees(180))
                .foregroundColor(textColor)
                .font(iconFont(size: fontSize2))
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

struct CircularTextView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(alignment: .center) {
            ForEach([
                "Encyclopedia Galactica",
//                "Application Fair",
//                "Fine Dining",
                "Yankee Swap",
//                "Angry Birds",
//                "Tidal Pool",
                "Running Bear",
                "The Happening",
                "Creative Sovereign",
//                "The App",
            ], id: \.self) { appName in
                FairIconView(appName)
                    .frame(height: CGFloat.random(in: 20...300))
            }
        }
        .previewLayout(.sizeThatFits)
    }
}
#endif
