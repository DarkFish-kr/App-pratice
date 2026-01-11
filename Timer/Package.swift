// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Timer",
    platforms: [
        // 기존 .macOS(.v12)를 .v13으로 변경합니다.
        .macOS(.v13) 
    ],
    targets: [
        .executableTarget(
            name: "Timer",
            path: "Sources"),
    ]
)