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
import FairCore

#if canImport(SwiftUI)

/// An item that contains a title, subtitle, and optional animation.
/// It is uniquely identified and codable, and meant to contain localizable information.
public struct Card : Codable, Identifiable {
    public typealias CardGraphic = XOr<FairSymbol>.Or<VectorAnimation>

    public var id: UUID
    /// The localized title of the card. Will be displayed in caps. Should be very short, and should not include punctuation.
    public var title: String
    public var subtitle: String?
    public var foregroundColor: BannerColor?
    public var backgroundColors: [BannerColor]?
    public var backgroundGradientOpacity: Double?
    public var body: String?
    public var graphic: CardGraphic?
    public var graphicHeight: CGFloat?

    public init(id: UUID = UUID(), title: String, subtitle: String? = nil, body: String? = nil, foregroundColor: Card.BannerColor? = nil, backgroundColors: [Card.BannerColor]? = nil, backgroundGradientOpacity: Double? = nil, graphic: CardGraphic? = nil, graphicHeight: CGFloat? = nil) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.body = body
        self.foregroundColor = foregroundColor
        self.backgroundColors = backgroundColors
        self.backgroundGradientOpacity = backgroundGradientOpacity
        self.graphic = graphic
        self.graphicHeight = graphicHeight
    }

    public struct BannerColor : Codable {
        public typealias HexString = String
        public let color: XOr<SystemColor>.Or<HexString>

        public init(_ color: SystemColor) {
            self.color = .init(color)
        }

        public var systemColor: SwiftUI.Color? {
            switch color {
            case .p(let color): return color.systemColor
            case .q(let hex): return HexColor(hexString: hex)?.sRGBColor()
            }
        }

        /// Enumeration definit system UI colors
        public enum SystemColor : String, Codable, CaseIterable {
            case red
            case orange
            case yellow
            case green
            case mint
            case teal
            case cyan
            case blue
            case indigo
            case purple
            case pink
            case brown
            case white
            case gray
            case black
            case clear
            case primary
            case secondary
            case accent

            public var systemColor: SwiftUI.Color {
                switch self {
                case .red: return .red
                case .orange: return .orange
                case .yellow: return .yellow
                case .green: return .green
                case .mint: return .mint
                case .teal: return .teal
                case .cyan: return .cyan
                case .blue: return .blue
                case .indigo: return .indigo
                case .purple: return .purple
                case .pink: return .pink
                case .brown: return .brown
                case .white: return .white
                case .gray: return .gray
                case .black: return .black
                case .clear: return .clear
                case .primary: return .primary
                case .secondary: return .secondary
                case .accent: return .accentColor
                }
            }
        }
    }
}

/// A view that renders a seties of ``Card``s in a grid.
public struct CardBoard : View {
    public let cards: [Card]
    @Environment(\.colorScheme) var colorScheme
    @State var selectedItem: Card.ID?

    public init(cards: [Card]) {
        self.cards = cards
    }

    public var body: some View {
        GeometryReader { proxy in
            ScrollViewReader { scroller in
                ScrollView {
                    //bodyStack(size: proxy.size)
                    bodyGrid(size: proxy.size)
                }
                .onChange(of: selectedItem) { item in
                    if let item = item {
                        withAnimation {
                            scroller.scrollTo(item, anchor: .center)
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder public func bodyGrid(size: CGSize) -> some View {
        let minWidth = selectedItem == nil ? max(300, size.width * 0.45) : (size.width * 0.75)

        LazyVGrid(columns: [.init(.adaptive(minimum: minWidth, maximum: size.width))], alignment: .center) {
            cardsView(size: size, span: minWidth)
        }
    }

    public func cardsView(size: CGSize, span: CGFloat) -> some View {
        // ForEach(cards.filter({ selectedItem == nil || selectedItem == $0.id }).enumerated().array(), id: \.element.id) { index, item in
        ForEach(cards.enumerated().array(), id: \.element.id) { index, item in
            // TODO: tapping on a card should switch to pages tabs and let the user navigate the cards by swiping left/right for detailed information

            Button {
                dbg((selectedItem == item.id ? "de-" : "") + "selecting card id", item.id)
                withAnimation {
                    selectedItem = selectedItem == item.id ? nil : item.id
                }
            } label: {
                CardBoardItemView(item: item, span: span)
                    //.shadow(radius: 1, x: 1, y: 1)
                    .padding()
                    .background(cardBackground(item).cornerRadius(24).shadow(radius: 1, x: 2, y: 2))
                    .frame(height: selectedItem == item.id ? 600 : 300)
                    .padding()
                    .edgesIgnoringSafeArea(.all)
                    .allowsHitTesting(true)
            }
            .buttonStyle(.zoomable)
        }
    }

    /// The arrangement of the gradient is relative to the background, which will probably be defined by the current color scheme.
    ///
    /// Since the default gradient treatment has lighter colors coming from the top
    /// - Parameter colors: the colors to make a gradient from
    func schemeRelativeGradient(_ colors: [SwiftUI.Color]) -> LinearGradient {
        switch colorScheme {
        case .dark: return LinearGradient(colors: colors, startPoint: .bottom, endPoint: .top)
        case .light: return LinearGradient(colors: colors, startPoint: .top, endPoint: .bottom)
        @unknown default: return LinearGradient(colors: colors, startPoint: .top, endPoint: .bottom)
        }
    }

    @ViewBuilder public func cardBackground(_ item: Card) -> some View {
        if let backgroundColors = item.backgroundColors, backgroundColors.count > 1 {
            LinearGradient(colors: backgroundColors.compactMap(\.systemColor), startPoint: .top, endPoint: .bottom)
        } else if let color = item.backgroundColors?.first?.systemColor {
            schemeRelativeGradient([color.opacity(item.backgroundGradientOpacity ?? 0.75), color])
        }
    }
}

public struct CardBoardItemView : View {
    public let item: Card
    public let span: CGFloat

    public init(item: Card, span: CGFloat) {
        self.item = item
        self.span = span
    }

    public var body: some View {
        cardView
    }

    public var cardView: some View {
        VStack {
            Text(atx: item.title)
                .font(.system(size: 30, weight: .bold, design: .rounded).lowercaseSmallCaps())
                .lineLimit(nil)
                .truncationMode(.middle)
                .multilineTextAlignment(.center)
                .shadow(radius: 1, x: 1, y: 1)
                .frame(alignment: .center)

            // subtitle
            if let subtitle = item.subtitle {
                Text(atx: subtitle)
                    .multilineTextAlignment(.center)
                    .font(.title2)
                    .frame(maxWidth: .infinity)
                    .frame(alignment: .leading)
            }

            Spacer(minLength: 0)

            Group {
                switch item.graphic {
                case .none:
                    EmptyView()
                case .p(let symbol):
                    Image(symbol).resizable().aspectRatio(contentMode: .fit)
                        .padding()
                case .q(let animation):
                    VectorAnimationView(animation: animation)
                }
            }
            .frame(maxWidth: span * 0.50, maxHeight: span * 0.50)
            .frame(minWidth: span * 0.25, minHeight: span * 0.25)
            .frame(height: item.graphicHeight)

            Spacer(minLength: 0)

            // body
            if let body = item.body {
                Text(atx: body)
                    .font(.body)
                    .multilineTextAlignment(.leading)
                    .lineLimit(nil)
            }
        }
        .foregroundColor(item.foregroundColor?.systemColor ?? .white)
        .textSelection(.enabled)
        .allowsTightening(true)
    }
}

public struct ZoomableButtonStyle: ButtonStyle {
    var zoomLevel = 0.95

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? zoomLevel : 1, anchor: .center)
    }
}

extension ButtonStyle where Self == ZoomableButtonStyle {
    public static var zoomable: ZoomableButtonStyle {
        ZoomableButtonStyle()
    }

    public static func zoomable(level: Double = 0.95) -> ZoomableButtonStyle {
        ZoomableButtonStyle(zoomLevel: level)
    }
}

#endif // canImport(SwiftUI)
