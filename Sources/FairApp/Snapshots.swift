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
import Swift

#if canImport(SwiftUI)
import SwiftUI

public extension View {
    /// Takes a snapshot of the view and returns the PNG data.
    /// - Parameters:
    ///   - viewBounds: the bounds to draw; if `nil`, attempts to use the view's `intrinsicContentSize`
    ///   - normalize: whether to normalize to 0,0 origin
    /// - Returns: the PNG data for the view
    func png(bounds viewBounds: CGRect?, normalize: Bool = true, drawHierarchy: Bool = false, scale: Double? = nil) -> Data? {
        snapshot(bounds: viewBounds, normalize: normalize, pdf: false, drawHierarchy: drawHierarchy, scale: scale)
    }

    /// Takes a snapshot of the view and returns the PDF data.
    /// - Parameters:
    ///   - viewBounds: the bounds to draw; if `nil`, attempts to use the view's `intrinsicContentSize`
    ///   - normalize: whether to normalize to 0,0 origin
    /// - Returns: the PDF data for the view
    func pdf(bounds viewBounds: CGRect?, normalize: Bool = true, drawHierarchy: Bool = false) -> Data? {
        snapshot(bounds: viewBounds, normalize: normalize, pdf: true, drawHierarchy: drawHierarchy, scale: nil)
    }

    /// Takes a snapshot of the view and returns the image data.
    /// - Parameters:
    ///   - viewBounds: the bounds to draw; if `nil`, attempts to use the view's `intrinsicContentSize`
    ///   - normalize: whether to normalize to 0,0 origin
    /// - Returns: the image data for the view
    private func snapshot(bounds viewBounds: CGRect?, normalize: Bool = true, pdf: Bool = false, drawHierarchy: Bool = false, scale: Double?) -> Data? {

        // size this view with the given bounds
        let v = self.frame(width: viewBounds?.width, height: viewBounds?.height)
            //.environment(\.displayScale, 2)

        let controller = UXHostingController(rootView: v)

        #if canImport(UIKit)
        let view = controller.view!
        #elseif canImport(AppKit)
        let view = controller.view
        #endif

        var bounds = viewBounds ?? CGRect(origin: .zero, size: view.intrinsicContentSize)
        if normalize {
            bounds = bounds.offsetBy(dx: -bounds.minX, dy: -bounds.minY) // normalize to 0,0
            bounds = bounds.offsetBy(dx: -bounds.width / 2, dy: -bounds.height / 2)
        }

        //bounds.size = .init(width: bounds.size.width / 2, height: bounds.size.height / 2)

#if canImport(UIKit)
        controller.view.backgroundColor = .clear
//        controller.view.frame = window.frame
//        controller.view.translatesAutoresizingMaskIntoConstraints =
//        viewController.view.translatesAutoresizingMaskIntoConstraints
        controller.preferredContentSize = bounds.size
//        viewController.view.frame = controller.view.frame
//        controller.view.addSubview(viewController.view)
//        if viewController.view.translatesAutoresizingMaskIntoConstraints {
//            viewController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]


        let window = UIWindow(frame: bounds)

        window.rootViewController = controller
        window.makeKeyAndVisible() // FIXME: seems to be the only way to avoid nil screenshots
        // window.contentScaleFactor = 2.0

        // view.backgroundColor = .clear
        view.bounds = bounds

        // PDF not working well
        if pdf {
            let format = UIGraphicsPDFRendererFormat()
            format.documentInfo = [ kCGPDFContextAuthor as String : "Fair" ]

            let pdfRenderer = UIGraphicsPDFRenderer(bounds: view.bounds, format: format)

            let data = pdfRenderer.pdfData(actions: { context in
                context.beginPage()
                view.layer.render(in: context.cgContext)
            })

            return data
        } else { // png

            //let traits = UITraitCollection() // (horizontalSizeClass: .regular)
            let format = UIGraphicsImageRendererFormat.default() // (for: traits)
            format.opaque = true
            //format.scale = 1.0
            if let scale = scale {
                format.scale = scale
            }

            let renderer = UIGraphicsImageRenderer(size: bounds.size, format: format)
            let data = renderer.pngData { ctx in
                if drawHierarchy {
                    view.drawHierarchy(in: bounds, afterScreenUpdates: true)
                } else {
                    view.layer.render(in: ctx.cgContext)
                }
            }

            return data
        }

#elseif canImport(AppKit)
        // TODO: handle PDF
        // TODO: handle scale parameter

        guard let rep: NSBitmapImageRep = view.bitmapImageRepForCachingDisplay(in: bounds) else {
            dbg("could not cache rep in", bounds)
            return nil
        }

        view.cacheDisplay(in: bounds, to: rep)
        let data = rep.representation(using: .png, properties: [:])
        return data
#else
        return nil // needs cross-platform SwiftUI
#endif
    }
}
#endif

