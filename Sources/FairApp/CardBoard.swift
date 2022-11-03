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

/// A view that renders a collection of ``Card``s in a grid.
public struct CardBoard<Flair, FlairContent: View> : View {
    public let cards: [Card<Flair>]
    let flairContent: (Flair, Bool) -> FlairContent
    @Environment(\.colorScheme) var colorScheme
    @Binding var selectedItem: Card.ID?

    public init(selection: Binding<Card.ID?>, cards: [Card<Flair>], @ViewBuilder flairContent: @escaping (Flair, Bool) -> FlairContent) {
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
                // whenever the selection changes (either through a user's tap or through autocycling), scroll to make the top of the card visible
                if let item = item {
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

        let text = [card.title, card.subtitle, card.body].compacted().joined(separator: "\n")
        let wordCount = text.wordCount
        let interval = (TimeInterval(wordCount) + 5.0) / 2
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
                try await Task.sleep(interval: interval ?? cardCycleDuration ?? 10)
            } catch {
                // an expected cancellation error, which will occur when the user switches away from the view
                //dbg("cancelled autocycle:", error)
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
                let outline = RoundedRectangle(cornerRadius: 24, style: .continuous)
                let background = outline
                    //.strokeBorder(Color.accentColor, lineWidth: selected ? 3.0 : 0.0)
                    .strokeBorder(cardBackground(item, inverted: true), lineWidth: selected ? 3 : 0)
                    .shadow(radius: 1, x: 1, y: 1)
                    .background(outline.fill(cardBackground(item)).animation(.none, value: 0))
                    //.animation(.linear(duration: 0.01), value: selectedItem)
                CardBoardItemView(item: item, flairContent: { flair in flairContent(flair, selected) })
                    //.shadow(radius: 1, x: 1, y: 1)
                    .padding()
                    .background(background)
                    .frame(maxHeight: selected ? nil : 350)
                    .padding()
                    .edgesIgnoringSafeArea(.all)
                    .allowsHitTesting(true)
            }
            .buttonStyle(.zoomable)
        }
    }

    public func cardBackground(_ item: Card<Flair>, inverted: Bool = false) -> LinearGradient {
        //cardBackgroundRadial(item)
        cardBackgroundLinear(item, order: colorScheme == (inverted ? .light : .dark) ? [.top, .bottom] : [.bottom, .top])
    }

    public func cardBackgroundLinear(_ item: Card<Flair>, order points: [UnitPoint]) -> LinearGradient {
        LinearGradient(gradient: gradientColors(item), startPoint: points.first ?? .top, endPoint: points.last ?? .bottom)
    }

    public func cardBackgroundRadial(_ item: Card<Flair>) -> RadialGradient {
        return RadialGradient(gradient: gradientColors(item), center: .center, startRadius: 10, endRadius: 200)
    }

    public func gradientColors(_ item: Card<Flair>) -> Gradient {
        if let background = item.background, background.count > 1 {
            return Gradient(colors: background.compactMap(\.systemColor))
        } else if let color = item.background?.first?.systemColor {
            return Gradient(colors: [color, color.opacity(item.backgroundGradientOpacity ?? 0.75)])
        } else {
            return Gradient(colors: [Color.clear])
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
                .font(.system(size: 30, weight: .semibold, design: .default))
                .lineLimit(nil)
                .truncationMode(.middle)
                .multilineTextAlignment(.center)
                //.shadow(radius: 1, x: 1, y: 1)
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

extension CardBoard where Flair == String, FlairContent == SymbolFlairContent {
    /// Creates standard flair content for cards whose `Flair` is a `String`.
    /// - Parameters:
    ///   - selection: the card selection
    ///   - cards: the array of cards to display
    public init(selection: Binding<Card.ID?>, selectedMode: SymbolRenderingMode? = nil, unselectedMode: SymbolRenderingMode? = nil, selectedVariants: SymbolVariants? = nil, unselectedVariants: SymbolVariants? = nil, cards: [Card<Flair>]) {
        self.init(selection: selection, cards: cards) { flair, selected in
            SymbolFlairContent(symbolName: flair, symbolRenderingMode: selected ? selectedMode : unselectedMode, symbolVariants: selected ? selectedVariants : unselectedVariants)
        }
    }
}

/// Fair content that renders a symbol
public struct SymbolFlairContent : View {
    let symbolName: String
    let symbolRenderingMode: SymbolRenderingMode?
    let symbolVariants: SymbolVariants?

    public var body: some View {
        // the center image for the card; this can be any SwiftUI view, such as a Lottie VectorAnimation
        Text(Image(systemName: symbolName))
            .symbolRenderingMode(symbolRenderingMode)
            .symbolVariant(symbolVariants ?? .none)
            .font(.system(size: 80, weight: .semibold, design: .rounded))
            .shadow(radius: 2)
    }
}

#endif // canImport(SwiftUI)
