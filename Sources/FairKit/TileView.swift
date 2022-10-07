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
import FairApp

// WARNING: much of this code is only compiled when Lottie is present in an app,
// and so syntax errors will not show up in the normal Fair CI.

#if canImport(Lottie)
import Lottie
/// When Lottie is independently added to a package, a ``VectorAnimation`` will be
/// a lottie animation JSON format, which can be included inline in a ``Banner Item``.
/// On platforms that do not import Lottie, this will be an opaque blob of JSON expressed as a ``JSum``.
///
/// Lottie can be added to a project with the project dependency:
///
/// `.package(url: "https://github.com/airbnb/lottie-ios.git", from: "3.4.3")`
///
/// and a target dependency:
///
/// `.product(name: "Lottie", package: "lottie-ios")`
///
public typealias VectorAnimation = Lottie.Animation
#else
/// When Lottie is independently added to a package, a ``VectorAnimation`` will be
/// a lottie animation JSON format, which can be included inline in a ``Banner Item``.
/// On platforms that do not import Lottie, this will be an opaque blob of JSON expressed as a ``JSum``.
///
/// Lottie can be added to a project with the project dependency:
///
/// `.package(url: "https://github.com/airbnb/lottie-ios.git", from: "3.4.3")`
///
/// and a target dependency:
///
/// `.product(name: "Lottie", package: "lottie-ios")`
///
public typealias VectorAnimation = JSum

public extension VectorAnimation {
    /// Loads the ``VectorAnimation`` from the given resource path in the specified ``Bundle``.
    static func named(_ path: String, bundle: Bundle) -> Self? {
        try? bundle.url(forResource: path, withExtension: nil).flatMap({
            try JSum.parse(json: Data(contentsOf: $0))
        })
    }
}
#endif


/// An item that contains a title, subtitle, and optional animation.
/// It is uniquely identified and codable, and meant to contain localizable information.
public struct Tile : Codable, Identifiable {
    public var id: UUID
    public var title: String
    public var subtitle: String? = nil
    public var subtitleTrailing: Bool?
    public var foregroundColor: BannerColor? = nil
    public var backgroundColors: [BannerColor]? = nil
    public var backgroundGradientOpacity: Double? = nil
    public var animation: VectorAnimation? = nil
    public var body: String? = nil

    public init(id: UUID, title: String, subtitle: String? = nil, subtitleTrailing: Bool? = nil, foregroundColor: Tile.BannerColor? = nil, backgroundColors: [Tile.BannerColor]? = nil, backgroundGradientOpacity: Double? = nil, animation: VectorAnimation? = nil, body: String? = nil) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.subtitleTrailing = subtitleTrailing
        self.foregroundColor = foregroundColor
        self.backgroundColors = backgroundColors
        self.backgroundGradientOpacity = backgroundGradientOpacity
        self.animation = animation
        self.body = body
    }

    @ViewBuilder public var background: some View {
        if let backgroundColors = backgroundColors, backgroundColors.count > 1 {
            LinearGradient(colors: backgroundColors.compactMap(\.systemColor), startPoint: .top, endPoint: .bottom)
        } else if let color = backgroundColors?.first?.systemColor {
            LinearGradient(colors: [color, color.opacity(backgroundGradientOpacity ?? 0.75)], startPoint: .top, endPoint: .bottom)
        }
    }

    public func trailing(_ trailing: Bool) -> Self {
        var item = self
        item.subtitleTrailing = trailing
        return item
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
        public enum SystemColor : String, Codable {
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

/// A view that renders a ``Tile`` with the standard treatment.
public struct TileView : View {
    public let item: Tile

    public init(item: Tile) {
        self.item = item
    }

    public var body: some View {
        VStack {
            Text(atx: item.title)
                //.font(.title.lowercaseSmallCaps())
                .font(.system(size: 40, weight: .bold, design: .rounded).lowercaseSmallCaps())
                .multilineTextAlignment(.center)
                .lineLimit(nil)
                .padding()
                .foregroundColor(item.foregroundColor?.systemColor)
            HStack(alignment: .top) {
                if item.subtitleTrailing != true, let subtitle = item.subtitle {
                    sub(subtitle, leading: true)
                }
                // when Lottie is imported, we can render the Bodymovin JSON
                #if canImport(Lottie)
                if let animation = item.animation {
//                    GeometryReader { proxy in
                        VectorAnimationView(animation: animation)
                            .loopMode(.loop)
                            .contentMode(.scaleAspectFit)
//                            .frame(minHeight: proxy.size.width)
//                    }
                }
                #endif
                if item.subtitleTrailing == true, let subtitle = item.subtitle {
                    sub(subtitle, leading: false)
                }
            }
            if let body = item.body {
                Text(atx: body)
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .lineLimit(nil)
                    .foregroundColor(item.foregroundColor?.systemColor)
            }
        }
    }

    private func sub(_ string: String, leading: Bool) -> some View {
        Text(atx: string)
            .multilineTextAlignment(!leading ? .leading : .trailing)
            .font(.title)
            .foregroundColor(item.foregroundColor?.systemColor)
            .frame(maxWidth: .infinity)
            .frame(alignment: !leading ? .leading : .trailing)
    }
}

#if canImport(Lottie)

public struct VectorAnimationView: View {
    let animation: VectorAnimation
    fileprivate var _loopMode: Lottie.LottieLoopMode?
    fileprivate var _animationSpan: CGFloat?
    #if os(iOS)
    public typealias CMode = UXView.ContentMode
    #else
    public typealias CMode = LottieContentMode
    #endif

    fileprivate var _contentMode: CMode?

    public init(animation: Lottie.Animation) {
        self.animation = animation
    }

    public var body: some View {
        VectorAnimationViewRepresentable(source: self)
//        GeometryReader { proxy in
//            VectorAnimationViewRepresentable(source: self)
//                .frame(width: _animationSpan == nil ? nil : proxy.size.width * _animationSpan!)
//        }
    }

    /// Changes the loop mode.
    public func loopMode(_ mode: Lottie.LottieLoopMode?) -> Self {
        var view = self
        view._loopMode = mode
        return view
    }

    /// Changes the loop mode.
    public func contentMode(_ mode: CMode?) -> Self {
        var view = self
        view._contentMode = mode
        return view
    }

    /// Changes the loop mode.
    public func animationSpan(_ span: CGFloat?) -> Self {
        var view = self
        view._animationSpan = span
        return view
    }
}

/// The underlying Lottie representable.
private struct VectorAnimationViewRepresentable : UXViewRepresentable {
    let source: VectorAnimationView
    //typealias UXViewType = AnimationView
    typealias UXViewType = UXView

    func makeUXView(context: Context) -> UXViewType {
        let container = UXView()
        #if os(macOS)
        container.autoresizingMask = [.height, .width]
        #else
        container.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        #endif
        container.translatesAutoresizingMaskIntoConstraints = true
        let animationView = makeAnimationView(context: context)
        container.addSubview(animationView)
        return container
    }

    func makeAnimationView(context: Context) -> AnimationView {
        let animationView = AnimationView()

        #if os(macOS)
        animationView.autoresizingMask = [.height, .width]
        #else
        animationView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        #endif
        animationView.translatesAutoresizingMaskIntoConstraints = true

        animationView.animation = source.animation

        if let loopMode = source._loopMode {
            animationView.loopMode = loopMode
        }
        if let contentMode = source._contentMode {
            animationView.contentMode = contentMode
        }


        return animationView
    }

    func updateUXView(_ view: UXViewType, context: Context) {
        (view.subviews.first as? AnimationView)?.play() // TODO: add start/stop controls

    }

    static func dismantleUXView(_ view: UXViewType, coordinator: ()) {
        (view.subviews.first as? AnimationView)?.stop() // TODO: add start/stop controls
    }
}
#endif
