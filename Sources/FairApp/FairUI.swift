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
import FairCore
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

/// An image that loads from a URL, either synchronously or asynchronously
public struct URLImage : View, Equatable {
    /// Whether the image should be loaded synchronously or asynchronously
    public let sync: Bool
    /// The URL from which to load
    public let url: URL
    /// The scale of the image
    public let scale: CGFloat
    /// Whether the image should be resizable or not
    public let resizable: ContentMode?
    /// Whether a progress placeholder should be used
    public let showProgress: Bool
    /// The recommended size of the image, as encoded with the image ending in `"-widthxheight"`
    public let suggestedSize: CGSize?

    public init(sync: Bool = false, url: URL, scale: CGFloat = 1.0, resizable: ContentMode? = nil, showProgress: Bool = false) {
        self.sync = sync
        self.url = url
        self.scale = scale
        self.resizable = resizable
        self.showProgress = showProgress
        if let lastPart = url.deletingPathExtension()
            .lastPathComponent.split(separator: "-").last,
           let sizeParts = Optional.some(lastPart)?.split(separator: "x"),
           sizeParts.count == 2,
           let width = Int(sizeParts[0]),
           let height = Int(sizeParts[1]) {
            self.suggestedSize = CGSize(width: width, height: height)
        } else {
            self.suggestedSize = nil
        }
    }

    public var body: some View {
        if sync == false, #available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 8.0, *) {
            AsyncImage(url: url, scale: scale) { phase in
                if let image = phase.image {
                    if let resizable = resizable {
                        image
                            .resizable(resizingMode: .stretch)
                            .aspectRatio(contentMode: resizable)
                    } else {
                        image
                    }
                } else if let error = phase.error {
                    Label(error.localizedDescription, systemImage: "xmark.octagon")
                } else if showProgress == true {
                    ProgressView().progressViewStyle(.automatic)
                } else if let suggestedSize = suggestedSize {
                    if let resizable = resizable {
                        placeholderImage(size: suggestedSize)
                            .resizable()
                            .aspectRatio(contentMode: resizable)
                            .redacted(reason: .placeholder)
                    } else {
                        placeholderImage(size: suggestedSize)
                            .redacted(reason: .placeholder)
                    }
                } else {
                    Circle().hidden()
                    // Color.gray.opacity(0.5)
                }
            }
        } else { // load the image synchronously
            if let img = try? UXImage(data: Data(contentsOf: url)) {
                if let resizable = resizable {
                    Image(uxImage: img)
                        .resizable(resizingMode: .stretch)
                        .aspectRatio(contentMode: resizable)
                } else {
                    Image(uxImage: img)
                }
            } else {
                Label("Error Loading Image", systemImage: "xmark.octagon")
            }
        }
    }

    func placeholderImage(size: CGSize, color: CIColor = .clear) -> Image {
        Image(uxImage: UXImage(size: size, flipped: false, drawingHandler: { rect in
            true
        }))
    }
}

extension ForEach where Content : View {
    /// Initialize with elements that are identified merely by their index
    public init<S : Sequence>(enumerated sequence: S, @ViewBuilder content: @escaping (Int, S.Element) -> Content) where ID == Int, Data == Array<EnumeratedSequence<S>.Element> {
        self = ForEach(Array(sequence.enumerated()), id: \.offset, content: content)
    }
}


#endif
