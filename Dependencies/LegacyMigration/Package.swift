// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "LegacyMigration",
    platforms: [.iOS(.v18), .macOS(.v13)],
    products: [.library(name: "LegacyMigration", targets: ["LegacyMigration"])],
    targets: [
        .target(name: "LegacyMigration"),
        .testTarget(name: "LegacyMigrationTests", dependencies: ["LegacyMigration"], resources: [.copy("Fixtures")]),
    ]
)
