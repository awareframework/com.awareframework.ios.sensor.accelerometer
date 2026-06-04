// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "com.awareframework.ios.sensor.accelerometer",
    platforms: [.iOS(.v13)],
    products: [
        .library(
            name: "com.awareframework.ios.sensor.accelerometer",
            targets: [
                "com.awareframework.ios.sensor.accelerometer"
            ]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/awareframework/com.awareframework.ios.core.git", from: "1.1.0")
    ],
    targets: [
        .target(
            name: "com.awareframework.ios.sensor.accelerometer",
            dependencies: [
                .product(name: "com.awareframework.ios.core", package: "com.awareframework.ios.core", condition: .when(platforms: [.iOS]))
            ],
            path: "Sources/com.awareframework.ios.sensor.accelerometer"
        ),
        .testTarget(
            name: "com.awareframework.ios.sensor.accelerometerTests",
            dependencies: ["com.awareframework.ios.core", "com.awareframework.ios.sensor.accelerometer"]
        )
    ],
    swiftLanguageModes: [.v5]
)
