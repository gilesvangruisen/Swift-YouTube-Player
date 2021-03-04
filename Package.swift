// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "YouTubePlayer",
    platforms: [.iOS(.v13)],
    products: [
        .library(name: "YouTubePlayer",
                 targets: ["YouTubePlayer"])
    ],
    dependencies: [],
    targets: [
        .target(
            name: "YouTubePlayer",
            dependencies: [],
            path: "YouTubePlayer/YouTubePlayer",
            exclude: ["Info.plist"],
            resources: [
                .process("YTPlayer.html")
            ]
        ),
        .testTarget(
            name: "YouTubePlayerTests",
            dependencies: ["YouTubePlayer"],
            path: "YouTubePlayer/Tests/YouTubePlayerTests"
        )
    ]
)
