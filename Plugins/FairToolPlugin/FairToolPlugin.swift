import Foundation
import PackagePlugin
#if canImport(XcodeProjectPlugin)
import XcodeProjectPlugin
#endif

/// A plug-in that invokes the fairtool from the SPM sandbox.
@main struct FairToolPlugin: CommandPlugin {
    func performCommand(context: PluginContext, arguments: [String]) throws {
        Diagnostics.emit(.remark, "running fairtool with arguments: \(arguments)")

        let tool = try context.tool(named: "fairtool")
        let toolUrl = URL(fileURLWithPath: tool.path.string)

        let process = Process()
        process.executableURL = toolUrl
        process.arguments = arguments

        Diagnostics.emit(.remark, "running: \(toolUrl.path) with arguments: \(process.arguments!.joined())")

        try process.run()
        process.waitUntilExit()
    }
}
