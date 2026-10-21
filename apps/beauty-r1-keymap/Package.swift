// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "BeautyR1Keymap",
    platforms: [.macOS(.v13)],
    products: [
        .library(name: "BeautyR1Core", targets: ["BeautyR1Core"]),
        .executable(name: "BeautyR1App", targets: ["BeautyR1App"])
    ],
    targets: [
        .target(name: "BeautyR1Core"),
        .executableTarget(name: "BeautyR1App", dependencies: ["BeautyR1Core"]),
        .testTarget(name: "BeautyR1CoreTests", dependencies: ["BeautyR1Core"])
    ]
)
