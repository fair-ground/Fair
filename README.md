The `fairtool` is a cross-platform (Linux & macOS) command-line utility for 
managing an ecosystem of apps.
It is powered by the Fair package, which is a zero-dependency 
cross-platform (Linux, macOS, & iOS) set of Swift 5.6 modules.

The Fair package is used to power app distribution networks such as 
[appfair.net](https://appfair.net), as well as the end-user applications
that interface with them such as [App Fair.app](https://appfair.app).

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

```json5
// fairtool app info /System/Applications/Calculator.app
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


### fairtool app info _url_.ipa

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

Another useful application might be to download and check the
version of an online app download. For example:

```
% fairtool app info https://github.com/Cloud-Cuckoo/App/releases/latest/download/Cloud-Cuckoo-macOS.zip | jq '.[].info.CFBundleShortVersionString'

downloading from URL: https://github.com/Cloud-Cuckoo/App/releases/latest/download/Cloud-Cuckoo-macOS.zip
extracting info: https://github.com/Cloud-Cuckoo/App/releases/latest/download/Cloud-Cuckoo-macOS.zip

"0.9.95"
```

#### Multi-line JSON output

When the fairtool command outputs JSON, it does it as a single top-level
array with one  element for each command line argument.
This allows the output to be produced as each (potentially slow) resources is
acquired and analyzed.

For example, the following command may take some time to complete:

```
% fairtool app info /System/Applications/*.app | jq '.[].info.CFBundleName'

"App Store"
"Automator"
"Books"
…
"TV"
"TextEdit"
"Time Machine"
"VoiceMemos"
```


The end result will not be printed until the command has completed,
since `jq` is waiting for the entire array before it will process
the command.

You can, instead, "promote" the JSON output from an embedded array
to the straight output of raw JSON objects using the `-J` flag,
which will then enable `jq` to process them as they are produced.

Contrast this command with the one above:

```
% fairtool app info -J /System/Applications/*.app | jq '.info.CFBundleName'
```

The output will be the same, but the latter command with the `-J`
flag will output each element in turn as it is downloaded.
This can be especially important when checking potentially slow
access to online resources, or when processing may archives at once.


### fairtool source create

The `fairtool source create` command will analyze the information
from `fairtool app info` and generate an App Source Catalog JSON blob. 
This catalog format is supported by app installation tools like
[The App Fair](https://appfair.app) on macOS and
[AltStore](https://altstore.io) on iOS.

The tool has the following options:

```
% fairtool source create --help 

OVERVIEW: Create a source from the specified .ipa or .zip.

USAGE: fairtool source create [--verbose] [--quiet] [--promote-json] [--catalog-name <name>] [--catalog-identifier <id>] [--catalog-source-url <url>] [--app-localized-description <desc> ...] [--app-version-description <desc> ...] [--app-subtitle <title> ...] [--app-developer-name <email> ...] [--app-download-url <URL> ...] [<apps> ...]

ARGUMENTS:
  <apps>                  path(s) or url(s) for app folders or ipa archives

OPTIONS:
  -v, --verbose           whether to display verbose messages.
  -q, --quiet             whether to be suppress output.
  -J, --promote-json      exclude root JSON array from output.
  --catalog-name <name>   the name of the catalog.
  --catalog-identifier <id>
                          the identifier of the catalog.
  --catalog-source-url <url>
                          the source URL of the catalog.
  --app-localized-description <desc>
                          the default description(s) for the app(s).
  --app-version-description <desc>
                          the default versionDescription for the app(s).
  --app-subtitle <title>  the default subtitle(s) for the app(s).
  --app-developer-name <email>
                          the default developer name(s) for the app(s).
  --app-download-url <URL>
                          the download URLfor the app(s).
  -h, --help              Show help information.
```

An example of the catalog output is as follows:

```json5
// fairtool source create https://github.com/Cloud-Cuckoo/App/releases/latest/download/Cloud-Cuckoo-iOS.ipa

{
  "identifier": "CATALOG_IDENTIFIER",
  "name": "CATALOG_NAME",
  "apps": [
    {
      "bundleIdentifier": "app.Cloud-Cuckoo",
      "developerName": "DEVELOPER_NAME",
      "downloadURL": "https://github.com/Cloud-Cuckoo/App/releases/latest/download/Cloud-Cuckoo-iOS.ipa",
      "localizedDescription": "LOCALIZED_DESCRIPTION",
      "name": "Cloud Cuckoo",
      "permissions": [
        {
          "type": "usage",
          "usage": "NSAppleEventsUsageDescription",
          "usageDescription": "AppleScript can be used by this app."
        }
      ],
      "screenshotURLs": [],
      "sha256": "56e748bf053aff8612702ba9f1aa13031ef0c29313cc4047e3176b9ba8526686",
      "size": 5136274,
      "subtitle": "SUBTITLE",
      "version": "0.9.95",
      "versionDate": "2022-07-02T04:57:53Z",
      "versionDescription": "VERSION_DESCRIPTION"
    }
  ]
}

```


### fairtool source verify

The `fairtool source verify` can be used to check the validity of the
apps in a JSON catalog.

For example:

```shell
% fairtool source create https://github.com/Cloud-Cuckoo/App/releases/latest/download/Cloud-Cuckoo-iOS.ipa > catalog.json

% fairtool source verify catalog.json

[
  {
    "app": {
      "bundleIdentifier": "app.Cloud-Cuckoo"
      "sha256": "56e748bf053aff8612702ba9f1aa13031ef0c29313cc4047e3176b9ba8526686",
      "size": 5136274
    }
  }
]
```

If, for example, the resource at the `downloadURL` no longer matches the
SHA256 checksum or file size, the catalog's validation errors 
would look like:

```json
[
  {
    "app": {
      "bundleIdentifier": "app.Cloud-Cuckoo"
      "size": 5136274,
      "sha256": "56e748bf053aff8612702ba9f1aa13031ef0c29313cc4047e3176b9ba8526686"
    },
    "failures": [
      {
        "type": "size_mismatch",
        "message": "Download size mismatch (5136274 vs. 5052688) from: https://github.com/Cloud-Cuckoo/App/releases/latest/download/Cloud-Cuckoo-iOS.ipa"
      },
      {
        "type": "checksum_failed",
        "message": "Checksum mismatch (56e748bf053aff8612702ba9f1aa13031ef0c29313cc4047e3176b9ba8526686 vs. 07e74b8db6eed309a6cdc92e40d5f7b7fd00922126f8ff49085516dd052ffa3a) from: https://github.com/Cloud-Cuckoo/App/releases/latest/download/Cloud-Cuckoo-iOS.ipa"
      }
    ]
  }
]
```


#### App Source Catalog

The format of the catalog and the meaning of the various properties is described
at [https://appfair.net/#app-source-catalog](https://appfair.net/#app-source-catalog).


### fairtool online 

An experimental web service with a subset of the 
fairtool's functionality is available at:
[https://fairtool.herokuapp.com](https://fairtool.herokuapp.com).

This service can be used to inspect the properties of `.app` `.zip` and `.ipa`
URLs online, as well as generate default catalog entries for
application artifacts.


## Fair Library

The `fairtool` is powered by the `Fair` package, which is a
zero-dependency cross-platform set of modules written in Swift.
There are four top-level modules in the package:

### FairCore

The `FairCore` module is the lowest-level set of data structures and
algorithms shared throughout the package.
It supports macOS 12+, iOS 15+, and Linux (Windows is close,
but needs a fix for missing zlib; Android is TBD).

Some notable types that are used throughout the `Fair*` modules are
[JSum](https://fair-ground.github.io/Fair/documentation/faircore/jsum/)
and
[XOr](https://fair-ground.github.io/Fair/documentation/faircore/xor/).

FairCore also contains utilities for 
[zip file handling](https://fair-ground.github.io/Fair/documentation/faircore/ziparchive)
and 
[XML parsing](https://fair-ground.github.io/Fair/documentation/faircore/xmlnode).

See the [documentation for FairCore](https://fair-ground.github.io/Fair/documentation/faircore/).

### FairApp

The `FairApp` module contains the necessary functionality for
building and distributing an app on a fair ground such as
[appfair.net](https://appfair.net). `FairApp` depends on `FairCore`.

Important types are
[AppCatalog](https://fair-ground.github.io/Fair/documentation/fairapp/appcatalog),
which is a serialized form of the [App Source Catalog](#app-source-catalog) format,
[AppBundle](https://fair-ground.github.io/Fair/documentation/fairapp/appbundle),
which is an abstraction of the packing of an iOS or macOS app.

See the [documentation for FairApp](https://fair-ground.github.io/Fair/documentation/fairapp/).

### FairExpo

The `FairExpo` module provides a cross-platform set of networking
protocols, such as utilities for interacting with a
[GraphQLEndpointService](https://fair-ground.github.io/Fair/documentation/fairexpo/graphqlendpointservice),
getting metadata from the
[HomebrewAPI](https://fair-ground.github.io/Fair/documentation/fairexpo/homebrewapi/),
and creating and verifying App Source catalogs with the
[https://fair-ground.github.io/Fair/documentation/fairexpo/appcatalogapi](AppCatalogAPI).

 `FairExpo` depends on `FairApp`.
 
See the [documentation for FairExpo](https://fair-ground.github.io/Fair/documentation/fairexpo/).

### FairKit

The `FairKit` module contains optional SwiftUI Views and enhancements,
such as a SwiftUI [WebView](https://fair-ground.github.io/Fair/documentation/fairkit/webview).

 `FairKit` depends on `FairApp`.

See the [documentation for FairKit](https://fair-ground.github.io/Fair/documentation/fairkit/).


## Swift Package Manager

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

