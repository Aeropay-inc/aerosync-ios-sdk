// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "aerosync-ios-sdk",
    platforms: [
        .iOS(.v14)
    ],
    products: [
        .library(
            name: "aerosync-ios-sdk",
            targets: ["aerosync-ios-sdk"]
        ),
    ],
    targets: [
        .target(
            name: "aerosync-ios-sdk",
            dependencies: []
        )
    ]
)