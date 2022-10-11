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

#if canImport(UIKit)
import UIKit
/// Cross-platorm alias for `String` and `NSUserInterfaceItemIdentifier`
public typealias UXID = String // UIUserInterfaceItemIdentifier
/// Cross-platorm alias for ``UIKit.UIResponder`` and ``AppKit.NSResponder``
public typealias UXResponder = UIResponder
/// Cross-platorm alias for ``UIKit.UIWindow`` and ``AppKit.NSWindow``
public typealias UXWindow = UIWindow
/// Cross-platorm alias for ``UIKit.UIView`` and ``AppKit.NSView``
public typealias UXView = UIView
/// Cross-platorm alias for ``UIKit.UIFont`` and ``AppKit.NSFont``
public typealias UXFont = UIFont
/// Cross-platorm alias for ``UIKit.UIColor`` and ``AppKit.NSColor``
public typealias UXColor = UIColor
/// Cross-platorm alias for ``UIKit.UIBezierPath`` and ``AppKit.NSBezierPath``
public typealias UXBezierPath = UIBezierPath
/// Cross-platorm alias for ``UIKit.UIImage`` and ``AppKit.NSImage``
public typealias UXImage = UIImage
/// Cross-platorm alias for ``UIKit.UIButton`` and ``AppKit.NSButton``
public typealias UXButton = UIButton
/// Cross-platorm alias for ``UIKit.UITextField`` and ``AppKit.NSTextField``
public typealias UXTextField = UITextField
/// Cross-platorm alias for ``UIKit.UITextView`` and ``AppKit.NSTextView``
public typealias UXTextView = UITextView
/// Cross-platorm alias for ``UIKit.UITextViewDelegate`` and ``AppKit.NSTextViewDelegate``
public typealias UXTextViewDelegate = UITextViewDelegate
/// Cross-platorm alias for ``UIKit.UIFontDescriptor`` and ``AppKit.NSFontDescriptor``
public typealias UXFontDescriptor = UIFontDescriptor
/// Cross-platorm alias for ``UIKit.UIViewController`` and ``AppKit.NSViewController``
public typealias UXViewController = UIViewController
/// Cross-platorm alias for ``UIKit.UIScrollView`` and ``AppKit.NSScrollView``
public typealias UXScrollView = UIScrollView
/// Cross-platorm alias for ``UIKit.UIVisualEffectView`` and ``AppKit.NSVisualEffectView``
public typealias UXVisualEffectView = UIVisualEffectView
/// Cross-platorm alias for ``UIKit.UIDocument`` and ``AppKit.NSDocument``
public typealias UXDocument = UIDocument
/// Cross-platorm alias for ``UIKit.UIApplication`` and ``AppKit.NSApplication``
public typealias UXApplication = UIApplication
/// Cross-platorm alias for ``UIKit.UIEvent`` and ``AppKit.NSEvent``
public typealias UXEvent = UIEvent
/// Cross-platorm alias for ``UIKit.UIViewRepresentableContext`` and ``AppKit.NSViewRepresentableContext``
public typealias UXViewRepresentableContext = UIViewRepresentableContext
/// Cross-platorm alias for ``UIKit.UIHostingController`` and ``AppKit.NSHostingController``
public typealias UXHostingController = UIHostingController
/// Cross-platorm alias for ``UIKit.UIHostingView`` and ``AppKit.NSHostingView``
//public typealias UXHostingView = UIHostingView // does not exist in UIKit
/// Cross-platorm alias for ``UIKit.UIPasteboard`` and ``AppKit.NSPasteboard``
public typealias UXPasteboard = UIPasteboard

public extension UIPasteboard {
    typealias PasteboardType = String
}

public extension UIEvent {
    typealias ModifierFlags = UIKeyModifierFlags
}

#elseif canImport(AppKit)
import AppKit
/// Cross-platorm alias for ``NSUserInterfaceItemIdentifier``
public typealias NID = NSUserInterfaceItemIdentifier
/// Cross-platorm alias for `NSID` and `UIID`
public typealias UXID = NID
/// Cross-platorm alias for ``AppKit.NSResponder`` and ``UIKit.UIResponder``
public typealias UXResponder = NSResponder
/// Cross-platorm alias for ``AppKit.NSWindow`` and ``UIKit.UIWindow``
public typealias UXWindow = NSWindow
/// Cross-platorm alias for ``AppKit.NSView`` and ``UIKit.UIView``
public typealias UXView = NSView
/// Cross-platorm alias for ``AppKit.NSFont`` and ``UIKit.UIFont``
public typealias UXFont = NSFont
/// Cross-platorm alias for ``AppKit.NSColor`` and ``UIKit.UIColor``
public typealias UXColor = NSColor
/// Cross-platorm alias for ``AppKit.NSBezierPath`` and ``UIKit.UIBezierPath``
public typealias UXBezierPath = NSBezierPath
/// Cross-platorm alias for ``AppKit.NSImage`` and ``UIKit.UIImage``
public typealias UXImage = NSImage
/// Cross-platorm alias for ``AppKit.NSButton`` and ``UIKit.UIButton``
public typealias UXButton = NSButton
/// Cross-platorm alias for ``AppKit.NSTextField`` and ``UIKit.UITextField``
public typealias UXTextField = NSTextField
/// Cross-platorm alias for ``AppKit.NSTextView`` and ``UIKit.UITextView``
public typealias UXTextView = NSTextView
/// Cross-platorm alias for ``AppKit.NSTextViewDelegate`` and ``UIKit.UITextViewDelegate``
public typealias UXTextViewDelegate = NSTextViewDelegate
/// Cross-platorm alias for ``AppKit.NSFontDescriptor`` and ``UIKit.UIFontDescriptor``
public typealias UXFontDescriptor = NSFontDescriptor
/// Cross-platorm alias for ``AppKit.NSViewController`` and ``UIKit.UIViewController``
public typealias UXViewController = NSViewController
/// Cross-platorm alias for ``AppKit.NSScrollView`` and ``UIKit.UIScrollView``
public typealias UXScrollView = NSScrollView
/// Cross-platorm alias for ``AppKit.NSVisualEffectView`` and ``UIKit.UIVisualEffectView``
public typealias UXVisualEffectView = NSVisualEffectView
/// Cross-platorm alias for ``AppKit.NSDocument`` and ``UIKit.UIDocument``
public typealias UXDocument = NSDocument
/// Cross-platorm alias for ``AppKit.NSApplication`` and ``UIKit.UIApplication``
public typealias UXApplication = NSApplication
/// Cross-platorm alias for ``AppKit.NSEvent`` and ``UIKit.UIEvent``
public typealias UXEvent = NSEvent
/// Cross-platorm alias for ``AppKit.UIViewRepresentableContext`` and ``UIKit.NSViewRepresentableContext``
public typealias UXViewRepresentableContext = NSViewRepresentableContext
/// Cross-platorm alias for ``AppKit.UIHostingController`` and ``UIKit.NSHostingController``
public typealias UXHostingController = NSHostingController
/// Cross-platorm alias for ``AppKit.UIHostingView`` and ``UIKit.NSHostingView``
//public typealias UXHostingView = NSHostingView // does not exist in UIKit
/// Cross-platorm alias for ``AppKit.NSPasteboard`` and ``UIKit.UIPasteboard``
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

public extension UXPasteboard {
#if os(macOS)
    /// Returns a Boolean value indicating whether or not the urls property contains a nonempty array.
    var hasURLs: Bool {
        urls?.isEmpty == false
    }

    /// An array of URLs objects in all pasteboard items.
    var urls: [URL]? {
        //readObjects(forClasses: [NSURL.self]) as? [URL]
        (readObjects(forClasses: [NSString.self]) as? [String])?.compactMap({ str in
            str.count <= 4 && str.count > 1024 ? nil : URL(string: str)
        })
    }
#endif
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

extension UXView : TreeRoot {
    /// An iterator that recursively traverse the tree of view controller children in a depth-first manner
    @inlinable public var subviewsDepthFirst: TreeNodeIterator<UXView> {
        self[depthFirst: \.subviews]
    }

    /// An iterator that recursively traverse the tree of view controller children in a breadth-first manner
    @inlinable public var subviewsBreadthFirst: TreeNodeIterator<UXView> {
        self[breadthFirst: \.subviews]
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

    /// Derives a native view from this SwiftUI view
    public func viewWrapper() -> UXView {
        UXHostingController(rootView: self).view
    }
}


extension View {
    /// The first time this window is shows, set the size to the given amount.
    ///
    /// This works around the inability to set the initial window size in SwiftUI.
    ///
    /// Usage:
    ///
    /// ```
    /// WindowGroup {
    ///    RootView().initialViewSize(.init(width: 1200, height: 700))
    /// }
    /// ```
    public func initialViewSize(_ size: CGSize?) -> ModifiedContent<Self, InitialSizeViewModifier> {
        modifier(InitialSizeViewModifier(size: size))
    }
}

/// A modifier that sets an intial view size for a window's content view the first time it appears,
/// and then afterwars allows the view to be resized.
///
/// This works around the inability to set an intiail window size in SwiftUI.
public struct InitialSizeViewModifier: ViewModifier {
    public let size: CGSize?

    /// The storage for the last initial size that the view was opened as
    @AppStorage("initialViewSizeLaunch") private var initialViewSizeLaunch: String = ""

    @ViewBuilder public func body(content: Content) -> some View {
        if let size = size {
            let needsUpdate = initialViewSizeLaunch.description != size.debugDescription
            content
                .frame(width: needsUpdate ? size.width : nil, height: needsUpdate ? size.height : nil)
                .onAppear {
                    if needsUpdate {
                        initialViewSizeLaunch = size.debugDescription
                    }
                }
        } else {
            content
        }
    }
}



extension View {
    /// Performs the given asynchronous action after the specified delay with the option to cancel
    ///
    /// Example usage:
    ///
    /// ```
    /// TextField(text: $searchText)
    ///    .onChange(of: searchText, debounce: 0.20, action: updateSearchResults) // a brief delay to allow for more responsive typing
    /// ```
    public func onChange<T: Equatable>(of value: T, debounce interval: TimeInterval, priority: TaskPriority, perform action: @escaping (T) async -> ()) -> some View {
        task(id: value, priority: priority) {
            do {
                // buffer search typing by a short interval so we can type
                // without the UI slowing down with live search results
                try await Task.sleep(interval: interval)
                await action(value)
            } catch _ as CancellationError {
                // no need to log
                //dbg("cancelling debounce delay \(interval)")
            } catch {
                dbg("unexpected error waiting for delay \(interval): \(error)")
            }
        }
    }
}

extension View {
    /// Refreshes this view at the start of each minute. Useful for a label that displays
    /// relative date text like: "Updated N minutes ago…"
    public func refreshingEveryMinute() -> some View {
        TimelineView(.everyMinute) { context in
            RefreshingView(date: context.date) { _ in
                self
            }
        }
    }
}

private struct RefreshingView<V : View> : View {
    let date: Date
    let content: (Date) -> (V)

    @ViewBuilder var body: some View {
        content(date)
    }
}

extension String {
    /// Returns this text verbatim as a ``SwiftUI.Text``
    public func text() -> Text {
        Text(verbatim: self)
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
                navigationTitle(Text("\(title): \(subtitle)", bundle: .module, comment: "formatting string separating navigation title from subtitle"))
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

extension View {
    /// Causes the view to change its `SymbolVariants` when it is hovered.
    /// The animation only works with `symbolRenderingMode(.hierarchical)`.
    public func hoverSymbol(activeVariant: SymbolVariants = SymbolVariants.fill, inactiveVariant: SymbolVariants = SymbolVariants.none, animation: Animation? = .default) -> ModifiedContent<Self, HoverSymbolModifier> {
        modifier(HoverSymbolModifier(activeVariant: activeVariant, inactiveVariant: inactiveVariant, animation: animation))
    }
}

/// A modifier that changes the `symbolVariant` based on whether it is hovered over.
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

extension View {
    /// Provides an overlay with the given number (or other ``VectorArithmetic`` type).
    public func animatingVectorOverlay<N: VectorArithmetic, V: View>(for vector: N, alignment: Alignment = .center, @ViewBuilder content: @escaping (N) -> V) -> some View {
        modifier(AnimatableVectorArithmeticModifier(animatableData: vector, alignment: alignment, content: content))
    }

    /// Provides an overlay with the given number (or other ``VectorArithmetic`` type).
    public func animatingVectorBackground<N: VectorArithmetic, V: View>(for vector: N, alignment: Alignment = .center, @ViewBuilder content: @escaping (N) -> V) -> some View {
        modifier(AnimatableVectorArithmeticModifier(animatableData: vector, alignment: alignment, content: content))
    }
}

/// A modfier that applies the given content as an overlay
struct AnimatableVectorArithmeticModifier<N: VectorArithmetic, V: View>: AnimatableModifier {
    var animatableData: N
    var alignment: Alignment
    let content: (N) -> V


    func body(content: Content) -> some View {
        content.overlay(alignment: alignment) {
            self.content(animatableData)
        }
    }
}


public struct EmbeddedBrowser : View {
    let url: URL
    @State var presented = true
    @Environment(\.dismiss) var dismiss

    public init(url: URL, presented: Bool = true) {
        self.url = url
        self.presented = presented
    }

    public var body: some View {
        Link(destination: url) {
            VStack {
                //Text("Open:", bundle: .module, comment: "show url preview")
                Text(verbatim: url.absoluteString)
                    .font(Font.headline.monospaced().bold())
            }
                .multilineTextAlignment(.center)
        }
#if canImport(SafariServices)
        #if os(iOS)
        .fullScreenCover(isPresented: $presented, content: {
            EmbeddedBrowserController(url: url) {
                dismiss()
            }
        })
        #endif // os(iOS)
#endif
    }
}

#if canImport(SafariServices)
import SafariServices

#if os(iOS)
struct EmbeddedBrowserController: UXViewControllerRepresentable {
    let url: URL
    let config: SFSafariViewController.Configuration = .init()
    let onDismiss: () -> ()

    func makeUXViewController(context: UIViewControllerRepresentableContext<Self>) -> SFSafariViewController {
        let controller = SFSafariViewController(url: url, configuration: config)
        controller.delegate = context.coordinator
        return controller
    }

    func updateUXViewController(_ uiViewController: SFSafariViewController, context: UIViewControllerRepresentableContext<Self>) {
    }

    static func dismantleUXViewController(_ controller: SFSafariViewController, coordinator: Coordinator) {
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(onDismiss: onDismiss)
    }

    class Coordinator : NSObject, SFSafariViewControllerDelegate {
        let onDismiss: () -> ()

        init(onDismiss: @escaping () -> ()) {
            self.onDismiss = onDismiss
        }

        func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
            dbg("closed controller")
            onDismiss()
        }

    }
}
#endif
#endif

#endif // canImport(SwiftUI)

