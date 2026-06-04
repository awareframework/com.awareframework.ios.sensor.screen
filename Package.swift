// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "com.awareframework.ios.sensor.screen",
    platforms: [.iOS(.v13)],
    products: [
        .library(
            name: "com.awareframework.ios.sensor.screen",
            targets: [
                "com.awareframework.ios.sensor.screen"
            ]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/awareframework/com.awareframework.ios.core.git", from: "1.1.0")
    ],
    targets: [
        .target(
            name: "com.awareframework.ios.sensor.screen",
            dependencies: [
                .product(name: "com.awareframework.ios.core", package: "com.awareframework.ios.core", condition: .when(platforms: [.iOS]))
            ],
            path: "Sources/com.awareframework.ios.sensor.screen"
        ),
        .testTarget(
            name: "com.awareframework.ios.sensor.screenTests",
            dependencies: [
                .target(name: "com.awareframework.ios.sensor.screen")
            ],
            path: "Tests/com.awareframework.ios.sensor.screenTests"
        )
    ],
    swiftLanguageModes: [.v5]
)
