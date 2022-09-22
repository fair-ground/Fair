import Foundation
import PackagePlugin
#if canImport(XcodeProjectPlugin)
import XcodeProjectPlugin
#endif

@main
struct MyCommandPlugin: CommandPlugin {

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

//
//struct FairToolPlugin: BuildToolPlugin {
//    func createBuildCommands(context: PluginContext, target: Target) async throws -> [Command] {
//        guard let target = target as? SourceModuleTarget else {
//            return []
//        }
//
//        let resourcesDirectoryPath = context.pluginWorkDirectory
//            .appending(subpath: target.name)
//            .appending(subpath: "Resources")
//        let localizationDirectoryPath = resourcesDirectoryPath.appending(subpath: "en.lproj")
//
//        try FileManager.default.createDirectory(atPath: localizationDirectoryPath.string, withIntermediateDirectories: true)
//
//        let swiftSourceFiles = target.sourceFiles(withSuffix: ".swift")
//        let inputFiles = swiftSourceFiles.map(\.path)
//
//        //print("swift file: \(swiftSourceFiles), inputfile: \(inputFiles)")
//        //print("FairToolPlugin invoke")
//
//        //Diagnostics.emit(Diagnostics.Severity.error, "Diagnostics: FairToolPlugin emit error")
//        //Diagnostics.error("Diagnostics: FairToolPlugin error")
//        //Diagnostics.warning("Diagnostics: FairToolPlugin warning")
//        //Diagnostics.remark("Diagnostics: FairToolPlugin remark")
//
//        Diagnostics.remark("FairTool: extracting localized strings")
//
////        let gitLogPath = context.pluginWorkDirectory.appending(subpath: "gstlog.txt")
////        try FileManager.default.createFile(atPath: gitLogPath.string, contents: nil)
//
//        let stringsOutput = localizationDirectoryPath.appending(subpath: "Localizable.strings")
//
//        return [
//            .prebuildCommand(
//                displayName: "Generating Localized strings from source files",
//                executable: .init("/usr/bin/xcrun"),
//                arguments: ["genstrings", "-SwiftUI", "-o", localizationDirectoryPath] + inputFiles,
//                outputFilesDirectory: localizationDirectoryPath),
//            .prebuildCommand(
//                displayName: "Convert Localized strings encoding",
//                executable: .init("/usr/bin/iconv"),
//                arguments: ["-c", "-f", "utf-16", "-t", "utf-8", stringsOutput], // , ">", "/tmp/foo.strings"],
//                outputFilesDirectory: localizationDirectoryPath),
//            //.prebuildCommand(displayName: "build command git status", executable: .init( "/usr/bin/sh"), arguments: ["ls"], outputFilesDirectory: localizationDirectoryPath),
//
//            //.buildCommand(displayName: "build command git status", executable: .init( "/usr/bin/git"), arguments: ["status"], outputFiles: [gitLogPath])
//        ]
//    }
//}
