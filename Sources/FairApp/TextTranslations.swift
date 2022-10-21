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
import Foundation

#if canImport(SwiftUI)
import SwiftUI

/// This file contains references to the localized translated Text embedded in the `FairApp` module.
public extension Text {
    /// A standard translation of "The App Fair"
    static let TheAppFairText = Text("The App Fair", bundle: .module, comment: "standard compact translation of The App Fair")

    /// A standard translation of "Welcome"
    static let WelcomeText = Text("Welcome", bundle: .module, comment: "standard compact translation of Welcome")

    /// A standard translation of "Home"
    static let HomeText = Text("Home", bundle: .module, comment: "standard compact translation of Home")

    /// A standard translation of "Settings"
    static let SettingsText = Text("Settings", bundle: .module, comment: "standard compact translation of Settings")

    /// A standard translation of "Discover"
    static let DiscoverText = Text("Discover", bundle: .module, comment: "standard compact translation of Discover")

    /// A standard translation of "Search"
    static let SearchText = Text("Search", bundle: .module, comment: "standard compact translation of Search")

    /// A standard translation of "Language"
    static let LanguageText = Text("Language", bundle: .module, comment: "standard compact translation of Language")

    /// A standard translation of "Support"
    static let SupportText = Text("Support", bundle: .module, comment: "standard compact translation of Support")

    /// A standard translation of "Appearance"
    static let AppearanceText = Text("Appearance", bundle: .module, comment: "standard compact translation of Appearance")

    /// A standard translation of "Preferences"
    static let PreferencesText = Text("Preferences", bundle: .module, comment: "standard compact translation of Preferences")

    /// A standard translation of "Themes"
    static let ThemesText = Text("Themes", bundle: .module, comment: "standard compact translation of Themes")

}

#endif
