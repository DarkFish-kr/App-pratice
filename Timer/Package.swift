// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Timer",
    platforms: [
        .macOS(.v12) // macOS Monterey 12.0 이상 타겟팅 (SwiftUI 기능 활용을 위해)
    ],
    targets: [
        .executableTarget(
            name: "Timer",
            path: "Sources"), // Sources 폴더를 바라보도록 설정
    ]
)