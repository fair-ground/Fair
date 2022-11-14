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
import FairApp

public struct ArtifactCommand : AsyncParsableCommand {
    public static let experimental = false
    public static var configuration = CommandConfiguration(commandName: "artifact",
                                                           abstract: "Commands for examining a compiled app artifact.",
                                                           shouldDisplay: !experimental, subcommands: Self.subcommands)

    static let subcommands: [ParsableCommand.Type] = [
        InfoCommand.self,
    ]

    public init() {
    }

    public struct InfoCommand: FairStructuredCommand {
        public static let experimental = false
        public static var configuration = CommandConfiguration(commandName: "info",
                                                               abstract: "Output information about the specified app(s).",
                                                               shouldDisplay: !experimental)

        public typealias Output = InfoItem

        public struct InfoItem : FairCommandOutput, Decodable {
            public var url: URL
            public var info: JSum
            public var entitlements: [JSum]?
        }

        @OptionGroup public var msgOptions: MsgOptions
        @OptionGroup public var downloadOptions: DownloadOptions

        @Argument(help: ArgumentHelp("Path(s) or url(s) for app folders or ipa archives", valueName: "apps", visibility: .default))
        public var apps: [String]

        public init() {
        }

        public func executeCommand() -> AsyncThrowingStream<InfoItem, Error> {
            msg(.debug, "getting info from apps:", apps)
            return executeStream(apps) { app in
                return try await extractInfo(from: downloadOptions.acquire(path: app, onDownload: { url in
                    msg(.info, "downloading from URL:", url.absoluteString)
                    return url
                }))
            }
        }

        private func extractInfo(from: (from: URL, local: URL)) async throws -> InfoItem {
            msg(.info, "extracting info: \(from.from)")
            let (info, entitlements) = try AppBundleLoader.loadInfo(fromAppBundle: from.local)

            return try InfoItem(url: from.from, info: info.jsum(), entitlements: entitlements?.map({ try $0.jsum() }))
        }
    }
}
