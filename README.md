# Fair

This project contains the engine for a fair-ground.
It consists of:

1. `fairtool`: a command-line tool for creating & managing fair-grounds
1. `FairCore` & `FairApp`: Swift modules for including runtime support for a fair-ground app

A fair-ground is an independent distribution platform
for free and open-source native apps written in SwiftUI.

## fairtool

The `fairtool` is a command-line executable for macOS12.
It is used to manage all aspects of an App distribution
fair-ground.

Quick start:

```
git clone https://github.com/fair-ground/Fair.git 
cd Fair 
swift run fairtool welcome
```

## Runtime support


Swift Package Manager usage:

```swift
// swift-tools-version:5.5
import PackageDescription

let package = Package(
    name: "App",
    defaultLocalization: "en",
    platforms: [ .macOS(.v12), .iOS(.v15) ],
    products: [ .library(name: "App", targets: ["App"]) ],
    dependencies: [
        .package(name: "Fair", url: "https://fair-ground.org/Fair.git", .branch("main")), 
    ],
    targets: [
        .target(name: "App", dependencies: [ .product(name: "FairApp", package: "Fair") ], resources: [.process("Resources"), .copy("Bundle")]),
        .testTarget(name: "AppTests", dependencies: ["App"]),
    ]
)
```

