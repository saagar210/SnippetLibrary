// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "SnippetLibrary",
    platforms: [.macOS(.v14)],
    dependencies: [
        .package(url: "https://github.com/groue/GRDB.swift.git", from: "7.0.0"),
        .package(url: "https://github.com/raspu/Highlightr.git", from: "2.1.0")
    ],
    targets: [
        .executableTarget(
            name: "SnippetLibrary",
            dependencies: [
                .product(name: "GRDB", package: "GRDB.swift"),
                .product(name: "Highlightr", package: "Highlightr")
            ],
            path: "SnippetLibrary",
            exclude: ["Info.plist"],
            resources: [
                .process("Assets.xcassets")
            ],
            linkerSettings: [
                .unsafeFlags([
                    "-Xlinker", "-sectcreate",
                    "-Xlinker", "__TEXT",
                    "-Xlinker", "__info_plist",
                    "-Xlinker", "SnippetLibrary/Info.plist"
                ])
            ]
        ),
        .testTarget(
            name: "SnippetLibraryTests",
            dependencies: ["SnippetLibrary"]
        )
    ]
)
