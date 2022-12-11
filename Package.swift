// swift-tools-version:5.6
import PackageDescription

extension Platform {
#if os(macOS)
    static let current: Platform = .macOS
#elseif os(iOS)
    static let current: Platform = .iOS
#elseif os(tvOS)
    static let current: Platform = .tvOS
#elseif os(watchOS)
    static let current: Platform = .watchOS
#elseif os(Android)
    static let current: Platform = .android
#elseif os(Linux)
    static let current: Platform = .linux
#elseif os(Windows)
    static let current: Platform = .windows
#else
    #error("Unsupported platform.")
#endif
}

let package = Package(
    name: "Fair",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v12), .iOS(.v15), .tvOS(.v15), .watchOS(.v8)
    ],
    products: [
        .library(name: "FairCore", targets: ["FairCore"]),
        Platform.current == .android ? nil : .library(name: "FairApp", targets: ["FairApp"]),
        Platform.current == .android ? nil : .library(name: "FairKit", targets: ["FairKit"]),
        Platform.current == .android ? nil : .library(name: "FairExpo", targets: ["FairExpo"]),
        Platform.current == .macOS || Platform.current == .linux ? .executable(name: "fairtool", targets: ["fairtool"]) : nil,
        Platform.current == .macOS ? .plugin(name: "FairToolPlugin", targets: ["FairToolPlugin"]) : nil,
        Platform.current == .macOS ? .plugin(name: "FairBuild", targets: ["FairBuild"]) : nil,
    ].compactMap({ $0 }),
dependencies: [ .package(name: "swift-docc-plugin", url: "https://github.com/apple/swift-docc-plugin", from: "1.0.0"),
    ],
    targets: [
        .target(name: "CZLib", linkerSettings: [ .linkedLibrary("z") ]),
        .target(name: "FairCore", dependencies: ["CZLib"], resources: [.process("Resources")], cSettings: [.define("_GNU_SOURCE", to: "1")]),
        Platform.current == .android ? nil : .target(name: "FairApp", dependencies: ["FairCore"], resources: [.process("Resources")]),
        Platform.current == .android ? nil : .target(name: "FairExpo", dependencies: ["FairApp"], resources: [.process("Resources")]),
        Platform.current == .android ? nil : .target(name: "FairKit", dependencies: ["FairApp"], resources: [.process("Resources")]),

        Platform.current == .macOS || Platform.current == .linux ? .executableTarget(name: "fairtool", dependencies: ["FairExpo"]) : nil,

        Platform.current == .macOS ? .plugin(name: "FairToolPlugin", capability: .command(intent: .custom(verb: "fairtool", description: "Runs fairtool in a sandboxed environment."), permissions: [ .writeToPackageDirectory(reason: "This plugin will update the project source and configuration files. Use `swift package --allow-writing-to-package-directory fairtool` to skip this prompt.") ]), dependencies: ["fairtool"]) : nil,

        Platform.current == .macOS ? .plugin(name: "FairBuild", capability: .buildTool(), dependencies: ["fairtool"]) : nil,

        .testTarget(name: "FairCoreTests", dependencies: ["FairCore"], resources: [.process("Resources")]),
        Platform.current == .android ? nil : .testTarget(name: "FairAppTests", dependencies: [.target(name: "FairApp")], resources: [.process("Resources")]),
        Platform.current == .android ? nil : .testTarget(name: "FairKitTests", dependencies: [.target(name: "FairKit")], resources: [.process("Resources")]),
        Platform.current == .android ? nil : .testTarget(name: "FairExpoTests", dependencies: [.target(name: "FairExpo")], resources: [.process("Resources")]),
        Platform.current == .macOS || Platform.current == .linux ? .testTarget(name: "FairToolTests", dependencies: [.target(name: "fairtool")], resources: [.process("Resources")]) : nil,

    ].compactMap({ $0 })
)
