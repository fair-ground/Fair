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

 You should have received a copy of the GNU Affero General Public License
 along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */
import Swift

@_exported import FairApp

#if canImport(SwiftUI)
import SwiftUI

public extension Bundle {
    /// Creates a label with the given localized key and the optional icon
    @available(*, deprecated)
    func label(_ title: LocalizedStringKey, _ iconSymbol: String? = nil) -> Label<Text, Image?> {
        Label(title: {
            Text(title, bundle: self)
        }, icon: {
            iconSymbol.flatMap(Image.init(systemName:))
        })
    }

    /// Creates a button with the given localized key and the optional icon
    @available(*, deprecated)
    func button(_ title: LocalizedStringKey, _ iconSymbol: String? = nil, action: @escaping () -> ()) -> Button<Label<Text, Image?>> {
        Button(action: action, label: { label(title, iconSymbol) })
    }
}


/// A caching mechanism for images
public protocol CachedImageCache {
    @MainActor subscript(url: URL) -> Image? { get nonmutating set }
}

public final class AsyncCachedImageCache : CachedImageCache {
    /// A singleton image cache that can be used globally
    public static let shared = AsyncCachedImageCache()

    private var cache = NSCache<NSURL, ImageInfo>()

    /// Access the underlying cached image
    @MainActor public subscript(_ url: URL) -> Image? {
        get {
            cache.object(forKey: url as NSURL)?.image
        }

        set {
            if let newValue = newValue {
                cache.setObject(ImageInfo(image: newValue), forKey: url as NSURL)
            } else {
                cache.removeObject(forKey: url as NSURL)
            }
        }
    }

    /// Clear the image cache
    public func clear() {
        cache.removeAllObjects()
    }

    private final class ImageInfo {
        let image: SwiftUI.Image

        init(image: SwiftUI.Image) {
            self.image = image
        }
    }
}

@available(*, deprecated, message: "cached SwiftUI.Image instances seem to become invalid after a while")
public struct AsyncCachedImage<Content>: View where Content: View {
    private let cache: CachedImageCache
    private let url: URL
    private let scale: CGFloat
    private let transaction: Transaction
    private let content: (AsyncImagePhase) -> Content

    public init(cache: CachedImageCache = AsyncCachedImageCache.shared, url: URL, scale: CGFloat = 1.0, transaction: Transaction = Transaction(), @ViewBuilder content: @escaping (AsyncImagePhase) -> Content) {
        self.cache = cache
        self.url = url
        self.scale = scale
        self.transaction = transaction
        self.content = content
    }

    public var body: some View {
        if let cached = cache[url] {
            content(.success(cached))
        } else {
            AsyncImage(url: url, scale: scale, transaction: transaction) { phase in
                cacheAndRender(phase: phase)
            }
        }
    }

    @MainActor func cacheAndRender(phase: AsyncImagePhase) -> some View {
        if case .success (let image) = phase {
            cache[url] = image // cache the image
        }
        return content(phase)
    }
}

/// An image that loads from a URL, either synchronously or asynchronously
public struct URLImage : View, Equatable {
    /// The URL from which to load
    public let url: URL
    /// The scale of the image
    public let scale: CGFloat
    /// Whether the image should be resizable or not
    public let resizable: ContentMode?
    /// Whether to show the error message
    public let showError: Bool
    /// Whether to re-attempt a cancelled error if it fails
    public let retryCancelledError: Bool
    /// The recommended size of the image, as encoded with the image ending in `"-widthxheight"`
    public let suggestedSize: CGSize?
    /// The cache of URL to images
    //private let imageCache: Cache<URL, Image>?

    public init(url: URL, scale: CGFloat = 1.0, resizable: ContentMode? = nil, showError: Bool = true, retryCancelledError: Bool = true) {
        self.url = url
        self.scale = scale
        self.resizable = resizable
        //self.imageCache = imageCache
        self.showError = showError
        self.retryCancelledError = retryCancelledError

        if let assetName = try? AssetName(string: url.lastPathComponent) {
            self.suggestedSize = assetName.size
        } else {
            self.suggestedSize = nil
        }
    }

    /// Cache the given image parameter for later re-use
    private func caching(image: Image) -> Image {
//        if let imageCache = imageCache {
//            imageCache[url] = image
//            dbg("cached image:", url.absoluteString)
//        }
        return image
    }

    @ViewBuilder func configureImage(_ image: Image?, cache: Bool = true) -> some View {
        if let image = image, let resizable = resizable {
            caching(image: image)
                .resizable(resizingMode: .stretch)
                .aspectRatio(contentMode: resizable)
        } else if let image = image {
            caching(image: image)
        }
    }

    /// Re-creates the same URLImage as a re-try for cancelled images
    private func retryImage() -> some View {
        URLImage(url: self.url, scale: self.scale, resizable: self.resizable, /*imageCache: self.imageCache, */ showError: self.showError, retryCancelledError: false)
    }

    @ViewBuilder public var body: some View {
//        if let cached = imageCache?[url] {
//            configureImage(cached, cache: false)
//        } else {
            AsyncImage(url: url, scale: scale, transaction: Transaction(animation: .easeIn)) { phase in
                if let image = phase.image {
                    configureImage(image)
                } else if let error = phase.error {
                    if let urlError = error as? URLError,
                       urlError.code == URLError.Code.cancelled,
                       retryCancelledError == true {
                        // there's a persistent issue with AsyncImages embedded in lazy containers like lists mentioned at https://developer.apple.com/forums/thread/682498 ; one work-around is to have AsyncImage return another AsyncImage with its handler reports a cancelled error
                        retryImage()
                    } else {
                        configureImage(placeholderImage(size: suggestedSize ?? .zero, color: .accentColor))
                            .overlay(Material.thick)
                            .help(showError ? error.localizedDescription : "An error occured when loading this image")
                    }
                } else if let suggestedSize = suggestedSize, suggestedSize.width > 0.0, suggestedSize.height > 0.0 {
                    configureImage(placeholderImage(size: suggestedSize))
                        .overlay(Material.thick)
                } else {
                    Circle().hidden()
                    // Color.gray.opacity(0.5)
                }
            }
//        }
    }

    /// Creates an empty image with a certain dimension.
    /// Useful for replicating the behavior of a placeholder image when all that is known is the size;
    /// the image will be drawn at the given size and so the aspect ratio will be respected.
    func placeholderImage(size: CGSize, color: Color? = nil, scale: CGFloat = 1.0, opaque: Bool = true) -> Image? {
        #if os(iOS)
        let rect = CGRect(origin: .zero, size: size)

        UIGraphicsBeginImageContextWithOptions(size, opaque, scale)
        if let color = color {
            UXColor(color).set()
        }
        UIRectFill(rect)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return Image(uxImage: image!)
        #elseif os(macOS)
        return Image(uxImage: NSImage(size: size, flipped: false) { rect in
            if let color = color {
                UXColor(color).set()
            }
            if opaque {
                rect.fill()
            }
            return true
        })
        #else
        return nil
        #endif
    }
}

extension ForEach where Content : View {
    /// Initialize with elements that are identified merely by their index
    public init<S : Sequence>(enumerated sequence: S, @ViewBuilder content: @escaping (Int, S.Element) -> Content) where ID == Int, Data == Array<EnumeratedSequence<S>.Element> {
        self = ForEach(Array(sequence.enumerated()), id: \.offset, content: content)
    }
}

public extension UsageDescriptionKeys {
    var icon: FairSymbol {
        switch self {
        case .NSSiriUsageDescription: return .ear
        case .NSSpeechRecognitionUsageDescription: return .waveform
        case .NSMicrophoneUsageDescription: return .mic_circle
        case .NSCameraUsageDescription: return .camera
        case .NSMotionUsageDescription: return .gyroscope
        case .NFCReaderUsageDescription: return .barcode_viewfinder
        case .NSBluetoothUsageDescription: return .cable_connector
        case .NSBluetoothAlwaysUsageDescription: return .cable_connector_horizontal
        case .NSBluetoothPeripheralUsageDescription: return .printer
        case .NSRemindersUsageDescription: return .text_badge_checkmark
        case .NSContactsUsageDescription: return .person_text_rectangle
        case .NSCalendarsUsageDescription: return .calendar
        case .NSPhotoLibraryAddUsageDescription: return .text_below_photo_fill
        case .NSPhotoLibraryUsageDescription: return .photo
        case .NSAppleMusicUsageDescription: return .music_note
        case .NSHomeKitUsageDescription: return .house
            //case .NSVideoSubscriberAccountUsageDescription: return .sparkles_tv
        case .NSHealthShareUsageDescription: return .stethoscope
        case .NSHealthUpdateUsageDescription: return .stethoscope_circle
        case .NSAppleEventsUsageDescription: return .scroll
        case .NSFocusStatusUsageDescription: return .eyeglasses
        case .NSLocalNetworkUsageDescription: return .network
        case .NSFaceIDUsageDescription: return .viewfinder
        case .NSLocationUsageDescription: return .location
        case .NSLocationAlwaysUsageDescription: return .location_fill
        case .NSLocationTemporaryUsageDescriptionDictionary: return .location_circle
        case .NSLocationWhenInUseUsageDescription: return .location_north
        case .NSLocationAlwaysAndWhenInUseUsageDescription: return .location_fill_viewfinder
        case .NSUserTrackingUsageDescription: return .eyes
        case .NSNearbyInteractionAllowOnceUsageDescription:
                return .person_badge_clock_fill
        case .NSLocationDefaultAccuracyReduced: return .location_square_fill
        case .NSWidgetWantsLocation: return .location_magnifyingglass
        case .NSVoIPUsageDescription: return .network_badge_shield_half_filled
        case .NSNearbyInteractionUsageDescription: return .person_2_wave_2
        case .NSSensorKitUsageDescription: return .antenna_radiowaves_left_and_right
        case .NSBluetoothWhileInUseUsageDescription: return .dot_radiowaves_right
        case .NSFallDetectionUsageDescription: return .figure_walk
        case .NSVideoSubscriberAccountUsageDescription: return .play_tv
        case .NSGKFriendListUsageDescription: return .person_3_sequence
        case .NSHealthClinicalHealthRecordsShareUsageDescription: return .cross_circle
        case .NSDesktopFolderUsageDescription: return .dock_rectangle
        case .NSDocumentsFolderUsageDescription: return .menubar_dock_rectangle
        case .NSDownloadsFolderUsageDescription: return .dock_arrow_down_rectangle
        case .NSSystemExtensionUsageDescription: return .desktopcomputer
        case .NSSystemAdministrationUsageDescription: return .lock_laptopcomputer
        case .NSFileProviderDomainUsageDescription: return .externaldrive_connected_to_line_below
        case .NSFileProviderPresenceUsageDescription: return .externaldrive_badge_checkmark
        case .NSNetworkVolumesUsageDescription: return .externaldrive_badge_wifi
        case .NSRemovableVolumesUsageDescription: return .externaldrive
        default: return .questionmark_circle
        }
    }
}

@available(macOS 12.0, iOS 15.0, *)
extension SwiftUI.TextField {
    /// Creates a `Link` to the given URL and overlays it over the trailing end of the field.
    public func overlink(to destination: URL?, image: Image = FairSymbol.arrowshape_turn_up_right_circle_fill.image) -> some View {
        self.overlay(alignment: .trailing) {
            if let destination = destination {
                Link(destination: destination) {
                    image
                }
                //.padding(.horizontal) // causes a crash
            }
        }
    }

}



#endif
