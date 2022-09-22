// swift-tools-version:5.6
import PackageDescription

#if os(Linux)
let (linux, macOS, windows) = (true, false, false)
#elseif os(Windows)
let (linux, macOS, windows) = (false, false, true)
#elseif os(macOS)
let (linux, macOS, windows) = (false, true, false)
#endif

#if canImport(Compression)
let coreTargets: [Target] = [
    .target(name: "FairCore", resources: [.process("Resources")]),
]
#else
let coreTargets: [Target] = [
    .systemLibrary(name: "CZLib", pkgConfig: "zlib", providers: [.brew(["zlib"]), .apt(["zlib"])]),
    .target(name: "FairCore", dependencies: ["CZLib"], resources: [.process("Resources")], cSettings: [.define("_GNU_SOURCE", to: "1")]),
]
#endif

let package = Package(
    name: "Fair",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v12), .iOS(.v15), .tvOS(.v15), .watchOS(.v8)
    ],
    products: [
        .library(name: "FairCore", targets: ["FairCore"]),
        .library(name: "FairApp", targets: ["FairApp"]),
        .library(name: "FairKit", targets: ["FairKit"]),
        .library(name: "FairExpo", targets: ["FairExpo"]),
        .executable(name: "fairtool", targets: ["FairTool"]),
        .plugin(name: "FairToolPlugin", targets: ["FairToolPlugin"]),
    ],
dependencies: [ .package(name: "swift-docc-plugin", url: "https://github.com/apple/swift-docc-plugin", from: "1.0.0"),
    ],
    targets: [
        .target(name: "FairCore", dependencies: linux ? ["CZLib"] : [], resources: [.process("Resources")]),
        .target(name: "FairApp", dependencies: ["FairCore"], resources: [.process("Resources")]),
        .target(name: "FairExpo", dependencies: ["FairApp"], resources: [.process("Resources")]),
        .target(name: "FairKit", dependencies: ["FairApp"], resources: [.process("Resources")]),

        .executableTarget(name: "FairTool", dependencies: ["FairExpo"]),
        .plugin(name: "FairToolPlugin", capability: .command(intent: .custom(verb: "fairtool", description: "Runs fairtool in a sandboxed environment."), permissions: [ .writeToPackageDirectory(reason: "This plugin will update the project source and configuration files. Use `swift package --allow-writing-to-package-directory fairtool` to skip this prompt.") ]), dependencies: ["FairTool"]),

        .testTarget(name: "FairCoreTests", dependencies: ["FairCore"], resources: [.process("Resources")]),
        .testTarget(name: "FairAppTests", dependencies: [.target(name: "FairApp")], resources: [.process("Resources")]),
        .testTarget(name: "FairKitTests", dependencies: [.target(name: "FairKit")], resources: [.process("Resources")]),
        .testTarget(name: "FairExpoTests", dependencies: [.target(name: "FairExpo")], resources: [.process("Resources")]),
        .testTarget(name: "FairToolTests", dependencies: [.target(name: "FairTool")], resources: [.process("Resources")]),

        linux ? .systemLibrary(name: "CZLib", pkgConfig: "zlib", providers: [.brew(["zlib"]), .apt(["zlib"])]) : nil,
    ].compactMap({ $0 })
)
