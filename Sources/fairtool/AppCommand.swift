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

public struct AppCommand : AsyncParsableCommand {
    public static let experimental = false
    public static var configuration = CommandConfiguration(commandName: "app",
                                                           abstract: "Commands for creating and validating an App Fair app.",
                                                           shouldDisplay: !experimental, subcommands: Self.subcommands)
#if os(macOS)
    static let subcommands: [ParsableCommand.Type] = [
        InfoCommand.self,
        RefreshCommand.self,
        LocalizeCommand.self,
    ]
#else
    static let subcommands: [ParsableCommand.Type] = [
        InfoCommand.self,
    ]
#endif

    public init() {
    }

    public struct InfoCommand: FairProjectCommand, FairStructuredCommand {
        public static let experimental = false
        public static var configuration = CommandConfiguration(commandName: "info", abstract: "Output information about the specified app(s).", shouldDisplay: !experimental)

        public typealias Output = FairProjectInfo

        @OptionGroup public var msgOptions: MsgOptions
        @OptionGroup public var projectOptions: ProjectOptions

        public init() {
        }

        public func executeCommand() -> AsyncThrowingStream<FairProjectInfo, Error> {
            msg(.debug, "getting info from project:", projectOptions.projectPathFlag)
            warnExperimental(Self.experimental)
            let projects = [URL(fileURLWithPath: projectOptions.projectPathFlag)]
            return executeStream(projects) {
                try parseGitConfig(from: $0)
            }
        }
    }

#if os(macOS)

    /// An aggregate command that performs the following tasks:
    ///
    ///  - create or update the docs/CNAME file
    ///  - create and update the localized strings file
    public struct RefreshCommand: FairAppCommand {
        public static let experimental = false
        public static var configuration = CommandConfiguration(commandName: "refresh", abstract: "Update project resources and configuration.", shouldDisplay: !experimental)

        @OptionGroup public var msgOptions: MsgOptions
        @OptionGroup public var projectOptions: ProjectOptions

        @Option(name: [.long], help: ArgumentHelp("The app target."))
        public var targets: [String] = ["App"]

        @Option(name: [.long], help: ArgumentHelp("The language to generate."))
        public var language: [String] = []

        public init() {
        }

        public func run() async throws {
            let info = try parseGitConfig(from: URL(fileURLWithPath: projectOptions.projectPathFlag))
            msg(.info, "refreshing project:", info.url)

            let fm = FileManager.default
            let host = info.url.deletingLastPathComponent().lastPathComponent.lowercased() + ".appfair.net"
            if try fm.update(url: projectOptions.projectPathURL(path: "docs/CNAME"), with: host.utf8Data) != nil {
                msg(.info, "set landing page:", host)
            }

            try await generateLocalizedStrings()
        }
    }

    public struct LocalizeCommand: FairAppCommand {
        public static let experimental = false
        public static var configuration = CommandConfiguration(commandName: "localize", abstract: "Generate Localized.strings files from source code.", shouldDisplay: !experimental)

        @OptionGroup public var msgOptions: MsgOptions
        @OptionGroup public var projectOptions: ProjectOptions

        @Option(name: [.long], help: ArgumentHelp("The package localization target."))
        public var targets: [String] = ["App"]

        @Option(name: [.long], help: ArgumentHelp("The locale to generate."))
        public var language: [String] = []

        public init() {
        }

        public func run() async throws {
            try await generateLocalizedStrings()
        }
    }

#endif
}

fileprivate extension FairProjectCommand {
    /// Get the git information from the given repository.
    func parseGitConfig(from url: URL, configPath: String = ".git/config") throws -> FairProjectInfo {
        msg(.info, "extracting info: \(url.path)")
        let gitConfigPath = projectOptions.projectPathURL(path: configPath)
        if !FileManager.default.isReadableFile(atPath: gitConfigPath.path) {
            throw AppError(String(format: NSLocalizedString("Project folder expected to be a git repository, but it does not contain a .git/FETCH_HEAD file", bundle: .module, comment: "error message")))
        }

        let config = try EnvFile(url: gitConfigPath)

        guard let origin = config["url", section: #"remote "origin""#],
              let originURL = URL(string: origin) else {
            throw AppError(String(format: NSLocalizedString("Missing remote origin url in .git/config file", bundle: .module, comment: "error message")))
        }


        let repoName = originURL.lastPathComponent
        let orgName = originURL.deletingLastPathComponent().lastPathComponent
        let baseURL = originURL.deletingLastPathComponent().deletingLastPathComponent()

        if baseURL.absoluteString != "https://github.com/" {
            throw AppError(String(format: NSLocalizedString("Unsupported repository host: %@", bundle: .module, comment: "error message"), arguments: [baseURL.absoluteString]))
        }

        if repoName != "App.git" && repoName != "App" {
            throw AppError(String(format: NSLocalizedString("Repository must be named “App”, but found “%@”", bundle: .module, comment: "error message"), arguments: [repoName]))

        }

        let org = orgName.dehyphenated()
        return FairProjectInfo(name: org, url: originURL)
    }
}

