# Fair

This project is the engine for running a fair-ground such as 
[The App Fair](https://www.appfair.net).

A fair-ground is an independent distribution platform
for free and open-source native apps written in SwiftUI.

For more information, see the
[fair-ground documentation](https://www.appfair.net/#the-app-fair-fair-ground).


SPM usage:

```swift
// swift-tools-version:5.5
import PackageDescription

let package = Package(
    name: "App",
    defaultLocalization: "en",
    platforms: [ .macOS(.v11), .iOS(.v14) ],
    products: [ .library(name: "App", targets: ["App"]) ],
    dependencies: [
        .package(name: "Fair", url: "https://appfair.org/Fair.git", .branch("main")),
    ],
    targets: [
        .target(name: "App", dependencies: [ .product(name: "FairApp", package: "Fair") ], resources: [.process("Resources"), .copy("Bundle")]),
        .testTarget(name: "AppTests", dependencies: ["App"]),
    ]
)
```



