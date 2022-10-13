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

/// An item that contains a title, subtitle, and optional flair, which can be an image or animation.
///
/// The "flair" is context-specific, and may be a system symbol name, or could be a `VectorAnimation` for projects that import Lottie.
public struct Card<Flair> : Identifiable {
    public var id: UUID
    /// The localized title of the card. Will be displayed in caps. Should be very short, and should not include punctuation.
    public var title: String
    public var subtitle: String?
    public var foreground: CodableColor?
    public var background: [CodableColor]?
    public var backgroundGradientOpacity: Double?
    public var body: String?
    public var flair: Flair?
    public var flairHeight: CGFloat?

    public init(id: UUID = UUID(), title: String, subtitle: String? = nil, body: String? = nil, foreground: CodableColor? = nil, background: [CodableColor]? = nil, backgroundGradientOpacity: Double? = nil, flair: Flair? = nil, flairHeight: CGFloat? = nil) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.body = body
        self.foreground = foreground
        self.background = background
        self.backgroundGradientOpacity = backgroundGradientOpacity
        self.flair = flair
        self.flairHeight = flairHeight
    }
}

extension Card : Encodable where Flair : Encodable { }
extension Card : Decodable where Flair : Decodable { }
extension Card : Equatable where Flair : Equatable { }
extension Card : Hashable where Flair : Hashable { }
extension Card : Sendable where Flair : Sendable { }

/// An encodable color, which can use either a system color name (e.g. `accent` or `pink`) or a hex string.
public struct CodableColor : Codable, Hashable, Sendable {
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
    public enum SystemColor : String, Codable, CaseIterable, Sendable {
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

/// A view that renders a seties of ``Card``s in a grid.
public struct CardBoard<Flair, FlairContent: View> : View {
    public let cards: [Card<Flair>]
    let flairContent: (Flair) -> FlairContent
    @Environment(\.colorScheme) var colorScheme
    @Namespace var namespace
    @Binding var selectedItem: Card.ID?
    #if os(iOS)
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    var isNarrow: Bool { horizontalSizeClass == .compact }
    #else
    var isNarrow: Bool { false }
    #endif

    public init(selection: Binding<Card.ID?>, cards: [Card<Flair>], @ViewBuilder flairContent: @escaping (Flair) -> FlairContent) {
        self._selectedItem = selection
        self.cards = cards
        self.flairContent = flairContent
    }

    public var body: some View {
        ScrollViewReader { scroller in
            ScrollView {
                //bodyStack(size: proxy.size)
                bodyGrid()
            }
            .onChange(of: selectedItem) { item in
                // if there is no selected item, scroll to the top
                if let item = item ?? cards.first?.id {
                    withAnimation {
                        scroller.scrollTo(item, anchor: .top)
                    }
                }
            }
        }
    }

    /// The duration the selected card will be shown, which is simply the number of words in the card.
    var cardCycleDuration: Double? {
        guard let card = self.cards.first(where: { card in
            card.id == self.selectedItem
        }) else {
            return nil // the default time
        }

        guard let body = card.body else {
            return nil
        }

        let text = card.title + "\n" + (card.subtitle ?? "") + "\n" + body
        let wordCount = text.wordCount
        let interval = (TimeInterval(wordCount) + 5.0) / 2.5
        dbg("showing card “\(card.title)” for \(interval) seconds")
        return interval
    }

    /// Start cycling through all the possible cards with the given interval and delay.
    /// - Parameters:
    ///   - interval: the delay between cycled cards
    /// - Returns: the view with the task attached
    public func autocycle(interval: TimeInterval? = nil) -> some View {
        task(id: self.selectedItem, priority: .background) {
            do {
                // wait an initial delay before auto-cycling
                try await Task.sleep(interval: interval ?? cardCycleDuration ?? 15)
            } catch {
                // an expected cancellation error, which will occur when the user switches away from the view
                dbg("cancelled autocycle:", error)
                return
            }

            let ids = self.cards.map(\.id)
            withAnimation {
                // select the next card if there is currently a selection
                if let currentIndex = self.selectedItem.flatMap(ids.firstIndex(of:)) {
                    self.selectedItem = currentIndex >= ids.count - 1 ? nil : ids[currentIndex + 1]
                } else { // otherwise select the initial card
                    self.selectedItem = ids[0]
                }
            }
        }
    }

    @ViewBuilder public func bodyGrid() -> some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 350, maximum: 500), alignment: .top)]) {
            cardsView()
        }
    }

    public func cardsView() -> some View {
        // ForEach(cards.filter({ selectedItem == nil || selectedItem == $0.id }).enumerated().array(), id: \.element.id) { index, item in
        ForEach(cards.enumerated().array(), id: \.element.id) { index, item in
            // TODO: tapping on a card should switch to pages tabs and let the user navigate the cards by swiping left/right for detailed information
            Button {
                dbg((selectedItem == item.id ? "de-" : "") + "selecting card id", item.id)
                withAnimation {
                    selectedItem = selectedItem == item.id ? nil : item.id
                }
            } label: {
                let selected = selectedItem == item.id
                let background = RoundedRectangle(cornerRadius: 24, style: .continuous)

                CardBoardItemView(item: item, flairContent: flairContent)
                    //.shadow(radius: 1, x: 1, y: 1)
                    .padding()
                    .background(background.strokeBorder(Color.primary, lineWidth: selected ? 2.0 : 0.0).shadow(radius: 1, x: 2, y: 2).background(background.fill(cardBackground(item)).animation(.none, value: 0)))
                    .frame(maxHeight: selected ? nil : 350)
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

    public func cardBackground(_ item: Card<Flair>) -> LinearGradient {
        if let background = item.background, background.count > 1 {
            return LinearGradient(colors: background.compactMap(\.systemColor), startPoint: .top, endPoint: .bottom)
        } else if let color = item.background?.first?.systemColor {
            return schemeRelativeGradient([color.opacity(item.backgroundGradientOpacity ?? 0.75), color])
        } else {
            return LinearGradient(Color.clear)
        }
    }
}

struct CardBoardItemView<Flair, V : View> : View {
    let item: Card<Flair>
    let flairContent: (Flair) -> V

    public var body: some View {
        cardView
    }

    public var cardView: some View {
        VStack(spacing: 12) {
            Text(atx: item.title)
                .allowsTightening(true)
                .font(.system(size: 30, weight: .bold, design: .rounded).lowercaseSmallCaps())
                .lineLimit(nil)
                .truncationMode(.middle)
                .multilineTextAlignment(.center)
                .shadow(radius: 1, x: 1, y: 1)
                .frame(alignment: .center)

            // subtitle
            if let subtitle = item.subtitle {
                Text(atx: subtitle)
                    .allowsTightening(true)
                    .multilineTextAlignment(.center)
                    .font(.title2)
                    .frame(maxWidth: .infinity)
            }

            if let flair = item.flair {
                flairContent(flair)
                    .frame(height: item.flairHeight)
            }

            Spacer(minLength: 0)

            // body
            if let body = item.body {
                Text(atx: body)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .allowsTightening(true)
                    .font(.body)
                    .multilineTextAlignment(.leading)
                    .lineLimit(nil)
            }
        }
        .foregroundColor(item.foreground?.systemColor ?? .white)
    }
}

public struct ZoomableButtonStyle: ButtonStyle {
    var zoomLevel = 0.98

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? zoomLevel : 1, anchor: .center)
    }
}

extension ButtonStyle where Self == ZoomableButtonStyle {
    public static var zoomable: ZoomableButtonStyle {
        ZoomableButtonStyle()
    }

    public static func zoomable(level: Double = 0.98) -> ZoomableButtonStyle {
        ZoomableButtonStyle(zoomLevel: level)
    }
}


#if canImport(NaturalLanguage)
import NaturalLanguage

extension String {
    /// An estimate of the number words in the given string.
    public var wordCount: Int {
        let tokenizer = NLTokenizer(unit: .word)
        tokenizer.string = self
        var wordCount = 0
        tokenizer.enumerateTokens(in: startIndex..<endIndex) { tokenRange, _ in
            wordCount += 1
            return true
        }
        return wordCount
    }
}
#else
extension String {
    /// An estimate of the number words in the given string.
    ///
    /// When NaturalLanguage is not available, this merely splits on whitespace and newlines and returns the count, with is a decent approximation for many Western languages.
    public var wordCount: Int {
        components(separatedBy: .whitespacesAndNewlines).count
    }
}
#endif

#endif // canImport(SwiftUI)
