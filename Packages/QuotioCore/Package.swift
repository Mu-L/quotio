// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "QuotioCore",
    platforms: [
        .macOS(.v14),
    ],
    products: [
        .library(name: "QuotioDomain", targets: ["QuotioDomain"]),
        .library(name: "QuotioApplication", targets: ["QuotioApplication"]),
        .library(name: "QuotioInfrastructure", targets: ["QuotioInfrastructure"]),
        .library(name: "QuotioPresentation", targets: ["QuotioPresentation"]),
    ],
    dependencies: [
        .package(path: "../QuotioHostClient"),
        .package(url: "https://github.com/PostHog/posthog-ios.git", exact: "3.64.1"),
        .package(url: "https://github.com/sparkle-project/Sparkle", exact: "2.8.1"),
    ],
    targets: [
        .target(name: "QuotioDomain"),
        .target(
            name: "QuotioApplication",
            dependencies: ["QuotioDomain"]
        ),
        .target(
            name: "QuotioInfrastructure",
            dependencies: [
                .product(name: "QuotioHostClient", package: "QuotioHostClient"),
                "QuotioApplication",
                "QuotioDomain",
                .product(name: "PostHog", package: "posthog-ios"),
                .product(name: "Sparkle", package: "Sparkle"),
            ]
        ),
        .target(
            name: "QuotioPresentation",
            dependencies: ["QuotioApplication", "QuotioDomain"]
        ),
        .testTarget(
            name: "QuotioDomainTests",
            dependencies: ["QuotioDomain"]
        ),
        .testTarget(
            name: "QuotioApplicationTests",
            dependencies: ["QuotioApplication", "QuotioDomain"]
        ),
        .testTarget(
            name: "QuotioInfrastructureTests",
            dependencies: ["QuotioInfrastructure", "QuotioApplication", "QuotioDomain", .product(name: "QuotioHostClient", package: "QuotioHostClient")]
        ),
        .testTarget(
            name: "QuotioPresentationTests",
            dependencies: ["QuotioPresentation", "QuotioApplication", "QuotioDomain"]
        ),
    ],
    swiftLanguageModes: [.v6]
)
