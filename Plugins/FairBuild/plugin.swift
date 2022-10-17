import PackagePlugin
import Foundation

@main
struct FairBuildPlugin: BuildToolPlugin {
    func createBuildCommands(context: PluginContext, target: Target) throws -> [Command] {
        [
            .prebuildCommand(
                displayName: "FairBuild",
                executable: try dump(context.tool(named: "fairtool").path),
                arguments: [
                    "version",
                ],
                environment: [:],
                outputFilesDirectory: context.pluginWorkDirectory.appending("FairBuildOutput"))
        ]
    }
}

//#if canImport(XcodeProjectPlugin)
//import XcodeProjectPlugin
//
//extension FairBuildPlugin: XcodeBuildToolPlugin {
//    func createBuildCommands(context: XcodePluginContext, target: XcodeTarget) throws -> [Command] {
//        [
//            .buildCommand(
//                displayName: "FairTool",
//                executable: try context.tool(named: "fairtool").path,
//                arguments: [
//                    "version",
//                    //"--cache-path", "\(context.pluginWorkDirectory)"
//                ]
//            )
//        ]
//    }
//}
//#endif
