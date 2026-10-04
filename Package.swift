// swift-tools-version: 5.9
// Liveness add-on for the VerifyIQ eKYC SDK. Needs iOS 15 because AWS Face Liveness (Amplify UI
// Liveness) does, so it is a package of its own: Swift Package Manager has one platform floor per
// package and refuses an iOS 15 dependency inside the iOS 13 core package.
// Released from boost-capital/verifyiq-mobile: the release workflow copies
// Sources/VerifyIQeKYCLiveness and sets the core version, always the same as this package's.
import PackageDescription

let package = Package(
    name: "VerifyIQeKYCLiveness",
    platforms: [.iOS(.v15)],
    products: [
        .library(name: "VerifyIQeKYCLiveness", targets: ["VerifyIQeKYCLiveness"]),
    ],
    dependencies: [
        .package(url: "https://github.com/boost-capital/verifyiq-ekyc-ios", exact: "0.9.2"),
        .package(url: "https://github.com/aws-amplify/amplify-ui-swift-liveness", exact: "1.4.8"),
    ],
    targets: [
        .target(
            name: "VerifyIQeKYCLiveness",
            dependencies: [
                .product(name: "VerifyIQeKYC", package: "verifyiq-ekyc-ios"),
                .product(name: "FaceLiveness", package: "amplify-ui-swift-liveness"),
            ],
            path: "Sources/VerifyIQeKYCLiveness"
        ),
    ],
    swiftLanguageVersions: [.v5]
)
