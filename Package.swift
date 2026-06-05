// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "PhotoOrganizer-mac",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(
            name: "PhotoOrganizer",
            path: "Sources/PhotoOrganizer"
        ),
        .testTarget(
            name: "PhotoOrganizerTests",
            dependencies: ["PhotoOrganizer"],
            path: "Tests/PhotoOrganizerTests"
        )
    ]
)
