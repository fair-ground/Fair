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

        .testTarget(name: "FairCoreTests", dependencies: ["FairCore"], resources: [.process("Resources"), .copy("Bundle")]),
        .testTarget(name: "FairAppTests", dependencies: [.target(name: "FairApp")], resources: [.process("Resources"), .copy("Bundle")]),
        .testTarget(name: "FairKitTests", dependencies: [.target(name: "FairKit")], resources: [.process("Resources"), .copy("Bundle")]),
        .testTarget(name: "FairExpoTests", dependencies: [.target(name: "FairExpo")], resources: [.process("Resources"), .copy("Bundle")]),
        .testTarget(name: "FairToolTests", dependencies: [.target(name: "FairTool")], resources: [.process("Resources"), .copy("Bundle")])
    ]
)
