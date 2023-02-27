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
    func png(inWindow window: UXWindow? = nil, bounds viewBounds: CGRect?, normalize: Bool = true, drawHierarchy: Bool = false, scale: Double? = nil) -> Data? {
        snapshot(bounds: viewBounds, normalize: normalize, pdf: false, drawHierarchy: drawHierarchy, scale: scale)
    }

    /// Takes a snapshot of the view and returns the PDF data.
    /// - Parameters:
    ///   - viewBounds: the bounds to draw; if `nil`, attempts to use the view's `intrinsicContentSize`
    ///   - normalize: whether to normalize to 0,0 origin
    /// - Returns: the PDF data for the view
    func pdf(inWindow window: UXWindow? = nil, bounds viewBounds: CGRect?, normalize: Bool = true, drawHierarchy: Bool = false) -> Data? {
        snapshot(inWindow: window, bounds: viewBounds, normalize: normalize, pdf: true, drawHierarchy: drawHierarchy, scale: nil)
    }

    /// Takes a snapshot of the view and returns the image data.
    /// - Parameters:
    ///   - viewBounds: the bounds to draw; if `nil`, attempts to use the view's `intrinsicContentSize`
    ///   - normalize: whether to normalize to 0,0 origin
    /// - Returns: the image data for the view
    private func snapshot(inWindow: UXWindow? = nil, bounds viewBounds: CGRect?, normalize: Bool = true, pdf: Bool = false, drawHierarchy: Bool = false, scale: Double?) -> Data? {

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

        return controller.snapshot(inWindow: inWindow, bounds: bounds, normalize: normalize, pdf: pdf, drawHierarchy: drawHierarchy, scale: scale)
    }
}

extension UXViewController {
    /// Takes a snapshot of the controller's view and returns the image data.
    /// - Parameters:
    ///   - viewBounds: the bounds to draw; if `nil`, attempts to use the view's `intrinsicContentSize`
    ///   - normalize: whether to normalize to 0,0 origin
    /// - Returns: the image data for the view
    public func snapshot(inWindow: UXWindow? = nil, bounds: CGRect, normalize: Bool = true, pdf: Bool, drawHierarchy: Bool = false, scale: Double?) -> Data? {
        let controller = self

#if canImport(UIKit)
        let window = inWindow ?? {
            let win = UXWindow()
            win.makeKeyAndVisible() // seems to be the only way to avoid nil screenshots
            // win.contentScaleFactor = 2.0
            return win
        }()

        defer {
            if inWindow == nil {
                window.resignKey()
            }
        }

        window.bounds = bounds
        window.rootViewController = controller

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

extension SceneManager where AppFacets : FacetView & RawRepresentable, ConfigFacets : FacetView & RawRepresentable, AppFacets.RawValue == String, ConfigFacets.RawValue == String, AppFacets.FacetStore == Self {

    /// The locales that have keys defined in the `app.localizations` set of `App.yml`
    public func configuredLocales() throws -> [Locale]? {
        let config: JSON = try Self.configuration(name: "App")
        let app = config["app"]
        let locs = app?["localizations"]?.object
        return locs?.keys.map(Locale.init(identifier:))
    }

    @discardableResult public func captureFacetScreens(folder targetFolder: URL? = nil, appFacets: [AppFacets]? = nil, configFacets: [ConfigFacets]? = nil, locales targetLocales: [Locale]? = nil, devices targetDevices: [DevicePreview]? = nil) throws -> [ScreenshotResult] {
#if canImport(UIKit)
        let animationsWereEnabled = UIView.areAnimationsEnabled
        UIView.setAnimationsEnabled(false)
        defer { UIView.setAnimationsEnabled(animationsWereEnabled) }
#endif

        // let locales = targetLocales ?? [Locale(identifier: "en"), Locale(identifier: "fr")]
        // start with the development localization
//        let allLocalizations = ([bundle.developmentLocalization] + bundle.localizations.sorted()).compactMap({ $0 }).uniquing(by: \.self).array()
        //let allLocalizations = wip([bundle.developmentLocalization!])
//        let configuredLocalizations = allLocalizations
//            .map(Locale.init(identifier:)).filter {
//            !$0.languageTag.isEmpty
//        }

        let allLocalizations = try self.configuredLocales()

        let targetloc = targetLocales ?? allLocalizations
        //let devloc = bundle.developmentLocalization.flatMap(Locale.init(identifier:))
        let devloc = Locale(identifier: "en-US") // the base screenshots folder

        let locales = ([devloc] + (targetloc ?? [])).uniquing(by: \.identifier).array()
        
        dbg("creating screenshots for class:", Self.self, "bundle:", Self.bundle.bundleIdentifier, "in locales:", locales.map(\.identifier))

        let devices = targetDevices ?? [DevicePreview.iPhone8Plus, .iPhone14Plus, .iPadPro6]

        let folder = try targetFolder ?? FileManager.default
            .url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            .appendingPathComponent(Bundle.mainBundleID + "/screenshots", isDirectory: true)

        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        dbg("saving screens to:", folder.path)

        let shots = try self.captureScreenshots(folder: folder, vector: false, bundle: Self.bundle, devices: devices, locales: locales, appFacets: appFacets ?? Self.AppFacets.facets(for: self), configFacets: configFacets ?? Self.ConfigFacets.facets(for: self))

//        let expectedShotCount = devices.count * locales.count * 10
//
//        XCTAssertEqual(expectedShotCount, shots.count, "expected count to match device/locale matrix")
//        let hashes = shots.compactMap(\.imageSHA256).set()
//        XCTAssertLessThanOrEqual(expectedShotCount / 2, hashes.count, "expected at least \(expectedShotCount / 2) distinct shot counts")
        return shots
    }

    /// Captures screenshots from the app's top-level facets.
    ///
    /// 10 screenshots per 3 device type (5.5" iPhone, 6.5" iPhone, Pad) and 40 locales:
    ///    5 facets / light/dark mode
    ///
    /// Specific screenshot sizes for the App Store can be seen at:
    /// https://help.apple.com/app-store-connect/#/devd274dd925
    ///
    /// - Parameters:
    ///   - folder: the folder for outputting screenshot images, if any
    ///   - linkDuplicates: whether to create links for identical screenshot file contents
    ///   - vector: whether to output a vector (PDF) or bitmap (PNG)
    ///   - bundle: the bundle in which the localizations are contained
    ///   - devices: the devices to use for generating screens
    ///   - orientations: the orientations to use
    ///   - locales: the locales for screenshot genration; if nil, all the `bundle`'s supported localizations will be used
    ///   - colorSchemes: the schemes to use for generating screens
    ///   - appFacets: the facets to render, in order
    ///   - configFacets: the config facets to render, in order
    /// - Returns: metadata describing the screenshot that was created, as well as the URL that was written to
    @MainActor @discardableResult func captureScreenshots(folder: URL? = nil, linkDuplicates: Bool = true, vector: Bool, bundle: Bundle, devices: [DevicePreview] = DevicePreview.requiredDevices, orientations: [InterfaceOrientation] = [.portrait], locales: [Locale]? = nil, colorSchemes: [SwiftUI.ColorScheme] = [.light, .dark], appFacets: [AppFacets], configFacets: [ConfigFacets]) throws -> [ScreenshotResult] {

        #if os(macOS)
        if ({ true }()) {
            dbg("screenshots not yet supported on macOS")
            return []
        }
        #endif


        // if the locales are not set, then use every locale in the app's bundle
        let locales = locales ?? bundle.localizations.map(Locale.init(identifier:))

        var shots: [ScreenshotResult] = []

        // since we are running in test cases,
        let window = UXWindow()
        #if os(iOS)
        window.makeKeyAndVisible() // seems to be the only way to avoid nil screenshots
        #endif
        // win.contentScaleFactor = 2.0
        defer { window.resignKey() }

        let props = ScreenProps<AppFacets>()
        let container = ScreenshotContainerView<Self>(store: self, props: props)
        let view = container


        // re-scaling needs to be done to size the image correctly
        let rescale = 2.0

        let host = UXHostingController(rootView: view)

        for deviceType in devices {

            for locale in locales {
                props.locale = locale

                var screenindex = 0 // each locale and device combination can have up to 10 screenshots
                for orientation in orientations {
                    for colorScheme in colorSchemes {
                        props.colorScheme = colorScheme

                        var device = deviceType
                        if orientation == .landscapeLeft || orientation == .landscapeRight {
                            // handling landscape simple swaps the width and height
                            // swap(&device.width, &device.height)
                            let (width, height) = (device.width, device.height)
                            (device.width, device.height) = (height, width)
                        }

                        // var remaining = 5 // 5 screenshots per colorScheme
                        var remaining = 3 // 3 screenshots per colorScheme

                        for appFacet in appFacets {
                            props.appFacet = appFacet

                            remaining -= 1
                            if remaining <= 0 { break }

                            let shot = try shootScreen(configFacet: nil)
                            dbg("captured screenshot for appFacet:", appFacet.rawValue, "device:", shot)

                            if appFacet == appFacets.last {
                                // the final facet is the settings: if we have any screenshots remaining, cycle through them to get previews of the preferences, etc.
                                for configFacet in configFacets {
                                    let shot = try shootScreen(configFacet: configFacet)
                                    dbg("captured screenshot for configFacet:", configFacet.rawValue, "device:", shot)
                                    remaining -= 1
                                    if remaining <= 0 { break }
                                }
                            }

                            /// Take a screenshot of the given facet
                            func shootScreen(configFacet: ConfigFacets?) throws -> ScreenshotResult? {
                                assert(Thread.isMainThread)
                                // LocaleManager.shared.locale = wip(locale) // not working

                                var shot = ScreenshotResult(locale: locale.identifier, device: device.device.rawValue, appFacet: appFacet.rawValue, configFacet: configFacet?.rawValue, width: device.width, height: device.height)

                                //let view2 = Circle().fill(Color.red).padding()
                                let dwidth = device.width // / wip(2)
                                let dheight = device.height // / wip(2)

                                #if os(iOS)
                                host.view.layoutSubviews()
                                #elseif os(macOS)
                                host.view.layout()
                                #endif
                                guard let img = host.snapshot(inWindow: window, bounds: CGRect(origin: .zero, size: CGSize(width: dwidth / rescale, height: dheight / rescale)), pdf: vector, scale: rescale) else {
                                    dbg("could not create image for host")
                                    return nil
                                }

                                shot.imageSize = img.count
                                shot.imageSHA256 = img.sha256().hex()

                                if let folder = folder {
                                    var screenindexName = "\(screenindex)"
                                    if screenindex < 10 { // zero-pad: 01, 02, etc.
                                        screenindexName = "0" + screenindexName
                                    }

                                    // let localeFolder = folder.appendingPathComponent(locale.identifier, isDirectory: true)
                                    // relative paths let us create relative symbolic links, which are respected when relocated or archived

                                    // the name of the locale's folder should conform to Fastlane's localization identifiers;
                                    // otherwise the locale won't match up and `fastlane deliver` will fail
                                    guard let folderName = locale.exportedMetadataFolderName else {
                                        dbg("no export localization folder for:", locale.identifier)
                                        return nil
                                    }
                                    let localeFolder = URL(fileURLWithPath: folderName, isDirectory: true, relativeTo: folder)

                                    try FileManager.default.createDirectory(at: localeFolder, withIntermediateDirectories: true)

                                    let screenshotOutputURL = localeFolder
                                        .appendingPathComponent("screen-\(device.deviceClass.rawValue)-\(screenindexName)-\(colorScheme)-\(Int(dwidth))x\(Int(dheight))", isDirectory: false)
                                        .appendingPathExtension(vector ? "pdf": "png")

                                    //XCTAttachment(image: UIImage)
                                    //XCUIScreenshot

                                    if linkDuplicates == true,
                                       let existingShot = shots.first(where: { $0.imageSHA256 == shot.imageSHA256 }) {
                                        // if a shot is identical to another shot, simply create a symbolic link between them rather than writing an extra file
                                        dbg("screenshot duplicates:", shot, existingShot)
                                        if let existingURL = existingShot.url, existingURL != screenshotOutputURL {
                                            if FileManager.default.resolvingSymbolicLink(screenshotOutputURL) != existingURL {
                                                try? FileManager.default.removeItem(at: screenshotOutputURL) // overwrite existing screenshot link

                                                dbg("creating symbolic link from:", screenshotOutputURL.path, "to:", existingURL.path)
                                                try FileManager.default.createSymbolicLink(at: screenshotOutputURL, withDestinationURL: existingURL, relative: true)
                                            }
                                        }
                                    } else {
                                        dbg("writing screenshot to:", screenshotOutputURL.path)
                                        try img.overwrite(to: screenshotOutputURL)
                                        shot.url = screenshotOutputURL
                                    }
                                }

                                screenindex += 1
                                shots.append(shot)
                                return shot
                            }

                        }
                    }
                }
            }
        }

        let totalSize = shots.reduce(0) { a, b in a + (b.imageSize ?? 0) }
        let distinctShots = shots.grouping(by: \.imageSHA256)
        let totalDistinctSize = distinctShots.reduce(0) { a, b in a + (b.value.first?.imageSize ?? 0) }
        dbg("captured", shots.count, "screenshots", "total size:", totalSize.localizedByteCount(), "distinct:", distinctShots.count, "distinct size:", totalDistinctSize.localizedByteCount())
        return shots
    }
}

private final class ScreenProps<AppFacets> : ObservableObject {
    @Published var appFacet: AppFacets? = nil
    @Published var locale: Locale? = nil
    @Published var colorScheme: ColorScheme? = nil

    init() {
    }
}

private struct ScreenshotContainerView<Store: SceneManager> : View where Store.AppFacets.FacetStore == Store {
    @ObservedObject var store: Store
    @ObservedObject var props: ScreenProps<Store.AppFacets>

    init(store: Store, props: ScreenProps<Store.AppFacets>) {
        self.store = store
        self.props = props
    }

    var body: some View {
        FacetBrowserView<Store, Store.AppFacets>(nested: false, selection: $props.appFacet)
                .environmentObject(store)
                //.background(Color.black)
                .withLocaleSetting()
                .withAppearanceSetting()
                .environment(\.locale, props.locale ?? .current)
                .environment(\.colorScheme, props.colorScheme ?? .light)
                //.environment(\.displayScale, 2.0)
                //.environment(\.layoutDirection, layoutDirection) // TODO
                //.environment(\.verticalSizeClass, .compact) // TODO: set size classes for device
                //.environment(\.horizontalSizeClass, .compact) // TODO: set size classes for device
                //.previewInterfaceOrientation(orientation)
    }
}


/// A serializable screenshot result that tracks the parameters of the screenshot along with
public struct ScreenshotResult : Encodable {
    /// The ``Locale.identifier`` for the screenshot
    public var locale: String
    /// The device model name
    public var device: String
    /// Which app facet is being rendered
    public var appFacet: String
    /// Which config facet is used to render this shot (if any)
    public var configFacet: String?
    /// The width of the screenshot
    public var width: Double
    /// The height of the screenshot
    public var height: Double
    /// The location of the screenshot on disk
    public var url: URL?
    /// The total size of the image, in bytes, on disk
    public var imageSize: Int?
    /// The image's SHA-256
    public var imageSHA256: String?
}


public struct DevicePreview {
    public var device: PreviewDevice
    public var deviceClass: DeviceClass
    public var width: Double
    public var height: Double

    /// The support preview classes
    public enum DeviceClass : String {
        case iphone, ipad, mac, tv, watch

        public var platform: PreviewPlatform {
            switch self {
            case .iphone: return .iOS
            case .ipad: return .iOS
            case .mac: return .macOS
            case .tv: return .tvOS
            case .watch: return .watchOS
            }
        }

    }
}



/// Device constants for https://help.apple.com/app-store-connect/#/devd274dd925
public extension DevicePreview {
    /// The minimum set of required screenshots
    static let requiredDevices: [Self] = [.iPhone8Plus, .iPhone14Plus, .iPadPro6]

    /// 5.5 inch (iPhone 8 Plus, iPhone 7 Plus, iPhone 6s Plus) 1242 x 2208 pixels (portrait)
    static let iPhone8Plus = DevicePreview(device: PreviewDevice(rawValue: "iPhone 8 Plus"), deviceClass: .iphone, width: 1242, height: 2208)

    /// 6.5 inch device: 1284 x 2778 pixels
    static let iPhone14Plus = DevicePreview(device: PreviewDevice(rawValue: "iPhone 14 Plus"), deviceClass: .iphone, width: 1284, height: 2778)

    /// 12.9 inch (iPad Pro (6th generation, 5th generation, 4th generation, 3rd generation)) 2048 x 2732 pixels (portrait)
    static let iPadPro6 = DevicePreview(device: PreviewDevice(rawValue: "iPad Pro (6th generation)"), deviceClass: .ipad, width: 2048, height: 2732)
}

#endif
