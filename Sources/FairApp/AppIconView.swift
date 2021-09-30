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
#if canImport(SwiftUI)
import SwiftUI

@available(macOS 12.0, iOS 15.0, *)
struct AppIconView: View {
    var iconName: String
    var baseColor: Color

    var body: some View {
        GeometryReader { proxy in
            let span = min(proxy.size.width, proxy.size.height)
            ZStack(alignment: Alignment.center) {
                Circle()
                    .foregroundStyle(
                        .linearGradient(colors: [Color.gray, .white], startPoint: .bottomLeading, endPoint: .topTrailing))

                Circle()
                    .inset(by: span / 20)
                    .foregroundStyle(
                        .linearGradient(colors: [Color.gray, .white], startPoint: .topTrailing, endPoint: .bottomLeading))

                Image(systemName: iconName)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .foregroundStyle(.linearGradient(colors: [baseColor, baseColor.opacity(0.5)], startPoint: .topTrailing, endPoint: .bottomLeading))
                    //.border(.black, width: 1)
                    //.padding(span / 8)
                    //.background(Color.white.clipShape(Circle()))
                    //.padding(span / 30)
                    .shadow(color: .black, radius: 0, x: -span / 200, y: span / 200)
                    //.clipShape(Circle())
                    .frame(width: span * 0.5, height: span * 0.5)
            }
        }
        //.overlay(Text("X", bundle: .module).font(Font.system(size: 70, weight: .bold, design: .rounded)))
    }
}

@available(macOS 12.0, iOS 15.0, *)
struct AppIconView_Previews: PreviewProvider {
    static var previews: some View {
        ForEach([16.0, 32.0, 128.0, 256.0, 512.0], id: \.self) { span in
            AppIconView(iconName: symbolNames.randomElement()!, baseColor: Color(hue: Double.random(in: 0...1), saturation: 0.99, brightness: 0.99))
                .frame(width: span, height: span)
        }
    }
}

var symbolNames = [
    "pencil",
    "pencil.circle",
    "pencil.circle.fill",
    "pencil.slash",
    "square.and.pencil",
    "rectangle.and.pencil.and.ellipsis",
    "highlighter",
    "pencil.and.outline",
    "pencil.tip",
    "pencil.tip.crop.circle",
    "pencil.tip.crop.circle.badge.plus",
    "pencil.tip.crop.circle.badge.minus",
    "pencil.tip.crop.circle.badge.arrow.forward",
    "lasso",
    "lasso.and.sparkles",
    "trash",
    "trash.fill",
    "trash.circle",
    "trash.circle.fill",
    "trash.square",
    "trash.square.fill",
    "trash.slash",
    "trash.slash.fill",
    "trash.slash.circle",
    "trash.slash.circle.fill",
    "trash.slash.square",
    "trash.slash.square.fill",
    "folder",
    "folder.fill",
    "folder.circle",
    "folder.circle.fill",
    "folder.badge.plus",
    "folder.fill.badge.plus",
    "folder.badge.minus",
    "folder.fill.badge.minus",
    "folder.badge.questionmark",
    "folder.fill.badge.questionmark",
    "folder.badge.person.crop",
    "folder.fill.badge.person.crop",
    "square.grid.3x1.folder.badge.plus",
    "square.grid.3x1.folder.fill.badge.plus",
    "folder.badge.gearshape",
    "folder.fill.badge.gearshape",
    "plus.rectangle.on.folder",
    "plus.rectangle.on.folder.fill",
    "questionmark.folder",
    "questionmark.folder.fill",
    "paperplane",
    "paperplane.fill",
    "paperplane.circle",
    "paperplane.circle.fill",
    "tray",
    "tray.fill",
    "tray.circle",
    "tray.circle.fill",
    "tray.and.arrow.up",
    "tray.and.arrow.up.fill",
    "tray.and.arrow.down",
    "tray.and.arrow.down.fill",
    "tray.2",
    "tray.2.fill",
    "tray.full",
    "tray.full.fill",
    "externaldrive",
    "externaldrive.fill",
    "externaldrive.badge.plus",
    "externaldrive.fill.badge.plus",
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
    "externaldrive.fill.badge.timemachine",
    "internaldrive",
    "internaldrive.fill",
    "opticaldiscdrive",
    "opticaldiscdrive.fill",
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
    "doc.badge.plus",
    "doc.fill.badge.plus",
    "doc.badge.gearshape",
    "doc.badge.gearshape.fill",
    "doc.badge.ellipsis",
    "doc.fill.badge.ellipsis",
    "lock.doc",
    "lock.doc.fill",
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
    "book.closed",
    "book.closed.fill",
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
    "umbrella",
    "megaphone",
    "megaphone.fill",
    "speaker",
    "speaker.fill",
    "speaker.circle",
    "speaker.circle.fill",
    "speaker.slash",
    "speaker.slash.fill",
    "speaker.slash.circle",
    "speaker.slash.circle.fill",
    "speaker.zzz",
    "speaker.zzz.fill",
    "speaker.wave.1",
    "speaker.wave.1.fill",
    "speaker.wave.2",
    "speaker.wave.2.fill",
    "speaker.wave.2.circle",
    "speaker.wave.2.circle.fill",
    "speaker.wave.3",
    "speaker.wave.3.fill",
    "speaker.badge.exclamationmark",
    "speaker.badge.exclamationmark.fill",
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
    "flag",
    "flag.fill",
    "flag.circle",
    "flag.circle.fill",
    "flag.square",
    "flag.square.fill",
    "flag.slash",
    "flag.slash.fill",
    "flag.slash.circle",
    "flag.slash.circle.fill",
    "flag.badge.ellipsis",
    "flag.badge.ellipsis.fill",
    "flag.2.crossed",
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
    "bell.slash.fill",
    "bell.slash.circle",
    "bell.slash.circle.fill",
    "bell.and.waveform",
    "bell.and.waveform.fill",
    "bell.badge",
    "bell.badge.fill",
    "bell.badge.circle",
    "bell.badge.circle.fill",
    "tag",
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
    "camera.circle",
    "camera.circle.fill",
    "camera.shutter.button",
    "camera.shutter.button.fill",
    "camera.badge.ellipsis",
    "camera.fill.badge.ellipsis",
    "arrow.triangle.2.circlepath.camera",
    "arrow.triangle.2.circlepath.camera.fill",
    "camera.on.rectangle",
    "camera.on.rectangle.fill",
    "gear",
    "gearshape",
    "gearshape.fill",
    "gearshape.2",
    "gearshape.2.fill",
    "scissors",
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
    "die.face.1.fill",
    "die.face.2.fill",
    "die.face.3.fill",
    "die.face.4.fill",
    "die.face.5.fill",
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
    "clock",
    "clock.fill",
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
    "lightbulb.slash",
    "lightbulb.slash.fill",
    "exclamationmark.shield",
    "exclamationmark.shield.fill",
    "xmark.shield",
    "xmark.shield.fill",
    "checkmark.shield",
    "checkmark.shield.fill",
    "die.face.6",
    "die.face.5",
    "die.face.4",
    "die.face.3",
    "die.face.2",
    "die.face.1",
    "umbrella.fill",
]
#endif

