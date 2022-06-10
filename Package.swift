// swift-tools-version:5.5
/**
 This program is free software: you can redistribute it and/or modify
 it under the terms of the GNU Affero General Public License as
 published by the Free Software Foundation, either version 3 of the
 License, or (at your option) any later version.

 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU Affero General Public License for more details.

 You should have received a copy of the GNU Affero General Public License
 along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */
import PackageDescription

#if canImport(Compression)
let coreTargets: [Target] = [
    .target(name: "FairCore", resources: [.process("Resources"), .copy("Bundle")]),
]
#else
let coreTargets: [Target] = [
    .systemLibrary(name: "CZLib", pkgConfig: "zlib", providers: [.brew(["zlib"]), .apt(["zlib"])]),
    .target(name: "FairCore", dependencies: ["CZLib"], resources: [.process("Resources"), .copy("Bundle")], cSettings: [.define("_GNU_SOURCE", to: "1")]),
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
    ],
    dependencies: [
        // zero dependencies
    ],
    targets: coreTargets + [
        .target(name: "FairApp", dependencies: ["FairCore"], resources: [.process("Resources"), .copy("Bundle")]),
        .target(name: "FairExpo", dependencies: ["FairApp"], resources: [.process("Resources"), .copy("Bundle")]),
        .target(name: "FairKit", dependencies: ["FairApp"], resources: [.process("Resources"), .copy("Bundle")]),
        .executableTarget(name: "FairTool", dependencies: ["FairExpo"]),

        .testTarget(name: "FairCoreTests", dependencies: ["FairCore"]),
        .testTarget(name: "FairAppTests", dependencies: [.target(name: "FairApp")], resources: [.process("Resources"), .copy("Bundle")]),
        .testTarget(name: "FairKitTests", dependencies: [.target(name: "FairKit")]),
        .testTarget(name: "FairExpoTests", dependencies: [.target(name: "FairExpo")]),
        .testTarget(name: "FairToolTests", dependencies: [.target(name: "FairTool")])
    ]
)
