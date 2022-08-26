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

/// Constants for known symbol names
public extension FairSymbol {
    static let square_and_arrow_up: FairSymbol = Self(rawValue: "square.and.arrow.up")
    static let square_and_arrow_up_fill: FairSymbol = Self(rawValue: "square.and.arrow.up.fill")
    static let square_and_arrow_up_circle: FairSymbol = Self(rawValue: "square.and.arrow.up.circle")
    static let square_and_arrow_up_circle_fill: FairSymbol = Self(rawValue: "square.and.arrow.up.circle.fill")
    static let square_and_arrow_up_trianglebadge_exclamationmark: FairSymbol = Self(rawValue: "square.and.arrow.up.trianglebadge.exclamationmark")
    static let square_and_arrow_down: FairSymbol = Self(rawValue: "square.and.arrow.down")
    static let square_and_arrow_down_fill: FairSymbol = Self(rawValue: "square.and.arrow.down.fill")
    static let square_and_arrow_up_on_square: FairSymbol = Self(rawValue: "square.and.arrow.up.on.square")
    static let square_and_arrow_up_on_square_fill: FairSymbol = Self(rawValue: "square.and.arrow.up.on.square.fill")
    static let square_and_arrow_down_on_square: FairSymbol = Self(rawValue: "square.and.arrow.down.on.square")
    static let square_and_arrow_down_on_square_fill: FairSymbol = Self(rawValue: "square.and.arrow.down.on.square.fill")
    static let rectangle_portrait_and_arrow_right: FairSymbol = Self(rawValue: "rectangle.portrait.and.arrow.right")
    static let rectangle_portrait_and_arrow_right_fill: FairSymbol = Self(rawValue: "rectangle.portrait.and.arrow.right.fill")
    static let pencil: FairSymbol = Self(rawValue: "pencil")
    static let pencil_circle: FairSymbol = Self(rawValue: "pencil.circle")
    static let pencil_circle_fill: FairSymbol = Self(rawValue: "pencil.circle.fill")
    static let pencil_slash: FairSymbol = Self(rawValue: "pencil.slash")
    static let square_and_pencil: FairSymbol = Self(rawValue: "square.and.pencil")
    static let rectangle_and_pencil_and_ellipsis: FairSymbol = Self(rawValue: "rectangle.and.pencil.and.ellipsis")
    static let scribble: FairSymbol = Self(rawValue: "scribble")
    static let scribble_variable: FairSymbol = Self(rawValue: "scribble.variable")
    static let highlighter: FairSymbol = Self(rawValue: "highlighter")
    static let pencil_and_outline: FairSymbol = Self(rawValue: "pencil.and.outline")
    static let lasso: FairSymbol = Self(rawValue: "lasso")
    static let lasso_and_sparkles: FairSymbol = Self(rawValue: "lasso.and.sparkles")
    static let trash: FairSymbol = Self(rawValue: "trash")
    static let trash_fill: FairSymbol = Self(rawValue: "trash.fill")
    static let trash_circle: FairSymbol = Self(rawValue: "trash.circle")
    static let trash_circle_fill: FairSymbol = Self(rawValue: "trash.circle.fill")
    static let trash_square: FairSymbol = Self(rawValue: "trash.square")
    static let trash_square_fill: FairSymbol = Self(rawValue: "trash.square.fill")
    static let trash_slash: FairSymbol = Self(rawValue: "trash.slash")
    static let trash_slash_fill: FairSymbol = Self(rawValue: "trash.slash.fill")
    static let trash_slash_circle: FairSymbol = Self(rawValue: "trash.slash.circle")
    static let trash_slash_circle_fill: FairSymbol = Self(rawValue: "trash.slash.circle.fill")
    static let trash_slash_square: FairSymbol = Self(rawValue: "trash.slash.square")
    static let trash_slash_square_fill: FairSymbol = Self(rawValue: "trash.slash.square.fill")
    static let folder: FairSymbol = Self(rawValue: "folder")
    static let folder_fill: FairSymbol = Self(rawValue: "folder.fill")
    static let folder_circle: FairSymbol = Self(rawValue: "folder.circle")
    static let folder_circle_fill: FairSymbol = Self(rawValue: "folder.circle.fill")
    static let folder_badge_plus: FairSymbol = Self(rawValue: "folder.badge.plus")
    static let folder_fill_badge_plus: FairSymbol = Self(rawValue: "folder.fill.badge.plus")
    static let folder_badge_minus: FairSymbol = Self(rawValue: "folder.badge.minus")
    static let folder_fill_badge_minus: FairSymbol = Self(rawValue: "folder.fill.badge.minus")
    static let folder_badge_questionmark: FairSymbol = Self(rawValue: "folder.badge.questionmark")
    static let folder_fill_badge_questionmark: FairSymbol = Self(rawValue: "folder.fill.badge.questionmark")
    static let folder_badge_person_crop: FairSymbol = Self(rawValue: "folder.badge.person.crop")
    static let folder_fill_badge_person_crop: FairSymbol = Self(rawValue: "folder.fill.badge.person.crop")
    static let square_grid_3x1_folder_badge_plus: FairSymbol = Self(rawValue: "square.grid.3x1.folder.badge.plus")
    static let square_grid_3x1_folder_fill_badge_plus: FairSymbol = Self(rawValue: "square.grid.3x1.folder.fill.badge.plus")
    static let folder_badge_gearshape: FairSymbol = Self(rawValue: "folder.badge.gearshape")
    static let folder_fill_badge_gearshape: FairSymbol = Self(rawValue: "folder.fill.badge.gearshape")
    static let plus_rectangle_on_folder: FairSymbol = Self(rawValue: "plus.rectangle.on.folder")
    static let plus_rectangle_on_folder_fill: FairSymbol = Self(rawValue: "plus.rectangle.on.folder.fill")
    static let questionmark_folder: FairSymbol = Self(rawValue: "questionmark.folder")
    static let questionmark_folder_fill: FairSymbol = Self(rawValue: "questionmark.folder.fill")
    static let paperplane: FairSymbol = Self(rawValue: "paperplane")
    static let paperplane_fill: FairSymbol = Self(rawValue: "paperplane.fill")
    static let paperplane_circle: FairSymbol = Self(rawValue: "paperplane.circle")
    static let paperplane_circle_fill: FairSymbol = Self(rawValue: "paperplane.circle.fill")
    static let tray: FairSymbol = Self(rawValue: "tray")
    static let tray_fill: FairSymbol = Self(rawValue: "tray.fill")
    static let tray_circle: FairSymbol = Self(rawValue: "tray.circle")
    static let tray_circle_fill: FairSymbol = Self(rawValue: "tray.circle.fill")
    static let tray_and_arrow_up: FairSymbol = Self(rawValue: "tray.and.arrow.up")
    static let tray_and_arrow_up_fill: FairSymbol = Self(rawValue: "tray.and.arrow.up.fill")
    static let tray_and_arrow_down: FairSymbol = Self(rawValue: "tray.and.arrow.down")
    static let tray_and_arrow_down_fill: FairSymbol = Self(rawValue: "tray.and.arrow.down.fill")
    static let tray_2: FairSymbol = Self(rawValue: "tray.2")
    static let tray_2_fill: FairSymbol = Self(rawValue: "tray.2.fill")
    static let tray_full: FairSymbol = Self(rawValue: "tray.full")
    static let tray_full_fill: FairSymbol = Self(rawValue: "tray.full.fill")
    static let externaldrive: FairSymbol = Self(rawValue: "externaldrive")
    static let externaldrive_fill: FairSymbol = Self(rawValue: "externaldrive.fill")
    static let externaldrive_badge_plus: FairSymbol = Self(rawValue: "externaldrive.badge.plus")
    static let externaldrive_fill_badge_plus: FairSymbol = Self(rawValue: "externaldrive.fill.badge.plus")
    static let externaldrive_badge_minus: FairSymbol = Self(rawValue: "externaldrive.badge.minus")
    static let externaldrive_fill_badge_minus: FairSymbol = Self(rawValue: "externaldrive.fill.badge.minus")
    static let externaldrive_badge_checkmark: FairSymbol = Self(rawValue: "externaldrive.badge.checkmark")
    static let externaldrive_fill_badge_checkmark: FairSymbol = Self(rawValue: "externaldrive.fill.badge.checkmark")
    static let externaldrive_badge_xmark: FairSymbol = Self(rawValue: "externaldrive.badge.xmark")
    static let externaldrive_fill_badge_xmark: FairSymbol = Self(rawValue: "externaldrive.fill.badge.xmark")
    static let externaldrive_badge_person_crop: FairSymbol = Self(rawValue: "externaldrive.badge.person.crop")
    static let externaldrive_fill_badge_person_crop: FairSymbol = Self(rawValue: "externaldrive.fill.badge.person.crop")
    static let externaldrive_badge_icloud: FairSymbol = Self(rawValue: "externaldrive.badge.icloud")
    static let externaldrive_fill_badge_icloud: FairSymbol = Self(rawValue: "externaldrive.fill.badge.icloud")
    static let externaldrive_badge_wifi: FairSymbol = Self(rawValue: "externaldrive.badge.wifi")
    static let externaldrive_fill_badge_wifi: FairSymbol = Self(rawValue: "externaldrive.fill.badge.wifi")
    static let externaldrive_badge_timemachine: FairSymbol = Self(rawValue: "externaldrive.badge.timemachine")
    static let externaldrive_fill_badge_timemachine: FairSymbol = Self(rawValue: "externaldrive.fill.badge.timemachine")
    static let internaldrive: FairSymbol = Self(rawValue: "internaldrive")
    static let internaldrive_fill: FairSymbol = Self(rawValue: "internaldrive.fill")
    static let opticaldiscdrive: FairSymbol = Self(rawValue: "opticaldiscdrive")
    static let opticaldiscdrive_fill: FairSymbol = Self(rawValue: "opticaldiscdrive.fill")
    static let externaldrive_connected_to_line_below: FairSymbol = Self(rawValue: "externaldrive.connected.to.line.below")
    static let externaldrive_connected_to_line_below_fill: FairSymbol = Self(rawValue: "externaldrive.connected.to.line.below.fill")
    static let archivebox: FairSymbol = Self(rawValue: "archivebox")
    static let archivebox_fill: FairSymbol = Self(rawValue: "archivebox.fill")
    static let archivebox_circle: FairSymbol = Self(rawValue: "archivebox.circle")
    static let archivebox_circle_fill: FairSymbol = Self(rawValue: "archivebox.circle.fill")
    static let xmark_bin: FairSymbol = Self(rawValue: "xmark.bin")
    static let xmark_bin_fill: FairSymbol = Self(rawValue: "xmark.bin.fill")
    static let xmark_bin_circle: FairSymbol = Self(rawValue: "xmark.bin.circle")
    static let xmark_bin_circle_fill: FairSymbol = Self(rawValue: "xmark.bin.circle.fill")
    static let arrow_up_bin: FairSymbol = Self(rawValue: "arrow.up.bin")
    static let arrow_up_bin_fill: FairSymbol = Self(rawValue: "arrow.up.bin.fill")
    static let doc: FairSymbol = Self(rawValue: "doc")
    static let doc_fill: FairSymbol = Self(rawValue: "doc.fill")
    static let doc_circle: FairSymbol = Self(rawValue: "doc.circle")
    static let doc_circle_fill: FairSymbol = Self(rawValue: "doc.circle.fill")
    static let doc_badge_plus: FairSymbol = Self(rawValue: "doc.badge.plus")
    static let doc_fill_badge_plus: FairSymbol = Self(rawValue: "doc.fill.badge.plus")
    static let doc_badge_gearshape: FairSymbol = Self(rawValue: "doc.badge.gearshape")
    static let doc_badge_gearshape_fill: FairSymbol = Self(rawValue: "doc.badge.gearshape.fill")
    static let doc_badge_ellipsis: FairSymbol = Self(rawValue: "doc.badge.ellipsis")
    static let doc_fill_badge_ellipsis: FairSymbol = Self(rawValue: "doc.fill.badge.ellipsis")
    static let lock_doc: FairSymbol = Self(rawValue: "lock.doc")
    static let lock_doc_fill: FairSymbol = Self(rawValue: "lock.doc.fill")
    static let arrow_up_doc: FairSymbol = Self(rawValue: "arrow.up.doc")
    static let arrow_up_doc_fill: FairSymbol = Self(rawValue: "arrow.up.doc.fill")
    static let arrow_down_doc: FairSymbol = Self(rawValue: "arrow.down.doc")
    static let arrow_down_doc_fill: FairSymbol = Self(rawValue: "arrow.down.doc.fill")
    static let doc_text: FairSymbol = Self(rawValue: "doc.text")
    static let doc_text_fill: FairSymbol = Self(rawValue: "doc.text.fill")
    static let doc_zipper: FairSymbol = Self(rawValue: "doc.zipper")
    static let doc_on_doc: FairSymbol = Self(rawValue: "doc.on.doc")
    static let doc_on_doc_fill: FairSymbol = Self(rawValue: "doc.on.doc.fill")
    static let doc_on_clipboard: FairSymbol = Self(rawValue: "doc.on.clipboard")
    static let arrow_right_doc_on_clipboard: FairSymbol = Self(rawValue: "arrow.right.doc.on.clipboard")
    static let arrow_up_doc_on_clipboard: FairSymbol = Self(rawValue: "arrow.up.doc.on.clipboard")
    static let arrow_triangle_2_circlepath_doc_on_clipboard: FairSymbol = Self(rawValue: "arrow.triangle.2.circlepath.doc.on.clipboard")
    static let doc_on_clipboard_fill: FairSymbol = Self(rawValue: "doc.on.clipboard.fill")
    static let doc_richtext: FairSymbol = Self(rawValue: "doc.richtext")
    static let doc_richtext_fill: FairSymbol = Self(rawValue: "doc.richtext.fill")
    static let doc_plaintext: FairSymbol = Self(rawValue: "doc.plaintext")
    static let doc_plaintext_fill: FairSymbol = Self(rawValue: "doc.plaintext.fill")
    static let doc_append: FairSymbol = Self(rawValue: "doc.append")
    static let doc_append_fill: FairSymbol = Self(rawValue: "doc.append.fill")
    static let doc_text_below_ecg: FairSymbol = Self(rawValue: "doc.text.below.ecg")
    static let doc_text_below_ecg_fill: FairSymbol = Self(rawValue: "doc.text.below.ecg.fill")
    static let chart_bar_doc_horizontal: FairSymbol = Self(rawValue: "chart.bar.doc.horizontal")
    static let chart_bar_doc_horizontal_fill: FairSymbol = Self(rawValue: "chart.bar.doc.horizontal.fill")
    static let list_bullet_rectangle_portrait: FairSymbol = Self(rawValue: "list.bullet.rectangle.portrait")
    static let list_bullet_rectangle_portrait_fill: FairSymbol = Self(rawValue: "list.bullet.rectangle.portrait.fill")
    static let doc_text_magnifyingglass: FairSymbol = Self(rawValue: "doc.text.magnifyingglass")
    static let list_bullet_rectangle: FairSymbol = Self(rawValue: "list.bullet.rectangle")
    static let list_bullet_rectangle_fill: FairSymbol = Self(rawValue: "list.bullet.rectangle.fill")
    static let list_dash_header_rectangle: FairSymbol = Self(rawValue: "list.dash.header.rectangle")
    static let terminal: FairSymbol = Self(rawValue: "terminal")
    static let terminal_fill: FairSymbol = Self(rawValue: "terminal.fill")
    static let note: FairSymbol = Self(rawValue: "note")
    static let note_text: FairSymbol = Self(rawValue: "note.text")
    static let note_text_badge_plus: FairSymbol = Self(rawValue: "note.text.badge.plus")
    static let calendar: FairSymbol = Self(rawValue: "calendar")
    static let calendar_circle: FairSymbol = Self(rawValue: "calendar.circle")
    static let calendar_circle_fill: FairSymbol = Self(rawValue: "calendar.circle.fill")
    static let calendar_badge_plus: FairSymbol = Self(rawValue: "calendar.badge.plus")
    static let calendar_badge_minus: FairSymbol = Self(rawValue: "calendar.badge.minus")
    static let calendar_badge_clock: FairSymbol = Self(rawValue: "calendar.badge.clock")
    static let calendar_badge_exclamationmark: FairSymbol = Self(rawValue: "calendar.badge.exclamationmark")
    static let calendar_day_timeline_left: FairSymbol = Self(rawValue: "calendar.day.timeline.left")
    static let calendar_day_timeline_right: FairSymbol = Self(rawValue: "calendar.day.timeline.right")
    static let calendar_day_timeline_leading: FairSymbol = Self(rawValue: "calendar.day.timeline.leading")
    static let calendar_day_timeline_trailing: FairSymbol = Self(rawValue: "calendar.day.timeline.trailing")
    static let arrowshape_turn_up_left: FairSymbol = Self(rawValue: "arrowshape.turn.up.left")
    static let arrowshape_turn_up_left_fill: FairSymbol = Self(rawValue: "arrowshape.turn.up.left.fill")
    static let arrowshape_turn_up_left_circle: FairSymbol = Self(rawValue: "arrowshape.turn.up.left.circle")
    static let arrowshape_turn_up_left_circle_fill: FairSymbol = Self(rawValue: "arrowshape.turn.up.left.circle.fill")
    static let arrowshape_turn_up_backward: FairSymbol = Self(rawValue: "arrowshape.turn.up.backward")
    static let arrowshape_turn_up_backward_fill: FairSymbol = Self(rawValue: "arrowshape.turn.up.backward.fill")
    static let arrowshape_turn_up_backward_circle: FairSymbol = Self(rawValue: "arrowshape.turn.up.backward.circle")
    static let arrowshape_turn_up_backward_circle_fill: FairSymbol = Self(rawValue: "arrowshape.turn.up.backward.circle.fill")
    static let arrowshape_turn_up_right: FairSymbol = Self(rawValue: "arrowshape.turn.up.right")
    static let arrowshape_turn_up_right_fill: FairSymbol = Self(rawValue: "arrowshape.turn.up.right.fill")
    static let arrowshape_turn_up_right_circle: FairSymbol = Self(rawValue: "arrowshape.turn.up.right.circle")
    static let arrowshape_turn_up_right_circle_fill: FairSymbol = Self(rawValue: "arrowshape.turn.up.right.circle.fill")
    static let arrowshape_turn_up_forward: FairSymbol = Self(rawValue: "arrowshape.turn.up.forward")
    static let arrowshape_turn_up_forward_fill: FairSymbol = Self(rawValue: "arrowshape.turn.up.forward.fill")
    static let arrowshape_turn_up_forward_circle: FairSymbol = Self(rawValue: "arrowshape.turn.up.forward.circle")
    static let arrowshape_turn_up_forward_circle_fill: FairSymbol = Self(rawValue: "arrowshape.turn.up.forward.circle.fill")
    static let arrowshape_turn_up_left_2: FairSymbol = Self(rawValue: "arrowshape.turn.up.left.2")
    static let arrowshape_turn_up_left_2_fill: FairSymbol = Self(rawValue: "arrowshape.turn.up.left.2.fill")
    static let arrowshape_turn_up_left_2_circle: FairSymbol = Self(rawValue: "arrowshape.turn.up.left.2.circle")
    static let arrowshape_turn_up_left_2_circle_fill: FairSymbol = Self(rawValue: "arrowshape.turn.up.left.2.circle.fill")
    static let arrowshape_turn_up_backward_2: FairSymbol = Self(rawValue: "arrowshape.turn.up.backward.2")
    static let arrowshape_turn_up_backward_2_fill: FairSymbol = Self(rawValue: "arrowshape.turn.up.backward.2.fill")
    static let arrowshape_turn_up_backward_2_circle: FairSymbol = Self(rawValue: "arrowshape.turn.up.backward.2.circle")
    static let arrowshape_turn_up_backward_2_circle_fill: FairSymbol = Self(rawValue: "arrowshape.turn.up.backward.2.circle.fill")
    static let arrowshape_zigzag_right: FairSymbol = Self(rawValue: "arrowshape.zigzag.right")
    static let arrowshape_zigzag_right_fill: FairSymbol = Self(rawValue: "arrowshape.zigzag.right.fill")
    static let arrowshape_zigzag_forward: FairSymbol = Self(rawValue: "arrowshape.zigzag.forward")
    static let arrowshape_zigzag_forward_fill: FairSymbol = Self(rawValue: "arrowshape.zigzag.forward.fill")
    static let arrowshape_bounce_right: FairSymbol = Self(rawValue: "arrowshape.bounce.right")
    static let arrowshape_bounce_right_fill: FairSymbol = Self(rawValue: "arrowshape.bounce.right.fill")
    static let arrowshape_bounce_forward: FairSymbol = Self(rawValue: "arrowshape.bounce.forward")
    static let arrowshape_bounce_forward_fill: FairSymbol = Self(rawValue: "arrowshape.bounce.forward.fill")
    static let book: FairSymbol = Self(rawValue: "book")
    static let book_fill: FairSymbol = Self(rawValue: "book.fill")
    static let book_circle: FairSymbol = Self(rawValue: "book.circle")
    static let book_circle_fill: FairSymbol = Self(rawValue: "book.circle.fill")
    static let books_vertical: FairSymbol = Self(rawValue: "books.vertical")
    static let books_vertical_fill: FairSymbol = Self(rawValue: "books.vertical.fill")
    static let books_vertical_circle: FairSymbol = Self(rawValue: "books.vertical.circle")
    static let books_vertical_circle_fill: FairSymbol = Self(rawValue: "books.vertical.circle.fill")
    static let book_closed: FairSymbol = Self(rawValue: "book.closed")
    static let book_closed_fill: FairSymbol = Self(rawValue: "book.closed.fill")
    static let book_closed_circle: FairSymbol = Self(rawValue: "book.closed.circle")
    static let book_closed_circle_fill: FairSymbol = Self(rawValue: "book.closed.circle.fill")
    static let character_book_closed: FairSymbol = Self(rawValue: "character.book.closed")
    static let character_book_closed_fill: FairSymbol = Self(rawValue: "character.book.closed.fill")
    static let text_book_closed: FairSymbol = Self(rawValue: "text.book.closed")
    static let text_book_closed_fill: FairSymbol = Self(rawValue: "text.book.closed.fill")
    static let menucard: FairSymbol = Self(rawValue: "menucard")
    static let menucard_fill: FairSymbol = Self(rawValue: "menucard.fill")
    static let greetingcard: FairSymbol = Self(rawValue: "greetingcard")
    static let greetingcard_fill: FairSymbol = Self(rawValue: "greetingcard.fill")
    static let magazine: FairSymbol = Self(rawValue: "magazine")
    static let magazine_fill: FairSymbol = Self(rawValue: "magazine.fill")
    static let newspaper: FairSymbol = Self(rawValue: "newspaper")
    static let newspaper_fill: FairSymbol = Self(rawValue: "newspaper.fill")
    static let newspaper_circle: FairSymbol = Self(rawValue: "newspaper.circle")
    static let newspaper_circle_fill: FairSymbol = Self(rawValue: "newspaper.circle.fill")
    static let heart_text_square: FairSymbol = Self(rawValue: "heart.text.square")
    static let heart_text_square_fill: FairSymbol = Self(rawValue: "heart.text.square.fill")
    static let square_text_square: FairSymbol = Self(rawValue: "square.text.square")
    static let square_text_square_fill: FairSymbol = Self(rawValue: "square.text.square.fill")
    static let doc_text_image: FairSymbol = Self(rawValue: "doc.text.image")
    static let doc_text_image_fill: FairSymbol = Self(rawValue: "doc.text.image.fill")
    static let bookmark: FairSymbol = Self(rawValue: "bookmark")
    static let bookmark_fill: FairSymbol = Self(rawValue: "bookmark.fill")
    static let bookmark_circle: FairSymbol = Self(rawValue: "bookmark.circle")
    static let bookmark_circle_fill: FairSymbol = Self(rawValue: "bookmark.circle.fill")
    static let bookmark_square: FairSymbol = Self(rawValue: "bookmark.square")
    static let bookmark_square_fill: FairSymbol = Self(rawValue: "bookmark.square.fill")
    static let bookmark_slash: FairSymbol = Self(rawValue: "bookmark.slash")
    static let bookmark_slash_fill: FairSymbol = Self(rawValue: "bookmark.slash.fill")
    static let rosette: FairSymbol = Self(rawValue: "rosette")
    static let graduationcap: FairSymbol = Self(rawValue: "graduationcap")
    static let graduationcap_fill: FairSymbol = Self(rawValue: "graduationcap.fill")
    static let graduationcap_circle: FairSymbol = Self(rawValue: "graduationcap.circle")
    static let graduationcap_circle_fill: FairSymbol = Self(rawValue: "graduationcap.circle.fill")
    static let ticket: FairSymbol = Self(rawValue: "ticket")
    static let ticket_fill: FairSymbol = Self(rawValue: "ticket.fill")
    static let paperclip: FairSymbol = Self(rawValue: "paperclip")
    static let paperclip_circle: FairSymbol = Self(rawValue: "paperclip.circle")
    static let paperclip_circle_fill: FairSymbol = Self(rawValue: "paperclip.circle.fill")
    static let paperclip_badge_ellipsis: FairSymbol = Self(rawValue: "paperclip.badge.ellipsis")
    static let rectangle_and_paperclip: FairSymbol = Self(rawValue: "rectangle.and.paperclip")
    static let rectangle_dashed_and_paperclip: FairSymbol = Self(rawValue: "rectangle.dashed.and.paperclip")
    static let link: FairSymbol = Self(rawValue: "link")
    static let link_circle: FairSymbol = Self(rawValue: "link.circle")
    static let link_circle_fill: FairSymbol = Self(rawValue: "link.circle.fill")
    static let link_badge_plus: FairSymbol = Self(rawValue: "link.badge.plus")
    static let personalhotspot: FairSymbol = Self(rawValue: "personalhotspot")
    static let personalhotspot_circle: FairSymbol = Self(rawValue: "personalhotspot.circle")
    static let personalhotspot_circle_fill: FairSymbol = Self(rawValue: "personalhotspot.circle.fill")
    static let lineweight: FairSymbol = Self(rawValue: "lineweight")
    static let person: FairSymbol = Self(rawValue: "person")
    static let person_fill: FairSymbol = Self(rawValue: "person.fill")
    static let person_fill_turn_right: FairSymbol = Self(rawValue: "person.fill.turn.right")
    static let person_fill_turn_down: FairSymbol = Self(rawValue: "person.fill.turn.down")
    static let person_fill_turn_left: FairSymbol = Self(rawValue: "person.fill.turn.left")
    static let person_fill_checkmark: FairSymbol = Self(rawValue: "person.fill.checkmark")
    static let person_fill_xmark: FairSymbol = Self(rawValue: "person.fill.xmark")
    static let person_fill_questionmark: FairSymbol = Self(rawValue: "person.fill.questionmark")
    static let person_circle: FairSymbol = Self(rawValue: "person.circle")
    static let person_circle_fill: FairSymbol = Self(rawValue: "person.circle.fill")
    static let person_badge_plus: FairSymbol = Self(rawValue: "person.badge.plus")
    static let person_fill_badge_plus: FairSymbol = Self(rawValue: "person.fill.badge.plus")
    static let person_badge_minus: FairSymbol = Self(rawValue: "person.badge.minus")
    static let person_fill_badge_minus: FairSymbol = Self(rawValue: "person.fill.badge.minus")
    static let person_badge_clock: FairSymbol = Self(rawValue: "person.badge.clock")
    static let person_badge_clock_fill: FairSymbol = Self(rawValue: "person.badge.clock.fill")
    static let rectangle_inset_filled_and_person_filled: FairSymbol = Self(rawValue: "rectangle.inset.filled.and.person.filled")
    static let person_and_arrow_left_and_arrow_right: FairSymbol = Self(rawValue: "person.and.arrow.left.and.arrow.right")
    static let person_fill_and_arrow_left_and_arrow_right: FairSymbol = Self(rawValue: "person.fill.and.arrow.left.and.arrow.right")
    static let person_2: FairSymbol = Self(rawValue: "person.2")
    static let person_2_fill: FairSymbol = Self(rawValue: "person.2.fill")
    static let person_2_circle: FairSymbol = Self(rawValue: "person.2.circle")
    static let person_2_circle_fill: FairSymbol = Self(rawValue: "person.2.circle.fill")
    static let person_wave_2: FairSymbol = Self(rawValue: "person.wave.2")
    static let person_wave_2_fill: FairSymbol = Self(rawValue: "person.wave.2.fill")
    static let person_2_wave_2: FairSymbol = Self(rawValue: "person.2.wave.2")
    static let person_2_wave_2_fill: FairSymbol = Self(rawValue: "person.2.wave.2.fill")
    static let person_3: FairSymbol = Self(rawValue: "person.3")
    static let person_3_fill: FairSymbol = Self(rawValue: "person.3.fill")
    static let person_3_sequence: FairSymbol = Self(rawValue: "person.3.sequence")
    static let person_3_sequence_fill: FairSymbol = Self(rawValue: "person.3.sequence.fill")
    static let lanyardcard: FairSymbol = Self(rawValue: "lanyardcard")
    static let lanyardcard_fill: FairSymbol = Self(rawValue: "lanyardcard.fill")
    static let person_crop_circle: FairSymbol = Self(rawValue: "person.crop.circle")
    static let person_crop_circle_fill: FairSymbol = Self(rawValue: "person.crop.circle.fill")
    static let person_crop_circle_badge_plus: FairSymbol = Self(rawValue: "person.crop.circle.badge.plus")
    static let person_crop_circle_fill_badge_plus: FairSymbol = Self(rawValue: "person.crop.circle.fill.badge.plus")
    static let person_crop_circle_badge_minus: FairSymbol = Self(rawValue: "person.crop.circle.badge.minus")
    static let person_crop_circle_fill_badge_minus: FairSymbol = Self(rawValue: "person.crop.circle.fill.badge.minus")
    static let person_crop_circle_badge_checkmark: FairSymbol = Self(rawValue: "person.crop.circle.badge.checkmark")
    static let person_crop_circle_fill_badge_checkmark: FairSymbol = Self(rawValue: "person.crop.circle.fill.badge.checkmark")
    static let person_crop_circle_badge_xmark: FairSymbol = Self(rawValue: "person.crop.circle.badge.xmark")
    static let person_crop_circle_fill_badge_xmark: FairSymbol = Self(rawValue: "person.crop.circle.fill.badge.xmark")
    static let person_crop_circle_badge_questionmark: FairSymbol = Self(rawValue: "person.crop.circle.badge.questionmark")
    static let person_crop_circle_badge_questionmark_fill: FairSymbol = Self(rawValue: "person.crop.circle.badge.questionmark.fill")
    static let person_crop_circle_badge_exclamationmark: FairSymbol = Self(rawValue: "person.crop.circle.badge.exclamationmark")
    static let person_crop_circle_badge_exclamationmark_fill: FairSymbol = Self(rawValue: "person.crop.circle.badge.exclamationmark.fill")
    static let person_crop_circle_badge_moon: FairSymbol = Self(rawValue: "person.crop.circle.badge.moon")
    static let person_crop_circle_badge_moon_fill: FairSymbol = Self(rawValue: "person.crop.circle.badge.moon.fill")
    static let person_crop_circle_badge_clock: FairSymbol = Self(rawValue: "person.crop.circle.badge.clock")
    static let person_crop_circle_badge_clock_fill: FairSymbol = Self(rawValue: "person.crop.circle.badge.clock.fill")
    static let person_crop_circle_badge: FairSymbol = Self(rawValue: "person.crop.circle.badge")
    static let person_crop_circle_badge_fill: FairSymbol = Self(rawValue: "person.crop.circle.badge.fill")
    static let person_crop_square: FairSymbol = Self(rawValue: "person.crop.square")
    static let person_crop_square_fill: FairSymbol = Self(rawValue: "person.crop.square.fill")
    static let person_crop_artframe: FairSymbol = Self(rawValue: "person.crop.artframe")
    static let photo_artframe: FairSymbol = Self(rawValue: "photo.artframe")
    static let person_crop_rectangle_stack: FairSymbol = Self(rawValue: "person.crop.rectangle.stack")
    static let person_crop_rectangle_stack_fill: FairSymbol = Self(rawValue: "person.crop.rectangle.stack.fill")
    static let person_2_crop_square_stack: FairSymbol = Self(rawValue: "person.2.crop.square.stack")
    static let person_2_crop_square_stack_fill: FairSymbol = Self(rawValue: "person.2.crop.square.stack.fill")
    static let person_crop_rectangle: FairSymbol = Self(rawValue: "person.crop.rectangle")
    static let person_crop_rectangle_fill: FairSymbol = Self(rawValue: "person.crop.rectangle.fill")
    static let arrow_up_and_person_rectangle_portrait: FairSymbol = Self(rawValue: "arrow.up.and.person.rectangle.portrait")
    static let arrow_up_and_person_rectangle_turn_right: FairSymbol = Self(rawValue: "arrow.up.and.person.rectangle.turn.right")
    static let arrow_up_and_person_rectangle_turn_left: FairSymbol = Self(rawValue: "arrow.up.and.person.rectangle.turn.left")
    static let person_crop_square_filled_and_at_rectangle: FairSymbol = Self(rawValue: "person.crop.square.filled.and.at.rectangle")
    static let person_crop_square_filled_and_at_rectangle_fill: FairSymbol = Self(rawValue: "person.crop.square.filled.and.at.rectangle.fill")
    static let square_and_at_rectangle: FairSymbol = Self(rawValue: "square.and.at.rectangle")
    static let square_and_at_rectangle_fill: FairSymbol = Self(rawValue: "square.and.at.rectangle.fill")
    static let person_text_rectangle: FairSymbol = Self(rawValue: "person.text.rectangle")
    static let person_text_rectangle_fill: FairSymbol = Self(rawValue: "person.text.rectangle.fill")
    static let command: FairSymbol = Self(rawValue: "command")
    static let command_circle: FairSymbol = Self(rawValue: "command.circle")
    static let command_circle_fill: FairSymbol = Self(rawValue: "command.circle.fill")
    static let command_square: FairSymbol = Self(rawValue: "command.square")
    static let command_square_fill: FairSymbol = Self(rawValue: "command.square.fill")
    static let option: FairSymbol = Self(rawValue: "option")
    static let alt: FairSymbol = Self(rawValue: "alt")
    static let clear: FairSymbol = Self(rawValue: "clear")
    static let clear_fill: FairSymbol = Self(rawValue: "clear.fill")
    static let delete_left: FairSymbol = Self(rawValue: "delete.left")
    static let delete_left_fill: FairSymbol = Self(rawValue: "delete.left.fill")
    static let delete_backward: FairSymbol = Self(rawValue: "delete.backward")
    static let delete_backward_fill: FairSymbol = Self(rawValue: "delete.backward.fill")
    static let delete_right: FairSymbol = Self(rawValue: "delete.right")
    static let delete_right_fill: FairSymbol = Self(rawValue: "delete.right.fill")
    static let delete_forward: FairSymbol = Self(rawValue: "delete.forward")
    static let delete_forward_fill: FairSymbol = Self(rawValue: "delete.forward.fill")
    static let shift: FairSymbol = Self(rawValue: "shift")
    static let shift_fill: FairSymbol = Self(rawValue: "shift.fill")
    static let capslock: FairSymbol = Self(rawValue: "capslock")
    static let capslock_fill: FairSymbol = Self(rawValue: "capslock.fill")
    static let escape: FairSymbol = Self(rawValue: "escape")
    static let restart: FairSymbol = Self(rawValue: "restart")
    static let restart_circle: FairSymbol = Self(rawValue: "restart.circle")
    static let restart_circle_fill: FairSymbol = Self(rawValue: "restart.circle.fill")
    static let sleep: FairSymbol = Self(rawValue: "sleep")
    static let sleep_circle: FairSymbol = Self(rawValue: "sleep.circle")
    static let sleep_circle_fill: FairSymbol = Self(rawValue: "sleep.circle.fill")
    static let wake: FairSymbol = Self(rawValue: "wake")
    static let wake_circle: FairSymbol = Self(rawValue: "wake.circle")
    static let wake_circle_fill: FairSymbol = Self(rawValue: "wake.circle.fill")
    static let power: FairSymbol = Self(rawValue: "power")
    static let power_circle: FairSymbol = Self(rawValue: "power.circle")
    static let power_circle_fill: FairSymbol = Self(rawValue: "power.circle.fill")
    static let power_dotted: FairSymbol = Self(rawValue: "power.dotted")
    static let togglepower: FairSymbol = Self(rawValue: "togglepower")
    static let poweron: FairSymbol = Self(rawValue: "poweron")
    static let poweroff: FairSymbol = Self(rawValue: "poweroff")
    static let powersleep: FairSymbol = Self(rawValue: "powersleep")
    static let directcurrent: FairSymbol = Self(rawValue: "directcurrent")
    static let alternatingcurrent: FairSymbol = Self(rawValue: "alternatingcurrent")
    static let peacesign: FairSymbol = Self(rawValue: "peacesign")
    static let dot_arrowtriangles_up_right_down_left_circle: FairSymbol = Self(rawValue: "dot.arrowtriangles.up.right.down.left.circle")
    static let globe: FairSymbol = Self(rawValue: "globe")
    static let globe_badge_chevron_backward: FairSymbol = Self(rawValue: "globe.badge.chevron.backward")
    static let network: FairSymbol = Self(rawValue: "network")
    static let network_badge_shield_half_filled: FairSymbol = Self(rawValue: "network.badge.shield.half.filled")
    static let globe_americas: FairSymbol = Self(rawValue: "globe.americas")
    static let globe_americas_fill: FairSymbol = Self(rawValue: "globe.americas.fill")
    static let globe_europe_africa: FairSymbol = Self(rawValue: "globe.europe.africa")
    static let globe_europe_africa_fill: FairSymbol = Self(rawValue: "globe.europe.africa.fill")
    static let globe_asia_australia: FairSymbol = Self(rawValue: "globe.asia.australia")
    static let globe_asia_australia_fill: FairSymbol = Self(rawValue: "globe.asia.australia.fill")
    static let sun_min: FairSymbol = Self(rawValue: "sun.min")
    static let sun_min_fill: FairSymbol = Self(rawValue: "sun.min.fill")
    static let sun_max: FairSymbol = Self(rawValue: "sun.max")
    static let sun_max_fill: FairSymbol = Self(rawValue: "sun.max.fill")
    static let sun_max_circle: FairSymbol = Self(rawValue: "sun.max.circle")
    static let sun_max_circle_fill: FairSymbol = Self(rawValue: "sun.max.circle.fill")
    static let sunrise: FairSymbol = Self(rawValue: "sunrise")
    static let sunrise_fill: FairSymbol = Self(rawValue: "sunrise.fill")
    static let sunset: FairSymbol = Self(rawValue: "sunset")
    static let sunset_fill: FairSymbol = Self(rawValue: "sunset.fill")
    static let sun_and_horizon: FairSymbol = Self(rawValue: "sun.and.horizon")
    static let sun_and_horizon_fill: FairSymbol = Self(rawValue: "sun.and.horizon.fill")
    static let sun_dust: FairSymbol = Self(rawValue: "sun.dust")
    static let sun_dust_fill: FairSymbol = Self(rawValue: "sun.dust.fill")
    static let sun_haze: FairSymbol = Self(rawValue: "sun.haze")
    static let sun_haze_fill: FairSymbol = Self(rawValue: "sun.haze.fill")
    static let moon: FairSymbol = Self(rawValue: "moon")
    static let moon_fill: FairSymbol = Self(rawValue: "moon.fill")
    static let moon_circle: FairSymbol = Self(rawValue: "moon.circle")
    static let moon_circle_fill: FairSymbol = Self(rawValue: "moon.circle.fill")
    static let zzz: FairSymbol = Self(rawValue: "zzz")
    static let moon_zzz: FairSymbol = Self(rawValue: "moon.zzz")
    static let moon_zzz_fill: FairSymbol = Self(rawValue: "moon.zzz.fill")
    static let sparkle: FairSymbol = Self(rawValue: "sparkle")
    static let sparkles: FairSymbol = Self(rawValue: "sparkles")
    static let moon_stars: FairSymbol = Self(rawValue: "moon.stars")
    static let moon_stars_fill: FairSymbol = Self(rawValue: "moon.stars.fill")
    static let cloud: FairSymbol = Self(rawValue: "cloud")
    static let cloud_fill: FairSymbol = Self(rawValue: "cloud.fill")
    static let cloud_drizzle: FairSymbol = Self(rawValue: "cloud.drizzle")
    static let cloud_drizzle_fill: FairSymbol = Self(rawValue: "cloud.drizzle.fill")
    static let cloud_rain: FairSymbol = Self(rawValue: "cloud.rain")
    static let cloud_rain_fill: FairSymbol = Self(rawValue: "cloud.rain.fill")
    static let cloud_heavyrain: FairSymbol = Self(rawValue: "cloud.heavyrain")
    static let cloud_heavyrain_fill: FairSymbol = Self(rawValue: "cloud.heavyrain.fill")
    static let cloud_fog: FairSymbol = Self(rawValue: "cloud.fog")
    static let cloud_fog_fill: FairSymbol = Self(rawValue: "cloud.fog.fill")
    static let cloud_hail: FairSymbol = Self(rawValue: "cloud.hail")
    static let cloud_hail_fill: FairSymbol = Self(rawValue: "cloud.hail.fill")
    static let cloud_snow: FairSymbol = Self(rawValue: "cloud.snow")
    static let cloud_snow_fill: FairSymbol = Self(rawValue: "cloud.snow.fill")
    static let cloud_sleet: FairSymbol = Self(rawValue: "cloud.sleet")
    static let cloud_sleet_fill: FairSymbol = Self(rawValue: "cloud.sleet.fill")
    static let cloud_bolt: FairSymbol = Self(rawValue: "cloud.bolt")
    static let cloud_bolt_fill: FairSymbol = Self(rawValue: "cloud.bolt.fill")
    static let cloud_bolt_rain: FairSymbol = Self(rawValue: "cloud.bolt.rain")
    static let cloud_bolt_rain_fill: FairSymbol = Self(rawValue: "cloud.bolt.rain.fill")
    static let cloud_sun: FairSymbol = Self(rawValue: "cloud.sun")
    static let cloud_sun_fill: FairSymbol = Self(rawValue: "cloud.sun.fill")
    static let cloud_sun_rain: FairSymbol = Self(rawValue: "cloud.sun.rain")
    static let cloud_sun_rain_fill: FairSymbol = Self(rawValue: "cloud.sun.rain.fill")
    static let cloud_sun_bolt: FairSymbol = Self(rawValue: "cloud.sun.bolt")
    static let cloud_sun_bolt_fill: FairSymbol = Self(rawValue: "cloud.sun.bolt.fill")
    static let cloud_moon: FairSymbol = Self(rawValue: "cloud.moon")
    static let cloud_moon_fill: FairSymbol = Self(rawValue: "cloud.moon.fill")
    static let cloud_moon_rain: FairSymbol = Self(rawValue: "cloud.moon.rain")
    static let cloud_moon_rain_fill: FairSymbol = Self(rawValue: "cloud.moon.rain.fill")
    static let cloud_moon_bolt: FairSymbol = Self(rawValue: "cloud.moon.bolt")
    static let cloud_moon_bolt_fill: FairSymbol = Self(rawValue: "cloud.moon.bolt.fill")
    static let smoke: FairSymbol = Self(rawValue: "smoke")
    static let smoke_fill: FairSymbol = Self(rawValue: "smoke.fill")
    static let wind: FairSymbol = Self(rawValue: "wind")
    static let wind_snow: FairSymbol = Self(rawValue: "wind.snow")
    static let snowflake: FairSymbol = Self(rawValue: "snowflake")
    static let snowflake_circle: FairSymbol = Self(rawValue: "snowflake.circle")
    static let snowflake_circle_fill: FairSymbol = Self(rawValue: "snowflake.circle.fill")
    static let tornado: FairSymbol = Self(rawValue: "tornado")
    static let tropicalstorm: FairSymbol = Self(rawValue: "tropicalstorm")
    static let hurricane: FairSymbol = Self(rawValue: "hurricane")
    static let thermometer_sun: FairSymbol = Self(rawValue: "thermometer.sun")
    static let thermometer_sun_fill: FairSymbol = Self(rawValue: "thermometer.sun.fill")
    static let thermometer_snowflake: FairSymbol = Self(rawValue: "thermometer.snowflake")
    static let thermometer: FairSymbol = Self(rawValue: "thermometer")
    static let aqi_low: FairSymbol = Self(rawValue: "aqi.low")
    static let aqi_medium: FairSymbol = Self(rawValue: "aqi.medium")
    static let aqi_high: FairSymbol = Self(rawValue: "aqi.high")
    static let humidity: FairSymbol = Self(rawValue: "humidity")
    static let humidity_fill: FairSymbol = Self(rawValue: "humidity.fill")
    static let umbrella: FairSymbol = Self(rawValue: "umbrella")
    static let umbrella_fill: FairSymbol = Self(rawValue: "umbrella.fill")
    static let flame: FairSymbol = Self(rawValue: "flame")
    static let flame_fill: FairSymbol = Self(rawValue: "flame.fill")
    static let flame_circle: FairSymbol = Self(rawValue: "flame.circle")
    static let flame_circle_fill: FairSymbol = Self(rawValue: "flame.circle.fill")
    static let light_min: FairSymbol = Self(rawValue: "light.min")
    static let light_max: FairSymbol = Self(rawValue: "light.max")
    static let rays: FairSymbol = Self(rawValue: "rays")
    static let slowmo: FairSymbol = Self(rawValue: "slowmo")
    static let timelapse: FairSymbol = Self(rawValue: "timelapse")
    static let cursorarrow_rays: FairSymbol = Self(rawValue: "cursorarrow.rays")
    static let cursorarrow: FairSymbol = Self(rawValue: "cursorarrow")
    static let cursorarrow_square: FairSymbol = Self(rawValue: "cursorarrow.square")
    static let cursorarrow_and_square_on_square_dashed: FairSymbol = Self(rawValue: "cursorarrow.and.square.on.square.dashed")
    static let cursorarrow_click: FairSymbol = Self(rawValue: "cursorarrow.click")
    static let cursorarrow_click_2: FairSymbol = Self(rawValue: "cursorarrow.click.2")
    static let contextualmenu_and_cursorarrow: FairSymbol = Self(rawValue: "contextualmenu.and.cursorarrow")
    static let filemenu_and_cursorarrow: FairSymbol = Self(rawValue: "filemenu.and.cursorarrow")
    static let filemenu_and_selection: FairSymbol = Self(rawValue: "filemenu.and.selection")
    static let dot_circle_and_hand_point_up_left_fill: FairSymbol = Self(rawValue: "dot.circle.and.hand.point.up.left.fill")
    static let dot_circle_and_cursorarrow: FairSymbol = Self(rawValue: "dot.circle.and.cursorarrow")
    static let cursorarrow_motionlines: FairSymbol = Self(rawValue: "cursorarrow.motionlines")
    static let cursorarrow_motionlines_click: FairSymbol = Self(rawValue: "cursorarrow.motionlines.click")
    static let cursorarrow_click_badge_clock: FairSymbol = Self(rawValue: "cursorarrow.click.badge.clock")
    static let keyboard: FairSymbol = Self(rawValue: "keyboard")
    static let keyboard_fill: FairSymbol = Self(rawValue: "keyboard.fill")
    static let keyboard_badge_ellipsis: FairSymbol = Self(rawValue: "keyboard.badge.ellipsis")
    static let keyboard_chevron_compact_down: FairSymbol = Self(rawValue: "keyboard.chevron.compact.down")
    static let keyboard_chevron_compact_left: FairSymbol = Self(rawValue: "keyboard.chevron.compact.left")
    static let keyboard_onehanded_left: FairSymbol = Self(rawValue: "keyboard.onehanded.left")
    static let keyboard_onehanded_right: FairSymbol = Self(rawValue: "keyboard.onehanded.right")
    static let rectangle_3_group: FairSymbol = Self(rawValue: "rectangle.3.group")
    static let rectangle_3_group_fill: FairSymbol = Self(rawValue: "rectangle.3.group.fill")
    static let square_grid_3x2: FairSymbol = Self(rawValue: "square.grid.3x2")
    static let square_grid_3x2_fill: FairSymbol = Self(rawValue: "square.grid.3x2.fill")
    static let rectangle_grid_3x2: FairSymbol = Self(rawValue: "rectangle.grid.3x2")
    static let rectangle_grid_3x2_fill: FairSymbol = Self(rawValue: "rectangle.grid.3x2.fill")
    static let square_grid_2x2: FairSymbol = Self(rawValue: "square.grid.2x2")
    static let square_grid_2x2_fill: FairSymbol = Self(rawValue: "square.grid.2x2.fill")
    static let rectangle_grid_2x2: FairSymbol = Self(rawValue: "rectangle.grid.2x2")
    static let rectangle_grid_2x2_fill: FairSymbol = Self(rawValue: "rectangle.grid.2x2.fill")
    static let square_grid_3x1_below_line_grid_1x2: FairSymbol = Self(rawValue: "square.grid.3x1.below.line.grid.1x2")
    static let square_grid_3x1_below_line_grid_1x2_fill: FairSymbol = Self(rawValue: "square.grid.3x1.below.line.grid.1x2.fill")
    static let square_grid_4x3_fill: FairSymbol = Self(rawValue: "square.grid.4x3.fill")
    static let rectangle_grid_1x2: FairSymbol = Self(rawValue: "rectangle.grid.1x2")
    static let rectangle_grid_1x2_fill: FairSymbol = Self(rawValue: "rectangle.grid.1x2.fill")
    static let circle_grid_2x2: FairSymbol = Self(rawValue: "circle.grid.2x2")
    static let circle_grid_2x2_fill: FairSymbol = Self(rawValue: "circle.grid.2x2.fill")
    static let circle_grid_3x3: FairSymbol = Self(rawValue: "circle.grid.3x3")
    static let circle_grid_3x3_fill: FairSymbol = Self(rawValue: "circle.grid.3x3.fill")
    static let circle_grid_3x3_circle: FairSymbol = Self(rawValue: "circle.grid.3x3.circle")
    static let circle_grid_3x3_circle_fill: FairSymbol = Self(rawValue: "circle.grid.3x3.circle.fill")
    static let square_grid_3x3: FairSymbol = Self(rawValue: "square.grid.3x3")
    static let square_grid_3x3_fill: FairSymbol = Self(rawValue: "square.grid.3x3.fill")
    static let square_grid_3x3_topleft_filled: FairSymbol = Self(rawValue: "square.grid.3x3.topleft.filled")
    static let square_grid_3x3_topmiddle_filled: FairSymbol = Self(rawValue: "square.grid.3x3.topmiddle.filled")
    static let square_grid_3x3_topright_filled: FairSymbol = Self(rawValue: "square.grid.3x3.topright.filled")
    static let square_grid_3x3_middleleft_filled: FairSymbol = Self(rawValue: "square.grid.3x3.middleleft.filled")
    static let square_grid_3x3_middle_filled: FairSymbol = Self(rawValue: "square.grid.3x3.middle.filled")
    static let square_grid_3x3_middleright_filled: FairSymbol = Self(rawValue: "square.grid.3x3.middleright.filled")
    static let square_grid_3x3_bottomleft_filled: FairSymbol = Self(rawValue: "square.grid.3x3.bottomleft.filled")
    static let square_grid_3x3_bottommiddle_filled: FairSymbol = Self(rawValue: "square.grid.3x3.bottommiddle.filled")
    static let square_grid_3x3_bottomright_filled: FairSymbol = Self(rawValue: "square.grid.3x3.bottomright.filled")
    static let circle_hexagongrid: FairSymbol = Self(rawValue: "circle.hexagongrid")
    static let circle_hexagongrid_fill: FairSymbol = Self(rawValue: "circle.hexagongrid.fill")
    static let circle_hexagongrid_circle: FairSymbol = Self(rawValue: "circle.hexagongrid.circle")
    static let circle_hexagongrid_circle_fill: FairSymbol = Self(rawValue: "circle.hexagongrid.circle.fill")
    static let circle_hexagonpath: FairSymbol = Self(rawValue: "circle.hexagonpath")
    static let circle_hexagonpath_fill: FairSymbol = Self(rawValue: "circle.hexagonpath.fill")
    static let circle_grid_cross: FairSymbol = Self(rawValue: "circle.grid.cross")
    static let circle_grid_cross_fill: FairSymbol = Self(rawValue: "circle.grid.cross.fill")
    static let circle_grid_cross_left_filled: FairSymbol = Self(rawValue: "circle.grid.cross.left.filled")
    static let circle_grid_cross_up_filled: FairSymbol = Self(rawValue: "circle.grid.cross.up.filled")
    static let circle_grid_cross_right_filled: FairSymbol = Self(rawValue: "circle.grid.cross.right.filled")
    static let circle_grid_cross_down_filled: FairSymbol = Self(rawValue: "circle.grid.cross.down.filled")
    static let seal: FairSymbol = Self(rawValue: "seal")
    static let seal_fill: FairSymbol = Self(rawValue: "seal.fill")
    static let checkmark_seal: FairSymbol = Self(rawValue: "checkmark.seal")
    static let checkmark_seal_fill: FairSymbol = Self(rawValue: "checkmark.seal.fill")
    static let xmark_seal: FairSymbol = Self(rawValue: "xmark.seal")
    static let xmark_seal_fill: FairSymbol = Self(rawValue: "xmark.seal.fill")
    static let exclamationmark_triangle: FairSymbol = Self(rawValue: "exclamationmark.triangle")
    static let exclamationmark_triangle_fill: FairSymbol = Self(rawValue: "exclamationmark.triangle.fill")
    static let drop: FairSymbol = Self(rawValue: "drop")
    static let drop_fill: FairSymbol = Self(rawValue: "drop.fill")
    static let drop_circle: FairSymbol = Self(rawValue: "drop.circle")
    static let drop_circle_fill: FairSymbol = Self(rawValue: "drop.circle.fill")
    static let drop_triangle: FairSymbol = Self(rawValue: "drop.triangle")
    static let drop_triangle_fill: FairSymbol = Self(rawValue: "drop.triangle.fill")
    static let play: FairSymbol = Self(rawValue: "play")
    static let play_fill: FairSymbol = Self(rawValue: "play.fill")
    static let play_circle: FairSymbol = Self(rawValue: "play.circle")
    static let play_circle_fill: FairSymbol = Self(rawValue: "play.circle.fill")
    static let play_square: FairSymbol = Self(rawValue: "play.square")
    static let play_square_fill: FairSymbol = Self(rawValue: "play.square.fill")
    static let play_rectangle: FairSymbol = Self(rawValue: "play.rectangle")
    static let play_rectangle_fill: FairSymbol = Self(rawValue: "play.rectangle.fill")
    static let play_slash: FairSymbol = Self(rawValue: "play.slash")
    static let play_slash_fill: FairSymbol = Self(rawValue: "play.slash.fill")
    static let pause: FairSymbol = Self(rawValue: "pause")
    static let pause_fill: FairSymbol = Self(rawValue: "pause.fill")
    static let pause_circle: FairSymbol = Self(rawValue: "pause.circle")
    static let pause_circle_fill: FairSymbol = Self(rawValue: "pause.circle.fill")
    static let pause_rectangle: FairSymbol = Self(rawValue: "pause.rectangle")
    static let pause_rectangle_fill: FairSymbol = Self(rawValue: "pause.rectangle.fill")
    static let stop: FairSymbol = Self(rawValue: "stop")
    static let stop_fill: FairSymbol = Self(rawValue: "stop.fill")
    static let stop_circle: FairSymbol = Self(rawValue: "stop.circle")
    static let stop_circle_fill: FairSymbol = Self(rawValue: "stop.circle.fill")
    static let record_circle: FairSymbol = Self(rawValue: "record.circle")
    static let record_circle_fill: FairSymbol = Self(rawValue: "record.circle.fill")
    static let playpause: FairSymbol = Self(rawValue: "playpause")
    static let playpause_fill: FairSymbol = Self(rawValue: "playpause.fill")
    static let backward: FairSymbol = Self(rawValue: "backward")
    static let backward_fill: FairSymbol = Self(rawValue: "backward.fill")
    static let backward_circle: FairSymbol = Self(rawValue: "backward.circle")
    static let backward_circle_fill: FairSymbol = Self(rawValue: "backward.circle.fill")
    static let forward: FairSymbol = Self(rawValue: "forward")
    static let forward_fill: FairSymbol = Self(rawValue: "forward.fill")
    static let forward_circle: FairSymbol = Self(rawValue: "forward.circle")
    static let forward_circle_fill: FairSymbol = Self(rawValue: "forward.circle.fill")
    static let backward_end: FairSymbol = Self(rawValue: "backward.end")
    static let backward_end_fill: FairSymbol = Self(rawValue: "backward.end.fill")
    static let forward_end: FairSymbol = Self(rawValue: "forward.end")
    static let forward_end_fill: FairSymbol = Self(rawValue: "forward.end.fill")
    static let backward_end_alt: FairSymbol = Self(rawValue: "backward.end.alt")
    static let backward_end_alt_fill: FairSymbol = Self(rawValue: "backward.end.alt.fill")
    static let forward_end_alt: FairSymbol = Self(rawValue: "forward.end.alt")
    static let forward_end_alt_fill: FairSymbol = Self(rawValue: "forward.end.alt.fill")
    static let backward_frame: FairSymbol = Self(rawValue: "backward.frame")
    static let backward_frame_fill: FairSymbol = Self(rawValue: "backward.frame.fill")
    static let forward_frame: FairSymbol = Self(rawValue: "forward.frame")
    static let forward_frame_fill: FairSymbol = Self(rawValue: "forward.frame.fill")
    static let eject: FairSymbol = Self(rawValue: "eject")
    static let eject_fill: FairSymbol = Self(rawValue: "eject.fill")
    static let eject_circle: FairSymbol = Self(rawValue: "eject.circle")
    static let eject_circle_fill: FairSymbol = Self(rawValue: "eject.circle.fill")
    static let mount: FairSymbol = Self(rawValue: "mount")
    static let mount_fill: FairSymbol = Self(rawValue: "mount.fill")
    static let memories: FairSymbol = Self(rawValue: "memories")
    static let memories_badge_plus: FairSymbol = Self(rawValue: "memories.badge.plus")
    static let memories_badge_minus: FairSymbol = Self(rawValue: "memories.badge.minus")
    static let shuffle: FairSymbol = Self(rawValue: "shuffle")
    static let shuffle_circle: FairSymbol = Self(rawValue: "shuffle.circle")
    static let shuffle_circle_fill: FairSymbol = Self(rawValue: "shuffle.circle.fill")
    static let `repeat`: FairSymbol = Self(rawValue: "`")
    static let repeat_circle: FairSymbol = Self(rawValue: "repeat.circle")
    static let repeat_circle_fill: FairSymbol = Self(rawValue: "repeat.circle.fill")
    static let repeat_1: FairSymbol = Self(rawValue: "repeat.1")
    static let repeat_1_circle: FairSymbol = Self(rawValue: "repeat.1.circle")
    static let repeat_1_circle_fill: FairSymbol = Self(rawValue: "repeat.1.circle.fill")
    static let infinity: FairSymbol = Self(rawValue: "infinity")
    static let infinity_circle: FairSymbol = Self(rawValue: "infinity.circle")
    static let infinity_circle_fill: FairSymbol = Self(rawValue: "infinity.circle.fill")
    static let megaphone: FairSymbol = Self(rawValue: "megaphone")
    static let megaphone_fill: FairSymbol = Self(rawValue: "megaphone.fill")
    static let speaker: FairSymbol = Self(rawValue: "speaker")
    static let speaker_fill: FairSymbol = Self(rawValue: "speaker.fill")
    static let speaker_circle: FairSymbol = Self(rawValue: "speaker.circle")
    static let speaker_circle_fill: FairSymbol = Self(rawValue: "speaker.circle.fill")
    static let speaker_slash: FairSymbol = Self(rawValue: "speaker.slash")
    static let speaker_slash_fill: FairSymbol = Self(rawValue: "speaker.slash.fill")
    static let speaker_slash_circle: FairSymbol = Self(rawValue: "speaker.slash.circle")
    static let speaker_slash_circle_fill: FairSymbol = Self(rawValue: "speaker.slash.circle.fill")
    static let speaker_zzz: FairSymbol = Self(rawValue: "speaker.zzz")
    static let speaker_zzz_fill: FairSymbol = Self(rawValue: "speaker.zzz.fill")
    static let speaker_wave_1: FairSymbol = Self(rawValue: "speaker.wave.1")
    static let speaker_wave_1_fill: FairSymbol = Self(rawValue: "speaker.wave.1.fill")
    static let speaker_wave_2: FairSymbol = Self(rawValue: "speaker.wave.2")
    static let speaker_wave_2_fill: FairSymbol = Self(rawValue: "speaker.wave.2.fill")
    static let speaker_wave_2_circle: FairSymbol = Self(rawValue: "speaker.wave.2.circle")
    static let speaker_wave_2_circle_fill: FairSymbol = Self(rawValue: "speaker.wave.2.circle.fill")
    static let speaker_wave_3: FairSymbol = Self(rawValue: "speaker.wave.3")
    static let speaker_wave_3_fill: FairSymbol = Self(rawValue: "speaker.wave.3.fill")
    static let speaker_badge_exclamationmark: FairSymbol = Self(rawValue: "speaker.badge.exclamationmark")
    static let speaker_badge_exclamationmark_fill: FairSymbol = Self(rawValue: "speaker.badge.exclamationmark.fill")
    static let badge_plus_radiowaves_right: FairSymbol = Self(rawValue: "badge.plus.radiowaves.right")
    static let badge_plus_radiowaves_forward: FairSymbol = Self(rawValue: "badge.plus.radiowaves.forward")
    static let music_note: FairSymbol = Self(rawValue: "music.note")
    static let music_note_list: FairSymbol = Self(rawValue: "music.note.list")
    static let music_quarternote_3: FairSymbol = Self(rawValue: "music.quarternote.3")
    static let music_mic: FairSymbol = Self(rawValue: "music.mic")
    static let music_mic_circle: FairSymbol = Self(rawValue: "music.mic.circle")
    static let music_mic_circle_fill: FairSymbol = Self(rawValue: "music.mic.circle.fill")
    static let arrow_rectanglepath: FairSymbol = Self(rawValue: "arrow.rectanglepath")
    static let goforward: FairSymbol = Self(rawValue: "goforward")
    static let gobackward: FairSymbol = Self(rawValue: "gobackward")
    static let goforward_5: FairSymbol = Self(rawValue: "goforward.5")
    static let gobackward_5: FairSymbol = Self(rawValue: "gobackward.5")
    static let goforward_10: FairSymbol = Self(rawValue: "goforward.10")
    static let gobackward_10: FairSymbol = Self(rawValue: "gobackward.10")
    static let goforward_15: FairSymbol = Self(rawValue: "goforward.15")
    static let gobackward_15: FairSymbol = Self(rawValue: "gobackward.15")
    static let goforward_30: FairSymbol = Self(rawValue: "goforward.30")
    static let gobackward_30: FairSymbol = Self(rawValue: "gobackward.30")
    static let goforward_45: FairSymbol = Self(rawValue: "goforward.45")
    static let gobackward_45: FairSymbol = Self(rawValue: "gobackward.45")
    static let goforward_60: FairSymbol = Self(rawValue: "goforward.60")
    static let gobackward_60: FairSymbol = Self(rawValue: "gobackward.60")
    static let goforward_75: FairSymbol = Self(rawValue: "goforward.75")
    static let gobackward_75: FairSymbol = Self(rawValue: "gobackward.75")
    static let goforward_90: FairSymbol = Self(rawValue: "goforward.90")
    static let gobackward_90: FairSymbol = Self(rawValue: "gobackward.90")
    static let goforward_plus: FairSymbol = Self(rawValue: "goforward.plus")
    static let gobackward_minus: FairSymbol = Self(rawValue: "gobackward.minus")
    static let magnifyingglass: FairSymbol = Self(rawValue: "magnifyingglass")
    static let magnifyingglass_circle: FairSymbol = Self(rawValue: "magnifyingglass.circle")
    static let magnifyingglass_circle_fill: FairSymbol = Self(rawValue: "magnifyingglass.circle.fill")
    static let plus_magnifyingglass: FairSymbol = Self(rawValue: "plus.magnifyingglass")
    static let minus_magnifyingglass: FairSymbol = Self(rawValue: "minus.magnifyingglass")
    static let N1_magnifyingglass: FairSymbol = Self(rawValue: "1.magnifyingglass")
    static let arrow_up_left_and_down_right_magnifyingglass: FairSymbol = Self(rawValue: "arrow.up.left.and.down.right.magnifyingglass")
    static let text_magnifyingglass: FairSymbol = Self(rawValue: "text.magnifyingglass")
    static let sparkle_magnifyingglass: FairSymbol = Self(rawValue: "sparkle.magnifyingglass")
    static let location_magnifyingglass: FairSymbol = Self(rawValue: "location.magnifyingglass")
    static let loupe: FairSymbol = Self(rawValue: "loupe")
    static let mic: FairSymbol = Self(rawValue: "mic")
    static let mic_fill: FairSymbol = Self(rawValue: "mic.fill")
    static let mic_circle: FairSymbol = Self(rawValue: "mic.circle")
    static let mic_circle_fill: FairSymbol = Self(rawValue: "mic.circle.fill")
    static let mic_square: FairSymbol = Self(rawValue: "mic.square")
    static let mic_square_fill: FairSymbol = Self(rawValue: "mic.square.fill")
    static let mic_slash: FairSymbol = Self(rawValue: "mic.slash")
    static let mic_slash_fill: FairSymbol = Self(rawValue: "mic.slash.fill")
    static let mic_slash_circle: FairSymbol = Self(rawValue: "mic.slash.circle")
    static let mic_slash_circle_fill: FairSymbol = Self(rawValue: "mic.slash.circle.fill")
    static let mic_badge_plus: FairSymbol = Self(rawValue: "mic.badge.plus")
    static let mic_fill_badge_plus: FairSymbol = Self(rawValue: "mic.fill.badge.plus")
    static let line_diagonal: FairSymbol = Self(rawValue: "line.diagonal")
    static let line_diagonal_arrow: FairSymbol = Self(rawValue: "line.diagonal.arrow")
    static let circle: FairSymbol = Self(rawValue: "circle")
    static let circle_fill: FairSymbol = Self(rawValue: "circle.fill")
    static let circle_slash: FairSymbol = Self(rawValue: "circle.slash")
    static let circle_slash_fill: FairSymbol = Self(rawValue: "circle.slash.fill")
    static let circle_lefthalf_filled: FairSymbol = Self(rawValue: "circle.lefthalf.filled")
    static let circle_righthalf_filled: FairSymbol = Self(rawValue: "circle.righthalf.filled")
    static let circle_tophalf_filled: FairSymbol = Self(rawValue: "circle.tophalf.filled")
    static let circle_bottomhalf_filled: FairSymbol = Self(rawValue: "circle.bottomhalf.filled")
    static let circle_inset_filled: FairSymbol = Self(rawValue: "circle.inset.filled")
    static let smallcircle_filled_circle: FairSymbol = Self(rawValue: "smallcircle.filled.circle")
    static let smallcircle_filled_circle_fill: FairSymbol = Self(rawValue: "smallcircle.filled.circle.fill")
    static let circle_dashed: FairSymbol = Self(rawValue: "circle.dashed")
    static let circle_dashed_inset_filled: FairSymbol = Self(rawValue: "circle.dashed.inset.filled")
    static let circle_dotted: FairSymbol = Self(rawValue: "circle.dotted")
    static let circlebadge: FairSymbol = Self(rawValue: "circlebadge")
    static let circlebadge_fill: FairSymbol = Self(rawValue: "circlebadge.fill")
    static let circlebadge_2: FairSymbol = Self(rawValue: "circlebadge.2")
    static let circlebadge_2_fill: FairSymbol = Self(rawValue: "circlebadge.2.fill")
    static let smallcircle_circle: FairSymbol = Self(rawValue: "smallcircle.circle")
    static let smallcircle_circle_fill: FairSymbol = Self(rawValue: "smallcircle.circle.fill")
    static let target: FairSymbol = Self(rawValue: "target")
    static let capsule: FairSymbol = Self(rawValue: "capsule")
    static let capsule_fill: FairSymbol = Self(rawValue: "capsule.fill")
    static let capsule_lefthalf_filled: FairSymbol = Self(rawValue: "capsule.lefthalf.filled")
    static let capsule_righthalf_filled: FairSymbol = Self(rawValue: "capsule.righthalf.filled")
    static let capsule_tophalf_filled: FairSymbol = Self(rawValue: "capsule.tophalf.filled")
    static let capsule_bottomhalf_filled: FairSymbol = Self(rawValue: "capsule.bottomhalf.filled")
    static let capsule_inset_filled: FairSymbol = Self(rawValue: "capsule.inset.filled")
    static let capsule_portrait: FairSymbol = Self(rawValue: "capsule.portrait")
    static let capsule_portrait_fill: FairSymbol = Self(rawValue: "capsule.portrait.fill")
    static let capsule_portrait_lefthalf_filled: FairSymbol = Self(rawValue: "capsule.portrait.lefthalf.filled")
    static let capsule_portrait_righthalf_filled: FairSymbol = Self(rawValue: "capsule.portrait.righthalf.filled")
    static let capsule_portrait_tophalf_filled: FairSymbol = Self(rawValue: "capsule.portrait.tophalf.filled")
    static let capsule_portrait_bottomhalf_filled: FairSymbol = Self(rawValue: "capsule.portrait.bottomhalf.filled")
    static let capsule_portrait_inset_filled: FairSymbol = Self(rawValue: "capsule.portrait.inset.filled")
    static let oval: FairSymbol = Self(rawValue: "oval")
    static let oval_fill: FairSymbol = Self(rawValue: "oval.fill")
    static let oval_lefthalf_filled: FairSymbol = Self(rawValue: "oval.lefthalf.filled")
    static let oval_righthalf_filled: FairSymbol = Self(rawValue: "oval.righthalf.filled")
    static let oval_tophalf_filled: FairSymbol = Self(rawValue: "oval.tophalf.filled")
    static let oval_bottomhalf_filled: FairSymbol = Self(rawValue: "oval.bottomhalf.filled")
    static let oval_inset_filled: FairSymbol = Self(rawValue: "oval.inset.filled")
    static let oval_portrait: FairSymbol = Self(rawValue: "oval.portrait")
    static let oval_portrait_fill: FairSymbol = Self(rawValue: "oval.portrait.fill")
    static let oval_portrait_lefthalf_filled: FairSymbol = Self(rawValue: "oval.portrait.lefthalf.filled")
    static let oval_portrait_righthalf_filled: FairSymbol = Self(rawValue: "oval.portrait.righthalf.filled")
    static let oval_portrait_tophalf_filled: FairSymbol = Self(rawValue: "oval.portrait.tophalf.filled")
    static let oval_portrait_bottomhalf_filled: FairSymbol = Self(rawValue: "oval.portrait.bottomhalf.filled")
    static let oval_portrait_inset_filled: FairSymbol = Self(rawValue: "oval.portrait.inset.filled")
    static let placeholdertext_fill: FairSymbol = Self(rawValue: "placeholdertext.fill")
    static let square: FairSymbol = Self(rawValue: "square")
    static let square_fill: FairSymbol = Self(rawValue: "square.fill")
    static let square_slash: FairSymbol = Self(rawValue: "square.slash")
    static let square_slash_fill: FairSymbol = Self(rawValue: "square.slash.fill")
    static let square_lefthalf_filled: FairSymbol = Self(rawValue: "square.lefthalf.filled")
    static let square_righthalf_filled: FairSymbol = Self(rawValue: "square.righthalf.filled")
    static let square_tophalf_filled: FairSymbol = Self(rawValue: "square.tophalf.filled")
    static let square_bottomhalf_filled: FairSymbol = Self(rawValue: "square.bottomhalf.filled")
    static let square_inset_filled: FairSymbol = Self(rawValue: "square.inset.filled")
    static let square_split_2x1: FairSymbol = Self(rawValue: "square.split.2x1")
    static let square_split_2x1_fill: FairSymbol = Self(rawValue: "square.split.2x1.fill")
    static let square_split_1x2: FairSymbol = Self(rawValue: "square.split.1x2")
    static let square_split_1x2_fill: FairSymbol = Self(rawValue: "square.split.1x2.fill")
    static let square_split_2x2: FairSymbol = Self(rawValue: "square.split.2x2")
    static let square_split_2x2_fill: FairSymbol = Self(rawValue: "square.split.2x2.fill")
    static let square_split_diagonal_2x2: FairSymbol = Self(rawValue: "square.split.diagonal.2x2")
    static let square_split_diagonal_2x2_fill: FairSymbol = Self(rawValue: "square.split.diagonal.2x2.fill")
    static let square_split_diagonal: FairSymbol = Self(rawValue: "square.split.diagonal")
    static let square_split_diagonal_fill: FairSymbol = Self(rawValue: "square.split.diagonal.fill")
    static let dot_square: FairSymbol = Self(rawValue: "dot.square")
    static let dot_square_fill: FairSymbol = Self(rawValue: "dot.square.fill")
    static let circle_square: FairSymbol = Self(rawValue: "circle.square")
    static let circle_square_fill: FairSymbol = Self(rawValue: "circle.square.fill")
    static let square_dashed: FairSymbol = Self(rawValue: "square.dashed")
    static let square_dashed_inset_filled: FairSymbol = Self(rawValue: "square.dashed.inset.filled")
    static let plus_square_dashed: FairSymbol = Self(rawValue: "plus.square.dashed")
    static let questionmark_square_dashed: FairSymbol = Self(rawValue: "questionmark.square.dashed")
    static let square_on_square: FairSymbol = Self(rawValue: "square.on.square")
    static let square_fill_on_square_fill: FairSymbol = Self(rawValue: "square.fill.on.square.fill")
    static let square_filled_on_square: FairSymbol = Self(rawValue: "square.filled.on.square")
    static let hand_raised_square_on_square: FairSymbol = Self(rawValue: "hand.raised.square.on.square")
    static let hand_raised_square_on_square_fill: FairSymbol = Self(rawValue: "hand.raised.square.on.square.fill")
    static let sparkles_square_filled_on_square: FairSymbol = Self(rawValue: "sparkles.square.filled.on.square")
    static let square_on_square_dashed: FairSymbol = Self(rawValue: "square.on.square.dashed")
    static let plus_square_on_square: FairSymbol = Self(rawValue: "plus.square.on.square")
    static let plus_square_fill_on_square_fill: FairSymbol = Self(rawValue: "plus.square.fill.on.square.fill")
    static let square_on_circle: FairSymbol = Self(rawValue: "square.on.circle")
    static let square_fill_on_circle_fill: FairSymbol = Self(rawValue: "square.fill.on.circle.fill")
    static let r_square_on_square: FairSymbol = Self(rawValue: "r.square.on.square")
    static let r_square_on_square_fill: FairSymbol = Self(rawValue: "r.square.on.square.fill")
    static let j_square_on_square: FairSymbol = Self(rawValue: "j.square.on.square")
    static let j_square_on_square_fill: FairSymbol = Self(rawValue: "j.square.on.square.fill")
    static let h_square_on_square: FairSymbol = Self(rawValue: "h.square.on.square")
    static let h_square_on_square_fill: FairSymbol = Self(rawValue: "h.square.on.square.fill")
    static let square_stack: FairSymbol = Self(rawValue: "square.stack")
    static let square_stack_fill: FairSymbol = Self(rawValue: "square.stack.fill")
    static let squareshape: FairSymbol = Self(rawValue: "squareshape")
    static let squareshape_fill: FairSymbol = Self(rawValue: "squareshape.fill")
    static let squareshape_dashed_squareshape: FairSymbol = Self(rawValue: "squareshape.dashed.squareshape")
    static let squareshape_squareshape_dashed: FairSymbol = Self(rawValue: "squareshape.squareshape.dashed")
    static let dot_squareshape: FairSymbol = Self(rawValue: "dot.squareshape")
    static let dot_squareshape_fill: FairSymbol = Self(rawValue: "dot.squareshape.fill")
    static let app: FairSymbol = Self(rawValue: "app")
    static let app_fill: FairSymbol = Self(rawValue: "app.fill")
    static let rectangle: FairSymbol = Self(rawValue: "rectangle")
    static let rectangle_fill: FairSymbol = Self(rawValue: "rectangle.fill")
    static let rectangle_slash: FairSymbol = Self(rawValue: "rectangle.slash")
    static let rectangle_slash_fill: FairSymbol = Self(rawValue: "rectangle.slash.fill")
    static let rectangle_lefthalf_filled: FairSymbol = Self(rawValue: "rectangle.lefthalf.filled")
    static let rectangle_righthalf_filled: FairSymbol = Self(rawValue: "rectangle.righthalf.filled")
    static let rectangle_tophalf_filled: FairSymbol = Self(rawValue: "rectangle.tophalf.filled")
    static let rectangle_bottomhalf_filled: FairSymbol = Self(rawValue: "rectangle.bottomhalf.filled")
    static let rectangle_split_2x1: FairSymbol = Self(rawValue: "rectangle.split.2x1")
    static let rectangle_split_2x1_fill: FairSymbol = Self(rawValue: "rectangle.split.2x1.fill")
    static let rectangle_split_2x1_slash: FairSymbol = Self(rawValue: "rectangle.split.2x1.slash")
    static let rectangle_split_2x1_slash_fill: FairSymbol = Self(rawValue: "rectangle.split.2x1.slash.fill")
    static let rectangle_split_1x2: FairSymbol = Self(rawValue: "rectangle.split.1x2")
    static let rectangle_split_1x2_fill: FairSymbol = Self(rawValue: "rectangle.split.1x2.fill")
    static let rectangle_split_3x1: FairSymbol = Self(rawValue: "rectangle.split.3x1")
    static let rectangle_split_3x1_fill: FairSymbol = Self(rawValue: "rectangle.split.3x1.fill")
    static let rectangle_split_2x2: FairSymbol = Self(rawValue: "rectangle.split.2x2")
    static let rectangle_split_2x2_fill: FairSymbol = Self(rawValue: "rectangle.split.2x2.fill")
    static let tablecells: FairSymbol = Self(rawValue: "tablecells")
    static let tablecells_fill: FairSymbol = Self(rawValue: "tablecells.fill")
    static let tablecells_badge_ellipsis: FairSymbol = Self(rawValue: "tablecells.badge.ellipsis")
    static let tablecells_fill_badge_ellipsis: FairSymbol = Self(rawValue: "tablecells.fill.badge.ellipsis")
    static let rectangle_split_3x3: FairSymbol = Self(rawValue: "rectangle.split.3x3")
    static let rectangle_inset_filled: FairSymbol = Self(rawValue: "rectangle.inset.filled")
    static let rectangle_tophalf_inset_filled: FairSymbol = Self(rawValue: "rectangle.tophalf.inset.filled")
    static let rectangle_bottomhalf_inset_filled: FairSymbol = Self(rawValue: "rectangle.bottomhalf.inset.filled")
    static let rectangle_lefthalf_inset_filled: FairSymbol = Self(rawValue: "rectangle.lefthalf.inset.filled")
    static let rectangle_righthalf_inset_filled: FairSymbol = Self(rawValue: "rectangle.righthalf.inset.filled")
    static let rectangle_leadinghalf_inset_filled: FairSymbol = Self(rawValue: "rectangle.leadinghalf.inset.filled")
    static let rectangle_trailinghalf_inset_filled: FairSymbol = Self(rawValue: "rectangle.trailinghalf.inset.filled")
    static let rectangle_lefthalf_inset_filled_arrow_left: FairSymbol = Self(rawValue: "rectangle.lefthalf.inset.filled.arrow.left")
    static let rectangle_righthalf_inset_filled_arrow_right: FairSymbol = Self(rawValue: "rectangle.righthalf.inset.filled.arrow.right")
    static let rectangle_leadinghalf_inset_filled_arrow_leading: FairSymbol = Self(rawValue: "rectangle.leadinghalf.inset.filled.arrow.leading")
    static let rectangle_trailinghalf_inset_filled_arrow_trailing: FairSymbol = Self(rawValue: "rectangle.trailinghalf.inset.filled.arrow.trailing")
    static let rectangle_topthird_inset_filled: FairSymbol = Self(rawValue: "rectangle.topthird.inset.filled")
    static let rectangle_bottomthird_inset_filled: FairSymbol = Self(rawValue: "rectangle.bottomthird.inset.filled")
    static let rectangle_leftthird_inset_filled: FairSymbol = Self(rawValue: "rectangle.leftthird.inset.filled")
    static let rectangle_rightthird_inset_filled: FairSymbol = Self(rawValue: "rectangle.rightthird.inset.filled")
    static let rectangle_leadingthird_inset_filled: FairSymbol = Self(rawValue: "rectangle.leadingthird.inset.filled")
    static let rectangle_trailingthird_inset_filled: FairSymbol = Self(rawValue: "rectangle.trailingthird.inset.filled")
    static let rectangle_center_inset_filled: FairSymbol = Self(rawValue: "rectangle.center.inset.filled")
    static let rectangle_center_inset_filled_badge_plus: FairSymbol = Self(rawValue: "rectangle.center.inset.filled.badge.plus")
    static let rectangle_inset_topleft_filled: FairSymbol = Self(rawValue: "rectangle.inset.topleft.filled")
    static let rectangle_inset_topright_filled: FairSymbol = Self(rawValue: "rectangle.inset.topright.filled")
    static let rectangle_inset_topleading_filled: FairSymbol = Self(rawValue: "rectangle.inset.topleading.filled")
    static let rectangle_inset_toptrailing_filled: FairSymbol = Self(rawValue: "rectangle.inset.toptrailing.filled")
    static let rectangle_inset_bottomleft_filled: FairSymbol = Self(rawValue: "rectangle.inset.bottomleft.filled")
    static let rectangle_inset_bottomright_filled: FairSymbol = Self(rawValue: "rectangle.inset.bottomright.filled")
    static let rectangle_inset_bottomleading_filled: FairSymbol = Self(rawValue: "rectangle.inset.bottomleading.filled")
    static let rectangle_inset_bottomtrailing_filled: FairSymbol = Self(rawValue: "rectangle.inset.bottomtrailing.filled")
    static let rectangle_on_rectangle: FairSymbol = Self(rawValue: "rectangle.on.rectangle")
    static let rectangle_fill_on_rectangle_fill: FairSymbol = Self(rawValue: "rectangle.fill.on.rectangle.fill")
    static let rectangle_on_rectangle_circle: FairSymbol = Self(rawValue: "rectangle.on.rectangle.circle")
    static let rectangle_on_rectangle_circle_fill: FairSymbol = Self(rawValue: "rectangle.on.rectangle.circle.fill")
    static let rectangle_on_rectangle_square: FairSymbol = Self(rawValue: "rectangle.on.rectangle.square")
    static let rectangle_on_rectangle_square_fill: FairSymbol = Self(rawValue: "rectangle.on.rectangle.square.fill")
    static let rectangle_inset_filled_on_rectangle: FairSymbol = Self(rawValue: "rectangle.inset.filled.on.rectangle")
    static let rectangle_on_rectangle_slash: FairSymbol = Self(rawValue: "rectangle.on.rectangle.slash")
    static let rectangle_on_rectangle_slash_fill: FairSymbol = Self(rawValue: "rectangle.on.rectangle.slash.fill")
    static let rectangle_on_rectangle_slash_circle: FairSymbol = Self(rawValue: "rectangle.on.rectangle.slash.circle")
    static let rectangle_on_rectangle_slash_circle_fill: FairSymbol = Self(rawValue: "rectangle.on.rectangle.slash.circle.fill")
    static let play_rectangle_on_rectangle: FairSymbol = Self(rawValue: "play.rectangle.on.rectangle")
    static let play_rectangle_on_rectangle_fill: FairSymbol = Self(rawValue: "play.rectangle.on.rectangle.fill")
    static let play_rectangle_on_rectangle_circle: FairSymbol = Self(rawValue: "play.rectangle.on.rectangle.circle")
    static let play_rectangle_on_rectangle_circle_fill: FairSymbol = Self(rawValue: "play.rectangle.on.rectangle.circle.fill")
    static let plus_rectangle_on_rectangle: FairSymbol = Self(rawValue: "plus.rectangle.on.rectangle")
    static let plus_rectangle_fill_on_rectangle_fill: FairSymbol = Self(rawValue: "plus.rectangle.fill.on.rectangle.fill")
    static let rectangle_portrait: FairSymbol = Self(rawValue: "rectangle.portrait")
    static let rectangle_portrait_fill: FairSymbol = Self(rawValue: "rectangle.portrait.fill")
    static let rectangle_portrait_slash: FairSymbol = Self(rawValue: "rectangle.portrait.slash")
    static let rectangle_portrait_slash_fill: FairSymbol = Self(rawValue: "rectangle.portrait.slash.fill")
    static let rectangle_portrait_lefthalf_filled: FairSymbol = Self(rawValue: "rectangle.portrait.lefthalf.filled")
    static let rectangle_portrait_righthalf_filled: FairSymbol = Self(rawValue: "rectangle.portrait.righthalf.filled")
    static let rectangle_portrait_tophalf_filled: FairSymbol = Self(rawValue: "rectangle.portrait.tophalf.filled")
    static let rectangle_portrait_bottomhalf_filled: FairSymbol = Self(rawValue: "rectangle.portrait.bottomhalf.filled")
    static let rectangle_portrait_inset_filled: FairSymbol = Self(rawValue: "rectangle.portrait.inset.filled")
    static let rectangle_portrait_tophalf_inset_filled: FairSymbol = Self(rawValue: "rectangle.portrait.tophalf.inset.filled")
    static let rectangle_portrait_bottomhalf_inset_filled: FairSymbol = Self(rawValue: "rectangle.portrait.bottomhalf.inset.filled")
    static let rectangle_portrait_lefthalf_inset_filled: FairSymbol = Self(rawValue: "rectangle.portrait.lefthalf.inset.filled")
    static let rectangle_portrait_righthalf_inset_filled: FairSymbol = Self(rawValue: "rectangle.portrait.righthalf.inset.filled")
    static let rectangle_portrait_leadinghalf_inset_filled: FairSymbol = Self(rawValue: "rectangle.portrait.leadinghalf.inset.filled")
    static let rectangle_portrait_trailinghalf_inset_filled: FairSymbol = Self(rawValue: "rectangle.portrait.trailinghalf.inset.filled")
    static let rectangle_portrait_topthird_inset_filled: FairSymbol = Self(rawValue: "rectangle.portrait.topthird.inset.filled")
    static let rectangle_portrait_bottomthird_inset_filled: FairSymbol = Self(rawValue: "rectangle.portrait.bottomthird.inset.filled")
    static let rectangle_portrait_leftthird_inset_filled: FairSymbol = Self(rawValue: "rectangle.portrait.leftthird.inset.filled")
    static let rectangle_portrait_rightthird_inset_filled: FairSymbol = Self(rawValue: "rectangle.portrait.rightthird.inset.filled")
    static let rectangle_portrait_leadingthird_inset_filled: FairSymbol = Self(rawValue: "rectangle.portrait.leadingthird.inset.filled")
    static let rectangle_portrait_trailingthird_inset_filled: FairSymbol = Self(rawValue: "rectangle.portrait.trailingthird.inset.filled")
    static let rectangle_portrait_center_inset_filled: FairSymbol = Self(rawValue: "rectangle.portrait.center.inset.filled")
    static let rectangle_portrait_topleft_inset_filled: FairSymbol = Self(rawValue: "rectangle.portrait.topleft.inset.filled")
    static let rectangle_portrait_topright_inset_filled: FairSymbol = Self(rawValue: "rectangle.portrait.topright.inset.filled")
    static let rectangle_portrait_topleading_inset_filled: FairSymbol = Self(rawValue: "rectangle.portrait.topleading.inset.filled")
    static let rectangle_portrait_toptrailing_inset_filled: FairSymbol = Self(rawValue: "rectangle.portrait.toptrailing.inset.filled")
    static let rectangle_portrait_bottomleft_inset_filled: FairSymbol = Self(rawValue: "rectangle.portrait.bottomleft.inset.filled")
    static let rectangle_portrait_bottomright_inset_filled: FairSymbol = Self(rawValue: "rectangle.portrait.bottomright.inset.filled")
    static let rectangle_portrait_bottomleading_inset_filled: FairSymbol = Self(rawValue: "rectangle.portrait.bottomleading.inset.filled")
    static let rectangle_portrait_bottomtrailing_inset_filled: FairSymbol = Self(rawValue: "rectangle.portrait.bottomtrailing.inset.filled")
    static let rectangle_portrait_on_rectangle_portrait: FairSymbol = Self(rawValue: "rectangle.portrait.on.rectangle.portrait")
    static let rectangle_portrait_on_rectangle_portrait_fill: FairSymbol = Self(rawValue: "rectangle.portrait.on.rectangle.portrait.fill")
    static let rectangle_portrait_on_rectangle_portrait_slash: FairSymbol = Self(rawValue: "rectangle.portrait.on.rectangle.portrait.slash")
    static let rectangle_portrait_on_rectangle_portrait_slash_fill: FairSymbol = Self(rawValue: "rectangle.portrait.on.rectangle.portrait.slash.fill")
    static let rectangle_portrait_split_2x1: FairSymbol = Self(rawValue: "rectangle.portrait.split.2x1")
    static let rectangle_portrait_split_2x1_fill: FairSymbol = Self(rawValue: "rectangle.portrait.split.2x1.fill")
    static let rectangle_portrait_split_2x1_slash: FairSymbol = Self(rawValue: "rectangle.portrait.split.2x1.slash")
    static let rectangle_portrait_split_2x1_slash_fill: FairSymbol = Self(rawValue: "rectangle.portrait.split.2x1.slash.fill")
    static let triangle: FairSymbol = Self(rawValue: "triangle")
    static let triangle_fill: FairSymbol = Self(rawValue: "triangle.fill")
    static let triangle_lefthalf_filled: FairSymbol = Self(rawValue: "triangle.lefthalf.filled")
    static let triangle_righthalf_filled: FairSymbol = Self(rawValue: "triangle.righthalf.filled")
    static let triangle_tophalf_filled: FairSymbol = Self(rawValue: "triangle.tophalf.filled")
    static let triangle_bottomhalf_filled: FairSymbol = Self(rawValue: "triangle.bottomhalf.filled")
    static let triangle_inset_filled: FairSymbol = Self(rawValue: "triangle.inset.filled")
    static let diamond: FairSymbol = Self(rawValue: "diamond")
    static let diamond_fill: FairSymbol = Self(rawValue: "diamond.fill")
    static let diamond_circle: FairSymbol = Self(rawValue: "diamond.circle")
    static let diamond_circle_fill: FairSymbol = Self(rawValue: "diamond.circle.fill")
    static let diamond_lefthalf_filled: FairSymbol = Self(rawValue: "diamond.lefthalf.filled")
    static let diamond_righthalf_filled: FairSymbol = Self(rawValue: "diamond.righthalf.filled")
    static let diamond_tophalf_filled: FairSymbol = Self(rawValue: "diamond.tophalf.filled")
    static let diamond_bottomhalf_filled: FairSymbol = Self(rawValue: "diamond.bottomhalf.filled")
    static let diamond_inset_filled: FairSymbol = Self(rawValue: "diamond.inset.filled")
    static let octagon: FairSymbol = Self(rawValue: "octagon")
    static let octagon_fill: FairSymbol = Self(rawValue: "octagon.fill")
    static let octagon_lefthalf_filled: FairSymbol = Self(rawValue: "octagon.lefthalf.filled")
    static let octagon_righthalf_filled: FairSymbol = Self(rawValue: "octagon.righthalf.filled")
    static let octagon_tophalf_filled: FairSymbol = Self(rawValue: "octagon.tophalf.filled")
    static let octagon_bottomhalf_filled: FairSymbol = Self(rawValue: "octagon.bottomhalf.filled")
    static let hexagon: FairSymbol = Self(rawValue: "hexagon")
    static let hexagon_fill: FairSymbol = Self(rawValue: "hexagon.fill")
    static let hexagon_lefthalf_filled: FairSymbol = Self(rawValue: "hexagon.lefthalf.filled")
    static let hexagon_righthalf_filled: FairSymbol = Self(rawValue: "hexagon.righthalf.filled")
    static let hexagon_tophalf_filled: FairSymbol = Self(rawValue: "hexagon.tophalf.filled")
    static let hexagon_bottomhalf_filled: FairSymbol = Self(rawValue: "hexagon.bottomhalf.filled")
    static let pentagon: FairSymbol = Self(rawValue: "pentagon")
    static let pentagon_fill: FairSymbol = Self(rawValue: "pentagon.fill")
    static let pentagon_lefthalf_filled: FairSymbol = Self(rawValue: "pentagon.lefthalf.filled")
    static let pentagon_righthalf_filled: FairSymbol = Self(rawValue: "pentagon.righthalf.filled")
    static let pentagon_tophalf_filled: FairSymbol = Self(rawValue: "pentagon.tophalf.filled")
    static let pentagon_bottomhalf_filled: FairSymbol = Self(rawValue: "pentagon.bottomhalf.filled")
    static let suit_heart: FairSymbol = Self(rawValue: "suit.heart")
    static let suit_heart_fill: FairSymbol = Self(rawValue: "suit.heart.fill")
    static let suit_club: FairSymbol = Self(rawValue: "suit.club")
    static let suit_club_fill: FairSymbol = Self(rawValue: "suit.club.fill")
    static let suit_spade: FairSymbol = Self(rawValue: "suit.spade")
    static let suit_spade_fill: FairSymbol = Self(rawValue: "suit.spade.fill")
    static let suit_diamond: FairSymbol = Self(rawValue: "suit.diamond")
    static let suit_diamond_fill: FairSymbol = Self(rawValue: "suit.diamond.fill")
    static let heart: FairSymbol = Self(rawValue: "heart")
    static let heart_fill: FairSymbol = Self(rawValue: "heart.fill")
    static let heart_circle: FairSymbol = Self(rawValue: "heart.circle")
    static let heart_circle_fill: FairSymbol = Self(rawValue: "heart.circle.fill")
    static let heart_square: FairSymbol = Self(rawValue: "heart.square")
    static let heart_square_fill: FairSymbol = Self(rawValue: "heart.square.fill")
    static let heart_rectangle: FairSymbol = Self(rawValue: "heart.rectangle")
    static let heart_rectangle_fill: FairSymbol = Self(rawValue: "heart.rectangle.fill")
    static let heart_slash: FairSymbol = Self(rawValue: "heart.slash")
    static let heart_slash_fill: FairSymbol = Self(rawValue: "heart.slash.fill")
    static let heart_slash_circle: FairSymbol = Self(rawValue: "heart.slash.circle")
    static let heart_slash_circle_fill: FairSymbol = Self(rawValue: "heart.slash.circle.fill")
    static let bolt_heart: FairSymbol = Self(rawValue: "bolt.heart")
    static let bolt_heart_fill: FairSymbol = Self(rawValue: "bolt.heart.fill")
    static let arrow_up_heart: FairSymbol = Self(rawValue: "arrow.up.heart")
    static let arrow_up_heart_fill: FairSymbol = Self(rawValue: "arrow.up.heart.fill")
    static let arrow_down_heart: FairSymbol = Self(rawValue: "arrow.down.heart")
    static let arrow_down_heart_fill: FairSymbol = Self(rawValue: "arrow.down.heart.fill")
    static let arrow_clockwise_heart: FairSymbol = Self(rawValue: "arrow.clockwise.heart")
    static let arrow_clockwise_heart_fill: FairSymbol = Self(rawValue: "arrow.clockwise.heart.fill")
    static let rhombus: FairSymbol = Self(rawValue: "rhombus")
    static let rhombus_fill: FairSymbol = Self(rawValue: "rhombus.fill")
    static let star: FairSymbol = Self(rawValue: "star")
    static let star_fill: FairSymbol = Self(rawValue: "star.fill")
    static let star_leadinghalf_filled: FairSymbol = Self(rawValue: "star.leadinghalf.filled")
    static let star_circle: FairSymbol = Self(rawValue: "star.circle")
    static let star_circle_fill: FairSymbol = Self(rawValue: "star.circle.fill")
    static let star_square: FairSymbol = Self(rawValue: "star.square")
    static let star_square_fill: FairSymbol = Self(rawValue: "star.square.fill")
    static let star_slash: FairSymbol = Self(rawValue: "star.slash")
    static let star_slash_fill: FairSymbol = Self(rawValue: "star.slash.fill")
    static let line_horizontal_star_fill_line_horizontal: FairSymbol = Self(rawValue: "line.horizontal.star.fill.line.horizontal")
    static let flag: FairSymbol = Self(rawValue: "flag")
    static let flag_fill: FairSymbol = Self(rawValue: "flag.fill")
    static let flag_circle: FairSymbol = Self(rawValue: "flag.circle")
    static let flag_circle_fill: FairSymbol = Self(rawValue: "flag.circle.fill")
    static let flag_square: FairSymbol = Self(rawValue: "flag.square")
    static let flag_square_fill: FairSymbol = Self(rawValue: "flag.square.fill")
    static let flag_slash: FairSymbol = Self(rawValue: "flag.slash")
    static let flag_slash_fill: FairSymbol = Self(rawValue: "flag.slash.fill")
    static let flag_slash_circle: FairSymbol = Self(rawValue: "flag.slash.circle")
    static let flag_slash_circle_fill: FairSymbol = Self(rawValue: "flag.slash.circle.fill")
    static let flag_badge_ellipsis: FairSymbol = Self(rawValue: "flag.badge.ellipsis")
    static let flag_badge_ellipsis_fill: FairSymbol = Self(rawValue: "flag.badge.ellipsis.fill")
    static let flag_2_crossed: FairSymbol = Self(rawValue: "flag.2.crossed")
    static let flag_2_crossed_fill: FairSymbol = Self(rawValue: "flag.2.crossed.fill")
    static let flag_filled_and_flag_crossed: FairSymbol = Self(rawValue: "flag.filled.and.flag.crossed")
    static let flag_and_flag_filled_crossed: FairSymbol = Self(rawValue: "flag.and.flag.filled.crossed")
    static let location: FairSymbol = Self(rawValue: "location")
    static let location_fill: FairSymbol = Self(rawValue: "location.fill")
    static let location_circle: FairSymbol = Self(rawValue: "location.circle")
    static let location_circle_fill: FairSymbol = Self(rawValue: "location.circle.fill")
    static let location_square: FairSymbol = Self(rawValue: "location.square")
    static let location_square_fill: FairSymbol = Self(rawValue: "location.square.fill")
    static let location_slash: FairSymbol = Self(rawValue: "location.slash")
    static let location_slash_fill: FairSymbol = Self(rawValue: "location.slash.fill")
    static let location_north: FairSymbol = Self(rawValue: "location.north")
    static let location_north_fill: FairSymbol = Self(rawValue: "location.north.fill")
    static let location_north_circle: FairSymbol = Self(rawValue: "location.north.circle")
    static let location_north_circle_fill: FairSymbol = Self(rawValue: "location.north.circle.fill")
    static let location_north_line: FairSymbol = Self(rawValue: "location.north.line")
    static let location_north_line_fill: FairSymbol = Self(rawValue: "location.north.line.fill")
    static let sensor_tag_radiowaves_forward: FairSymbol = Self(rawValue: "sensor.tag.radiowaves.forward")
    static let sensor_tag_radiowaves_forward_fill: FairSymbol = Self(rawValue: "sensor.tag.radiowaves.forward.fill")
    static let bell: FairSymbol = Self(rawValue: "bell")
    static let bell_fill: FairSymbol = Self(rawValue: "bell.fill")
    static let bell_circle: FairSymbol = Self(rawValue: "bell.circle")
    static let bell_circle_fill: FairSymbol = Self(rawValue: "bell.circle.fill")
    static let bell_square: FairSymbol = Self(rawValue: "bell.square")
    static let bell_square_fill: FairSymbol = Self(rawValue: "bell.square.fill")
    static let bell_slash: FairSymbol = Self(rawValue: "bell.slash")
    static let bell_slash_fill: FairSymbol = Self(rawValue: "bell.slash.fill")
    static let bell_slash_circle: FairSymbol = Self(rawValue: "bell.slash.circle")
    static let bell_slash_circle_fill: FairSymbol = Self(rawValue: "bell.slash.circle.fill")
    static let bell_and_waveform: FairSymbol = Self(rawValue: "bell.and.waveform")
    static let bell_and_waveform_fill: FairSymbol = Self(rawValue: "bell.and.waveform.fill")
    static let bell_badge: FairSymbol = Self(rawValue: "bell.badge")
    static let bell_badge_fill: FairSymbol = Self(rawValue: "bell.badge.fill")
    static let bell_badge_circle: FairSymbol = Self(rawValue: "bell.badge.circle")
    static let bell_badge_circle_fill: FairSymbol = Self(rawValue: "bell.badge.circle.fill")
    static let tag: FairSymbol = Self(rawValue: "tag")
    static let tag_fill: FairSymbol = Self(rawValue: "tag.fill")
    static let tag_circle: FairSymbol = Self(rawValue: "tag.circle")
    static let tag_circle_fill: FairSymbol = Self(rawValue: "tag.circle.fill")
    static let tag_square: FairSymbol = Self(rawValue: "tag.square")
    static let tag_square_fill: FairSymbol = Self(rawValue: "tag.square.fill")
    static let tag_slash: FairSymbol = Self(rawValue: "tag.slash")
    static let tag_slash_fill: FairSymbol = Self(rawValue: "tag.slash.fill")
    static let bolt: FairSymbol = Self(rawValue: "bolt")
    static let bolt_fill: FairSymbol = Self(rawValue: "bolt.fill")
    static let bolt_circle: FairSymbol = Self(rawValue: "bolt.circle")
    static let bolt_circle_fill: FairSymbol = Self(rawValue: "bolt.circle.fill")
    static let bolt_square: FairSymbol = Self(rawValue: "bolt.square")
    static let bolt_square_fill: FairSymbol = Self(rawValue: "bolt.square.fill")
    static let bolt_ring_closed: FairSymbol = Self(rawValue: "bolt.ring.closed")
    static let bolt_shield: FairSymbol = Self(rawValue: "bolt.shield")
    static let bolt_shield_fill: FairSymbol = Self(rawValue: "bolt.shield.fill")
    static let bolt_slash: FairSymbol = Self(rawValue: "bolt.slash")
    static let bolt_slash_fill: FairSymbol = Self(rawValue: "bolt.slash.fill")
    static let bolt_slash_circle: FairSymbol = Self(rawValue: "bolt.slash.circle")
    static let bolt_slash_circle_fill: FairSymbol = Self(rawValue: "bolt.slash.circle.fill")
    static let bolt_badge_a: FairSymbol = Self(rawValue: "bolt.badge.a")
    static let bolt_badge_a_fill: FairSymbol = Self(rawValue: "bolt.badge.a.fill")
    static let bolt_horizontal: FairSymbol = Self(rawValue: "bolt.horizontal")
    static let bolt_horizontal_fill: FairSymbol = Self(rawValue: "bolt.horizontal.fill")
    static let bolt_horizontal_circle: FairSymbol = Self(rawValue: "bolt.horizontal.circle")
    static let bolt_horizontal_circle_fill: FairSymbol = Self(rawValue: "bolt.horizontal.circle.fill")
    static let eye: FairSymbol = Self(rawValue: "eye")
    static let eye_fill: FairSymbol = Self(rawValue: "eye.fill")
    static let eye_circle: FairSymbol = Self(rawValue: "eye.circle")
    static let eye_circle_fill: FairSymbol = Self(rawValue: "eye.circle.fill")
    static let eye_square: FairSymbol = Self(rawValue: "eye.square")
    static let eye_square_fill: FairSymbol = Self(rawValue: "eye.square.fill")
    static let eye_slash: FairSymbol = Self(rawValue: "eye.slash")
    static let eye_slash_fill: FairSymbol = Self(rawValue: "eye.slash.fill")
    static let eye_slash_circle: FairSymbol = Self(rawValue: "eye.slash.circle")
    static let eye_slash_circle_fill: FairSymbol = Self(rawValue: "eye.slash.circle.fill")
    static let eye_trianglebadge_exclamationmark: FairSymbol = Self(rawValue: "eye.trianglebadge.exclamationmark")
    static let eye_trianglebadge_exclamationmark_fill: FairSymbol = Self(rawValue: "eye.trianglebadge.exclamationmark.fill")
    static let tshirt: FairSymbol = Self(rawValue: "tshirt")
    static let tshirt_fill: FairSymbol = Self(rawValue: "tshirt.fill")
    static let eyes: FairSymbol = Self(rawValue: "eyes")
    static let eyes_inverse: FairSymbol = Self(rawValue: "eyes.inverse")
    static let eyebrow: FairSymbol = Self(rawValue: "eyebrow")
    static let nose: FairSymbol = Self(rawValue: "nose")
    static let nose_fill: FairSymbol = Self(rawValue: "nose.fill")
    static let mustache: FairSymbol = Self(rawValue: "mustache")
    static let mustache_fill: FairSymbol = Self(rawValue: "mustache.fill")
    static let mouth: FairSymbol = Self(rawValue: "mouth")
    static let mouth_fill: FairSymbol = Self(rawValue: "mouth.fill")
    static let eyeglasses: FairSymbol = Self(rawValue: "eyeglasses")
    static let facemask: FairSymbol = Self(rawValue: "facemask")
    static let facemask_fill: FairSymbol = Self(rawValue: "facemask.fill")
    static let brain_head_profile: FairSymbol = Self(rawValue: "brain.head.profile")
    static let brain: FairSymbol = Self(rawValue: "brain")
    static let flashlight_off_fill: FairSymbol = Self(rawValue: "flashlight.off.fill")
    static let flashlight_on_fill: FairSymbol = Self(rawValue: "flashlight.on.fill")
    static let camera: FairSymbol = Self(rawValue: "camera")
    static let camera_fill: FairSymbol = Self(rawValue: "camera.fill")
    static let camera_circle: FairSymbol = Self(rawValue: "camera.circle")
    static let camera_circle_fill: FairSymbol = Self(rawValue: "camera.circle.fill")
    static let camera_shutter_button: FairSymbol = Self(rawValue: "camera.shutter.button")
    static let camera_shutter_button_fill: FairSymbol = Self(rawValue: "camera.shutter.button.fill")
    static let camera_badge_ellipsis: FairSymbol = Self(rawValue: "camera.badge.ellipsis")
    static let camera_fill_badge_ellipsis: FairSymbol = Self(rawValue: "camera.fill.badge.ellipsis")
    static let arrow_triangle_2_circlepath_camera: FairSymbol = Self(rawValue: "arrow.triangle.2.circlepath.camera")
    static let arrow_triangle_2_circlepath_camera_fill: FairSymbol = Self(rawValue: "arrow.triangle.2.circlepath.camera.fill")
    static let camera_on_rectangle: FairSymbol = Self(rawValue: "camera.on.rectangle")
    static let camera_on_rectangle_fill: FairSymbol = Self(rawValue: "camera.on.rectangle.fill")
    static let bubble_right: FairSymbol = Self(rawValue: "bubble.right")
    static let bubble_right_fill: FairSymbol = Self(rawValue: "bubble.right.fill")
    static let bubble_right_circle: FairSymbol = Self(rawValue: "bubble.right.circle")
    static let bubble_right_circle_fill: FairSymbol = Self(rawValue: "bubble.right.circle.fill")
    static let bubble_left: FairSymbol = Self(rawValue: "bubble.left")
    static let bubble_left_fill: FairSymbol = Self(rawValue: "bubble.left.fill")
    static let bubble_left_circle: FairSymbol = Self(rawValue: "bubble.left.circle")
    static let bubble_left_circle_fill: FairSymbol = Self(rawValue: "bubble.left.circle.fill")
    static let exclamationmark_bubble: FairSymbol = Self(rawValue: "exclamationmark.bubble")
    static let exclamationmark_bubble_fill: FairSymbol = Self(rawValue: "exclamationmark.bubble.fill")
    static let exclamationmark_bubble_circle: FairSymbol = Self(rawValue: "exclamationmark.bubble.circle")
    static let exclamationmark_bubble_circle_fill: FairSymbol = Self(rawValue: "exclamationmark.bubble.circle.fill")
    static let quote_opening: FairSymbol = Self(rawValue: "quote.opening")
    static let quote_closing: FairSymbol = Self(rawValue: "quote.closing")
    static let quote_bubble: FairSymbol = Self(rawValue: "quote.bubble")
    static let quote_bubble_fill: FairSymbol = Self(rawValue: "quote.bubble.fill")
    static let star_bubble: FairSymbol = Self(rawValue: "star.bubble")
    static let star_bubble_fill: FairSymbol = Self(rawValue: "star.bubble.fill")
    static let character_bubble: FairSymbol = Self(rawValue: "character.bubble")
    static let character_bubble_fill: FairSymbol = Self(rawValue: "character.bubble.fill")
    static let text_bubble: FairSymbol = Self(rawValue: "text.bubble")
    static let text_bubble_fill: FairSymbol = Self(rawValue: "text.bubble.fill")
    static let captions_bubble: FairSymbol = Self(rawValue: "captions.bubble")
    static let captions_bubble_fill: FairSymbol = Self(rawValue: "captions.bubble.fill")
    static let plus_bubble: FairSymbol = Self(rawValue: "plus.bubble")
    static let plus_bubble_fill: FairSymbol = Self(rawValue: "plus.bubble.fill")
    static let checkmark_bubble: FairSymbol = Self(rawValue: "checkmark.bubble")
    static let checkmark_bubble_fill: FairSymbol = Self(rawValue: "checkmark.bubble.fill")
    static let rectangle_3_group_bubble_left: FairSymbol = Self(rawValue: "rectangle.3.group.bubble.left")
    static let rectangle_3_group_bubble_left_fill: FairSymbol = Self(rawValue: "rectangle.3.group.bubble.left.fill")
    static let ellipsis_bubble: FairSymbol = Self(rawValue: "ellipsis.bubble")
    static let ellipsis_bubble_fill: FairSymbol = Self(rawValue: "ellipsis.bubble.fill")
    static let ellipsis_vertical_bubble: FairSymbol = Self(rawValue: "ellipsis.vertical.bubble")
    static let ellipsis_vertical_bubble_fill: FairSymbol = Self(rawValue: "ellipsis.vertical.bubble.fill")
    static let phone_bubble_left: FairSymbol = Self(rawValue: "phone.bubble.left")
    static let phone_bubble_left_fill: FairSymbol = Self(rawValue: "phone.bubble.left.fill")
    static let bubble_middle_bottom: FairSymbol = Self(rawValue: "bubble.middle.bottom")
    static let bubble_middle_bottom_fill: FairSymbol = Self(rawValue: "bubble.middle.bottom.fill")
    static let bubble_middle_top: FairSymbol = Self(rawValue: "bubble.middle.top")
    static let bubble_middle_top_fill: FairSymbol = Self(rawValue: "bubble.middle.top.fill")
    static let bubble_left_and_bubble_right: FairSymbol = Self(rawValue: "bubble.left.and.bubble.right")
    static let bubble_left_and_bubble_right_fill: FairSymbol = Self(rawValue: "bubble.left.and.bubble.right.fill")
    static let bubble_left_and_exclamationmark_bubble_right: FairSymbol = Self(rawValue: "bubble.left.and.exclamationmark.bubble.right")
    static let bubble_left_and_exclamationmark_bubble_right_fill: FairSymbol = Self(rawValue: "bubble.left.and.exclamationmark.bubble.right.fill")
    static let phone: FairSymbol = Self(rawValue: "phone")
    static let phone_fill: FairSymbol = Self(rawValue: "phone.fill")
    static let phone_circle: FairSymbol = Self(rawValue: "phone.circle")
    static let phone_circle_fill: FairSymbol = Self(rawValue: "phone.circle.fill")
    static let phone_badge_plus: FairSymbol = Self(rawValue: "phone.badge.plus")
    static let phone_fill_badge_plus: FairSymbol = Self(rawValue: "phone.fill.badge.plus")
    static let phone_connection: FairSymbol = Self(rawValue: "phone.connection")
    static let phone_fill_connection: FairSymbol = Self(rawValue: "phone.fill.connection")
    static let phone_and_waveform: FairSymbol = Self(rawValue: "phone.and.waveform")
    static let phone_and_waveform_fill: FairSymbol = Self(rawValue: "phone.and.waveform.fill")
    static let phone_arrow_up_right: FairSymbol = Self(rawValue: "phone.arrow.up.right")
    static let phone_fill_arrow_up_right: FairSymbol = Self(rawValue: "phone.fill.arrow.up.right")
    static let phone_arrow_down_left: FairSymbol = Self(rawValue: "phone.arrow.down.left")
    static let phone_fill_arrow_down_left: FairSymbol = Self(rawValue: "phone.fill.arrow.down.left")
    static let phone_arrow_right: FairSymbol = Self(rawValue: "phone.arrow.right")
    static let phone_fill_arrow_right: FairSymbol = Self(rawValue: "phone.fill.arrow.right")
    static let phone_down: FairSymbol = Self(rawValue: "phone.down")
    static let phone_down_fill: FairSymbol = Self(rawValue: "phone.down.fill")
    static let phone_down_circle: FairSymbol = Self(rawValue: "phone.down.circle")
    static let phone_down_circle_fill: FairSymbol = Self(rawValue: "phone.down.circle.fill")
    static let envelope: FairSymbol = Self(rawValue: "envelope")
    static let envelope_fill: FairSymbol = Self(rawValue: "envelope.fill")
    static let envelope_circle: FairSymbol = Self(rawValue: "envelope.circle")
    static let envelope_circle_fill: FairSymbol = Self(rawValue: "envelope.circle.fill")
    static let envelope_arrow_triangle_branch: FairSymbol = Self(rawValue: "envelope.arrow.triangle.branch")
    static let envelope_arrow_triangle_branch_fill: FairSymbol = Self(rawValue: "envelope.arrow.triangle.branch.fill")
    static let envelope_open: FairSymbol = Self(rawValue: "envelope.open")
    static let envelope_open_fill: FairSymbol = Self(rawValue: "envelope.open.fill")
    static let envelope_badge: FairSymbol = Self(rawValue: "envelope.badge")
    static let envelope_badge_fill: FairSymbol = Self(rawValue: "envelope.badge.fill")
    static let envelope_badge_shield_half_filled: FairSymbol = Self(rawValue: "envelope.badge.shield.half.filled")
    static let envelope_badge_shield_half_filled_fill: FairSymbol = Self(rawValue: "envelope.badge.shield.half.filled.fill")
    static let mail_stack: FairSymbol = Self(rawValue: "mail.stack")
    static let mail_stack_fill: FairSymbol = Self(rawValue: "mail.stack.fill")
    static let mail: FairSymbol = Self(rawValue: "mail")
    static let mail_fill: FairSymbol = Self(rawValue: "mail.fill")
    static let mail_and_text_magnifyingglass: FairSymbol = Self(rawValue: "mail.and.text.magnifyingglass")
    static let rectangle_and_text_magnifyingglass: FairSymbol = Self(rawValue: "rectangle.and.text.magnifyingglass")
    static let arrow_up_right_and_arrow_down_left_rectangle: FairSymbol = Self(rawValue: "arrow.up.right.and.arrow.down.left.rectangle")
    static let arrow_up_right_and_arrow_down_left_rectangle_fill: FairSymbol = Self(rawValue: "arrow.up.right.and.arrow.down.left.rectangle.fill")
    static let gear: FairSymbol = Self(rawValue: "gear")
    static let gear_circle: FairSymbol = Self(rawValue: "gear.circle")
    static let gear_circle_fill: FairSymbol = Self(rawValue: "gear.circle.fill")
    static let gear_badge_checkmark: FairSymbol = Self(rawValue: "gear.badge.checkmark")
    static let gear_badge_xmark: FairSymbol = Self(rawValue: "gear.badge.xmark")
    static let gear_badge_questionmark: FairSymbol = Self(rawValue: "gear.badge.questionmark")
    static let gearshape: FairSymbol = Self(rawValue: "gearshape")
    static let gearshape_fill: FairSymbol = Self(rawValue: "gearshape.fill")
    static let gearshape_circle: FairSymbol = Self(rawValue: "gearshape.circle")
    static let gearshape_circle_fill: FairSymbol = Self(rawValue: "gearshape.circle.fill")
    static let gearshape_2: FairSymbol = Self(rawValue: "gearshape.2")
    static let gearshape_2_fill: FairSymbol = Self(rawValue: "gearshape.2.fill")
    static let signature: FairSymbol = Self(rawValue: "signature")
    static let line_3_crossed_swirl_circle: FairSymbol = Self(rawValue: "line.3.crossed.swirl.circle")
    static let line_3_crossed_swirl_circle_fill: FairSymbol = Self(rawValue: "line.3.crossed.swirl.circle.fill")
    static let scissors: FairSymbol = Self(rawValue: "scissors")
    static let scissors_circle: FairSymbol = Self(rawValue: "scissors.circle")
    static let scissors_circle_fill: FairSymbol = Self(rawValue: "scissors.circle.fill")
    static let scissors_badge_ellipsis: FairSymbol = Self(rawValue: "scissors.badge.ellipsis")
    static let ellipsis: FairSymbol = Self(rawValue: "ellipsis")
    static let ellipsis_circle: FairSymbol = Self(rawValue: "ellipsis.circle")
    static let ellipsis_circle_fill: FairSymbol = Self(rawValue: "ellipsis.circle.fill")
    static let ellipsis_rectangle: FairSymbol = Self(rawValue: "ellipsis.rectangle")
    static let ellipsis_rectangle_fill: FairSymbol = Self(rawValue: "ellipsis.rectangle.fill")
    static let bag: FairSymbol = Self(rawValue: "bag")
    static let bag_fill: FairSymbol = Self(rawValue: "bag.fill")
    static let bag_circle: FairSymbol = Self(rawValue: "bag.circle")
    static let bag_circle_fill: FairSymbol = Self(rawValue: "bag.circle.fill")
    static let bag_badge_plus: FairSymbol = Self(rawValue: "bag.badge.plus")
    static let bag_fill_badge_plus: FairSymbol = Self(rawValue: "bag.fill.badge.plus")
    static let bag_badge_minus: FairSymbol = Self(rawValue: "bag.badge.minus")
    static let bag_fill_badge_minus: FairSymbol = Self(rawValue: "bag.fill.badge.minus")
    static let cart: FairSymbol = Self(rawValue: "cart")
    static let cart_fill: FairSymbol = Self(rawValue: "cart.fill")
    static let cart_circle: FairSymbol = Self(rawValue: "cart.circle")
    static let cart_circle_fill: FairSymbol = Self(rawValue: "cart.circle.fill")
    static let cart_badge_plus: FairSymbol = Self(rawValue: "cart.badge.plus")
    static let cart_fill_badge_plus: FairSymbol = Self(rawValue: "cart.fill.badge.plus")
    static let cart_badge_minus: FairSymbol = Self(rawValue: "cart.badge.minus")
    static let cart_fill_badge_minus: FairSymbol = Self(rawValue: "cart.fill.badge.minus")
    static let creditcard: FairSymbol = Self(rawValue: "creditcard")
    static let creditcard_fill: FairSymbol = Self(rawValue: "creditcard.fill")
    static let creditcard_circle: FairSymbol = Self(rawValue: "creditcard.circle")
    static let creditcard_circle_fill: FairSymbol = Self(rawValue: "creditcard.circle.fill")
    static let creditcard_and_123: FairSymbol = Self(rawValue: "creditcard.and.123")
    static let creditcard_trianglebadge_exclamationmark: FairSymbol = Self(rawValue: "creditcard.trianglebadge.exclamationmark")
    static let giftcard: FairSymbol = Self(rawValue: "giftcard")
    static let giftcard_fill: FairSymbol = Self(rawValue: "giftcard.fill")
    static let wallet_pass: FairSymbol = Self(rawValue: "wallet.pass")
    static let wallet_pass_fill: FairSymbol = Self(rawValue: "wallet.pass.fill")
    static let wand_and_rays: FairSymbol = Self(rawValue: "wand.and.rays")
    static let wand_and_rays_inverse: FairSymbol = Self(rawValue: "wand.and.rays.inverse")
    static let wand_and_stars: FairSymbol = Self(rawValue: "wand.and.stars")
    static let wand_and_stars_inverse: FairSymbol = Self(rawValue: "wand.and.stars.inverse")
    static let crop: FairSymbol = Self(rawValue: "crop")
    static let crop_rotate: FairSymbol = Self(rawValue: "crop.rotate")
    static let dial_min: FairSymbol = Self(rawValue: "dial.min")
    static let dial_min_fill: FairSymbol = Self(rawValue: "dial.min.fill")
    static let dial_max: FairSymbol = Self(rawValue: "dial.max")
    static let dial_max_fill: FairSymbol = Self(rawValue: "dial.max.fill")
    static let gyroscope: FairSymbol = Self(rawValue: "gyroscope")
    static let nosign: FairSymbol = Self(rawValue: "nosign")
    static let gauge: FairSymbol = Self(rawValue: "gauge")
    static let gauge_badge_plus: FairSymbol = Self(rawValue: "gauge.badge.plus")
    static let gauge_badge_minus: FairSymbol = Self(rawValue: "gauge.badge.minus")
    static let speedometer: FairSymbol = Self(rawValue: "speedometer")
    static let barometer: FairSymbol = Self(rawValue: "barometer")
    static let metronome: FairSymbol = Self(rawValue: "metronome")
    static let metronome_fill: FairSymbol = Self(rawValue: "metronome.fill")
    static let amplifier: FairSymbol = Self(rawValue: "amplifier")
    static let dice: FairSymbol = Self(rawValue: "dice")
    static let dice_fill: FairSymbol = Self(rawValue: "dice.fill")
    static let die_face_1: FairSymbol = Self(rawValue: "die.face.1")
    static let die_face_1_fill: FairSymbol = Self(rawValue: "die.face.1.fill")
    static let die_face_2: FairSymbol = Self(rawValue: "die.face.2")
    static let die_face_2_fill: FairSymbol = Self(rawValue: "die.face.2.fill")
    static let die_face_3: FairSymbol = Self(rawValue: "die.face.3")
    static let die_face_3_fill: FairSymbol = Self(rawValue: "die.face.3.fill")
    static let die_face_4: FairSymbol = Self(rawValue: "die.face.4")
    static let die_face_4_fill: FairSymbol = Self(rawValue: "die.face.4.fill")
    static let die_face_5: FairSymbol = Self(rawValue: "die.face.5")
    static let die_face_5_fill: FairSymbol = Self(rawValue: "die.face.5.fill")
    static let die_face_6: FairSymbol = Self(rawValue: "die.face.6")
    static let die_face_6_fill: FairSymbol = Self(rawValue: "die.face.6.fill")
    static let square_grid_3x3_square: FairSymbol = Self(rawValue: "square.grid.3x3.square")
    static let pianokeys: FairSymbol = Self(rawValue: "pianokeys")
    static let pianokeys_inverse: FairSymbol = Self(rawValue: "pianokeys.inverse")
    static let tuningfork: FairSymbol = Self(rawValue: "tuningfork")
    static let paintbrush: FairSymbol = Self(rawValue: "paintbrush")
    static let paintbrush_fill: FairSymbol = Self(rawValue: "paintbrush.fill")
    static let paintbrush_pointed: FairSymbol = Self(rawValue: "paintbrush.pointed")
    static let paintbrush_pointed_fill: FairSymbol = Self(rawValue: "paintbrush.pointed.fill")
    static let bandage: FairSymbol = Self(rawValue: "bandage")
    static let bandage_fill: FairSymbol = Self(rawValue: "bandage.fill")
    static let ruler: FairSymbol = Self(rawValue: "ruler")
    static let ruler_fill: FairSymbol = Self(rawValue: "ruler.fill")
    static let level: FairSymbol = Self(rawValue: "level")
    static let level_fill: FairSymbol = Self(rawValue: "level.fill")
    static let lines_measurement_horizontal: FairSymbol = Self(rawValue: "lines.measurement.horizontal")
    static let wrench: FairSymbol = Self(rawValue: "wrench")
    static let wrench_fill: FairSymbol = Self(rawValue: "wrench.fill")
    static let hammer: FairSymbol = Self(rawValue: "hammer")
    static let hammer_fill: FairSymbol = Self(rawValue: "hammer.fill")
    static let hammer_circle: FairSymbol = Self(rawValue: "hammer.circle")
    static let hammer_circle_fill: FairSymbol = Self(rawValue: "hammer.circle.fill")
    static let screwdriver: FairSymbol = Self(rawValue: "screwdriver")
    static let screwdriver_fill: FairSymbol = Self(rawValue: "screwdriver.fill")
    static let eyedropper: FairSymbol = Self(rawValue: "eyedropper")
    static let eyedropper_halffull: FairSymbol = Self(rawValue: "eyedropper.halffull")
    static let eyedropper_full: FairSymbol = Self(rawValue: "eyedropper.full")
    static let wrench_and_screwdriver: FairSymbol = Self(rawValue: "wrench.and.screwdriver")
    static let wrench_and_screwdriver_fill: FairSymbol = Self(rawValue: "wrench.and.screwdriver.fill")
    static let scroll: FairSymbol = Self(rawValue: "scroll")
    static let scroll_fill: FairSymbol = Self(rawValue: "scroll.fill")
    static let stethoscope: FairSymbol = Self(rawValue: "stethoscope")
    static let stethoscope_circle: FairSymbol = Self(rawValue: "stethoscope.circle")
    static let stethoscope_circle_fill: FairSymbol = Self(rawValue: "stethoscope.circle.fill")
    static let printer: FairSymbol = Self(rawValue: "printer")
    static let printer_fill: FairSymbol = Self(rawValue: "printer.fill")
    static let printer_filled_and_paper: FairSymbol = Self(rawValue: "printer.filled.and.paper")
    static let printer_dotmatrix: FairSymbol = Self(rawValue: "printer.dotmatrix")
    static let printer_dotmatrix_fill: FairSymbol = Self(rawValue: "printer.dotmatrix.fill")
    static let printer_dotmatrix_filled_and_paper: FairSymbol = Self(rawValue: "printer.dotmatrix.filled.and.paper")
    static let scanner: FairSymbol = Self(rawValue: "scanner")
    static let scanner_fill: FairSymbol = Self(rawValue: "scanner.fill")
    static let faxmachine: FairSymbol = Self(rawValue: "faxmachine")
    static let briefcase: FairSymbol = Self(rawValue: "briefcase")
    static let briefcase_fill: FairSymbol = Self(rawValue: "briefcase.fill")
    static let briefcase_circle: FairSymbol = Self(rawValue: "briefcase.circle")
    static let briefcase_circle_fill: FairSymbol = Self(rawValue: "briefcase.circle.fill")
    static let `case`: FairSymbol = Self(rawValue: "`")
    static let case_fill: FairSymbol = Self(rawValue: "case.fill")
    static let latch_2_case: FairSymbol = Self(rawValue: "latch.2.case")
    static let latch_2_case_fill: FairSymbol = Self(rawValue: "latch.2.case.fill")
    static let cross_case: FairSymbol = Self(rawValue: "cross.case")
    static let cross_case_fill: FairSymbol = Self(rawValue: "cross.case.fill")
    static let suitcase: FairSymbol = Self(rawValue: "suitcase")
    static let suitcase_fill: FairSymbol = Self(rawValue: "suitcase.fill")
    static let suitcase_cart: FairSymbol = Self(rawValue: "suitcase.cart")
    static let suitcase_cart_fill: FairSymbol = Self(rawValue: "suitcase.cart.fill")
    static let theatermasks: FairSymbol = Self(rawValue: "theatermasks")
    static let theatermasks_fill: FairSymbol = Self(rawValue: "theatermasks.fill")
    static let theatermasks_circle: FairSymbol = Self(rawValue: "theatermasks.circle")
    static let theatermasks_circle_fill: FairSymbol = Self(rawValue: "theatermasks.circle.fill")
    static let puzzlepiece_extension: FairSymbol = Self(rawValue: "puzzlepiece.extension")
    static let puzzlepiece_extension_fill: FairSymbol = Self(rawValue: "puzzlepiece.extension.fill")
    static let puzzlepiece: FairSymbol = Self(rawValue: "puzzlepiece")
    static let puzzlepiece_fill: FairSymbol = Self(rawValue: "puzzlepiece.fill")
    static let house: FairSymbol = Self(rawValue: "house")
    static let house_fill: FairSymbol = Self(rawValue: "house.fill")
    static let house_circle: FairSymbol = Self(rawValue: "house.circle")
    static let house_circle_fill: FairSymbol = Self(rawValue: "house.circle.fill")
    static let music_note_house: FairSymbol = Self(rawValue: "music.note.house")
    static let music_note_house_fill: FairSymbol = Self(rawValue: "music.note.house.fill")
    static let building_columns: FairSymbol = Self(rawValue: "building.columns")
    static let building_columns_fill: FairSymbol = Self(rawValue: "building.columns.fill")
    static let building_columns_circle: FairSymbol = Self(rawValue: "building.columns.circle")
    static let building_columns_circle_fill: FairSymbol = Self(rawValue: "building.columns.circle.fill")
    static let signpost_left: FairSymbol = Self(rawValue: "signpost.left")
    static let signpost_left_fill: FairSymbol = Self(rawValue: "signpost.left.fill")
    static let signpost_right: FairSymbol = Self(rawValue: "signpost.right")
    static let signpost_right_fill: FairSymbol = Self(rawValue: "signpost.right.fill")
    static let square_split_bottomrightquarter: FairSymbol = Self(rawValue: "square.split.bottomrightquarter")
    static let square_split_bottomrightquarter_fill: FairSymbol = Self(rawValue: "square.split.bottomrightquarter.fill")
    static let building: FairSymbol = Self(rawValue: "building")
    static let building_fill: FairSymbol = Self(rawValue: "building.fill")
    static let building_2: FairSymbol = Self(rawValue: "building.2")
    static let building_2_fill: FairSymbol = Self(rawValue: "building.2.fill")
    static let building_2_crop_circle: FairSymbol = Self(rawValue: "building.2.crop.circle")
    static let building_2_crop_circle_fill: FairSymbol = Self(rawValue: "building.2.crop.circle.fill")
    static let lock: FairSymbol = Self(rawValue: "lock")
    static let lock_fill: FairSymbol = Self(rawValue: "lock.fill")
    static let lock_circle: FairSymbol = Self(rawValue: "lock.circle")
    static let lock_circle_fill: FairSymbol = Self(rawValue: "lock.circle.fill")
    static let lock_square: FairSymbol = Self(rawValue: "lock.square")
    static let lock_square_fill: FairSymbol = Self(rawValue: "lock.square.fill")
    static let lock_square_stack: FairSymbol = Self(rawValue: "lock.square.stack")
    static let lock_square_stack_fill: FairSymbol = Self(rawValue: "lock.square.stack.fill")
    static let lock_rectangle: FairSymbol = Self(rawValue: "lock.rectangle")
    static let lock_rectangle_fill: FairSymbol = Self(rawValue: "lock.rectangle.fill")
    static let lock_rectangle_stack: FairSymbol = Self(rawValue: "lock.rectangle.stack")
    static let lock_rectangle_stack_fill: FairSymbol = Self(rawValue: "lock.rectangle.stack.fill")
    static let lock_rectangle_on_rectangle: FairSymbol = Self(rawValue: "lock.rectangle.on.rectangle")
    static let lock_rectangle_on_rectangle_fill: FairSymbol = Self(rawValue: "lock.rectangle.on.rectangle.fill")
    static let lock_shield: FairSymbol = Self(rawValue: "lock.shield")
    static let lock_shield_fill: FairSymbol = Self(rawValue: "lock.shield.fill")
    static let lock_slash: FairSymbol = Self(rawValue: "lock.slash")
    static let lock_slash_fill: FairSymbol = Self(rawValue: "lock.slash.fill")
    static let lock_open: FairSymbol = Self(rawValue: "lock.open")
    static let lock_open_fill: FairSymbol = Self(rawValue: "lock.open.fill")
    static let lock_rotation: FairSymbol = Self(rawValue: "lock.rotation")
    static let lock_rotation_open: FairSymbol = Self(rawValue: "lock.rotation.open")
    static let key: FairSymbol = Self(rawValue: "key")
    static let key_fill: FairSymbol = Self(rawValue: "key.fill")
    static let wifi: FairSymbol = Self(rawValue: "wifi")
    static let wifi_circle: FairSymbol = Self(rawValue: "wifi.circle")
    static let wifi_circle_fill: FairSymbol = Self(rawValue: "wifi.circle.fill")
    static let wifi_square: FairSymbol = Self(rawValue: "wifi.square")
    static let wifi_square_fill: FairSymbol = Self(rawValue: "wifi.square.fill")
    static let wifi_slash: FairSymbol = Self(rawValue: "wifi.slash")
    static let wifi_exclamationmark: FairSymbol = Self(rawValue: "wifi.exclamationmark")
    static let pin: FairSymbol = Self(rawValue: "pin")
    static let pin_fill: FairSymbol = Self(rawValue: "pin.fill")
    static let pin_circle: FairSymbol = Self(rawValue: "pin.circle")
    static let pin_circle_fill: FairSymbol = Self(rawValue: "pin.circle.fill")
    static let pin_square: FairSymbol = Self(rawValue: "pin.square")
    static let pin_square_fill: FairSymbol = Self(rawValue: "pin.square.fill")
    static let pin_slash: FairSymbol = Self(rawValue: "pin.slash")
    static let pin_slash_fill: FairSymbol = Self(rawValue: "pin.slash.fill")
    static let mappin: FairSymbol = Self(rawValue: "mappin")
    static let mappin_circle: FairSymbol = Self(rawValue: "mappin.circle")
    static let mappin_circle_fill: FairSymbol = Self(rawValue: "mappin.circle.fill")
    static let mappin_square: FairSymbol = Self(rawValue: "mappin.square")
    static let mappin_square_fill: FairSymbol = Self(rawValue: "mappin.square.fill")
    static let mappin_slash: FairSymbol = Self(rawValue: "mappin.slash")
    static let mappin_slash_circle: FairSymbol = Self(rawValue: "mappin.slash.circle")
    static let mappin_slash_circle_fill: FairSymbol = Self(rawValue: "mappin.slash.circle.fill")
    static let mappin_and_ellipse: FairSymbol = Self(rawValue: "mappin.and.ellipse")
    static let map: FairSymbol = Self(rawValue: "map")
    static let map_fill: FairSymbol = Self(rawValue: "map.fill")
    static let map_circle: FairSymbol = Self(rawValue: "map.circle")
    static let map_circle_fill: FairSymbol = Self(rawValue: "map.circle.fill")
    static let move_3d: FairSymbol = Self(rawValue: "move.3d")
    static let scale_3d: FairSymbol = Self(rawValue: "scale.3d")
    static let rotate_3d: FairSymbol = Self(rawValue: "rotate.3d")
    static let torus: FairSymbol = Self(rawValue: "torus")
    static let rotate_left: FairSymbol = Self(rawValue: "rotate.left")
    static let rotate_left_fill: FairSymbol = Self(rawValue: "rotate.left.fill")
    static let rotate_right: FairSymbol = Self(rawValue: "rotate.right")
    static let rotate_right_fill: FairSymbol = Self(rawValue: "rotate.right.fill")
    static let selection_pin_in_out: FairSymbol = Self(rawValue: "selection.pin.in.out")
    static let powerplug: FairSymbol = Self(rawValue: "powerplug")
    static let powerplug_fill: FairSymbol = Self(rawValue: "powerplug.fill")
    static let timeline_selection: FairSymbol = Self(rawValue: "timeline.selection")
    static let cpu: FairSymbol = Self(rawValue: "cpu")
    static let cpu_fill: FairSymbol = Self(rawValue: "cpu.fill")
    static let memorychip: FairSymbol = Self(rawValue: "memorychip")
    static let memorychip_fill: FairSymbol = Self(rawValue: "memorychip.fill")
    static let opticaldisc: FairSymbol = Self(rawValue: "opticaldisc")
    static let display: FairSymbol = Self(rawValue: "display")
    static let lock_display: FairSymbol = Self(rawValue: "lock.display")
    static let lock_open_display: FairSymbol = Self(rawValue: "lock.open.display")
    static let display_and_arrow_down: FairSymbol = Self(rawValue: "display.and.arrow.down")
    static let display_trianglebadge_exclamationmark: FairSymbol = Self(rawValue: "display.trianglebadge.exclamationmark")
    static let display_2: FairSymbol = Self(rawValue: "display.2")
    static let desktopcomputer: FairSymbol = Self(rawValue: "desktopcomputer")
    static let lock_desktopcomputer: FairSymbol = Self(rawValue: "lock.desktopcomputer")
    static let lock_open_desktopcomputer: FairSymbol = Self(rawValue: "lock.open.desktopcomputer")
    static let desktopcomputer_and_arrow_down: FairSymbol = Self(rawValue: "desktopcomputer.and.arrow.down")
    static let desktopcomputer_trianglebadge_exclamationmark: FairSymbol = Self(rawValue: "desktopcomputer.trianglebadge.exclamationmark")
    static let pc: FairSymbol = Self(rawValue: "pc")
    static let server_rack: FairSymbol = Self(rawValue: "server.rack")
    static let laptopcomputer: FairSymbol = Self(rawValue: "laptopcomputer")
    static let lock_laptopcomputer: FairSymbol = Self(rawValue: "lock.laptopcomputer")
    static let lock_open_laptopcomputer: FairSymbol = Self(rawValue: "lock.open.laptopcomputer")
    static let laptopcomputer_and_arrow_down: FairSymbol = Self(rawValue: "laptopcomputer.and.arrow.down")
    static let laptopcomputer_trianglebadge_exclamationmark: FairSymbol = Self(rawValue: "laptopcomputer.trianglebadge.exclamationmark")
    static let flipphone: FairSymbol = Self(rawValue: "flipphone")
    static let candybarphone: FairSymbol = Self(rawValue: "candybarphone")
    static let lock_iphone: FairSymbol = Self(rawValue: "lock.iphone")
    static let lock_open_iphone: FairSymbol = Self(rawValue: "lock.open.iphone")
    static let iphone_and_arrow_forward: FairSymbol = Self(rawValue: "iphone.and.arrow.forward")
    static let arrow_turn_up_forward_iphone: FairSymbol = Self(rawValue: "arrow.turn.up.forward.iphone")
    static let arrow_turn_up_forward_iphone_fill: FairSymbol = Self(rawValue: "arrow.turn.up.forward.iphone.fill")
    static let iphone_rear_camera: FairSymbol = Self(rawValue: "iphone.rear.camera")
    static let platter_filled_top_iphone: FairSymbol = Self(rawValue: "platter.filled.top.iphone")
    static let platter_filled_bottom_iphone: FairSymbol = Self(rawValue: "platter.filled.bottom.iphone")
    static let platter_filled_top_and_arrow_up_iphone: FairSymbol = Self(rawValue: "platter.filled.top.and.arrow.up.iphone")
    static let platter_filled_bottom_and_arrow_down_iphone: FairSymbol = Self(rawValue: "platter.filled.bottom.and.arrow.down.iphone")
    static let platter_2_filled_iphone: FairSymbol = Self(rawValue: "platter.2.filled.iphone")
    static let platter_2_filled_iphone_landscape: FairSymbol = Self(rawValue: "platter.2.filled.iphone.landscape")
    static let lock_ipad: FairSymbol = Self(rawValue: "lock.ipad")
    static let lock_open_ipad: FairSymbol = Self(rawValue: "lock.open.ipad")
    static let ipad_and_arrow_forward: FairSymbol = Self(rawValue: "ipad.and.arrow.forward")
    static let ipad_rear_camera: FairSymbol = Self(rawValue: "ipad.rear.camera")
    static let platter_2_filled_ipad: FairSymbol = Self(rawValue: "platter.2.filled.ipad")
    static let platter_2_filled_ipad_landscape: FairSymbol = Self(rawValue: "platter.2.filled.ipad.landscape")
    static let computermouse: FairSymbol = Self(rawValue: "computermouse")
    static let computermouse_fill: FairSymbol = Self(rawValue: "computermouse.fill")
    static let headphones: FairSymbol = Self(rawValue: "headphones")
    static let headphones_circle: FairSymbol = Self(rawValue: "headphones.circle")
    static let headphones_circle_fill: FairSymbol = Self(rawValue: "headphones.circle.fill")
    static let earbuds: FairSymbol = Self(rawValue: "earbuds")
    static let earbuds_case: FairSymbol = Self(rawValue: "earbuds.case")
    static let earbuds_case_fill: FairSymbol = Self(rawValue: "earbuds.case.fill")
    static let hifispeaker: FairSymbol = Self(rawValue: "hifispeaker")
    static let hifispeaker_fill: FairSymbol = Self(rawValue: "hifispeaker.fill")
    static let hifispeaker_2: FairSymbol = Self(rawValue: "hifispeaker.2")
    static let hifispeaker_2_fill: FairSymbol = Self(rawValue: "hifispeaker.2.fill")
    static let mediastick: FairSymbol = Self(rawValue: "mediastick")
    static let cable_connector: FairSymbol = Self(rawValue: "cable.connector")
    static let cable_connector_horizontal: FairSymbol = Self(rawValue: "cable.connector.horizontal")
    static let radio: FairSymbol = Self(rawValue: "radio")
    static let radio_fill: FairSymbol = Self(rawValue: "radio.fill")
    static let tv: FairSymbol = Self(rawValue: "tv")
    static let tv_fill: FairSymbol = Self(rawValue: "tv.fill")
    static let tv_inset_filled: FairSymbol = Self(rawValue: "tv.inset.filled")
    static let tv_circle: FairSymbol = Self(rawValue: "tv.circle")
    static let tv_circle_fill: FairSymbol = Self(rawValue: "tv.circle.fill")
    static let sparkles_tv: FairSymbol = Self(rawValue: "sparkles.tv")
    static let sparkles_tv_fill: FairSymbol = Self(rawValue: "sparkles.tv.fill")
    static let N4k_tv: FairSymbol = Self(rawValue: "4k.tv")
    static let N4k_tv_fill: FairSymbol = Self(rawValue: "4k.tv.fill")
    static let music_note_tv: FairSymbol = Self(rawValue: "music.note.tv")
    static let music_note_tv_fill: FairSymbol = Self(rawValue: "music.note.tv.fill")
    static let play_tv: FairSymbol = Self(rawValue: "play.tv")
    static let play_tv_fill: FairSymbol = Self(rawValue: "play.tv.fill")
    static let photo_tv: FairSymbol = Self(rawValue: "photo.tv")
    static let tv_and_hifispeaker_fill: FairSymbol = Self(rawValue: "tv.and.hifispeaker.fill")
    static let tv_and_mediabox: FairSymbol = Self(rawValue: "tv.and.mediabox")
    static let dot_radiowaves_left_and_right: FairSymbol = Self(rawValue: "dot.radiowaves.left.and.right")
    static let dot_radiowaves_right: FairSymbol = Self(rawValue: "dot.radiowaves.right")
    static let dot_radiowaves_forward: FairSymbol = Self(rawValue: "dot.radiowaves.forward")
    static let wave_3_left: FairSymbol = Self(rawValue: "wave.3.left")
    static let wave_3_left_circle: FairSymbol = Self(rawValue: "wave.3.left.circle")
    static let wave_3_left_circle_fill: FairSymbol = Self(rawValue: "wave.3.left.circle.fill")
    static let wave_3_backward: FairSymbol = Self(rawValue: "wave.3.backward")
    static let wave_3_backward_circle: FairSymbol = Self(rawValue: "wave.3.backward.circle")
    static let wave_3_backward_circle_fill: FairSymbol = Self(rawValue: "wave.3.backward.circle.fill")
    static let wave_3_right: FairSymbol = Self(rawValue: "wave.3.right")
    static let wave_3_right_circle: FairSymbol = Self(rawValue: "wave.3.right.circle")
    static let wave_3_right_circle_fill: FairSymbol = Self(rawValue: "wave.3.right.circle.fill")
    static let wave_3_forward: FairSymbol = Self(rawValue: "wave.3.forward")
    static let wave_3_forward_circle: FairSymbol = Self(rawValue: "wave.3.forward.circle")
    static let wave_3_forward_circle_fill: FairSymbol = Self(rawValue: "wave.3.forward.circle.fill")
    static let dot_radiowaves_up_forward: FairSymbol = Self(rawValue: "dot.radiowaves.up.forward")
    static let antenna_radiowaves_left_and_right: FairSymbol = Self(rawValue: "antenna.radiowaves.left.and.right")
    static let antenna_radiowaves_left_and_right_slash: FairSymbol = Self(rawValue: "antenna.radiowaves.left.and.right.slash")
    static let antenna_radiowaves_left_and_right_circle: FairSymbol = Self(rawValue: "antenna.radiowaves.left.and.right.circle")
    static let antenna_radiowaves_left_and_right_circle_fill: FairSymbol = Self(rawValue: "antenna.radiowaves.left.and.right.circle.fill")
    static let pip: FairSymbol = Self(rawValue: "pip")
    static let pip_fill: FairSymbol = Self(rawValue: "pip.fill")
    static let pip_exit: FairSymbol = Self(rawValue: "pip.exit")
    static let pip_enter: FairSymbol = Self(rawValue: "pip.enter")
    static let pip_swap: FairSymbol = Self(rawValue: "pip.swap")
    static let pip_remove: FairSymbol = Self(rawValue: "pip.remove")
    static let rectangle_arrowtriangle_2_outward: FairSymbol = Self(rawValue: "rectangle.arrowtriangle.2.outward")
    static let rectangle_arrowtriangle_2_inward: FairSymbol = Self(rawValue: "rectangle.arrowtriangle.2.inward")
    static let rectangle_portrait_arrowtriangle_2_outward: FairSymbol = Self(rawValue: "rectangle.portrait.arrowtriangle.2.outward")
    static let rectangle_portrait_arrowtriangle_2_inward: FairSymbol = Self(rawValue: "rectangle.portrait.arrowtriangle.2.inward")
    static let rectangle_2_swap: FairSymbol = Self(rawValue: "rectangle.2.swap")
    static let guitars: FairSymbol = Self(rawValue: "guitars")
    static let guitars_fill: FairSymbol = Self(rawValue: "guitars.fill")
    static let airplane: FairSymbol = Self(rawValue: "airplane")
    static let airplane_circle: FairSymbol = Self(rawValue: "airplane.circle")
    static let airplane_circle_fill: FairSymbol = Self(rawValue: "airplane.circle.fill")
    static let airplane_arrival: FairSymbol = Self(rawValue: "airplane.arrival")
    static let airplane_departure: FairSymbol = Self(rawValue: "airplane.departure")
    static let car: FairSymbol = Self(rawValue: "car")
    static let car_fill: FairSymbol = Self(rawValue: "car.fill")
    static let car_circle: FairSymbol = Self(rawValue: "car.circle")
    static let car_circle_fill: FairSymbol = Self(rawValue: "car.circle.fill")
    static let bolt_car: FairSymbol = Self(rawValue: "bolt.car")
    static let bolt_car_fill: FairSymbol = Self(rawValue: "bolt.car.fill")
    static let bolt_car_circle: FairSymbol = Self(rawValue: "bolt.car.circle")
    static let bolt_car_circle_fill: FairSymbol = Self(rawValue: "bolt.car.circle.fill")
    static let car_2: FairSymbol = Self(rawValue: "car.2")
    static let car_2_fill: FairSymbol = Self(rawValue: "car.2.fill")
    static let bus: FairSymbol = Self(rawValue: "bus")
    static let bus_fill: FairSymbol = Self(rawValue: "bus.fill")
    static let bus_doubledecker: FairSymbol = Self(rawValue: "bus.doubledecker")
    static let bus_doubledecker_fill: FairSymbol = Self(rawValue: "bus.doubledecker.fill")
    static let tram: FairSymbol = Self(rawValue: "tram")
    static let tram_fill: FairSymbol = Self(rawValue: "tram.fill")
    static let tram_circle: FairSymbol = Self(rawValue: "tram.circle")
    static let tram_circle_fill: FairSymbol = Self(rawValue: "tram.circle.fill")
    static let tram_fill_tunnel: FairSymbol = Self(rawValue: "tram.fill.tunnel")
    static let cablecar: FairSymbol = Self(rawValue: "cablecar")
    static let cablecar_fill: FairSymbol = Self(rawValue: "cablecar.fill")
    static let ferry: FairSymbol = Self(rawValue: "ferry")
    static let ferry_fill: FairSymbol = Self(rawValue: "ferry.fill")
    static let car_ferry: FairSymbol = Self(rawValue: "car.ferry")
    static let car_ferry_fill: FairSymbol = Self(rawValue: "car.ferry.fill")
    static let train_side_front_car: FairSymbol = Self(rawValue: "train.side.front.car")
    static let train_side_middle_car: FairSymbol = Self(rawValue: "train.side.middle.car")
    static let train_side_rear_car: FairSymbol = Self(rawValue: "train.side.rear.car")
    static let bicycle: FairSymbol = Self(rawValue: "bicycle")
    static let bicycle_circle: FairSymbol = Self(rawValue: "bicycle.circle")
    static let bicycle_circle_fill: FairSymbol = Self(rawValue: "bicycle.circle.fill")
    static let scooter: FairSymbol = Self(rawValue: "scooter")
    static let parkingsign: FairSymbol = Self(rawValue: "parkingsign")
    static let parkingsign_circle: FairSymbol = Self(rawValue: "parkingsign.circle")
    static let parkingsign_circle_fill: FairSymbol = Self(rawValue: "parkingsign.circle.fill")
    static let fuelpump: FairSymbol = Self(rawValue: "fuelpump")
    static let fuelpump_fill: FairSymbol = Self(rawValue: "fuelpump.fill")
    static let fuelpump_circle: FairSymbol = Self(rawValue: "fuelpump.circle")
    static let fuelpump_circle_fill: FairSymbol = Self(rawValue: "fuelpump.circle.fill")
    static let fanblades: FairSymbol = Self(rawValue: "fanblades")
    static let fanblades_fill: FairSymbol = Self(rawValue: "fanblades.fill")
    static let bed_double: FairSymbol = Self(rawValue: "bed.double")
    static let bed_double_fill: FairSymbol = Self(rawValue: "bed.double.fill")
    static let bed_double_circle: FairSymbol = Self(rawValue: "bed.double.circle")
    static let bed_double_circle_fill: FairSymbol = Self(rawValue: "bed.double.circle.fill")
    static let lungs: FairSymbol = Self(rawValue: "lungs")
    static let lungs_fill: FairSymbol = Self(rawValue: "lungs.fill")
    static let allergens: FairSymbol = Self(rawValue: "allergens")
    static let pills: FairSymbol = Self(rawValue: "pills")
    static let pills_fill: FairSymbol = Self(rawValue: "pills.fill")
    static let pills_circle: FairSymbol = Self(rawValue: "pills.circle")
    static let pills_circle_fill: FairSymbol = Self(rawValue: "pills.circle.fill")
    static let testtube_2: FairSymbol = Self(rawValue: "testtube.2")
    static let ivfluid_bag: FairSymbol = Self(rawValue: "ivfluid.bag")
    static let ivfluid_bag_fill: FairSymbol = Self(rawValue: "ivfluid.bag.fill")
    static let cross_vial: FairSymbol = Self(rawValue: "cross.vial")
    static let cross_vial_fill: FairSymbol = Self(rawValue: "cross.vial.fill")
    static let cross: FairSymbol = Self(rawValue: "cross")
    static let cross_fill: FairSymbol = Self(rawValue: "cross.fill")
    static let cross_circle: FairSymbol = Self(rawValue: "cross.circle")
    static let cross_circle_fill: FairSymbol = Self(rawValue: "cross.circle.fill")
    static let hare: FairSymbol = Self(rawValue: "hare")
    static let hare_fill: FairSymbol = Self(rawValue: "hare.fill")
    static let tortoise: FairSymbol = Self(rawValue: "tortoise")
    static let tortoise_fill: FairSymbol = Self(rawValue: "tortoise.fill")
    static let pawprint: FairSymbol = Self(rawValue: "pawprint")
    static let pawprint_fill: FairSymbol = Self(rawValue: "pawprint.fill")
    static let pawprint_circle: FairSymbol = Self(rawValue: "pawprint.circle")
    static let pawprint_circle_fill: FairSymbol = Self(rawValue: "pawprint.circle.fill")
    static let ant: FairSymbol = Self(rawValue: "ant")
    static let ant_fill: FairSymbol = Self(rawValue: "ant.fill")
    static let ant_circle: FairSymbol = Self(rawValue: "ant.circle")
    static let ant_circle_fill: FairSymbol = Self(rawValue: "ant.circle.fill")
    static let ladybug: FairSymbol = Self(rawValue: "ladybug")
    static let ladybug_fill: FairSymbol = Self(rawValue: "ladybug.fill")
    static let leaf: FairSymbol = Self(rawValue: "leaf")
    static let leaf_fill: FairSymbol = Self(rawValue: "leaf.fill")
    static let leaf_circle: FairSymbol = Self(rawValue: "leaf.circle")
    static let leaf_circle_fill: FairSymbol = Self(rawValue: "leaf.circle.fill")
    static let leaf_arrow_triangle_circlepath: FairSymbol = Self(rawValue: "leaf.arrow.triangle.circlepath")
    static let film: FairSymbol = Self(rawValue: "film")
    static let film_fill: FairSymbol = Self(rawValue: "film.fill")
    static let film_circle: FairSymbol = Self(rawValue: "film.circle")
    static let film_circle_fill: FairSymbol = Self(rawValue: "film.circle.fill")
    static let sportscourt: FairSymbol = Self(rawValue: "sportscourt")
    static let sportscourt_fill: FairSymbol = Self(rawValue: "sportscourt.fill")
    static let face_smiling: FairSymbol = Self(rawValue: "face.smiling")
    static let face_smiling_fill: FairSymbol = Self(rawValue: "face.smiling.fill")
    static let face_dashed: FairSymbol = Self(rawValue: "face.dashed")
    static let face_dashed_fill: FairSymbol = Self(rawValue: "face.dashed.fill")
    static let crown: FairSymbol = Self(rawValue: "crown")
    static let crown_fill: FairSymbol = Self(rawValue: "crown.fill")
    static let comb: FairSymbol = Self(rawValue: "comb")
    static let comb_fill: FairSymbol = Self(rawValue: "comb.fill")
    static let qrcode: FairSymbol = Self(rawValue: "qrcode")
    static let barcode: FairSymbol = Self(rawValue: "barcode")
    static let viewfinder: FairSymbol = Self(rawValue: "viewfinder")
    static let viewfinder_circle: FairSymbol = Self(rawValue: "viewfinder.circle")
    static let viewfinder_circle_fill: FairSymbol = Self(rawValue: "viewfinder.circle.fill")
    static let barcode_viewfinder: FairSymbol = Self(rawValue: "barcode.viewfinder")
    static let qrcode_viewfinder: FairSymbol = Self(rawValue: "qrcode.viewfinder")
    static let plus_viewfinder: FairSymbol = Self(rawValue: "plus.viewfinder")
    static let camera_viewfinder: FairSymbol = Self(rawValue: "camera.viewfinder")
    static let doc_viewfinder: FairSymbol = Self(rawValue: "doc.viewfinder")
    static let doc_viewfinder_fill: FairSymbol = Self(rawValue: "doc.viewfinder.fill")
    static let location_viewfinder: FairSymbol = Self(rawValue: "location.viewfinder")
    static let location_fill_viewfinder: FairSymbol = Self(rawValue: "location.fill.viewfinder")
    static let person_fill_viewfinder: FairSymbol = Self(rawValue: "person.fill.viewfinder")
    static let text_viewfinder: FairSymbol = Self(rawValue: "text.viewfinder")
    static let dot_viewfinder: FairSymbol = Self(rawValue: "dot.viewfinder")
    static let dot_circle_viewfinder: FairSymbol = Self(rawValue: "dot.circle.viewfinder")
    static let photo: FairSymbol = Self(rawValue: "photo")
    static let photo_fill: FairSymbol = Self(rawValue: "photo.fill")
    static let photo_circle: FairSymbol = Self(rawValue: "photo.circle")
    static let photo_circle_fill: FairSymbol = Self(rawValue: "photo.circle.fill")
    static let text_below_photo: FairSymbol = Self(rawValue: "text.below.photo")
    static let text_below_photo_fill: FairSymbol = Self(rawValue: "text.below.photo.fill")
    static let checkerboard_rectangle: FairSymbol = Self(rawValue: "checkerboard.rectangle")
    static let camera_metering_center_weighted_average: FairSymbol = Self(rawValue: "camera.metering.center.weighted.average")
    static let camera_metering_center_weighted: FairSymbol = Self(rawValue: "camera.metering.center.weighted")
    static let camera_metering_matrix: FairSymbol = Self(rawValue: "camera.metering.matrix")
    static let camera_metering_multispot: FairSymbol = Self(rawValue: "camera.metering.multispot")
    static let camera_metering_none: FairSymbol = Self(rawValue: "camera.metering.none")
    static let camera_metering_partial: FairSymbol = Self(rawValue: "camera.metering.partial")
    static let camera_metering_spot: FairSymbol = Self(rawValue: "camera.metering.spot")
    static let camera_metering_unknown: FairSymbol = Self(rawValue: "camera.metering.unknown")
    static let camera_aperture: FairSymbol = Self(rawValue: "camera.aperture")
    static let rectangle_dashed: FairSymbol = Self(rawValue: "rectangle.dashed")
    static let rectangle_dashed_badge_record: FairSymbol = Self(rawValue: "rectangle.dashed.badge.record")
    static let rectangle_badge_plus: FairSymbol = Self(rawValue: "rectangle.badge.plus")
    static let rectangle_fill_badge_plus: FairSymbol = Self(rawValue: "rectangle.fill.badge.plus")
    static let rectangle_badge_minus: FairSymbol = Self(rawValue: "rectangle.badge.minus")
    static let rectangle_fill_badge_minus: FairSymbol = Self(rawValue: "rectangle.fill.badge.minus")
    static let rectangle_badge_checkmark: FairSymbol = Self(rawValue: "rectangle.badge.checkmark")
    static let rectangle_fill_badge_checkmark: FairSymbol = Self(rawValue: "rectangle.fill.badge.checkmark")
    static let rectangle_badge_xmark: FairSymbol = Self(rawValue: "rectangle.badge.xmark")
    static let rectangle_fill_badge_xmark: FairSymbol = Self(rawValue: "rectangle.fill.badge.xmark")
    static let rectangle_badge_person_crop: FairSymbol = Self(rawValue: "rectangle.badge.person.crop")
    static let rectangle_fill_badge_person_crop: FairSymbol = Self(rawValue: "rectangle.fill.badge.person.crop")
    static let photo_on_rectangle: FairSymbol = Self(rawValue: "photo.on.rectangle")
    static let photo_fill_on_rectangle_fill: FairSymbol = Self(rawValue: "photo.fill.on.rectangle.fill")
    static let rectangle_on_rectangle_angled: FairSymbol = Self(rawValue: "rectangle.on.rectangle.angled")
    static let rectangle_fill_on_rectangle_angled_fill: FairSymbol = Self(rawValue: "rectangle.fill.on.rectangle.angled.fill")
    static let photo_on_rectangle_angled: FairSymbol = Self(rawValue: "photo.on.rectangle.angled")
    static let rectangle_stack: FairSymbol = Self(rawValue: "rectangle.stack")
    static let rectangle_stack_fill: FairSymbol = Self(rawValue: "rectangle.stack.fill")
    static let rectangle_stack_badge_plus: FairSymbol = Self(rawValue: "rectangle.stack.badge.plus")
    static let rectangle_stack_fill_badge_plus: FairSymbol = Self(rawValue: "rectangle.stack.fill.badge.plus")
    static let rectangle_stack_badge_minus: FairSymbol = Self(rawValue: "rectangle.stack.badge.minus")
    static let rectangle_stack_fill_badge_minus: FairSymbol = Self(rawValue: "rectangle.stack.fill.badge.minus")
    static let rectangle_stack_badge_person_crop: FairSymbol = Self(rawValue: "rectangle.stack.badge.person.crop")
    static let rectangle_stack_badge_person_crop_fill: FairSymbol = Self(rawValue: "rectangle.stack.badge.person.crop.fill")
    static let rectangle_stack_badge_play: FairSymbol = Self(rawValue: "rectangle.stack.badge.play")
    static let rectangle_stack_badge_play_fill: FairSymbol = Self(rawValue: "rectangle.stack.badge.play.fill")
    static let sparkles_rectangle_stack: FairSymbol = Self(rawValue: "sparkles.rectangle.stack")
    static let sparkles_rectangle_stack_fill: FairSymbol = Self(rawValue: "sparkles.rectangle.stack.fill")
    static let sidebar_left: FairSymbol = Self(rawValue: "sidebar.left")
    static let sidebar_right: FairSymbol = Self(rawValue: "sidebar.right")
    static let sidebar_leading: FairSymbol = Self(rawValue: "sidebar.leading")
    static let sidebar_trailing: FairSymbol = Self(rawValue: "sidebar.trailing")
    static let sidebar_squares_left: FairSymbol = Self(rawValue: "sidebar.squares.left")
    static let sidebar_squares_right: FairSymbol = Self(rawValue: "sidebar.squares.right")
    static let sidebar_squares_leading: FairSymbol = Self(rawValue: "sidebar.squares.leading")
    static let sidebar_squares_trailing: FairSymbol = Self(rawValue: "sidebar.squares.trailing")
    static let macwindow: FairSymbol = Self(rawValue: "macwindow")
    static let macwindow_badge_plus: FairSymbol = Self(rawValue: "macwindow.badge.plus")
    static let slider_horizontal_2_rectangle_and_arrow_triangle_2_circlepath: FairSymbol = Self(rawValue: "slider.horizontal.2.rectangle.and.arrow.triangle.2.circlepath")
    static let dock_rectangle: FairSymbol = Self(rawValue: "dock.rectangle")
    static let dock_arrow_up_rectangle: FairSymbol = Self(rawValue: "dock.arrow.up.rectangle")
    static let dock_arrow_down_rectangle: FairSymbol = Self(rawValue: "dock.arrow.down.rectangle")
    static let menubar_rectangle: FairSymbol = Self(rawValue: "menubar.rectangle")
    static let menubar_dock_rectangle: FairSymbol = Self(rawValue: "menubar.dock.rectangle")
    static let menubar_dock_rectangle_badge_record: FairSymbol = Self(rawValue: "menubar.dock.rectangle.badge.record")
    static let menubar_arrow_up_rectangle: FairSymbol = Self(rawValue: "menubar.arrow.up.rectangle")
    static let menubar_arrow_down_rectangle: FairSymbol = Self(rawValue: "menubar.arrow.down.rectangle")
    static let macwindow_on_rectangle: FairSymbol = Self(rawValue: "macwindow.on.rectangle")
    static let text_and_command_macwindow: FairSymbol = Self(rawValue: "text.and.command.macwindow")
    static let keyboard_macwindow: FairSymbol = Self(rawValue: "keyboard.macwindow")
    static let uiwindow_split_2x1: FairSymbol = Self(rawValue: "uiwindow.split.2x1")
    static let mosaic: FairSymbol = Self(rawValue: "mosaic")
    static let mosaic_fill: FairSymbol = Self(rawValue: "mosaic.fill")
    static let squares_below_rectangle: FairSymbol = Self(rawValue: "squares.below.rectangle")
    static let rectangle_split_3x3_fill: FairSymbol = Self(rawValue: "rectangle.split.3x3.fill")
    static let square_on_square_squareshape_controlhandles: FairSymbol = Self(rawValue: "square.on.square.squareshape.controlhandles")
    static let squareshape_controlhandles_on_squareshape_controlhandles: FairSymbol = Self(rawValue: "squareshape.controlhandles.on.squareshape.controlhandles")
    static let pano: FairSymbol = Self(rawValue: "pano")
    static let pano_fill: FairSymbol = Self(rawValue: "pano.fill")
    static let circle_grid_2x1: FairSymbol = Self(rawValue: "circle.grid.2x1")
    static let circle_grid_2x1_fill: FairSymbol = Self(rawValue: "circle.grid.2x1.fill")
    static let circle_grid_2x1_left_filled: FairSymbol = Self(rawValue: "circle.grid.2x1.left.filled")
    static let circle_grid_2x1_right_filled: FairSymbol = Self(rawValue: "circle.grid.2x1.right.filled")
    static let square_and_line_vertical_and_square: FairSymbol = Self(rawValue: "square.and.line.vertical.and.square")
    static let square_fill_and_line_vertical_and_square_fill: FairSymbol = Self(rawValue: "square.fill.and.line.vertical.and.square.fill")
    static let square_filled_and_line_vertical_and_square: FairSymbol = Self(rawValue: "square.filled.and.line.vertical.and.square")
    static let square_and_line_vertical_and_square_filled: FairSymbol = Self(rawValue: "square.and.line.vertical.and.square.filled")
    static let flowchart: FairSymbol = Self(rawValue: "flowchart")
    static let flowchart_fill: FairSymbol = Self(rawValue: "flowchart.fill")
    static let rectangle_connected_to_line_below: FairSymbol = Self(rawValue: "rectangle.connected.to.line.below")
    static let align_horizontal_left: FairSymbol = Self(rawValue: "align.horizontal.left")
    static let align_horizontal_left_fill: FairSymbol = Self(rawValue: "align.horizontal.left.fill")
    static let align_horizontal_center: FairSymbol = Self(rawValue: "align.horizontal.center")
    static let align_horizontal_center_fill: FairSymbol = Self(rawValue: "align.horizontal.center.fill")
    static let align_horizontal_right: FairSymbol = Self(rawValue: "align.horizontal.right")
    static let align_horizontal_right_fill: FairSymbol = Self(rawValue: "align.horizontal.right.fill")
    static let align_vertical_top: FairSymbol = Self(rawValue: "align.vertical.top")
    static let align_vertical_top_fill: FairSymbol = Self(rawValue: "align.vertical.top.fill")
    static let align_vertical_center: FairSymbol = Self(rawValue: "align.vertical.center")
    static let align_vertical_center_fill: FairSymbol = Self(rawValue: "align.vertical.center.fill")
    static let align_vertical_bottom: FairSymbol = Self(rawValue: "align.vertical.bottom")
    static let align_vertical_bottom_fill: FairSymbol = Self(rawValue: "align.vertical.bottom.fill")
    static let shield: FairSymbol = Self(rawValue: "shield")
    static let shield_fill: FairSymbol = Self(rawValue: "shield.fill")
    static let shield_lefthalf_filled: FairSymbol = Self(rawValue: "shield.lefthalf.filled")
    static let shield_righthalf_filled: FairSymbol = Self(rawValue: "shield.righthalf.filled")
    static let shield_slash: FairSymbol = Self(rawValue: "shield.slash")
    static let shield_slash_fill: FairSymbol = Self(rawValue: "shield.slash.fill")
    static let shield_lefthalf_filled_slash: FairSymbol = Self(rawValue: "shield.lefthalf.filled.slash")
    static let checkerboard_shield: FairSymbol = Self(rawValue: "checkerboard.shield")
    static let switch_2: FairSymbol = Self(rawValue: "switch.2")
    static let point_topleft_down_curvedto_point_bottomright_up: FairSymbol = Self(rawValue: "point.topleft.down.curvedto.point.bottomright.up")
    static let point_topleft_down_curvedto_point_bottomright_up_fill: FairSymbol = Self(rawValue: "point.topleft.down.curvedto.point.bottomright.up.fill")
    static let point_topleft_down_curvedto_point_filled_bottomright_up: FairSymbol = Self(rawValue: "point.topleft.down.curvedto.point.filled.bottomright.up")
    static let point_filled_topleft_down_curvedto_point_bottomright_up: FairSymbol = Self(rawValue: "point.filled.topleft.down.curvedto.point.bottomright.up")
    static let app_connected_to_app_below_fill: FairSymbol = Self(rawValue: "app.connected.to.app.below.fill")
    static let slider_horizontal_3: FairSymbol = Self(rawValue: "slider.horizontal.3")
    static let slider_horizontal_below_rectangle: FairSymbol = Self(rawValue: "slider.horizontal.below.rectangle")
    static let slider_horizontal_below_square_filled_and_square: FairSymbol = Self(rawValue: "slider.horizontal.below.square.filled.and.square")
    static let slider_vertical_3: FairSymbol = Self(rawValue: "slider.vertical.3")
    static let cube: FairSymbol = Self(rawValue: "cube")
    static let cube_fill: FairSymbol = Self(rawValue: "cube.fill")
    static let cube_transparent: FairSymbol = Self(rawValue: "cube.transparent")
    static let cube_transparent_fill: FairSymbol = Self(rawValue: "cube.transparent.fill")
    static let shippingbox: FairSymbol = Self(rawValue: "shippingbox")
    static let shippingbox_fill: FairSymbol = Self(rawValue: "shippingbox.fill")
    static let shippingbox_circle: FairSymbol = Self(rawValue: "shippingbox.circle")
    static let shippingbox_circle_fill: FairSymbol = Self(rawValue: "shippingbox.circle.fill")
    static let cone: FairSymbol = Self(rawValue: "cone")
    static let cone_fill: FairSymbol = Self(rawValue: "cone.fill")
    static let pyramid: FairSymbol = Self(rawValue: "pyramid")
    static let pyramid_fill: FairSymbol = Self(rawValue: "pyramid.fill")
    static let square_stack_3d_down_right: FairSymbol = Self(rawValue: "square.stack.3d.down.right")
    static let square_stack_3d_down_right_fill: FairSymbol = Self(rawValue: "square.stack.3d.down.right.fill")
    static let square_stack_3d_down_forward: FairSymbol = Self(rawValue: "square.stack.3d.down.forward")
    static let square_stack_3d_down_forward_fill: FairSymbol = Self(rawValue: "square.stack.3d.down.forward.fill")
    static let square_stack_3d_up: FairSymbol = Self(rawValue: "square.stack.3d.up")
    static let square_stack_3d_up_fill: FairSymbol = Self(rawValue: "square.stack.3d.up.fill")
    static let square_stack_3d_up_slash: FairSymbol = Self(rawValue: "square.stack.3d.up.slash")
    static let square_stack_3d_up_slash_fill: FairSymbol = Self(rawValue: "square.stack.3d.up.slash.fill")
    static let square_stack_3d_up_badge_a: FairSymbol = Self(rawValue: "square.stack.3d.up.badge.a")
    static let square_stack_3d_up_badge_a_fill: FairSymbol = Self(rawValue: "square.stack.3d.up.badge.a.fill")
    static let square_stack_3d_forward_dottedline: FairSymbol = Self(rawValue: "square.stack.3d.forward.dottedline")
    static let square_stack_3d_forward_dottedline_fill: FairSymbol = Self(rawValue: "square.stack.3d.forward.dottedline.fill")
    static let scope: FairSymbol = Self(rawValue: "scope")
    static let helm: FairSymbol = Self(rawValue: "helm")
    static let clock: FairSymbol = Self(rawValue: "clock")
    static let clock_fill: FairSymbol = Self(rawValue: "clock.fill")
    static let clock_circle: FairSymbol = Self(rawValue: "clock.circle")
    static let clock_circle_fill: FairSymbol = Self(rawValue: "clock.circle.fill")
    static let clock_badge_checkmark: FairSymbol = Self(rawValue: "clock.badge.checkmark")
    static let clock_badge_checkmark_fill: FairSymbol = Self(rawValue: "clock.badge.checkmark.fill")
    static let clock_badge_exclamationmark: FairSymbol = Self(rawValue: "clock.badge.exclamationmark")
    static let clock_badge_exclamationmark_fill: FairSymbol = Self(rawValue: "clock.badge.exclamationmark.fill")
    static let deskclock: FairSymbol = Self(rawValue: "deskclock")
    static let deskclock_fill: FairSymbol = Self(rawValue: "deskclock.fill")
    static let alarm: FairSymbol = Self(rawValue: "alarm")
    static let alarm_fill: FairSymbol = Self(rawValue: "alarm.fill")
    static let stopwatch: FairSymbol = Self(rawValue: "stopwatch")
    static let stopwatch_fill: FairSymbol = Self(rawValue: "stopwatch.fill")
    static let chart_xyaxis_line: FairSymbol = Self(rawValue: "chart.xyaxis.line")
    static let timer: FairSymbol = Self(rawValue: "timer")
    static let timer_square: FairSymbol = Self(rawValue: "timer.square")
    static let clock_arrow_circlepath: FairSymbol = Self(rawValue: "clock.arrow.circlepath")
    static let exclamationmark_arrow_circlepath: FairSymbol = Self(rawValue: "exclamationmark.arrow.circlepath")
    static let clock_arrow_2_circlepath: FairSymbol = Self(rawValue: "clock.arrow.2.circlepath")
    static let gamecontroller: FairSymbol = Self(rawValue: "gamecontroller")
    static let gamecontroller_fill: FairSymbol = Self(rawValue: "gamecontroller.fill")
    static let l_joystick: FairSymbol = Self(rawValue: "l.joystick")
    static let l_joystick_fill: FairSymbol = Self(rawValue: "l.joystick.fill")
    static let r_joystick: FairSymbol = Self(rawValue: "r.joystick")
    static let r_joystick_fill: FairSymbol = Self(rawValue: "r.joystick.fill")
    static let l_joystick_press_down: FairSymbol = Self(rawValue: "l.joystick.press.down")
    static let l_joystick_press_down_fill: FairSymbol = Self(rawValue: "l.joystick.press.down.fill")
    static let r_joystick_press_down: FairSymbol = Self(rawValue: "r.joystick.press.down")
    static let r_joystick_press_down_fill: FairSymbol = Self(rawValue: "r.joystick.press.down.fill")
    static let l_joystick_tilt_left: FairSymbol = Self(rawValue: "l.joystick.tilt.left")
    static let l_joystick_tilt_left_fill: FairSymbol = Self(rawValue: "l.joystick.tilt.left.fill")
    static let l_joystick_tilt_right: FairSymbol = Self(rawValue: "l.joystick.tilt.right")
    static let l_joystick_tilt_right_fill: FairSymbol = Self(rawValue: "l.joystick.tilt.right.fill")
    static let l_joystick_tilt_up: FairSymbol = Self(rawValue: "l.joystick.tilt.up")
    static let l_joystick_tilt_up_fill: FairSymbol = Self(rawValue: "l.joystick.tilt.up.fill")
    static let l_joystick_tilt_down: FairSymbol = Self(rawValue: "l.joystick.tilt.down")
    static let l_joystick_tilt_down_fill: FairSymbol = Self(rawValue: "l.joystick.tilt.down.fill")
    static let r_joystick_tilt_left: FairSymbol = Self(rawValue: "r.joystick.tilt.left")
    static let r_joystick_tilt_left_fill: FairSymbol = Self(rawValue: "r.joystick.tilt.left.fill")
    static let r_joystick_tilt_right: FairSymbol = Self(rawValue: "r.joystick.tilt.right")
    static let r_joystick_tilt_right_fill: FairSymbol = Self(rawValue: "r.joystick.tilt.right.fill")
    static let r_joystick_tilt_up: FairSymbol = Self(rawValue: "r.joystick.tilt.up")
    static let r_joystick_tilt_up_fill: FairSymbol = Self(rawValue: "r.joystick.tilt.up.fill")
    static let r_joystick_tilt_down: FairSymbol = Self(rawValue: "r.joystick.tilt.down")
    static let r_joystick_tilt_down_fill: FairSymbol = Self(rawValue: "r.joystick.tilt.down.fill")
    static let dpad: FairSymbol = Self(rawValue: "dpad")
    static let dpad_fill: FairSymbol = Self(rawValue: "dpad.fill")
    static let dpad_left_filled: FairSymbol = Self(rawValue: "dpad.left.filled")
    static let dpad_up_filled: FairSymbol = Self(rawValue: "dpad.up.filled")
    static let dpad_right_filled: FairSymbol = Self(rawValue: "dpad.right.filled")
    static let dpad_down_filled: FairSymbol = Self(rawValue: "dpad.down.filled")
    static let circle_circle: FairSymbol = Self(rawValue: "circle.circle")
    static let circle_circle_fill: FairSymbol = Self(rawValue: "circle.circle.fill")
    static let square_circle: FairSymbol = Self(rawValue: "square.circle")
    static let square_circle_fill: FairSymbol = Self(rawValue: "square.circle.fill")
    static let triangle_circle: FairSymbol = Self(rawValue: "triangle.circle")
    static let triangle_circle_fill: FairSymbol = Self(rawValue: "triangle.circle.fill")
    static let rectangle_roundedtop: FairSymbol = Self(rawValue: "rectangle.roundedtop")
    static let rectangle_roundedtop_fill: FairSymbol = Self(rawValue: "rectangle.roundedtop.fill")
    static let rectangle_roundedbottom: FairSymbol = Self(rawValue: "rectangle.roundedbottom")
    static let rectangle_roundedbottom_fill: FairSymbol = Self(rawValue: "rectangle.roundedbottom.fill")
    static let l_rectangle_roundedbottom: FairSymbol = Self(rawValue: "l.rectangle.roundedbottom")
    static let l_rectangle_roundedbottom_fill: FairSymbol = Self(rawValue: "l.rectangle.roundedbottom.fill")
    static let l1_rectangle_roundedbottom: FairSymbol = Self(rawValue: "l1.rectangle.roundedbottom")
    static let l1_rectangle_roundedbottom_fill: FairSymbol = Self(rawValue: "l1.rectangle.roundedbottom.fill")
    static let l2_rectangle_roundedtop: FairSymbol = Self(rawValue: "l2.rectangle.roundedtop")
    static let l2_rectangle_roundedtop_fill: FairSymbol = Self(rawValue: "l2.rectangle.roundedtop.fill")
    static let r_rectangle_roundedbottom: FairSymbol = Self(rawValue: "r.rectangle.roundedbottom")
    static let r_rectangle_roundedbottom_fill: FairSymbol = Self(rawValue: "r.rectangle.roundedbottom.fill")
    static let r1_rectangle_roundedbottom: FairSymbol = Self(rawValue: "r1.rectangle.roundedbottom")
    static let r1_rectangle_roundedbottom_fill: FairSymbol = Self(rawValue: "r1.rectangle.roundedbottom.fill")
    static let r2_rectangle_roundedtop: FairSymbol = Self(rawValue: "r2.rectangle.roundedtop")
    static let r2_rectangle_roundedtop_fill: FairSymbol = Self(rawValue: "r2.rectangle.roundedtop.fill")
    static let lb_rectangle_roundedbottom: FairSymbol = Self(rawValue: "lb.rectangle.roundedbottom")
    static let lb_rectangle_roundedbottom_fill: FairSymbol = Self(rawValue: "lb.rectangle.roundedbottom.fill")
    static let rb_rectangle_roundedbottom: FairSymbol = Self(rawValue: "rb.rectangle.roundedbottom")
    static let rb_rectangle_roundedbottom_fill: FairSymbol = Self(rawValue: "rb.rectangle.roundedbottom.fill")
    static let lt_rectangle_roundedtop: FairSymbol = Self(rawValue: "lt.rectangle.roundedtop")
    static let lt_rectangle_roundedtop_fill: FairSymbol = Self(rawValue: "lt.rectangle.roundedtop.fill")
    static let rt_rectangle_roundedtop: FairSymbol = Self(rawValue: "rt.rectangle.roundedtop")
    static let rt_rectangle_roundedtop_fill: FairSymbol = Self(rawValue: "rt.rectangle.roundedtop.fill")
    static let zl_rectangle_roundedtop: FairSymbol = Self(rawValue: "zl.rectangle.roundedtop")
    static let zl_rectangle_roundedtop_fill: FairSymbol = Self(rawValue: "zl.rectangle.roundedtop.fill")
    static let zr_rectangle_roundedtop: FairSymbol = Self(rawValue: "zr.rectangle.roundedtop")
    static let zr_rectangle_roundedtop_fill: FairSymbol = Self(rawValue: "zr.rectangle.roundedtop.fill")
    static let paintpalette: FairSymbol = Self(rawValue: "paintpalette")
    static let paintpalette_fill: FairSymbol = Self(rawValue: "paintpalette.fill")
    static let cup_and_saucer: FairSymbol = Self(rawValue: "cup.and.saucer")
    static let cup_and_saucer_fill: FairSymbol = Self(rawValue: "cup.and.saucer.fill")
    static let takeoutbag_and_cup_and_straw: FairSymbol = Self(rawValue: "takeoutbag.and.cup.and.straw")
    static let takeoutbag_and_cup_and_straw_fill: FairSymbol = Self(rawValue: "takeoutbag.and.cup.and.straw.fill")
    static let fork_knife: FairSymbol = Self(rawValue: "fork.knife")
    static let fork_knife_circle: FairSymbol = Self(rawValue: "fork.knife.circle")
    static let fork_knife_circle_fill: FairSymbol = Self(rawValue: "fork.knife.circle.fill")
    static let figure_walk: FairSymbol = Self(rawValue: "figure.walk")
    static let figure_walk_circle: FairSymbol = Self(rawValue: "figure.walk.circle")
    static let figure_walk_circle_fill: FairSymbol = Self(rawValue: "figure.walk.circle.fill")
    static let figure_walk_diamond: FairSymbol = Self(rawValue: "figure.walk.diamond")
    static let figure_walk_diamond_fill: FairSymbol = Self(rawValue: "figure.walk.diamond.fill")
    static let figure_stand: FairSymbol = Self(rawValue: "figure.stand")
    static let figure_stand_line_dotted_figure_stand: FairSymbol = Self(rawValue: "figure.stand.line.dotted.figure.stand")
    static let figure_wave: FairSymbol = Self(rawValue: "figure.wave")
    static let figure_wave_circle: FairSymbol = Self(rawValue: "figure.wave.circle")
    static let figure_wave_circle_fill: FairSymbol = Self(rawValue: "figure.wave.circle.fill")
    static let figure_roll: FairSymbol = Self(rawValue: "figure.roll")
    static let ear: FairSymbol = Self(rawValue: "ear")
    static let ear_badge_checkmark: FairSymbol = Self(rawValue: "ear.badge.checkmark")
    static let ear_trianglebadge_exclamationmark: FairSymbol = Self(rawValue: "ear.trianglebadge.exclamationmark")
    static let ear_and_waveform: FairSymbol = Self(rawValue: "ear.and.waveform")
    static let ear_fill: FairSymbol = Self(rawValue: "ear.fill")
    static let hearingdevice_ear: FairSymbol = Self(rawValue: "hearingdevice.ear")
    static let hand_raised: FairSymbol = Self(rawValue: "hand.raised")
    static let hand_raised_fill: FairSymbol = Self(rawValue: "hand.raised.fill")
    static let hand_raised_circle: FairSymbol = Self(rawValue: "hand.raised.circle")
    static let hand_raised_circle_fill: FairSymbol = Self(rawValue: "hand.raised.circle.fill")
    static let hand_raised_square: FairSymbol = Self(rawValue: "hand.raised.square")
    static let hand_raised_square_fill: FairSymbol = Self(rawValue: "hand.raised.square.fill")
    static let hand_raised_slash: FairSymbol = Self(rawValue: "hand.raised.slash")
    static let hand_raised_slash_fill: FairSymbol = Self(rawValue: "hand.raised.slash.fill")
    static let hand_thumbsup: FairSymbol = Self(rawValue: "hand.thumbsup")
    static let hand_thumbsup_fill: FairSymbol = Self(rawValue: "hand.thumbsup.fill")
    static let hand_thumbsup_circle: FairSymbol = Self(rawValue: "hand.thumbsup.circle")
    static let hand_thumbsup_circle_fill: FairSymbol = Self(rawValue: "hand.thumbsup.circle.fill")
    static let hand_thumbsdown: FairSymbol = Self(rawValue: "hand.thumbsdown")
    static let hand_thumbsdown_fill: FairSymbol = Self(rawValue: "hand.thumbsdown.fill")
    static let hand_thumbsdown_circle: FairSymbol = Self(rawValue: "hand.thumbsdown.circle")
    static let hand_thumbsdown_circle_fill: FairSymbol = Self(rawValue: "hand.thumbsdown.circle.fill")
    static let hand_point_up_left: FairSymbol = Self(rawValue: "hand.point.up.left")
    static let hand_point_up_left_fill: FairSymbol = Self(rawValue: "hand.point.up.left.fill")
    static let hand_draw: FairSymbol = Self(rawValue: "hand.draw")
    static let hand_draw_fill: FairSymbol = Self(rawValue: "hand.draw.fill")
    static let hand_tap: FairSymbol = Self(rawValue: "hand.tap")
    static let hand_tap_fill: FairSymbol = Self(rawValue: "hand.tap.fill")
    static let rectangle_and_hand_point_up_left: FairSymbol = Self(rawValue: "rectangle.and.hand.point.up.left")
    static let rectangle_and_hand_point_up_left_fill: FairSymbol = Self(rawValue: "rectangle.and.hand.point.up.left.fill")
    static let rectangle_filled_and_hand_point_up_left: FairSymbol = Self(rawValue: "rectangle.filled.and.hand.point.up.left")
    static let rectangle_and_hand_point_up_left_filled: FairSymbol = Self(rawValue: "rectangle.and.hand.point.up.left.filled")
    static let hand_point_left: FairSymbol = Self(rawValue: "hand.point.left")
    static let hand_point_left_fill: FairSymbol = Self(rawValue: "hand.point.left.fill")
    static let hand_point_right: FairSymbol = Self(rawValue: "hand.point.right")
    static let hand_point_right_fill: FairSymbol = Self(rawValue: "hand.point.right.fill")
    static let hand_point_up: FairSymbol = Self(rawValue: "hand.point.up")
    static let hand_point_up_fill: FairSymbol = Self(rawValue: "hand.point.up.fill")
    static let hand_point_up_braille: FairSymbol = Self(rawValue: "hand.point.up.braille")
    static let hand_point_up_braille_fill: FairSymbol = Self(rawValue: "hand.point.up.braille.fill")
    static let hand_point_down: FairSymbol = Self(rawValue: "hand.point.down")
    static let hand_point_down_fill: FairSymbol = Self(rawValue: "hand.point.down.fill")
    static let hand_wave: FairSymbol = Self(rawValue: "hand.wave")
    static let hand_wave_fill: FairSymbol = Self(rawValue: "hand.wave.fill")
    static let hands_clap: FairSymbol = Self(rawValue: "hands.clap")
    static let hands_clap_fill: FairSymbol = Self(rawValue: "hands.clap.fill")
    static let hands_sparkles: FairSymbol = Self(rawValue: "hands.sparkles")
    static let hands_sparkles_fill: FairSymbol = Self(rawValue: "hands.sparkles.fill")
    static let rectangle_compress_vertical: FairSymbol = Self(rawValue: "rectangle.compress.vertical")
    static let rectangle_expand_vertical: FairSymbol = Self(rawValue: "rectangle.expand.vertical")
    static let rectangle_and_arrow_up_right_and_arrow_down_left: FairSymbol = Self(rawValue: "rectangle.and.arrow.up.right.and.arrow.down.left")
    static let rectangle_and_arrow_up_right_and_arrow_down_left_slash: FairSymbol = Self(rawValue: "rectangle.and.arrow.up.right.and.arrow.down.left.slash")
    static let square_2_stack_3d: FairSymbol = Self(rawValue: "square.2.stack.3d")
    static let square_2_stack_3d_top_filled: FairSymbol = Self(rawValue: "square.2.stack.3d.top.filled")
    static let square_2_stack_3d_bottom_filled: FairSymbol = Self(rawValue: "square.2.stack.3d.bottom.filled")
    static let square_3_layers_3d_down_right: FairSymbol = Self(rawValue: "square.3.layers.3d.down.right")
    static let square_3_layers_3d_down_left: FairSymbol = Self(rawValue: "square.3.layers.3d.down.left")
    static let square_3_layers_3d_down_forward: FairSymbol = Self(rawValue: "square.3.layers.3d.down.forward")
    static let square_3_layers_3d_down_backward: FairSymbol = Self(rawValue: "square.3.layers.3d.down.backward")
    static let square_3_stack_3d: FairSymbol = Self(rawValue: "square.3.stack.3d")
    static let square_3_stack_3d_top_filled: FairSymbol = Self(rawValue: "square.3.stack.3d.top.filled")
    static let square_3_stack_3d_middle_filled: FairSymbol = Self(rawValue: "square.3.stack.3d.middle.filled")
    static let square_3_stack_3d_bottom_filled: FairSymbol = Self(rawValue: "square.3.stack.3d.bottom.filled")
    static let cylinder: FairSymbol = Self(rawValue: "cylinder")
    static let cylinder_fill: FairSymbol = Self(rawValue: "cylinder.fill")
    static let cylinder_split_1x2: FairSymbol = Self(rawValue: "cylinder.split.1x2")
    static let cylinder_split_1x2_fill: FairSymbol = Self(rawValue: "cylinder.split.1x2.fill")
    static let chart_bar: FairSymbol = Self(rawValue: "chart.bar")
    static let chart_bar_fill: FairSymbol = Self(rawValue: "chart.bar.fill")
    static let chart_pie: FairSymbol = Self(rawValue: "chart.pie")
    static let chart_pie_fill: FairSymbol = Self(rawValue: "chart.pie.fill")
    static let chart_bar_xaxis: FairSymbol = Self(rawValue: "chart.bar.xaxis")
    static let chart_line_uptrend_xyaxis: FairSymbol = Self(rawValue: "chart.line.uptrend.xyaxis")
    static let chart_line_uptrend_xyaxis_circle: FairSymbol = Self(rawValue: "chart.line.uptrend.xyaxis.circle")
    static let chart_line_uptrend_xyaxis_circle_fill: FairSymbol = Self(rawValue: "chart.line.uptrend.xyaxis.circle.fill")
    static let dot_squareshape_split_2x2: FairSymbol = Self(rawValue: "dot.squareshape.split.2x2")
    static let squareshape_split_2x2_dotted: FairSymbol = Self(rawValue: "squareshape.split.2x2.dotted")
    static let squareshape_split_2x2: FairSymbol = Self(rawValue: "squareshape.split.2x2")
    static let squareshape_split_3x3: FairSymbol = Self(rawValue: "squareshape.split.3x3")
    static let burst: FairSymbol = Self(rawValue: "burst")
    static let burst_fill: FairSymbol = Self(rawValue: "burst.fill")
    static let waveform_path_ecg: FairSymbol = Self(rawValue: "waveform.path.ecg")
    static let waveform_path_ecg_rectangle: FairSymbol = Self(rawValue: "waveform.path.ecg.rectangle")
    static let waveform_path_ecg_rectangle_fill: FairSymbol = Self(rawValue: "waveform.path.ecg.rectangle.fill")
    static let waveform_path: FairSymbol = Self(rawValue: "waveform.path")
    static let waveform_path_badge_plus: FairSymbol = Self(rawValue: "waveform.path.badge.plus")
    static let waveform_path_badge_minus: FairSymbol = Self(rawValue: "waveform.path.badge.minus")
    static let point_3_connected_trianglepath_dotted: FairSymbol = Self(rawValue: "point.3.connected.trianglepath.dotted")
    static let point_3_filled_connected_trianglepath_dotted: FairSymbol = Self(rawValue: "point.3.filled.connected.trianglepath.dotted")
    static let waveform: FairSymbol = Self(rawValue: "waveform")
    static let waveform_circle: FairSymbol = Self(rawValue: "waveform.circle")
    static let waveform_circle_fill: FairSymbol = Self(rawValue: "waveform.circle.fill")
    static let waveform_badge_plus: FairSymbol = Self(rawValue: "waveform.badge.plus")
    static let waveform_badge_minus: FairSymbol = Self(rawValue: "waveform.badge.minus")
    static let waveform_badge_exclamationmark: FairSymbol = Self(rawValue: "waveform.badge.exclamationmark")
    static let waveform_and_magnifyingglass: FairSymbol = Self(rawValue: "waveform.and.magnifyingglass")
    static let waveform_and_mic: FairSymbol = Self(rawValue: "waveform.and.mic")
    static let staroflife: FairSymbol = Self(rawValue: "staroflife")
    static let staroflife_fill: FairSymbol = Self(rawValue: "staroflife.fill")
    static let staroflife_circle: FairSymbol = Self(rawValue: "staroflife.circle")
    static let staroflife_circle_fill: FairSymbol = Self(rawValue: "staroflife.circle.fill")
    static let simcard: FairSymbol = Self(rawValue: "simcard")
    static let simcard_fill: FairSymbol = Self(rawValue: "simcard.fill")
    static let simcard_2: FairSymbol = Self(rawValue: "simcard.2")
    static let simcard_2_fill: FairSymbol = Self(rawValue: "simcard.2.fill")
    static let sdcard: FairSymbol = Self(rawValue: "sdcard")
    static let sdcard_fill: FairSymbol = Self(rawValue: "sdcard.fill")
    static let esim: FairSymbol = Self(rawValue: "esim")
    static let esim_fill: FairSymbol = Self(rawValue: "esim.fill")
    static let atom: FairSymbol = Self(rawValue: "atom")
    static let scalemass: FairSymbol = Self(rawValue: "scalemass")
    static let scalemass_fill: FairSymbol = Self(rawValue: "scalemass.fill")
    static let gift: FairSymbol = Self(rawValue: "gift")
    static let gift_fill: FairSymbol = Self(rawValue: "gift.fill")
    static let gift_circle: FairSymbol = Self(rawValue: "gift.circle")
    static let gift_circle_fill: FairSymbol = Self(rawValue: "gift.circle.fill")
    static let plus_app: FairSymbol = Self(rawValue: "plus.app")
    static let plus_app_fill: FairSymbol = Self(rawValue: "plus.app.fill")
    static let arrow_down_app: FairSymbol = Self(rawValue: "arrow.down.app")
    static let arrow_down_app_fill: FairSymbol = Self(rawValue: "arrow.down.app.fill")
    static let arrow_up_forward_app: FairSymbol = Self(rawValue: "arrow.up.forward.app")
    static let arrow_up_forward_app_fill: FairSymbol = Self(rawValue: "arrow.up.forward.app.fill")
    static let xmark_app: FairSymbol = Self(rawValue: "xmark.app")
    static let xmark_app_fill: FairSymbol = Self(rawValue: "xmark.app.fill")
    static let questionmark_app: FairSymbol = Self(rawValue: "questionmark.app")
    static let questionmark_app_fill: FairSymbol = Self(rawValue: "questionmark.app.fill")
    static let app_badge: FairSymbol = Self(rawValue: "app.badge")
    static let app_badge_fill: FairSymbol = Self(rawValue: "app.badge.fill")
    static let app_badge_checkmark: FairSymbol = Self(rawValue: "app.badge.checkmark")
    static let app_badge_checkmark_fill: FairSymbol = Self(rawValue: "app.badge.checkmark.fill")
    static let app_dashed: FairSymbol = Self(rawValue: "app.dashed")
    static let questionmark_app_dashed: FairSymbol = Self(rawValue: "questionmark.app.dashed")
    static let app_gift: FairSymbol = Self(rawValue: "app.gift")
    static let app_gift_fill: FairSymbol = Self(rawValue: "app.gift.fill")
    static let studentdesk: FairSymbol = Self(rawValue: "studentdesk")
    static let hourglass: FairSymbol = Self(rawValue: "hourglass")
    static let hourglass_circle: FairSymbol = Self(rawValue: "hourglass.circle")
    static let hourglass_circle_fill: FairSymbol = Self(rawValue: "hourglass.circle.fill")
    static let hourglass_badge_plus: FairSymbol = Self(rawValue: "hourglass.badge.plus")
    static let hourglass_bottomhalf_filled: FairSymbol = Self(rawValue: "hourglass.bottomhalf.filled")
    static let hourglass_tophalf_filled: FairSymbol = Self(rawValue: "hourglass.tophalf.filled")
    static let banknote: FairSymbol = Self(rawValue: "banknote")
    static let banknote_fill: FairSymbol = Self(rawValue: "banknote.fill")
    static let paragraphsign: FairSymbol = Self(rawValue: "paragraphsign")
    static let purchased: FairSymbol = Self(rawValue: "purchased")
    static let purchased_circle: FairSymbol = Self(rawValue: "purchased.circle")
    static let purchased_circle_fill: FairSymbol = Self(rawValue: "purchased.circle.fill")
    static let perspective: FairSymbol = Self(rawValue: "perspective")
    static let circle_and_line_horizontal: FairSymbol = Self(rawValue: "circle.and.line.horizontal")
    static let circle_and_line_horizontal_fill: FairSymbol = Self(rawValue: "circle.and.line.horizontal.fill")
    static let trapezoid_and_line_vertical: FairSymbol = Self(rawValue: "trapezoid.and.line.vertical")
    static let trapezoid_and_line_vertical_fill: FairSymbol = Self(rawValue: "trapezoid.and.line.vertical.fill")
    static let trapezoid_and_line_horizontal: FairSymbol = Self(rawValue: "trapezoid.and.line.horizontal")
    static let trapezoid_and_line_horizontal_fill: FairSymbol = Self(rawValue: "trapezoid.and.line.horizontal.fill")
    static let aspectratio: FairSymbol = Self(rawValue: "aspectratio")
    static let aspectratio_fill: FairSymbol = Self(rawValue: "aspectratio.fill")
    static let camera_filters: FairSymbol = Self(rawValue: "camera.filters")
    static let skew: FairSymbol = Self(rawValue: "skew")
    static let arrow_left_and_right_righttriangle_left_righttriangle_right: FairSymbol = Self(rawValue: "arrow.left.and.right.righttriangle.left.righttriangle.right")
    static let arrow_left_and_right_righttriangle_left_righttriangle_right_fill: FairSymbol = Self(rawValue: "arrow.left.and.right.righttriangle.left.righttriangle.right.fill")
    static let arrow_up_and_down_righttriangle_up_righttriangle_down: FairSymbol = Self(rawValue: "arrow.up.and.down.righttriangle.up.righttriangle.down")
    static let arrow_up_and_down_righttriangle_up_righttriangle_down_fill: FairSymbol = Self(rawValue: "arrow.up.and.down.righttriangle.up.righttriangle.down.fill")
    static let arrowtriangle_left_and_line_vertical_and_arrowtriangle_right: FairSymbol = Self(rawValue: "arrowtriangle.left.and.line.vertical.and.arrowtriangle.right")
    static let arrowtriangle_left_and_line_vertical_and_arrowtriangle_right_fill: FairSymbol = Self(rawValue: "arrowtriangle.left.and.line.vertical.and.arrowtriangle.right.fill")
    static let arrowtriangle_right_and_line_vertical_and_arrowtriangle_left: FairSymbol = Self(rawValue: "arrowtriangle.right.and.line.vertical.and.arrowtriangle.left")
    static let arrowtriangle_right_and_line_vertical_and_arrowtriangle_left_fill: FairSymbol = Self(rawValue: "arrowtriangle.right.and.line.vertical.and.arrowtriangle.left.fill")
    static let grid: FairSymbol = Self(rawValue: "grid")
    static let grid_circle: FairSymbol = Self(rawValue: "grid.circle")
    static let grid_circle_fill: FairSymbol = Self(rawValue: "grid.circle.fill")
    static let burn: FairSymbol = Self(rawValue: "burn")
    static let lifepreserver: FairSymbol = Self(rawValue: "lifepreserver")
    static let lifepreserver_fill: FairSymbol = Self(rawValue: "lifepreserver.fill")
    static let recordingtape: FairSymbol = Self(rawValue: "recordingtape")
    static let binoculars: FairSymbol = Self(rawValue: "binoculars")
    static let binoculars_fill: FairSymbol = Self(rawValue: "binoculars.fill")
    static let battery_100: FairSymbol = Self(rawValue: "battery.100")
    static let battery_75: FairSymbol = Self(rawValue: "battery.75")
    static let battery_50: FairSymbol = Self(rawValue: "battery.50")
    static let battery_25: FairSymbol = Self(rawValue: "battery.25")
    static let battery_0: FairSymbol = Self(rawValue: "battery.0")
    static let battery_100_bolt: FairSymbol = Self(rawValue: "battery.100.bolt")
    static let minus_plus_batteryblock: FairSymbol = Self(rawValue: "minus.plus.batteryblock")
    static let minus_plus_batteryblock_fill: FairSymbol = Self(rawValue: "minus.plus.batteryblock.fill")
    static let bolt_batteryblock: FairSymbol = Self(rawValue: "bolt.batteryblock")
    static let bolt_batteryblock_fill: FairSymbol = Self(rawValue: "bolt.batteryblock.fill")
    static let lightbulb: FairSymbol = Self(rawValue: "lightbulb")
    static let lightbulb_fill: FairSymbol = Self(rawValue: "lightbulb.fill")
    static let lightbulb_circle: FairSymbol = Self(rawValue: "lightbulb.circle")
    static let lightbulb_circle_fill: FairSymbol = Self(rawValue: "lightbulb.circle.fill")
    static let lightbulb_slash: FairSymbol = Self(rawValue: "lightbulb.slash")
    static let lightbulb_slash_fill: FairSymbol = Self(rawValue: "lightbulb.slash.fill")
    static let fibrechannel: FairSymbol = Self(rawValue: "fibrechannel")
    static let checklist: FairSymbol = Self(rawValue: "checklist")
    static let square_fill_text_grid_1x2: FairSymbol = Self(rawValue: "square.fill.text.grid.1x2")
    static let list_dash: FairSymbol = Self(rawValue: "list.dash")
    static let list_bullet: FairSymbol = Self(rawValue: "list.bullet")
    static let list_bullet_circle: FairSymbol = Self(rawValue: "list.bullet.circle")
    static let list_bullet_circle_fill: FairSymbol = Self(rawValue: "list.bullet.circle.fill")
    static let list_triangle: FairSymbol = Self(rawValue: "list.triangle")
    static let list_bullet_indent: FairSymbol = Self(rawValue: "list.bullet.indent")
    static let list_number: FairSymbol = Self(rawValue: "list.number")
    static let list_star: FairSymbol = Self(rawValue: "list.star")
    static let increase_indent: FairSymbol = Self(rawValue: "increase.indent")
    static let decrease_indent: FairSymbol = Self(rawValue: "decrease.indent")
    static let decrease_quotelevel: FairSymbol = Self(rawValue: "decrease.quotelevel")
    static let increase_quotelevel: FairSymbol = Self(rawValue: "increase.quotelevel")
    static let list_bullet_below_rectangle: FairSymbol = Self(rawValue: "list.bullet.below.rectangle")
    static let text_badge_plus: FairSymbol = Self(rawValue: "text.badge.plus")
    static let text_badge_minus: FairSymbol = Self(rawValue: "text.badge.minus")
    static let text_badge_checkmark: FairSymbol = Self(rawValue: "text.badge.checkmark")
    static let text_badge_xmark: FairSymbol = Self(rawValue: "text.badge.xmark")
    static let text_badge_star: FairSymbol = Self(rawValue: "text.badge.star")
    static let text_insert: FairSymbol = Self(rawValue: "text.insert")
    static let text_append: FairSymbol = Self(rawValue: "text.append")
    static let text_quote: FairSymbol = Self(rawValue: "text.quote")
    static let text_alignleft: FairSymbol = Self(rawValue: "text.alignleft")
    static let text_aligncenter: FairSymbol = Self(rawValue: "text.aligncenter")
    static let text_alignright: FairSymbol = Self(rawValue: "text.alignright")
    static let text_justify: FairSymbol = Self(rawValue: "text.justify")
    static let text_justify_left: FairSymbol = Self(rawValue: "text.justify.left")
    static let text_justify_right: FairSymbol = Self(rawValue: "text.justify.right")
    static let text_justify_leading: FairSymbol = Self(rawValue: "text.justify.leading")
    static let text_justify_trailing: FairSymbol = Self(rawValue: "text.justify.trailing")
    static let text_redaction: FairSymbol = Self(rawValue: "text.redaction")
    static let list_and_film: FairSymbol = Self(rawValue: "list.and.film")
    static let line_3_horizontal: FairSymbol = Self(rawValue: "line.3.horizontal")
    static let line_3_horizontal_decrease: FairSymbol = Self(rawValue: "line.3.horizontal.decrease")
    static let line_3_horizontal_decrease_circle: FairSymbol = Self(rawValue: "line.3.horizontal.decrease.circle")
    static let line_3_horizontal_decrease_circle_fill: FairSymbol = Self(rawValue: "line.3.horizontal.decrease.circle.fill")
    static let line_3_horizontal_circle: FairSymbol = Self(rawValue: "line.3.horizontal.circle")
    static let line_3_horizontal_circle_fill: FairSymbol = Self(rawValue: "line.3.horizontal.circle.fill")
    static let line_2_horizontal_decrease_circle: FairSymbol = Self(rawValue: "line.2.horizontal.decrease.circle")
    static let line_2_horizontal_decrease_circle_fill: FairSymbol = Self(rawValue: "line.2.horizontal.decrease.circle.fill")
    static let character: FairSymbol = Self(rawValue: "character")
    static let textformat_size_smaller: FairSymbol = Self(rawValue: "textformat.size.smaller")
    static let textformat_size_larger: FairSymbol = Self(rawValue: "textformat.size.larger")
    static let textformat_size: FairSymbol = Self(rawValue: "textformat.size")
    static let textformat: FairSymbol = Self(rawValue: "textformat")
    static let textformat_alt: FairSymbol = Self(rawValue: "textformat.alt")
    static let textformat_superscript: FairSymbol = Self(rawValue: "textformat.superscript")
    static let textformat_subscript: FairSymbol = Self(rawValue: "textformat.subscript")
    static let abc: FairSymbol = Self(rawValue: "abc")
    static let textformat_abc: FairSymbol = Self(rawValue: "textformat.abc")
    static let textformat_abc_dottedunderline: FairSymbol = Self(rawValue: "textformat.abc.dottedunderline")
    static let bold: FairSymbol = Self(rawValue: "bold")
    static let italic: FairSymbol = Self(rawValue: "italic")
    static let underline: FairSymbol = Self(rawValue: "underline")
    static let strikethrough: FairSymbol = Self(rawValue: "strikethrough")
    static let shadow: FairSymbol = Self(rawValue: "shadow")
    static let bold_italic_underline: FairSymbol = Self(rawValue: "bold.italic.underline")
    static let bold_underline: FairSymbol = Self(rawValue: "bold.underline")
    static let view_2d: FairSymbol = Self(rawValue: "view.2d")
    static let view_3d: FairSymbol = Self(rawValue: "view.3d")
    static let character_cursor_ibeam: FairSymbol = Self(rawValue: "character.cursor.ibeam")
    static let fx: FairSymbol = Self(rawValue: "fx")
    static let f_cursive: FairSymbol = Self(rawValue: "f.cursive")
    static let f_cursive_circle: FairSymbol = Self(rawValue: "f.cursive.circle")
    static let f_cursive_circle_fill: FairSymbol = Self(rawValue: "f.cursive.circle.fill")
    static let k: FairSymbol = Self(rawValue: "k")
    static let sum: FairSymbol = Self(rawValue: "sum")
    static let percent: FairSymbol = Self(rawValue: "percent")
    static let function: FairSymbol = Self(rawValue: "function")
    static let fn: FairSymbol = Self(rawValue: "fn")
    static let textformat_123: FairSymbol = Self(rawValue: "textformat.123")
    static let N123_rectangle: FairSymbol = Self(rawValue: "123.rectangle")
    static let N123_rectangle_fill: FairSymbol = Self(rawValue: "123.rectangle.fill")
    static let character_textbox: FairSymbol = Self(rawValue: "character.textbox")
    static let a_magnify: FairSymbol = Self(rawValue: "a.magnify")
    static let info: FairSymbol = Self(rawValue: "info")
    static let info_circle: FairSymbol = Self(rawValue: "info.circle")
    static let info_circle_fill: FairSymbol = Self(rawValue: "info.circle.fill")
    static let at: FairSymbol = Self(rawValue: "at")
    static let at_circle: FairSymbol = Self(rawValue: "at.circle")
    static let at_circle_fill: FairSymbol = Self(rawValue: "at.circle.fill")
    static let at_badge_plus: FairSymbol = Self(rawValue: "at.badge.plus")
    static let at_badge_minus: FairSymbol = Self(rawValue: "at.badge.minus")
    static let questionmark: FairSymbol = Self(rawValue: "questionmark")
    static let questionmark_circle: FairSymbol = Self(rawValue: "questionmark.circle")
    static let questionmark_circle_fill: FairSymbol = Self(rawValue: "questionmark.circle.fill")
    static let questionmark_square: FairSymbol = Self(rawValue: "questionmark.square")
    static let questionmark_square_fill: FairSymbol = Self(rawValue: "questionmark.square.fill")
    static let questionmark_diamond: FairSymbol = Self(rawValue: "questionmark.diamond")
    static let questionmark_diamond_fill: FairSymbol = Self(rawValue: "questionmark.diamond.fill")
    static let exclamationmark: FairSymbol = Self(rawValue: "exclamationmark")
    static let exclamationmark_2: FairSymbol = Self(rawValue: "exclamationmark.2")
    static let exclamationmark_3: FairSymbol = Self(rawValue: "exclamationmark.3")
    static let exclamationmark_circle: FairSymbol = Self(rawValue: "exclamationmark.circle")
    static let exclamationmark_circle_fill: FairSymbol = Self(rawValue: "exclamationmark.circle.fill")
    static let exclamationmark_square: FairSymbol = Self(rawValue: "exclamationmark.square")
    static let exclamationmark_square_fill: FairSymbol = Self(rawValue: "exclamationmark.square.fill")
    static let exclamationmark_octagon: FairSymbol = Self(rawValue: "exclamationmark.octagon")
    static let exclamationmark_octagon_fill: FairSymbol = Self(rawValue: "exclamationmark.octagon.fill")
    static let exclamationmark_shield: FairSymbol = Self(rawValue: "exclamationmark.shield")
    static let exclamationmark_shield_fill: FairSymbol = Self(rawValue: "exclamationmark.shield.fill")
    static let plus: FairSymbol = Self(rawValue: "plus")
    static let plus_circle: FairSymbol = Self(rawValue: "plus.circle")
    static let plus_circle_fill: FairSymbol = Self(rawValue: "plus.circle.fill")
    static let plus_square: FairSymbol = Self(rawValue: "plus.square")
    static let plus_square_fill: FairSymbol = Self(rawValue: "plus.square.fill")
    static let plus_rectangle: FairSymbol = Self(rawValue: "plus.rectangle")
    static let plus_rectangle_fill: FairSymbol = Self(rawValue: "plus.rectangle.fill")
    static let plus_rectangle_portrait: FairSymbol = Self(rawValue: "plus.rectangle.portrait")
    static let plus_rectangle_portrait_fill: FairSymbol = Self(rawValue: "plus.rectangle.portrait.fill")
    static let plus_diamond: FairSymbol = Self(rawValue: "plus.diamond")
    static let plus_diamond_fill: FairSymbol = Self(rawValue: "plus.diamond.fill")
    static let minus: FairSymbol = Self(rawValue: "minus")
    static let minus_circle: FairSymbol = Self(rawValue: "minus.circle")
    static let minus_circle_fill: FairSymbol = Self(rawValue: "minus.circle.fill")
    static let minus_square: FairSymbol = Self(rawValue: "minus.square")
    static let minus_square_fill: FairSymbol = Self(rawValue: "minus.square.fill")
    static let minus_rectangle: FairSymbol = Self(rawValue: "minus.rectangle")
    static let minus_rectangle_fill: FairSymbol = Self(rawValue: "minus.rectangle.fill")
    static let minus_rectangle_portrait: FairSymbol = Self(rawValue: "minus.rectangle.portrait")
    static let minus_rectangle_portrait_fill: FairSymbol = Self(rawValue: "minus.rectangle.portrait.fill")
    static let minus_diamond: FairSymbol = Self(rawValue: "minus.diamond")
    static let minus_diamond_fill: FairSymbol = Self(rawValue: "minus.diamond.fill")
    static let plusminus: FairSymbol = Self(rawValue: "plusminus")
    static let plusminus_circle: FairSymbol = Self(rawValue: "plusminus.circle")
    static let plusminus_circle_fill: FairSymbol = Self(rawValue: "plusminus.circle.fill")
    static let plus_forwardslash_minus: FairSymbol = Self(rawValue: "plus.forwardslash.minus")
    static let minus_forwardslash_plus: FairSymbol = Self(rawValue: "minus.forwardslash.plus")
    static let multiply: FairSymbol = Self(rawValue: "multiply")
    static let multiply_circle: FairSymbol = Self(rawValue: "multiply.circle")
    static let multiply_circle_fill: FairSymbol = Self(rawValue: "multiply.circle.fill")
    static let multiply_square: FairSymbol = Self(rawValue: "multiply.square")
    static let multiply_square_fill: FairSymbol = Self(rawValue: "multiply.square.fill")
    static let xmark_rectangle: FairSymbol = Self(rawValue: "xmark.rectangle")
    static let xmark_rectangle_fill: FairSymbol = Self(rawValue: "xmark.rectangle.fill")
    static let xmark_rectangle_portrait: FairSymbol = Self(rawValue: "xmark.rectangle.portrait")
    static let xmark_rectangle_portrait_fill: FairSymbol = Self(rawValue: "xmark.rectangle.portrait.fill")
    static let xmark_diamond: FairSymbol = Self(rawValue: "xmark.diamond")
    static let xmark_diamond_fill: FairSymbol = Self(rawValue: "xmark.diamond.fill")
    static let xmark_shield: FairSymbol = Self(rawValue: "xmark.shield")
    static let xmark_shield_fill: FairSymbol = Self(rawValue: "xmark.shield.fill")
    static let xmark_octagon: FairSymbol = Self(rawValue: "xmark.octagon")
    static let xmark_octagon_fill: FairSymbol = Self(rawValue: "xmark.octagon.fill")
    static let divide: FairSymbol = Self(rawValue: "divide")
    static let divide_circle: FairSymbol = Self(rawValue: "divide.circle")
    static let divide_circle_fill: FairSymbol = Self(rawValue: "divide.circle.fill")
    static let divide_square: FairSymbol = Self(rawValue: "divide.square")
    static let divide_square_fill: FairSymbol = Self(rawValue: "divide.square.fill")
    static let equal: FairSymbol = Self(rawValue: "equal")
    static let equal_circle: FairSymbol = Self(rawValue: "equal.circle")
    static let equal_circle_fill: FairSymbol = Self(rawValue: "equal.circle.fill")
    static let equal_square: FairSymbol = Self(rawValue: "equal.square")
    static let equal_square_fill: FairSymbol = Self(rawValue: "equal.square.fill")
    static let lessthan: FairSymbol = Self(rawValue: "lessthan")
    static let lessthan_circle: FairSymbol = Self(rawValue: "lessthan.circle")
    static let lessthan_circle_fill: FairSymbol = Self(rawValue: "lessthan.circle.fill")
    static let lessthan_square: FairSymbol = Self(rawValue: "lessthan.square")
    static let lessthan_square_fill: FairSymbol = Self(rawValue: "lessthan.square.fill")
    static let greaterthan: FairSymbol = Self(rawValue: "greaterthan")
    static let greaterthan_circle: FairSymbol = Self(rawValue: "greaterthan.circle")
    static let greaterthan_circle_fill: FairSymbol = Self(rawValue: "greaterthan.circle.fill")
    static let greaterthan_square: FairSymbol = Self(rawValue: "greaterthan.square")
    static let greaterthan_square_fill: FairSymbol = Self(rawValue: "greaterthan.square.fill")
    static let chevron_left_forwardslash_chevron_right: FairSymbol = Self(rawValue: "chevron.left.forwardslash.chevron.right")
    static let parentheses: FairSymbol = Self(rawValue: "parentheses")
    static let curlybraces: FairSymbol = Self(rawValue: "curlybraces")
    static let curlybraces_square: FairSymbol = Self(rawValue: "curlybraces.square")
    static let curlybraces_square_fill: FairSymbol = Self(rawValue: "curlybraces.square.fill")
    static let ellipsis_curlybraces: FairSymbol = Self(rawValue: "ellipsis.curlybraces")
    static let number: FairSymbol = Self(rawValue: "number")
    static let number_circle: FairSymbol = Self(rawValue: "number.circle")
    static let number_circle_fill: FairSymbol = Self(rawValue: "number.circle.fill")
    static let number_square: FairSymbol = Self(rawValue: "number.square")
    static let number_square_fill: FairSymbol = Self(rawValue: "number.square.fill")
    static let x_squareroot: FairSymbol = Self(rawValue: "x.squareroot")
    static let xmark: FairSymbol = Self(rawValue: "xmark")
    static let xmark_circle: FairSymbol = Self(rawValue: "xmark.circle")
    static let xmark_circle_fill: FairSymbol = Self(rawValue: "xmark.circle.fill")
    static let xmark_square: FairSymbol = Self(rawValue: "xmark.square")
    static let xmark_square_fill: FairSymbol = Self(rawValue: "xmark.square.fill")
    static let checkmark: FairSymbol = Self(rawValue: "checkmark")
    static let checkmark_circle: FairSymbol = Self(rawValue: "checkmark.circle")
    static let checkmark_circle_fill: FairSymbol = Self(rawValue: "checkmark.circle.fill")
    static let checkmark_circle_trianglebadge_exclamationmark: FairSymbol = Self(rawValue: "checkmark.circle.trianglebadge.exclamationmark")
    static let checkmark_square: FairSymbol = Self(rawValue: "checkmark.square")
    static let checkmark_square_fill: FairSymbol = Self(rawValue: "checkmark.square.fill")
    static let checkmark_rectangle: FairSymbol = Self(rawValue: "checkmark.rectangle")
    static let checkmark_rectangle_fill: FairSymbol = Self(rawValue: "checkmark.rectangle.fill")
    static let checkmark_rectangle_portrait: FairSymbol = Self(rawValue: "checkmark.rectangle.portrait")
    static let checkmark_rectangle_portrait_fill: FairSymbol = Self(rawValue: "checkmark.rectangle.portrait.fill")
    static let checkmark_diamond: FairSymbol = Self(rawValue: "checkmark.diamond")
    static let checkmark_diamond_fill: FairSymbol = Self(rawValue: "checkmark.diamond.fill")
    static let checkmark_shield: FairSymbol = Self(rawValue: "checkmark.shield")
    static let checkmark_shield_fill: FairSymbol = Self(rawValue: "checkmark.shield.fill")
    static let chevron_left: FairSymbol = Self(rawValue: "chevron.left")
    static let chevron_left_circle: FairSymbol = Self(rawValue: "chevron.left.circle")
    static let chevron_left_circle_fill: FairSymbol = Self(rawValue: "chevron.left.circle.fill")
    static let chevron_left_square: FairSymbol = Self(rawValue: "chevron.left.square")
    static let chevron_left_square_fill: FairSymbol = Self(rawValue: "chevron.left.square.fill")
    static let chevron_backward: FairSymbol = Self(rawValue: "chevron.backward")
    static let chevron_backward_circle: FairSymbol = Self(rawValue: "chevron.backward.circle")
    static let chevron_backward_circle_fill: FairSymbol = Self(rawValue: "chevron.backward.circle.fill")
    static let chevron_backward_square: FairSymbol = Self(rawValue: "chevron.backward.square")
    static let chevron_backward_square_fill: FairSymbol = Self(rawValue: "chevron.backward.square.fill")
    static let chevron_right: FairSymbol = Self(rawValue: "chevron.right")
    static let chevron_right_circle: FairSymbol = Self(rawValue: "chevron.right.circle")
    static let chevron_right_circle_fill: FairSymbol = Self(rawValue: "chevron.right.circle.fill")
    static let chevron_right_square: FairSymbol = Self(rawValue: "chevron.right.square")
    static let chevron_right_square_fill: FairSymbol = Self(rawValue: "chevron.right.square.fill")
    static let chevron_forward: FairSymbol = Self(rawValue: "chevron.forward")
    static let chevron_forward_circle: FairSymbol = Self(rawValue: "chevron.forward.circle")
    static let chevron_forward_circle_fill: FairSymbol = Self(rawValue: "chevron.forward.circle.fill")
    static let chevron_forward_square: FairSymbol = Self(rawValue: "chevron.forward.square")
    static let chevron_forward_square_fill: FairSymbol = Self(rawValue: "chevron.forward.square.fill")
    static let chevron_left_2: FairSymbol = Self(rawValue: "chevron.left.2")
    static let chevron_backward_2: FairSymbol = Self(rawValue: "chevron.backward.2")
    static let chevron_right_2: FairSymbol = Self(rawValue: "chevron.right.2")
    static let chevron_forward_2: FairSymbol = Self(rawValue: "chevron.forward.2")
    static let chevron_up: FairSymbol = Self(rawValue: "chevron.up")
    static let chevron_up_circle: FairSymbol = Self(rawValue: "chevron.up.circle")
    static let chevron_up_circle_fill: FairSymbol = Self(rawValue: "chevron.up.circle.fill")
    static let chevron_up_square: FairSymbol = Self(rawValue: "chevron.up.square")
    static let chevron_up_square_fill: FairSymbol = Self(rawValue: "chevron.up.square.fill")
    static let chevron_down: FairSymbol = Self(rawValue: "chevron.down")
    static let chevron_down_circle: FairSymbol = Self(rawValue: "chevron.down.circle")
    static let chevron_down_circle_fill: FairSymbol = Self(rawValue: "chevron.down.circle.fill")
    static let chevron_down_square: FairSymbol = Self(rawValue: "chevron.down.square")
    static let chevron_down_square_fill: FairSymbol = Self(rawValue: "chevron.down.square.fill")
    static let control: FairSymbol = Self(rawValue: "control")
    static let projective: FairSymbol = Self(rawValue: "projective")
    static let chevron_up_chevron_down: FairSymbol = Self(rawValue: "chevron.up.chevron.down")
    static let chevron_compact_up: FairSymbol = Self(rawValue: "chevron.compact.up")
    static let chevron_compact_down: FairSymbol = Self(rawValue: "chevron.compact.down")
    static let chevron_compact_left: FairSymbol = Self(rawValue: "chevron.compact.left")
    static let chevron_compact_right: FairSymbol = Self(rawValue: "chevron.compact.right")
    static let arrow_left: FairSymbol = Self(rawValue: "arrow.left")
    static let arrow_left_circle: FairSymbol = Self(rawValue: "arrow.left.circle")
    static let arrow_left_circle_fill: FairSymbol = Self(rawValue: "arrow.left.circle.fill")
    static let arrow_left_square: FairSymbol = Self(rawValue: "arrow.left.square")
    static let arrow_left_square_fill: FairSymbol = Self(rawValue: "arrow.left.square.fill")
    static let arrow_backward: FairSymbol = Self(rawValue: "arrow.backward")
    static let arrow_backward_circle: FairSymbol = Self(rawValue: "arrow.backward.circle")
    static let arrow_backward_circle_fill: FairSymbol = Self(rawValue: "arrow.backward.circle.fill")
    static let arrow_backward_square: FairSymbol = Self(rawValue: "arrow.backward.square")
    static let arrow_backward_square_fill: FairSymbol = Self(rawValue: "arrow.backward.square.fill")
    static let arrow_right: FairSymbol = Self(rawValue: "arrow.right")
    static let arrow_right_circle: FairSymbol = Self(rawValue: "arrow.right.circle")
    static let arrow_right_circle_fill: FairSymbol = Self(rawValue: "arrow.right.circle.fill")
    static let arrow_right_square: FairSymbol = Self(rawValue: "arrow.right.square")
    static let arrow_right_square_fill: FairSymbol = Self(rawValue: "arrow.right.square.fill")
    static let arrow_forward: FairSymbol = Self(rawValue: "arrow.forward")
    static let arrow_forward_circle: FairSymbol = Self(rawValue: "arrow.forward.circle")
    static let arrow_forward_circle_fill: FairSymbol = Self(rawValue: "arrow.forward.circle.fill")
    static let arrow_forward_square: FairSymbol = Self(rawValue: "arrow.forward.square")
    static let arrow_forward_square_fill: FairSymbol = Self(rawValue: "arrow.forward.square.fill")
    static let arrow_up: FairSymbol = Self(rawValue: "arrow.up")
    static let arrow_up_circle: FairSymbol = Self(rawValue: "arrow.up.circle")
    static let arrow_up_circle_fill: FairSymbol = Self(rawValue: "arrow.up.circle.fill")
    static let arrow_up_square: FairSymbol = Self(rawValue: "arrow.up.square")
    static let arrow_up_square_fill: FairSymbol = Self(rawValue: "arrow.up.square.fill")
    static let arrow_down: FairSymbol = Self(rawValue: "arrow.down")
    static let arrow_down_circle: FairSymbol = Self(rawValue: "arrow.down.circle")
    static let arrow_down_circle_fill: FairSymbol = Self(rawValue: "arrow.down.circle.fill")
    static let arrow_down_square: FairSymbol = Self(rawValue: "arrow.down.square")
    static let arrow_down_square_fill: FairSymbol = Self(rawValue: "arrow.down.square.fill")
    static let arrow_up_left: FairSymbol = Self(rawValue: "arrow.up.left")
    static let arrow_up_left_circle: FairSymbol = Self(rawValue: "arrow.up.left.circle")
    static let arrow_up_left_circle_fill: FairSymbol = Self(rawValue: "arrow.up.left.circle.fill")
    static let arrow_up_left_square: FairSymbol = Self(rawValue: "arrow.up.left.square")
    static let arrow_up_left_square_fill: FairSymbol = Self(rawValue: "arrow.up.left.square.fill")
    static let arrow_up_backward: FairSymbol = Self(rawValue: "arrow.up.backward")
    static let arrow_up_backward_circle: FairSymbol = Self(rawValue: "arrow.up.backward.circle")
    static let arrow_up_backward_circle_fill: FairSymbol = Self(rawValue: "arrow.up.backward.circle.fill")
    static let arrow_up_backward_square: FairSymbol = Self(rawValue: "arrow.up.backward.square")
    static let arrow_up_backward_square_fill: FairSymbol = Self(rawValue: "arrow.up.backward.square.fill")
    static let arrow_up_right: FairSymbol = Self(rawValue: "arrow.up.right")
    static let arrow_up_right_circle: FairSymbol = Self(rawValue: "arrow.up.right.circle")
    static let arrow_up_right_circle_fill: FairSymbol = Self(rawValue: "arrow.up.right.circle.fill")
    static let arrow_up_right_square: FairSymbol = Self(rawValue: "arrow.up.right.square")
    static let arrow_up_right_square_fill: FairSymbol = Self(rawValue: "arrow.up.right.square.fill")
    static let arrow_up_forward: FairSymbol = Self(rawValue: "arrow.up.forward")
    static let arrow_up_forward_circle: FairSymbol = Self(rawValue: "arrow.up.forward.circle")
    static let arrow_up_forward_circle_fill: FairSymbol = Self(rawValue: "arrow.up.forward.circle.fill")
    static let arrow_up_forward_square: FairSymbol = Self(rawValue: "arrow.up.forward.square")
    static let arrow_up_forward_square_fill: FairSymbol = Self(rawValue: "arrow.up.forward.square.fill")
    static let arrow_down_left: FairSymbol = Self(rawValue: "arrow.down.left")
    static let arrow_down_left_circle: FairSymbol = Self(rawValue: "arrow.down.left.circle")
    static let arrow_down_left_circle_fill: FairSymbol = Self(rawValue: "arrow.down.left.circle.fill")
    static let arrow_down_left_square: FairSymbol = Self(rawValue: "arrow.down.left.square")
    static let arrow_down_left_square_fill: FairSymbol = Self(rawValue: "arrow.down.left.square.fill")
    static let arrow_down_backward: FairSymbol = Self(rawValue: "arrow.down.backward")
    static let arrow_down_backward_circle: FairSymbol = Self(rawValue: "arrow.down.backward.circle")
    static let arrow_down_backward_circle_fill: FairSymbol = Self(rawValue: "arrow.down.backward.circle.fill")
    static let arrow_down_backward_square: FairSymbol = Self(rawValue: "arrow.down.backward.square")
    static let arrow_down_backward_square_fill: FairSymbol = Self(rawValue: "arrow.down.backward.square.fill")
    static let arrow_down_right: FairSymbol = Self(rawValue: "arrow.down.right")
    static let arrow_down_right_circle: FairSymbol = Self(rawValue: "arrow.down.right.circle")
    static let arrow_down_right_circle_fill: FairSymbol = Self(rawValue: "arrow.down.right.circle.fill")
    static let arrow_down_right_square: FairSymbol = Self(rawValue: "arrow.down.right.square")
    static let arrow_down_right_square_fill: FairSymbol = Self(rawValue: "arrow.down.right.square.fill")
    static let arrow_down_forward: FairSymbol = Self(rawValue: "arrow.down.forward")
    static let arrow_down_forward_circle: FairSymbol = Self(rawValue: "arrow.down.forward.circle")
    static let arrow_down_forward_circle_fill: FairSymbol = Self(rawValue: "arrow.down.forward.circle.fill")
    static let arrow_down_forward_square: FairSymbol = Self(rawValue: "arrow.down.forward.square")
    static let arrow_down_forward_square_fill: FairSymbol = Self(rawValue: "arrow.down.forward.square.fill")
    static let arrow_left_arrow_right: FairSymbol = Self(rawValue: "arrow.left.arrow.right")
    static let arrow_left_arrow_right_circle: FairSymbol = Self(rawValue: "arrow.left.arrow.right.circle")
    static let arrow_left_arrow_right_circle_fill: FairSymbol = Self(rawValue: "arrow.left.arrow.right.circle.fill")
    static let arrow_left_arrow_right_square: FairSymbol = Self(rawValue: "arrow.left.arrow.right.square")
    static let arrow_left_arrow_right_square_fill: FairSymbol = Self(rawValue: "arrow.left.arrow.right.square.fill")
    static let arrow_up_arrow_down: FairSymbol = Self(rawValue: "arrow.up.arrow.down")
    static let arrow_up_arrow_down_circle: FairSymbol = Self(rawValue: "arrow.up.arrow.down.circle")
    static let arrow_up_arrow_down_circle_fill: FairSymbol = Self(rawValue: "arrow.up.arrow.down.circle.fill")
    static let arrow_up_arrow_down_square: FairSymbol = Self(rawValue: "arrow.up.arrow.down.square")
    static let arrow_up_arrow_down_square_fill: FairSymbol = Self(rawValue: "arrow.up.arrow.down.square.fill")
    static let arrow_turn_down_left: FairSymbol = Self(rawValue: "arrow.turn.down.left")
    static let arrow_turn_up_left: FairSymbol = Self(rawValue: "arrow.turn.up.left")
    static let arrow_turn_down_right: FairSymbol = Self(rawValue: "arrow.turn.down.right")
    static let arrow_turn_up_right: FairSymbol = Self(rawValue: "arrow.turn.up.right")
    static let arrow_turn_right_up: FairSymbol = Self(rawValue: "arrow.turn.right.up")
    static let arrow_turn_left_up: FairSymbol = Self(rawValue: "arrow.turn.left.up")
    static let arrow_turn_right_down: FairSymbol = Self(rawValue: "arrow.turn.right.down")
    static let arrow_turn_left_down: FairSymbol = Self(rawValue: "arrow.turn.left.down")
    static let arrow_uturn_left: FairSymbol = Self(rawValue: "arrow.uturn.left")
    static let arrow_uturn_left_circle: FairSymbol = Self(rawValue: "arrow.uturn.left.circle")
    static let arrow_uturn_left_circle_fill: FairSymbol = Self(rawValue: "arrow.uturn.left.circle.fill")
    static let arrow_uturn_left_circle_badge_ellipsis: FairSymbol = Self(rawValue: "arrow.uturn.left.circle.badge.ellipsis")
    static let arrow_uturn_left_square: FairSymbol = Self(rawValue: "arrow.uturn.left.square")
    static let arrow_uturn_left_square_fill: FairSymbol = Self(rawValue: "arrow.uturn.left.square.fill")
    static let arrow_uturn_backward: FairSymbol = Self(rawValue: "arrow.uturn.backward")
    static let arrow_uturn_backward_circle: FairSymbol = Self(rawValue: "arrow.uturn.backward.circle")
    static let arrow_uturn_backward_circle_fill: FairSymbol = Self(rawValue: "arrow.uturn.backward.circle.fill")
    static let arrow_uturn_backward_circle_badge_ellipsis: FairSymbol = Self(rawValue: "arrow.uturn.backward.circle.badge.ellipsis")
    static let arrow_uturn_backward_square: FairSymbol = Self(rawValue: "arrow.uturn.backward.square")
    static let arrow_uturn_backward_square_fill: FairSymbol = Self(rawValue: "arrow.uturn.backward.square.fill")
    static let arrow_uturn_right: FairSymbol = Self(rawValue: "arrow.uturn.right")
    static let arrow_uturn_right_circle: FairSymbol = Self(rawValue: "arrow.uturn.right.circle")
    static let arrow_uturn_right_circle_fill: FairSymbol = Self(rawValue: "arrow.uturn.right.circle.fill")
    static let arrow_uturn_right_square: FairSymbol = Self(rawValue: "arrow.uturn.right.square")
    static let arrow_uturn_right_square_fill: FairSymbol = Self(rawValue: "arrow.uturn.right.square.fill")
    static let arrow_uturn_forward: FairSymbol = Self(rawValue: "arrow.uturn.forward")
    static let arrow_uturn_forward_circle: FairSymbol = Self(rawValue: "arrow.uturn.forward.circle")
    static let arrow_uturn_forward_circle_fill: FairSymbol = Self(rawValue: "arrow.uturn.forward.circle.fill")
    static let arrow_uturn_forward_square: FairSymbol = Self(rawValue: "arrow.uturn.forward.square")
    static let arrow_uturn_forward_square_fill: FairSymbol = Self(rawValue: "arrow.uturn.forward.square.fill")
    static let arrow_uturn_up: FairSymbol = Self(rawValue: "arrow.uturn.up")
    static let arrow_uturn_up_circle: FairSymbol = Self(rawValue: "arrow.uturn.up.circle")
    static let arrow_uturn_up_circle_fill: FairSymbol = Self(rawValue: "arrow.uturn.up.circle.fill")
    static let arrow_uturn_up_square: FairSymbol = Self(rawValue: "arrow.uturn.up.square")
    static let arrow_uturn_up_square_fill: FairSymbol = Self(rawValue: "arrow.uturn.up.square.fill")
    static let arrow_uturn_down: FairSymbol = Self(rawValue: "arrow.uturn.down")
    static let arrow_uturn_down_circle: FairSymbol = Self(rawValue: "arrow.uturn.down.circle")
    static let arrow_uturn_down_circle_fill: FairSymbol = Self(rawValue: "arrow.uturn.down.circle.fill")
    static let arrow_uturn_down_square: FairSymbol = Self(rawValue: "arrow.uturn.down.square")
    static let arrow_uturn_down_square_fill: FairSymbol = Self(rawValue: "arrow.uturn.down.square.fill")
    static let arrow_up_and_down_and_arrow_left_and_right: FairSymbol = Self(rawValue: "arrow.up.and.down.and.arrow.left.and.right")
    static let arrow_up_left_and_down_right_and_arrow_up_right_and_down_left: FairSymbol = Self(rawValue: "arrow.up.left.and.down.right.and.arrow.up.right.and.down.left")
    static let arrow_left_and_right: FairSymbol = Self(rawValue: "arrow.left.and.right")
    static let arrow_left_and_right_circle: FairSymbol = Self(rawValue: "arrow.left.and.right.circle")
    static let arrow_left_and_right_circle_fill: FairSymbol = Self(rawValue: "arrow.left.and.right.circle.fill")
    static let arrow_left_and_right_square: FairSymbol = Self(rawValue: "arrow.left.and.right.square")
    static let arrow_left_and_right_square_fill: FairSymbol = Self(rawValue: "arrow.left.and.right.square.fill")
    static let arrow_up_and_down: FairSymbol = Self(rawValue: "arrow.up.and.down")
    static let arrow_up_and_down_circle: FairSymbol = Self(rawValue: "arrow.up.and.down.circle")
    static let arrow_up_and_down_circle_fill: FairSymbol = Self(rawValue: "arrow.up.and.down.circle.fill")
    static let arrow_up_and_down_square: FairSymbol = Self(rawValue: "arrow.up.and.down.square")
    static let arrow_up_and_down_square_fill: FairSymbol = Self(rawValue: "arrow.up.and.down.square.fill")
    static let arrow_up_to_line: FairSymbol = Self(rawValue: "arrow.up.to.line")
    static let arrow_up_to_line_compact: FairSymbol = Self(rawValue: "arrow.up.to.line.compact")
    static let arrow_up_to_line_circle: FairSymbol = Self(rawValue: "arrow.up.to.line.circle")
    static let arrow_up_to_line_circle_fill: FairSymbol = Self(rawValue: "arrow.up.to.line.circle.fill")
    static let arrow_down_to_line: FairSymbol = Self(rawValue: "arrow.down.to.line")
    static let arrow_down_to_line_compact: FairSymbol = Self(rawValue: "arrow.down.to.line.compact")
    static let arrow_down_to_line_circle: FairSymbol = Self(rawValue: "arrow.down.to.line.circle")
    static let arrow_down_to_line_circle_fill: FairSymbol = Self(rawValue: "arrow.down.to.line.circle.fill")
    static let arrow_left_to_line: FairSymbol = Self(rawValue: "arrow.left.to.line")
    static let arrow_left_to_line_compact: FairSymbol = Self(rawValue: "arrow.left.to.line.compact")
    static let arrow_left_to_line_circle: FairSymbol = Self(rawValue: "arrow.left.to.line.circle")
    static let arrow_left_to_line_circle_fill: FairSymbol = Self(rawValue: "arrow.left.to.line.circle.fill")
    static let arrow_backward_to_line: FairSymbol = Self(rawValue: "arrow.backward.to.line")
    static let arrow_backward_to_line_circle: FairSymbol = Self(rawValue: "arrow.backward.to.line.circle")
    static let arrow_backward_to_line_circle_fill: FairSymbol = Self(rawValue: "arrow.backward.to.line.circle.fill")
    static let arrow_right_to_line: FairSymbol = Self(rawValue: "arrow.right.to.line")
    static let arrow_right_to_line_compact: FairSymbol = Self(rawValue: "arrow.right.to.line.compact")
    static let arrow_right_to_line_circle: FairSymbol = Self(rawValue: "arrow.right.to.line.circle")
    static let arrow_right_to_line_circle_fill: FairSymbol = Self(rawValue: "arrow.right.to.line.circle.fill")
    static let arrow_forward_to_line: FairSymbol = Self(rawValue: "arrow.forward.to.line")
    static let arrow_forward_to_line_circle: FairSymbol = Self(rawValue: "arrow.forward.to.line.circle")
    static let arrow_forward_to_line_circle_fill: FairSymbol = Self(rawValue: "arrow.forward.to.line.circle.fill")
    static let arrow_clockwise: FairSymbol = Self(rawValue: "arrow.clockwise")
    static let arrow_clockwise_circle: FairSymbol = Self(rawValue: "arrow.clockwise.circle")
    static let arrow_clockwise_circle_fill: FairSymbol = Self(rawValue: "arrow.clockwise.circle.fill")
    static let arrow_counterclockwise: FairSymbol = Self(rawValue: "arrow.counterclockwise")
    static let arrow_counterclockwise_circle: FairSymbol = Self(rawValue: "arrow.counterclockwise.circle")
    static let arrow_counterclockwise_circle_fill: FairSymbol = Self(rawValue: "arrow.counterclockwise.circle.fill")
    static let arrow_up_left_and_arrow_down_right: FairSymbol = Self(rawValue: "arrow.up.left.and.arrow.down.right")
    static let arrow_up_left_and_arrow_down_right_circle: FairSymbol = Self(rawValue: "arrow.up.left.and.arrow.down.right.circle")
    static let arrow_up_left_and_arrow_down_right_circle_fill: FairSymbol = Self(rawValue: "arrow.up.left.and.arrow.down.right.circle.fill")
    static let arrow_up_backward_and_arrow_down_forward: FairSymbol = Self(rawValue: "arrow.up.backward.and.arrow.down.forward")
    static let arrow_up_backward_and_arrow_down_forward_circle: FairSymbol = Self(rawValue: "arrow.up.backward.and.arrow.down.forward.circle")
    static let arrow_up_backward_and_arrow_down_forward_circle_fill: FairSymbol = Self(rawValue: "arrow.up.backward.and.arrow.down.forward.circle.fill")
    static let arrow_down_right_and_arrow_up_left: FairSymbol = Self(rawValue: "arrow.down.right.and.arrow.up.left")
    static let arrow_down_right_and_arrow_up_left_circle: FairSymbol = Self(rawValue: "arrow.down.right.and.arrow.up.left.circle")
    static let arrow_down_right_and_arrow_up_left_circle_fill: FairSymbol = Self(rawValue: "arrow.down.right.and.arrow.up.left.circle.fill")
    static let arrow_down_forward_and_arrow_up_backward: FairSymbol = Self(rawValue: "arrow.down.forward.and.arrow.up.backward")
    static let arrow_down_forward_and_arrow_up_backward_circle: FairSymbol = Self(rawValue: "arrow.down.forward.and.arrow.up.backward.circle")
    static let arrow_down_forward_and_arrow_up_backward_circle_fill: FairSymbol = Self(rawValue: "arrow.down.forward.and.arrow.up.backward.circle.fill")
    static let `return`: FairSymbol = Self(rawValue: "`")
    static let return_left: FairSymbol = Self(rawValue: "return.left")
    static let return_right: FairSymbol = Self(rawValue: "return.right")
    static let arrow_2_squarepath: FairSymbol = Self(rawValue: "arrow.2.squarepath")
    static let arrow_triangle_2_circlepath: FairSymbol = Self(rawValue: "arrow.triangle.2.circlepath")
    static let arrow_triangle_2_circlepath_circle: FairSymbol = Self(rawValue: "arrow.triangle.2.circlepath.circle")
    static let arrow_triangle_2_circlepath_circle_fill: FairSymbol = Self(rawValue: "arrow.triangle.2.circlepath.circle.fill")
    static let exclamationmark_arrow_triangle_2_circlepath: FairSymbol = Self(rawValue: "exclamationmark.arrow.triangle.2.circlepath")
    static let arrow_triangle_capsulepath: FairSymbol = Self(rawValue: "arrow.triangle.capsulepath")
    static let arrow_3_trianglepath: FairSymbol = Self(rawValue: "arrow.3.trianglepath")
    static let arrow_triangle_turn_up_right_diamond: FairSymbol = Self(rawValue: "arrow.triangle.turn.up.right.diamond")
    static let arrow_triangle_turn_up_right_diamond_fill: FairSymbol = Self(rawValue: "arrow.triangle.turn.up.right.diamond.fill")
    static let arrow_triangle_turn_up_right_circle: FairSymbol = Self(rawValue: "arrow.triangle.turn.up.right.circle")
    static let arrow_triangle_turn_up_right_circle_fill: FairSymbol = Self(rawValue: "arrow.triangle.turn.up.right.circle.fill")
    static let arrow_triangle_merge: FairSymbol = Self(rawValue: "arrow.triangle.merge")
    static let arrow_triangle_swap: FairSymbol = Self(rawValue: "arrow.triangle.swap")
    static let arrow_triangle_branch: FairSymbol = Self(rawValue: "arrow.triangle.branch")
    static let arrow_triangle_pull: FairSymbol = Self(rawValue: "arrow.triangle.pull")
    static let arrowtriangle_left: FairSymbol = Self(rawValue: "arrowtriangle.left")
    static let arrowtriangle_left_fill: FairSymbol = Self(rawValue: "arrowtriangle.left.fill")
    static let arrowtriangle_left_circle: FairSymbol = Self(rawValue: "arrowtriangle.left.circle")
    static let arrowtriangle_left_circle_fill: FairSymbol = Self(rawValue: "arrowtriangle.left.circle.fill")
    static let arrowtriangle_left_square: FairSymbol = Self(rawValue: "arrowtriangle.left.square")
    static let arrowtriangle_left_square_fill: FairSymbol = Self(rawValue: "arrowtriangle.left.square.fill")
    static let arrowtriangle_backward: FairSymbol = Self(rawValue: "arrowtriangle.backward")
    static let arrowtriangle_backward_fill: FairSymbol = Self(rawValue: "arrowtriangle.backward.fill")
    static let arrowtriangle_backward_circle: FairSymbol = Self(rawValue: "arrowtriangle.backward.circle")
    static let arrowtriangle_backward_circle_fill: FairSymbol = Self(rawValue: "arrowtriangle.backward.circle.fill")
    static let arrowtriangle_backward_square: FairSymbol = Self(rawValue: "arrowtriangle.backward.square")
    static let arrowtriangle_backward_square_fill: FairSymbol = Self(rawValue: "arrowtriangle.backward.square.fill")
    static let arrowtriangle_right: FairSymbol = Self(rawValue: "arrowtriangle.right")
    static let arrowtriangle_right_fill: FairSymbol = Self(rawValue: "arrowtriangle.right.fill")
    static let arrowtriangle_right_circle: FairSymbol = Self(rawValue: "arrowtriangle.right.circle")
    static let arrowtriangle_right_circle_fill: FairSymbol = Self(rawValue: "arrowtriangle.right.circle.fill")
    static let arrowtriangle_right_square: FairSymbol = Self(rawValue: "arrowtriangle.right.square")
    static let arrowtriangle_right_square_fill: FairSymbol = Self(rawValue: "arrowtriangle.right.square.fill")
    static let arrowtriangle_forward: FairSymbol = Self(rawValue: "arrowtriangle.forward")
    static let arrowtriangle_forward_fill: FairSymbol = Self(rawValue: "arrowtriangle.forward.fill")
    static let arrowtriangle_forward_circle: FairSymbol = Self(rawValue: "arrowtriangle.forward.circle")
    static let arrowtriangle_forward_circle_fill: FairSymbol = Self(rawValue: "arrowtriangle.forward.circle.fill")
    static let arrowtriangle_forward_square: FairSymbol = Self(rawValue: "arrowtriangle.forward.square")
    static let arrowtriangle_forward_square_fill: FairSymbol = Self(rawValue: "arrowtriangle.forward.square.fill")
    static let arrowtriangle_up: FairSymbol = Self(rawValue: "arrowtriangle.up")
    static let arrowtriangle_up_fill: FairSymbol = Self(rawValue: "arrowtriangle.up.fill")
    static let arrowtriangle_up_circle: FairSymbol = Self(rawValue: "arrowtriangle.up.circle")
    static let arrowtriangle_up_circle_fill: FairSymbol = Self(rawValue: "arrowtriangle.up.circle.fill")
    static let arrowtriangle_up_square: FairSymbol = Self(rawValue: "arrowtriangle.up.square")
    static let arrowtriangle_up_square_fill: FairSymbol = Self(rawValue: "arrowtriangle.up.square.fill")
    static let arrowtriangle_down: FairSymbol = Self(rawValue: "arrowtriangle.down")
    static let arrowtriangle_down_fill: FairSymbol = Self(rawValue: "arrowtriangle.down.fill")
    static let arrowtriangle_down_circle: FairSymbol = Self(rawValue: "arrowtriangle.down.circle")
    static let arrowtriangle_down_circle_fill: FairSymbol = Self(rawValue: "arrowtriangle.down.circle.fill")
    static let arrowtriangle_down_square: FairSymbol = Self(rawValue: "arrowtriangle.down.square")
    static let arrowtriangle_down_square_fill: FairSymbol = Self(rawValue: "arrowtriangle.down.square.fill")
    static let slash_circle: FairSymbol = Self(rawValue: "slash.circle")
    static let slash_circle_fill: FairSymbol = Self(rawValue: "slash.circle.fill")
    static let asterisk: FairSymbol = Self(rawValue: "asterisk")
    static let asterisk_circle: FairSymbol = Self(rawValue: "asterisk.circle")
    static let asterisk_circle_fill: FairSymbol = Self(rawValue: "asterisk.circle.fill")
    static let a_circle: FairSymbol = Self(rawValue: "a.circle")
    static let a_circle_fill: FairSymbol = Self(rawValue: "a.circle.fill")
    static let a_square: FairSymbol = Self(rawValue: "a.square")
    static let a_square_fill: FairSymbol = Self(rawValue: "a.square.fill")
    static let b_circle: FairSymbol = Self(rawValue: "b.circle")
    static let b_circle_fill: FairSymbol = Self(rawValue: "b.circle.fill")
    static let b_square: FairSymbol = Self(rawValue: "b.square")
    static let b_square_fill: FairSymbol = Self(rawValue: "b.square.fill")
    static let c_circle: FairSymbol = Self(rawValue: "c.circle")
    static let c_circle_fill: FairSymbol = Self(rawValue: "c.circle.fill")
    static let c_square: FairSymbol = Self(rawValue: "c.square")
    static let c_square_fill: FairSymbol = Self(rawValue: "c.square.fill")
    static let d_circle: FairSymbol = Self(rawValue: "d.circle")
    static let d_circle_fill: FairSymbol = Self(rawValue: "d.circle.fill")
    static let d_square: FairSymbol = Self(rawValue: "d.square")
    static let d_square_fill: FairSymbol = Self(rawValue: "d.square.fill")
    static let e_circle: FairSymbol = Self(rawValue: "e.circle")
    static let e_circle_fill: FairSymbol = Self(rawValue: "e.circle.fill")
    static let e_square: FairSymbol = Self(rawValue: "e.square")
    static let e_square_fill: FairSymbol = Self(rawValue: "e.square.fill")
    static let f_circle: FairSymbol = Self(rawValue: "f.circle")
    static let f_circle_fill: FairSymbol = Self(rawValue: "f.circle.fill")
    static let f_square: FairSymbol = Self(rawValue: "f.square")
    static let f_square_fill: FairSymbol = Self(rawValue: "f.square.fill")
    static let g_circle: FairSymbol = Self(rawValue: "g.circle")
    static let g_circle_fill: FairSymbol = Self(rawValue: "g.circle.fill")
    static let g_square: FairSymbol = Self(rawValue: "g.square")
    static let g_square_fill: FairSymbol = Self(rawValue: "g.square.fill")
    static let h_circle: FairSymbol = Self(rawValue: "h.circle")
    static let h_circle_fill: FairSymbol = Self(rawValue: "h.circle.fill")
    static let h_square: FairSymbol = Self(rawValue: "h.square")
    static let h_square_fill: FairSymbol = Self(rawValue: "h.square.fill")
    static let i_circle: FairSymbol = Self(rawValue: "i.circle")
    static let i_circle_fill: FairSymbol = Self(rawValue: "i.circle.fill")
    static let i_square: FairSymbol = Self(rawValue: "i.square")
    static let i_square_fill: FairSymbol = Self(rawValue: "i.square.fill")
    static let j_circle: FairSymbol = Self(rawValue: "j.circle")
    static let j_circle_fill: FairSymbol = Self(rawValue: "j.circle.fill")
    static let j_square: FairSymbol = Self(rawValue: "j.square")
    static let j_square_fill: FairSymbol = Self(rawValue: "j.square.fill")
    static let k_circle: FairSymbol = Self(rawValue: "k.circle")
    static let k_circle_fill: FairSymbol = Self(rawValue: "k.circle.fill")
    static let k_square: FairSymbol = Self(rawValue: "k.square")
    static let k_square_fill: FairSymbol = Self(rawValue: "k.square.fill")
    static let l_circle: FairSymbol = Self(rawValue: "l.circle")
    static let l_circle_fill: FairSymbol = Self(rawValue: "l.circle.fill")
    static let l_square: FairSymbol = Self(rawValue: "l.square")
    static let l_square_fill: FairSymbol = Self(rawValue: "l.square.fill")
    static let m_circle: FairSymbol = Self(rawValue: "m.circle")
    static let m_circle_fill: FairSymbol = Self(rawValue: "m.circle.fill")
    static let m_square: FairSymbol = Self(rawValue: "m.square")
    static let m_square_fill: FairSymbol = Self(rawValue: "m.square.fill")
    static let n_circle: FairSymbol = Self(rawValue: "n.circle")
    static let n_circle_fill: FairSymbol = Self(rawValue: "n.circle.fill")
    static let n_square: FairSymbol = Self(rawValue: "n.square")
    static let n_square_fill: FairSymbol = Self(rawValue: "n.square.fill")
    static let o_circle: FairSymbol = Self(rawValue: "o.circle")
    static let o_circle_fill: FairSymbol = Self(rawValue: "o.circle.fill")
    static let o_square: FairSymbol = Self(rawValue: "o.square")
    static let o_square_fill: FairSymbol = Self(rawValue: "o.square.fill")
    static let p_circle: FairSymbol = Self(rawValue: "p.circle")
    static let p_circle_fill: FairSymbol = Self(rawValue: "p.circle.fill")
    static let p_square: FairSymbol = Self(rawValue: "p.square")
    static let p_square_fill: FairSymbol = Self(rawValue: "p.square.fill")
    static let q_circle: FairSymbol = Self(rawValue: "q.circle")
    static let q_circle_fill: FairSymbol = Self(rawValue: "q.circle.fill")
    static let q_square: FairSymbol = Self(rawValue: "q.square")
    static let q_square_fill: FairSymbol = Self(rawValue: "q.square.fill")
    static let r_circle: FairSymbol = Self(rawValue: "r.circle")
    static let r_circle_fill: FairSymbol = Self(rawValue: "r.circle.fill")
    static let r_square: FairSymbol = Self(rawValue: "r.square")
    static let r_square_fill: FairSymbol = Self(rawValue: "r.square.fill")
    static let s_circle: FairSymbol = Self(rawValue: "s.circle")
    static let s_circle_fill: FairSymbol = Self(rawValue: "s.circle.fill")
    static let s_square: FairSymbol = Self(rawValue: "s.square")
    static let s_square_fill: FairSymbol = Self(rawValue: "s.square.fill")
    static let t_circle: FairSymbol = Self(rawValue: "t.circle")
    static let t_circle_fill: FairSymbol = Self(rawValue: "t.circle.fill")
    static let t_square: FairSymbol = Self(rawValue: "t.square")
    static let t_square_fill: FairSymbol = Self(rawValue: "t.square.fill")
    static let u_circle: FairSymbol = Self(rawValue: "u.circle")
    static let u_circle_fill: FairSymbol = Self(rawValue: "u.circle.fill")
    static let u_square: FairSymbol = Self(rawValue: "u.square")
    static let u_square_fill: FairSymbol = Self(rawValue: "u.square.fill")
    static let v_circle: FairSymbol = Self(rawValue: "v.circle")
    static let v_circle_fill: FairSymbol = Self(rawValue: "v.circle.fill")
    static let v_square: FairSymbol = Self(rawValue: "v.square")
    static let v_square_fill: FairSymbol = Self(rawValue: "v.square.fill")
    static let w_circle: FairSymbol = Self(rawValue: "w.circle")
    static let w_circle_fill: FairSymbol = Self(rawValue: "w.circle.fill")
    static let w_square: FairSymbol = Self(rawValue: "w.square")
    static let w_square_fill: FairSymbol = Self(rawValue: "w.square.fill")
    static let x_circle: FairSymbol = Self(rawValue: "x.circle")
    static let x_circle_fill: FairSymbol = Self(rawValue: "x.circle.fill")
    static let x_square: FairSymbol = Self(rawValue: "x.square")
    static let x_square_fill: FairSymbol = Self(rawValue: "x.square.fill")
    static let y_circle: FairSymbol = Self(rawValue: "y.circle")
    static let y_circle_fill: FairSymbol = Self(rawValue: "y.circle.fill")
    static let y_square: FairSymbol = Self(rawValue: "y.square")
    static let y_square_fill: FairSymbol = Self(rawValue: "y.square.fill")
    static let z_circle: FairSymbol = Self(rawValue: "z.circle")
    static let z_circle_fill: FairSymbol = Self(rawValue: "z.circle.fill")
    static let z_square: FairSymbol = Self(rawValue: "z.square")
    static let z_square_fill: FairSymbol = Self(rawValue: "z.square.fill")
    static let dollarsign_circle: FairSymbol = Self(rawValue: "dollarsign.circle")
    static let dollarsign_circle_fill: FairSymbol = Self(rawValue: "dollarsign.circle.fill")
    static let dollarsign_square: FairSymbol = Self(rawValue: "dollarsign.square")
    static let dollarsign_square_fill: FairSymbol = Self(rawValue: "dollarsign.square.fill")
    static let centsign_circle: FairSymbol = Self(rawValue: "centsign.circle")
    static let centsign_circle_fill: FairSymbol = Self(rawValue: "centsign.circle.fill")
    static let centsign_square: FairSymbol = Self(rawValue: "centsign.square")
    static let centsign_square_fill: FairSymbol = Self(rawValue: "centsign.square.fill")
    static let yensign_circle: FairSymbol = Self(rawValue: "yensign.circle")
    static let yensign_circle_fill: FairSymbol = Self(rawValue: "yensign.circle.fill")
    static let yensign_square: FairSymbol = Self(rawValue: "yensign.square")
    static let yensign_square_fill: FairSymbol = Self(rawValue: "yensign.square.fill")
    static let sterlingsign_circle: FairSymbol = Self(rawValue: "sterlingsign.circle")
    static let sterlingsign_circle_fill: FairSymbol = Self(rawValue: "sterlingsign.circle.fill")
    static let sterlingsign_square: FairSymbol = Self(rawValue: "sterlingsign.square")
    static let sterlingsign_square_fill: FairSymbol = Self(rawValue: "sterlingsign.square.fill")
    static let francsign_circle: FairSymbol = Self(rawValue: "francsign.circle")
    static let francsign_circle_fill: FairSymbol = Self(rawValue: "francsign.circle.fill")
    static let francsign_square: FairSymbol = Self(rawValue: "francsign.square")
    static let francsign_square_fill: FairSymbol = Self(rawValue: "francsign.square.fill")
    static let florinsign_circle: FairSymbol = Self(rawValue: "florinsign.circle")
    static let florinsign_circle_fill: FairSymbol = Self(rawValue: "florinsign.circle.fill")
    static let florinsign_square: FairSymbol = Self(rawValue: "florinsign.square")
    static let florinsign_square_fill: FairSymbol = Self(rawValue: "florinsign.square.fill")
    static let turkishlirasign_circle: FairSymbol = Self(rawValue: "turkishlirasign.circle")
    static let turkishlirasign_circle_fill: FairSymbol = Self(rawValue: "turkishlirasign.circle.fill")
    static let turkishlirasign_square: FairSymbol = Self(rawValue: "turkishlirasign.square")
    static let turkishlirasign_square_fill: FairSymbol = Self(rawValue: "turkishlirasign.square.fill")
    static let rublesign_circle: FairSymbol = Self(rawValue: "rublesign.circle")
    static let rublesign_circle_fill: FairSymbol = Self(rawValue: "rublesign.circle.fill")
    static let rublesign_square: FairSymbol = Self(rawValue: "rublesign.square")
    static let rublesign_square_fill: FairSymbol = Self(rawValue: "rublesign.square.fill")
    static let eurosign_circle: FairSymbol = Self(rawValue: "eurosign.circle")
    static let eurosign_circle_fill: FairSymbol = Self(rawValue: "eurosign.circle.fill")
    static let eurosign_square: FairSymbol = Self(rawValue: "eurosign.square")
    static let eurosign_square_fill: FairSymbol = Self(rawValue: "eurosign.square.fill")
    static let dongsign_circle: FairSymbol = Self(rawValue: "dongsign.circle")
    static let dongsign_circle_fill: FairSymbol = Self(rawValue: "dongsign.circle.fill")
    static let dongsign_square: FairSymbol = Self(rawValue: "dongsign.square")
    static let dongsign_square_fill: FairSymbol = Self(rawValue: "dongsign.square.fill")
    static let indianrupeesign_circle: FairSymbol = Self(rawValue: "indianrupeesign.circle")
    static let indianrupeesign_circle_fill: FairSymbol = Self(rawValue: "indianrupeesign.circle.fill")
    static let indianrupeesign_square: FairSymbol = Self(rawValue: "indianrupeesign.square")
    static let indianrupeesign_square_fill: FairSymbol = Self(rawValue: "indianrupeesign.square.fill")
    static let tengesign_circle: FairSymbol = Self(rawValue: "tengesign.circle")
    static let tengesign_circle_fill: FairSymbol = Self(rawValue: "tengesign.circle.fill")
    static let tengesign_square: FairSymbol = Self(rawValue: "tengesign.square")
    static let tengesign_square_fill: FairSymbol = Self(rawValue: "tengesign.square.fill")
    static let pesetasign_circle: FairSymbol = Self(rawValue: "pesetasign.circle")
    static let pesetasign_circle_fill: FairSymbol = Self(rawValue: "pesetasign.circle.fill")
    static let pesetasign_square: FairSymbol = Self(rawValue: "pesetasign.square")
    static let pesetasign_square_fill: FairSymbol = Self(rawValue: "pesetasign.square.fill")
    static let pesosign_circle: FairSymbol = Self(rawValue: "pesosign.circle")
    static let pesosign_circle_fill: FairSymbol = Self(rawValue: "pesosign.circle.fill")
    static let pesosign_square: FairSymbol = Self(rawValue: "pesosign.square")
    static let pesosign_square_fill: FairSymbol = Self(rawValue: "pesosign.square.fill")
    static let kipsign_circle: FairSymbol = Self(rawValue: "kipsign.circle")
    static let kipsign_circle_fill: FairSymbol = Self(rawValue: "kipsign.circle.fill")
    static let kipsign_square: FairSymbol = Self(rawValue: "kipsign.square")
    static let kipsign_square_fill: FairSymbol = Self(rawValue: "kipsign.square.fill")
    static let wonsign_circle: FairSymbol = Self(rawValue: "wonsign.circle")
    static let wonsign_circle_fill: FairSymbol = Self(rawValue: "wonsign.circle.fill")
    static let wonsign_square: FairSymbol = Self(rawValue: "wonsign.square")
    static let wonsign_square_fill: FairSymbol = Self(rawValue: "wonsign.square.fill")
    static let lirasign_circle: FairSymbol = Self(rawValue: "lirasign.circle")
    static let lirasign_circle_fill: FairSymbol = Self(rawValue: "lirasign.circle.fill")
    static let lirasign_square: FairSymbol = Self(rawValue: "lirasign.square")
    static let lirasign_square_fill: FairSymbol = Self(rawValue: "lirasign.square.fill")
    static let australsign_circle: FairSymbol = Self(rawValue: "australsign.circle")
    static let australsign_circle_fill: FairSymbol = Self(rawValue: "australsign.circle.fill")
    static let australsign_square: FairSymbol = Self(rawValue: "australsign.square")
    static let australsign_square_fill: FairSymbol = Self(rawValue: "australsign.square.fill")
    static let hryvniasign_circle: FairSymbol = Self(rawValue: "hryvniasign.circle")
    static let hryvniasign_circle_fill: FairSymbol = Self(rawValue: "hryvniasign.circle.fill")
    static let hryvniasign_square: FairSymbol = Self(rawValue: "hryvniasign.square")
    static let hryvniasign_square_fill: FairSymbol = Self(rawValue: "hryvniasign.square.fill")
    static let nairasign_circle: FairSymbol = Self(rawValue: "nairasign.circle")
    static let nairasign_circle_fill: FairSymbol = Self(rawValue: "nairasign.circle.fill")
    static let nairasign_square: FairSymbol = Self(rawValue: "nairasign.square")
    static let nairasign_square_fill: FairSymbol = Self(rawValue: "nairasign.square.fill")
    static let guaranisign_circle: FairSymbol = Self(rawValue: "guaranisign.circle")
    static let guaranisign_circle_fill: FairSymbol = Self(rawValue: "guaranisign.circle.fill")
    static let guaranisign_square: FairSymbol = Self(rawValue: "guaranisign.square")
    static let guaranisign_square_fill: FairSymbol = Self(rawValue: "guaranisign.square.fill")
    static let coloncurrencysign_circle: FairSymbol = Self(rawValue: "coloncurrencysign.circle")
    static let coloncurrencysign_circle_fill: FairSymbol = Self(rawValue: "coloncurrencysign.circle.fill")
    static let coloncurrencysign_square: FairSymbol = Self(rawValue: "coloncurrencysign.square")
    static let coloncurrencysign_square_fill: FairSymbol = Self(rawValue: "coloncurrencysign.square.fill")
    static let cedisign_circle: FairSymbol = Self(rawValue: "cedisign.circle")
    static let cedisign_circle_fill: FairSymbol = Self(rawValue: "cedisign.circle.fill")
    static let cedisign_square: FairSymbol = Self(rawValue: "cedisign.square")
    static let cedisign_square_fill: FairSymbol = Self(rawValue: "cedisign.square.fill")
    static let cruzeirosign_circle: FairSymbol = Self(rawValue: "cruzeirosign.circle")
    static let cruzeirosign_circle_fill: FairSymbol = Self(rawValue: "cruzeirosign.circle.fill")
    static let cruzeirosign_square: FairSymbol = Self(rawValue: "cruzeirosign.square")
    static let cruzeirosign_square_fill: FairSymbol = Self(rawValue: "cruzeirosign.square.fill")
    static let tugriksign_circle: FairSymbol = Self(rawValue: "tugriksign.circle")
    static let tugriksign_circle_fill: FairSymbol = Self(rawValue: "tugriksign.circle.fill")
    static let tugriksign_square: FairSymbol = Self(rawValue: "tugriksign.square")
    static let tugriksign_square_fill: FairSymbol = Self(rawValue: "tugriksign.square.fill")
    static let millsign_circle: FairSymbol = Self(rawValue: "millsign.circle")
    static let millsign_circle_fill: FairSymbol = Self(rawValue: "millsign.circle.fill")
    static let millsign_square: FairSymbol = Self(rawValue: "millsign.square")
    static let millsign_square_fill: FairSymbol = Self(rawValue: "millsign.square.fill")
    static let shekelsign_circle: FairSymbol = Self(rawValue: "shekelsign.circle")
    static let shekelsign_circle_fill: FairSymbol = Self(rawValue: "shekelsign.circle.fill")
    static let shekelsign_square: FairSymbol = Self(rawValue: "shekelsign.square")
    static let shekelsign_square_fill: FairSymbol = Self(rawValue: "shekelsign.square.fill")
    static let manatsign_circle: FairSymbol = Self(rawValue: "manatsign.circle")
    static let manatsign_circle_fill: FairSymbol = Self(rawValue: "manatsign.circle.fill")
    static let manatsign_square: FairSymbol = Self(rawValue: "manatsign.square")
    static let manatsign_square_fill: FairSymbol = Self(rawValue: "manatsign.square.fill")
    static let rupeesign_circle: FairSymbol = Self(rawValue: "rupeesign.circle")
    static let rupeesign_circle_fill: FairSymbol = Self(rawValue: "rupeesign.circle.fill")
    static let rupeesign_square: FairSymbol = Self(rawValue: "rupeesign.square")
    static let rupeesign_square_fill: FairSymbol = Self(rawValue: "rupeesign.square.fill")
    static let bahtsign_circle: FairSymbol = Self(rawValue: "bahtsign.circle")
    static let bahtsign_circle_fill: FairSymbol = Self(rawValue: "bahtsign.circle.fill")
    static let bahtsign_square: FairSymbol = Self(rawValue: "bahtsign.square")
    static let bahtsign_square_fill: FairSymbol = Self(rawValue: "bahtsign.square.fill")
    static let larisign_circle: FairSymbol = Self(rawValue: "larisign.circle")
    static let larisign_circle_fill: FairSymbol = Self(rawValue: "larisign.circle.fill")
    static let larisign_square: FairSymbol = Self(rawValue: "larisign.square")
    static let larisign_square_fill: FairSymbol = Self(rawValue: "larisign.square.fill")
    static let bitcoinsign_circle: FairSymbol = Self(rawValue: "bitcoinsign.circle")
    static let bitcoinsign_circle_fill: FairSymbol = Self(rawValue: "bitcoinsign.circle.fill")
    static let bitcoinsign_square: FairSymbol = Self(rawValue: "bitcoinsign.square")
    static let bitcoinsign_square_fill: FairSymbol = Self(rawValue: "bitcoinsign.square.fill")
    static let brazilianrealsign_circle: FairSymbol = Self(rawValue: "brazilianrealsign.circle")
    static let brazilianrealsign_circle_fill: FairSymbol = Self(rawValue: "brazilianrealsign.circle.fill")
    static let brazilianrealsign_square: FairSymbol = Self(rawValue: "brazilianrealsign.square")
    static let brazilianrealsign_square_fill: FairSymbol = Self(rawValue: "brazilianrealsign.square.fill")
    static let N0_circle: FairSymbol = Self(rawValue: "0.circle")
    static let N0_circle_fill: FairSymbol = Self(rawValue: "0.circle.fill")
    static let N0_square: FairSymbol = Self(rawValue: "0.square")
    static let N0_square_fill: FairSymbol = Self(rawValue: "0.square.fill")
    static let N1_circle: FairSymbol = Self(rawValue: "1.circle")
    static let N1_circle_fill: FairSymbol = Self(rawValue: "1.circle.fill")
    static let N1_square: FairSymbol = Self(rawValue: "1.square")
    static let N1_square_fill: FairSymbol = Self(rawValue: "1.square.fill")
    static let N2_circle: FairSymbol = Self(rawValue: "2.circle")
    static let N2_circle_fill: FairSymbol = Self(rawValue: "2.circle.fill")
    static let N2_square: FairSymbol = Self(rawValue: "2.square")
    static let N2_square_fill: FairSymbol = Self(rawValue: "2.square.fill")
    static let N3_circle: FairSymbol = Self(rawValue: "3.circle")
    static let N3_circle_fill: FairSymbol = Self(rawValue: "3.circle.fill")
    static let N3_square: FairSymbol = Self(rawValue: "3.square")
    static let N3_square_fill: FairSymbol = Self(rawValue: "3.square.fill")
    static let N4_circle: FairSymbol = Self(rawValue: "4.circle")
    static let N4_circle_fill: FairSymbol = Self(rawValue: "4.circle.fill")
    static let N4_square: FairSymbol = Self(rawValue: "4.square")
    static let N4_square_fill: FairSymbol = Self(rawValue: "4.square.fill")
    static let N4_alt_circle: FairSymbol = Self(rawValue: "4.alt.circle")
    static let N4_alt_circle_fill: FairSymbol = Self(rawValue: "4.alt.circle.fill")
    static let N4_alt_square: FairSymbol = Self(rawValue: "4.alt.square")
    static let N4_alt_square_fill: FairSymbol = Self(rawValue: "4.alt.square.fill")
    static let N5_circle: FairSymbol = Self(rawValue: "5.circle")
    static let N5_circle_fill: FairSymbol = Self(rawValue: "5.circle.fill")
    static let N5_square: FairSymbol = Self(rawValue: "5.square")
    static let N5_square_fill: FairSymbol = Self(rawValue: "5.square.fill")
    static let N6_circle: FairSymbol = Self(rawValue: "6.circle")
    static let N6_circle_fill: FairSymbol = Self(rawValue: "6.circle.fill")
    static let N6_square: FairSymbol = Self(rawValue: "6.square")
    static let N6_square_fill: FairSymbol = Self(rawValue: "6.square.fill")
    static let N6_alt_circle: FairSymbol = Self(rawValue: "6.alt.circle")
    static let N6_alt_circle_fill: FairSymbol = Self(rawValue: "6.alt.circle.fill")
    static let N6_alt_square: FairSymbol = Self(rawValue: "6.alt.square")
    static let N6_alt_square_fill: FairSymbol = Self(rawValue: "6.alt.square.fill")
    static let N7_circle: FairSymbol = Self(rawValue: "7.circle")
    static let N7_circle_fill: FairSymbol = Self(rawValue: "7.circle.fill")
    static let N7_square: FairSymbol = Self(rawValue: "7.square")
    static let N7_square_fill: FairSymbol = Self(rawValue: "7.square.fill")
    static let N8_circle: FairSymbol = Self(rawValue: "8.circle")
    static let N8_circle_fill: FairSymbol = Self(rawValue: "8.circle.fill")
    static let N8_square: FairSymbol = Self(rawValue: "8.square")
    static let N8_square_fill: FairSymbol = Self(rawValue: "8.square.fill")
    static let N9_circle: FairSymbol = Self(rawValue: "9.circle")
    static let N9_circle_fill: FairSymbol = Self(rawValue: "9.circle.fill")
    static let N9_square: FairSymbol = Self(rawValue: "9.square")
    static let N9_square_fill: FairSymbol = Self(rawValue: "9.square.fill")
    static let N9_alt_circle: FairSymbol = Self(rawValue: "9.alt.circle")
    static let N9_alt_circle_fill: FairSymbol = Self(rawValue: "9.alt.circle.fill")
    static let N9_alt_square: FairSymbol = Self(rawValue: "9.alt.square")
    static let N9_alt_square_fill: FairSymbol = Self(rawValue: "9.alt.square.fill")
    static let N00_circle: FairSymbol = Self(rawValue: "00.circle")
    static let N00_circle_fill: FairSymbol = Self(rawValue: "00.circle.fill")
    static let N00_square: FairSymbol = Self(rawValue: "00.square")
    static let N00_square_fill: FairSymbol = Self(rawValue: "00.square.fill")
    static let N01_circle: FairSymbol = Self(rawValue: "01.circle")
    static let N01_circle_fill: FairSymbol = Self(rawValue: "01.circle.fill")
    static let N01_square: FairSymbol = Self(rawValue: "01.square")
    static let N01_square_fill: FairSymbol = Self(rawValue: "01.square.fill")
    static let N02_circle: FairSymbol = Self(rawValue: "02.circle")
    static let N02_circle_fill: FairSymbol = Self(rawValue: "02.circle.fill")
    static let N02_square: FairSymbol = Self(rawValue: "02.square")
    static let N02_square_fill: FairSymbol = Self(rawValue: "02.square.fill")
    static let N03_circle: FairSymbol = Self(rawValue: "03.circle")
    static let N03_circle_fill: FairSymbol = Self(rawValue: "03.circle.fill")
    static let N03_square: FairSymbol = Self(rawValue: "03.square")
    static let N03_square_fill: FairSymbol = Self(rawValue: "03.square.fill")
    static let N04_circle: FairSymbol = Self(rawValue: "04.circle")
    static let N04_circle_fill: FairSymbol = Self(rawValue: "04.circle.fill")
    static let N04_square: FairSymbol = Self(rawValue: "04.square")
    static let N04_square_fill: FairSymbol = Self(rawValue: "04.square.fill")
    static let N05_circle: FairSymbol = Self(rawValue: "05.circle")
    static let N05_circle_fill: FairSymbol = Self(rawValue: "05.circle.fill")
    static let N05_square: FairSymbol = Self(rawValue: "05.square")
    static let N05_square_fill: FairSymbol = Self(rawValue: "05.square.fill")
    static let N06_circle: FairSymbol = Self(rawValue: "06.circle")
    static let N06_circle_fill: FairSymbol = Self(rawValue: "06.circle.fill")
    static let N06_square: FairSymbol = Self(rawValue: "06.square")
    static let N06_square_fill: FairSymbol = Self(rawValue: "06.square.fill")
    static let N07_circle: FairSymbol = Self(rawValue: "07.circle")
    static let N07_circle_fill: FairSymbol = Self(rawValue: "07.circle.fill")
    static let N07_square: FairSymbol = Self(rawValue: "07.square")
    static let N07_square_fill: FairSymbol = Self(rawValue: "07.square.fill")
    static let N08_circle: FairSymbol = Self(rawValue: "08.circle")
    static let N08_circle_fill: FairSymbol = Self(rawValue: "08.circle.fill")
    static let N08_square: FairSymbol = Self(rawValue: "08.square")
    static let N08_square_fill: FairSymbol = Self(rawValue: "08.square.fill")
    static let N09_circle: FairSymbol = Self(rawValue: "09.circle")
    static let N09_circle_fill: FairSymbol = Self(rawValue: "09.circle.fill")
    static let N09_square: FairSymbol = Self(rawValue: "09.square")
    static let N09_square_fill: FairSymbol = Self(rawValue: "09.square.fill")
    static let N10_circle: FairSymbol = Self(rawValue: "10.circle")
    static let N10_circle_fill: FairSymbol = Self(rawValue: "10.circle.fill")
    static let N10_square: FairSymbol = Self(rawValue: "10.square")
    static let N10_square_fill: FairSymbol = Self(rawValue: "10.square.fill")
    static let N11_circle: FairSymbol = Self(rawValue: "11.circle")
    static let N11_circle_fill: FairSymbol = Self(rawValue: "11.circle.fill")
    static let N11_square: FairSymbol = Self(rawValue: "11.square")
    static let N11_square_fill: FairSymbol = Self(rawValue: "11.square.fill")
    static let N12_circle: FairSymbol = Self(rawValue: "12.circle")
    static let N12_circle_fill: FairSymbol = Self(rawValue: "12.circle.fill")
    static let N12_square: FairSymbol = Self(rawValue: "12.square")
    static let N12_square_fill: FairSymbol = Self(rawValue: "12.square.fill")
    static let N13_circle: FairSymbol = Self(rawValue: "13.circle")
    static let N13_circle_fill: FairSymbol = Self(rawValue: "13.circle.fill")
    static let N13_square: FairSymbol = Self(rawValue: "13.square")
    static let N13_square_fill: FairSymbol = Self(rawValue: "13.square.fill")
    static let N14_circle: FairSymbol = Self(rawValue: "14.circle")
    static let N14_circle_fill: FairSymbol = Self(rawValue: "14.circle.fill")
    static let N14_square: FairSymbol = Self(rawValue: "14.square")
    static let N14_square_fill: FairSymbol = Self(rawValue: "14.square.fill")
    static let N15_circle: FairSymbol = Self(rawValue: "15.circle")
    static let N15_circle_fill: FairSymbol = Self(rawValue: "15.circle.fill")
    static let N15_square: FairSymbol = Self(rawValue: "15.square")
    static let N15_square_fill: FairSymbol = Self(rawValue: "15.square.fill")
    static let N16_circle: FairSymbol = Self(rawValue: "16.circle")
    static let N16_circle_fill: FairSymbol = Self(rawValue: "16.circle.fill")
    static let N16_square: FairSymbol = Self(rawValue: "16.square")
    static let N16_square_fill: FairSymbol = Self(rawValue: "16.square.fill")
    static let N17_circle: FairSymbol = Self(rawValue: "17.circle")
    static let N17_circle_fill: FairSymbol = Self(rawValue: "17.circle.fill")
    static let N17_square: FairSymbol = Self(rawValue: "17.square")
    static let N17_square_fill: FairSymbol = Self(rawValue: "17.square.fill")
    static let N18_circle: FairSymbol = Self(rawValue: "18.circle")
    static let N18_circle_fill: FairSymbol = Self(rawValue: "18.circle.fill")
    static let N18_square: FairSymbol = Self(rawValue: "18.square")
    static let N18_square_fill: FairSymbol = Self(rawValue: "18.square.fill")
    static let N19_circle: FairSymbol = Self(rawValue: "19.circle")
    static let N19_circle_fill: FairSymbol = Self(rawValue: "19.circle.fill")
    static let N19_square: FairSymbol = Self(rawValue: "19.square")
    static let N19_square_fill: FairSymbol = Self(rawValue: "19.square.fill")
    static let N20_circle: FairSymbol = Self(rawValue: "20.circle")
    static let N20_circle_fill: FairSymbol = Self(rawValue: "20.circle.fill")
    static let N20_square: FairSymbol = Self(rawValue: "20.square")
    static let N20_square_fill: FairSymbol = Self(rawValue: "20.square.fill")
    static let N21_circle: FairSymbol = Self(rawValue: "21.circle")
    static let N21_circle_fill: FairSymbol = Self(rawValue: "21.circle.fill")
    static let N21_square: FairSymbol = Self(rawValue: "21.square")
    static let N21_square_fill: FairSymbol = Self(rawValue: "21.square.fill")
    static let N22_circle: FairSymbol = Self(rawValue: "22.circle")
    static let N22_circle_fill: FairSymbol = Self(rawValue: "22.circle.fill")
    static let N22_square: FairSymbol = Self(rawValue: "22.square")
    static let N22_square_fill: FairSymbol = Self(rawValue: "22.square.fill")
    static let N23_circle: FairSymbol = Self(rawValue: "23.circle")
    static let N23_circle_fill: FairSymbol = Self(rawValue: "23.circle.fill")
    static let N23_square: FairSymbol = Self(rawValue: "23.square")
    static let N23_square_fill: FairSymbol = Self(rawValue: "23.square.fill")
    static let N24_circle: FairSymbol = Self(rawValue: "24.circle")
    static let N24_circle_fill: FairSymbol = Self(rawValue: "24.circle.fill")
    static let N24_square: FairSymbol = Self(rawValue: "24.square")
    static let N24_square_fill: FairSymbol = Self(rawValue: "24.square.fill")
    static let N25_circle: FairSymbol = Self(rawValue: "25.circle")
    static let N25_circle_fill: FairSymbol = Self(rawValue: "25.circle.fill")
    static let N25_square: FairSymbol = Self(rawValue: "25.square")
    static let N25_square_fill: FairSymbol = Self(rawValue: "25.square.fill")
    static let N26_circle: FairSymbol = Self(rawValue: "26.circle")
    static let N26_circle_fill: FairSymbol = Self(rawValue: "26.circle.fill")
    static let N26_square: FairSymbol = Self(rawValue: "26.square")
    static let N26_square_fill: FairSymbol = Self(rawValue: "26.square.fill")
    static let N27_circle: FairSymbol = Self(rawValue: "27.circle")
    static let N27_circle_fill: FairSymbol = Self(rawValue: "27.circle.fill")
    static let N27_square: FairSymbol = Self(rawValue: "27.square")
    static let N27_square_fill: FairSymbol = Self(rawValue: "27.square.fill")
    static let N28_circle: FairSymbol = Self(rawValue: "28.circle")
    static let N28_circle_fill: FairSymbol = Self(rawValue: "28.circle.fill")
    static let N28_square: FairSymbol = Self(rawValue: "28.square")
    static let N28_square_fill: FairSymbol = Self(rawValue: "28.square.fill")
    static let N29_circle: FairSymbol = Self(rawValue: "29.circle")
    static let N29_circle_fill: FairSymbol = Self(rawValue: "29.circle.fill")
    static let N29_square: FairSymbol = Self(rawValue: "29.square")
    static let N29_square_fill: FairSymbol = Self(rawValue: "29.square.fill")
    static let N30_circle: FairSymbol = Self(rawValue: "30.circle")
    static let N30_circle_fill: FairSymbol = Self(rawValue: "30.circle.fill")
    static let N30_square: FairSymbol = Self(rawValue: "30.square")
    static let N30_square_fill: FairSymbol = Self(rawValue: "30.square.fill")
    static let N31_circle: FairSymbol = Self(rawValue: "31.circle")
    static let N31_circle_fill: FairSymbol = Self(rawValue: "31.circle.fill")
    static let N31_square: FairSymbol = Self(rawValue: "31.square")
    static let N31_square_fill: FairSymbol = Self(rawValue: "31.square.fill")
    static let N32_circle: FairSymbol = Self(rawValue: "32.circle")
    static let N32_circle_fill: FairSymbol = Self(rawValue: "32.circle.fill")
    static let N32_square: FairSymbol = Self(rawValue: "32.square")
    static let N32_square_fill: FairSymbol = Self(rawValue: "32.square.fill")
    static let N33_circle: FairSymbol = Self(rawValue: "33.circle")
    static let N33_circle_fill: FairSymbol = Self(rawValue: "33.circle.fill")
    static let N33_square: FairSymbol = Self(rawValue: "33.square")
    static let N33_square_fill: FairSymbol = Self(rawValue: "33.square.fill")
    static let N34_circle: FairSymbol = Self(rawValue: "34.circle")
    static let N34_circle_fill: FairSymbol = Self(rawValue: "34.circle.fill")
    static let N34_square: FairSymbol = Self(rawValue: "34.square")
    static let N34_square_fill: FairSymbol = Self(rawValue: "34.square.fill")
    static let N35_circle: FairSymbol = Self(rawValue: "35.circle")
    static let N35_circle_fill: FairSymbol = Self(rawValue: "35.circle.fill")
    static let N35_square: FairSymbol = Self(rawValue: "35.square")
    static let N35_square_fill: FairSymbol = Self(rawValue: "35.square.fill")
    static let N36_circle: FairSymbol = Self(rawValue: "36.circle")
    static let N36_circle_fill: FairSymbol = Self(rawValue: "36.circle.fill")
    static let N36_square: FairSymbol = Self(rawValue: "36.square")
    static let N36_square_fill: FairSymbol = Self(rawValue: "36.square.fill")
    static let N37_circle: FairSymbol = Self(rawValue: "37.circle")
    static let N37_circle_fill: FairSymbol = Self(rawValue: "37.circle.fill")
    static let N37_square: FairSymbol = Self(rawValue: "37.square")
    static let N37_square_fill: FairSymbol = Self(rawValue: "37.square.fill")
    static let N38_circle: FairSymbol = Self(rawValue: "38.circle")
    static let N38_circle_fill: FairSymbol = Self(rawValue: "38.circle.fill")
    static let N38_square: FairSymbol = Self(rawValue: "38.square")
    static let N38_square_fill: FairSymbol = Self(rawValue: "38.square.fill")
    static let N39_circle: FairSymbol = Self(rawValue: "39.circle")
    static let N39_circle_fill: FairSymbol = Self(rawValue: "39.circle.fill")
    static let N39_square: FairSymbol = Self(rawValue: "39.square")
    static let N39_square_fill: FairSymbol = Self(rawValue: "39.square.fill")
    static let N40_circle: FairSymbol = Self(rawValue: "40.circle")
    static let N40_circle_fill: FairSymbol = Self(rawValue: "40.circle.fill")
    static let N40_square: FairSymbol = Self(rawValue: "40.square")
    static let N40_square_fill: FairSymbol = Self(rawValue: "40.square.fill")
    static let N41_circle: FairSymbol = Self(rawValue: "41.circle")
    static let N41_circle_fill: FairSymbol = Self(rawValue: "41.circle.fill")
    static let N41_square: FairSymbol = Self(rawValue: "41.square")
    static let N41_square_fill: FairSymbol = Self(rawValue: "41.square.fill")
    static let N42_circle: FairSymbol = Self(rawValue: "42.circle")
    static let N42_circle_fill: FairSymbol = Self(rawValue: "42.circle.fill")
    static let N42_square: FairSymbol = Self(rawValue: "42.square")
    static let N42_square_fill: FairSymbol = Self(rawValue: "42.square.fill")
    static let N43_circle: FairSymbol = Self(rawValue: "43.circle")
    static let N43_circle_fill: FairSymbol = Self(rawValue: "43.circle.fill")
    static let N43_square: FairSymbol = Self(rawValue: "43.square")
    static let N43_square_fill: FairSymbol = Self(rawValue: "43.square.fill")
    static let N44_circle: FairSymbol = Self(rawValue: "44.circle")
    static let N44_circle_fill: FairSymbol = Self(rawValue: "44.circle.fill")
    static let N44_square: FairSymbol = Self(rawValue: "44.square")
    static let N44_square_fill: FairSymbol = Self(rawValue: "44.square.fill")
    static let N45_circle: FairSymbol = Self(rawValue: "45.circle")
    static let N45_circle_fill: FairSymbol = Self(rawValue: "45.circle.fill")
    static let N45_square: FairSymbol = Self(rawValue: "45.square")
    static let N45_square_fill: FairSymbol = Self(rawValue: "45.square.fill")
    static let N46_circle: FairSymbol = Self(rawValue: "46.circle")
    static let N46_circle_fill: FairSymbol = Self(rawValue: "46.circle.fill")
    static let N46_square: FairSymbol = Self(rawValue: "46.square")
    static let N46_square_fill: FairSymbol = Self(rawValue: "46.square.fill")
    static let N47_circle: FairSymbol = Self(rawValue: "47.circle")
    static let N47_circle_fill: FairSymbol = Self(rawValue: "47.circle.fill")
    static let N47_square: FairSymbol = Self(rawValue: "47.square")
    static let N47_square_fill: FairSymbol = Self(rawValue: "47.square.fill")
    static let N48_circle: FairSymbol = Self(rawValue: "48.circle")
    static let N48_circle_fill: FairSymbol = Self(rawValue: "48.circle.fill")
    static let N48_square: FairSymbol = Self(rawValue: "48.square")
    static let N48_square_fill: FairSymbol = Self(rawValue: "48.square.fill")
    static let N49_circle: FairSymbol = Self(rawValue: "49.circle")
    static let N49_circle_fill: FairSymbol = Self(rawValue: "49.circle.fill")
    static let N49_square: FairSymbol = Self(rawValue: "49.square")
    static let N49_square_fill: FairSymbol = Self(rawValue: "49.square.fill")
    static let N50_circle: FairSymbol = Self(rawValue: "50.circle")
    static let N50_circle_fill: FairSymbol = Self(rawValue: "50.circle.fill")
    static let N50_square: FairSymbol = Self(rawValue: "50.square")
    static let N50_square_fill: FairSymbol = Self(rawValue: "50.square")
    
    // TODO: next version of symbols, gated behind a version check
    // rectangle.portrait.and.arrow.forward
    // rectangle.portrait.and.arrow.forward.fill
    // square.and.pencil.circle
    // square.and.pencil.circle.fill
    // externaldrive.badge.questionmark
    // externaldrive.fill.badge.questionmark
    // externaldrive.badge.exclamationmark
    // externaldrive.fill.badge.exclamationmark
    // externaldrive.trianglebadge.exclamationmark
    // externaldrive.fill.trianglebadge.exclamationmark
    // doc.badge.arrow.up
    // doc.badge.arrow.up.fill
    // clipboard
    // clipboard.fill
    // list.bullet.clipboard
    // list.bullet.clipboard.fill
    // list.clipboard
    // list.clipboard.fill
    // arrowshape.left
    // arrowshape.left.fill
    // arrowshape.right
    // arrowshape.right.fill
    // arrowshape.backward
    // arrowshape.backward.fill
    // arrowshape.forward
    // arrowshape.forward.fill
    // arrowshape.turn.up.backward.badge.clock
    // arrowshape.turn.up.backward.badge.clock.fill
    // pencil.and.ruler
    // pencil.and.ruler.fill
    // backpack
    // backpack.fill
    // person.badge.shield.checkmark
    // person.badge.shield.checkmark.fill
    // shared.with.you
    // shared.with.you.slash
    // person.2.gobackward
    // person.2.badge.gearshape
    // person.2.badge.gearshape.fill
    // person.line.dotted.person
    // person.line.dotted.person.fill
    // person.bust
    // person.bust.fill
    // person.crop.rectangle.badge.plus
    // person.crop.rectangle.badge.plus.fill
    // square.on.square.badge.person.crop
    // square.on.square.badge.person.crop.fill
    // figure.dress.line.vertical.figure
    // figure.arms.open
    // figure.2.arms.open
    // figure.2.and.child.holdinghands
    // figure.and.child.holdinghands
    // figure.walk.arrival
    // figure.walk.departure
    // figure.walk.motion
    // figure.fall
    // figure.fall.circle
    // figure.fall.circle.fill
    // figure.run
    // figure.run.circle
    // figure.run.circle.fill
    // figure.roll.runningpace
    // figure.american.football
    // figure.archery
    // figure.australian.football
    // figure.badminton
    // figure.barre
    // figure.baseball
    // figure.basketball
    // figure.bowling
    // figure.boxing
    // figure.climbing
    // figure.cooldown
    // figure.core.training
    // figure.cricket
    // figure.skiing.crosscountry
    // figure.cross.training
    // figure.curling
    // figure.dance
    // figure.disc.sports
    // figure.skiing.downhill
    // figure.elliptical
    // figure.equestrian.sports
    // figure.fencing
    // figure.fishing
    // figure.flexibility
    // figure.strengthtraining.functional
    // figure.golf
    // figure.gymnastics
    // figure.hand.cycling
    // figure.handball
    // figure.highintensity.intervaltraining
    // figure.hiking
    // figure.hockey
    // figure.hunting
    // figure.indoor.cycle
    // figure.jumprope
    // figure.kickboxing
    // figure.lacrosse
    // figure.martial.arts
    // figure.mind.and.body
    // figure.mixed.cardio
    // figure.open.water.swim
    // figure.outdoor.cycle
    // oar.2.crossed
    // figure.pickleball
    // figure.pilates
    // figure.play
    // figure.pool.swim
    // figure.racquetball
    // figure.rolling
    // figure.rower
    // figure.rugby
    // figure.sailing
    // figure.skating
    // figure.snowboarding
    // figure.soccer
    // figure.socialdance
    // figure.softball
    // figure.squash
    // figure.stair.stepper
    // figure.stairs
    // figure.step.training
    // figure.surfing
    // figure.table.tennis
    // figure.taichi
    // figure.tennis
    // figure.track.and.field
    // figure.strengthtraining.traditional
    // figure.volleyball
    // figure.water.fitness
    // figure.waterpolo
    // figure.wrestling
    // figure.yoga
    // baseball.diamond.bases
    // dumbbell
    // dumbbell.fill
    // soccerball
    // soccerball.inverse
    // baseball
    // baseball.fill
    // basketball
    // basketball.fill
    // football
    // football.fill
    // tennis.racket
    // trophy
    // trophy.fill
    // trophy.circle
    // trophy.circle.fill
    // medal
    // medal.fill
    // chevron.left.to.line
    // chevron.right.to.line
    // chevron.backward.to.line
    // chevron.forward.to.line
    // cursorarrow.square.fill
    // keyboard.badge.ellipsis.fill
    // keyboard.badge.eye
    // keyboard.badge.eye.fill
    // keyboard.chevron.compact.down.fill
    // keyboard.chevron.compact.left.fill
    // keyboard.onehanded.left.fill
    // keyboard.onehanded.right.fill
    // globe.central.south.asia
    // globe.central.south.asia.fill
    // moon.haze
    // moon.haze.fill
    // moonphase.new.moon
    // moonphase.waxing.crescent
    // moonphase.first.quarter
    // moonphase.waxing.gibbous
    // moonphase.full.moon
    // moonphase.waning.gibbous
    // moonphase.last.quarter
    // moonphase.waning.crescent
    // moonphase.new.moon.inverse
    // moonphase.waxing.crescent.inverse
    // moonphase.first.quarter.inverse
    // moonphase.waxing.gibbous.inverse
    // moonphase.full.moon.inverse
    // moonphase.waning.gibbous.inverse
    // moonphase.last.quarter.inverse
    // moonphase.waning.crescent.inverse
    // thermometer.low
    // thermometer.medium
    // thermometer.high
    // thermometer.medium.slash
    // water.waves
    // water.waves.slash
    // water.waves.and.arrow.up
    // water.waves.and.arrow.down
    // drop.degreesign
    // drop.degreesign.fill
    // drop.degreesign.slash
    // drop.degreesign.slash.fill
    // beach.umbrella
    // beach.umbrella.fill
    // umbrella.percent
    // umbrella.percent.fill
    // playpause.circle
    // playpause.circle.fill
    // backward.end.circle
    // backward.end.circle.fill
    // forward.end.circle
    // forward.end.circle.fill
    // speaker.square
    // speaker.square.fill
    // mic.badge.xmark
    // mic.fill.badge.xmark
    // mic.and.signal.meter
    // mic.and.signal.meter.fill
    // square.topthird.inset.filled
    // square.bottomthird.inset.filled
    // square.leftthird.inset.filled
    // square.rightthird.inset.filled
    // square.leadingthird.inset.filled
    // square.trailingthird.inset.filled
    // square.dotted
    // star.square.on.square
    // star.square.on.square.fill
    // square.on.square.intersection.dashed
    // rectangle.portrait.on.rectangle.portrait.angled
    // rectangle.portrait.on.rectangle.portrait.angled.fill
    // fleuron
    // fleuron.fill
    // firewall
    // firewall.fill
    // flag.checkered
    // location.slash.circle
    // location.slash.circle.fill
    // bell.and.waves.left.and.right
    // bell.and.waves.left.and.right.fill
    // bolt.badge.clock
    // bolt.badge.clock.fill
    // message.badge
    // message.badge.filled.fill
    // message.badge.circle
    // message.badge.circle.fill
    // message.badge.fill
    // checkmark.message
    // checkmark.message.fill
    // arrow.down.message
    // arrow.down.message.fill
    // ellipsis.message
    // ellipsis.message.fill
    // info.bubble
    // info.bubble.fill
    // questionmark.bubble
    // questionmark.bubble.fill
    // speaker.wave.2.bubble.left
    // speaker.wave.2.bubble.left.fill
    // phone.badge.checkmark
    // phone.fill.badge.checkmark
    // phone.connection.fill
    // phone.arrow.up.right.fill
    // phone.arrow.up.right.circle
    // phone.arrow.up.right.circle.fill
    // phone.arrow.down.left.fill
    // phone.arrow.right.fill
    // phone.down.waves.left.and.right
    // deskview
    // deskview.fill
    // envelope.open.badge.clock
    // gear.badge
    // bag.badge.questionmark
    // bag.fill.badge.questionmark
    // cart.badge.questionmark
    // cart.fill.badge.questionmark
    // basket
    // basket.fill
    // dial.low
    // dial.low.fill
    // dial.medium
    // dial.medium.fill
    // dial.high
    // dial.high.fill
    // gauge.medium
    // gauge.medium.badge.plus
    // gauge.medium.badge.minus
    // gauge.low
    // gauge.high
    // wrench.adjustable
    // wrench.adjustable.fill
    // faxmachine.fill
    // theatermask.and.paintbrush
    // theatermask.and.paintbrush.fill
    // lightbulb.2
    // lightbulb.2.fill
    // lightbulb.led
    // lightbulb.led.fill
    // lightbulb.led.wide
    // lightbulb.led.wide.fill
    // fan.oscillation
    // fan.oscillation.fill
    // fan.desk
    // fan.desk.fill
    // fan.floor
    // fan.floor.fill
    // fan.ceiling
    // fan.ceiling.fill
    // fan.and.light.ceiling
    // fan.and.light.ceiling.fill
    // lamp.desk
    // lamp.desk.fill
    // lamp.table
    // lamp.table.fill
    // lamp.floor
    // lamp.floor.fill
    // lamp.ceiling
    // lamp.ceiling.fill
    // lamp.ceiling.inverse
    // light.recessed
    // light.recessed.fill
    // light.recessed.inverse
    // light.recessed.3
    // light.recessed.3.fill
    // light.recessed.3.inverse
    // light.panel
    // light.panel.fill
    // light.cylindrical.ceiling
    // light.cylindrical.ceiling.fill
    // light.cylindrical.ceiling.inverse
    // light.strip.2
    // light.strip.2.fill
    // light.ribbon
    // light.ribbon.fill
    // chandelier
    // chandelier.fill
    // lightswitch.on
    // lightswitch.on.fill
    // lightswitch.on.square
    // lightswitch.on.square.fill
    // lightswitch.off
    // lightswitch.off.fill
    // lightswitch.off.square
    // lightswitch.off.square.fill
    // button.programmable
    // button.programmable.square
    // button.programmable.square.fill
    // switch.programmable
    // switch.programmable.fill
    // switch.programmable.square
    // switch.programmable.square.fill
    // poweroutlet.type.a
    // poweroutlet.type.a.fill
    // poweroutlet.type.a.square
    // poweroutlet.type.a.square.fill
    // poweroutlet.type.b
    // poweroutlet.type.b.fill
    // poweroutlet.type.b.square
    // poweroutlet.type.b.square.fill
    // poweroutlet.type.c
    // poweroutlet.type.c.fill
    // poweroutlet.type.c.square
    // poweroutlet.type.c.square.fill
    // poweroutlet.type.d
    // poweroutlet.type.d.fill
    // poweroutlet.type.d.square
    // poweroutlet.type.d.square.fill
    // poweroutlet.type.e
    // poweroutlet.type.e.fill
    // poweroutlet.type.e.square
    // poweroutlet.type.e.square.fill
    // poweroutlet.type.f
    // poweroutlet.type.f.fill
    // poweroutlet.type.f.square
    // poweroutlet.type.f.square.fill
    // poweroutlet.type.g
    // poweroutlet.type.g.fill
    // poweroutlet.type.g.square
    // poweroutlet.type.g.square.fill
    // poweroutlet.type.h
    // poweroutlet.type.h.fill
    // poweroutlet.type.h.square
    // poweroutlet.type.h.square.fill
    // poweroutlet.type.i
    // poweroutlet.type.i.fill
    // poweroutlet.type.i.square
    // poweroutlet.type.i.square.fill
    // poweroutlet.type.j
    // poweroutlet.type.j.fill
    // poweroutlet.type.j.square
    // poweroutlet.type.j.square.fill
    // poweroutlet.type.k
    // poweroutlet.type.k.fill
    // poweroutlet.type.k.square
    // poweroutlet.type.k.square.fill
    // poweroutlet.type.l
    // poweroutlet.type.l.fill
    // poweroutlet.type.l.square
    // poweroutlet.type.l.square.fill
    // poweroutlet.type.m
    // poweroutlet.type.m.fill
    // poweroutlet.type.m.square
    // poweroutlet.type.m.square.fill
    // poweroutlet.type.n
    // poweroutlet.type.n.fill
    // poweroutlet.type.n.square
    // poweroutlet.type.n.square.fill
    // poweroutlet.type.o
    // poweroutlet.type.o.fill
    // poweroutlet.type.o.square
    // poweroutlet.type.o.square.fill
    // poweroutlet.strip
    // poweroutlet.strip.fill
    // light.beacon
    // light.beacon.fill
    // web.camera
    // web.camera.fill
    // video.doorbell
    // video.doorbell.fill
    // entry.lever.keypad
    // entry.lever.keypad.fill
    // entry.lever.keypad.trianglebadge.exclamationmark
    // entry.lever.keypad.trianglebadge.exclamationmark.fill
    // door.left.hand.open
    // door.left.hand.closed
    // door.right.hand.open
    // door.right.hand.closed
    // door.sliding.left.hand.open
    // door.sliding.left.hand.closed
    // door.sliding.right.hand.open
    // door.sliding.right.hand.closed
    // door.garage.open
    // door.garage.closed
    // door.garage.open.trianglebadge.exclamationmark
    // door.garage.closed.trianglebadge.exclamationmark
    // door.garage.double.bay.open
    // door.garage.double.bay.closed
    // door.garage.double.bay.open.trianglebadge.exclamationmark
    // door.garage.double.bay.closed.trianglebadge.exclamationmark
    // door.french.open
    // door.french.closed
    // pedestrian.gate.closed
    // pedestrian.gate.open
    // window.vertical.open
    // window.vertical.closed
    // window.horizontal
    // window.horizontal.closed
    // window.ceiling
    // window.ceiling.closed
    // window.casement
    // window.casement.closed
    // window.awning
    // window.awning.closed
    // blinds.vertical.open
    // blinds.vertical.closed
    // blinds.horizontal.open
    // blinds.horizontal.closed
    // window.shade.open
    // window.shade.closed
    // roller.shade.open
    // roller.shade.closed
    // roman.shade.open
    // roman.shade.closed
    // curtains.open
    // curtains.closed
    // air.purifier
    // air.purifier.fill
    // dehumidifier
    // dehumidifier.fill
    // humidifier
    // humidifier.fill
    // humidifier.and.droplets
    // humidifier.and.droplets.fill
    // heater.vertical
    // heater.vertical.fill
    // air.conditioner.vertical
    // air.conditioner.vertical.fill
    // air.conditioner.horizontal
    // air.conditioner.horizontal.fill
    // sprinkler
    // sprinkler.fill
    // sprinkler.and.droplets
    // sprinkler.and.droplets.fill
    // spigot
    // spigot.fill
    // drop.keypad.rectangle
    // drop.keypad.rectangle.fill
    // shower.sidejet
    // shower.sidejet.fill
    // shower
    // shower.fill
    // shower.handheld
    // shower.handheld.fill
    // bathtub
    // bathtub.fill
    // contact.sensor
    // contact.sensor.fill
    // sensor
    // sensor.fill
    // carbon.monoxide.cloud
    // carbon.monoxide.cloud.fill
    // carbon.dioxide.cloud
    // carbon.dioxide.cloud.fill
    // pipe.and.drop
    // pipe.and.drop.fill
    // hifireceiver
    // hifireceiver.fill
    // videoprojector
    // videoprojector.fill
    // wifi.router
    // wifi.router.fill
    // party.popper
    // party.popper.fill
    // balloon
    // balloon.fill
    // balloon.2
    // balloon.2.fill
    // frying.pan
    // frying.pan.fill
    // popcorn
    // popcorn.fill
    // sofa
    // sofa.fill
    // chair.lounge
    // chair.lounge.fill
    // chair
    // chair.fill
    // cabinet
    // cabinet.fill
    // fireplace
    // fireplace.fill
    // table.furniture
    // table.furniture.fill
    // washer
    // washer.fill
    // dryer
    // dryer.fill
    // dishwasher
    // dishwasher.fill
    // oven
    // oven.fill
    // stove
    // stove.fill
    // cooktop
    // cooktop.fill
    // microwave
    // microwave.fill
    // refrigerator
    // refrigerator.fill
    // sink
    // sink.fill
    // toilet
    // toilet.fill
    // stairs
    // tent
    // tent.fill
    // exclamationmark.lock
    // exclamationmark.lock.fill
    // lock.trianglebadge.exclamationmark
    // lock.trianglebadge.exclamationmark.fill
    // opticaldisc.fill
    // play.display
    // play.desktopcomputer
    // play.laptopcomputer
    // laptopcomputer.and.ipad
    // macstudio
    // macstudio.fill
    // arrow.up.and.down.and.sparkles
    // av.remote
    // av.remote.fill
    // box.truck
    // box.truck.fill
    // box.truck.badge.clock
    // box.truck.badge.clock.fill
    // sailboat
    // sailboat.fill
    // allergens.fill
    // microbe
    // microbe.fill
    // bubbles.and.sparkles
    // bubbles.and.sparkles.fill
    // medical.thermometer
    // medical.thermometer.fill
    // syringe
    // syringe.fill
    // pill
    // pill.fill
    // pill.circle
    // pill.circle.fill
    // lizard
    // lizard.fill
    // bird
    // bird.fill
    // fish
    // fish.fill
    // teddybear
    // teddybear.fill
    // laurel.leading
    // laurel.trailing
    // shoeprints.fill
    // film.stack
    // film.stack.fill
    // hearingdevice.ear.fill
    // hearingdevice.and.signal.meter
    // hearingdevice.and.signal.meter.fill
    // hand.raised.fingers.spread
    // hand.raised.fingers.spread.fill
    // creditcard.viewfinder
    // vial.viewfinder
    // photo.stack
    // photo.stack.fill
    // squares.leading.rectangle
    // distribute.vertical.top
    // distribute.vertical.top.fill
    // distribute.vertical.center
    // distribute.vertical.center.fill
    // distribute.vertical.bottom
    // distribute.vertical.bottom.fill
    // distribute.horizontal.left
    // distribute.horizontal.left.fill
    // distribute.horizontal.center
    // distribute.horizontal.center.fill
    // distribute.horizontal.right
    // distribute.horizontal.right.fill
    // slider.horizontal.2.square.on.square
    // slider.horizontal.2.square.badge.arrow.down
    // slider.horizontal.2.gobackward
    // slider.horizontal.below.square.and.square.filled
    // shippingbox.and.arrow.backward
    // shippingbox.and.arrow.backward.fill
    // clock.badge
    // clock.badge.fill
    // alarm.waves.left.and.right
    // alarm.waves.left.and.right.fill
    // timer.circle
    // timer.circle.fill
    // playstationlogo
    // xboxlogo
    // swatchpalette
    // swatchpalette.fill
    // wineglass
    // wineglass.fill
    // birthday.cake
    // birthday.cake.fill
    // carrot
    // carrot.fill
    // square.2.layers.3d
    // square.2.layers.3d.top.filled
    // square.2.layers.3d.bottom.filled
    // square.3.layers.3d
    // square.3.layers.3d.slash
    // square.3.layers.3d.top.filled
    // square.3.layers.3d.middle.filled
    // square.3.layers.3d.bottom.filled
    // cellularbars
    // chart.line.downtrend.xyaxis
    // chart.line.downtrend.xyaxis.circle
    // chart.line.downtrend.xyaxis.circle.fill
    // chart.line.flattrend.xyaxis
    // chart.line.flattrend.xyaxis.circle
    // chart.line.flattrend.xyaxis.circle.fill
    // squareshape.dotted.split.2x2
    // waveform.slash
    // angle
    // compass.drawing
    // globe.desk
    // globe.desk.fill
    // fossil.shell
    // fossil.shell.fill
    // dollarsign.arrow.circlepath
    // recordingtape.circle
    // recordingtape.circle.fill
    // battery.100.circle
    // battery.100.circle.fill
    // checklist.unchecked
    // checklist.checked
    // quotelevel
    // text.line.first.and.arrowtriangle.forward
    // text.line.last.and.arrowtriangle.forward
    // text.word.spacing
    // arrow.up.and.down.text.horizontal
    // arrow.left.and.right.text.vertical
    // textformat.12
    // numbersign
    // character.sutton
    // character.duployan
    // character.phonetic
    // info.square
    // info.square.fill
    // exclamationmark.questionmark
    // arrow.up.circle.badge.clock
    // arrow.left.and.line.vertical.and.arrow.right
    // arrow.right.and.line.vertical.and.arrow.left
    // arrow.down.and.line.horizontal.and.arrow.up
    // arrow.up.and.line.horizontal.and.arrow.down
    // gearshape.arrow.triangle.2.circlepath
    // dollarsign
    // centsign
    // yensign
    // sterlingsign
    // francsign
    // florinsign
    // turkishlirasign
    // rublesign
    // eurosign
    // dongsign
    // indianrupeesign
    // tengesign
    // pesetasign
    // pesosign
    // kipsign
    // wonsign
    // lirasign
    // australsign
    // hryvniasign
    // nairasign
    // guaranisign
    // coloncurrencysign
    // cedisign
    // cruzeirosign
    // tugriksign
    // millsign
    // shekelsign
    // manatsign
    // rupeesign
    // bahtsign
    // larisign
    // bitcoinsign
    // brazilianrealsign
        
}

