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
import Swift

#if canImport(UIKit)
import UIKit
/// Cross-platorm alias for `String` and `NSUserInterfaceItemIdentifier`
public typealias UXID = String // UIUserInterfaceItemIdentifier
/// Cross-platorm alias for `UIResponder` and `NSResponder`
public typealias UXResponder = UIResponder
/// Cross-platorm alias for `UIWindow` and `NSWindow`
public typealias UXWindow = UIWindow
/// Cross-platorm alias for `UIView` and `NSView`
public typealias UXView = UIView
/// Cross-platorm alias for `UIFont` and `NSFont`
public typealias UXFont = UIFont
/// Cross-platorm alias for `UIColor` and `NSColor`
public typealias UXColor = UIColor
/// Cross-platorm alias for `UIBezierPath` and `NSBezierPath`
public typealias UXBezierPath = UIBezierPath
/// Cross-platorm alias for `UIImage` and `NSImage`
public typealias UXImage = UIImage
/// Cross-platorm alias for `UIButton` and `NSButton`
public typealias UXButton = UIButton
/// Cross-platorm alias for `UITextField` and `NSTextField`
public typealias UXTextField = UITextField
/// Cross-platorm alias for `UITextView` and `NSTextView`
public typealias UXTextView = UITextView
/// Cross-platorm alias for `UITextViewDelegate` and `NSTextViewDelegate`
public typealias UXTextViewDelegate = UITextViewDelegate
/// Cross-platorm alias for `UIFontDescriptor` and `NSFontDescriptor`
public typealias UXFontDescriptor = UIFontDescriptor
/// Cross-platorm alias for `UIViewController` and `NSViewController`
public typealias UXViewController = UIViewController
/// Cross-platorm alias for `UIScrollView` and `NSScrollView`
public typealias UXScrollView = UIScrollView
/// Cross-platorm alias for `UIVisualEffectView` and `NSVisualEffectView`
public typealias UXVisualEffectView = UIVisualEffectView
/// Cross-platorm alias for `UIDocument` and `NSDocument`
public typealias UXDocument = UIDocument
/// Cross-platorm alias for `UIApplication` and `NSApplication`
public typealias UXApplication = UIApplication
/// Cross-platorm alias for `UIEvent` and `NSEvent`
public typealias UXEvent = UIEvent
/// Cross-platorm alias for `UIViewRepresentableContext` and `NSViewRepresentableContext`
public typealias UXViewRepresentableContext = UIViewRepresentableContext
/// Cross-platorm alias for `UIHostingController` and `NSHostingController`
public typealias UXHostingController = UIHostingController
/// Cross-platorm alias for `UIHostingView` and `NSHostingView`
//public typealias UXHostingView = UIHostingView // does not exist in UIKit
/// Cross-platorm alias for `UIPasteboard` and `NSPasteboard`
public typealias UXPasteboard = UIPasteboard

public extension UIPasteboard {
    typealias PasteboardType = String
}

public extension UIEvent {
    typealias ModifierFlags = UIKeyModifierFlags
}

#elseif canImport(AppKit)
import AppKit
/// Cross-platorm alias for `NID` and `NID`
public typealias NID = NSUserInterfaceItemIdentifier
/// Cross-platorm alias for `NSID` and `UIID`
public typealias UXID = NID
/// Cross-platorm alias for `NSResponder` and `UIResponder`
public typealias UXResponder = NSResponder
/// Cross-platorm alias for `NSWindow` and `UIWindow`
public typealias UXWindow = NSWindow
/// Cross-platorm alias for `NSView` and `UIView`
public typealias UXView = NSView
/// Cross-platorm alias for `NSFont` and `UIFont`
public typealias UXFont = NSFont
/// Cross-platorm alias for `NSColor` and `UIColor`
public typealias UXColor = NSColor
/// Cross-platorm alias for `NSBezierPath` and `UIBezierPath`
public typealias UXBezierPath = NSBezierPath
/// Cross-platorm alias for `NSImage` and `UIImage`
public typealias UXImage = NSImage
/// Cross-platorm alias for `NSButton` and `UIButton`
public typealias UXButton = NSButton
/// Cross-platorm alias for `NSTextField` and `UITextField`
public typealias UXTextField = NSTextField
/// Cross-platorm alias for `NSTextView` and `UITextView`
public typealias UXTextView = NSTextView
/// Cross-platorm alias for `NSTextViewDelegate` and `UITextViewDelegate`
public typealias UXTextViewDelegate = NSTextViewDelegate
/// Cross-platorm alias for `NSFontDescriptor` and `UIFontDescriptor`
public typealias UXFontDescriptor = NSFontDescriptor
/// Cross-platorm alias for `NSViewController` and `UIViewController`
public typealias UXViewController = NSViewController
/// Cross-platorm alias for `NSScrollView` and `UIScrollView`
public typealias UXScrollView = NSScrollView
/// Cross-platorm alias for `NSVisualEffectView` and `UIVisualEffectView`
public typealias UXVisualEffectView = NSVisualEffectView
/// Cross-platorm alias for `NSDocument` and `UIDocument`
public typealias UXDocument = NSDocument
/// Cross-platorm alias for `NSApplication` and `UIApplication`
public typealias UXApplication = NSApplication
/// Cross-platorm alias for `NSEvent` and `UIEvent`
public typealias UXEvent = NSEvent
/// Cross-platorm alias for `UIViewRepresentableContext` and `NSViewRepresentableContext`
public typealias UXViewRepresentableContext = NSViewRepresentableContext
/// Cross-platorm alias for `UIHostingController` and `NSHostingController`
public typealias UXHostingController = NSHostingController
/// Cross-platorm alias for `UIHostingView` and `NSHostingView`
//public typealias UXHostingView = NSHostingView // does not exist in UIKit
/// Cross-platorm alias for `NSPasteboard` and `UIPasteboard`
public typealias UXPasteboard = NSPasteboard
#endif


#if canImport(SwiftUI)
@_exported import SwiftUI

#if canImport(AppKit)
@_exported import AppKit
@available(macOS 11, *)
typealias UXApplicationDelegateAdaptor = NSApplicationDelegateAdaptor
typealias UXApplicationDelegate = NSApplicationDelegate
#elseif canImport(UIKit)
@_exported import UIKit
typealias UXApplicationDelegateAdaptor = UIApplicationDelegateAdaptor
typealias UXApplicationDelegate = UIApplicationDelegate
#endif


// MARK: ViewRepresentable

#if canImport(AppKit)
/// AppKit adapter for `NSViewRepresentable`
public protocol UXViewRepresentable : NSViewRepresentable {
    associatedtype UXViewType : NSView
    func makeUXView(context: Self.Context) -> Self.UXViewType
    func updateUXView(_ view: Self.UXViewType, context: Self.Context)
    static func dismantleUXView(_ view: Self.UXViewType, coordinator: Self.Coordinator)
}
#elseif canImport(UIKit)
/// UIKit adapter for `UIViewRepresentable`
public protocol UXViewRepresentable : UIViewRepresentable {
    associatedtype UXViewType : UIView
    func makeUXView(context: Self.Context) ->  Self.UXViewType
    func updateUXView(_ view:  Self.UXViewType, context: Self.Context)
    static func dismantleUXView(_ view:  Self.UXViewType, coordinator: Self.Coordinator)
}
#endif

public extension SwiftUI.Image {
    init(uxImage nativeImage: UXImage) {
    #if canImport(AppKit)
        self.init(nsImage: nativeImage)
    #elseif canImport(UIKit)
        self.init(uiImage: nativeImage)
    #endif
    }
}

public extension UXApplication {
    /// Sets the badge of the dock/icon for this app.
    ///
    /// - Parameter number: the number to set; 0 will hide the badge
    func setBadge(_ number: Int) {
        #if canImport(AppKit)
        NSApp.dockTile.badgeLabel = number <= 0 ? nil : "\(number)"
        #endif
        #if canImport(UIKit)
        UNUserNotificationCenter.current().requestAuthorization(options: [.badge]) { success, error in
            if success == true && error == nil {
                DispatchQueue.main.async {
                    self.applicationIconBadgeNumber = number
                }
            }
        }
        #endif
    }
}

public extension UXViewRepresentable {

    #if canImport(UIKit)
    // MARK: UIKit UIViewRepresentable support

    func makeUIView(context: Self.Context) -> Self.UXViewType {
        return makeUXView(context: context)
    }

    func updateUIView(_ uiView: Self.UXViewType, context: Self.Context) {
        updateUXView(uiView, context: context)
    }

    static func dismantleUIView(_ uiView: Self.UXViewType, coordinator: Self.Coordinator) {
        Self.dismantleUXView(uiView, coordinator: coordinator)
    }
    #endif

    #if canImport(AppKit)
    // MARK: AppKit NSViewRepresentable support

    func makeNSView(context: Self.Context) -> Self.UXViewType {
        return makeUXView(context: context)
    }

    func updateNSView(_ nsView: Self.UXViewType, context: Self.Context) {
        updateUXView(nsView, context: context)
    }

    static func dismantleNSView(_ nsView: Self.UXViewType, coordinator: Self.Coordinator) {
        Self.dismantleUXView(nsView, coordinator: coordinator)
    }
    #endif
}

// MARK: ViewControllerRepresentable

#if canImport(AppKit)
/// AppKit adapter for `NSViewControllerRepresentable`
public protocol UXViewControllerRepresentable : NSViewControllerRepresentable {
    associatedtype UXViewControllerType : NSViewController
    func makeUXViewController(context: Self.Context) -> Self.UXViewControllerType
    func updateUXViewController(_ controller: Self.UXViewControllerType, context: Self.Context)
    static func dismantleUXViewController(_ controller: Self.UXViewControllerType, coordinator: Self.Coordinator)
}
#elseif canImport(UIKit)
/// UIKit adapter for `UIViewControllerRepresentable`
public protocol UXViewControllerRepresentable : UIViewControllerRepresentable {
    associatedtype UXViewControllerType : UIViewController
    func makeUXViewController(context: Self.Context) ->  Self.UXViewControllerType
    func updateUXViewController(_ controller:  Self.UXViewControllerType, context: Self.Context)
    static func dismantleUXViewController(_ controller:  Self.UXViewControllerType, coordinator: Self.Coordinator)
}
#endif


public extension UXViewControllerRepresentable {

    #if canImport(UIKit)
    // MARK: UIKit UIViewControllerRepresentable support

    func makeUIViewController(context: Self.Context) -> Self.UXViewControllerType {
        return makeUXViewController(context: context)
    }

    func updateUIViewController(_ uiViewController: Self.UXViewControllerType, context: Self.Context) {
        updateUXViewController(uiViewController, context: context)
    }

    static func dismantleUIViewController(_ uiViewController: Self.UXViewControllerType, coordinator: Self.Coordinator) {
        Self.dismantleUXViewController(uiViewController, coordinator: coordinator)
    }
    #elseif canImport(AppKit)
    // MARK: AppKit NSViewControllerRepresentable support

    func makeNSViewController(context: Self.Context) -> Self.UXViewControllerType {
        return makeUXViewController(context: context)
    }

    func updateNSViewController(_ nsViewController: Self.UXViewControllerType, context: Self.Context) {
        updateUXViewController(nsViewController, context: context)
    }

    static func dismantleNSViewController(_ nsViewController: Self.UXViewControllerType, coordinator: Self.Coordinator) {
        Self.dismantleUXViewController(nsViewController, coordinator: coordinator)
    }
    #endif
}

public extension View {
    /// Takes a snapshot of the view and returns the PNG data.
    /// - Parameters:
    ///   - viewBounds: the bounds to draw; if `nil`, attempts to use the view's `intrinsicContentSize`
    ///   - normalize: whether to normalize to 0,0 origin
    /// - Returns: the PNG data for the view
    func png(bounds viewBounds: CGRect?, normalize: Bool = true) -> Data? {
        let controller = UXHostingController(rootView: self.frame(width: viewBounds?.width, height: viewBounds?.height))
        let view: UXView = controller.view
        var bounds = viewBounds ?? CGRect(origin: .zero, size: view.intrinsicContentSize)
        if normalize {
            bounds = bounds.offsetBy(dx: -bounds.minX, dy: -bounds.minY) // normalize to 0,0
            bounds = bounds.offsetBy(dx: -bounds.width / 2, dy: -bounds.height / 2)
        }

#if canImport(UIKit)
        view.backgroundColor = .clear
        let renderer = UIGraphicsImageRenderer(size: bounds.size)
        let data = renderer.pngData { _ in
            view.drawHierarchy(in: bounds, afterScreenUpdates: true)
        }
        return data
#elseif canImport(AppKit)
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

extension View {
    /// When called within an invocation of body of a view of this type,
    /// prints the names of the changed dynamic properties that caused the
    /// result of body to need to be refreshed.
    ///
    /// As well as the physical property names,
    /// `@self` is used to mark that the view value itself has changed, and
    /// `@identity` to mark that the identity of the view has changed
    /// (i.e. that the persistent data associated with the view has been
    /// recycled for a new instance of the same type).
    ///
    /// This is only called on iOS 15+ and when `DEBUG` is set
    @inlinable public func debuggingViewChanges() {
        #if DEBUG
        if #available(macOS 12.0, iOS 15.0, *) {
            Self._printChanges()
        }
        #endif
    }
}

extension View {
    /// Configure the navigation title and subtitle for the type of device
    public func navigation(title: Text, subtitle: Text?) -> some View {
        #if os(macOS)
        return Group {
            if let subtitle = subtitle {
                navigationTitle(title).navigationSubtitle(subtitle)
            } else {
                navigationTitle(title)
            }
        }
        #else
        return Group {
            if let subtitle = subtitle {
                navigationTitle(title + Text(": ") + subtitle)
            } else {
                navigationTitle(title)
            }
        }
        #endif
    }
}

extension NavigationLink {
    /// Specifies whether this is a detail link.
    ///
    /// This only has an effect on iOS with multi-column navigation.
    public func detailLink(_ detail: Bool) -> some View {
        #if os(iOS)
        isDetailLink(detail)
        #else
        self
        #endif
    }
}

extension View {
    public func windowToolbarUnified(compact: Bool, showsTitle: Bool) -> some View {
        #if os(macOS)
        Group {
            if compact {
                self.presentedWindowToolbarStyle(.unifiedCompact(showsTitle: showsTitle))
            } else {
                self.presentedWindowToolbarStyle(.unified(showsTitle: showsTitle))
            }
        }
        #else
        self
        #endif
    }
}

@available(macOS 12.0, iOS 15.0, *)
extension View {
    /// Causes the view to change its `SymbolVariants` when it is hovered.
    /// The animation only works with `symbolRenderingMode(.hierarchical)`.
    public func hoverSymbol(activeVariant: SymbolVariants = SymbolVariants.fill, inactiveVariant: SymbolVariants = SymbolVariants.none, animation: Animation? = .default) -> ModifiedContent<Self, HoverSymbolModifier> {
        modifier(HoverSymbolModifier(activeVariant: activeVariant, inactiveVariant: inactiveVariant, animation: animation))
    }
}

/// A modifier that changes the `symbolVariant` based on whether it is hovered over.
@available(macOS 12.0, iOS 15.0, *)
public struct HoverSymbolModifier: ViewModifier {
    @State private var hovered = false
    internal let activeVariant: SymbolVariants
    internal let inactiveVariant: SymbolVariants
    internal let animation: Animation?

    public func body(content: Content) -> some View {
        content
            .symbolVariant(hovered ? activeVariant : inactiveVariant)
            .onHover(perform: { hover in
                withAnimation(animation) {
                    hovered = hover
                }
            })
    }
}



#endif // canImport(SwiftUI)

