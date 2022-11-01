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
import Foundation

// WARNING: much of this code is only compiled when Lottie is present in an app,
// and so syntax errors will not show up in the normal Fair CI.

#if canImport(Lottie)
import Lottie
/// When Lottie is independently added to a package, a ``VectorAnimation`` will be
/// a lottie animation JSON format, which can be included inline in a ``Card``.
/// On platforms that do not import Lottie, this will be an opaque blob of JSON expressed as a ``JSum``.
///
/// Lottie can be added to a project with the project dependency:
///
/// `.package(url: "https://github.com/airbnb/lottie-ios.git", from: "3.5.0")`
///
/// and a target dependency:
///
/// `.product(name: "Lottie", package: "lottie-ios")`
///
public typealias VectorAnimation = LottieAnimation
#else
/// When Lottie is independently added to a package, a ``VectorAnimation`` will be
/// a lottie animation JSON format, which can be included inline in a ``Card``.
/// On platforms that do not import Lottie, this will be an opaque blob of JSON expressed as a ``JSum``.
///
/// Lottie can be added to a project with the project dependency:
///
/// `.package(url: "https://github.com/airbnb/lottie-ios.git", from: "3.5.0")`
///
/// and a target dependency:
///
/// `.product(name: "Lottie", package: "lottie-ios")`
///
public typealias VectorAnimation = JSum
#endif

public extension VectorAnimation {
    /// Loads the ``VectorAnimation`` from the given resource path in the specified ``Bundle``.
    static func load(_ path: String, bundle: Bundle) throws -> Self {
        guard let url = bundle.url(forResource: path, withExtension: nil) else {
            throw CocoaError(.fileReadInvalidFileName)
        }
        return try JSONDecoder().decode(Self.self, from: Data(contentsOf: url))
    }
}

#if canImport(SwiftUI)
public struct VectorAnimationView: View {
    let animation: VectorAnimation
    #if canImport(Lottie)
    fileprivate var _loopMode: Lottie.LottieLoopMode? = .loop
    #if os(iOS)
    public typealias CMode = UXView.ContentMode
    #else
    public typealias CMode = LottieContentMode
    #endif

    fileprivate var _contentMode: CMode? = .scaleAspectFit
    #endif

    public init(animation: VectorAnimation) {
        self.animation = animation
        #if canImport(Lottie)
        // Use the Core Animation rendering engine if possible,
        // otherwise fall back to using the Main Thread rendering engine.
        //  - Call this early in your app lifecycle, such as in the AppDelegate.
        LottieConfiguration.shared.renderingEngine = .automatic
        #endif
    }

#if canImport(Lottie)
    @ViewBuilder public var body: some View {
        VectorAnimationViewRepresentable(source: self)
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
#else
    /// When Lottie is not imported, this view is just a stub.
    public var body: some View {
        EmptyView()
    }
#endif
}

#if canImport(Lottie)
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

    func makeAnimationView(context: Context) -> LottieAnimationView {
        let animationView = LottieAnimationView()

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
        (view.subviews.first as? LottieAnimationView)?.play() // TODO: add start/stop controls

    }

    static func dismantleUXView(_ view: UXViewType, coordinator: ()) {
        (view.subviews.first as? LottieAnimationView)?.stop() // TODO: add start/stop controls
    }
}
#endif
#endif // canImport(SwiftUI)
