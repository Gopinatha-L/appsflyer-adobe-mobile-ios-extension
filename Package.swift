// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "appsflyer-adobe-mobile-ios-extension",
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "appsflyer-adobe-mobile-ios-extension",
            targets: ["appsflyer-adobe-mobile-ios-extension"]),
    ],
    dependencies: [
        .package(name: "AppsFlyerLib" , url: "https://github.com/AppsFlyerSDK/AppsFlyerFramework.git", from: "6.3.1"),

    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "appsflyer-adobe-mobile-ios-extension",
            dependencies: [
                .product(name: "AppsFlyerLib", package: "AppsFlyerLib"),
],
            path: "AppsFlyerAdobeExtension/Classes",
                       publicHeadersPath: ""
        )
    ]
)
