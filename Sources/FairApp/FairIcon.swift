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
import Foundation
#if canImport(SwiftUI)
import SwiftUI
import FairCore

/// A view that generates the default icon for a FairApp.
/// The icon consists of the app name laid out on a circular path.
public struct FairIconView : View, Equatable {
    /// The first word of the app's name
    var word1: String
    /// The second word of the app's name
    var word2: String
    /// A string to appear below the monogram
    let subtitle: String?
    /// System symbol names to emboss behind the monogram
    let symbolNames: [String]
    /// The base color for the icon
    let iconColor: Color?

    public init(_ name: String, subtitle: String?, symbolNames: [String] = [], iconColor: Color? = nil) {
        let parts = name.components(separatedBy: CharacterSet.letters.inverted)
        self.word1 = parts.first ?? "Invalid"
        self.word2 = parts.last ?? "Name"
        self.subtitle = subtitle
        self.symbolNames = symbolNames
        self.iconColor = iconColor
    }

    public var body: some View {
        GeometryReader { proxy in
            iconView(for: min(proxy.size.width, proxy.size.height))
        }
    }

    /// Returns the default icon color for the given app name, separated into two parts
    public static func iconColor(name: String) -> Color {
        let parts = name.components(separatedBy: CharacterSet.letters.inverted)
        let word1 = parts.first ?? "Invalid"
        let word2 = parts.last ?? "Name"
        return renderColor(word1: word1, word2: word2)
    }
    
    /// The default icon color for the two parts
    /// - Parameters:
    ///   - word1: the first word
    ///   - word2: the second word
    ///   - saturation: the color saturation
    ///   - brightness: the color brightness
    ///   - base: a base color to use rather than the word's seeded random
    /// - Returns: the color to use for rendering
    static func renderColor(word1: String, word2: String, saturation: CGFloat = 0.99, brightness: CGFloat = 0.8, base: Color? = nil) -> Color {
        let wordHue = (word1.derivedComponent + word2.derivedComponent) / 2.0
        var hue = wordHue

        // if we have specified a base color, use the hue as the basis for our app
        if let base = base {
            UXColor(base).getHue(&hue, saturation: nil, brightness: nil, alpha: nil)
        }
        let color = Color(hue: hue, saturation: saturation, brightness: brightness)
        return color
    }
    
    func iconFont(size: CGFloat) -> Font {
        Font.system(size: size, design: Font.Design.rounded)
            .weight(.bold)
//            .smallCaps()
        //Font.system(size: size).smallCaps()
    }

    func iconView(for span: CGFloat) -> some View {
        let monogram = String([word1.first, word2.first].compacted()).uppercased()

        // create a top-down gradient of the brighter color
        func clr(s: CGFloat, b: CGFloat) -> Color {
            Self.renderColor(word1: word1, word2: word2, saturation: s, brightness: b, base: iconColor)
        }

        let c1 = clr(s: 0.5, b: 0.9)
        let c2 = clr(s: 0.9, b: 0.5)
        let c3 = clr(s: 0.7, b: 0.75)

        let gradient = Gradient(colors: [c1, c2])

        let fillStyle = LinearGradient(gradient: gradient, startPoint: .top, endPoint: .bottom)
        //let fillStyle = RadialGradient(gradient: gradient, center: .center, startRadius: 0, endRadius: span*0.6)

        let textColor = Color.white

        let rect = CGRect(origin: .zero, size: CGSize(width: span, height: span))

        let squircle = RoundedRectangle(cornerRadius: span / 4.3, style: .continuous)
        func maskPath() -> some Shape {
            //var shape = Circle().path(in: rect)
            var shape = Rectangle().path(in: rect)
            shape.addPath(Circle().inset(by: span * 0.24).path(in: rect))
            return shape
        }

        func borderMask() -> some Shape {
            //var shape = Circle().path(in: rect)
            var shape = squircle.path(in: rect)
            shape.addPath(squircle.inset(by: span * 0.04).path(in: rect))
            return shape
        }

        return ZStack(alignment: .center) {
            squircle
                .fill(fillStyle)
                .frame(width: span, height: span, alignment: .center)
                //.mask(maskPath().fill(style: FillStyle(eoFill: true)))

            squircle
                .fill(c3)
                //.mask(RoundedRectangle(cornerRadius: span / 4.3, style: .continuous).path(in: rect).fill(style: FillStyle(eoFill: true)))
                .mask(borderMask().fill(style: FillStyle(eoFill: true)))
                .shadow(color: Color.black.opacity(1.0), radius: span * 0.010, x: 0, y: 0) // double interior shadow for raised effect

            ZStack {
                ForEach(self.symbolNames, id: \.self) { symbolName in
                    Text(Image(systemName: symbolName))
                        .font(iconFont(size: span * 0.5))
                        .opacity(0.95)
                        //.opacity(monogram.isEmpty ? 1.0 : 0.5)
                }
                if self.symbolNames.isEmpty {
                    VStack {
                        Text(monogram)
                            .font(iconFont(size: span * 0.5))
                        if let subtitle = subtitle {
                            Text(subtitle)
                                .font(Font.system(size: span * 0.16, weight: .semibold, design: .rounded))
                        }
                    }
                }
            }
            .shadow(color: Color.black.opacity(0.9), radius: span * 0.010, x: 0, y: 1)
            .foregroundColor(textColor)
            .lineLimit(1)
            .multilineTextAlignment(.center)
        }
    }
}

extension LinearGradient {
    init(_ colors: Color...) {
        self.init(gradient: Gradient(colors: colors), startPoint: .topLeading, endPoint: .bottomTrailing)
    }
}

private extension String {
    /// Returns a pseudo-random value from 0.0-1.0 based on the word's SHA hash
    var derivedComponent: CGFloat {
        let i: UInt8 = self.utf8Data.sha256().last ?? 0
        return CGFloat(i) / CGFloat(UInt8.max)
    }
}

private struct CharSeqSizeKey: PreferenceKey {
    static var defaultValue: [CGSize] { [] }
    static func reduce(value: inout [CGSize], nextValue: () -> [CGSize]) {
        value.append(contentsOf: nextValue())
    }
}

private struct PropagateSize<V: View>: View {
    var content: () -> V
    var body: some View {
        content()
            .background(GeometryReader { proxy in
                Color.clear.preference(key: CharSeqSizeKey.self, value: [proxy.size])
            })
    }
}

private struct IndexedChar: Hashable, Identifiable {
    let index: Int
    let character: Character

    var id: Self { self }

    var string: String { "\(character)" }
}

struct FairIconView_Previews: PreviewProvider {
    static var previews: some View {
        let span: CGFloat = 80
        var rndgen = SeededRandomNumberGenerator(uuids: UUID(uuidString: "C3C3FF68-AF95-4AF4-BE53-EC88EE097552")!)

        let symbolNames = sampleSymbolNames.shuffled(using: &rndgen)
        let appNames = try! AppNameValidation.standard.suggestNames(count: 24, rnd: &rndgen)
        let appSymbols: [(appName: String, symbolName: String)] = Array(zip(appNames, symbolNames))

        return LazyHGrid(rows: [
            GridItem(.adaptive(minimum: span, maximum: span)),
            //GridItem(.adaptive(minimum: 100, maximum: 200)),
        ]) {
            ForEach(appSymbols, id: \.appName) { appName, symbolName in
                FairIconView(appName, subtitle: "", symbolNames: [symbolName])
                    .frame(width: span, height: span)
            }
        }
        .frame(width: 400, height: 600)
        .previewLayout(.sizeThatFits)
    }
}

let sampleSymbolNames = [
    "pencil",
    "pencil.circle",
    "square.and.pencil",
    "rectangle.and.pencil.and.ellipsis",
    "highlighter",
    "pencil.and.outline",
    "pencil.tip",
    "pencil.tip.crop.circle",
    "lasso",
    "lasso.and.sparkles",
    "trash",
    "trash.fill",
    "trash.circle",
    "trash.slash.square",
    "trash.slash.square.fill",
    "folder",
    "folder.fill",
    "folder.circle",
    "folder.circle.fill",
    "folder.badge.plus",
    "folder.fill.badge.questionmark",
    "folder.badge.person.crop",
    "questionmark.folder",
    "questionmark.folder.fill",
    "paperplane",
    "paperplane.fill",
    "paperplane.circle",
    "paperplane.circle.fill",
    "tray",
    "tray.fill",
    "tray.circle",
    "externaldrive.badge.minus",
    "externaldrive.fill.badge.minus",
    "externaldrive.badge.checkmark",
    "externaldrive.fill.badge.checkmark",
    "externaldrive.badge.xmark",
    "externaldrive.fill.badge.xmark",
    "externaldrive.badge.person.crop",
    "externaldrive.fill.badge.person.crop",
    "externaldrive.badge.icloud",
    "externaldrive.fill.badge.icloud",
    "externaldrive.badge.wifi",
    "externaldrive.fill.badge.wifi",
    "externaldrive.badge.timemachine",
    "externaldrive.connected.to.line.below",
    "externaldrive.connected.to.line.below.fill",
    "archivebox",
    "archivebox.fill",
    "archivebox.circle",
    "archivebox.circle.fill",
    "xmark.bin",
    "xmark.bin.fill",
    "xmark.bin.circle",
    "xmark.bin.circle.fill",
    "arrow.up.bin",
    "arrow.up.bin.fill",
    "doc",
    "doc.fill",
    "doc.circle",
    "doc.circle.fill",
    "arrow.up.doc",
    "arrow.up.doc.fill",
    "arrow.down.doc",
    "arrow.down.doc.fill",
    "doc.text",
    "doc.text.fill",
    "doc.on.doc",
    "doc.on.doc.fill",
    "doc.on.clipboard",
    "arrow.right.doc.on.clipboard",
    "arrow.up.doc.on.clipboard",
    "arrow.triangle.2.circlepath.doc.on.clipboard",
    "doc.on.clipboard.fill",
    "doc.text.magnifyingglass",
    "note",
    "note.text",
    "note.text.badge.plus",
    "calendar",
    "calendar.circle",
    "calendar.circle.fill",
    "calendar.badge.plus",
    "calendar.badge.minus",
    "calendar.badge.clock",
    "calendar.badge.exclamationmark",
    "book",
    "book.fill",
    "book.circle",
    "book.circle.fill",
    "books.vertical",
    "books.vertical.fill",
    "books.vertical.circle",
    "books.vertical.circle.fill",
    "book.closed",
    "book.closed.fill",
    "book.closed.circle",
    "book.closed.circle.fill",
    "character.book.closed",
    "character.book.closed.fill",
    "text.book.closed",
    "text.book.closed.fill",
    "menucard",
    "menucard.fill",
    "greetingcard",
    "greetingcard.fill",
    "magazine",
    "magazine.fill",
    "newspaper",
    "newspaper.fill",
    "newspaper.circle",
    "newspaper.circle.fill",
    "bookmark",
    "bookmark.fill",
    "bookmark.circle",
    "bookmark.circle.fill",
    "bookmark.square",
    "bookmark.square.fill",
    "bookmark.slash",
    "bookmark.slash.fill",
    "rosette",
    "graduationcap",
    "graduationcap.fill",
    "graduationcap.circle",
    "graduationcap.circle.fill",
    "ticket",
    "ticket.fill",
    "paperclip",
    "paperclip.circle",
    "paperclip.circle.fill",
    "paperclip.badge.ellipsis",
    "rectangle.and.paperclip",
    "rectangle.dashed.and.paperclip",
    "link",
    "link.circle",
    "link.circle.fill",
    "link.badge.plus",
    "personalhotspot",
    "personalhotspot.circle",
    "personalhotspot.circle.fill",
    "umbrella",
    "umbrella.fill",
    "megaphone",
    "megaphone.fill",
    "speaker",
    "speaker.wave.1",
    "speaker.wave.1.fill",
    "speaker.wave.2",
    "music.mic",
    "music.mic.circle",
    "music.mic.circle.fill",
    "magnifyingglass",
    "magnifyingglass.circle",
    "magnifyingglass.circle.fill",
    "plus.magnifyingglass",
    "minus.magnifyingglass",
    "1.magnifyingglass",
    "arrow.up.left.and.down.right.magnifyingglass",
    "text.magnifyingglass",
    "sparkle.magnifyingglass",
    "location.magnifyingglass",
    "flag",
    "flag.fill",
    "flag.circle",
    "flag.circle.fill",
    "flag.square",
    "flag.square.fill",
    "flag.2.crossed.fill",
    "flag.filled.and.flag.crossed",
    "flag.and.flag.filled.crossed",
    "sensor.tag.radiowaves.forward",
    "sensor.tag.radiowaves.forward.fill",
    "bell",
    "bell.fill",
    "bell.circle",
    "bell.circle.fill",
    "bell.square",
    "bell.square.fill",
    "bell.slash",
    "tag.fill",
    "tag.circle",
    "tag.circle.fill",
    "tag.square",
    "tag.square.fill",
    "tag.slash",
    "tag.slash.fill",
    "bolt.shield",
    "bolt.shield.fill",
    "eyeglasses",
    "facemask",
    "facemask.fill",
    "flashlight.off.fill",
    "flashlight.on.fill",
    "camera",
    "camera.fill",
    "arrow.triangle.2.circlepath.camera.fill",
    "camera.on.rectangle",
    "camera.on.rectangle.fill",
    "gear",
    "gearshape",
    "gearshape.fill",
    "gearshape.2",
    "gearshape.2.fill",
    "scissors",
    "scissors.circle",
    "scissors.circle.fill",
    "scissors.badge.ellipsis",
    "wallet.pass",
    "wallet.pass.fill",
    "wand.and.rays",
    "wand.and.rays.inverse",
    "wand.and.stars",
    "wand.and.stars.inverse",
    "crop",
    "crop.rotate",
    "dial.min",
    "dial.min.fill",
    "dial.max",
    "dial.max.fill",
    "gyroscope",
    "gauge",
    "gauge.badge.plus",
    "gauge.badge.minus",
    "speedometer",
    "barometer",
    "metronome",
    "metronome.fill",
    "amplifier",
    "dice",
    "dice.fill",
    "die.face.1",
    "die.face.1.fill",
    "die.face.2",
    "die.face.2.fill",
    "die.face.3",
    "die.face.3.fill",
    "die.face.4",
    "die.face.4.fill",
    "die.face.5",
    "die.face.5.fill",
    "die.face.6",
    "die.face.6.fill",
    "pianokeys",
    "pianokeys.inverse",
    "tuningfork",
    "paintbrush",
    "paintbrush.fill",
    "paintbrush.pointed",
    "paintbrush.pointed.fill",
    "bandage",
    "bandage.fill",
    "ruler",
    "ruler.fill",
    "level",
    "level.fill",
    "wrench",
    "wrench.fill",
    "hammer",
    "hammer.fill",
    "hammer.circle",
    "hammer.circle.fill",
    "screwdriver",
    "screwdriver.fill",
    "eyedropper",
    "eyedropper.halffull",
    "eyedropper.full",
    "wrench.and.screwdriver",
    "wrench.and.screwdriver.fill",
    "scroll",
    "scroll.fill",
    "stethoscope",
    "stethoscope.circle",
    "stethoscope.circle.fill",
    "printer",
    "printer.fill",
    "printer.filled.and.paper",
    "printer.dotmatrix",
    "printer.dotmatrix.fill",
    "printer.dotmatrix.filled.and.paper",
    "scanner",
    "scanner.fill",
    "faxmachine",
    "briefcase",
    "briefcase.fill",
    "briefcase.circle",
    "briefcase.circle.fill",
    "case",
    "case.fill",
    "latch.2.case",
    "latch.2.case.fill",
    "cross.case",
    "cross.case.fill",
    "suitcase",
    "suitcase.fill",
    "suitcase.cart",
    "suitcase.cart.fill",
    "theatermasks",
    "theatermasks.fill",
    "theatermasks.circle",
    "theatermasks.circle.fill",
    "puzzlepiece.extension",
    "puzzlepiece.extension.fill",
    "puzzlepiece",
    "puzzlepiece.fill",
    "building",
    "building.fill",
    "building.2",
    "building.2.fill",
    "building.2.crop.circle",
    "building.2.crop.circle.fill",
    "lock",
    "lock.fill",
    "lock.circle",
    "lock.circle.fill",
    "lock.square",
    "lock.square.fill",
    "lock.square.stack",
    "lock.square.stack.fill",
    "lock.rectangle",
    "lock.rectangle.fill",
    "lock.rectangle.stack",
    "lock.rectangle.stack.fill",
    "lock.rectangle.on.rectangle",
    "lock.rectangle.on.rectangle.fill",
    "lock.shield",
    "lock.shield.fill",
    "lock.slash",
    "lock.slash.fill",
    "lock.open",
    "lock.open.fill",
    "lock.rotation",
    "lock.rotation.open",
    "key",
    "key.fill",
    "pin",
    "pin.fill",
    "pin.circle",
    "pin.circle.fill",
    "pin.square",
    "pin.square.fill",
    "pin.slash",
    "pin.slash.fill",
    "mappin",
    "mappin.circle",
    "mappin.circle.fill",
    "mappin.square",
    "mappin.square.fill",
    "mappin.slash",
    "mappin.and.ellipse",
    "map",
    "map.fill",
    "map.circle",
    "map.circle.fill",
    "powerplug",
    "powerplug.fill",
    "cpu",
    "cpu.fill",
    "memorychip",
    "memorychip.fill",
    "opticaldisc",
    "airpodsmax",
    "beats.headphones",
    "headphones",
    "headphones.circle",
    "headphones.circle.fill",
    "radio",
    "radio.fill",
    "antenna.radiowaves.left.and.right",
    "antenna.radiowaves.left.and.right.slash",
    "antenna.radiowaves.left.and.right.circle",
    "antenna.radiowaves.left.and.right.circle.fill",
    "guitars",
    "guitars.fill",
    "fuelpump",
    "fuelpump.fill",
    "fuelpump.circle",
    "fuelpump.circle.fill",
    "fanblades",
    "fanblades.fill",
    "bed.double",
    "bed.double.fill",
    "bed.double.circle",
    "bed.double.circle.fill",
    "testtube.2",
    "ivfluid.bag",
    "ivfluid.bag.fill",
    "cross.vial",
    "cross.vial.fill",
    "film",
    "film.fill",
    "film.circle",
    "film.circle.fill",
    "crown",
    "crown.fill",
    "comb",
    "comb.fill",
    "camera.viewfinder",
    "shield",
    "shield.fill",
    "shield.lefthalf.filled",
    "shield.righthalf.filled",
    "shield.slash",
    "shield.slash.fill",
    "shield.lefthalf.filled.slash",
    "checkerboard.shield",
    "cube",
    "cube.fill",
    "shippingbox",
    "shippingbox.fill",
    "shippingbox.circle",
    "shippingbox.circle.fill",
    "clock",
    "clock.fill",
    "clock.circle",
    "clock.circle.fill",
    "clock.badge.checkmark",
    "clock.badge.checkmark.fill",
    "clock.badge.exclamationmark",
    "clock.badge.exclamationmark.fill",
    "deskclock",
    "deskclock.fill",
    "alarm",
    "alarm.fill",
    "stopwatch",
    "stopwatch.fill",
    "chart.xyaxis.line",
    "timer",
    "timer.square",
    "gamecontroller",
    "gamecontroller.fill",
    "paintpalette",
    "paintpalette.fill",
    "cup.and.saucer",
    "cup.and.saucer.fill",
    "takeoutbag.and.cup.and.straw",
    "takeoutbag.and.cup.and.straw.fill",
    "fork.knife",
    "fork.knife.circle",
    "fork.knife.circle.fill",
    "simcard",
    "simcard.fill",
    "simcard.2",
    "simcard.2.fill",
    "sdcard",
    "sdcard.fill",
    "esim",
    "esim.fill",
    "scalemass",
    "scalemass.fill",
    "gift",
    "gift.fill",
    "gift.circle",
    "gift.circle.fill",
    "studentdesk",
    "hourglass",
    "hourglass.circle",
    "hourglass.circle.fill",
    "hourglass.badge.plus",
    "hourglass.bottomhalf.filled",
    "hourglass.tophalf.filled",
    "camera.filters",
    "lifepreserver",
    "lifepreserver.fill",
    "binoculars",
    "binoculars.fill",
    "battery.100",
    "battery.75",
    "battery.50",
    "battery.25",
    "battery.0",
    "battery.100.bolt",
    "minus.plus.batteryblock",
    "minus.plus.batteryblock.fill",
    "bolt.batteryblock",
    "bolt.batteryblock.fill",
    "lightbulb",
    "lightbulb.fill",
    "lightbulb.circle",
    "lightbulb.circle.fill",
    "lightbulb.slash",
    "lightbulb.slash.fill",
    "exclamationmark.shield",
    "exclamationmark.shield.fill",
    "xmark.shield",
    "xmark.shield.fill",
    "checkmark.shield",
    "checkmark.shield.fill",
]
#endif
