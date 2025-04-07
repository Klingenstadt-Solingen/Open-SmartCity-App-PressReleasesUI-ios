// swift-tools-version:5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

/// use local package path
let packageLocal: Bool = false

let oscaEssentialsVersion = Version("1.1.0")
let oscaTestCaseExtensionVersion = Version("1.1.0")
let oscaPressReleasesVersion = Version("1.1.0")
let swiftSoupVersion = Version("2.4.3")

let package = Package(
  name: "OSCAPressReleasesUI",
  defaultLocalization: "de",
  platforms: [.iOS(.v13)],
  products: [
    // Products define the executables and libraries a package produces, and make them visible to other packages.
    .library(
      name: "OSCAPressReleasesUI",
      targets: ["OSCAPressReleasesUI"]),
  ],
  dependencies: [
    // Dependencies declare other packages that this package depends on.
    // .package(url: /* package url */, from: "1.0.0"),
    // OSCAEssentials
    packageLocal ? .package(path: "../OSCAEssentials") :
    .package(url: "https://git-dev.solingen.de/smartcityapp/modules/oscaessentials-ios.git",
             .upToNextMinor(from: oscaEssentialsVersion)),
    // OSCAPressReleases
    packageLocal ? .package(path: "../OSCAPressReleases") :
    .package(url: "https://git-dev.solingen.de/smartcityapp/modules/oscapressreleases-ios.git",
             .upToNextMinor(from: oscaPressReleasesVersion)),
    // OSCATestCaseExtension
    packageLocal ? .package(path: "../OSCATestCaseExtension") :
    .package(url: "https://git-dev.solingen.de/smartcityapp/modules/oscatestcaseextension-ios.git",
             .upToNextMinor(from: oscaTestCaseExtensionVersion)),
    // SwiftSoup
    .package(url: "https://github.com/scinfu/SwiftSoup.git",
             .upToNextMinor(from: swiftSoupVersion))
  ],
  targets: [
    // Targets are the basic building blocks of a package. A target can define a module or a test suite.
    // Targets can depend on other targets in this package, and on products in packages this package depends on.
    .target(
      name: "OSCAPressReleasesUI",
      dependencies: [.product(name: "OSCAPressReleases",
                              package: packageLocal ? "OSCAPressReleases" : "oscapressreleases-ios"),
                     /* OSCAEssentials */
                     .product(name: "OSCAEssentials",
                              package: packageLocal ? "OSCAEssentials" : "oscaessentials-ios")],
      path: "OSCAPressReleasesUI/OSCAPressReleasesUI",
      exclude: ["Info.plist",
                "SupportingFiles"],
      resources: [.process("Resources")]
    ),
    .testTarget(
      name: "OSCAPressReleasesUITests",
      dependencies: ["OSCAPressReleasesUI",
                     .product(name: "OSCATestCaseExtension",
                              package: packageLocal ? "OSCATestCaseExtension" : "oscatestcaseextension-ios"),
                     .product(name: "SwiftSoup",
                              package: "SwiftSoup")],
      path: "OSCAPressReleasesUI/OSCAPressReleasesUITests",
      exclude:["Info.plist"],
      resources: [.process("Resources")]
    ),
  ]
)
