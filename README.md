The `fairtool` is a cross-platform (Linux & macOS) command-line utility for 
managing an ecosystem of apps.
It is powered by the Fair library, which is a zero-dependency 
cross-platform (Linux, macOS, & iOS) Swift 5.6 module licensed under the GNU AGPL.
This library is used to power app distribution networks such as 
[https://appfair.net](https://appfair.net), as well as the end-user applications
that utilize them such as [https://appfair.app](https://appfair.app).

## fairtool

The functionality of the `Fair` module can best be illustrated by the
capabilities of the `fairtool`, which is a command-line utility for
macOS (12+) and Linux. The easiest way to get started with the
utility for [Homebrew](https://brew.sh) users is to run the commands:

```shell
% brew tap appfair/app

==> Tapping appfair/app
Tapped 37 casks and 2 formulae (53 files, 778.2KB).

% brew install fairtool

==> Downloading https://github.com/fair-ground/Fair/releases/download/0.4.36/fai
==> Downloading from https://objects.githubusercontent.com/github-production-rel
######################################################################## 100.0%
==> Installing fairtool from appfair/app
==> Pouring fairtool-0.4.36.arm64_monterey.bottle.tar.gz
🍺  /opt/homebrew/Cellar/fairtool/0.4.36: 6 files, 9.9MB

% fairtool version

fairtool 0.4.36
```

Alternatively, if you have a Swift 5.6 compiler installed,
you can build and run from the source:

```shell
% git clone https://fair-ground.org/Fair.git

Cloning into 'Fair'...
remote: Enumerating objects: 43471, done.
remote: Counting objects: 100% (4455/4455), done.
remote: Compressing objects: 100% (525/525), done.
remote: Total 43471 (delta 3755), reused 4454 (delta 3754), pack-reused 39016
Receiving objects: 100% (43471/43471), 12.90 MiB | 13.17 MiB/s, done.
Resolving deltas: 100% (39783/39783), done.

% cd Fair

% swift run fairtool version

Building for debugging...
[61/61] Linking fairtool
Build complete! (9.94s)

fairtool 0.4.36
```

### fairtool app info _file_.app

The "app info" command will examine a macOS `.app` folder 
or an unencrypted `.ipa` file or url
and output a JSON representation of the contents of the app's
`Info.plist` along with the entitlements embedded within the 
app's primary executable.

```json
% fairtool app info /System/Applications/Calculator.app

[
  {
    "entitlements" : [
      {
        "com.apple.security.app-sandbox" : true,
        "com.apple.security.files.user-selected.read-write" : true,
        "com.apple.security.network.client" : true,
        "com.apple.security.print" : true
      },
      {
        "com.apple.security.app-sandbox" : true,
        "com.apple.security.files.user-selected.read-write" : true,
        "com.apple.security.network.client" : true,
        "com.apple.security.print" : true
      }
    ],
    "info" : {
      "BuildMachineOSBuild" : "20A241133",
      "CFBundleDevelopmentRegion" : "English",
      "CFBundleExecutable" : "Calculator",
      "CFBundleHelpBookFolder" : "Calculator.help",
      "CFBundleHelpBookName" : "com.apple.Calculator.help",
      "CFBundleIconFile" : "AppIcon",
      "CFBundleIconName" : "AppIcon",
      "CFBundleIdentifier" : "com.apple.calculator",
      "CFBundleInfoDictionaryVersion" : "6.0",
      "CFBundleName" : "Calculator",
      "CFBundlePackageType" : "APPL",
      "CFBundleShortVersionString" : "10.16",
      "CFBundleSignature" : "????",
      "CFBundleSupportedPlatforms" : [
        "MacOSX"
      ],
      "CFBundleVersion" : "223",
      "CTIgnoreUserFonts" : true,
      "DTCompiler" : "com.apple.compilers.llvm.clang.1_0",
      "DTPlatformBuild" : "13E6049a",
      "DTPlatformName" : "macosx",
      "DTPlatformVersion" : "12.4",
      "DTSDKBuild" : "21F64",
      "DTSDKName" : "macosx12.4.internal",
      "DTXcode" : "1330",
      "DTXcodeBuild" : "13E6049a",
      "LSApplicationCategoryType" : "public.app-category.utilities",
      "LSApplicationSecondaryCategoryType" : "public.app-category.productivity",
      "LSHasLocalizedDisplayName" : true,
      "LSMinimumSystemVersion" : "12.4",
      "NSMainNibFile" : "Calculator",
      "NSPrincipalClass" : "NSApplication",
      "NSSupportsSuddenTermination" : true
    },
    "url" : "file:///System/Applications/Calculator.app/"
  }
]
```

The `info` property contains a JSON-ized form of the contents 
if the `Info.plist`.
The `entitlements` array contains the entitlements extracted from
the binary. Note that in the case of multi-architecture binaries 
(such as a "universal binary"), one set of entitlements will be
output for each processor architectures in the Mach-O binary.


### fairtool app info _file_.ipa

The fairtool can also output the same information for an unencrypted
iOS .ipa file, either a local file or a remote URL:

```json5
// fairtool app info https://github.com/Cloud-Cuckoo/App/releases/latest/download/Cloud-Cuckoo-iOS.ipa

[
  {
    "entitlements" : [
  
    ],
    "info" : {
      "BuildMachineOSBuild" : "21F79",
      "CFBundleExecutable" : "Cloud Cuckoo",
      "CFBundleIcons" : {
        "CFBundlePrimaryIcon" : {
          "CFBundleIconFiles" : [
            "AppIcon60x60"
          ],
          "CFBundleIconName" : "AppIcon"
        }
      },
      "CFBundleIcons~ipad" : {
        "CFBundlePrimaryIcon" : {
          "CFBundleIconFiles" : [
            "AppIcon60x60",
            "AppIcon76x76"
          ],
          "CFBundleIconName" : "AppIcon"
        }
      },
      "CFBundleIdentifier" : "app.Cloud-Cuckoo",
      "CFBundleInfoDictionaryVersion" : "6.0",
      "CFBundleName" : "Cloud Cuckoo",
      "CFBundlePackageType" : "APPL",
      "CFBundleShortVersionString" : "0.9.95",
      "CFBundleSupportedPlatforms" : [
        "iPhoneOS"
      ],
      "CFBundleURLTypes" : [
        {
          "CFBundleTypeRole" : "Editor",
          "CFBundleURLName" : "Cloud Cuckoo",
          "CFBundleURLSchemes" : [
            "app.Cloud-Cuckoo"
          ]
        }
      ],
      "CFBundleVersion" : "453",
      "DTCompiler" : "com.apple.compilers.llvm.clang.1_0",
      "DTPlatformBuild" : "19C51",
      "DTPlatformName" : "iphoneos",
      "DTPlatformVersion" : "15.2",
      "DTSDKBuild" : "19C51",
      "DTSDKName" : "iphoneos15.2",
      "DTXcode" : "1321",
      "DTXcodeBuild" : "13C100",
      "ITSAppUsesNonExemptEncryption" : false,
      "LSApplicationQueriesSchemes" : [
        "appfair"
      ],
      "LSMinimumSystemVersion" : "12.0",
      "LSSupportsOpeningDocumentsInPlace" : true,
      "LSUIPresentationMode" : 0,
      "MinimumOSVersion" : "15.0",
      "NSAccentColorName" : "AccentColor",
      "NSAppleEventsUsageDescription" : "AppleScript can be used by this app.",
      "NSAppleScriptEnabled" : true,
      "NSAppTransportSecurity" : {
        "NSAllowsArbitraryLoads" : true
      },
      "NSHumanReadableCopyright" : "GNU Affero General Public License",
      "UIApplicationSceneManifest" : {
        "UIApplicationSupportsMultipleScenes" : true
      },
      "UIApplicationSupportsIndirectInputEvents" : true,
      "UIDeviceFamily" : [
        1,
        2
      ],
      "UILaunchScreen" : {
  
      },
      "UIRequiredDeviceCapabilities" : [
        "arm64"
      ],
      "UISupportedInterfaceOrientations" : [
        "UIInterfaceOrientationPortrait",
        "UIInterfaceOrientationPortraitUpsideDown",
        "UIInterfaceOrientationLandscapeLeft",
        "UIInterfaceOrientationLandscapeRight"
      ]
    },
    "url" : "https://github.com/Cloud-Cuckoo/App/releases/latest/download/Cloud-Cuckoo-iOS.ipa"
  }
]
```

### fairtool JSON output

Most of the fairtool's informational operations will output
well-formed JSON. This is so it can be used in conjunction with
other tools.

One such tools is the popular `jq` utility, which can be used to format,
filter, and re-structure JSON. For example, to examine an app's
"*UsageDescription" properties (which will give insight into which
privacy-sensitive operations the app is capable of performing), you might run:

```
% fairtool app info /Applications/Signal.app | jq '.[].info | with_entries(select(.key|match("UsageDescription")))[]'

"This app needs access to Bluetooth"
"This app needs access to the camera"
"This app needs access to the microphone"
```

### fairtool online 

An experimental web service with limited functionality is available at
[https://fairtool.herokuapp.com](https://fairtool.herokuapp.com).
The service can be used to inspect the properties of .app .zip and .ipa
URLs online, as well as generate default catalog entries for
application artifacts.


## Fair Library

The `fairtool` is powered by the `Fair` library, which is a
zero-dependency cross-platform set of modules written in Swift.



## Swift Package Manager usage

In order to add the Fair module to an existing package named "App",


```swift
// swift-tools-version: 5.6
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "App",
    platforms: [ .macOS(.v12), .iOS(.v15) ],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "App",
            targets: ["App"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
        .package(url: "https://fair-ground.org/Fair.git", from: "0.4.0"), 
    ],
    targets: [
        .target(name: "App", dependencies: [
            // platform-native support for Fair apps (macOS, iOS, Linux)
            .product(name: "FairApp", package: "Fair"),
            // low-level data structures and utilities (macOS, iOS, Linux)
            .product(name: "FairCore", package: "Fair"),
            // optional networking utilities (macOS, iOS, Linux)
            .product(name: "FairExpo", package: "Fair"),
            // optional SwiftUI enhancements (macOS, iOS)
            .product(name: "FairKit", package: "Fair"),
        ]),
        .testTarget(name: "AppTests", dependencies: ["App"]),
    ]
)
```

