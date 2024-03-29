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
import FairExpo
import FairApp
import ArgumentParser

public struct TranslateCommand : AsyncParsableCommand {
    public static let experimental = false
    public static var configuration = CommandConfiguration(commandName: "translate",
                                                           abstract: "Commands for handling localizations",
                                                           shouldDisplay: !experimental, subcommands: Self.subcommands)
    static let subcommands: [ParsableCommand.Type] = [
        ScanCommand.self,
    ]

    public init() {
    }


    /// An aggregate command that performs the following tasks:
    ///
    ///  - create or update the docs/CNAME file
    ///  - create and update the localized strings file
    public struct ScanCommand: FairMsgCommand {
        public static let experimental = true
        public static var configuration = CommandConfiguration(commandName: "scan", abstract: "Scans translations for the given key(s)", shouldDisplay: !experimental)

        @OptionGroup public var msgOptions: MsgOptions
        @OptionGroup public var projectOptions: ProjectOptions

        @Option(name: [.long], help: ArgumentHelp("The translation keys to search for"))
        public var key: [String] = [".*"]

        @Argument(help: ArgumentHelp("Resources folder to scan", valueName: "dir", visibility: .default))
        public var dir: [String]

        public init() {
        }

        public func run() async throws {
            for dir in dir {
                msg(.info, "scanning", dir)
                do {
                    let locales: [String : [(URL, Plist)]] = try loadLocalizations(resourcesFolder: URL(fileOrScheme: dir), localeFileName: ".*.strings")
                    msg(.info, "loaded", locales.count, "languages", locales.keys.sorted())
                    for (_, localeFiles) in locales {
                        //msg(.info, "locale", localeName)
                        for (localeFile, plist) in localeFiles {
                            for keyArg in self.key {
                                for (pkey, pvalue) in plist.rawValue {
                                    guard let skey = pkey as? String else { continue }
                                    if try skey.matches(regex: keyArg) {
                                        msg(.info, dir, "locale:", localeFile.path, "key:", skey, "value:", pvalue)
                                        // TODO: store the localized translations
                                    }
                                }
                            }
                        }
                    }
                } catch {
                    msg(.info, "error loading:", dir, error)
                }
            }
        }
    }
}
