// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "AppsFlyerAdobeExtension",
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "AppsFlyerAdobeExtension",
            targets: ["AppsFlyerAdobeExtension"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
        .package(url: "https://github.com/AppsFlyerSDK/AppsFlyerFramework", from: "6.4.4"),
//        .package(url: "https://github.com/adobe/aepsdk-core-ios.git", .upToNextMajor(from: "3.0.0"))
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "AppsFlyerAdobeExtension",
            dependencies: [
//                .product(name: "AEPCore", package: "aepsdk-core-ios"),
                .product(name: "AppsFlyerLib", package:"AppsFlyerFramework")

            ],
            path: "AppsFlyerAdobeExtension/Sources")
    ]
)

