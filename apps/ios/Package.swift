// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "QuotioMobile",
    platforms: [.iOS("26.0"), .macOS(.v14)],
    products: [.library(name: "QuotioMobile", targets: ["QuotioMobile"])],
    dependencies: [.package(path: "../../Packages/QuotioHostClient")],
    targets: [
        .target(name: "QuotioMobile", dependencies: ["QuotioHostClient"]),
        .testTarget(name: "QuotioMobileTests", dependencies: ["QuotioMobile"]),
    ],
    swiftLanguageModes: [.v6]
)
