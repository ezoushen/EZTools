// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "EZTools",
    platforms: [
        .iOS(.v13)
    ],
    products: [
        // Products define the executables and libraries produced by a package, and make them visible to other packages.
        .library(
            name: "FontCase",
            type: .dynamic,
            targets: ["FontCase"]),
        .library(
            name: "CombineCocoa",
            type: .dynamic,
            targets: ["CombineCocoa"]),
        .library(
            name: "LayoutEngine",
            type: .dynamic,
            targets: ["LayoutEngine"]),
        .library(
            name: "Localization",
            type: .dynamic,
            targets: ["Localization"]),
        .library(
            name: "AppArchitecture",
            targets: ["AppArchitecture"]),
        
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package depends on.
        .target(
            name: "FontCase",
            dependencies: []),
        .target(
            name: "CombineCocoa",
            dependencies: []),
        .target(
            name: "LayoutEngine",
            dependencies: []),
        .target(
            name: "Localization",
            dependencies: []),
        .target(
            name: "AppArchitecture",
            dependencies: []),
    ]
)
